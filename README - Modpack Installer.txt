STALKER ANOMALY VANILLA+ COOP PACK - INSTALLER
==============================================

This installer downloads every mod from its original page and sets it up
exactly like the pack owner's game: same files, same load order, same xrRazom
engine build and the same MCM settings. Mods are NOT re-uploaded; they come
from their authors' ModDB / GitHub pages.


WHAT YOU NEED
-------------
- Windows 10 or 11
- About 25 GB of free space, or about 55 GB if the installer also downloads
  Anomaly for you
- S.T.A.L.K.E.R. Anomaly 1.5.3 is optional: the installer can use your
  existing copy (GOG or ModDB) or download it for you


INSTALL
-------
1. Download "Stalker_Anomaly_VanillaPlus_Coop_Pack_Setup_<date>.exe" and run it.
   Windows may say "Windows protected your PC" because the file isn't signed:
   click "More info", then "Run anyway".
2. Pick a folder (an empty one for a new install, e.g. D:\Games\Anomaly Coop,
   not inside Program Files), then choose where Anomaly 1.5.3 comes from:
   your GOG copy, a download from ModDB, or another Anomaly folder.
3. Wait. If ModDB only allows browser downloads, its pages open and the
   downloads start by themselves - let them save to your Downloads folder.
   Setup notices each finished file. "Skip these" gives up on the missing ones.
4. When it says "All done", press "Launch Mod Organizer" (or use the
   "Stalker Anomaly Vanilla+ Coop Pack" shortcut on your desktop).
5. In MO2, pick "Anomaly (DX11-AVX)" or "Anomaly (DX11)" and press Run.

UPDATING FROM AN OLDER VERSION OF THE PACK: run the new Setup and pick the
same folder. It only downloads what changed and removes mods that were
dropped. Then START A NEW GAME - this version swaps the weapon pack
(Blindside's -> MRAA) and changes how scopes attach, so old saves can crash.


If something goes wrong, just run Setup again. Downloads that
already finished are kept.

GOG users: in GOG Galaxy, turn off automatic updates for Anomaly in its
settings, and don't use "Verify / Repair" on it. Both put the original game
files back and remove the co-op engine files (then just run the installer
again).


FIRST LAUNCH (in game)
----------------------
- The installer already applied the pack owner's game settings (graphics,
  Atmospherics "Summer" preset, gameplay options). Your key bindings, mouse,
  resolution/monitor and sound device are left alone. Don't turn SSAO or
  anti-aliasing back on - the shader mods fail to compile with them.
- Options > Video: set your resolution / display mode.
- Options > Controls: check your key bindings and mouse sensitivity.
- Options > xrRazom / Co-op: set your player name.
- Your MCM settings (SSS, Atmospherics, HUD...) already match the pack owner's.
- Seasons: grass/trees (C Consciousness) are spring, weather is Atmospherics
  summer. Other weather: console "cfg_load Atmos_Neutral" (autumn look) or
  "cfg_load Atmos_Summer". Everyone in co-op should keep the same CCon season.


VOICE CHAT (posvoip)
--------------------
1. Start "posvoip (Coop Voice)" on your desktop FIRST, then the pack
   (Mod Organizer 2) and the game.
2. Join by CODE (easiest, no router setup) or by IP. In IP mode only the
   host forwards UDP port 49500 on their router; everyone else enters the
   host's IP address.
3. Push-to-talk and radio keys are in the game's MCM menu (posvoip).


WHAT THE INSTALLER CHANGES
--------------------------
- mods\, profiles\Coop, ModOrganizer.ini   (Mod Organizer 2, portable)
- bin\ and gamedata\   (xrRazom co-op engine files)
  Your original files are saved in _modpack_backup\ before being replaced.
- appdata\user.ltx: the pack settings above (a backup is kept as
  user.ltx.before-modpack). appdata\shaders_cache is cleared.
- posvoip\   (the voice chat program)
- Two desktop shortcuts: "Stalker Anomaly Vanilla+ Coop Pack" (MO2) and
  "posvoip (Coop Voice)".
- MRAA 3DSS Fix: its weapon models are rebuilt on your PC from the mods the
  installer downloaded, then checked file by file. If the check fails the
  fix is switched off (the rest of the pack still installs) and
  modpack_logs\mraa_fix_log.txt explains why - send that file to the
  pack owner.


CREDITS
-------
All mods belong to their authors. Please visit their pages, endorse them
and leave a comment - that's the only thanks they get.


CO-OP
- xrRazom: Stalker Anomaly Co-Op  by xrRazom team
    https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op
- Persistent Stalkers  by MeeMaster
    https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/persistent-stalkers
- Master Core  by MeeMaster
    https://www.moddb.com/mods/xrrazom-stalker-anomaly-co-op/addons/master-core
- xrr_gestures 1.2.1  by leer (xrRazom Discord)
    Only shared on Discord, so it ships inside Setup unchanged.

