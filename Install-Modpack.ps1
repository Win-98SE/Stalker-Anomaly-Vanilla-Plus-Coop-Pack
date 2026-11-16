<#
  Install-Modpack.ps1  -  run on a FRIEND'S PC.

  Put the installer in an EMPTY folder (or in an existing Anomaly 1.5.3 folder) and run it.
  0. Finds Anomaly 1.5.3: this folder, a GOG install, or another folder - or downloads it
     from ModDB into this folder
  1. Gets Mod Organizer 2 (portable) and 7-Zip if needed
  2. Downloads every mod archive from its original page (ModDB / GitHub),
     or asks you to download it by hand if that fails, and checks it is the right file
  3. Installs exactly the files the pack owner has, in the same mod folders
  4. Installs the xrRazom engine files into bin\ (originals backed up)
  5. Copies the pack owner's MO2 profile, load order and MCM settings
  Re-running is safe: finished downloads are reused.
#>
param(
    [switch]$FreshDownloads,
    [switch]$Gui,                 # run by the Setup .exe: no console questions, progress as @@ lines
    [string]$Target = '',         # GUI: the Anomaly folder (or the empty folder for a ModDB install)
    [switch]$InstallBase,         # GUI: download/unpack Anomaly 1.5.3 into $Target first
    [switch]$DeleteBaseArchive,   # GUI: delete the 9.1 GB Anomaly download afterwards
    [ValidateSet('en', 'uk', 'ru')][string]$Lang = 'en'   # language of the messages
)
$ErrorActionPreference = 'Stop'
if ($Gui) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    try { [Console]::OutputEncoding = $utf8 } catch { }
    try { [Console]::InputEncoding = $utf8 } catch { }
}
function Emit($kind, $text) {
    # one line per message for the Setup window:  @@KIND|text
    [Console]::Out.WriteLine('@@' + $kind + '|' + (($text -as [string]) -replace '[\r\n]+', ' '))
    [Console]::Out.Flush()
}
trap {
    if ($Gui) {
        $where = ''
        try { $where = " [line $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())]" } catch { }
        Emit 'ERROR' ($_.Exception.Message + $where)
        exit 1
    }
    break
}
# ------------------------------------------------------------------ texts (English / Ukrainian / Russian)
$LangIdx = @{ en = 0; uk = 1; ru = 2 }[$Lang]
if ($LangIdx -eq $null) { $LangIdx = 0 }
$Texts = @{
    st_dl_base      = @('Downloading Anomaly 1.5.3 from ModDB (9.1 GB)...', 'Завантаження Anomaly 1.5.3 з ModDB (9,1 ГБ)...', 'Загрузка Anomaly 1.5.3 с ModDB (9,1 ГБ)...')
    st_wait_base    = @('Waiting for the Anomaly download in your browser...', 'Очікування завантаження Anomaly у браузері...', 'Ожидание загрузки Anomaly в браузере...')
    st_unpack_base  = @('Unpacking Anomaly 1.5.3 (this takes a while)...', 'Розпакування Anomaly 1.5.3 (це займе деякий час)...', 'Распаковка Anomaly 1.5.3 (это займёт некоторое время)...')
    msg_base_done   = @('Anomaly 1.5.3 installed.', 'Anomaly 1.5.3 встановлено.', 'Anomaly 1.5.3 установлена.')
    msg_base_del    = @('Anomaly download deleted.', 'Завантажений архів Anomaly видалено.', 'Скачанный архив Anomaly удалён.')
    msg_base_block  = @('ModDB only allows this download from a real browser.', 'ModDB дозволяє це завантаження лише через браузер.', 'ModDB разрешает эту загрузку только через браузер.')
    msg_found       = @('Found {0}', 'Знайдено {0}', 'Найдено {0}')
    msg_checking    = @('checking {0} (takes a minute or two)...', 'перевірка {0} (займе хвилину-дві)...', 'проверка {0} (займёт минуту-две)...')
    msg_bad_file    = @('that file is damaged or a different version - ignoring it', 'цей файл пошкоджений або іншої версії - пропускаю', 'этот файл повреждён или другой версии - пропускаю')
    msg_dl_damaged  = @('the download is damaged - removing it', 'завантаження пошкоджене - видаляю', 'загрузка повреждена - удаляю')
    st_mo2          = @('Getting Mod Organizer 2 v{0}...', 'Завантаження Mod Organizer 2 v{0}...', 'Загрузка Mod Organizer 2 v{0}...')
    st_checking     = @('Checking / downloading mods...', 'Перевірка / завантаження модів...', 'Проверка / загрузка модов...')
    st_dl_n         = @('Downloading mods - {0} of {1}', 'Завантаження модів - {0} з {1}', 'Загрузка модов - {0} из {1}')
    st_browser      = @('Waiting for downloads in your browser ({0} of {1} done)...', 'Очікування завантажень у браузері (готово {0} з {1})...', 'Ожидание загрузок в браузере (готово {0} из {1})...')
    st_install      = @('Installing mods...', 'Встановлення модів...', 'Установка модов...')
    st_install_n    = @('Installing mods - {0} of {1}', 'Встановлення модів - {0} з {1}', 'Установка модов - {0} из {1}')
    st_settings     = @('Applying the pack settings (profile, load order, MCM settings)...', 'Застосування налаштувань збірки (профіль, порядок завантаження, MCM)...', 'Применение настроек сборки (профиль, порядок загрузки, MCM)...')
    st_cleanup      = @('Cleaning up...', 'Прибирання...', 'Очистка...')
    msg_already     = @('already downloaded', 'вже завантажено', 'уже загружено')
    msg_in_dl       = @('found in your Downloads folder', 'знайдено в папці «Завантаження»', 'найдено в папке «Загрузки»')
    msg_moddb_block = @('ModDB blocks automatic downloads - this one (and the other ModDB mods) will download in your browser.', 'ModDB блокує автоматичні завантаження - цей та інші моди з ModDB завантажаться через браузер.', 'ModDB блокирует автоматические загрузки - этот и другие моды с ModDB загрузятся через браузер.')
    msg_auto_fail   = @('automatic download failed: {0}', 'автоматичне завантаження не вдалося: {0}', 'автоматическая загрузка не удалась: {0}')
    msg_page_diff   = @('the file on the page is not the same version the pack uses', 'файл на сторінці не тієї версії, що використовує збірка', 'файл на странице не той версии, что использует сборка')
    msg_got         = @('got {0}', 'отримано {0}', 'получено {0}')
    msg_skipped     = @('skipped {0}', 'пропущено {0}', 'пропущено {0}')
    msg_skip_diff   = @('skipped {0} (different version)', 'пропущено {0} (інша версія)', 'пропущено {0} (другая версия)')
    gdrive_hint     = @('(Google Drive: right-click the file > Download)', '(Google Диск: клацніть правою кнопкою по файлу > Завантажити)', '(Google Диск: щёлкните правой кнопкой по файлу > Скачать)')
    ask_diff        = @('{0} in your Downloads folder is a different version than the pack uses ({1} MB instead of {2} MB). Use it anyway? (No skips this mod; your file is kept.)',
                        '{0} у папці «Завантаження» іншої версії, ніж у збірці ({1} МБ замість {2} МБ). Все одно використати? (Ні - мод буде пропущено, ваш файл залишиться.)',
                        '{0} в папке «Загрузки» другой версии, чем в сборке ({1} МБ вместо {2} МБ). Всё равно использовать? (Нет - мод будет пропущен, ваш файл останется.)')
    ask_space       = @('About {0} GB free space is recommended, this drive has {1} GB. Continue anyway?', 'Рекомендовано близько {0} ГБ вільного місця, на цьому диску {1} ГБ. Все одно продовжити?', 'Рекомендуется около {0} ГБ свободного места, на этом диске {1} ГБ. Всё равно продолжить?')
    ask_version     = @('This Anomaly does not look like version 1.5.3 (changes152to153.txt is missing). The pack is made for 1.5.3 and co-op needs everyone on the same version. Continue anyway?',
                        'Схоже, це не Anomaly версії 1.5.3 (немає changes152to153.txt). Збірку зроблено для 1.5.3, а для кооперативу всім потрібна однакова версія. Все одно продовжити?',
                        'Похоже, это не Anomaly версии 1.5.3 (нет changes152to153.txt). Сборка сделана для 1.5.3, а для кооператива всем нужна одинаковая версия. Всё равно продолжить?')
    err_space       = @('Stopped: not enough free disk space.', 'Зупинено: недостатньо вільного місця на диску.', 'Остановлено: недостаточно свободного места на диске.')
    err_version     = @('Stopped: this Anomaly is not version 1.5.3.', 'Зупинено: це не Anomaly версії 1.5.3.', 'Остановлено: это не Anomaly версии 1.5.3.')
    err_close_mo2   = @('Close Mod Organizer and the game first, then run Setup again.', 'Спочатку закрийте Mod Organizer і гру, потім запустіть інсталятор знову.', 'Сначала закройте Mod Organizer и игру, затем запустите установщик снова.')
    err_no_anomaly  = @('No Anomaly found in {0} (AnomalyLauncher.exe, bin\ and db\ are missing).', 'У {0} не знайдено Anomaly (немає AnomalyLauncher.exe, bin\ і db\).', 'В {0} не найдена Anomaly (нет AnomalyLauncher.exe, bin\ и db\).')
    err_writable    = @('Windows does not allow changes in {0}. Run Setup as administrator, or install into a normal folder.', 'Windows не дозволяє змінювати {0}. Запустіть інсталятор від імені адміністратора або встановіть у звичайну папку.', 'Windows не разрешает изменять {0}. Запустите установщик от имени администратора или установите в обычную папку.')
    err_base_unpack = @('Anomaly could not be unpacked. Check free disk space and run Setup again.', 'Не вдалося розпакувати Anomaly. Перевірте вільне місце на диску й запустіть інсталятор знову.', 'Не удалось распаковать Anomaly. Проверьте свободное место на диске и запустите установщик снова.')
    err_base_files  = @('The Anomaly archive did not contain the expected files (db\, bin\, AnomalyLauncher.exe).', 'Архів Anomaly не містить потрібних файлів (db\, bin\, AnomalyLauncher.exe).', 'Архив Anomaly не содержит нужных файлов (db\, bin\, AnomalyLauncher.exe).')
    err_base_stop   = @('Stopped while waiting for the Anomaly download. Run Setup again when you are ready.', 'Зупинено під час очікування завантаження Anomaly. Запустіть інсталятор знову, коли будете готові.', 'Остановлено во время ожидания загрузки Anomaly. Запустите установщик снова, когда будете готовы.')
    err_mo2         = @('Mod Organizer 2 could not be unpacked.', 'Не вдалося розпакувати Mod Organizer 2.', 'Не удалось распаковать Mod Organizer 2.')
    err_7z          = @('Could not set up 7-Zip. Install it from https://www.7-zip.org and run Setup again.', 'Не вдалося підготувати 7-Zip. Встановіть його з https://www.7-zip.org і запустіть інсталятор знову.', 'Не удалось подготовить 7-Zip. Установите его с https://www.7-zip.org и запустите установщик снова.')
    prob_missing    = @('{0}: skipped - mods missing: {1}', '{0}: пропущено - не встановлено моди: {1}', '{0}: пропущено - не установлены моды: {1}')
    prob_unpack     = @('{0}: could not be unpacked', '{0}: не вдалося розпакувати', '{0}: не удалось распаковать')
    prob_diff       = @('{0}: installed a different version than the pack owner', '{0}: встановлено іншу версію, ніж у автора збірки', '{0}: установлена другая версия, чем у автора сборки')
    msg_done        = @('=== All done! ===', '=== Готово! ===', '=== Готово! ===')
    msg_done_prob   = @('=== Finished, but with problems: ===', '=== Завершено, але з проблемами: ===', '=== Завершено, но с проблемами: ===')
    msg_retry       = @('Run Setup again to retry (finished downloads are kept), or send this list to the pack owner.', 'Запустіть інсталятор знову, щоб повторити спробу (готові завантаження зберігаються), або надішліть цей список автору збірки.', 'Запустите установщик снова, чтобы повторить попытку (готовые загрузки сохраняются), или отправьте этот список автору сборки.')
    msg_update      = @('Updating the pack: installed {0} -> new {1}', 'Оновлення збірки: встановлено {0} -> нова {1}', 'Обновление сборки: установлена {0} -> новая {1}')
    msg_upd_counts  = @('{0} mod(s) unchanged, {1} updated, {2} new, {3} removed', 'без змін: {0}, оновлено: {1}, нових: {2}, видалено: {3}', 'без изменений: {0}, обновлено: {1}, новых: {2}, удалено: {3}')
    msg_upd_mod     = @('updated: {0}', 'оновлено: {0}', 'обновлено: {0}')
    msg_new_mod     = @('new: {0}', 'новий: {0}', 'новый: {0}')
    msg_removed_mod = @('removed {0} (no longer in the pack)', 'видалено {0} (більше немає у збірці)', 'удалён {0} (больше нет в сборке)')
    msg_removed_dl  = @('deleted old download {0}', 'видалено старе завантаження {0}', 'удалена старая загрузка {0}')
    msg_nothing     = @('All mods are up to date - only the pack settings are refreshed.', 'Усі моди актуальні - оновлюються лише налаштування збірки.', 'Все моды актуальны - обновляются только настройки сборки.')
    msg_unpacking   = @('unpacking...', 'розпакування...', 'распаковка...')
    msg_settings    = @("Game settings applied: the pack owner's settings ({0} lines)", 'Налаштування гри застосовано: налаштування автора збірки ({0} рядків)', 'Настройки игры применены: настройки автора сборки ({0} строк)')
    msg_target      = @('Installing into: {0}', 'Встановлення в: {0}', 'Установка в: {0}')
}
function T($key) {
    $v = $Texts[$key]
    if (-not $v) { return $key }
    $s = $v[$LangIdx]
    if ($args.Count -gt 0) { return ($s -f $args) }
    return $s
}

