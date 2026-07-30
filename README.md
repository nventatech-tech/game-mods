# Game Mods

[![Nexus Mods](https://img.shields.io/badge/Nexus%20Mods-opaaaaaaaaaaaa-orange?logo=nexusmods)](https://next.nexusmods.com/profile/opaaaaaaaaaaaa/mods)
[![Steam Workshop](https://img.shields.io/badge/Steam-Workshop-blue?logo=steam)](https://steamcommunity.com/profiles/76561198982807823/myworkshopfiles/)
[![BepInEx](https://img.shields.io/badge/framework-BepInEx%205-blue)](https://github.com/BepInEx/BepInEx)
[![MelonLoader](https://img.shields.io/badge/framework-MelonLoader-green)](https://melonwiki.xyz/)

Releases of my published game mods. Each folder has the release zip (the same file
published on Nexus / Workshop), screenshots and a short README.

## 🎮 Mods

| Mod | Game | Framework | Download |
|-----|------|-----------|----------|
| [GiveMeEverything](CyberPunk/GiveMeEverything) | Cyberpunk 2077 | CET (Lua) | [31460](https://www.nexusmods.com/cyberpunk2077/mods/31460) |
| [FindMyRide](CyberPunk/FindMyRide) | Cyberpunk 2077 | redscript | [31610](https://www.nexusmods.com/cyberpunk2077/mods/31610) |
| [BestInSlot](CyberPunk/BestInSlot) | Cyberpunk 2077 | redscript | [31702](https://www.nexusmods.com/cyberpunk2077/mods/31702) |
| [UnequipMods](CyberPunk/UnequipMods) | Cyberpunk 2077 | redscript | [31701](https://www.nexusmods.com/cyberpunk2077/mods/31701) |
| [QuestGuide](CyberPunk/QuestGuide) | Cyberpunk 2077 | redscript | [31784](https://www.nexusmods.com/cyberpunk2077/mods/31784) |
| [OnePunchHK](Hollow%20Knight/OnePunchHK) | Hollow Knight | BepInEx 5 | [193](https://www.nexusmods.com/hollowknight/mods/193) |
| [OnePunchSilksong](Silksong/OnePunchSilksong) | Hollow Knight: Silksong | BepInEx 5 | [1215](https://www.nexusmods.com/hollowknightsilksong/mods/1215) |
| [CupheadDoubleAssist](Cuphead/CupheadDoubleAssist) | Cuphead | BepInEx 5 | [115](https://www.nexusmods.com/cuphead/mods/115) |
| [CupheadUltraWideBepInEx](Cuphead/CupheadUltraWideBepInEx) | Cuphead | BepInEx 5 | [122](https://www.nexusmods.com/cuphead/mods/122) |
| [BepInEx for Cuphead](Cuphead/Bepinex) | Cuphead | pack | [173](https://www.nexusmods.com/cuphead/mods/173) |
| [NineSolsPowerMod](NineSols/NineSolsPowerMod) | Nine Sols | BepInEx 5 | [16](https://www.nexusmods.com/ninesols/mods/16) |
| [BepInEx pack for Nine Sols](NineSols/BepInExPack) | Nine Sols | pack | [17](https://www.nexusmods.com/ninesols/mods/17) |
| [CultOfQoL_PTBR](CultOfTheLamb/CultOfQoL_PTBR) | Cult of the Lamb | BepInEx 5 | [84](https://www.nexusmods.com/cultofthelamb/mods/84) |
| [UltraCleaningTools](CrimeSceneCleaner/UltraCleaningTools) | Crime Scene Cleaner | MelonLoader | [10](https://www.nexusmods.com/crimescenecleaner/mods/10) |
| [MouseTrainer](MOUSE/MouseTrainer) | MOUSE: P.I. For Hire | BepInEx 5 | [23](https://www.nexusmods.com/mousepiforhire/mods/23) |
| [DefluxorNoOverheat](Stray/DefluxorNoOverheat) | Stray | BepInEx 5 | [390](https://www.nexusmods.com/stray/mods/390) |
| [ShopWishlist](Brotato/ShopWishlist) | Brotato | GDScript (ModLoader) | [Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3771061737) |
| [ModOptionsTabs](Brotato/ModOptionsTabs) | Brotato | GDScript (ModLoader) | [Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3769887447) |
| [EnemiesEvolve](Brotato/EnemiesEvolve) | Brotato | GDScript (ModLoader) | [Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3769878400) |

## 📦 Install

Each zip is in the mod manager layout: `BepInEx/plugins/<Mod>.dll` for BepInEx games,
flat dll for MelonLoader, game-specific trees for Cyberpunk. Extract into the game
folder or install with Vortex / Mod Organizer 2. Brotato mods are distributed via
Steam Workshop (subscribe to install); the zip here is the uploaded package.

Nine Sols needs `HideManagerGameObject = true` in `BepInEx/config/BepInEx.cfg`.
With the default value the game destroys the BepInEx object on the first scene
change — plugins load, then stop running. The pack zip ships the correct config.

## 🔨 Build

C# mods: `dotnet build -c Release` in the mod folder. Game assembly references resolve
from the game install path set in each `.csproj` (`GameDir`/`ManagedDir` properties) —
adjust to your install or pass `/p:GameDir=...`.

## ❤️ Support

If a mod helped you, consider [donating via PayPal](https://www.paypal.com/donate/?business=SR28XBBCYSPHE&no_recurring=0&item_name=Help+me+buy+a+coffee.&currency_code=USD).

[![Donate](https://raw.githubusercontent.com/nventatech-tech/cctop/main/contents/images/donate-qr.png)](https://www.paypal.com/donate/?business=SR28XBBCYSPHE&no_recurring=0&item_name=Help+me+buy+a+coffee.&currency_code=USD)