UI / HUD
- Maid's Vanilla HD Icons  by maidresidence
    https://www.moddb.com/mods/stalker-anomaly/addons/maids-vanilla-hd-icons
- Hunger, Thirst, Sleepiness Bars  by bvcx
    https://www.moddb.com/mods/stalker-anomaly/addons/hunger-thirst-sleepiness-bars
- Crook's Faction Identification UI  by Crook (uploaded by Grokitach)
    https://www.moddb.com/mods/stalker-anomaly/addons/crooks-faction-identification-ui
- O.L.D. D.O.G. HUD  by Strogglet15
    https://www.moddb.com/mods/stalker-anomaly/addons/olddog

WEAPONS / ANIMATIONS / SCOPES
- Mask's Reanimated Anomaly Arsenal (MRAA) 1.4.6  by Mask961
  (credits: Party_50, BarryBogs, JadeyM, Von Avalon, Aoldri, Utjan,
  FIREBREATH1001, BixFeo, TAZ team)
    https://www.moddb.com/mods/stalker-anomaly/addons/masks-reanimated-anomaly-arsenal-v10
- 3D Shader Sights MRAA  by MsPizza727 (credits: Party_50, Mask961)
    https://www.moddb.com/mods/stalker-anomaly/addons/3dss-mraa
- MRAA 1.4 meshes for 3DSS MRAA  by _Zazquatch_ (credits: MsPizza727,
  Party_50, Mask961)
    https://www.moddb.com/mods/stalker-anomaly/addons/mraa-14-3dss-meshes
- Backported Obligatory Objectively Better Systems (BOOBS)  by MsPizza727
    https://www.moddb.com/addons/boobs
- Modular Attachment System  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/modular-attachment-system
- Shader 3D Scopes  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/shader-3d-scopes
- Parallax Reflex Sights  by party_50 (credits: LVutner)
    https://www.moddb.com/addons/parallax-reflex-sights
- Mark Switch  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/mark-switch
- Better red dots for default weapons  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/better-red-dots-for-default-weapons
- Thicc Russian Reticles  by Napolemon
    https://www.moddb.com/addons/thicc-russian-reticles
- Vanilla Weapons Resmoothed & Relensed  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/vanilla-weapons-resmoothed-relensed
- Procedural Movement Animations  by party_50
    https://www.moddb.com/mods/stalker-anomaly/addons/procedural-movement-animations
- Procedural Movement RE/Animate  by Haxoo
    https://www.moddb.com/mods/stalker-anomaly/addons/procedural-movement-reanimate
- MRAA 3DSS Fix  - made for this pack
    Points the 3DSS MRAA / MRAA 1.4 3DSS models at MRAA 1.4.6's animations,
    resizes the P90 to match, and fixes the P90 and Type 63 sights. Rebuilt
    on your PC from those mods - none of their files ship with Setup.
- SR-3M Vikhr Unsuppressed Sound  - made for this pack
    The Vikhr without a suppressor uses the OTS-14 Groza's shot sound.
- MAS HD Icons Scope Fix, Ready Stances, RE-Animate Sprint Fix
  - made for this pack

HANDS / ITEM ANIMATIONS
- T.H.A.P. Rework  by IENCE (based on T.H.A.P. by ICHICROW)
    https://www.moddb.com/mods/stalker-anomaly/addons/thap-rework
- T.H.A.P. Rework Repaired EXO  by Makrent
    https://www.moddb.com/mods/stalker-anomaly/addons/thap-rework-repaired-exo
