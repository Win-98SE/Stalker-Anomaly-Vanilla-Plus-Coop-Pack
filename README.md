# Stalker Anomaly Vanilla+ Coop Pack

A vanilla-plus mod setup for **S.T.A.L.K.E.R. Anomaly 1.5.3** with **xrRazom co-op**, packaged as an installer that rebuilds the exact same game on your PC.

The installer does **not** contain anyone else's mods. It downloads every mod from its author's own ModDB / GitHub page and installs exactly the files, options and load order the pack uses, through a portable Mod Organizer 2 setup. The only files inside Setup are the pack's own small fixes and the posvoip voice chat program (open source, MPL-2.0; see Credits).

## Download

Get **`Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_<date>.exe`** from the latest release on the **[Releases](../../releases/latest)** page.

## Install

You need Windows 10/11 and about 25 GB of free space (about 55 GB if Setup also downloads Anomaly for you).

1. Run the Setup `.exe`. It isn't code-signed, so Windows may show "Windows protected your PC": click **More info**, then **Run anyway**.
2. Pick a folder (an empty one for a new install, not inside Program Files).
3. Choose where **S.T.A.L.K.E.R. Anomaly 1.5.3** comes from: your **GOG** copy (Anomaly is [free on GOG](https://www.gog.com/en/game/stalker_anomaly)), a **ModDB** download (9.1 GB) into the chosen folder, or another Anomaly folder on your PC.
4. Wait. If ModDB blocks a download, its page opens in your browser and the download starts by itself; Setup notices the finished file.
5. Press **Launch Mod Organizer**, pick *Anomaly (DX11-AVX)* and press Run.

Setup puts two shortcuts on your desktop: **Stalker Anomaly Vanilla+ Coop Pack** (Mod Organizer 2) and **posvoip (Coop Voice)**.

Setup speaks **English, Ukrainian and Russian** (you pick on the first screen).

## Updating

When a new release is out, Setup tells you when you open it. Download the new Setup `.exe` and point it at the same folder: it only downloads and reinstalls the mods that changed, removes mods that were dropped from the pack, and keeps everything else.

Full instructions and troubleshooting are in `README - Modpack Installer.txt`, which Setup copies into your Anomaly folder.

> Everyone playing together must use the **same release**: co-op needs identical files on every PC.

> **Start a new game after updating to this release.** It replaces the weapon pack (Blindside's -> MRAA) and changes how scopes attach; old saves can crash.

## Voice chat (posvoip)

The pack includes [posvoip](https://gitlab.com/darklight-outpost/posvoip/-/releases), proximity voice chat for xrRazom: you hear friends from where their character stands.

1. Start **posvoip (Coop Voice)** from your desktop **first**, then the pack (Mod Organizer 2) and the game.
2. Connect with a **code** (easiest - no router setup) or by **IP**: in IP mode only the host forwards **UDP port 49500**, and everyone else enters the host's IP.
3. Push-to-talk and radio keys are in the game's **MCM** menu (posvoip).

## Seasons

The pack ships C Consciousness Grass & Trees as **spring** with Atmospherics **summer** weather (Setup applies `cfg_load Atmos_Summer`). Other seasons/presets are a personal choice; for co-op everyone should use the same CCon season.

## Is it safe?

The Setup `.exe` isn't code-signed, so Windows shows a warning the first time. You don't have to take it on trust - you can check it yourself:

- **Read the source.** Everything Setup does is in this repo, as plain text:
  - [`SetupGui.cs`](SetupGui.cs) - the Setup window (C#). The `.exe` is compiled from this file.
  - [`Install-Modpack.ps1`](Install-Modpack.ps1) - the installer itself (PowerShell), which the window runs.
  - [`Mraa3dssFix.cs`](Mraa3dssFix.cs) - the MRAA 3DSS Fix recipe the installer runs on your PC (C#).
  - [`Build-Modpack-Installer.ps1`](Build-Modpack-Installer.ps1) - how the pack owner builds the `.exe` from their own Mod Organizer setup, using the C# compiler that comes with Windows.
  - [`modpack-sources.csv`](modpack-sources.csv) - every download link Setup uses.
- **Check the file is the original.** Each release lists the SHA-256 fingerprint of the `.exe`. In PowerShell, run `Get-FileHash .\Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_<date>.exe` and compare.
- **See the virus scan.** Each release links its VirusTotal report (about 70 antivirus engines). New, unsigned home-made programs sometimes get one or two "generic" or "heuristic" flags from smaller engines - that is a guess based on the file being unknown, not a detected virus.

### What Setup does on your PC

- Downloads only from the mod pages listed under Credits, plus S.T.A.L.K.E.R. Anomaly (ModDB), Mod Organizer 2 (GitHub) and 7-Zip (7-zip.org) if you don't have them.
- Writes only to the folder you choose, two desktop shortcuts, and a temporary folder that it deletes when it closes.
- Doesn't need administrator rights (unless you pick a folder inside Program Files).
- Sends nothing about you anywhere. Its only other connection is one check with GitHub for a newer release of this pack.

## Credits

All mods belong to their authors. Please visit their pages, endorse them and leave a comment.


**Co-op**

- [xrRazom: Stalker Anomaly Co-Op](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op) by xrRazom team
- [Persistent Stalkers](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/persistent-stalkers) by MeeMaster
- [Master Core](https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/master-core) by MeeMaster
- xrr_gestures 1.2.1 by leer (xrRazom Discord) - only shared on Discord, so it ships inside Setup unchanged, with credit.

**UI / HUD**

- [Maid's Vanilla HD Icons](https://www.moddb.com/mods/stalker-anomaly/addons/maids-vanilla-hd-icons) by maidresidence
- [Hunger, Thirst, Sleepiness Bars](https://www.moddb.com/mods/stalker-anomaly/addons/hunger-thirst-sleepiness-bars) by bvcx
- [Crook's Faction Identification UI](https://www.moddb.com/mods/stalker-anomaly/addons/crooks-faction-identification-ui) by Crook (uploaded by Grokitach)
- [O.L.D. D.O.G. HUD](https://www.moddb.com/mods/stalker-anomaly/addons/olddog) by Strogglet15

**Weapons / Animations / Scopes**

- [Mask's Reanimated Anomaly Arsenal (MRAA) 1.4.6](https://www.moddb.com/mods/stalker-anomaly/addons/masks-reanimated-anomaly-arsenal-v10) by Mask961 (credits: Party_50, BarryBogs, JadeyM, Von Avalon, Aoldri, Utjan, FIREBREATH1001, BixFeo, TAZ team)
- [3D Shader Sights MRAA](https://www.moddb.com/mods/stalker-anomaly/addons/3dss-mraa) by MsPizza727 (credits: Party_50, Mask961)
- [MRAA 1.4 meshes for 3DSS MRAA](https://www.moddb.com/mods/stalker-anomaly/addons/mraa-14-3dss-meshes) by _Zazquatch_ (credits: MsPizza727, Party_50, Mask961)
- [Backported Obligatory Objectively Better Systems (BOOBS)](https://www.moddb.com/addons/boobs) by MsPizza727 (credits: Party_50)
- [Modular Attachment System](https://www.moddb.com/mods/stalker-anomaly/addons/modular-attachment-system) by party_50
- [Shader 3D Scopes](https://www.moddb.com/mods/stalker-anomaly/addons/shader-3d-scopes) by party_50
- [Parallax Reflex Sights](https://www.moddb.com/addons/parallax-reflex-sights) by party_50 (credits: LVutner)
- [Mark Switch](https://www.moddb.com/mods/stalker-anomaly/addons/mark-switch) by party_50
- [Better red dots for default weapons](https://www.moddb.com/mods/stalker-anomaly/addons/better-red-dots-for-default-weapons) by party_50
- [Thicc Russian Reticles](https://www.moddb.com/addons/thicc-russian-reticles) by Napolemon
- [Vanilla Weapons Resmoothed & Relensed](https://www.moddb.com/mods/stalker-anomaly/addons/vanilla-weapons-resmoothed-relensed) by party_50
- [Procedural Movement Animations](https://www.moddb.com/mods/stalker-anomaly/addons/procedural-movement-animations) by party_50
- [Procedural Movement RE/Animate](https://www.moddb.com/mods/stalker-anomaly/addons/procedural-movement-reanimate) by Haxoo
- MRAA 3DSS Fix - made for this pack. 3DSS MRAA and the MRAA 1.4 3DSS meshes were made for MRAA 1.3; this points their weapon models at MRAA 1.4.6's animations, resizes the P90 to match MRAA 1.4.6, and fixes the P90 and Type 63 sight positions. **None of those mods' files ship with Setup**: Setup rebuilds the fixed models on your PC from the mods it downloaded and checks every file against the pack owner's (if the check fails, the fix is switched off and a log is written to `modpack_logs\mraa_fix_log.txt`).
- THAP Repaired EXO Duty Fix - made for this pack. Fixes the crash when wearing the Duty Nosorog exo: T.H.A.P. Rework Repaired EXO points it at a hands model (`actor_hud_duty_exo`) that doesn't exist; this points it at T.H.A.P.'s Duty exo hands. Ships inside Setup.
- SR-3M Vikhr Unsuppressed Sound - made for this pack. The Vikhr without a suppressor uses the OTS-14 Groza's unsuppressed shot. Ships inside Setup.
- MAS HD Icons Scope Fix, Ready Stances, RE-Animate Sprint Fix - made for this pack. Ship inside Setup.

**Hands / Item Animations**

- [T.H.A.P. Rework](https://www.moddb.com/mods/stalker-anomaly/addons/thap-rework) by IENCE (based on T.H.A.P. by ICHICROW)
- [T.H.A.P. Rework Repaired EXO](https://www.moddb.com/mods/stalker-anomaly/addons/thap-rework-repaired-exo) by Makrent
- [Food, Drug and Drinks Animations (FDDA)](https://www.moddb.com/mods/stalker-anomaly/addons/food-drug-and-drinks-animations-reuploaded) by Feel_Fried
- [FDDA Enhanced Animations - Food and Drinks](https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-food-n-drinks) by Mirrowel
- [FDDA Enhanced Animations Enhanced](https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-enhanced) by lizzardman
- [FDDA Enhanced Animations - Medical / EXO](https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-medical-exo-anims) by Mirrowel
- [FDDA Redone](https://www.moddb.com/mods/stalker-anomaly/addons/fdda-redone) by lizzardman (includes Animated Lead Box by leer_h)
- [Item's Model Drop After Usage](https://www.moddb.com/mods/stalker-anomaly/addons/items-model-drop-after-usage) by Kutee and Purple

**Voice chat**

- [posvoip](https://gitlab.com/darklight-outpost/posvoip/-/releases) and its STALKER adapter by darklight-outpost - open source under the Mozilla Public License 2.0 (license included). Bundled in Setup unchanged.

**Audio**

- [Dark Signal Amplified Soundscape](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-soundscape) by Shr¡ke
- [JSRS Sound Mod (port)](https://www.moddb.com/mods/stalker-anomaly/addons/solarint-gunshot-overhaul) by Solarint
- [Dark Signal Amplified Footsteps v5 Extended](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-footsteps-v5-extended) by Shr¡ke
- [Dark Signal Amplified Item and UI Soundpack](https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-item-and-ui-soundpack) by Shr¡ke

**Effects**

- ["Cinematic VFX" Particle Effects Addon 3.7](https://www.moddb.com/addons/cinemavfx3-7) by jdud
- CVFX 3.7 Generators and Poltergeist Fix - made for this pack, based on helloworlder's CVFX generators crash / poltergeist fix. Ships inside Setup.

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
- [Useful Idiots](https://www.moddb.com/mods/stalker-anomaly/addons/useful-idiots) by bellyillish
- [Zone Customization Project (ZCP)](https://www.moddb.com/mods/stalker-anomaly/addons/survival-mode-remade-151) by Diphenhydramine-HCl
- ZCP Relations List Symbol Fix - made for this pack. Fixes the "nїS" shown before each faction in the new-game Relations list with ZCP. Ships inside Setup.
- Inventory Cell Crash Guard - made for this pack. Stops a crash in Anomaly's item grid (utils_ui.script line 1226) when an item has no inventory icon size, e.g. switching debug spawner categories. Ships inside Setup.

**Base game and tools**

- [S.T.A.L.K.E.R. Anomaly](https://www.moddb.com/mods/stalker-anomaly) by the Anomaly Developers
- [Mod Organizer 2](https://github.com/ModOrganizer2/modorganizer)
- [Anomaly Mod Configuration Menu (MCM)](https://www.moddb.com/mods/stalker-anomaly/addons/anomaly-mod-configuration-menu) by RavenAscendant

Please don't re-upload the mods themselves.