$script:FailedArchives = New-Object System.Collections.Generic.HashSet[string]
$script:DiffArchives = New-Object System.Collections.Generic.HashSet[string]
$script:StartTime = Get-Date
# this PC's own Downloads folder (follows the user if they moved it to another drive)
$UserDownloads = Join-Path $env:USERPROFILE 'Downloads'
try {
    $v = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'
    if ($v) { $v = [Environment]::ExpandEnvironmentVariables($v); if (Test-Path -LiteralPath $v) { $UserDownloads = $v } }
} catch { }
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Pack = $PSScriptRoot                         # where the installer files are
$Root = $PSScriptRoot                         # the Anomaly folder the pack goes into (decided below)
if ($Gui -and $Target) { $Root = $Target.TrimEnd('\') }
$Overlay = Join-Path $Pack 'modpack_overlay'
# Anomaly 1.5.3 full version on ModDB (same files as the free GOG version)
$BaseGame = [pscustomobject]@{
    file = 'Anomaly-1.5.3-Full.2.7z'
    size = 9742156148
    md5  = 'D6BCE51A4E6D98F9610EF0AA967BA964'
    url  = 'https://www.moddb.com/downloads/start/277404'
    page = 'https://www.moddb.com/mods/stalker-anomaly/downloads/stalker-anomaly-153'
}
$GogPage = 'https://www.gog.com/en/game/stalker_anomaly'
$GogProductId = '1700809445'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
$Problems = New-Object System.Collections.Generic.List[string]

function Say($msg, $color = 'Gray') {
    if ($Gui) { Emit 'LOG' ($color + '|' + $msg) } else { Write-Host $msg -ForegroundColor $color }
}
function Status($msg) { if ($Gui) { Emit 'STATUS' $msg } else { Write-Host $msg -ForegroundColor White } }
function Progress($cur, $max) { if ($Gui) { Emit 'PROGRESS' ("$cur|$max") } }
function Ask($question) {
    # a Y/N question; returns $true for yes
    if ($Gui) { Emit 'ASK' $question; $ans = [Console]::In.ReadLine() }
    else { $ans = Read-Host "$question (Y/N)" }
    return ($ans -match '^[yY]')
}
function Open-Url($url) {
    # open a web page in the default browser (works even without a console window)
    try { [Diagnostics.Process]::Start((New-Object Diagnostics.ProcessStartInfo -Property @{ FileName = $url; UseShellExecute = $true })) | Out-Null }
    catch { Start-Process 'explorer.exe' -ArgumentList ('"' + $url + '"') }
}
function Pause-ForUser($msg) { if (-not $Gui) { Read-Host $msg | Out-Null } }
function Test-SkipRequest {
    # console: S key; GUI: the window drops a skip.flag file next to this script
    if ($Gui) {
        $f = Join-Path $Pack 'skip.flag'
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; return $true }
        return $false
    }
    try {
        if ([Console]::KeyAvailable) { $k = [Console]::ReadKey($true); return ($k.KeyChar -eq 's' -or $k.KeyChar -eq 'S') }
    } catch { }
    return $false
}
function Test-ReopenRequest {
    if (-not $Gui) { return $false }
    $f = Join-Path $Pack 'reopen.flag'
    if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; return $true }
    return $false
}
function Problem($msg) { $Problems.Add($msg); Say "  ! $msg" 'Red' }