- THAP Repaired EXO Duty Fix  - made for this pack
    Fixes the crash when wearing the Duty Nosorog exo (it pointed at a hands
    model that doesn't exist).
- Food, Drug and Drinks Animations (FDDA)  by Feel_Fried
    https://www.moddb.com/mods/stalker-anomaly/addons/food-drug-and-drinks-animations-reuploaded
- FDDA Enhanced Animations - Food and Drinks  by Mirrowel
    https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-food-n-drinks
- FDDA Enhanced Animations Enhanced  by lizzardman
    https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-enhanced
- FDDA Enhanced Animations - Medical / EXO  by Mirrowel
    https://www.moddb.com/mods/stalker-anomaly/addons/fdda-enhanced-animations-medical-exo-anims
- FDDA Redone  by lizzardman (includes Animated Lead Box by leer_h)
    https://www.moddb.com/mods/stalker-anomaly/addons/fdda-redone
- Item's Model Drop After Usage  by Kutee and Purple
    https://www.moddb.com/mods/stalker-anomaly/addons/items-model-drop-after-usage

VOICE CHAT
- posvoip + STALKER adapter  by darklight-outpost
  (open source, Mozilla Public License 2.0 - license included, bundled
  unchanged)
    https://gitlab.com/darklight-outpost/posvoip/-/releases

AUDIO
- Dark Signal Amplified Soundscape  by Shr¡ke
    https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-soundscape
- JSRS Sound Mod (port)  by Solarint
    https://www.moddb.com/mods/stalker-anomaly/addons/solarint-gunshot-overhaul
- Dark Signal Amplified Footsteps v5 Extended  by Shr¡ke
    https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-footsteps-v5-extended
- Dark Signal Amplified Item and UI Soundpack  by Shr¡ke
    https://www.moddb.com/mods/stalker-anomaly/addons/dark-signal-amplified-item-and-ui-soundpack

EFFECTS
- "Cinematic VFX" Particle Effects Addon 3.7  by jdud
    https://www.moddb.com/addons/cinemavfx3-7
- CVFX 3.7 Generators and Poltergeist Fix  - made for this pack
    Based on helloworlder's CVFX generators crash / poltergeist fix.

GRAPHICS
- Fixed Vanilla Models & Textures  by Strogglet15
    https://www.moddb.com/mods/stalker-anomaly/addons/fvm
- Atmospherics (Anomaly version)  by Hozar_2002
    https://drive.google.com/drive/folders/1oxxygDE0_YNU-DAYfRaL2MOL2EHeseGk
- 2K Upscaled Skyboxes  by TheMrDemonized
    https://www.moddb.com/mods/stalker-anomaly/addons/2k-upscaled-skyboxes-almost-definitive-edtion
- C Consciousness Grass & Trees  by Huh_?
    https://www.moddb.com/mods/stalker-anomaly/addons/ccon-grass-n-trees
- Screen Space Shaders  by Ascii1457
    https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders
- Enhanced Shaders and Color Grading  by KennShade
    https://www.moddb.com/addons/enhanced-shaders-and-color-grading-for-151
- Beef's Shader Based NVGs  by theRealBeef
    https://www.moddb.com/mods/stalker-anomaly/addons/beefs-shader-based-nvgs-v10
- Nicer Flashlights and Headlamps  by shortnamesalex
    https://www.moddb.com/addons/nicer-flashlights-and-headlamps-addon

GAMEPLAY
- iTheon's PDA Taskboard  by iTheon
    https://www.moddb.com/mods/stalker-anomaly/addons/itheons-pda-taskboard
- iTheon's New Tasks  by iTheon
    https://github.com/lTheon/iTheon-New-Tasks-Addon
- RF Receiver Tasks QOL patch  by CookBook (uploaded by Aeonera)
    https://www.moddb.com/addons/rf-receiver-tasks-qol-update
- TB's RF Receiver Hidden Package Sidequests  by Tweaki_Breeki
    https://www.moddb.com/addons/tbs-rf-receiver-hidden-package-sidequests
- Dynamic Anomalies Overhaul (DAO)  by TheMrDemonized
    https://www.moddb.com/addons/dynamic-anomalies-overhaul-dao-read-description-please
- Hideout Furniture Expansion  by maidresidence
    https://www.moddb.com/mods/stalker-anomaly/addons/hideout-furniture-expansion
- Hideout Furniture (HF)  by Aoldri
    https://www.moddb.com/addons/hideout-furniture-hf
- Useful Idiots  by bellyillish
    https://www.moddb.com/mods/stalker-anomaly/addons/useful-idiots
- Zone Customization Project (ZCP)  by Diphenhydramine-HCl
    https://www.moddb.com/mods/stalker-anomaly/addons/survival-mode-remade-151
- ZCP Relations List Symbol Fix  - made for this pack
    Fixes the "nїS" before each faction on the new-game screen.
- Inventory Cell Crash Guard  - made for this pack
    Stops an item-grid crash when an item has no inventory icon size.

S.T.A.L.K.E.R. Anomaly by the Anomaly Developers: https://www.moddb.com/mods/stalker-anomaly
Mod Organizer 2: https://github.com/ModOrganizer2/modorganizer
Anomaly Mod Configuration Menu (MCM) by RavenAscendant:
    https://www.moddb.com/mods/stalker-anomaly/addons/anomaly-mod-configuration-menu



TROUBLESHOOTING
---------------
"different version than the pack uses":
    The mod author updated the file on ModDB. Ask the pack owner for the
    updated installer, or answer Y to use the newer file (it usually works,
    but co-op is safest when everyone has identical files).

Crash on start mentioning shaders:
    Delete Anomaly\appdata\shaders_cache and launch again.

"MRAA 3DSS Fix could not be applied":
    Everything else is installed and the game works; MRAA guns just keep
    some old reload/pose bugs. Send modpack_logs\mraa_fix_log.txt (in your
    Anomaly folder) to the pack owner.

No voice in posvoip:
    Start posvoip BEFORE the game. In IP mode the host must forward UDP
    49500; try joining by code instead.

Can't join each other's game:
    Everyone must use the same installer version. Compare the date in
    modpack.json ("created").

Please don't re-upload the mods themselves. They belong to their authors.
