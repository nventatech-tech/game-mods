using System;
using System.Collections.Generic;
using System.Reflection;
using HarmonyLib;
using MelonLoader;
using UnityEngine;
using UnityEngine.SceneManagement;

[assembly: MelonInfo(typeof(UltraCleaningTools.UltraCleaningToolsMod), "Ultra Cleaning Tools", "3.2", "opaaaaaaaaaaaa")]
[assembly: MelonGame(null, null)]

namespace UltraCleaningTools
{
    public class UltraCleaningToolsMod : MelonMod
    {
        private HarmonyLib.Harmony _harmony;

        private const float InfiniteValue = 9999f;
        private const int InfiniteGarbageSize = 999999;
        private const float TrashDelayAfterSceneLoad = 10f;

        private static float _trashDisabledUntil;
        private static bool _sceneBlocked = true;

        private static ApplyProfile _cleaningItemProfile;

        // Não zerar currentSize/fillLevel/currentGarbageSize: corrompe finalização/abandono da missão.
        private static readonly ApplyProfile TrashProfile = new ApplyProfile(
            ("trashCapacity", InfiniteGarbageSize), ("TrashCapacity", InfiniteGarbageSize),
            ("capacity", InfiniteGarbageSize), ("Capacity", InfiniteGarbageSize),
            ("maxCapacity", InfiniteGarbageSize), ("MaxCapacity", InfiniteGarbageSize),
            ("maxSize", InfiniteGarbageSize), ("MaxSize", InfiniteGarbageSize),
            ("maxGarbageSize", InfiniteGarbageSize), ("MaxGarbageSize", InfiniteGarbageSize),
            ("holdingReachedMaxCapacity", false), ("HoldingReachedMaxCapacity", false),
            ("reachedMaxCapacity", false), ("ReachedMaxCapacity", false),
            ("isFull", false), ("IsFull", false),
            ("full", false), ("Full", false),
            ("canCollect", true), ("CanCollect", true),
            ("canUse", true), ("CanUse", true),
            ("hasSpace", true), ("HasSpace", true));

        private static readonly ApplyProfile DetergentProfile = new ApplyProfile(
            ("numberOfUses", InfiniteValue), ("NumberOfUses", InfiniteValue),
            ("baseCapacity", InfiniteValue), ("BaseCapacity", InfiniteValue),
            ("capacity", InfiniteValue), ("Capacity", InfiniteValue),
            ("maxCapacity", InfiniteValue), ("MaxCapacity", InfiniteValue),
            ("currentCapacity", InfiniteValue), ("CurrentCapacity", InfiniteValue),
            ("amount", InfiniteValue), ("Amount", InfiniteValue),
            ("currentAmount", InfiniteValue), ("CurrentAmount", InfiniteValue),
            ("detergentAmount", InfiniteValue), ("DetergentAmount", InfiniteValue),
            ("isEmpty", false), ("IsEmpty", false),
            ("empty", false), ("Empty", false),
            ("hasDetergent", true), ("HasDetergent", true));

        private static readonly ApplyProfile WasherProfile = new ApplyProfile(
            ("consumedWater", 0f), ("ConsumedWater", 0f),
            ("water", InfiniteValue), ("Water", InfiniteValue),
            ("waterLevel", InfiniteValue), ("WaterLevel", InfiniteValue),
            ("currentWaterLevel", InfiniteValue), ("CurrentWaterLevel", InfiniteValue),
            ("maxWaterLevel", InfiniteValue), ("MaxWaterLevel", InfiniteValue),
            ("waterCapacity", InfiniteValue), ("WaterCapacity", InfiniteValue),
            ("capacity", InfiniteValue), ("Capacity", InfiniteValue),
            ("maxCapacity", InfiniteValue), ("MaxCapacity", InfiniteValue),
            ("currentCapacity", InfiniteValue), ("CurrentCapacity", InfiniteValue),
            ("amount", InfiniteValue), ("Amount", InfiniteValue),
            ("currentAmount", InfiniteValue), ("CurrentAmount", InfiniteValue),
            ("hasWater", true), ("HasWater", true),
            ("canSpray", true), ("CanSpray", true),
            ("isEmpty", false), ("IsEmpty", false),
            ("empty", false), ("Empty", false));

