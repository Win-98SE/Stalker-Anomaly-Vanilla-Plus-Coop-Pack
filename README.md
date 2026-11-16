# Stalker Anomaly Vanilla+ Coop Pack

A vanilla-plus mod setup for **S.T.A.L.K.E.R. Anomaly 1.5.3** with **xrRazom co-op**, packaged as an installer that rebuilds the exact same game on your PC.

The installer does **not** contain any mods. It downloads every mod from its author's own ModDB / GitHub page and installs exactly the files, options and load order the pack uses, through a portable Mod Organizer 2 setup.

## Download

Get **`Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_<date>.exe`** from the latest release on the **[Releases](../../releases/latest)** page.

## Install

You need Windows 10/11 and about 25 GB of free space (about 55 GB if Setup also downloads Anomaly for you).

1. Run the Setup `.exe`. It isn't code-signed, so Windows may show "Windows protected your PC": click **More info**, then **Run anyway**.
2. Pick a folder (an empty one for a new install, not inside Program Files).
3. Choose where **S.T.A.L.K.E.R. Anomaly 1.5.3** comes from: your **GOG** copy (Anomaly is [free on GOG](https://www.gog.com/en/game/stalker_anomaly)), a **ModDB** download (9.1 GB) into the chosen folder, or another Anomaly folder on your PC.
4. Wait. If ModDB blocks a download, its page opens in your browser and the download starts by itself; Setup notices the finished file.
5. Press **Launch Mod Organizer**, pick *Anomaly (DX11-AVX)* and press Run.

Setup speaks **English, Ukrainian and Russian** (you pick on the first screen).

## Updating

When a new release is out, Setup tells you when you open it. Download the new Setup `.exe` and point it at the same folder: it only downloads and reinstalls the mods that changed, removes mods that were dropped from the pack, and keeps everything else.

Full instructions and troubleshooting are in `README - Modpack Installer.txt`, which Setup copies into your Anomaly folder.

> Everyone playing together must use the **same release**: co-op needs identical files on every PC.

## Is it safe?

The Setup `.exe` isn't code-signed, so Windows shows a warning the first time. You don't have to take it on trust - you can check it yourself:

- **Read the source.** Everything Setup does is in this repo, as plain text:
  - [`SetupGui.cs`](SetupGui.cs) - the Setup window (C#). The `.exe` is compiled from this file.
  - [`Install-Modpack.ps1`](Install-Modpack.ps1) - the installer itself (PowerShell), which the window runs.
  - [`Build-Modpack-Installer.ps1`](Build-Modpack-Installer.ps1) - how the pack owner builds the `.exe` from their own Mod Organizer setup, using the C# compiler that comes with Windows.
  - [`modpack-sources.csv`](modpack-sources.csv) - every download link Setup uses.
- **Check the file is the original.** Each release lists the SHA-256 fingerprint of the `.exe`. In PowerShell, run `Get-FileHash .\Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_<date>.exe` and compare.
- **See the virus scan.** Each release links its VirusTotal report (about 70 antivirus engines). New, unsigned home-made programs sometimes get one or two "generic" or "heuristic" flags from smaller engines - that is a guess based on the file being unknown, not a detected virus.

### What Setup does on your PC

- Downloads only from the mod pages listed under Credits, plus S.T.A.L.K.E.R. Anomaly (ModDB), Mod Organizer 2 (GitHub) and 7-Zip (7-zip.org) if you don't have them.
- Writes only to the folder you choose, a desktop shortcut, and a temporary folder that it deletes when it closes.
- Doesn't need administrator rights (unless you pick a folder inside Program Files).
- Sends nothing about you anywhere. Its only other connection is one check with GitHub for a newer release of this pack.

## Credits

All mods belong to their authors. Please visit their pages, endorse them and leave a comment.


**Co-op**

- [xrRazom: Stalker Anomaly Co-Op](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op) by xrRazom team
- [Persistent Stalkers](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/persistent-stalkers) by xrRazom team (uploaded by MeeMaster)
- [Master Core](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/master-core) by xrRazom team (uploaded by MeeMaster)

**UI / HUD**

- [Maid's Vanilla HD Icons](https://www.moddb.com/mods/stalker-anomaly/addons/maids-vanilla-hd-icons) by maidresidence
- [Hunger, Thirst, Sleepiness Bars](https://www.moddb.com/mods/stalker-anomaly/addons/hunger-thirst-sleepiness-bars) by bvcx
- [Crook's Faction Identification UI](https://www.moddb.com/mods/stalker-anomaly/addons/crooks-faction-identification-ui) by Crook (uploaded by Grokitach)
- [O.L.D. D.O.G. HUD](https://www.moddb.com/mods/stalker-anomaly/addons/olddog) by Strogglet15

**Weapons / Animations**

- [3D Shader Scopes - Blindside's](https://www.moddb.com/mods/stalker-anomaly/addons/3dss-blindsides) by MsPizza727
- [3D Shader Scopes - Vanilla](https://www.moddb.com/mods/stalker-anomaly/addons/3d-shader-scopes-vanilla) by MsPizza727
- [Shader 3D Scopes](https://www.moddb.com/mods/stalker-anomaly/addons/shader-3d-scopes) by party_50
- [Mark Switch](https://www.moddb.com/mods/stalker-anomaly/addons/mark-switch) by party_50
- [Blindside's Weapon Reanimation - Military](https://www.moddb.com/mods/stalker-anomaly/addons/blindsides-weapon-reanimation-and-rebalance-military) by Blindxside
- [Vanilla Weapons Resmoothed & Relensed](https://www.moddb.com/mods/stalker-anomaly/addons/vanilla-weapons-resmoothed-relensed) by party_50

**Audio**

- [Dark Signal Amplified Soundscape](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-soundscape) by Shr¡ke
- [JSRS Sound Mod (port)](https://www.moddb.com/mods/stalker-anomaly/addons/solarint-gunshot-overhaul) by Solarint
- [Dark Signal Amplified Footsteps v5 Extended](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-footsteps-v5-extended) by Shr¡ke
- [Dark Signal Amplified Item and UI Soundpack](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-item-and-ui-soundpack) by Shr¡ke

**Graphics**

- [Fixed Vanilla Models & Textures](https://www.moddb.com/mods/stalker-anomaly/addons/fvm) by Strogglet15
- [Atmospherics (Anomaly version)](https://drive.google.com/drive/folders/1oxxygDE0_YNU-DAYfRaL2MOL2EHeseGk) by Hozar_2002
- [2K Upscaled Skyboxes](https://www.moddb.com/mods/stalker-anomaly/addons/2k-upscaled-skyboxes-almost-definitive-edtion) by TheMrDemonized
- [C Consciousness Grass & Trees](https://www.moddb.com/mods/stalker-anomaly/addons/ccon-grass-n-trees) by Huh_?
- [Screen Space Shaders](https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders) by Ascii1457
- [Enhanced Shaders and Color Grading](https://www.moddb.com/addons/enhanced-shaders-and-color-grading-for-151) by KennShade
- [Beef's Shader Based NVGs](https://www.moddb.com/mods/stalker-anomaly/addons/beefs-shader-based-nvgs-v10) by theRealBeef
- [Nicer Flashlights and Headlamps](https://www.moddb.com/addons/nicer-flashlights-and-headlamps-addon) by shortnamesalex

**Gameplay**

- [iTheon's PDA Taskboard](https://www.moddb.com/mods/stalker-anomaly/addons/itheons-pda-taskboard) by iTheon
- [iTheon's New Tasks](https://github.com/lTheon/iTheon-New-Tasks-Addon) by iTheon
- [RF Receiver Tasks QOL patch](https://www.moddb.com/addons/rf-receiver-tasks-qol-update) by CookBook (uploaded by Aeonera)
- [TB's RF Receiver Hidden Package Sidequests](https://www.moddb.com/addons/tbs-rf-receiver-hidden-package-sidequests) by Tweaki_Breeki
- [Dynamic Anomalies Overhaul (DAO)](https://www.moddb.com/addons/dynamic-anomalies-overhaul-dao-read-description-please) by TheMrDemonized
- [Hideout Furniture Expansion](https://www.moddb.com/mods/stalker-anomaly/addons/hideout-furniture-expansion) by maidresidence
- [Hideout Furniture (HF)](https://www.moddb.com/addons/hideout-furniture-hf) by Aoldri

**Base game and tools**

- [S.T.A.L.K.E.R. Anomaly](https://www.moddb.com/mods/stalker-anomaly) by the Anomaly Developers
- [Mod Organizer 2](https://github.com/ModOrganizer2/modorganizer)

Please don't re-upload the mods themselves.
