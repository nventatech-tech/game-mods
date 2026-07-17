using HarmonyLib;
using UnityEngine;

namespace MouseTrainer
{
    // Estado global dos cheats + helpers de vida e toast.
    internal static class State
    {
        // Defaults pedidos: dano e vida x2 ligados; god e municao desligados.
        public static bool God = false;
        public static bool InfAmmo = false;
        public static bool Damage2x = true;
        public static bool Health2x = true;
        public static bool Homing = false;

        public const int HealthMultiplier = 2;
        public const int DamageMultiplier = 2;

        // --- Vida ---
        private static PlayerHealth _ph;
        private static int _baseMax = -1; // maxHealth original do jogo

        // Chamado pelos patches de PlayerHealth.Start/Awake.
        public static void RegisterHealth(PlayerHealth ph)
        {
            if (ph == null) return;
            _ph = ph;
            int curMax = Traverse.Create(ph).Field("maxHealth").GetValue<int>();
            // So captura a base se ainda nao temos, ou se o jogo deu um valor "novo"
            // que nao seja o nosso dobro (evita capturar o valor ja dobrado).
            if (_baseMax < 0 || (curMax != _baseMax && curMax != _baseMax * HealthMultiplier))
                _baseMax = curMax;
            ApplyHealth(healToFull: true);
        }

        // Aplica/remove o x2 a partir da base guardada.
        public static void ApplyHealth(bool healToFull)
        {
            if (_ph == null || _baseMax < 0) return;
            int target = Health2x ? _baseMax * HealthMultiplier : _baseMax;
            var t = Traverse.Create(_ph);
            t.Field("maxHealth").SetValue(target);
            // defaultMaxHealth so existe pra restaurar; segue o mesmo alvo.
            var def = t.Field("defaultMaxHealth");
            if (def.FieldExists()) def.SetValue(target);
            if (healToFull)
                t.Field("health").SetValue(target);
            else
            {
                // clampa a vida atual ao novo maximo (ao desligar o x2)
                var hf = t.Field("health");
                int h = hf.GetValue<int>();
                if (h > target) hf.SetValue(target);
            }
        }

        // Reforca maxHealth todo frame sem mexer na vida atual (god mode cuida do dano).
        public static void EnforceMaxHealth()
        {
            if (_ph == null || _baseMax < 0) return;
            int target = Health2x ? _baseMax * HealthMultiplier : _baseMax;
            var mf = Traverse.Create(_ph).Field("maxHealth");
            if (mf.GetValue<int>() != target) mf.SetValue(target);
        }

        // --- Toast ---
        private static string _toast = "";
        private static float _toastExpire = 0f;
        private const float ToastDuration = 2f;

        public static void Toast(string text)
        {
            _toast = text;
            _toastExpire = Time.unscaledTime + ToastDuration;
        }

        public static void DrawToast()
        {
            if (string.IsNullOrEmpty(_toast)) return;
            float remaining = _toastExpire - Time.unscaledTime;
            if (remaining <= 0f) { _toast = ""; return; }

            float alpha = remaining < 0.5f ? remaining / 0.5f : 1f; // fade nos ultimos 0.5s
            var style = new GUIStyle { fontSize = 22 };
            // sombra
            style.normal.textColor = new Color(0f, 0f, 0f, alpha);
            GUI.Label(new Rect(Screen.width / 2f - 199, 41, 400, 40), _toast, style);
            style.normal.textColor = new Color(1f, 0.85f, 0.2f, alpha);
            GUI.Label(new Rect(Screen.width / 2f - 200, 40, 400, 40), _toast, style);
        }
    }
}