        public override void OnInitializeMelon()
        {
            var prefs = MelonPreferences.CreateCategory("UltraCleaningTools");
            var biggerArea = prefs.CreateEntry("BiggerCleaningArea", true, description: "Bigger cleaning radius and tools never get dirty");
            var sizeBoost = prefs.CreateEntry("CleaningSizeBoost", 8f, description: "Cleaning radius multiplier");
            var infLiquids = prefs.CreateEntry("InfiniteLiquids", true, description: "Sprays and cleaning liquids never run out");
            var infWasher = prefs.CreateEntry("InfinitePowerWasher", true, description: "Power washer station and backpack never run out of water");
            var infTrash = prefs.CreateEntry("InfiniteTrash", true, description: "Trash bags never fill up");

            _cleaningItemProfile = new ApplyProfile(
                ("cleaningSize", sizeBoost.Value), ("CleaningSize", sizeBoost.Value));

            _harmony = new HarmonyLib.Harmony("UltraCleaningTools.opaaaaaaaaaaaa");

            int cleaning = biggerArea.Value ? PatchCleaningItems() : -1;
            int liquids = infLiquids.Value ? PatchCleaningLiquids() : -1;
            int washer = -1;
            if (infWasher.Value)
            {
                washer = PatchPowerWasherStation("Il2Cpp.PowerWasherStation");
                washer += PatchPowerWasherStation("Il2Cpp.PowerWasherStationBackpack");
            }
            int trash = infTrash.Value ? PatchTrashCollectors() : -1;

            PauseTrashPatch(TrashDelayAfterSceneLoad);

            MelonLogger.Msg($"Patches applied - cleaning area: {Count(cleaning)}, liquids: {Count(liquids)}, power washer: {Count(washer)}, trash: {Count(trash)}");
            MelonLogger.Msg("Config: UserData/MelonPreferences.cfg [UltraCleaningTools] (restart game to apply)");
        }

        private static string Count(int value) => value < 0 ? "disabled" : value.ToString();

        public override void OnSceneWasLoaded(int buildIndex, string sceneName) => OnScene(sceneName);

        public override void OnSceneWasInitialized(int buildIndex, string sceneName) => OnScene(sceneName);