function Download($url, $outFile) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        if ($Gui) { & $curl.Source -sS -L --fail --retry 3 -A $UA -o $outFile $url 2>&1 | Out-Null }
        else { & $curl.Source -L --fail --retry 3 -A $UA -o $outFile $url }
        if ($LASTEXITCODE -ne 0) { throw "download failed (curl exit $LASTEXITCODE)" }
    } else {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UserAgent $UA -UseBasicParsing
    }
}

function Get-Page($url) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $old = [Console]::OutputEncoding
        try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
        try {
            $out = & $curl.Source -sSL --compressed --fail --max-time 60 -A $UA `
                -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' `
                -H 'Accept-Language: en-US,en;q=0.9' -H 'Upgrade-Insecure-Requests: 1' $url 2>&1
        } finally { try { [Console]::OutputEncoding = $old } catch { } }
        if ($LASTEXITCODE -ne 0) { throw "page request failed (curl exit $LASTEXITCODE): $(($out | Select-Object -Last 1))" }
        return ($out -join "`n")
    }
    return (Invoke-WebRequest -Uri $url -UserAgent $UA -UseBasicParsing -TimeoutSec 60).Content
}

function Find-7z {
    foreach ($c in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe", (Join-Path $Root '_modpack_tools\7z\7z.exe'))) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    $tools = Join-Path $Root '_modpack_tools'
    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    Say 'Getting 7-Zip (used to unpack the mods)...'
    Download 'https://www.7-zip.org/a/7zr.exe' (Join-Path $tools '7zr.exe')
    Download 'https://www.7-zip.org/a/7z2409-x64.exe' (Join-Path $tools '7z-x64.exe')
    & (Join-Path $tools '7zr.exe') x -y "-o$tools\7z" (Join-Path $tools '7z-x64.exe') | Out-Null
    $exe = Join-Path $tools '7z\7z.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw (T 'err_7z') }
    return $exe
}

function Test-ArchiveOk($path, $a) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    if ((Get-Item -LiteralPath $path).Length -ne [int64]$a.size) { return $false }
    if ($a.md5) { return ((Get-FileHash -LiteralPath $path -Algorithm MD5).Hash -eq $a.md5) }
    return ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $a.sha256)
}

# ------------------------------------------------------------------ base game (Anomaly 1.5.3)
function Test-AnomalyDir($d) {
    return ($d -and (Test-Path -LiteralPath (Join-Path $d 'db')) -and (Test-Path -LiteralPath (Join-Path $d 'bin')) -and
            (Test-Path -LiteralPath (Join-Path $d 'AnomalyLauncher.exe')))
}

