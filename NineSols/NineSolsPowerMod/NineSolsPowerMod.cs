using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using BepInEx;
using BepInEx.Configuration;
using HarmonyLib;
using UnityEngine;

namespace NineSolsPowerMod
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public class NineSolsPowerModPlugin : BaseUnityPlugin
    {
        public const string PluginGuid = "opaaaaaaaaaaaa.ninesols.powermod";
        public const string PluginName = "Nine Sols Power Mod";
        public const string PluginVersion = "1.2.3";

        internal static Harmony HarmonyInstance;

        internal static ConfigEntry<bool> ModEnabled;
        internal static ConfigEntry<bool> GodMode;
        internal static ConfigEntry<float> HealthMultiplier;
        internal static ConfigEntry<float> AttackMultiplier;
        internal static ConfigEntry<float> GoldMultiplier;
        internal static ConfigEntry<bool> InfiniteDash;
        internal static ConfigEntry<bool> UnlimitedJades;

        private static readonly HashSet<string> PatchedMethods = new HashSet<string>();
        private static readonly Dictionary<string, object> OriginalValues = new Dictionary<string, object>();

        private static Type PlayerType;
        private static MethodInfo ResetJumpAndDashMethod;

        private static object CachedPlayerGoldData;
        private static Type CachedGoldPickUIType;
        private static FieldInfo CachedGoldPickUIPlayerGoldField;
        private static GoldValueAccessor CachedGoldAccessor;

        private float _attackPatchTimer;
        private float _jadePatchTimer;
        private float _jadeQuickPatchTimer;
        private float _jadeBurstTimer;

        private const float JadeNormalRefreshIntervalSeconds = 10.0f;
        private const float JadeBurstRefreshIntervalSeconds = 1.0f;
        private const float JadeBurstDurationSeconds = 6.0f;
        private static bool JadeRuntimeCacheBuilt;
        private static readonly List<Type> JadeRuntimeTypes = new List<Type>();
        private static readonly Dictionary<Type, JadeMemberPatchPlan> JadeMemberPatchPlans = new Dictionary<Type, JadeMemberPatchPlan>();

        private static readonly string[] AttackFieldsToBoost =
        {
            "PlayerAttackBaseDamageRatio",
            "noramlAttackRatio",
            "fooDamageAttackRatio"
        };

        private static readonly string[] StatNumericFieldsToBoost =
        {
            "BaseValue",
            "_value",
            "lastBaseValue",
            "_permanentValue"
        };

        private class GoldBoostState
        {
            public bool HadGoldBefore;
            public double GoldBefore;
            public readonly List<ChangedMember> ChangedMembers = new List<ChangedMember>();
        }

        private class ChangedMember
        {
            public object Target;
            public FieldInfo Field;
            public PropertyInfo Property;
            public object OriginalValue;
        }

        private class GoldValueAccessor
        {
            public object Target;
            public FieldInfo Field;
            public PropertyInfo Property;
            public Type ValueType;

            public bool CanRead => Target != null && (Field != null || (Property != null && Property.CanRead));
            public bool CanWrite => Target != null && (Field != null || (Property != null && Property.CanWrite));
        }

        private class JadeMemberPatchPlan
        {
            public readonly List<FieldInfo> CostFields = new List<FieldInfo>();
            public readonly List<FieldInfo> CapacityFields = new List<FieldInfo>();
            public readonly List<PropertyInfo> CostProperties = new List<PropertyInfo>();
            public readonly List<PropertyInfo> CapacityProperties = new List<PropertyInfo>();

            public bool HasAny
            {
                get
                {
                    return CostFields.Count > 0 ||
                           CapacityFields.Count > 0 ||
                           CostProperties.Count > 0 ||
                           CapacityProperties.Count > 0;
                }
            }
        }

        private void Awake()
        {
            ModEnabled = Config.Bind(
                "General",
                "Enable Mod",
                true,
                "Enable or disable the entire mod."
            );

            GodMode = Config.Bind(
                "Player",
                "God Mode",
                false,
                "Prevents the player from taking damage."
            );

            HealthMultiplier = Config.Bind(
                "Player",
                "Health Multiplier",
                2.0f,
                new ConfigDescription(
                    "Effective health multiplier. Example: 2 means received damage is divided by 2.",
                    new AcceptableValueRange<float>(1.0f, 50.0f)
                )
            );

            AttackMultiplier = Config.Bind(
                "Player",
                "Attack Multiplier",
                2.0f,
                new ConfigDescription(
                    "Multiplies the player's main attack damage ratios.",
                    new AcceptableValueRange<float>(1.0f, 100.0f)
                )
            );

            GoldMultiplier = Config.Bind(
                "Player",
                "Gold Multiplier",
                2.0f,
                new ConfigDescription(
                    "Multiplies gold received. Example: 2 means double gold.",
                    new AcceptableValueRange<float>(1.0f, 100.0f)
                )
            );

            InfiniteDash = Config.Bind(
                "Player",
                "Infinite Dash",
                true,
                "Resets dash after a real roll/dodge action."
            );

            UnlimitedJades = Config.Bind(
                "Player",
                "Unlimited Jades",
                true,
                "Allows equipping jades without computing power limitations. The automatic runtime scanner is disabled for performance; F8 can force a one-time refresh if needed."
            );

            HarmonyInstance = new Harmony(PluginGuid);

            PlayerType = AccessTools.TypeByName("Player");

            PatchGodModeAndHealth();
            PatchDefenseRatio();
            PatchGoldMultiplier();
            FindResetJumpAndDash();
            PatchDashReset();
            PatchUnlimitedJadesMethods();
        }

        private void Update()
        {
            if (!ModEnabled.Value)
                return;

            if (UnlimitedJades.Value && Input.GetKeyDown(KeyCode.F8))
                ApplyUnlimitedJadesFullScan();

            _attackPatchTimer += Time.unscaledDeltaTime;

            if (_attackPatchTimer < 1.0f)
                return;

            _attackPatchTimer = 0f;

            PatchAttackStats();
        }

        private void OnDestroy()
        {
            try
            {
                HarmonyInstance?.UnpatchSelf();
            }
            catch
            {
            }
        }

        private static void PatchGodModeAndHealth()
        {
            PatchByName(
                "PlayerHealth",
                "ReceiveDamage",
                prefixName: nameof(PlayerHealth_ReceiveDamage_Prefix)
            );

            PatchByName(
                "PlayerHealth",
                "ReceiveRecoverableDamage",
                prefixName: nameof(PlayerHealth_FloatDamage_Prefix)
            );

            PatchByName(
                "PlayerHealth",
                "CoughHurt",
                prefixName: nameof(PlayerHealth_FloatDamage_Prefix)
            );

            PatchByName(
                "PlayerHealth",
                "ReceiveDOT_Damage",
                prefixName: nameof(PlayerHealth_FloatDamage_Prefix)
            );
        }

        private static void PatchDefenseRatio()
        {
            PatchByName(
                "GameConfig",
                "PlayerDefenseDamageGlobalRatio",
                postfixName: nameof(GameConfig_PlayerDefenseDamageGlobalRatio_Postfix)
            );
        }

        private static void PatchGoldMultiplier()
        {
            PatchByName(
                "DropMoney",
                "AbsorbedByPlayerImplementation",
                prefixName: nameof(DropMoney_AbsorbedByPlayerImplementation_Prefix),
                postfixName: nameof(DropMoney_AbsorbedByPlayerImplementation_Postfix)
            );
        }

        private static void FindResetJumpAndDash()
        {
            if (PlayerType == null)
                return;

            MethodInfo[] methods = PlayerType.GetMethods(
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Instance |
                BindingFlags.FlattenHierarchy
            );

            foreach (MethodInfo method in methods)
            {
                if (method.Name != "ResetJumpAndDash")
                    continue;

                ParameterInfo[] parameters = method.GetParameters();

                if (parameters.Length == 2 &&
                    parameters[0].ParameterType == typeof(bool) &&
                    parameters[1].ParameterType == typeof(bool))
                {
                    ResetJumpAndDashMethod = method;
                    return;
                }
            }
        }

        private static void PatchDashReset()
        {
            Type rollStateType = AccessTools.TypeByName("PlayerRollState");

            if (rollStateType == null)
                return;

            PatchByName(
                "PlayerRollState",
                "OnStateEnter",
                postfixName: nameof(PlayerRollState_Postfix)
            );

            PatchByName(
                "PlayerRollState",
                "DodgeEnd",
                postfixName: nameof(PlayerRollState_Postfix)
            );
        }

        private static bool PlayerHealth_ReceiveDamage_Prefix()
        {
            if (!ModEnabled.Value || !GodMode.Value)
                return true;

            return false;
        }

        private static void PlayerHealth_FloatDamage_Prefix(ref float __0)
        {
            if (!ModEnabled.Value)
                return;

            if (GodMode.Value)
            {
                __0 = 0f;
                return;
            }

            float multiplier = HealthMultiplier.Value;

            if (multiplier <= 1.0f)
                return;

            __0 /= multiplier;
        }

        private static void GameConfig_PlayerDefenseDamageGlobalRatio_Postfix(ref float __result)
        {
            if (!ModEnabled.Value)
                return;

            if (GodMode.Value)
            {
                __result = 0f;
                return;
            }

            float multiplier = HealthMultiplier.Value;

            if (multiplier <= 1.0f)
                return;

            __result /= multiplier;
        }

        private static void DropMoney_AbsorbedByPlayerImplementation_Prefix(object __instance, out GoldBoostState __state)
        {
            __state = new GoldBoostState();

            if (!ModEnabled.Value)
                return;

            float multiplier = GoldMultiplier.Value;

            if (multiplier <= 1.0f)
                return;

            TryBoostDropMoneyObject(__instance, multiplier, __state.ChangedMembers);

            if (__state.ChangedMembers.Count == 0 && TryReadPlayerGold(out double gold))
            {
                __state.HadGoldBefore = true;
                __state.GoldBefore = gold;
            }
        }

        private static void DropMoney_AbsorbedByPlayerImplementation_Postfix(GoldBoostState __state)
        {
            if (!ModEnabled.Value || __state == null)
                return;

            if (__state.ChangedMembers.Count > 0)
            {
                RestoreChangedMembers(__state.ChangedMembers);
                return;
            }

            float multiplier = GoldMultiplier.Value;

            if (multiplier <= 1.0f || !__state.HadGoldBefore)
                return;

            if (!TryReadPlayerGold(out double afterGold))
                return;

            double gained = afterGold - __state.GoldBefore;

            if (gained <= 0.0)
                return;

            double extra = gained * (multiplier - 1.0f);
            double finalGold = afterGold + extra;

            TryWritePlayerGold(finalGold);
        }

        private static void TryBoostDropMoneyObject(object dropMoney, float multiplier, List<ChangedMember> changedMembers)
        {
            if (dropMoney == null || changedMembers == null)
                return;

            HashSet<int> visited = new HashSet<int>();
            BoostMoneyMembersRecursive(dropMoney, multiplier, changedMembers, visited, 0);
        }

        private static int BoostMoneyMembersRecursive(
            object obj,
            float multiplier,
            List<ChangedMember> changedMembers,
            HashSet<int> visited,
            int depth)
        {
            if (obj == null || depth > 3)
                return 0;

            Type type = obj.GetType();

            if (type == typeof(string) || type.IsPrimitive || type.IsEnum)
                return 0;

            int id = RuntimeHelpers.GetHashCode(obj);

            if (visited.Contains(id))
                return 0;

            visited.Add(id);

            int changed = 0;

            FieldInfo[] fields;

            try
            {
                fields = type.GetFields(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                fields = new FieldInfo[0];
            }

            foreach (FieldInfo field in fields)
            {
                if (field == null || field.IsInitOnly)
                    continue;

                string fieldName = field.Name.ToLowerInvariant();

                if (IsNumericType(field.FieldType) && IsMoneyLikeName(fieldName))
                {
                    if (TryBoostField(obj, field, multiplier, changedMembers))
                        changed++;

                    continue;
                }

                if (depth >= 3)
                    continue;

                if (!ShouldEnterNestedMoneyObject(fieldName, field.FieldType))
                    continue;

                object nested = null;

                try
                {
                    nested = field.GetValue(obj);
                }
                catch
                {
                }

                if (nested == null)
                    continue;

                changed += BoostMoneyMembersRecursive(nested, multiplier, changedMembers, visited, depth + 1);
            }

            PropertyInfo[] properties;

            try
            {
                properties = type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                properties = new PropertyInfo[0];
            }

            foreach (PropertyInfo property in properties)
            {
                if (property == null ||
                    !property.CanRead ||
                    !property.CanWrite ||
                    property.GetIndexParameters().Length > 0)
                {
                    continue;
                }

                string propertyName = property.Name.ToLowerInvariant();

                if (!IsNumericType(property.PropertyType) || !IsMoneyLikeName(propertyName))
                    continue;

                if (TryBoostProperty(obj, property, multiplier, changedMembers))
                    changed++;
            }

            return changed;
        }

        private static bool IsMoneyLikeName(string name)
        {
            if (string.IsNullOrEmpty(name))
                return false;

            return name.Contains("money") ||
                   name.Contains("gold") ||
                   name.Contains("value") ||
                   name.Contains("amount") ||
                   name.Contains("count") ||
                   name.Contains("reward") ||
                   name.Contains("currency");
        }

        private static bool ShouldEnterNestedMoneyObject(string memberName, Type type)
        {
            if (type == null)
                return false;

            if (type == typeof(string) || type.IsPrimitive || type.IsEnum)
                return false;

            string name = memberName.ToLowerInvariant();
            string typeName = type.Name.ToLowerInvariant();

            return IsMoneyLikeName(name) ||
                   typeName.Contains("money") ||
                   typeName.Contains("gold") ||
                   typeName.Contains("drop") ||
                   typeName.Contains("data") ||
                   typeName.Contains("stat") ||
                   typeName.Contains("scriptable");
        }

        private static bool TryBoostField(object target, FieldInfo field, float multiplier, List<ChangedMember> changedMembers)
        {
            try
            {
                object original = field.GetValue(target);

                if (!IsValidNumber(original))
                    return false;

                object boosted = MultiplyNumber(original, field.FieldType, multiplier);

                if (boosted == null || NumbersEqual(original, boosted))
                    return false;

                changedMembers.Add(new ChangedMember
                {
                    Target = target,
                    Field = field,
                    OriginalValue = original
                });

                field.SetValue(target, boosted);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool TryBoostProperty(object target, PropertyInfo property, float multiplier, List<ChangedMember> changedMembers)
        {
            try
            {
                object original = property.GetValue(target, null);

                if (!IsValidNumber(original))
                    return false;

                object boosted = MultiplyNumber(original, property.PropertyType, multiplier);

                if (boosted == null || NumbersEqual(original, boosted))
                    return false;

                changedMembers.Add(new ChangedMember
                {
                    Target = target,
                    Property = property,
                    OriginalValue = original
                });

                property.SetValue(target, boosted, null);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static void RestoreChangedMembers(List<ChangedMember> changedMembers)
        {
            foreach (ChangedMember changed in changedMembers)
            {
                if (changed == null || changed.Target == null)
                    continue;

                try
                {
                    if (changed.Field != null)
                        changed.Field.SetValue(changed.Target, changed.OriginalValue);
                    else if (changed.Property != null && changed.Property.CanWrite)
                        changed.Property.SetValue(changed.Target, changed.OriginalValue, null);
                }
                catch
                {
                }
            }

            changedMembers.Clear();
        }

        private static bool TryReadPlayerGold(out double gold)
        {
            gold = 0.0;

            object playerGold = TryGetPlayerGoldData();

            if (playerGold == null)
                return false;

            return TryReadNumericValue(playerGold, out gold);
        }

        private static bool TryWritePlayerGold(double gold)
        {
            object playerGold = TryGetPlayerGoldData();

            if (playerGold == null)
                return false;

            return TryWriteNumericValue(playerGold, gold);
        }

        private static object TryGetPlayerGoldData()
        {
            if (IsValidCachedObject(CachedPlayerGoldData))
                return CachedPlayerGoldData;

            if (CachedGoldPickUIType == null)
                CachedGoldPickUIType = AccessTools.TypeByName("GoldPickUI");

            if (CachedGoldPickUIType == null)
                return null;

            if (CachedGoldPickUIPlayerGoldField == null)
            {
                CachedGoldPickUIPlayerGoldField = CachedGoldPickUIType.GetField(
                    "playerGold",
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance
                );
            }

            if (CachedGoldPickUIPlayerGoldField == null)
                return null;

            UnityEngine.Object[] objects;

            try
            {
                objects = Resources.FindObjectsOfTypeAll(CachedGoldPickUIType);
            }
            catch
            {
                return null;
            }

            foreach (UnityEngine.Object obj in objects)
            {
                if (obj == null)
                    continue;

                object playerGold = CachedGoldPickUIPlayerGoldField.GetValue(obj);

                if (playerGold == null)
                    continue;

                GoldValueAccessor accessor = BuildGoldAccessor(playerGold, 0, new HashSet<int>());

                if (accessor == null || !accessor.CanRead || !accessor.CanWrite)
                    continue;

                CachedPlayerGoldData = playerGold;
                CachedGoldAccessor = accessor;
                return CachedPlayerGoldData;
            }

            return null;
        }

        private static bool IsValidCachedObject(object obj)
        {
            if (obj == null)
                return false;

            if (obj is UnityEngine.Object unityObject && unityObject == null)
                return false;

            return true;
        }

        private static GoldValueAccessor BuildGoldAccessor(object obj, int depth, HashSet<int> visited)
        {
            if (obj == null || depth > 3)
                return null;

            Type type = obj.GetType();

            if (type == typeof(string) || type.IsPrimitive || type.IsEnum)
                return null;

            int id = RuntimeHelpers.GetHashCode(obj);

            if (visited.Contains(id))
                return null;

            visited.Add(id);

            GoldValueAccessor direct = FindDirectNumericAccessor(obj, type);

            if (direct != null)
                return direct;

            FieldInfo[] fields;

            try
            {
                fields = type.GetFields(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                fields = new FieldInfo[0];
            }

            foreach (FieldInfo field in fields)
            {
                if (field == null)
                    continue;

                Type fieldType = field.FieldType;

                if (fieldType == typeof(string) || fieldType.IsPrimitive || fieldType.IsEnum)
                    continue;

                if (!ShouldEnterNestedGoldAccessor(field.Name, fieldType))
                    continue;

                object nested = null;

                try
                {
                    nested = field.GetValue(obj);
                }
                catch
                {
                }

                GoldValueAccessor nestedAccessor = BuildGoldAccessor(nested, depth + 1, visited);

                if (nestedAccessor != null)
                    return nestedAccessor;
            }

            PropertyInfo[] properties;

            try
            {
                properties = type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                properties = new PropertyInfo[0];
            }

            foreach (PropertyInfo property in properties)
            {
                if (property == null ||
                    !property.CanRead ||
                    property.GetIndexParameters().Length > 0)
                {
                    continue;
                }

                Type propertyType = property.PropertyType;

                if (propertyType == typeof(string) || propertyType.IsPrimitive || propertyType.IsEnum)
                    continue;

                if (!ShouldEnterNestedGoldAccessor(property.Name, propertyType))
                    continue;

                object nested = null;

                try
                {
                    nested = property.GetValue(obj, null);
                }
                catch
                {
                }

                GoldValueAccessor nestedAccessor = BuildGoldAccessor(nested, depth + 1, visited);

                if (nestedAccessor != null)
                    return nestedAccessor;
            }

            return null;
        }

        private static GoldValueAccessor FindDirectNumericAccessor(object obj, Type type)
        {
            FieldInfo[] fields;

            try
            {
                fields = type.GetFields(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                fields = new FieldInfo[0];
            }

            string[] preferredNames =
            {
                "RawValue",
                "rawValue",
                "BaseValue",
                "baseValue",
                "CurrentValue",
                "currentValue",
                "current",
                "_current",
                "_value",
                "value",
                "Value",
                "amount",
                "Amount",
                "gold",
                "Gold"
            };

            foreach (string preferredName in preferredNames)
            {
                FieldInfo field = fields.FirstOrDefault(f =>
                    f != null &&
                    !f.IsInitOnly &&
                    IsNumericType(f.FieldType) &&
                    string.Equals(f.Name, preferredName, StringComparison.OrdinalIgnoreCase)
                );

                if (field != null)
                {
                    return new GoldValueAccessor
                    {
                        Target = obj,
                        Field = field,
                        ValueType = field.FieldType
                    };
                }
            }

            foreach (FieldInfo field in fields)
            {
                if (field == null ||
                    field.IsInitOnly ||
                    !IsNumericType(field.FieldType))
                {
                    continue;
                }

                string name = field.Name.ToLowerInvariant();

                if (name.Contains("value") ||
                    name.Contains("gold") ||
                    name.Contains("money") ||
                    name.Contains("amount") ||
                    name.Contains("currency"))
                {
                    return new GoldValueAccessor
                    {
                        Target = obj,
                        Field = field,
                        ValueType = field.FieldType
                    };
                }
            }

            PropertyInfo[] properties;

            try
            {
                properties = type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                properties = new PropertyInfo[0];
            }

            foreach (string preferredName in preferredNames)
            {
                PropertyInfo property = properties.FirstOrDefault(p =>
                    p != null &&
                    p.CanRead &&
                    p.CanWrite &&
                    p.GetIndexParameters().Length == 0 &&
                    IsNumericType(p.PropertyType) &&
                    string.Equals(p.Name, preferredName, StringComparison.OrdinalIgnoreCase)
                );

                if (property != null)
                {
                    return new GoldValueAccessor
                    {
                        Target = obj,
                        Property = property,
                        ValueType = property.PropertyType
                    };
                }
            }

            foreach (PropertyInfo property in properties)
            {
                if (property == null ||
                    !property.CanRead ||
                    !property.CanWrite ||
                    property.GetIndexParameters().Length > 0 ||
                    !IsNumericType(property.PropertyType))
                {
                    continue;
                }

                string name = property.Name.ToLowerInvariant();

                if (name.Contains("value") ||
                    name.Contains("gold") ||
                    name.Contains("money") ||
                    name.Contains("amount") ||
                    name.Contains("currency"))
                {
                    return new GoldValueAccessor
                    {
                        Target = obj,
                        Property = property,
                        ValueType = property.PropertyType
                    };
                }
            }

            return null;
        }

        private static bool ShouldEnterNestedGoldAccessor(string memberName, Type type)
        {
            if (type == null)
                return false;

            string name = memberName.ToLowerInvariant();
            string typeName = type.Name.ToLowerInvariant();

            return name.Contains("value") ||
                   name.Contains("gold") ||
                   name.Contains("money") ||
                   name.Contains("amount") ||
                   name.Contains("currency") ||
                   name.Contains("data") ||
                   name.Contains("stat") ||
                   typeName.Contains("value") ||
                   typeName.Contains("gold") ||
                   typeName.Contains("money") ||
                   typeName.Contains("data") ||
                   typeName.Contains("stat") ||
                   typeName.Contains("scriptable");
        }

        private static bool TryReadNumericValue(object obj, out double value)
        {
            value = 0.0;

            if (obj == null)
                return false;

            if (CachedGoldAccessor == null || !CachedGoldAccessor.CanRead)
                CachedGoldAccessor = BuildGoldAccessor(obj, 0, new HashSet<int>());

            if (CachedGoldAccessor == null || !CachedGoldAccessor.CanRead)
                return false;

            try
            {
                object raw;

                if (CachedGoldAccessor.Field != null)
                    raw = CachedGoldAccessor.Field.GetValue(CachedGoldAccessor.Target);
                else
                    raw = CachedGoldAccessor.Property.GetValue(CachedGoldAccessor.Target, null);

                if (!IsValidNumber(raw))
                    return false;

                value = Convert.ToDouble(raw);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool TryWriteNumericValue(object obj, double value)
        {
            if (obj == null)
                return false;

            if (CachedGoldAccessor == null || !CachedGoldAccessor.CanWrite)
                CachedGoldAccessor = BuildGoldAccessor(obj, 0, new HashSet<int>());

            if (CachedGoldAccessor == null || !CachedGoldAccessor.CanWrite)
                return false;

            object converted = ConvertNumber(value, CachedGoldAccessor.ValueType);

            if (converted == null)
                return false;

            try
            {
                if (CachedGoldAccessor.Field != null)
                    CachedGoldAccessor.Field.SetValue(CachedGoldAccessor.Target, converted);
                else
                    CachedGoldAccessor.Property.SetValue(CachedGoldAccessor.Target, converted, null);

                return true;
            }
            catch
            {
                return false;
            }
        }

        private static void PlayerRollState_Postfix(object __instance)
        {
            if (!ModEnabled.Value || !InfiniteDash.Value)
                return;

            object player = TryGetPlayerFromObject(__instance);

            if (player == null)
                return;

            ResetPlayerDash(player);
        }

        private static object TryGetPlayerFromObject(object instance)
        {
            if (instance == null)
                return null;

            if (PlayerType != null && PlayerType.IsInstanceOfType(instance))
                return instance;

            Type type = instance.GetType();

            FieldInfo playerField = type.GetField(
                "player",
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Instance
            );

            if (playerField != null)
            {
                object value = playerField.GetValue(instance);

                if (value != null)
                    return value;
            }

            PropertyInfo playerProperty = type.GetProperty(
                "player",
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Instance
            );

            if (playerProperty != null && playerProperty.CanRead)
            {
                object value = playerProperty.GetValue(instance, null);

                if (value != null)
                    return value;
            }

            return null;
        }

        private static void ResetPlayerDash(object player)
        {
            if (player == null || ResetJumpAndDashMethod == null)
                return;

            try
            {
                ResetJumpAndDashMethod.Invoke(player, new object[] { true, true });
            }
            catch
            {
            }
        }

        private static void PatchAttackStats()
        {
            float multiplier = AttackMultiplier.Value;

            if (multiplier <= 1.0f)
                return;

            Assembly asm = GetGameAssembly();

            if (asm == null)
                return;

            Type abilityType = SafeGetTypes(asm)
                .FirstOrDefault(t => t != null && t.Name == "PlayerMainAbilityCollection");

            if (abilityType == null)
                return;

            UnityEngine.Object[] objects;

            try
            {
                objects = Resources.FindObjectsOfTypeAll(abilityType);
            }
            catch
            {
                return;
            }

            foreach (UnityEngine.Object obj in objects)
            {
                if (obj == null)
                    continue;

                foreach (string fieldName in AttackFieldsToBoost)
                    BoostStatField(obj, fieldName, multiplier);
            }
        }

        private static void BoostStatField(object owner, string fieldName, float multiplier)
        {
            try
            {
                FieldInfo field = owner.GetType().GetField(
                    fieldName,
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance
                );

                if (field == null)
                    return;

                object statData = field.GetValue(owner);

                if (statData == null)
                    return;

                object statObject = GetFieldOrSelf(statData, "stat");

                if (statObject == null)
                    return;

                foreach (string numericFieldName in StatNumericFieldsToBoost)
                    BoostNumericField(statObject, fieldName, numericFieldName, multiplier);
            }
            catch
            {
            }
        }

        private static object GetFieldOrSelf(object obj, string fieldName)
        {
            if (obj == null)
                return null;

            FieldInfo field = obj.GetType().GetField(
                fieldName,
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Instance
            );

            if (field == null)
                return obj;

            object value = field.GetValue(obj);

            return value ?? obj;
        }

        private static void BoostNumericField(object obj, string rootName, string fieldName, float multiplier)
        {
            try
            {
                if (obj == null)
                    return;

                FieldInfo field = obj.GetType().GetField(
                    fieldName,
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance
                );

                if (field == null || field.IsInitOnly)
                    return;

                Type type = field.FieldType;

                if (!IsNumericType(type))
                    return;

                object currentValue = field.GetValue(obj);

                if (!IsValidNumber(currentValue))
                    return;

                string key = RuntimeHelpers.GetHashCode(obj) + "|" + rootName + "|" + fieldName;

                if (!OriginalValues.ContainsKey(key))
                    OriginalValues[key] = currentValue;

                object originalValue = OriginalValues[key];
                object targetValue = MultiplyNumber(originalValue, type, multiplier);

                if (targetValue == null)
                    return;

                if (NumbersEqual(currentValue, targetValue))
                    return;

                field.SetValue(obj, targetValue);
            }
            catch
            {
            }
        }


        private static bool ShouldTriggerJadeRefreshBurst()
        {
            return Input.GetKeyDown(KeyCode.F8) ||
                   Input.GetKeyDown(KeyCode.Tab) ||
                   Input.GetKeyDown(KeyCode.Escape) ||
                   Input.GetKeyDown(KeyCode.I) ||
                   Input.GetKeyDown(KeyCode.J) ||
                   Input.GetKeyDown(KeyCode.Return) ||
                   Input.GetKeyDown(KeyCode.JoystickButton6) ||
                   Input.GetKeyDown(KeyCode.JoystickButton7);
        }


        private static void PatchUnlimitedJadesMethods()
        {
            Assembly asm = GetGameAssembly();

            if (asm == null)
                return;

            Type[] types = SafeGetTypes(asm);

            foreach (Type type in types)
            {
                if (type == null)
                    continue;

                MethodInfo[] methods;

                try
                {
                    methods = type.GetMethods(
                        BindingFlags.Public |
                        BindingFlags.NonPublic |
                        BindingFlags.Instance |
                        BindingFlags.Static |
                        BindingFlags.DeclaredOnly
                    );
                }
                catch
                {
                    continue;
                }

                foreach (MethodInfo method in methods)
                {
                    if (method == null ||
                        method.IsAbstract ||
                        method.ContainsGenericParameters ||
                        method.IsConstructor)
                    {
                        continue;
                    }

                    Type returnType = method.ReturnType;

                    if (returnType == typeof(bool))
                    {
                        if (ShouldForceFalseJadeBoolMethod(method))
                            PatchMethod(method, postfixName: nameof(JadeBoolFalse_Postfix));
                        else if (ShouldForceTrueJadeBoolMethod(method))
                            PatchMethod(method, postfixName: nameof(JadeBoolTrue_Postfix));

                        continue;
                    }

                    if (!IsNumericType(returnType))
                        continue;

                    JadeNumericPatchKind kind = GetJadeNumericPatchKind(method);

                    if (kind == JadeNumericPatchKind.None)
                        continue;

                    if (kind == JadeNumericPatchKind.CostZero)
                    {
                        if (returnType == typeof(int))
                            PatchMethod(method, postfixName: nameof(JadeIntCostZero_Postfix));
                        else if (returnType == typeof(float))
                            PatchMethod(method, postfixName: nameof(JadeFloatCostZero_Postfix));
                        else if (returnType == typeof(double))
                            PatchMethod(method, postfixName: nameof(JadeDoubleCostZero_Postfix));
                        else if (returnType == typeof(long))
                            PatchMethod(method, postfixName: nameof(JadeLongCostZero_Postfix));
                        else if (returnType == typeof(short))
                            PatchMethod(method, postfixName: nameof(JadeShortCostZero_Postfix));
                    }
                    else if (kind == JadeNumericPatchKind.CapacityHigh)
                    {
                        if (returnType == typeof(int))
                            PatchMethod(method, postfixName: nameof(JadeIntCapacityHigh_Postfix));
                        else if (returnType == typeof(float))
                            PatchMethod(method, postfixName: nameof(JadeFloatCapacityHigh_Postfix));
                        else if (returnType == typeof(double))
                            PatchMethod(method, postfixName: nameof(JadeDoubleCapacityHigh_Postfix));
                        else if (returnType == typeof(long))
                            PatchMethod(method, postfixName: nameof(JadeLongCapacityHigh_Postfix));
                        else if (returnType == typeof(short))
                            PatchMethod(method, postfixName: nameof(JadeShortCapacityHigh_Postfix));
                    }
                }
            }
        }

        private enum JadeNumericPatchKind
        {
            None,
            CostZero,
            CapacityHigh
        }

        private static void JadeBoolTrue_Postfix(ref bool __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = true;
        }

        private static void JadeBoolFalse_Postfix(ref bool __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = false;
        }

        private static void JadeIntCostZero_Postfix(ref int __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = 0;
        }

        private static void JadeFloatCostZero_Postfix(ref float __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = 0f;
        }

        private static void JadeDoubleCostZero_Postfix(ref double __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = 0.0;
        }

        private static void JadeLongCostZero_Postfix(ref long __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = 0L;
        }

        private static void JadeShortCostZero_Postfix(ref short __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value)
                __result = 0;
        }

        private static void JadeIntCapacityHigh_Postfix(ref int __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value && __result < 99)
                __result = 99;
        }

        private static void JadeFloatCapacityHigh_Postfix(ref float __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value && __result < 99f)
                __result = 99f;
        }

        private static void JadeDoubleCapacityHigh_Postfix(ref double __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value && __result < 99.0)
                __result = 99.0;
        }

        private static void JadeLongCapacityHigh_Postfix(ref long __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value && __result < 99L)
                __result = 99L;
        }

        private static void JadeShortCapacityHigh_Postfix(ref short __result)
        {
            if (ModEnabled.Value && UnlimitedJades.Value && __result < 99)
                __result = 99;
        }

        private static void BuildJadeRuntimeCache()
        {
            if (JadeRuntimeCacheBuilt)
                return;

            JadeRuntimeCacheBuilt = true;
            JadeRuntimeTypes.Clear();
            JadeMemberPatchPlans.Clear();

            Assembly asm = GetGameAssembly();

            if (asm == null)
                return;

            Type[] types = SafeGetTypes(asm);

            foreach (Type type in types)
            {
                if (type == null)
                    continue;

                if (!typeof(UnityEngine.Object).IsAssignableFrom(type))
                    continue;

                string typeName = type.FullName != null
                    ? type.FullName.ToLowerInvariant()
                    : type.Name.ToLowerInvariant();

                if (!IsJadeOrComputingText(typeName))
                    continue;

                JadeMemberPatchPlan plan = BuildJadeMemberPatchPlan(type);

                if (plan == null || !plan.HasAny)
                    continue;

                JadeRuntimeTypes.Add(type);
                JadeMemberPatchPlans[type] = plan;
            }
        }

        private static JadeMemberPatchPlan BuildJadeMemberPatchPlan(Type type)
        {
            if (type == null)
                return null;

            JadeMemberPatchPlan plan = new JadeMemberPatchPlan();

            FieldInfo[] fields;

            try
            {
                fields = type.GetFields(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                fields = new FieldInfo[0];
            }

            foreach (FieldInfo field in fields)
            {
                if (field == null ||
                    field.IsInitOnly ||
                    !IsNumericType(field.FieldType))
                {
                    continue;
                }

                string fullName = BuildMemberSearchText(type, field.Name);

                if (IsJadeCostText(fullName))
                    plan.CostFields.Add(field);
                else if (IsJadeCapacityText(fullName))
                    plan.CapacityFields.Add(field);
            }

            PropertyInfo[] properties;

            try
            {
                properties = type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                properties = new PropertyInfo[0];
            }

            foreach (PropertyInfo property in properties)
            {
                if (property == null ||
                    !property.CanRead ||
                    !property.CanWrite ||
                    property.GetIndexParameters().Length > 0 ||
                    !IsNumericType(property.PropertyType))
                {
                    continue;
                }

                string fullName = BuildMemberSearchText(type, property.Name);

                if (IsJadeCostText(fullName))
                    plan.CostProperties.Add(property);
                else if (IsJadeCapacityText(fullName))
                    plan.CapacityProperties.Add(property);
            }

            return plan;
        }

        private static void ApplyUnlimitedJadesFullScan()
        {
            if (!ModEnabled.Value || !UnlimitedJades.Value)
                return;

            Assembly asm = GetGameAssembly();

            if (asm == null)
                return;

            Type[] types = SafeGetTypes(asm);

            foreach (Type type in types)
            {
                if (type == null)
                    continue;

                if (!typeof(UnityEngine.Object).IsAssignableFrom(type))
                    continue;

                string typeName = type.FullName != null
                    ? type.FullName.ToLowerInvariant()
                    : type.Name.ToLowerInvariant();

                if (!IsJadeOrComputingText(typeName))
                    continue;

                UnityEngine.Object[] objects;

                try
                {
                    objects = Resources.FindObjectsOfTypeAll(type);
                }
                catch
                {
                    continue;
                }

                foreach (UnityEngine.Object obj in objects)
                {
                    if (obj == null)
                        continue;

                    ApplyUnlimitedJadesToObjectFullScan(obj);
                }
            }
        }

        private static void ApplyUnlimitedJadesToObjectFullScan(object obj)
        {
            if (obj == null)
                return;

            Type type = obj.GetType();

            FieldInfo[] fields;

            try
            {
                fields = type.GetFields(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                fields = new FieldInfo[0];
            }

            foreach (FieldInfo field in fields)
            {
                if (field == null ||
                    field.IsInitOnly ||
                    !IsNumericType(field.FieldType))
                {
                    continue;
                }

                string fullName = BuildMemberSearchText(type, field.Name);

                try
                {
                    if (IsJadeCostText(fullName))
                    {
                        object value = ConvertNumber(0.0, field.FieldType);

                        if (value != null)
                            field.SetValue(obj, value);
                    }
                    else if (IsJadeCapacityText(fullName))
                    {
                        object current = field.GetValue(obj);

                        if (!IsValidNumberForJadePatch(current))
                            continue;

                        double currentValue = Convert.ToDouble(current);

                        if (currentValue >= 99.0)
                            continue;

                        object value = ConvertNumber(99.0, field.FieldType);

                        if (value != null)
                            field.SetValue(obj, value);
                    }
                }
                catch
                {
                }
            }

            PropertyInfo[] properties;

            try
            {
                properties = type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly
                );
            }
            catch
            {
                properties = new PropertyInfo[0];
            }

            foreach (PropertyInfo property in properties)
            {
                if (property == null ||
                    !property.CanRead ||
                    !property.CanWrite ||
                    property.GetIndexParameters().Length > 0 ||
                    !IsNumericType(property.PropertyType))
                {
                    continue;
                }

                string fullName = BuildMemberSearchText(type, property.Name);

                try
                {
                    if (IsJadeCostText(fullName))
                    {
                        object value = ConvertNumber(0.0, property.PropertyType);

                        if (value != null)
                            property.SetValue(obj, value, null);
                    }
                    else if (IsJadeCapacityText(fullName))
                    {
                        object current = property.GetValue(obj, null);

                        if (!IsValidNumberForJadePatch(current))
                            continue;

                        double currentValue = Convert.ToDouble(current);

                        if (currentValue >= 99.0)
                            continue;

                        object value = ConvertNumber(99.0, property.PropertyType);

                        if (value != null)
                            property.SetValue(obj, value, null);
                    }
                }
                catch
                {
                }
            }
        }


        private static void ApplyUnlimitedJades()
        {
            if (!ModEnabled.Value || !UnlimitedJades.Value)
                return;

            BuildJadeRuntimeCache();

            foreach (Type type in JadeRuntimeTypes)
            {
                if (type == null)
                    continue;

                JadeMemberPatchPlan plan;

                if (!JadeMemberPatchPlans.TryGetValue(type, out plan) ||
                    plan == null ||
                    !plan.HasAny)
                {
                    continue;
                }

                UnityEngine.Object[] objects;

                try
                {
                    objects = Resources.FindObjectsOfTypeAll(type);
                }
                catch
                {
                    continue;
                }

                foreach (UnityEngine.Object obj in objects)
                {
                    if (obj == null)
                        continue;

                    ApplyUnlimitedJadesToObject(obj, plan);
                }
            }
        }

        private static void ApplyUnlimitedJadesToObject(object obj, JadeMemberPatchPlan plan)
        {
            if (obj == null || plan == null)
                return;

            foreach (FieldInfo field in plan.CostFields)
            {
                try
                {
                    object value = ConvertNumber(0.0, field.FieldType);

                    if (value != null)
                        field.SetValue(obj, value);
                }
                catch
                {
                }
            }

            foreach (PropertyInfo property in plan.CostProperties)
            {
                try
                {
                    object value = ConvertNumber(0.0, property.PropertyType);

                    if (value != null)
                        property.SetValue(obj, value, null);
                }
                catch
                {
                }
            }

            foreach (FieldInfo field in plan.CapacityFields)
            {
                try
                {
                    object current = field.GetValue(obj);

                    if (!IsValidNumberForJadePatch(current))
                        continue;

                    double currentValue = Convert.ToDouble(current);

                    if (currentValue >= 99.0)
                        continue;

                    object value = ConvertNumber(99.0, field.FieldType);

                    if (value != null)
                        field.SetValue(obj, value);
                }
                catch
                {
                }
            }

            foreach (PropertyInfo property in plan.CapacityProperties)
            {
                try
                {
                    object current = property.GetValue(obj, null);

                    if (!IsValidNumberForJadePatch(current))
                        continue;

                    double currentValue = Convert.ToDouble(current);

                    if (currentValue >= 99.0)
                        continue;

                    object value = ConvertNumber(99.0, property.PropertyType);

                    if (value != null)
                        property.SetValue(obj, value, null);
                }
                catch
                {
                }
            }
        }

        private static bool ShouldForceTrueJadeBoolMethod(MethodInfo method)
        {
            if (method == null)
                return false;

            string text = BuildMethodSearchText(method);

            if (!IsJadeOrComputingText(text))
                return false;

            if (ShouldForceFalseJadeBoolMethod(method))
                return false;

            bool hasCanWord =
                text.Contains("can") ||
                text.Contains("allow") ||
                text.Contains("valid") ||
                text.Contains("enable") ||
                text.Contains("equipable") ||
                text.Contains("equippable") ||
                text.Contains("afford") ||
                text.Contains("enough") ||
                text.Contains("check") ||
                text.Contains("available") ||
                text.Contains("usable");

            bool hasEquipWord =
                text.Contains("equip") ||
                text.Contains("active") ||
                text.Contains("activate") ||
                text.Contains("insert") ||
                text.Contains("select") ||
                text.Contains("set") ||
                text.Contains("use") ||
                text.Contains("add") ||
                text.Contains("unlock");

            if (hasCanWord && hasEquipWord)
                return true;

            bool isComputingPowerCheck =
                (text.Contains("computing") || text.Contains("compute")) &&
                (text.Contains("enough") ||
                 text.Contains("afford") ||
                 text.Contains("available") ||
                 text.Contains("valid") ||
                 text.Contains("check") ||
                 text.Contains("capacity") ||
                 text.Contains("limit"));

            if (isComputingPowerCheck)
                return true;

            bool isJadeLimitCheck =
                text.Contains("jade") &&
                (text.Contains("capacity") ||
                 text.Contains("limit") ||
                 text.Contains("slot") ||
                 text.Contains("point") ||
                 text.Contains("power")) &&
                (text.Contains("can") ||
                 text.Contains("allow") ||
                 text.Contains("valid") ||
                 text.Contains("check") ||
                 text.Contains("enough") ||
                 text.Contains("afford"));

            return isJadeLimitCheck;
        }

        private static bool ShouldForceFalseJadeBoolMethod(MethodInfo method)
        {
            if (method == null)
                return false;

            string text = BuildMethodSearchText(method);

            if (!IsJadeOrComputingText(text))
                return false;

            return text.Contains("overlimit") ||
                   text.Contains("overcapacity") ||
                   text.Contains("exceed") ||
                   text.Contains("overflow") ||
                   text.Contains("notenough") ||
                   text.Contains("not_enough") ||
                   text.Contains("insufficient") ||
                   text.Contains("fullslot") ||
                   text.Contains("slotfull") ||
                   text.Contains("isfull");
        }

        private static JadeNumericPatchKind GetJadeNumericPatchKind(MethodInfo method)
        {
            if (method == null)
                return JadeNumericPatchKind.None;

            string text = BuildMethodSearchText(method);

            if (!IsJadeOrComputingText(text))
                return JadeNumericPatchKind.None;

            if (IsJadeCostText(text))
                return JadeNumericPatchKind.CostZero;

            if (IsJadeCapacityText(text))
                return JadeNumericPatchKind.CapacityHigh;

            return JadeNumericPatchKind.None;
        }

        private static string BuildMethodSearchText(MethodInfo method)
        {
            string typeName = method.DeclaringType != null && method.DeclaringType.FullName != null
                ? method.DeclaringType.FullName
                : string.Empty;

            return (typeName + "." + method.Name)
                .Replace("get_", string.Empty)
                .Replace("set_", string.Empty)
                .ToLowerInvariant();
        }

        private static string BuildMemberSearchText(Type type, string memberName)
        {
            string typeName = type != null && type.FullName != null
                ? type.FullName
                : string.Empty;

            return (typeName + "." + memberName).ToLowerInvariant();
        }

        private static bool IsJadeOrComputingText(string text)
        {
            if (string.IsNullOrEmpty(text))
                return false;

            return text.Contains("jade") ||
                   text.Contains("computing") ||
                   text.Contains("compute") ||
                   text.Contains("tao90") ||
                   text.Contains("tao_90");
        }

        private static bool IsJadeCostText(string text)
        {
            if (string.IsNullOrEmpty(text))
                return false;

            if (!IsJadeOrComputingText(text))
                return false;

            return text.Contains("cost") ||
                   text.Contains("consume") ||
                   text.Contains("consumption") ||
                   text.Contains("require") ||
                   text.Contains("required") ||
                   text.Contains("need") ||
                   text.Contains("usage") ||
                   text.Contains("usedpoint") ||
                   text.Contains("usepoint") ||
                   text.Contains("powercost") ||
                   text.Contains("computingcost") ||
                   text.Contains("computecost") ||
                   text.Contains("slotcost") ||
                   text.Contains("jadepointcost") ||
                   text.Contains("pointcost") ||
                   text.Contains("requiredpoint") ||
                   text.Contains("requirepoint") ||
                   text.Contains("usepoint") ||
                   text.Contains("usedpoint") ||
                   text.Contains("spent") ||
                   text.Contains("spend") ||
                   text.Contains("occupied") ||
                   text.Contains("equippedcost") ||
                   text.Contains("costsum");
        }

        private static bool IsJadeCapacityText(string text)
        {
            if (string.IsNullOrEmpty(text))
                return false;

            if (!IsJadeOrComputingText(text))
                return false;

            if (IsJadeCostText(text))
                return false;

            return text.Contains("capacity") ||
                   text.Contains("max") ||
                   text.Contains("limit") ||
                   text.Contains("available") ||
                   text.Contains("remain") ||
                   text.Contains("remaining") ||
                   text.Contains("total") ||
                   text.Contains("computingpower") ||
                   text.Contains("computepower") ||
                   text.Contains("computepoint") ||
                   text.Contains("computingpoint") ||
                   text.Contains("maxpoint") ||
                   text.Contains("maxslot") ||
                   text.Contains("slotlimit") ||
                   text.Contains("slotalimit") ||
                   text.Contains("equiplimit") ||
                   text.Contains("equipcapacity") ||
                   text.Contains("maxequip") ||
                   text.Contains("upperlimit");
        }

        private static bool IsValidNumberForJadePatch(object value)
        {
            if (value == null)
                return false;

            try
            {
                double d = Convert.ToDouble(value);

                if (double.IsNaN(d) || double.IsInfinity(d))
                    return false;

                if (d < 0.0 || d > 1000.0)
                    return false;

                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool IsNumericType(Type type)
        {
            return type == typeof(float) ||
                   type == typeof(double) ||
                   type == typeof(int) ||
                   type == typeof(long) ||
                   type == typeof(short);
        }

        private static bool IsValidNumber(object value)
        {
            if (value == null)
                return false;

            try
            {
                double d = Convert.ToDouble(value);

                if (double.IsNaN(d) || double.IsInfinity(d))
                    return false;

                if (Math.Abs(d) < 0.0001)
                    return false;

                if (Math.Abs(d) > 100000000.0)
                    return false;

                return true;
            }
            catch
            {
                return false;
            }
        }

        private static object MultiplyNumber(object value, Type targetType, float multiplier)
        {
            try
            {
                double original = Convert.ToDouble(value);
                double result = original * multiplier;

                return ConvertNumber(result, targetType);
            }
            catch
            {
                return null;
            }
        }

        private static object ConvertNumber(double value, Type targetType)
        {
            try
            {
                if (targetType == typeof(float))
                    return (float)value;

                if (targetType == typeof(double))
                    return value;

                if (targetType == typeof(int))
                    return Mathf.RoundToInt((float)value);

                if (targetType == typeof(long))
                    return (long)Math.Round(value);

                if (targetType == typeof(short))
                    return (short)Math.Round(value);

                return null;
            }
            catch
            {
                return null;
            }
        }

        private static bool NumbersEqual(object a, object b)
        {
            try
            {
                double da = Convert.ToDouble(a);
                double db = Convert.ToDouble(b);

                return Math.Abs(da - db) < 0.0001;
            }
            catch
            {
                return Equals(a, b);
            }
        }

        private static void PatchByName(string typeName, string methodName, string prefixName = null, string postfixName = null)
        {
            try
            {
                Type type = AccessTools.TypeByName(typeName);

                if (type == null)
                    return;

                MethodInfo method = AccessTools.Method(type, methodName);

                if (method == null)
                    return;

                PatchMethod(method, prefixName, postfixName);
            }
            catch
            {
            }
        }

        private static void PatchMethod(MethodInfo method, string prefixName = null, string postfixName = null)
        {
            try
            {
                if (method == null || method.IsAbstract || method.ContainsGenericParameters)
                    return;

                string key =
                    $"{method.DeclaringType?.FullName}.{method.Name}({string.Join(",", method.GetParameters().Select(p => p.ParameterType.FullName))})";

                if (PatchedMethods.Contains(key))
                    return;

                HarmonyMethod prefix = null;
                HarmonyMethod postfix = null;

                if (!string.IsNullOrEmpty(prefixName))
                {
                    MethodInfo prefixMethod = AccessTools.Method(typeof(NineSolsPowerModPlugin), prefixName);

                    if (prefixMethod == null)
                        return;

                    prefix = new HarmonyMethod(prefixMethod);
                }

                if (!string.IsNullOrEmpty(postfixName))
                {
                    MethodInfo postfixMethod = AccessTools.Method(typeof(NineSolsPowerModPlugin), postfixName);

                    if (postfixMethod == null)
                        return;

                    postfix = new HarmonyMethod(postfixMethod);
                }

                HarmonyInstance.Patch(method, prefix, postfix);
                PatchedMethods.Add(key);
            }
            catch
            {
            }
        }

        private static Assembly GetGameAssembly()
        {
            return AppDomain.CurrentDomain
                .GetAssemblies()
                .FirstOrDefault(a => a.GetName().Name == "Assembly-CSharp");
        }

        private static Type[] SafeGetTypes(Assembly assembly)
        {
            try
            {
                return assembly.GetTypes();
            }
            catch (ReflectionTypeLoadException ex)
            {
                return ex.Types.Where(t => t != null).ToArray();
            }
            catch
            {
                return new Type[0];
            }
        }
    }
}