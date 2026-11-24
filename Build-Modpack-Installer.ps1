<#
  Build-Modpack-Installer.ps1  -  run on YOUR PC (the pack owner), from the Anomaly folder.

  Reads your MO2 "Coop" profile, finds the original archive of every enabled mod,
  works out exactly which files from each archive ended up in the mod folder
  (FOMOD / BAIN / "set data directory" / hidden files - all of it), and writes:

    _ModpackInstaller\modpack.json        the recipe the friend-side installer follows
    _ModpackInstaller\modpack_overlay\    small files that are YOURS (meta.ini, profile,
                                          MCM settings, edited files, separators...)
    <parent folder>\Stalker_Anomaly_VanillaPlus_Coop_Pack_<date>.zip   what you send to friends

  Nothing in your install is changed.
#>
param(
    [string]$Profile = 'Coop',
    [string[]]$ArchiveDirs = @("$env:USERPROFILE\Downloads"),
    [switch]$SkipLinkCheck,
    [string]$GitHubRepo = 'Win-98SE/Stalker-Anomaly-Vanilla-Plus-Coop-Pack',  # Setup checks its latest release for updates
    # Mods made for this pack (no download exists) - their files ship inside Setup.
    # Anything NOT listed here that has no original archive still stops the build.
    [string[]]$OwnMods = @('ZCP Relations List Symbol Fix', 'Inventory Cell Crash Guard', 'MAS HD Icons Scope Fix', 'RE-Animate Sprint Fix', 'Ready Stances',
                           'SR-3M Vikhr Unsuppressed Sound', 'CVFX Generators and Poltergeist Fix', 'posvoip STALKER adapter', 'MRAA 3DSS Fix',
                           'xrr_gestures', 'THAP Repaired EXO Duty Fix'),   # xrr_gestures by leer: only shared on the xrRazom Discord (links expire), so bundled with credit
    # Pack mods whose model files are REBUILT on each friend's PC from other mods' files
    # (Mraa3dssFix.cs) - only their configs ship; their gamedata\meshes files are checked by SHA-256.
    [string[]]$GenMods = @('MRAA 3DSS Fix')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Tools = $PSScriptRoot
$Root = $Tools
if (-not (Test-Path -LiteralPath (Join-Path $Root 'ModOrganizer.exe'))) { $Root = Split-Path -Parent $Tools }
$Out = Join-Path $env:TEMP 'AnomalyModpackBuild'
$OverlayDir = Join-Path $Out 'modpack_overlay'
$Report = New-Object System.Collections.Generic.List[string]
$script:MissingArchives = New-Object System.Collections.Generic.List[string]

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Note($msg) { $Report.Add($msg); Say "  $msg" 'Yellow' }

# ---------------------------------------------------------------- helpers
Add-Type -TypeDefinition @"
public static class ModpackCrc {
    static readonly uint[] T = Make();
    static uint[] Make() {
        var t = new uint[256];
        for (uint i = 0; i < 256; i++) {
            uint c = i;
            for (int k = 0; k < 8; k++) c = ((c & 1) != 0) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
            t[i] = c;
        }
        return t;
    }
    public static string Of(string path) {
        uint c = 0xFFFFFFFFu;
        var buf = new byte[1 << 20];
        using (var fs = new System.IO.FileStream(path, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.ReadWrite, 1 << 20)) {
            int n;
            while ((n = fs.Read(buf, 0, buf.Length)) > 0)
                for (int i = 0; i < n; i++) c = T[(c ^ buf[i]) & 0xFF] ^ (c >> 8);
        }
        return (c ^ 0xFFFFFFFFu).ToString("X8");
    }
}
"@

function Find-7z {
    $cands = @(
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        (Join-Path $Tools '7z\7z.exe')
    )
    foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # bootstrap a private copy of 7-Zip (needed for .rar support)

    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    $zr = Join-Path $tools '7zr.exe'
    $inst = Join-Path $tools '7z-x64.exe'
    Say 'Downloading 7-Zip (needed to read the mod archives)...'
    Invoke-WebRequest 'https://www.7-zip.org/a/7zr.exe' -OutFile $zr -UseBasicParsing
    Invoke-WebRequest 'https://www.7-zip.org/a/7z2409-x64.exe' -OutFile $inst -UseBasicParsing
    & $zr x -y "-o$tools\7z" $inst | Out-Null
    $exe = Join-Path $tools '7z\7z.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw '7-Zip could not be set up. Install 7-Zip from https://www.7-zip.org and run again.' }
    return $exe
}

function Get-ArchiveEntries($sevenZip, $archive) {
    # returns list of @{ Path; Size; Crc } for files (no folders)
    $old = [Console]::OutputEncoding
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    try { $lines = & $sevenZip l -slt -sccUTF-8 -- $archive 2>$null }
    finally { [Console]::OutputEncoding = $old }
    if ($LASTEXITCODE -gt 1) { throw "7-Zip could not read $archive" }
    $list = New-Object System.Collections.Generic.List[object]
    $started = $false; $cur = $null
    foreach ($l in $lines) {
        if (-not $started) { if ($l -like '----------*') { $started = $true }; continue }
        if ($l -like 'Path = *') {
            if ($cur -and -not $cur.Dir) { $list.Add($cur) }
            $cur = [pscustomobject]@{ Path = $l.Substring(7).Replace('\', '/'); Size = [int64]-1; Crc = ''; Dir = $false }
        }
        elseif ($cur) {
            if ($l -like 'Size = *') { $v = $l.Substring(7); if ($v) { $cur.Size = [int64]$v } }
            elseif ($l -like 'CRC = *') { $cur.Crc = $l.Substring(6).Trim().ToUpper() }
            elseif ($l -eq 'Folder = +') { $cur.Dir = $true }
            elseif ($l -like 'Attributes = *' -and $l.Substring(13) -match '^D') { $cur.Dir = $true }
        }
    }
    if ($cur -and -not $cur.Dir) { $list.Add($cur) }
    return $list
}

function Read-Ini($path) {
    $h = @{}
    if (-not (Test-Path -LiteralPath $path)) { return $h }
    foreach ($l in [IO.File]::ReadAllLines($path)) {
        if ($l -match '^\s*([^=;\[]+?)\s*=\s*(.*)$') { if (-not $h.ContainsKey($Matches[1])) { $h[$Matches[1]] = $Matches[2] } }
    }
    return $h
}

function Split-Seg($p) { return @($p.Split('/') | Where-Object { $_ -ne '' }) }
function Join-Seg($segs, $from, $to) {
    if ($to -lt $from) { return '' }
    return ($segs[$from..$to] -join '/')
}

# Given archive path + installed relative path, split into srcPrefix/destPrefix/tail
function Get-Split($src, $dest) {
    [string[]]$s = @(Split-Seg $src); [string[]]$d = @(Split-Seg $dest)
    $i = $s.Count - 1; $j = $d.Count - 1; $n = 0
    while ($i -ge 0 -and $j -ge 0 -and ($s[$i] -ieq $d[$j])) { $i--; $j--; $n++ }
    return [pscustomobject]@{
        Src  = (Join-Seg $s 0 $i)
        Dest = (Join-Seg $d 0 $j)
        Tail = (Join-Seg $s ($i + 1) ($s.Count - 1))
    }
}

function Get-RelFiles($dir) {
    $base = (Resolve-Path -LiteralPath $dir).ProviderPath.TrimEnd('\') + '\'
    Get-ChildItem -LiteralPath $dir -Recurse -File -Force | ForEach-Object {
        [pscustomobject]@{ Rel = $_.FullName.Substring($base.Length).Replace('\', '/'); Full = $_.FullName; Size = $_.Length }
    }
}

# Build recipe rules for a set of installed files against one archive's entries.
# Returns @{ Rules=...; Hide=...; Unmatched=... }
function Get-Recipe($entries, $files, $destRootIsGameRoot) {
    $byLeaf = @{}
    foreach ($e in $entries) {
        $leaf = ($e.Path.Split('/')[-1]).ToLower() + '|' + $e.Size
        if (-not $byLeaf.ContainsKey($leaf)) { $byLeaf[$leaf] = New-Object System.Collections.Generic.List[object] }
        $byLeaf[$leaf].Add($e)
    }
    $pending = New-Object System.Collections.Generic.List[object]
    $unmatched = New-Object System.Collections.Generic.List[object]
    $prefixCount = @{}
    foreach ($f in $files) {
        $hidden = $f.Rel.EndsWith('.mohidden', [StringComparison]::OrdinalIgnoreCase)
        $key = if ($hidden) { $f.Rel.Substring(0, $f.Rel.Length - 9) } else { $f.Rel }
        $leaf = ($key.Split('/')[-1]).ToLower() + '|' + $f.Size
        $cands = @()
        if ($byLeaf.ContainsKey($leaf)) {
            $kl = $key.ToLower()
            $alt = if ($kl.StartsWith('gamedata/')) { $kl.Substring(9) } else { $null }
            foreach ($e in $byLeaf[$leaf]) {
                $pl = $e.Path.ToLower()
                if ($pl -eq $kl -or $pl.EndsWith('/' + $kl) -or ($alt -and ($pl -eq $alt -or $pl.EndsWith('/' + $alt)))) { $cands += $e }
            }
        }
        if ($cands.Count -gt 0) {
            $crc = [ModpackCrc]::Of($f.Full)
            $good = @($cands | Where-Object { $_.Crc -eq '' -or $_.Crc -eq $crc })
            $cands = $good
        }
        if ($cands.Count -eq 0) { $unmatched.Add($f); continue }
        $splits = @($cands | ForEach-Object { Get-Split $_.Path $key })
        foreach ($sp in $splits) { $k = $sp.Src + '>' + $sp.Dest; $prefixCount[$k] = 1 + [int]$prefixCount[$k] }
        $pending.Add([pscustomobject]@{ Key = $key; Hidden = $hidden; Splits = $splits })
    }
    # choose the most common prefix pair for each file, group into rules
    $groups = @{}
    $hide = New-Object System.Collections.Generic.List[string]
    foreach ($p in $pending) {
        $best = $p.Splits | Sort-Object { - [int]$prefixCount[$_.Src + '>' + $_.Dest] } | Select-Object -First 1
        $k = $best.Src + '>' + $best.Dest
        if (-not $groups.ContainsKey($k)) { $groups[$k] = [pscustomobject]@{ Src = $best.Src; Dest = $best.Dest; Tails = (New-Object System.Collections.Generic.List[string]) } }
        $groups[$k].Tails.Add($best.Tail)
        if ($p.Hidden) { $hide.Add($p.Key) }
    }
    $rules = New-Object System.Collections.Generic.List[object]
    foreach ($g in $groups.Values) {
        $pre = if ($g.Src) { $g.Src.ToLower() + '/' } else { '' }
        $under = @($entries | Where-Object { $_.Path.ToLower().StartsWith($pre) }).Count
        $distinct = @($g.Tails | ForEach-Object { $_.ToLower() } | Sort-Object -Unique).Count
        if ($under -eq $g.Tails.Count -and $distinct -eq $g.Tails.Count) {
            $item = [ordered]@{ src = $g.Src; dest = $g.Dest; all = $true; count = $g.Tails.Count }
            [void]$rules.Add($item)
        } else {
            $item = [ordered]@{ src = $g.Src; dest = $g.Dest; all = $false; files = @($g.Tails | Sort-Object) }
            [void]$rules.Add($item)
        }
    }
    return [pscustomobject]@{ Rules = $rules; Hide = $hide; Unmatched = $unmatched }
}

function Copy-ToOverlay($full, $relDest) {
    $target = Join-Path $OverlayDir ($relDest.Replace('/', '\'))
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    if ($relDest -match '(^|[\\/])meta\.ini$') {
        # MO2 stores the full download path (with your Windows user name) - keep only the file name
        $lines = [IO.File]::ReadAllLines($full) | ForEach-Object {
            if ($_ -match '^installationFile=(.+)$') { 'installationFile=' + ($Matches[1] -split '[\\/]')[-1] } else { $_ }
        }
        [IO.File]::WriteAllLines($target, [string[]]$lines)
    } else {
        [IO.File]::Copy($full, $target, $true)
    }
}

function Find-Archive($name) {
    if (-not $name) { return $null }
    $name = $name.Replace('/', '\')
    if ([IO.Path]::IsPathRooted($name) -and (Test-Path -LiteralPath $name)) { return $name }
    $leaf = Split-Path -Leaf $name
    foreach ($d in $script:SearchDirs) {
        $p = Join-Path $d $leaf
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

# The fix recipe runs here too, on your installed mods, and must rebuild your fix files
# byte-for-byte - otherwise the build stops (friends would get something different).
function Test-GenMod($name, $genFiles) {
    $cs = Join-Path $Tools 'Mraa3dssFix.cs'
    if (-not (Test-Path -LiteralPath $cs)) { throw "Mraa3dssFix.cs is missing next to this script (needed for '$name')." }
    if (-not ('Mraa3dssFix' -as [type])) { Add-Type -Path $cs }
    $tmp = Join-Path $env:TEMP 'AnomalyModpackGenTest'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    $glog = New-Object 'System.Collections.Generic.List[string]'
    Say "      testing the fix recipe against your installed files..." 'DarkGray'
    $made = [Mraa3dssFix]::Build((Join-Path $Root 'mods'), $tmp, $glog)
    $want = @{}; foreach ($g in $genFiles) { $want[$g.path.ToLower()] = $g.sha256 }
    $bad = New-Object System.Collections.Generic.List[string]
    foreach ($rel in $made) {
        $k = $rel.ToLower()
        if (-not $want.ContainsKey($k)) { $bad.Add("extra: $rel"); continue }
        $h = (Get-FileHash -LiteralPath (Join-Path $tmp $rel.Replace('/', '\')) -Algorithm SHA256).Hash
        if ($h -ne $want[$k]) { $bad.Add("different: $rel") }
        $want.Remove($k)
    }
    foreach ($k in $want.Keys) { $bad.Add("not rebuilt: $k") }
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if ($bad.Count -gt 0) {
        $f = Join-Path $Tools 'gen-test-errors.txt'
        [IO.File]::WriteAllLines($f, [string[]]$bad)
        throw "'$name' recipe does not rebuild your files exactly ($($bad.Count) problem(s), see $f) - nothing was built."
    }
    Say "      recipe OK: all $($made.Count) model files rebuilt identical" 'DarkGray'
}

# ---------------------------------------------------------------- checks
Say ''
Say '=== Stalker Anomaly Vanilla+ Coop Pack: building the installer ===' 'Cyan'
if (-not (Test-Path -LiteralPath (Join-Path $Root 'ModOrganizer.exe'))) { throw 'Put the "Modpack Tools" folder inside your Anomaly folder (next to ModOrganizer.exe).' }
$profDir = Join-Path $Root "profiles\$Profile"
$modlistPath = Join-Path $profDir 'modlist.txt'
if (-not (Test-Path -LiteralPath $modlistPath)) { throw "MO2 profile '$Profile' not found." }
if (Get-Process ModOrganizer -ErrorAction SilentlyContinue) { Say 'Note: MO2 is open. That is fine, but close it if you change anything while this runs.' 'Yellow' }

$moIni = Join-Path $Root 'ModOrganizer.ini'
$moIniText = [IO.File]::ReadAllText($moIni)
$downloadsDir = Join-Path $Root 'downloads'
if ($moIniText -match '(?m)^download_directory=(.+)$') { $downloadsDir = $Matches[1].Trim().Replace('/', '\') -replace '^@ByteArray\((.*)\)$', '$1' }
$script:SearchDirs = @($downloadsDir) + $ArchiveDirs | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
$mo2Version = '2.5.2'
if ($moIniText -match '(?m)^version=@ByteArray\(([\d\.]+)') { $mo2Version = $Matches[1] } elseif ($moIniText -match '(?m)^version=([\d\.]+)') { $mo2Version = $Matches[1] }
$mo2Version = ($mo2Version -split '\.')[0..2] -join '.'

$sevenZip = Find-7z
Say "7-Zip: $sevenZip"
Say "Looking for archives in: $($script:SearchDirs -join ' ; ')"

if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $OverlayDir | Out-Null

# sources table
$sources = @()
$srcCsv = Join-Path $Tools 'modpack-sources.csv'
if (Test-Path -LiteralPath $srcCsv) { $sources = @(Import-Csv -LiteralPath $srcCsv) }
function Get-SourceUrl($modName, $archiveName, $metaUrl) {
    foreach ($s in $sources) {
        if (-not $s.match -or -not $s.url) { continue }
        if (($archiveName -and $archiveName.StartsWith($s.match, [StringComparison]::OrdinalIgnoreCase)) -or
            $modName.StartsWith($s.match, [StringComparison]::OrdinalIgnoreCase)) { return $s.url }
    }
    if ($metaUrl -and $metaUrl -match '^https?://') { return $metaUrl }
    return ''
}

# ---------------------------------------------------------------- mods
$modLines = [IO.File]::ReadAllLines($modlistPath)
$enabled = New-Object System.Collections.Generic.List[string]
$keepLines = New-Object System.Collections.Generic.List[string]
foreach ($l in $modLines) {
    if ($l.StartsWith('#')) { $keepLines.Add($l); continue }
    $name = $l.Substring(1)
    if ($name.EndsWith('_separator')) {
        $keepLines.Add($l)
        $sepMeta = Join-Path $Root "mods\$name\meta.ini"
        if (Test-Path -LiteralPath $sepMeta) { Copy-ToOverlay $sepMeta "mods/$name/meta.ini" }
        continue
    }
    if ($l.StartsWith('+')) { $enabled.Add($name); $keepLines.Add($l) }
}
New-Item -ItemType Directory -Force -Path (Join-Path $OverlayDir "profiles\$Profile") | Out-Null
[IO.File]::WriteAllLines((Join-Path $OverlayDir "profiles\$Profile\modlist.txt"), [string[]]$keepLines)
Get-ChildItem -LiteralPath $profDir -File | Where-Object { $_.Name -ne 'modlist.txt' } | ForEach-Object {
    Copy-ToOverlay $_.FullName "profiles/$Profile/$($_.Name)"
}

$archives = [ordered]@{}   # file name -> info
$entryCache = @{}
$mods = New-Object System.Collections.Generic.List[object]
$xrArchiveName = $null
$n = 0
foreach ($name in $enabled) {
    $n++
    Say ("[{0}/{1}] {2}" -f $n, $enabled.Count, $name) 'White'
    $modDir = Join-Path $Root "mods\$name"
    if (-not (Test-Path -LiteralPath $modDir)) { Note "$name : folder missing - skipped"; continue }
    $meta = Read-Ini (Join-Path $modDir 'meta.ini')
    if (Test-Path -LiteralPath (Join-Path $modDir 'meta.ini')) { Copy-ToOverlay (Join-Path $modDir 'meta.ini') "mods/$name/meta.ini" }
    $files = @(Get-RelFiles $modDir | Where-Object { $_.Rel -ine 'meta.ini' })
    $instFile = $meta['installationFile']
    if ($instFile) { $instFile = $instFile.Trim().Trim('"') }
    if ($OwnMods -contains $name) {
        # the pack's own mod: ship its files; the content hash goes into the recipe so
        # Setup reinstalls it on friends' PCs whenever these files change
        $isGen = $GenMods -contains $name
        $genFiles = New-Object System.Collections.Generic.List[object]
        $sb = New-Object System.Text.StringBuilder
        foreach ($f in @($files | Sort-Object Rel)) {
            $h = (Get-FileHash -LiteralPath $f.Full -Algorithm SHA256).Hash
            [void]$sb.Append($f.Rel).Append('=').Append($h).Append(';')
            if ($isGen -and $f.Rel -like 'gamedata/meshes/*') { $genFiles.Add([ordered]@{ path = $f.Rel; sha256 = $h }); continue }
            Copy-ToOverlay $f.Full "mods/$name/$($f.Rel)"
        }
        $sha = [Security.Cryptography.SHA256]::Create()
        $own = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($sb.ToString()))).Replace('-', '')
        $item = [ordered]@{ name = $name; archive = $null; rules = @("own:$own"); hide = @() }
        if ($isGen) {
            Test-GenMod $name $genFiles
            $item['gen'] = [ordered]@{ recipe = 'mraa3dss'; inputs = @('3DSS MRAA', 'MRAA 1.4 3DSS Meshes', 'MRAA 1.4.6'); files = $genFiles.ToArray() }
            Say ("      pack's own mod - {0} config file(s) shipped, {1} model file(s) rebuilt on each PC" -f ($files.Count - $genFiles.Count), $genFiles.Count) 'DarkGray'
        } else {
            Say ("      pack's own mod - {0} file(s) shipped in Setup" -f $files.Count) 'DarkGray'
        }
        [void]$mods.Add($item)
        continue
    }
    $arcPath = Find-Archive $instFile
    if (-not $arcPath) {
        $bytes = ($files | Measure-Object Size -Sum).Sum
        Note ("{0} : original archive '{1}' not found - whole mod copied into the installer ({2:N1} MB)" -f $name, $instFile, ($bytes / 1MB))
        $script:MissingArchives.Add(("{0}  ->  {1}" -f $name, $instFile))
        foreach ($f in $files) { Copy-ToOverlay $f.Full "mods/$name/$($f.Rel)" }
        $item = [ordered]@{ name = $name; archive = $null; rules = @(); hide = @() }
        [void]$mods.Add($item)
        continue
    }
    $arcName = Split-Path -Leaf $arcPath
    if ($arcName -match 'xrRazom') { $xrArchiveName = $arcName }
    if (-not $entryCache.ContainsKey($arcName)) { $entryCache[$arcName] = Get-ArchiveEntries $sevenZip $arcPath }
    $entries = $entryCache[$arcName]
    $r = Get-Recipe $entries $files $false
    foreach ($u in $r.Unmatched) { Copy-ToOverlay $u.Full "mods/$name/$($u.Rel)" }
    if ($r.Unmatched.Count -gt 0) {
        $ub = ($r.Unmatched | Measure-Object Size -Sum).Sum
        Note ("{0} : {1} file(s) not from the archive (your edits/extra files) - packed into the installer ({2:N1} MB)" -f $name, $r.Unmatched.Count, ($ub / 1MB))
    }
    if (-not $archives.Contains($arcName)) {
        $fi = Get-Item -LiteralPath $arcPath
        Say "      hashing $arcName ..." 'DarkGray'
        $archives[$arcName] = [ordered]@{
            file   = $arcName
            size   = $fi.Length
            sha256 = (Get-FileHash -LiteralPath $arcPath -Algorithm SHA256).Hash
            url    = (Get-SourceUrl $name $arcName $meta['url'])
            mods   = @()
        }
    }
    $archives[$arcName].mods += $name
    $rulesArr = $r.Rules.ToArray()
    $hideArr = $r.Hide.ToArray()
    $item = [ordered]@{}
    $item['name'] = $name
    $item['archive'] = $arcName
    $item['rules'] = $rulesArr
    $item['hide'] = $hideArr
    [void]$mods.Add($item)
    Say ("      {0} rule(s), {1} hidden, {2} extra file(s)" -f $r.Rules.Count, $r.Hide.Count, $r.Unmatched.Count) 'DarkGray'
}

# ---------------------------------------------------------------- xrRazom root files (bin\, gamedata\)
$xrRecipe = $null
if ($xrArchiveName) {
    Say 'xrRazom engine files (bin\ and root gamedata\)...' 'White'
    $rootFiles = New-Object System.Collections.Generic.List[object]
    foreach ($sub in @('bin', 'gamedata')) {
        $d = Join-Path $Root $sub
        if (Test-Path -LiteralPath $d) {
            foreach ($f in (Get-RelFiles $d)) {
                if ($f.Rel -like '_vanilla_backup/*' -or $f.Rel -like '_modpack_backup/*') { continue }
                $rootFiles.Add([pscustomobject]@{ Rel = "$sub/$($f.Rel)"; Full = $f.Full; Size = $f.Size })
            }
        }
    }
    $r = Get-Recipe $entryCache[$xrArchiveName] $rootFiles $true
    foreach ($u in $r.Unmatched) {
        if ($u.Rel -like 'gamedata/*') {
            Copy-ToOverlay $u.Full "root/$($u.Rel)"
            Note "root : $($u.Rel) is yours (not from xrRazom) - packed into the installer"
        }
    }
    $rootRules = $r.Rules.ToArray()
    $xrRecipe = [ordered]@{}
    $xrRecipe['archive'] = $xrArchiveName
    $xrRecipe['rules'] = $rootRules
    $cnt = 0; foreach ($rule in $r.Rules) { if ($rule.all) { $cnt += $rule.count } else { $cnt += $rule.files.Count } }
    Say "      $cnt engine file(s) mapped from $xrArchiveName" 'DarkGray'
} else {
    Note 'xrRazom archive not found - root bin\ engine files are NOT part of the installer!'
}

# ---------------------------------------------------------------- MO2 settings
# your game settings (user.ltx). The whole file matters: some non-graphics lines change which
# shader code compiles, so everything is copied EXCEPT personal/hardware lines (keys, monitor,
# resolution, sound device, mouse, co-op name/host settings) - those stay as each friend has them.
$userLtx = Join-Path $Root 'appdata\user.ltx'
$skipKeys = '^(bind\S*|unbind\S*|vid_mode|vid_monitor|snd_device|mouse_\S*|xrr_player_name|xrr_host_\S*|xrr_lan\S*|r__framelimit)(\s|$)'
if (Test-Path -LiteralPath $userLtx) {
    $keep = @([IO.File]::ReadAllLines($userLtx) | Where-Object { $_.Trim() -and $_ -notmatch $skipKeys })
    if ($keep.Count -gt 0) {
        [IO.File]::WriteAllLines((Join-Path $OverlayDir 'modpack_settings.ltx'), [string[]]$keep)
        Say "Pack game settings taken from your user.ltx: $($keep.Count) line(s)" 'DarkGray'
    }
} else { Note 'appdata\user.ltx not found - the installer will not set the pack game settings (shaders may fail to compile)' }
# launch options (e.g. -smap4096 shadow map size, which also changes how shaders compile); debug flag removed
$cmdLine = Join-Path $Root 'commandline.txt'
if (Test-Path -LiteralPath $cmdLine) {
    $opts = (([IO.File]::ReadAllText($cmdLine) -split '\s+') | Where-Object { $_ -and $_ -ine '-dbg' }) -join ' '
    if ($opts) {
        [IO.File]::WriteAllText((Join-Path $OverlayDir 'commandline.txt'), $opts)
        Say "Launch options taken from commandline.txt: $opts" 'DarkGray'
    }
}
# posvoip voice chat (MPL-2.0, bundled with credit): the program folder goes into the game folder
$posDir = Join-Path $Root 'posvoip'
if (Test-Path -LiteralPath $posDir) {
    $pc = 0
    foreach ($f in (Get-RelFiles $posDir)) { Copy-ToOverlay $f.Full "root/posvoip/$($f.Rel)"; $pc++ }
    Say "posvoip program: $pc file(s) bundled" 'DarkGray'
} else { Note 'posvoip folder not found in the game folder - voice chat program NOT bundled' }
foreach ($extra in @('portable.txt', 'categories.dat')) {
    $p = Join-Path $Root $extra
    if (Test-Path -LiteralPath $p) { Copy-ToOverlay $p $extra }
}
$ini = $moIniText
$bsl2 = $Root.Replace('\', '\\')
$fwd = $Root.Replace('\', '/')
$ini = [regex]::Replace($ini, [regex]::Escape($bsl2), '{ROOT_BSL2}', 'IgnoreCase')
$ini = [regex]::Replace($ini, [regex]::Escape($fwd), '{ROOT_FWD}', 'IgnoreCase')
$ini = [regex]::Replace($ini, [regex]::Escape($Root), '{ROOT_BSL}', 'IgnoreCase')
$ini = [regex]::Replace($ini, '(?ms)^\[recentDirectories\].*?(?=^\[|\z)', '')
$ini = [regex]::Replace($ini, '(?m)^selected_profile=.*$', "selected_profile=@ByteArray($Profile)")
$ini = [regex]::Replace($ini, '(?m)^download_directory=.*\r?\n', '')
$userFwd = $env:USERPROFILE.Replace('\', '/')
$cleaned = New-Object System.Collections.Generic.List[string]
foreach ($l in ($ini -split "`r?`n")) {
    if ($l.IndexOf($env:USERPROFILE, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $l.IndexOf($userFwd, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $l.IndexOf($env:USERPROFILE.Replace('\', '\\'), [StringComparison]::OrdinalIgnoreCase) -ge 0) { continue }
    $cleaned.Add($l)
}
[IO.File]::WriteAllText((Join-Path $OverlayDir 'ModOrganizer.ini'), ($cleaned -join "`r`n"))

# ---------------------------------------------------------------- link check
function Get-Page($url) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $old = [Console]::OutputEncoding
        [Console]::OutputEncoding = [Text.Encoding]::UTF8
        try {
            $out = & $curl.Source -sSL --compressed --fail --max-time 60 -A $ua `
                -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' `
                -H 'Accept-Language: en-US,en;q=0.9' -H 'Upgrade-Insecure-Requests: 1' $url 2>&1
        } finally { [Console]::OutputEncoding = $old }
        if ($LASTEXITCODE -ne 0) { throw "page request failed (curl exit $LASTEXITCODE): $(($out | Select-Object -Last 1))" }
        return ($out -join "`n")
    }
    return (Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing -TimeoutSec 60).Content
}
$linkReport = New-Object System.Collections.Generic.List[string]
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
foreach ($a in $archives.Values) {
    if (-not $a.url) { $linkReport.Add("MISSING   $($a.file)   (used by: $($a.mods -join ', '))"); continue }
    if ($SkipLinkCheck -or $a.url -notmatch 'moddb\.com') { $linkReport.Add("SET       $($a.file)   $($a.url)"); continue }
    try {
        $html = Get-Page $a.url
        $fname = $null
        if ($html -match 'Filename</h5>\s*<span[^>]*>\s*([^<]+?)\s*</span>') { $fname = $Matches[1].Trim() }
        if ($html.IndexOf($a.file, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $linkReport.Add("OK        $($a.file)   $($a.url)") }
        elseif ($fname) { $linkReport.Add("DIFFERENT $($a.file)   page now has '$fname'  $($a.url)") }
        else { $linkReport.Add("UNCHECKED $($a.file)   (page opened, filename not shown)  $($a.url)") }
    } catch {
        if ($_.Exception.Message -match '403') { $linkReport.Add("SET       $($a.file)   $($a.url)   (ModDB blocks scripts, so this link can't be checked - open it in your browser to confirm)") }
        else { $linkReport.Add("BROKEN    $($a.file)   $($a.url)   ($($_.Exception.Message))") }
    }
    Start-Sleep -Milliseconds 600
}

# ---------------------------------------------------------------- write outputs
$archiveArr = New-Object System.Collections.Generic.List[object]
foreach ($v in $archives.Values) { [void]$archiveArr.Add($v) }
$archiveArr = $archiveArr.ToArray()
$modsArr = $mods.ToArray()
$manifest = [ordered]@{
    name      = "Stalker Anomaly Vanilla+ Coop Pack ($Profile)"
    created   = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    github    = $GitHubRepo
    profile   = $Profile
    mo2       = [ordered]@{ version = $mo2Version; url = "https://github.com/ModOrganizer2/modorganizer/releases/download/v$mo2Version/Mod.Organizer-$mo2Version.7z" }
    archives  = $archiveArr
    mods      = $modsArr
    root      = $xrRecipe
}
$json = $manifest | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText((Join-Path $Out 'modpack.json'), $json, (New-Object Text.UTF8Encoding $false))

foreach ($f in @('Install-Modpack.ps1', 'Install Modpack.bat', 'README - Modpack Installer.txt', 'Mraa3dssFix.cs')) {
    $p = Join-Path $Tools $f
    if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $Out }
    else { Note "$f not found next to this script - add it to the zip by hand" }
}

$reportText = @(
    "Built $($manifest.created)  -  $($mods.Count) mods, $($archives.Count) archives",
    '',
    'DOWNLOAD LINKS (fill MISSING / fix DIFFERENT or BROKEN in modpack-sources.csv, then run again):',
    $linkReport,
    '',
    'NOTES:',
    $Report
) | ForEach-Object { $_ }
[IO.File]::WriteAllLines((Join-Path $Tools 'modpack-build-report.txt'), [string[]]$reportText)

# ---------------------------------------------------------------- safety: never ship other people's mod files
if ($script:MissingArchives.Count -gt 0) {
    Say ''
    Say '=== STOPPED - nothing was built ===' 'Red'
    Say "The original download of these mods wasn't found, so their files would have been packed" 'Red'
    Say 'into the installer (that would re-upload the mod). Put each archive back in your Downloads' 'Red'
    Say "folder or in $(Join-Path $Root 'downloads'), then run this again:" 'Red'
    foreach ($x in $script:MissingArchives) { Say "   $x" 'Yellow' }
    Remove-Item -LiteralPath $Out -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# ---------------------------------------------------------------- pack icon (Setup .exe + desktop shortcut)
try {
    # icon: radiation symbol, classic 32-bit icon in 4 sizes
    Add-Type -AssemblyName System.Drawing
    $iconImages = New-Object System.Collections.Generic.List[byte[]]
    $iconSizes = @(16, 32, 48, 64)
    foreach ($sz in $iconSizes) {
        $f = $sz / 256.0
        $bmp = New-Object System.Drawing.Bitmap $sz, $sz, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Transparent)
        # same look as the Setup window header: white disc, yellow ring, black radiation symbol
        $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $fg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 40, 40, 40))
        $g.FillEllipse($bg, [float](8 * $f), [float](8 * $f), [float](240 * $f), [float](240 * $f))
        $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 230, 180, 0)), ([float][math]::Max(1.5, 16 * $f))
        $g.DrawEllipse($ring, [float](16 * $f), [float](16 * $f), [float](224 * $f), [float](224 * $f))
        foreach ($k in 0..2) { $g.FillPie($fg, [float](28 * $f), [float](28 * $f), [float](200 * $f), [float](200 * $f), [float](-120 + $k * 120), [float]60) }
        $g.FillEllipse($bg, [float](98 * $f), [float](98 * $f), [float](60 * $f), [float](60 * $f))
        $g.FillEllipse($fg, [float](110 * $f), [float](110 * $f), [float](36 * $f), [float](36 * $f))
        $g.Dispose()
        # DIB: header + BGRA pixels bottom-up + empty AND mask (alpha does the masking)
        $ms = New-Object System.IO.MemoryStream
        $w = New-Object System.IO.BinaryWriter $ms
        $andRow = [int]([math]::Ceiling($sz / 32.0) * 4)
        $w.Write([uint32]40); $w.Write([int32]$sz); $w.Write([int32]($sz * 2)); $w.Write([uint16]1); $w.Write([uint16]32)
        $w.Write([uint32]0); $w.Write([uint32]($sz * $sz * 4 + $andRow * $sz)); $w.Write([int32]0); $w.Write([int32]0); $w.Write([uint32]0); $w.Write([uint32]0)
        for ($y = $sz - 1; $y -ge 0; $y--) {
            for ($x = 0; $x -lt $sz; $x++) {
                $c = $bmp.GetPixel($x, $y)
                $w.Write([byte]$c.B); $w.Write([byte]$c.G); $w.Write([byte]$c.R); $w.Write([byte]$c.A)
            }
        }
        $w.Write((New-Object byte[] ($andRow * $sz)))
        $w.Flush()
        $iconImages.Add($ms.ToArray())
        $bmp.Dispose()
    }
    $ico = Join-Path $Out 'modpack.ico'
    $bw = New-Object System.IO.BinaryWriter ([IO.File]::Create($ico))
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$iconSizes.Count)
    $offset = 6 + 16 * $iconSizes.Count
    for ($n = 0; $n -lt $iconSizes.Count; $n++) {
        $sz = $iconSizes[$n]
        $bw.Write([byte]$sz); $bw.Write([byte]$sz); $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$iconImages[$n].Length); $bw.Write([uint32]$offset)
        $offset += $iconImages[$n].Length
    }
    foreach ($img in $iconImages) { $bw.Write($img) }
    $bw.Close()
} catch { $ico = $null; Note "Pack icon could not be made: $($_.Exception.Message)" }

$zip = Join-Path (Split-Path -Parent $Root) ("Stalker_Anomaly_VanillaPlus_Coop_Pack_{0}.zip" -f (Get-Date -Format 'yyyy-MM-dd'))
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($Out, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
$ovBytes = (Get-ChildItem -LiteralPath $OverlayDir -Recurse -File | Measure-Object Length -Sum).Sum

# ---------------------------------------------------------------- Setup .exe (window installer)
# Compiled with the C# compiler that is part of Windows (.NET Framework 4) - nothing to install.
$exe = $null
$exeError = $null
$csSource = Join-Path $Tools 'SetupGui.cs'
if (Test-Path -LiteralPath $csSource) {
    try {
        Say 'Building the Setup .exe...' 'White'
        $exeWork = Join-Path $env:TEMP 'AnomalyModpackExe'
        if (Test-Path -LiteralPath $exeWork) { Remove-Item -LiteralPath $exeWork -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $exeWork | Out-Null
        $payload = Join-Path $exeWork 'payload.zip'
        [IO.Compression.ZipFile]::CreateFromDirectory($Out, $payload, [IO.Compression.CompressionLevel]::Optimal, $false)


        $fw = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
        if (-not (Test-Path -LiteralPath (Join-Path $fw 'csc.exe'))) { $fw = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319' }
        $csc = Join-Path $fw 'csc.exe'
        if (-not (Test-Path -LiteralPath $csc)) { throw "the C# compiler was not found ($csc)" }
        $exeOut = Join-Path $exeWork 'setup.exe'
        $cscArgs = @(
            '/nologo', '/target:winexe', '/optimize+', '/platform:anycpu',
            "/out:$exeOut", "/resource:$payload,payload.zip",
            "/reference:$fw\System.dll", "/reference:$fw\System.Drawing.dll", "/reference:$fw\System.Windows.Forms.dll",
            "/reference:$fw\System.IO.Compression.dll", "/reference:$fw\System.IO.Compression.FileSystem.dll",
            $csSource
        )
        if ($ico -and (Test-Path -LiteralPath $ico)) { $cscArgs = @("/win32icon:$ico", "/resource:$ico,setup.ico") + $cscArgs }
        $cscOut = & $csc @cscArgs 2>&1
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exeOut)) {
            $errFile = Join-Path $Tools 'setup-exe-build-errors.txt'
            [IO.File]::WriteAllLines($errFile, [string[]]@($cscOut | ForEach-Object { "$_" }))
            throw "the C# compiler reported errors - see $errFile"
        }
        $errOld = Join-Path $Tools 'setup-exe-build-errors.txt'
        if (Test-Path -LiteralPath $errOld) { Remove-Item -LiteralPath $errOld -Force }
        $exe = Join-Path (Split-Path -Parent $Root) ("Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_{0}.exe" -f (Get-Date -Format 'yyyy-MM-dd'))
        Copy-Item -LiteralPath $exeOut -Destination $exe -Force
        Remove-Item -LiteralPath $exeWork -Recurse -Force
    } catch {
        $exeError = $_.Exception.Message
        Note "Setup .exe was NOT built: $exeError"
    }
} else { Note 'SetupGui.cs not found next to this script - only the zip was built' }

Remove-Item -LiteralPath $Out -Recurse -Force

Say ''
Say '=== Done ===' 'Green'
Say ("Installer zip : {0}  ({1:N1} MB, of which your own files: {2:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB), ($ovBytes / 1MB)) 'Green'
if ($exe) { Say ("Setup .exe    : {0}  ({1:N1} MB)" -f $exe, ((Get-Item $exe).Length / 1MB)) 'Green' }
elseif ($exeError) { Say "Setup .exe    : NOT built - $exeError" 'Red' }
Say "Report        : $(Join-Path $Tools 'modpack-build-report.txt')" 'Green'
Say ''
foreach ($l in $linkReport) {
    $c = 'Gray'
    if ($l -like 'OK*') { $c = 'Green' } elseif ($l -like 'MISSING*' -or $l -like 'BROKEN*' -or $l -like 'DIFFERENT*') { $c = 'Red' }
    Say $l $c
}
