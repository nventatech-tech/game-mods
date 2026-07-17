# Game Mods

[![Nexus Mods](https://img.shields.io/badge/Nexus%20Mods-opaaaaaaaaaaaa-orange?logo=nexusmods)](https://next.nexusmods.com/profile/opaaaaaaaaaaaa/mods)
[![BepInEx](https://img.shields.io/badge/framework-BepInEx%205-blue)](https://github.com/BepInEx/BepInEx)
[![MelonLoader](https://img.shields.io/badge/framework-MelonLoader-green)](https://melonwiki.xyz/)

Source code for my published game mods.

## 🎮 Mods

| Mod | Game | Framework | Nexus |
|-----|------|-----------|-------|
| [CupheadDoubleAssist](Cuphead/CupheadDoubleAssist) | Cuphead | BepInEx 5 | [115](https://www.nexusmods.com/cuphead/mods/115) |
| [CupheadUltraWideBepInEx](Cuphead/CupheadUltraWideBepInEx) | Cuphead | BepInEx 5 | [122](https://www.nexusmods.com/cuphead/mods/122) |
| [BepInEx for Cuphead](Cuphead/Bepinex) | Cuphead | pack | [173](https://www.nexusmods.com/cuphead/mods/173) |
| [FindMyRide](CyberPunk/FindMyRide) | Cyberpunk 2077 | redscript | [31610](https://www.nexusmods.com/cyberpunk2077/mods/31610) |
| [GiveMeEverything](CyberPunk/GiveMeEverything) | Cyberpunk 2077 | CET (Lua) | [31460](https://www.nexusmods.com/cyberpunk2077/mods/31460) |
| [NineSolsPowerMod](NineSols/NineSolsPowerMod) | Nine Sols | BepInEx 5 | [16](https://www.nexusmods.com/ninesols/mods/16) |
| [BepInEx pack for Nine Sols](NineSols/BepInExPack) | Nine Sols | pack | [17](https://www.nexusmods.com/ninesols/mods/17) |
| [CultOfQoL_PTBR](CultOfTheLamb/CultOfQoL_PTBR) | Cult of the Lamb | BepInEx 5 | [84](https://www.nexusmods.com/cultofthelamb/mods/84) |
| [OnePunchHK](Hollow%20Knight/OnePunchHK) | Hollow Knight | BepInEx 5 | [193](https://www.nexusmods.com/hollowknight/mods/193) |
| [MouseTrainer](MOUSE/MouseTrainer) | MOUSE: P.I. For Hire | BepInEx 5 | [23](https://www.nexusmods.com/mousepiforhire/mods/23) |
| [UltraCleaningTools](CrimeCleaner/UltraCleaningTools) | Crime Scene Cleaner | MelonLoader | [10](https://www.nexusmods.com/crimescenecleaner/mods/10) |

## 🔨 Build

C# mods: `dotnet build -c Release` in the mod folder. Game assembly references resolve
from the game install path set in each `.csproj` (`GameDir`/`ManagedDir` properties) —
adjust to your install or pass `/p:GameDir=...`.

## 📦 Download

Each mod folder contains the release zip (same file published on Nexus Mods), in the
mod manager layout: `BepInEx/plugins/<Mod>.dll` for BepInEx games, flat dll for
MelonLoader, game-specific trees for Cyberpunk. Extract into the game folder or
install with Vortex / Mod Organizer 2.
