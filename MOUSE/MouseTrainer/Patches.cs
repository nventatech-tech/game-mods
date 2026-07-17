using System;
using System.Reflection;
using HarmonyLib;

namespace MouseTrainer
{
    // Patch manual (evita Harmony.PatchAll, que quebra no mono do jogo ao usar
    // .ToLookup -> TypeLoadException de System.Linq.ILookup em System.Core 3.5).
    internal static class Patches
    {
        public static void Register(Harmony h)
        {
            // GOD MODE: pula o dano recebido pelo player.
            Patch(h, typeof(PlayerHealth), "GetDamage",
                  prefix: nameof(GodPrefix));

            // VIDA x2: captura o PlayerHealth e aplica multiplicador.
            Patch(h, typeof(PlayerHealth), "Start", postfix: nameof(RegisterHealthPostfix));
            Patch(h, typeof(PlayerHealth), "Awake", postfix: nameof(RegisterHealthPostfix));

            // DANO x2: WeaponController.CalculatedWeaponDamage(..., Damage __4, ...) calcula
            // o dano final por acerto, pra TODAS as armas do player (hitscan e projetil).
            // O valor e recalculado a cada chamada (nao acumula), entao dobrar no postfix
            // da dano x2 limpo por tiro.
            Patch(h, typeof(WeaponController), "CalculatedWeaponDamage", postfix: nameof(CalcDamagePostfix));

            // MUNICAO INFINITA.
            Patch(h, typeof(PlayerInventory), "RemoveAmmo", prefix: nameof(RemoveAmmoPrefix));
            Patch(h, typeof(PlayerInventory), "UseAmmo", prefix: nameof(UseAmmoPrefix));
            Patch(h, typeof(PlayerInventory), "HasAmmo", postfix: nameof(HasAmmoPostfix));
        }

        private static void Patch(Harmony h, Type type, string method, string prefix = null, string postfix = null)
        {
            try
            {
                var original = AccessTools.Method(type, method);
                if (original == null)
                {
                    Plugin.Log.LogError($"[patch] metodo nao encontrado: {type.Name}.{method}");
                    return;
                }
                var pre = prefix != null ? new HarmonyMethod(typeof(Patches).GetMethod(prefix, Flags)) : null;
                var post = postfix != null ? new HarmonyMethod(typeof(Patches).GetMethod(postfix, Flags)) : null;
                h.Patch(original, prefix: pre, postfix: post);
                Plugin.Log.LogInfo($"[patch] OK {type.Name}.{method}");
            }
            catch (Exception e)
            {
                Plugin.Log.LogError($"[patch] FALHOU {type.Name}.{method}: {e.Message}");
            }
        }

        private const BindingFlags Flags =
            BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;

        // ---------- GOD ----------
        private static bool GodPrefix() => !State.God; // false = nao aplica dano

        // ---------- VIDA x2 ----------
        private static void RegisterHealthPostfix(PlayerHealth __instance) => State.RegisterHealth(__instance);

        // ---------- DANO x2 ----------
        // __4 = o Damage calculado (object pra evitar problema de resolucao de tipo na
        // geracao do metodo dinamico; damageAmount vem da base Damage).
        private static void CalcDamagePostfix(object __4)
        {
            if (!State.Damage2x || __4 == null) return;
            var f = Traverse.Create(__4).Field("damageAmount");
            if (!f.FieldExists()) return;
            f.SetValue(f.GetValue<int>() * State.DamageMultiplier);
        }

        // ---------- MUNICAO ----------
        private static bool RemoveAmmoPrefix() => !State.InfAmmo;

        private static bool UseAmmoPrefix(ref int __result, int __2)
        {
            if (!State.InfAmmo) return true;
            __result = __2; // finge que usou, sem decrementar
            return false;
        }

        private static void HasAmmoPostfix(ref bool __result)
        {
            if (State.InfAmmo) __result = true;
        }
    }
}
