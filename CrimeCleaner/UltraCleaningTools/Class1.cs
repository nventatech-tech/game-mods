using System;
using System.Linq;
using System.Reflection;
using HarmonyLib;
using MelonLoader;
using UnityEngine;
using UnityEngine.SceneManagement;

[assembly: MelonInfo(typeof(UltraCleaningTools.UltraCleaningToolsMod), "Ultra Cleaning Tools", "3.1", "opaaaaaaaaaaaa")]
[assembly: MelonGame(null, null)]

namespace UltraCleaningTools
{
    public class UltraCleaningToolsMod : MelonMod
    {
        private HarmonyLib.Harmony _harmony;

        private const float CleaningSizeBoost = 8f;
        private const float InfiniteValue = 9999f;
        private const int InfiniteGarbageSize = 999999;

        private static float _trashDisabledUntil;
        private static string _lastSceneName = string.Empty;
        private const float TrashDelayAfterSceneLoad = 10f;

        public override void OnInitializeMelon()
        {
            _harmony = new HarmonyLib.Harmony("UltraCleaningTools.opaaaaaaaaaaaa.3.1");

            PatchCleaningItems();
            PatchCleaningLiquids();
            PatchPowerWasherStation("Il2Cpp.PowerWasherStation");
            PatchPowerWasherStation("Il2Cpp.PowerWasherStationBackpack");
            PatchTrashCollectors();

            PauseTrashPatch(TrashDelayAfterSceneLoad);
        }

        public override void OnSceneWasLoaded(int buildIndex, string sceneName)
        {
            _lastSceneName = sceneName ?? string.Empty;
            PauseTrashPatch(TrashDelayAfterSceneLoad);
        }

        public override void OnSceneWasInitialized(int buildIndex, string sceneName)
        {
            _lastSceneName = sceneName ?? string.Empty;
            PauseTrashPatch(TrashDelayAfterSceneLoad);
        }

        private static void PauseTrashPatch(float seconds)
        {
            try
            {
                _trashDisabledUntil = Time.realtimeSinceStartup + seconds;
            }
            catch
            {
                _trashDisabledUntil = 0f;
            }
        }

        private static bool CanUseTrashPatch(object instance = null)
        {
            try
            {
                if (Time.realtimeSinceStartup < _trashDisabledUntil)
                    return false;

                Scene scene = SceneManager.GetActiveScene();
                if (!scene.IsValid() || !scene.isLoaded)
                    return false;

                string sceneName = scene.name ?? _lastSceneName ?? string.Empty;
                if (string.IsNullOrWhiteSpace(sceneName))
                    return false;

                string lower = sceneName.ToLowerInvariant();

                if (lower.Contains("loading"))
                    return false;

                if (lower.Contains("menu"))
                    return false;

                if (lower.Contains("splash"))
                    return false;

                if (lower.Contains("hub"))
                    return false;

                Component component = instance as Component;
                if (component != null)
                {
                    if (component.gameObject == null)
                        return false;

                    if (!component.gameObject.activeInHierarchy)
                        return false;

                    Behaviour behaviour = component as Behaviour;
                    if (behaviour != null && !behaviour.isActiveAndEnabled)
                        return false;

                    Scene objectScene = component.gameObject.scene;
                    if (!objectScene.IsValid() || !objectScene.isLoaded)
                        return false;
                }

                return true;
            }
            catch
            {
                return false;
            }
        }

        private void PatchCleaningItems()
        {
            PatchPostfixAll("Il2Cpp.CleaningItem", "Start", nameof(CleaningItem_Start_Postfix));
            PatchPrefixAll("Il2Cpp.CleaningItem", "Taint", nameof(CleaningItem_Taint_Prefix));
        }

        private void PatchCleaningLiquids()
        {
            PatchPostfix("Il2Cpp.CleaningLiquid", "Awake", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "Start", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "OnEnable", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "Select", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "Deselect", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "Load", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "PourLiquid", nameof(CleaningLiquid_Postfix));
            PatchPostfix("Il2Cpp.CleaningLiquid", "EndPour", nameof(CleaningLiquid_Postfix));

            PatchPrefix("Il2Cpp.CleaningLiquid", "get_IsEmpty", nameof(CleaningLiquid_IsEmpty_Prefix));
            PatchPrefix("Il2Cpp.CleaningLiquid", "get_Capacity", nameof(FloatInfinite_Prefix));
            PatchPrefix("Il2Cpp.CleaningLiquid", "get_MaxCapacity", nameof(FloatInfinite_Prefix));
        }

