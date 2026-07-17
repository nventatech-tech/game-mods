using System;
using BepInEx;
using BepInEx.Configuration;
using HarmonyLib;
using UnityEngine;

[BepInPlugin("br.opaaaaaaaaaaaa.onepunchhk", "One Punch HK", "1.1")]
public class OnePunchHK : BaseUnityPlugin
{
    #region Fields

    internal static OnePunchHK Instance;

    private Harmony harmony;

    internal static ConfigEntry<bool> ModEnabled;
    internal static ConfigEntry<KeyboardShortcut> ToggleKey;

    internal static ConfigEntry<DamageMode> NailMode;

    internal static ConfigEntry<bool> InfiniteCharmSlots;

    internal static ConfigEntry<bool> KeepGeoOnDeath;
    internal static ConfigEntry<GeoGainMode> GeoGainMultiplier;

    internal static ConfigEntry<bool> InfiniteShadowDash;
    private static readonly AccessTools.FieldRef<HeroController, float> ShadowDashTimerRef =
        AccessTools.FieldRefAccess<HeroController, float>("shadowDashTimer");

    internal static ConfigEntry<bool> ImmortalPlayer;

    internal static ConfigEntry<bool> FreeSoulUsage;

    #endregion

    #region Enums

    public enum DamageMode
    {
        Off,
        X2,
        X3,
        X4,
        X5,
        HitKill
    }

    public enum GeoGainMode
    {
        Off,
        X2,
        X3,
        X4,
        X5
    }

    #endregion

    #region Unity Lifecycle

    private void Awake()
    {
        Instance = this;

        BindConfigs();

        harmony = new Harmony("br.opaaaaaaaaaaaa.onepunchhk");
        harmony.PatchAll();

        Logger.LogInfo("Loaded.");
    }

    private void Update()
    {
        if (ToggleKey.Value.IsDown())
        {
            ModEnabled.Value = !ModEnabled.Value;
            Logger.LogInfo(ModEnabled.Value ? "Enabled." : "Disabled.");
        }
    }

    private void LateUpdate()
    {
        HandleFreeSoulUsage();
        HandleKeepGeoOnDeath();
    }

    private void OnDestroy()
    {
        harmony?.UnpatchSelf();
    }

    #endregion

    #region Config

    private void BindConfigs()
    {
        InfiniteCharmSlots = Config.Bind(
            "Charms",
            "InfiniteCharmSlots",
            false,
            "Ignore charm notch limit."
        );

        NailMode = Config.Bind(
            "Damage",
            "NailDamageMode",
            DamageMode.Off,
            "Nail damage mode: Off, X2, X3, X4, X5, HitKill."
        );

        ModEnabled = Config.Bind(
            "General",
            "Enabled",
            true,
            "Enable the mod."
        );

        GeoGainMultiplier = Config.Bind(
            "Geo",
            "GeoGainMultiplier",
            GeoGainMode.Off,
            "Geo multiplier: Off, X2, X3, X4, X5."
        );

        KeepGeoOnDeath = Config.Bind(
            "Geo",
            "KeepGeoOnDeath",
            false,
            "Keep geo after death."
        );

        ToggleKey = Config.Bind(
            "Hotkeys",
            "ToggleMod",
            new KeyboardShortcut(KeyCode.F6),
            "Toggle the mod."
        );

        InfiniteShadowDash = Config.Bind(
            "Movement",
            "InfiniteShadowDash",
            false,
            "Remove shadow dash cooldown."
        );

        ImmortalPlayer = Config.Bind(
            "Player",
            "ImmortalPlayer",
            false,
            "Prevent health loss."
        );

        FreeSoulUsage = Config.Bind(
            "Soul",
            "FreeSoulUsage",
            false,
            "Prevent soul spending."
        );
    }

    #endregion

    #region Helpers

    internal static int CalculateDamage(int originalDamage, int enemyHp, DamageMode mode)
    {
        int dmg = Math.Max(1, originalDamage);

        switch (mode)
        {
            case DamageMode.Off:
                return dmg;
            case DamageMode.X2:
                return dmg * 2;
            case DamageMode.X3:
                return dmg * 3;
            case DamageMode.X4:
                return dmg * 4;
            case DamageMode.X5:
                return dmg * 5;
            case DamageMode.HitKill:
                return Math.Max(dmg, enemyHp);
            default:
                return dmg;
        }
    }

