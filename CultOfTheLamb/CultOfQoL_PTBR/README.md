# CultOfQoL PT-BR Configuration Manager Addon

Addon BepInEx separado para traduzir a exibição do `CultOfQoL.dll` no Configuration Manager, sem alterar o mod original.

## 🔨 Build no CachyOS/fish

```fish
set -gx COTL "/mnt/files/SteamLibrary/steamapps/common/Cult of the Lamb"
cd ~/Documentos/Mods/CultOfTheLamb/CultOfQoL_PTBR

dotnet restore /p:GameDir="$COTL"
dotnet build -c Release /p:GameDir="$COTL"

cp bin/Release/CultOfQoL_PTBR.dll "$COTL/BepInEx/plugins/"
```

Depois abra o jogo e o Configuration Manager. As opções do CultOfQoL devem aparecer em PT-BR.
