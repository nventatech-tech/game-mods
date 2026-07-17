using System.Collections;
using System.Reflection;
using HarmonyLib;
using UnityEngine;

namespace MouseTrainer
{
    // Bala teleguiada: todo tiro do player (hitscan e projetil) passa por
    // AimAssistController.AimAssistedShoot/AimAssistedDirection; com o cheat ON
    // a direcao vira o alvo ativo de menor angulo em relacao a mira que tenha
    // linha de visao livre, e o spread zera.
    internal static class Homing
    {
        private static FieldInfo _targetsField;
        private static FieldInfo _maskField;
        private static PropertyInfo _boundsProp;
        private static MethodInfo _instanceGetter;

        public static void Register(Harmony h)
        {
            var type = AccessTools.TypeByName("AimAssistController");
            if (type == null)
            {
                Plugin.Log.LogError("[homing] AimAssistController nao encontrado");
                return;
            }
            _targetsField = AccessTools.Field(type, "ActiveTargets");
            _maskField = AccessTools.Field(type, "lineOfSightMask");
            _instanceGetter = AccessTools.PropertyGetter(type, "Instance");
            Plugin.Log.LogInfo($"[homing] campos: targets={_targetsField != null} (static={_targetsField?.IsStatic}) mask={_maskField != null} instance={_instanceGetter != null}");

            foreach (var name in new[] { "AimAssistedShoot", "AimAssistedDirection" })
            {
                var original = AccessTools.Method(type, name);
                if (original == null)
                {
                    Plugin.Log.LogError($"[homing] metodo nao encontrado: {name}");
                    continue;
                }
                h.Patch(original, prefix: new HarmonyMethod(typeof(Homing).GetMethod(nameof(AimPrefix),
                    BindingFlags.Static | BindingFlags.NonPublic)));
                Plugin.Log.LogInfo($"[homing] OK {name}");
            }
        }

        // Parametros casam por nome com os metodos originais; ref permite reescrever.
        private static void AimPrefix(object __instance, Vector3 shootingShotOrigin, ref Vector3 shotDirection, ref float maxSpread)
        {
            if (!State.Homing) return;
            try
            {
                // AimAssistedShoot/Direction sao wrappers estaticos: __instance vem null,
                // o controller real e o singleton Instance.
                object controller = __instance ?? _instanceGetter?.Invoke(null, null);
                Vector3 dir;
                if (BestDirection(controller, shootingShotOrigin, shotDirection, out dir))
                {
                    shotDirection = dir;
                    maxSpread = 0f;
                }
            }
            catch (System.Exception e)
            {
                Plugin.Log.LogWarning($"[homing] prefix falhou: {e}");
            }
        }

        private static bool BestDirection(object controller, Vector3 origin, Vector3 aimDir, out Vector3 best)
        {
            best = Vector3.zero;
            if (_targetsField == null) return false;
            var targets = _targetsField.GetValue(_targetsField.IsStatic ? null : controller) as IEnumerable;
            if (targets == null)
            {
                Plugin.Log.LogWarning("[homing] ActiveTargets nulo");
                return false;
            }

            int losMask = 0;
            if (_maskField != null && (controller != null || _maskField.IsStatic))
            {
                var mv = _maskField.GetValue(_maskField.IsStatic ? null : controller);
                if (mv is LayerMask lm) losMask = lm.value;
            }

            float bestAngle = float.MaxValue;
            bool found = false;
            foreach (var t in targets)
            {
                if (t == null) continue;
                try
                {
                    if (_boundsProp == null || !_boundsProp.DeclaringType.IsInstanceOfType(t))
                        _boundsProp = AccessTools.Property(t.GetType(), "Bounds");
                    if (_boundsProp == null) continue;
                    Vector3 center = ((Bounds)_boundsProp.GetValue(t, null)).center;
                    Vector3 to = center - origin;
                    if (to.sqrMagnitude < 0.01f) continue;
                    float angle = Vector3.Angle(aimDir, to);
                    if (angle >= bestAngle) continue;
                    // cenario bloqueando = alvo invalido (mascara de LOS do proprio jogo)
                    if (losMask != 0 && Physics.Linecast(origin, center, losMask)) continue;
                    bestAngle = angle;
                    best = to.normalized;
                    found = true;
                }
                catch (System.Exception e)
                {
                    Plugin.Log.LogWarning($"[homing] alvo ignorado ({t.GetType().Name}): {e.Message}");
                }
            }
            return found;
        }
    }
}