    internal static int GeoMultiplierToInt(GeoGainMode mode)
    {
        switch (mode)
        {
            case GeoGainMode.X2:
                return 2;
            case GeoGainMode.X3:
                return 3;
            case GeoGainMode.X4:
                return 4;
            case GeoGainMode.X5:
                return 5;
            default:
                return 1;
        }
    }

    private static void LogPatchError(string patchName, Exception ex)
    {
        Instance?.Logger.LogError($"{patchName}: {ex.GetType().Name} - {ex.Message}");
    }

    private void HandleFreeSoulUsage()
    {
        if (GameManager.instance == null || GameManager.instance.playerData == null)
            return;

        if (!ModEnabled.Value || !FreeSoulUsage.Value)
            return;

        var pd = GameManager.instance.playerData;

        if (pd.MPCharge < pd.maxMP)
        {
            pd.MPCharge = pd.maxMP;
        }
    }

    private void HandleKeepGeoOnDeath()
    {
        if (GameManager.instance == null || GameManager.instance.playerData == null)
            return;

        if (!ModEnabled.Value || !KeepGeoOnDeath.Value)
            return;

        var pd = GameManager.instance.playerData;

        if (pd.geoPool > 0)
        {
            pd.geo += pd.geoPool;
            pd.geoPool = 0;
        }
    }

    #endregion

    #region Patches - Charms

    [HarmonyPatch(typeof(PlayerData), "GetInt")]
    private static class PlayerData_GetInt_Patch
    {
        private static bool Prefix(string intName, ref int __result)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return true;

                if (!InfiniteCharmSlots.Value)
                    return true;

                if (intName == "charmSlots")
                {
                    __result = 999;
                    return false;
                }

                return true;
            }
            catch (Exception ex)
            {
                LogPatchError("InfiniteCharmSlots", ex);
                return true;
            }
        }
    }

    #endregion

    #region Patches - Damage

    [HarmonyPatch(typeof(HealthManager), "TakeDamage")]
    private static class HealthManager_TakeDamage_Patch
    {
        private static void Prefix(HealthManager __instance, ref HitInstance hitInstance)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return;

                if (__instance == null)
                    return;

                if (NailMode.Value == DamageMode.Off)
                    return;

                if (hitInstance.AttackType != AttackTypes.Nail)
                    return;

                if (hitInstance.DamageDealt <= 0)
                    return;

                hitInstance.DamageDealt = CalculateDamage(
                    hitInstance.DamageDealt,
                    __instance.hp,
                    NailMode.Value
                );
            }
            catch (Exception ex)
            {
                LogPatchError("NailDamage", ex);
            }
        }
    }

    #endregion

    #region Patches - Geo Multiplier

    [HarmonyPatch(typeof(HeroController), "AddGeo")]
    private static class HeroController_AddGeo_Patch
    {
        private static void Prefix(ref int __0)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return;

                int mult = GeoMultiplierToInt(GeoGainMultiplier.Value);
                if (mult <= 1)
                    return;

                if (__0 <= 0)
                    return;

                __0 *= mult;
            }
            catch (Exception ex)
            {
                LogPatchError("GeoMultiplier", ex);
            }
        }
    }

    #endregion

    #region Patches - Movement

    [HarmonyPatch(typeof(HeroController), "Update")]
    private static class HeroController_Update_Patch
    {
        private static void Postfix(HeroController __instance)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return;

                if (!InfiniteShadowDash.Value)
                    return;

                if (__instance == null)
                    return;

                ShadowDashTimerRef(__instance) = 0f;
            }
            catch (Exception ex)
            {
                LogPatchError("InfiniteShadowDash", ex);
            }
        }
    }

    #endregion

    #region Patches - Player

    [HarmonyPatch(typeof(PlayerData), "TakeHealth")]
    private static class PlayerData_TakeHealth_Patch
    {
        private static void Prefix(ref int __0)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return;

                if (!ImmortalPlayer.Value)
                    return;

                if (__0 > 0)
                {
                    __0 = 0;
                }
            }
            catch (Exception ex)
            {
                LogPatchError("ImmortalPlayer", ex);
            }
        }
    }

    #endregion

    #region Patches - Soul

    [HarmonyPatch(typeof(PlayerData), "TakeMP")]
    private static class PlayerData_TakeMP_Patch
    {
        private static void Prefix(ref int __0)
        {
            try
            {
                if (Instance == null || !ModEnabled.Value)
                    return;

                if (!FreeSoulUsage.Value)
                    return;

                if (__0 > 0)
                {
                    __0 = 0;
                }
            }
            catch (Exception ex)
            {
                LogPatchError("FreeSoulUsage", ex);
            }
        }
    }

    #endregion
}
