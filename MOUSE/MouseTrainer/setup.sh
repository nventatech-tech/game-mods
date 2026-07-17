#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

GAME="/mnt/files/SteamLibrary/steamapps/common/MOUSE"

echo "Compilando MouseTrainer..."
dotnet build -c Release

echo "Copiando para BepInEx/plugins..."
cp bin/Release/MouseTrainer.dll "$GAME/BepInEx/plugins/"

echo ""
echo "OK! Teclas no jogo:"
echo "  F1 = God mode        (comeca OFF)"
echo "  F2 = Municao infinita (comeca OFF)"
echo "  F3 = Dano x2          (comeca ON)"
echo "  F4 = Vida x2          (comeca ON)"
echo "Toast aparece no topo da tela ao trocar."