function Find-GogAnomaly {
    foreach ($k in @("HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\$GogProductId", "HKLM:\SOFTWARE\GOG.com\Games\$GogProductId")) {
        try {
            $p = (Get-ItemProperty -LiteralPath $k -ErrorAction Stop).path
            if ($p -and (Test-AnomalyDir $p)) { return $p.TrimEnd('\') }
        } catch { }
    }
    return $null
}

function Test-Writable($d) {
    try {
        $t = Join-Path $d ('_modpack_write_test_' + [guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($t, 'x'); Remove-Item -LiteralPath $t -Force
        return $true
    } catch { return $false }
}

$script:BadBase = New-Object System.Collections.Generic.HashSet[string]
function Find-BaseArchive {
    # the exact file in this folder or the user's Downloads (any name - browsers sometimes add " (1)")
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($d in @(@($Pack, $Root, $UserDownloads) | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $d)) { continue }
        Get-ChildItem -LiteralPath $d -Filter '*.7z' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -eq $BaseGame.size } | ForEach-Object { $cands.Add($_.FullName) }
    }
    foreach ($c in $cands) {
        $key = $c + '|' + (Get-Item -LiteralPath $c).LastWriteTimeUtc.Ticks
        if ($script:BadBase.Contains($key)) { continue }
        Say ('   ' + (T 'msg_checking' $c)) 'DarkGray'
        if (Test-ArchiveOk $c $BaseGame) { return $c }
        Say ('   ' + (T 'msg_bad_file')) 'Yellow'
        [void]$script:BadBase.Add($key)
    }
    return $null
}

function Get-BaseGame {
    $arc = Find-BaseArchive
    if (-not $arc) {
        # try a direct download first (ModDB usually refuses scripts)
        $target = Join-Path $Root $BaseGame.file
        try {
            Status (T 'st_dl_base')
            Get-ModDBFile $BaseGame.url "$target.part"
            Move-Item -LiteralPath "$target.part" -Destination $target -Force
            if (Test-ArchiveOk $target $BaseGame) { $arc = $target }
            else { Say ('   ' + (T 'msg_dl_damaged')) 'Yellow'; Remove-Item -LiteralPath $target -Force }
        } catch {
            if (Test-Path -LiteralPath "$target.part") { Remove-Item -LiteralPath "$target.part" -Force }
            Say ('   ' + (T 'msg_base_block')) 'Yellow'
        }
    }
    while (-not $arc) {
        if (-not $Gui) {
        Say ''
        Say '=== Download Anomaly 1.5.3 in your browser ===' 'Cyan'
        Say "A ModDB page opens and the download ($($BaseGame.file), 9.1 GB) starts by itself" 'Cyan'
        Say 'after a few seconds. If it does not, click the download link on the page.' 'Cyan'
        Say "Let it save to your Downloads folder ($UserDownloads)." 'Cyan'
        Say 'This window notices when the download has finished - leave it open.' 'Cyan'
        }
        Pause-ForUser 'Press Enter to open the page'
        Open-Url $BaseGame.url
        Status (T 'st_wait_base')
        if ($Gui) { Emit 'BROWSER' "1|$($BaseGame.file) (9.1 GB)" }
        else { Say 'Waiting for the download... (press S to stop)' 'White' }
        while ($true) {
            $done = Get-ChildItem -LiteralPath $UserDownloads -Filter '*.7z' -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Length -eq $BaseGame.size }
            if ($done) { Start-Sleep -Seconds 3; $arc = Find-BaseArchive; if ($arc) { break } }
            if (Test-ReopenRequest) { Open-Url $BaseGame.url }
            if (Test-SkipRequest) { throw (T 'err_base_stop') }
            Start-Sleep -Seconds 5
        }
        if ($Gui) { Emit 'BROWSER' '0|' }
    }
    Say (T 'msg_found' $arc) 'Green'
    $unpack = Join-Path $Root '_anomaly_unpack'
    if (Test-Path -LiteralPath $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force }
    Status (T 'st_unpack_base')
    & $sevenZip x -y "-o$unpack" -- $arc | Out-Null
    if ($LASTEXITCODE -gt 1) { throw (T 'err_base_unpack') }
    # the archive may or may not have a top folder: find the folder with db\ and bin\ in it
    $game = $null
    foreach ($d in @(@(Get-Item -LiteralPath $unpack) + @(Get-ChildItem -LiteralPath $unpack -Directory -Recurse -Depth 2))) {
        if (Test-AnomalyDir $d.FullName) { $game = $d.FullName; break }
    }
    if (-not $game) { throw (T 'err_base_files') }
    foreach ($item in (Get-ChildItem -LiteralPath $game -Force)) {
        $dst = Join-Path $Root $item.Name
        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
        Move-Item -LiteralPath $item.FullName -Destination $dst
    }
    Remove-Item -LiteralPath $unpack -Recurse -Force
    Say (T 'msg_base_done') 'Green'
    $del = if ($Gui) { [bool]$DeleteBaseArchive } else { Ask "Delete the 9.1 GB Anomaly download ($arc) now? You only need it to reinstall." }
    if ($del) { Remove-Item -LiteralPath $arc -Force; Say (T 'msg_base_del') 'DarkGray' }
}

function Get-ModDBFile($page, $outFile) {
    $start = $null
    if ($page -match '/(addons|downloads)/start/\d+') { $start = $page; $html = '' } else { $html = Get-Page $page }
    if (-not $start -and $html -match 'href="((?:https://www\.moddb\.com)?/(?:downloads|addons)/start/\d+[^"]*)"') { $start = $Matches[1] }
    if (-not $start) { throw 'no download button found on the page' }
    if ($start.StartsWith('/')) { $start = 'https://www.moddb.com' + $start }
    $html2 = Get-Page $start
    if ($html2 -notmatch 'href="(/downloads/mirror/[^"]+)"') { throw 'no download mirror found' }
    Download ('https://www.moddb.com' + $Matches[1]) $outFile
}

function Get-ArchiveAuto($a) {
    $target = Join-Path $Downloads $a.file
    if (Test-ArchiveOk $target $a) { Say ('      ' + (T 'msg_already')) 'DarkGray'; return $target }
    # maybe the friend already has it in their own Downloads folder
    $own = Join-Path $UserDownloads $a.file
    if (-not $FreshDownloads -and (Test-ArchiveOk $own $a)) { Copy-Item -LiteralPath $own -Destination $target -Force; Say ('      ' + (T 'msg_in_dl')) 'DarkGray'; return $target }

    if ($a.url -match 'drive\.google\.com/drive/folders') { return $null }   # a shared folder: download by hand
    if ($a.url) {
        $part = "$target.part"
        try {
            if ($a.url -match 'moddb\.com/' -and $a.url -notmatch '/downloads/mirror/') {
                if ($script:ModDBBlocked) { return $null }
                Get-ModDBFile $a.url $part
            }
            else { Download $a.url $part }
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
            Move-Item -LiteralPath $part -Destination $target
            if (Test-ArchiveOk $target $a) { return $target }
            Say ('      ' + (T 'msg_page_diff')) 'Yellow'
            Rename-Item -LiteralPath $target -NewName ($a.file + '.wrong-version') -Force
        } catch {
            if ($_.Exception.Message -match '403') {
                $script:ModDBBlocked = $true
                Say ('      ' + (T 'msg_moddb_block')) 'Yellow'
            } else { Say ('      ' + (T 'msg_auto_fail' $_.Exception.Message)) 'Yellow' }
            if (Test-Path -LiteralPath $part) { Remove-Item -LiteralPath $part -Force }
        }
    }

    return $null
}

function Get-ManualBatch($list) {
    $pending = New-Object System.Collections.Generic.List[object]
    foreach ($a in $list) { $pending.Add($a) }
    $total = $pending.Count
    if (-not $Gui) {
    Say ''
    Say "=== $total mod(s) will download through your web browser ===" 'Cyan'
    Say 'ModDB only allows downloads from a real browser, so their download pages open a few' 'Cyan'
    Say 'at a time and the downloads START BY THEMSELVES after a few seconds.' 'Cyan'
    Say 'If one does not start, click its download link. If a Google Drive folder opens,' 'Cyan'
    Say 'download the file with the name shown below.' 'Cyan'
    Say "Save everything to: $UserDownloads   (or $Downloads)" 'Cyan'
    Say 'This window notices each file by itself - no need to come back and press anything.' 'Cyan'
    foreach ($a in $pending) { Say ("   - {0}  ({1:N1} MB)" -f $a.file, ([int64]$a.size / 1MB)) }
    }
    Pause-ForUser 'Press Enter to start opening the pages'
    $got = @{}
    $sizeSeen = @{}
    $askedAbout = @{}
    $doneCount = 0
    $groupSize = 5
    for ($g = 0; $g -lt $pending.Count; $g += $groupSize) {
        # plain arrays only: @() around a generic List breaks in Windows PowerShell 5.1
        $last = [math]::Min($g + $groupSize, $pending.Count) - 1
        $groupList = New-Object System.Collections.Generic.List[object]
        for ($q = $g; $q -le $last; $q++) { $groupList.Add($pending[$q]) }
        $group = $groupList.ToArray()
        $openGroup = {
            param($items)
            foreach ($it in @($items | ForEach-Object { $_ })) {
                if ($it.url -match '^https?://') { $u = ($it.url -replace '/archive/refs/heads/.*$', '') }
                else { $u = 'https://www.moddb.com/search?q=' + [uri]::EscapeDataString(($it.file -replace '\.(zip|7z|rar)$', '' -replace '[._-]+', ' ')) }
                Open-Url $u
                Start-Sleep -Milliseconds 800
            }
        }
        & $openGroup $group
        Status (T 'st_browser' $doneCount $total)
        if (-not $Gui) { Say '(press S to skip the ones still missing in this group)' 'White' }
        $waiting = New-Object System.Collections.Generic.List[object]
        foreach ($a in $group) { $waiting.Add($a) }
        $lastShown = ''
        while ($waiting.Count -gt 0) {
            if ($Gui) {
                $names = @($waiting.ToArray() | ForEach-Object {
                    if ($_.url -match 'drive\.google\.com') { $_.file + '  ' + (T 'gdrive_hint') } else { $_.file }
                })
                $now = $names -join ' ;; '
                if ($now -ne $lastShown) { Emit 'BROWSER' ("{0}|{1}" -f $names.Count, $now); $lastShown = $now }
            }
            foreach ($a in $waiting.ToArray()) {
                $target = Join-Path $Downloads $a.file
                $own = Join-Path $UserDownloads $a.file
                $ext = [IO.Path]::GetExtension($a.file); $base = $a.file.Substring(0, $a.file.Length - $ext.Length)
                $dupes = @(Get-ChildItem -LiteralPath $UserDownloads -Filter ($base + ' (*)' + $ext) -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
                foreach ($p in (@($own, $target) + $dupes)) {
                    if (-not (Test-Path -LiteralPath $p)) { continue }
                    if ($FreshDownloads -and $p -ne $target -and (Get-Item -LiteralPath $p).LastWriteTime -lt $script:StartTime) { continue }
                    if ((Get-Item -LiteralPath $p).Length -ne [int64]$a.size) { continue }   # still downloading or other version
                    if ($p -ne $target) { Copy-Item -LiteralPath $p -Destination $target -Force }
                    if (Test-ArchiveOk $target $a) {
                        Say ('   ' + (T 'msg_got' $a.file)) 'Green'
                        $got[$a.file] = $target; [void]$waiting.Remove($a)
                        $doneCount++; Progress $doneCount $total; Status (T 'st_browser' $doneCount $total)
                    }
                    break
                }
                # a finished file with the right name but the wrong size = different version.
                # Browsers leave placeholders while downloading (Firefox: an empty file plus a
                # "name.random.part"; Chrome/Edge: ".crdownload"), so only ask when nothing is
                # still downloading and the file has had the same non-zero size for a while.
                if ($waiting.Contains($a) -and (Test-Path -LiteralPath $own)) {
                    $fi = Get-Item -LiteralPath $own
                    $busy = @(Get-ChildItem -LiteralPath $UserDownloads -File -ErrorAction SilentlyContinue |
                        Where-Object { ($_.Extension -in '.part', '.crdownload', '.tmp', '.partial') -and $_.LastWriteTime -gt (Get-Date).AddSeconds(-60) }).Count -gt 0
                    $key = $own.ToLowerInvariant()
                    $prev = $sizeSeen[$key]
                    $sizeSeen[$key] = $fi.Length
                    $stable = ($prev -ne $null) -and ($prev -eq $fi.Length) -and ((Get-Date) - $fi.LastWriteTime).TotalSeconds -gt 30
                    if (-not $busy -and $stable -and $fi.Length -gt 0 -and $fi.Length -ne [int64]$a.size -and -not $askedAbout.ContainsKey($key)) {
                        $askedAbout[$key] = $true
                        if (Ask (T 'ask_diff' $a.file ([math]::Round($fi.Length / 1MB, 1)) ([math]::Round([int64]$a.size / 1MB, 1)))) {
                            Copy-Item -LiteralPath $own -Destination (Join-Path $Downloads $a.file) -Force
                            Problem (T 'prob_diff' $a.file); [void]$script:DiffArchives.Add($a.file)
                            $got[$a.file] = (Join-Path $Downloads $a.file); [void]$waiting.Remove($a)
                            $doneCount++; Progress $doneCount $total
                        } else {
                            Say ('   ' + (T 'msg_skip_diff' $a.file)) 'Yellow'
                            [void]$waiting.Remove($a)
                        }
                    }
                }
            }
            if ($waiting.Count -eq 0) { break }
            if (Test-ReopenRequest) { & $openGroup $waiting.ToArray() }
            if (Test-SkipRequest) {
                foreach ($a in $waiting) { Say ('   ' + (T 'msg_skipped' $a.file)) 'Yellow' }
                break
            }
            Start-Sleep -Seconds 2
        }
    }
    if ($Gui) { Emit 'BROWSER' '0|' }
    return $got
}

function Copy-File($src, $dst, $backupRoot) {
    $dir = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if ($backupRoot -and (Test-Path -LiteralPath $dst)) {
        $rel = $dst.Substring($Root.Length).TrimStart('\')
        $b = Join-Path $backupRoot $rel
        if (-not (Test-Path -LiteralPath $b)) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b) | Out-Null
            [IO.File]::Copy($dst, $b, $false)
        }
    }
    [IO.File]::Copy($src, $dst, $true)
}

function Apply-Rules($extracted, $rules, $destBase, $label, $backupRoot) {
    $count = 0
    foreach ($r in @($rules)) {
        $srcDir = if ($r.src) { Join-Path $extracted ($r.src.Replace('/', '\')) } else { $extracted }
        $dstDir = if ($r.dest) { Join-Path $destBase ($r.dest.Replace('/', '\')) } else { $destBase }
        if ($r.all) {
            if (-not (Test-Path -LiteralPath $srcDir)) { Problem "$label : folder '$($r.src)' missing in archive"; continue }
            $baseLen = (Resolve-Path -LiteralPath $srcDir).ProviderPath.TrimEnd('\').Length + 1
            foreach ($f in (Get-ChildItem -LiteralPath $srcDir -Recurse -File -Force)) {
                Copy-File $f.FullName (Join-Path $dstDir $f.FullName.Substring($baseLen)) $backupRoot
                $count++
            }
        } else {
            foreach ($t in @($r.files)) {
                $s = Join-Path $srcDir ($t.Replace('/', '\'))
                if (-not (Test-Path -LiteralPath $s)) { Problem "$label : '$($r.src)/$t' missing in archive"; continue }
                Copy-File $s (Join-Path $dstDir ($t.Replace('/', '\'))) $backupRoot
                $count++
            }
        }
    }
    return $count
}

# ------------------------------------------------------------------ start
Say ''
Say '=== Stalker Anomaly Vanilla+ Coop Pack - installer ===' 'Cyan'
$manifestPath = Join-Path $Pack 'modpack.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'modpack.json is missing - extract the WHOLE installer zip into one folder and run Install Modpack.bat from there.' }
if (Get-Process ModOrganizer, AnomalyDX11, AnomalyDX11AVX, AnomalyDX10, AnomalyDX10AVX, AnomalyDX9, AnomalyDX9AVX, AnomalyDX8, AnomalyDX8AVX -ErrorAction SilentlyContinue) {
    throw (T 'err_close_mo2')
}

# ---- where is Anomaly?
$doBase = $false
if ($Gui) {
    # the Setup window already asked; just check what it sent
    if (-not $Target) { throw 'No install folder was given.' }
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    $Root = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd('\')
    if ($InstallBase -and -not (Test-AnomalyDir $Root)) { $doBase = $true }
    elseif (-not (Test-AnomalyDir $Root)) { throw (T 'err_no_anomaly' $Root) }
} elseif (Test-AnomalyDir $Pack) {
    Say "Anomaly found in this folder: $Pack"
} else {
    $gog = Find-GogAnomaly
    Say ''
    Say 'This folder has no Anomaly in it yet. Choose how to get it:' 'White'
    $choices = @{}
    if ($gog) { Say "  [1] Use your GOG copy of Anomaly in $gog  (the pack is installed into that folder)"; $choices['1'] = 'gog' }
    Say '  [2] Download Anomaly 1.5.3 from ModDB into THIS folder  (9.1 GB download, about 30 GB free space needed)'; $choices['2'] = 'moddb'
    if (-not $gog) { Say '  [3] Get Anomaly free on GOG instead  (opens the GOG page - install it there, then run this again)'; $choices['3'] = 'gogpage' }
    Say '  [4] I already have Anomaly 1.5.3 in another folder  (type its path)'; $choices['4'] = 'path'
    $pick = $null
    while (-not $pick) { $ans = (Read-Host 'Your choice').Trim(); if ($choices.ContainsKey($ans)) { $pick = $choices[$ans] } }
    switch ($pick) {
        'gog'     { $Root = $gog }
        'moddb'   { $doBase = $true }
        'gogpage' { Start-Process $GogPage; Say 'Install Anomaly from GOG (free), then run Install Modpack.bat again and pick your GOG copy.' 'Cyan'; Read-Host 'Press Enter to close' | Out-Null; exit 0 }
        'path'    {
            while ($true) {
                $pth = (Read-Host 'Path of your Anomaly folder (the one with AnomalyLauncher.exe)').Trim().Trim('"').TrimEnd('\')
                if (Test-AnomalyDir $pth) { $Root = (Resolve-Path -LiteralPath $pth).ProviderPath; break }
                Say "   No Anomaly found in '$pth' - try again." 'Yellow'
            }
        }
    }
}
if (-not (Test-Writable $Root)) {
    if ($Gui) { throw (T 'err_writable' $Root) }
    throw "Windows does not allow changes in $Root (it is probably inside Program Files). Close this window, right-click 'Install Modpack.bat' and choose 'Run as administrator' - or pick option 2 to install a separate copy in a normal folder."
}
if ($Root -ne $Pack) { Say "The pack will be installed into: $Root" 'White' }
$Downloads = Join-Path $Root 'downloads'
$Tmp = Join-Path $Root '_modpack_tmp'
$Backup = Join-Path $Root '_modpack_backup'
$m = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
Say "Pack: $($m.name)   (built $($m.created))"
$needGB = [math]::Round(((@($m.archives) | Measure-Object size -Sum).Sum * 2.5) / 1GB, 1)
if ($doBase) { $needGB += 30 }   # Anomaly download + unpacked game
$drive = (Get-Item -LiteralPath $Root).PSDrive
if ($drive -and $drive.Free -and ($drive.Free / 1GB) -lt $needGB) {
    if (-not (Ask (T 'ask_space' $needGB ([math]::Round($drive.Free / 1GB, 1))))) { throw (T 'err_space') }
}
New-Item -ItemType Directory -Force -Path $Downloads, $Tmp | Out-Null
$sevenZip = Find-7z

if ($doBase) { Get-BaseGame }
if (-not (Test-Path -LiteralPath (Join-Path $Root 'changes152to153.txt'))) {
    if (-not (Ask (T 'ask_version'))) { throw (T 'err_version') }
}

# ------------------------------------------------------------------ MO2
if (-not (Test-Path -LiteralPath (Join-Path $Root 'ModOrganizer.exe'))) {
    Status (T 'st_mo2' $m.mo2.version)
    $moArc = Join-Path $Downloads ("Mod.Organizer-{0}.7z" -f $m.mo2.version)
    if (-not (Test-Path -LiteralPath $moArc)) { Download $m.mo2.url $moArc }
    & $sevenZip x -y "-o$Root" $moArc | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $Root 'ModOrganizer.exe'))) { throw (T 'err_mo2') }
} else { Say 'Mod Organizer 2 already present.' }

# ------------------------------------------------------------------ mods
# An earlier install of the pack leaves modpack_installed.json: mods whose archive and recipe
# did not change are kept as they are, so an update only touches what changed.
$modsDir = Join-Path $Root 'mods'
New-Item -ItemType Directory -Force -Path $modsDir | Out-Null
$recordPath = Join-Path $Root 'modpack_installed.json'
$prev = $null
if (-not $doBase -and (Test-Path -LiteralPath $recordPath)) {
    try { $prev = [IO.File]::ReadAllText($recordPath) | ConvertFrom-Json } catch { $prev = $null }
}
$archSha = @{}
foreach ($a in @($m.archives)) { $archSha[$a.file] = $a.sha256 }
function Get-ModSig($mod) {
    $recipe = (ConvertTo-Json -InputObject @{ r = $mod.rules; h = $mod.hide } -Depth 12 -Compress)
    $sha = [Security.Cryptography.SHA256]::Create()
    $h = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($recipe))).Replace('-', '')
    $as = ''
    if ($mod.archive) { $as = $archSha[$mod.archive] }
    return ("{0}|{1}|{2}" -f $mod.archive, $as, $h)
}
$prevSig = @{}
if ($prev) { foreach ($pm in @($prev.mods)) { if ($pm.name) { $prevSig[$pm.name] = $pm.sig } } }
$newNames = @{}
$keep = @{}
$countUpd = 0; $countNew = 0; $countSame = 0; $countRemoved = 0
$byArchive = @{}
foreach ($mod in @($m.mods)) {
    $newNames[$mod.name] = $true
    $sig = Get-ModSig $mod
    $md = Join-Path $modsDir $mod.name
    if ($prevSig.ContainsKey($mod.name) -and $prevSig[$mod.name] -eq $sig -and (Test-Path -LiteralPath $md)) {
        $keep[$mod.name] = $true; $countSame++
        continue
    }
    if ($prev) {
        if ($prevSig.ContainsKey($mod.name)) { $countUpd++; Say ('   ' + (T 'msg_upd_mod' $mod.name)) 'White' }
        else { $countNew++; Say ('   ' + (T 'msg_new_mod' $mod.name)) 'White' }
    }
    if ($mod.archive) {
        if (-not $byArchive.ContainsKey($mod.archive)) { $byArchive[$mod.archive] = New-Object System.Collections.Generic.List[object] }
        $byArchive[$mod.archive].Add($mod)
    }
    # start every changed pack mod from a clean folder
    if (Test-Path -LiteralPath $md) { Remove-Item -LiteralPath $md -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $md | Out-Null
}
if ($prev) {
    # mods the previous version installed that are no longer in the pack
    foreach ($name in @($prevSig.Keys)) {
        if ($newNames.ContainsKey($name)) { continue }
        $old = Join-Path $modsDir $name
        if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Recurse -Force }
        $countRemoved++
        Say ('   ' + (T 'msg_removed_mod' $name)) 'Yellow'
    }
    Say (T 'msg_update' $prev.created $m.created) 'Cyan'
    Say (T 'msg_upd_counts' $countSame $countUpd $countNew $countRemoved) 'Cyan'
}
# archives needed: those of changed mods, plus the xrRazom engine archive (always re-applied,
# because a GOG update or "Verify / Repair" can put the original engine files back)
$needed = New-Object System.Collections.Generic.List[object]
foreach ($a in @($m.archives)) {
    if ($byArchive.ContainsKey($a.file) -or ($m.root -and $m.root.archive -eq $a.file)) { $needed.Add($a) }
}
$neededArr = $needed.ToArray()
if ($prev -and $byArchive.Count -eq 0) { Say (T 'msg_nothing') 'Green' }

$script:ModDBBlocked = $false
$have = @{}
$needManual = New-Object System.Collections.Generic.List[object]
$i = 0
$total = $neededArr.Count
Status (T 'st_checking')
foreach ($a in $neededArr) {
    $i++
    Say ("[{0}/{1}] {2}" -f $i, $total, $a.file) 'White'
    Status (T 'st_dl_n' $i $total)
    Progress ($i - 1) $total
    $p = Get-ArchiveAuto $a
    if ($p) { $have[$a.file] = $p } else { $needManual.Add($a) }
}
if ($needManual.Count -gt 0) {
    Progress 0 $needManual.Count
    $got = Get-ManualBatch $needManual
    foreach ($k in $got.Keys) { $have[$k] = $got[$k] }
}

Say ''
Status (T 'st_install')
$i = 0
foreach ($a in $neededArr) {
    $i++
    Say ("[{0}/{1}] {2}" -f $i, $total, $a.file) 'White'
    Status (T 'st_install_n' $i $total)
    Progress ($i - 1) $total
    $path = $have[$a.file]
    if (-not $path) {
        Problem (T 'prob_missing' $a.file (@($a.mods) -join ', '))
        [void]$script:FailedArchives.Add($a.file)
        continue
    }
    $ex = Join-Path $Tmp ('a' + $i)
    if (Test-Path -LiteralPath $ex) { Remove-Item -LiteralPath $ex -Recurse -Force }
    Say ('      ' + (T 'msg_unpacking')) 'DarkGray'
    & $sevenZip x -y "-o$ex" -- $path | Out-Null
    if ($LASTEXITCODE -gt 1) { Problem (T 'prob_unpack' $a.file); [void]$script:FailedArchives.Add($a.file); continue }
    if ($byArchive.ContainsKey($a.file)) {
        foreach ($mod in $byArchive[$a.file]) {
            $md = Join-Path $modsDir $mod.name
            $c = Apply-Rules $ex $mod.rules $md $mod.name $null
            foreach ($h in @($mod.hide)) {
                if (-not $h) { continue }
                $hp = Join-Path $md ($h.Replace('/', '\'))
                if (Test-Path -LiteralPath $hp) { Move-Item -LiteralPath $hp -Destination "$hp.mohidden" -Force }
            }
            Say "      -> $($mod.name): $c" 'DarkGray'
        }
    }
    if ($m.root -and $m.root.archive -eq $a.file) {
        $c = Apply-Rules $ex $m.root.rules $Root 'xrRazom engine' $Backup
        Say "      -> xrRazom: bin\ + gamedata\  ($c)" 'DarkGray'
    }
    Remove-Item -LiteralPath $ex -Recurse -Force
}
Progress 1 1

# ------------------------------------------------------------------ pack owner's own files
Progress 1 1
Status (T 'st_settings')
if (Test-Path -LiteralPath $Overlay) {
    $baseLen = (Resolve-Path -LiteralPath $Overlay).ProviderPath.TrimEnd('\').Length + 1
    foreach ($f in (Get-ChildItem -LiteralPath $Overlay -Recurse -File -Force)) {
        $rel = $f.FullName.Substring($baseLen)
        if ($rel -like 'root\*') { Copy-File $f.FullName (Join-Path $Root $rel.Substring(5)) $Backup }
        elseif ($rel -ieq 'ModOrganizer.ini' -or $rel -ieq 'modpack_settings.ltx') { continue }
        else { Copy-File $f.FullName (Join-Path $Root $rel) $null }
    }
    $iniSrc = Join-Path $Overlay 'ModOrganizer.ini'
    if (Test-Path -LiteralPath $iniSrc) {
        $iniDst = Join-Path $Root 'ModOrganizer.ini'
        if (Test-Path -LiteralPath $iniDst) { Copy-Item -LiteralPath $iniDst -Destination "$iniDst.before-modpack" -Force }
        $t = [IO.File]::ReadAllText($iniSrc)
        $t = $t.Replace('{ROOT_BSL2}', $Root.Replace('\', '\\')).Replace('{ROOT_FWD}', $Root.Replace('\', '/')).Replace('{ROOT_BSL}', $Root)
        [IO.File]::WriteAllText($iniDst, $t)
    }
}

# ------------------------------------------------------------------ game settings
# Same as typing "cfg_load Atmos_Neutral" in the console, then the pack owner's game settings
# (everything except keys, resolution/monitor, sound device, mouse and co-op name/host settings).
$settingsLines = New-Object System.Collections.Generic.List[string]
$atmos = Join-Path $modsDir 'Atmospherics Anomaly\appdata\Atmos_Neutral.ltx'
if (Test-Path -LiteralPath $atmos) { foreach ($l in [IO.File]::ReadAllLines($atmos)) { if ($l.Trim()) { $settingsLines.Add($l.Trim()) } } }
$packSettings = Join-Path $Overlay 'modpack_settings.ltx'
if (Test-Path -LiteralPath $packSettings) { foreach ($l in [IO.File]::ReadAllLines($packSettings)) { if ($l.Trim()) { $settingsLines.Add($l.Trim()) } } }
if ($settingsLines.Count -gt 0) {
    $appdata = Join-Path $Root 'appdata'
    New-Item -ItemType Directory -Force -Path $appdata | Out-Null
    $ultx = Join-Path $appdata 'user.ltx'
    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $ultx) {
        Copy-Item -LiteralPath $ultx -Destination "$ultx.before-modpack" -Force
        foreach ($l in [IO.File]::ReadAllLines($ultx)) { $lines.Add($l) }
    }
    foreach ($set in $settingsLines) {
        $key = ($set -split '\s+', 2)[0]
        $idx = -1
        for ($k = 0; $k -lt $lines.Count; $k++) { if (($lines[$k] -split '\s+', 2)[0] -eq $key) { $idx = $k; break } }
        if ($idx -ge 0) { $lines[$idx] = $set } else { $lines.Add($set) }
    }
    [IO.File]::WriteAllLines($ultx, [string[]]$lines)
    Say (T 'msg_settings' $settingsLines.Count) 'DarkGray'
}

# ------------------------------------------------------------------ remember what is installed
Status (T 'st_cleanup')
# old archives of the previous pack version that this version no longer uses
$curFiles = @{}
foreach ($a in @($m.archives)) { $curFiles[$a.file] = $true }
if ($prev) {
    foreach ($f in @($prev.archives)) {
        if (-not $f -or $curFiles.ContainsKey($f)) { continue }
        $old = Join-Path $Downloads $f
        if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Force; Say ('   ' + (T 'msg_removed_dl' $f)) 'DarkGray' }
        foreach ($extra in @("$old.meta", "$old.wrong-version")) { if (Test-Path -LiteralPath $extra) { Remove-Item -LiteralPath $extra -Force } }
    }
}
# record of this install (mods that failed or used a different file are left out, so the next run redoes them)
$recMods = New-Object System.Collections.Generic.List[object]
foreach ($mod in @($m.mods)) {
    if ($mod.archive -and ($script:FailedArchives.Contains($mod.archive) -or $script:DiffArchives.Contains($mod.archive))) { continue }
    $recMods.Add([pscustomobject]@{ name = $mod.name; sig = (Get-ModSig $mod) })
}
$record = [ordered]@{}
$record['name'] = $m.name
$record['created'] = $m.created
$record['github'] = $m.github
$record['installedAt'] = (Get-Date).ToString('yyyy-MM-dd HH:mm')
$record['archives'] = [string[]]@(@($m.archives) | ForEach-Object { $_.file })
$record['mods'] = $recMods.ToArray()
[IO.File]::WriteAllText($recordPath, ($record | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))

# ------------------------------------------------------------------ finish
Get-ChildItem -LiteralPath $Root -File -Include *.exe, *.dll -Recurse -Depth 2 -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "$modsDir\*" } | Unblock-File -ErrorAction SilentlyContinue
$sc = Join-Path $Root 'appdata\shaders_cache'
if (Test-Path -LiteralPath $sc) { Remove-Item -LiteralPath $sc -Recurse -Force }
if (Test-Path -LiteralPath $Tmp) { Remove-Item -LiteralPath $Tmp -Recurse -Force }
try {
    $ws = New-Object -ComObject WScript.Shell
    $desk = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desk 'Stalker Anomaly Vanilla+ Coop Pack.lnk'
    if (Test-Path -LiteralPath $lnkPath) {
        $old = $ws.CreateShortcut($lnkPath).TargetPath
        if ($old -and ($old -ine (Join-Path $Root 'ModOrganizer.exe'))) { $lnkPath = Join-Path $desk ('Stalker Anomaly Vanilla+ Coop Pack (' + (Split-Path -Leaf $Root) + ').lnk') }
    }
    $lnk = $ws.CreateShortcut($lnkPath)
    $lnk.TargetPath = Join-Path $Root 'ModOrganizer.exe'
    $lnk.WorkingDirectory = $Root
    $lnk.Description = 'Stalker Anomaly Vanilla+ Coop Pack (Mod Organizer 2)'
    # the pack's own radiation icon instead of the MO2 icon
    $icoSrc = Join-Path $Pack 'modpack.ico'
    $icoDst = Join-Path $Root 'modpack.ico'
    if ((Test-Path -LiteralPath $icoSrc) -and ($icoSrc -ne $icoDst)) { Copy-Item -LiteralPath $icoSrc -Destination $icoDst -Force }
    if (Test-Path -LiteralPath $icoDst) { $lnk.IconLocation = "$icoDst,0" }
    $lnk.Save()
} catch { }

Say ''
if ($Problems.Count -eq 0) {
    Say (T 'msg_done') 'Green'
    Say 'Start "Stalker Anomaly Vanilla+ Coop Pack" on your desktop, make sure the Coop profile is selected, and launch Anomaly from MO2.' 'Green'
} else {
    Say (T 'msg_done_prob') 'Yellow'
    foreach ($p in $Problems) { Say " - $p" 'Yellow' }
    Say (T 'msg_retry') 'Yellow'
}
Say 'First launch steps are in "README - Modpack Installer.txt".'
if ($Gui) {
    $readme = Join-Path $Pack 'README - Modpack Installer.txt'
    if ((Test-Path -LiteralPath $readme) -and ($Pack -ne $Root)) { Copy-Item -LiteralPath $readme -Destination (Join-Path $Root 'README - Modpack Installer.txt') -Force }
    Emit 'DONE' ($Problems -join ' || ')
}