        private void PatchPowerWasherStation(string typeName)
        {
            PatchPostfix(typeName, "Awake", nameof(PowerWasherStation_Postfix));
            PatchPostfix(typeName, "Start", nameof(PowerWasherStation_Postfix));
            PatchPostfix(typeName, "OnEnable", nameof(PowerWasherStation_Postfix));
            PatchPostfix(typeName, "FillWithWater", nameof(PowerWasherStation_Postfix));
            PatchPostfix(typeName, "EquipKercher", nameof(PowerWasherStation_Postfix));
            PatchPostfix(typeName, "AssignWasherLance", nameof(PowerWasherStation_Postfix));

            PatchPrefix(typeName, "EmptyWaterTank", nameof(PowerWasherStation_EmptyWaterTank_Prefix));
            PatchPrefix(typeName, "get_HasWater", nameof(PowerWasherStation_HasWater_Prefix));
            PatchPrefix(typeName, "get_canSpray", nameof(PowerWasherStation_CanSpray_Prefix));
            PatchPrefix(typeName, "get_CanSpray", nameof(PowerWasherStation_CanSpray_Prefix));
        }

        private void PatchTrashCollectors()
        {
            PatchTrashAround("Il2Cpp.GarbageCollector", new[]
            {
                "TryCollectItem",
                "TryToCollectItem",
                "Collect",
                "GrabItem"
            });

            PatchTrashAround("Il2Cpp.StandingGarbageCollector", new[]
            {
                "OnItemEnter",
                "TryCollectItem"
            });
            // Não patchar IncreaseBagSize/SetLevel.
            // Esses métodos mexem no estado interno da lixeira e podem rodar ao finalizar/abandonar a missão.

            PatchTrashIntReturn("Il2Cpp.GarbageBagConnector", "GetMaxGarbageSize", nameof(TrashIntInfinite_Prefix));
        }

        private void PatchTrashAround(string typeName, string[] methodNames)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo prefix = typeof(UltraCleaningToolsMod).GetMethod(nameof(TrashApply_Prefix), BindingFlags.Static | BindingFlags.NonPublic);
                MethodInfo postfix = typeof(UltraCleaningToolsMod).GetMethod(nameof(TrashApply_Postfix), BindingFlags.Static | BindingFlags.NonPublic);
                if (prefix == null || postfix == null)
                    return;

                foreach (string methodName in methodNames)
                {
                    foreach (MethodInfo method in type.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
                    {
                        if (method.Name != methodName)
                            continue;

                        if (!CanPatchTrashMethod(method))
                            continue;

                        try
                        {
                            _harmony.Patch(method, prefix: new HarmonyMethod(prefix), postfix: new HarmonyMethod(postfix));
                        }
                        catch
                        {
                        }
                    }
                }
            }
            catch
            {
            }
        }

        private void PatchTrashIntReturn(string typeName, string methodName, string prefixName)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo prefix = typeof(UltraCleaningToolsMod).GetMethod(prefixName, BindingFlags.Static | BindingFlags.NonPublic);
                if (prefix == null)
                    return;

