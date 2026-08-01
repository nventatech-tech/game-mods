# Tricky Towers Offline Bots

Adds AI opponents to local multiplayer, so you can play Race, Survival and Puzzle offline — solo or with friends. Requested by the community since 2017, never implemented.

## Features
- Up to 3 bots in local multiplayer (BotCount 0-3)
- Play alone: with bots enabled, 1 player can start a local match
- Three difficulties: Easy, Normal, Hard
- Bots use the full game stack: wind, spells against them, win conditions
- Reserved slots show "BOT" on the player select screen

## Install
1. Install BepInEx 5 x86 in the game folder (game is 32-bit)
2. Drop `TrickyTowersOfflineBots.dll` into `BepInEx/plugins`
3. Linux/Proton: set launch options `WINEDLLOVERRIDES="winhttp=n,b" %command%`

## Config
`BepInEx/config/com.opaaaaaaaaaaaa.trickytowers.offlinebots.cfg`
- `BotCount` — number of bots (default 1, 0 disables)
- `Difficulty` — Easy / Normal / Hard

## Build
`dotnet build` (needs the game installed; path set in the .csproj)