        private static void OnScene(string sceneName)
        {
            string lower = (sceneName ?? string.Empty).ToLowerInvariant();
            _sceneBlocked = lower.Length == 0
                || lower.Contains("loading")
                || lower.Contains("menu")
                || lower.Contains("splash")
                || lower.Contains("hub");

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

        private static bool CanUseTrashPatch(object instance)
        {
            try
            {
                if (_sceneBlocked || Time.realtimeSinceStartup < _trashDisabledUntil)
                    return false;

                Component component = instance as Component;
                if (component != null)
                {
                    GameObject go = component.gameObject;
                    if (go == null || !go.activeInHierarchy)
                        return false;

                    Behaviour behaviour = component as Behaviour;
                    if (behaviour != null && !behaviour.isActiveAndEnabled)
                        return false;

                    Scene objectScene = go.scene;
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

        private int PatchCleaningItems()
        {
            int n = 0;
            n += Patch("Il2Cpp.CleaningItem", "Start", postfixName: nameof(CleaningItem_Start_Postfix));
            n += Patch("Il2Cpp.CleaningItem", "Taint", prefixName: nameof(CleaningItem_Taint_Prefix));
            return n;
        }

        private int PatchCleaningLiquids()
        {
            const string type = "Il2Cpp.CleaningLiquid";
            int n = 0;

            foreach (string method in new[] { "Awake", "Start", "OnEnable", "Select", "Deselect", "Load", "PourLiquid", "EndPour" })
                n += Patch(type, method, postfixName: nameof(CleaningLiquid_Postfix));

            n += Patch(type, "get_IsEmpty", prefixName: nameof(CleaningLiquid_IsEmpty_Prefix));
            n += Patch(type, "get_Capacity", prefixName: nameof(CleaningLiquid_FloatInfinite_Prefix));
            n += Patch(type, "get_MaxCapacity", prefixName: nameof(CleaningLiquid_FloatInfinite_Prefix));
            return n;
        }

        private int PatchPowerWasherStation(string typeName)
        {
            int n = 0;

            foreach (string method in new[] { "Awake", "Start", "OnEnable", "FillWithWater", "EquipKercher", "AssignWasherLance" })
                n += Patch(typeName, method, postfixName: nameof(PowerWasherStation_Postfix));

            n += Patch(typeName, "EmptyWaterTank", prefixName: nameof(PowerWasherStation_EmptyWaterTank_Prefix));
            n += Patch(typeName, "get_HasWater", prefixName: nameof(PowerWasherStation_HasWater_Prefix));
            n += Patch(typeName, "get_canSpray", prefixName: nameof(PowerWasherStation_CanSpray_Prefix));
            n += Patch(typeName, "get_CanSpray", prefixName: nameof(PowerWasherStation_CanSpray_Prefix));
            return n;
        }

        private int PatchTrashCollectors()
        {
            int n = 0;

            foreach (string method in new[] { "TryCollectItem", "TryToCollectItem", "Collect", "GrabItem" })
                n += Patch("Il2Cpp.GarbageCollector", method, prefixName: nameof(TrashApply_Prefix), filter: CanPatchTrashMethod);

            // Não patchar IncreaseBagSize/SetLevel: mexem no estado interno da lixeira ao finalizar/abandonar missão.
            foreach (string method in new[] { "OnItemEnter", "TryCollectItem" })
                n += Patch("Il2Cpp.StandingGarbageCollector", method, prefixName: nameof(TrashApply_Prefix), filter: CanPatchTrashMethod);

            n += Patch("Il2Cpp.GarbageBagConnector", "GetMaxGarbageSize", prefixName: nameof(TrashIntInfinite_Prefix),
                filter: m => m.ReturnType == typeof(int) && CanPatchTrashMethod(m));
            return n;
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
                TrashProfile.Apply(__instance);

            return true;
        }

        private static bool TrashIntInfinite_Prefix(object __instance, ref int __result)
        {
            if (!CanUseTrashPatch(__instance))
                return true;

            TrashProfile.Apply(__instance);
            __result = InfiniteGarbageSize;
            return false;
        }

        private static void CleaningItem_Start_Postfix(object __instance)
        {
            _cleaningItemProfile?.Apply(__instance);
        }

        private static bool CleaningItem_Taint_Prefix(object __instance)
        {
            _cleaningItemProfile?.Apply(__instance);
            return false;
        }

        private static void CleaningLiquid_Postfix(object __instance)
        {
            DetergentProfile.Apply(__instance);
        }

        private static bool CleaningLiquid_IsEmpty_Prefix(object __instance, ref bool __result)
        {
            DetergentProfile.Apply(__instance);
            __result = false;
            return false;
        }

        private static bool CleaningLiquid_FloatInfinite_Prefix(object __instance, ref float __result)
        {
            DetergentProfile.Apply(__instance);
            __result = InfiniteValue;
            return false;
        }

        private static void PowerWasherStation_Postfix(object __instance)
        {
            WasherProfile.Apply(__instance);
        }

        private static bool PowerWasherStation_EmptyWaterTank_Prefix(object __instance)
        {
            WasherProfile.Apply(__instance);
            return false;
        }

        private static bool PowerWasherStation_HasWater_Prefix(object __instance, ref bool __result)
        {
            WasherProfile.Apply(__instance);
            __result = true;
            return false;
        }

        private static bool PowerWasherStation_CanSpray_Prefix(object __instance, ref bool __result)
        {
            WasherProfile.Apply(__instance);
            __result = true;
            return false;
        }

        private int Patch(string typeName, string methodName, string prefixName = null, string postfixName = null, Func<MethodInfo, bool> filter = null)
        {
            int patched = 0;

            try
            {
                Type type = FindType(typeName);
                if (type == null)
                {
                    MelonLogger.Warning($"Type not found (game update?): {typeName}");
                    return 0;
                }

                HarmonyMethod prefix = ResolvePatch(prefixName);
                HarmonyMethod postfix = ResolvePatch(postfixName);
                if (prefix == null && postfix == null)
                    return 0;

                // DeclaredOnly: patchar método herdado atinge a classe base inteira (ex.: UsableItem.Start em todo item do jogo).
                foreach (MethodInfo method in type.GetMethods(BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                {
                    if (method.Name != methodName)
                        continue;

                    if (method.IsAbstract || method.IsGenericMethod)
                        continue;

                    if (filter != null && !filter(method))
                        continue;

                    try
                    {
                        _harmony.Patch(method, prefix: prefix, postfix: postfix);
                        patched++;
                    }
                    catch (Exception e)
                    {
                        MelonLogger.Warning($"Failed to patch {typeName}.{methodName}: {e.Message}");
                    }
                }
            }
            catch (Exception e)
            {
                MelonLogger.Warning($"Failed to patch {typeName}.{methodName}: {e.Message}");
            }

            return patched;
        }

        private static HarmonyMethod ResolvePatch(string name)
        {
            if (name == null)
                return null;

            MethodInfo method = typeof(UltraCleaningToolsMod).GetMethod(name, BindingFlags.Static | BindingFlags.NonPublic);
            return method == null ? null : new HarmonyMethod(method);
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

        // Resolve os membros por reflection uma vez por tipo e cacheia; Apply vira só um loop de sets.
        private sealed class ApplyProfile
        {
            private readonly (string Name, object Value)[] _targets;
            private readonly Dictionary<Type, List<Setter>> _cache = new Dictionary<Type, List<Setter>>();

            private struct Setter
            {
                public FieldInfo Field;
                public PropertyInfo Property;
                public object Value;
            }

            public ApplyProfile(params (string, object)[] targets)
            {
                _targets = targets;
            }

            public void Apply(object instance)
            {
                if (instance == null)
                    return;

                Type type;
                try
                {
                    type = instance.GetType();
                }
                catch
                {
                    return;
                }

                if (!_cache.TryGetValue(type, out List<Setter> setters))
                {
                    setters = Resolve(type);
                    _cache[type] = setters;
                }

                for (int i = 0; i < setters.Count; i++)
                {
                    Setter setter = setters[i];
                    try
                    {
                        if (setter.Field != null)
                            setter.Field.SetValue(instance, setter.Value);
                        else
                            setter.Property.SetValue(instance, setter.Value);
                    }
                    catch
                    {
                    }
                }
            }

            private List<Setter> Resolve(Type type)
            {
                var setters = new List<Setter>();

                foreach ((string name, object value) in _targets)
                {
                    try
                    {
                        FieldInfo field = FindFieldRecursive(type, name);
                        if (field != null)
                        {
                            setters.Add(new Setter { Field = field, Value = ConvertValue(value, field.FieldType) });
                            continue;
                        }

                        PropertyInfo prop = FindPropertyRecursive(type, name);
                        if (prop != null && prop.CanWrite)
                            setters.Add(new Setter { Property = prop, Value = ConvertValue(value, prop.PropertyType) });
                    }
                    catch
                    {
                    }
                }

                return setters;
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
}