                foreach (MethodInfo method in type.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
                {
                    if (method.Name != methodName)
                        continue;

                    if (method.ReturnType != typeof(int))
                        continue;

                    if (!CanPatchTrashMethod(method))
                        continue;

                    try
                    {
                        _harmony.Patch(method, prefix: new HarmonyMethod(prefix));
                    }
                    catch
                    {
                    }
                }
            }
            catch
            {
            }
        }

        private static bool CanPatchTrashMethod(MethodInfo method)
        {
            if (method == null)
                return false;

            if (method.IsStatic || method.IsAbstract || method.IsGenericMethod || method.IsConstructor)
                return false;

            if (method.IsSpecialName)
                return false;

            string name = method.Name ?? string.Empty;
            if (name.StartsWith("get_", StringComparison.Ordinal) || name.StartsWith("set_", StringComparison.Ordinal))
                return false;

            if (name == "Update" || name == "Awake" || name == "Start" || name == "OnEnable" || name == "OnDestroy" || name == "OnDisable")
                return false;

            string lower = name.ToLowerInvariant();

            if (lower.Contains("save") || lower.Contains("load") || lower.Contains("complete") || lower.Contains("finish") || lower.Contains("mission") || lower.Contains("abandon") || lower.Contains("leave") || lower.Contains("exit") || lower.Contains("dispose") || lower.Contains("destroy") || lower.Contains("unload") || lower.Contains("clear") || lower.Contains("release") || lower.Contains("deselect") || lower.Contains("remove"))
                return false;

            return true;
        }

        private static bool TrashApply_Prefix(object __instance)
        {
            if (CanUseTrashPatch(__instance))
                ApplyTrashSafe(__instance);

            return true;
        }

        private static void TrashApply_Postfix(object __instance)
        {
            if (CanUseTrashPatch(__instance))
                ApplyTrashSafe(__instance);
        }

        private static bool TrashIntInfinite_Prefix(object __instance, ref int __result)
        {
            if (!CanUseTrashPatch(__instance))
                return true;

            ApplyTrashSafe(__instance);
            __result = InfiniteGarbageSize;
            return false;
        }

        private static void ApplyTrashSafe(object instance)
        {
            if (instance == null)
                return;

            string fullName = string.Empty;

            try
            {
                Type type = instance.GetType();
                fullName = type.FullName ?? string.Empty;
            }
            catch
            {
            }

            SetValue(instance, "trashCapacity", InfiniteGarbageSize);
            SetValue(instance, "TrashCapacity", InfiniteGarbageSize);
            SetValue(instance, "capacity", InfiniteGarbageSize);
            SetValue(instance, "Capacity", InfiniteGarbageSize);
            SetValue(instance, "maxCapacity", InfiniteGarbageSize);
            SetValue(instance, "MaxCapacity", InfiniteGarbageSize);
            SetValue(instance, "maxSize", InfiniteGarbageSize);
            SetValue(instance, "MaxSize", InfiniteGarbageSize);
            SetValue(instance, "maxGarbageSize", InfiniteGarbageSize);
            SetValue(instance, "MaxGarbageSize", InfiniteGarbageSize);

            SetValue(instance, "holdingReachedMaxCapacity", false);
            SetValue(instance, "HoldingReachedMaxCapacity", false);
            SetValue(instance, "reachedMaxCapacity", false);
            SetValue(instance, "ReachedMaxCapacity", false);
            SetValue(instance, "isFull", false);
            SetValue(instance, "IsFull", false);
            SetValue(instance, "full", false);
            SetValue(instance, "Full", false);

            SetValue(instance, "canCollect", true);
            SetValue(instance, "CanCollect", true);
            SetValue(instance, "canUse", true);
            SetValue(instance, "CanUse", true);
            SetValue(instance, "hasSpace", true);
            SetValue(instance, "HasSpace", true);
            // Não zera currentSize/fillLevel/currentGarbageSize.
            // Zerar esses estados deixa a lixeira infinita, mas pode quebrar a finalização/abandono da missão.
            // A estabilidade vem de aumentar os limites e impedir estado de cheio, sem corromper contadores internos.
        }

        private static void CleaningItem_Start_Postfix(object __instance)
        {
            ApplyCleaningItem(__instance);
        }

        private static bool CleaningItem_Taint_Prefix(object __instance)
        {
            ApplyCleaningItem(__instance);
            return false;
        }

        private static void CleaningLiquid_Postfix(object __instance)
        {
            ApplyInfiniteDetergent(__instance);
        }

        private static bool CleaningLiquid_IsEmpty_Prefix(object __instance, ref bool __result)
        {
            ApplyInfiniteDetergent(__instance);
            __result = false;
            return false;
        }

        private static bool FloatInfinite_Prefix(object __instance, ref float __result)
        {
            ApplyInfiniteDetergent(__instance);
            __result = InfiniteValue;
            return false;
        }

        private static void PowerWasherStation_Postfix(object __instance)
        {
            ApplyInfinitePowerWasherStation(__instance);
        }

        private static bool PowerWasherStation_EmptyWaterTank_Prefix(object __instance)
        {
            ApplyInfinitePowerWasherStation(__instance);
            return false;
        }

        private static bool PowerWasherStation_HasWater_Prefix(object __instance, ref bool __result)
        {
            ApplyInfinitePowerWasherStation(__instance);
            __result = true;
            return false;
        }

        private static bool PowerWasherStation_CanSpray_Prefix(object __instance, ref bool __result)
        {
            ApplyInfinitePowerWasherStation(__instance);
            __result = true;
            return false;
        }

        private static void ApplyCleaningItem(object instance)
        {
            if (instance == null)
                return;

            SetValue(instance, "cleaningSize", CleaningSizeBoost);
            SetValue(instance, "CleaningSize", CleaningSizeBoost);
        }

        private static void ApplyInfiniteDetergent(object instance)
        {
            if (instance == null)
                return;

            SetValue(instance, "numberOfUses", InfiniteValue);
            SetValue(instance, "NumberOfUses", InfiniteValue);
            SetValue(instance, "baseCapacity", InfiniteValue);
            SetValue(instance, "BaseCapacity", InfiniteValue);
            SetValue(instance, "capacity", InfiniteValue);
            SetValue(instance, "Capacity", InfiniteValue);
            SetValue(instance, "maxCapacity", InfiniteValue);
            SetValue(instance, "MaxCapacity", InfiniteValue);
            SetValue(instance, "currentCapacity", InfiniteValue);
            SetValue(instance, "CurrentCapacity", InfiniteValue);
            SetValue(instance, "amount", InfiniteValue);
            SetValue(instance, "Amount", InfiniteValue);
            SetValue(instance, "currentAmount", InfiniteValue);
            SetValue(instance, "CurrentAmount", InfiniteValue);
            SetValue(instance, "detergentAmount", InfiniteValue);
            SetValue(instance, "DetergentAmount", InfiniteValue);
            SetValue(instance, "isEmpty", false);
            SetValue(instance, "IsEmpty", false);
            SetValue(instance, "empty", false);
            SetValue(instance, "Empty", false);
            SetValue(instance, "hasDetergent", true);
            SetValue(instance, "HasDetergent", true);
        }

        private static void ApplyInfinitePowerWasherStation(object instance)
        {
            if (instance == null)
                return;

            SetValue(instance, "consumedWater", 0f);
            SetValue(instance, "ConsumedWater", 0f);
            SetValue(instance, "water", InfiniteValue);
            SetValue(instance, "Water", InfiniteValue);
            SetValue(instance, "waterLevel", InfiniteValue);
            SetValue(instance, "WaterLevel", InfiniteValue);
            SetValue(instance, "currentWaterLevel", InfiniteValue);
            SetValue(instance, "CurrentWaterLevel", InfiniteValue);
            SetValue(instance, "maxWaterLevel", InfiniteValue);
            SetValue(instance, "MaxWaterLevel", InfiniteValue);
            SetValue(instance, "waterCapacity", InfiniteValue);
            SetValue(instance, "WaterCapacity", InfiniteValue);
            SetValue(instance, "capacity", InfiniteValue);
            SetValue(instance, "Capacity", InfiniteValue);
            SetValue(instance, "maxCapacity", InfiniteValue);
            SetValue(instance, "MaxCapacity", InfiniteValue);
            SetValue(instance, "currentCapacity", InfiniteValue);
            SetValue(instance, "CurrentCapacity", InfiniteValue);
            SetValue(instance, "amount", InfiniteValue);
            SetValue(instance, "Amount", InfiniteValue);
            SetValue(instance, "currentAmount", InfiniteValue);
            SetValue(instance, "CurrentAmount", InfiniteValue);
            SetValue(instance, "hasWater", true);
            SetValue(instance, "HasWater", true);
            SetValue(instance, "canSpray", true);
            SetValue(instance, "CanSpray", true);
            SetValue(instance, "isEmpty", false);
            SetValue(instance, "IsEmpty", false);
            SetValue(instance, "empty", false);
            SetValue(instance, "Empty", false);
        }

        private void PatchPostfix(string typeName, string methodName, string postfixName)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo original = FindMethod(type, methodName);
                if (original == null)
                    return;

                MethodInfo postfix = typeof(UltraCleaningToolsMod).GetMethod(postfixName, BindingFlags.Static | BindingFlags.NonPublic);
                if (postfix == null)
                    return;

                _harmony.Patch(original, postfix: new HarmonyMethod(postfix));
            }
            catch
            {
            }
        }

        private void PatchPrefix(string typeName, string methodName, string prefixName)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo original = FindMethod(type, methodName);
                if (original == null)
                    return;

                MethodInfo prefix = typeof(UltraCleaningToolsMod).GetMethod(prefixName, BindingFlags.Static | BindingFlags.NonPublic);
                if (prefix == null)
                    return;

                _harmony.Patch(original, prefix: new HarmonyMethod(prefix));
            }
            catch
            {
            }
        }

        private void PatchPostfixAll(string typeName, string methodName, string postfixName)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo postfix = typeof(UltraCleaningToolsMod).GetMethod(postfixName, BindingFlags.Static | BindingFlags.NonPublic);
                if (postfix == null)
                    return;

                foreach (MethodInfo method in type.GetMethods(BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic))
                {
                    if (method.Name != methodName)
                        continue;

                    if (method.IsAbstract || method.IsGenericMethod)
                        continue;

                    try
                    {
                        _harmony.Patch(method, postfix: new HarmonyMethod(postfix));
                    }
                    catch
                    {
                    }
                }
            }
            catch
            {
            }
        }

        private void PatchPrefixAll(string typeName, string methodName, string prefixName)
        {
            try
            {
                Type type = FindType(typeName);
                if (type == null)
                    return;

                MethodInfo prefix = typeof(UltraCleaningToolsMod).GetMethod(prefixName, BindingFlags.Static | BindingFlags.NonPublic);
                if (prefix == null)
                    return;

                foreach (MethodInfo method in type.GetMethods(BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic))
                {
                    if (method.Name != methodName)
                        continue;

                    if (method.IsAbstract || method.IsGenericMethod)
                        continue;

                    try
                    {
                        _harmony.Patch(method, prefix: new HarmonyMethod(prefix));
                    }
                    catch
                    {
                    }
                }
            }
            catch
            {
            }
        }

        private static Type FindType(string fullName)
        {
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                try
                {
                    Type type = assembly.GetType(fullName);
                    if (type != null)
                        return type;
                }
                catch
                {
                }
            }

            return null;
        }

        private static MethodInfo FindMethod(Type type, string methodName)
        {
            try
            {
                return type.GetMethods(BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly)
                    .FirstOrDefault(m => m.Name == methodName && !m.IsAbstract && !m.IsGenericMethod);
            }
            catch
            {
                return null;
            }
        }

        private static void SetValue(object instance, string name, object value)
        {
            if (instance == null)
                return;

            Type type = instance.GetType();

            try
            {
                FieldInfo field = FindFieldRecursive(type, name);
                if (field != null)
                {
                    object converted = ConvertValue(value, field.FieldType);
                    field.SetValue(instance, converted);
                    return;
                }
            }
            catch
            {
            }

            try
            {
                PropertyInfo prop = FindPropertyRecursive(type, name);
                if (prop != null && prop.CanWrite)
                {
                    object converted = ConvertValue(value, prop.PropertyType);
                    prop.SetValue(instance, converted);
                }
            }
            catch
            {
            }
        }

        private static void SetFieldOnly(object instance, string name, object value)
        {
            if (instance == null)
                return;

            try
            {
                Type type = instance.GetType();
                FieldInfo field = FindFieldRecursive(type, name);
                if (field == null)
                    return;

                object converted = ConvertValue(value, field.FieldType);
                field.SetValue(instance, converted);
            }
            catch
            {
            }
        }

        private static FieldInfo FindFieldRecursive(Type type, string name)
        {
            while (type != null)
            {
                try
                {
                    FieldInfo field = type.GetField(name, BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
                    if (field != null)
                        return field;
                }
                catch
                {
                }

                type = type.BaseType;
            }

            return null;
        }

        private static PropertyInfo FindPropertyRecursive(Type type, string name)
        {
            while (type != null)
            {
                try
                {
                    PropertyInfo prop = type.GetProperty(name, BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
                    if (prop != null)
                        return prop;
                }
                catch
                {
                }

                type = type.BaseType;
            }

            return null;
        }

        private static object ConvertValue(object value, Type targetType)
        {
            try
            {
                if (targetType == typeof(float))
                    return Convert.ToSingle(value);

                if (targetType == typeof(double))
                    return Convert.ToDouble(value);

                if (targetType == typeof(int))
                    return Convert.ToInt32(value);

                if (targetType == typeof(bool))
                    return Convert.ToBoolean(value);

                return value;
            }
            catch
            {
                return value;
            }
        }
    }
}
