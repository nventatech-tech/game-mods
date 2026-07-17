using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using UnityEngine;
using UnityEngine.InputSystem;

namespace MouseTrainer
{
    [BepInPlugin(PluginInfo.Guid, PluginInfo.Name, PluginInfo.Version)]
    public class Plugin : BaseUnityPlugin
    {
        internal static ManualLogSource Log;

        private void Awake()
        {
            Log = Logger;
            try
            {
                var harmony = new Harmony(PluginInfo.Guid);
                Patches.Register(harmony);
                Homing.Register(harmony);
            }
            catch (System.Exception e)
            {
                Log.LogError($"Falha ao registrar patches: {e}");
            }
            Log.LogInfo($"{PluginInfo.Name} v{PluginInfo.Version} carregado. " +
                        "F1=God F2=MunicaoInf F3=Dano x2 F4=Vida x2 F5=BalaTeleguiada. " +
                        $"Defaults: Dano x2 ON, Vida x2 ON.");
        }

        private void Update()
        {
            var kb = Keyboard.current;
            if (kb == null) return;

            if (kb.f1Key.wasPressedThisFrame)
            {
                State.God = !State.God;
                State.Toast($"God mode: {OnOff(State.God)}");
            }
            if (kb.f2Key.wasPressedThisFrame)
            {
                State.InfAmmo = !State.InfAmmo;
                State.Toast($"Municao infinita: {OnOff(State.InfAmmo)}");
            }
            if (kb.f3Key.wasPressedThisFrame)
            {
                State.Damage2x = !State.Damage2x;
                State.Toast($"Dano x2: {OnOff(State.Damage2x)}");
            }
            if (kb.f4Key.wasPressedThisFrame)
            {
                State.Health2x = !State.Health2x;
                State.ApplyHealth(healToFull: true);
                State.Toast($"Vida x2: {OnOff(State.Health2x)}");
            }
            if (kb.f5Key.wasPressedThisFrame)
            {
                State.Homing = !State.Homing;
                State.Toast($"Bala teleguiada: {OnOff(State.Homing)}");
            }

            // Reforca o maxHealth todo frame (o jogo pode reescrever apos o Start).
            State.EnforceMaxHealth();
        }

        private static string OnOff(bool b) => b ? "ON" : "OFF";

        private void OnGUI() => State.DrawToast();
    }

    internal static class PluginInfo
    {
        public const string Guid    = "com.opaaaaaaaaaaaa.mouse.trainer";
        public const string Name    = "Mouse Trainer";
        public const string Version = "1.1.0";
    }
}
