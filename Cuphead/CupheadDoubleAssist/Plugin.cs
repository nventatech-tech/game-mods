using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CupheadDoubleAssist
{
    [BepInPlugin("opaaaaaaaaaaaa.cuphead.doubleassist", "Cuphead Double Assist", "1.8.0")]
    public class Plugin : BaseUnityPlugin
    {
        internal static ManualLogSource Log;

        private Harmony harmony;

        private static bool modEnabledRuntime;

        private static bool controllerToggleModWasDown;
        private static bool controllerToggleInfiniteHealthWasDown;
        private static bool controllerToggleInfiniteDamageWasDown;

        private static int xinputBackend = 0;

        private static string toastText;
        private static float toastUntil;
        private static float nextConfigCheckTime;

        private const ushort XINPUT_GAMEPAD_A = 0x1000;
        private const ushort XINPUT_GAMEPAD_B = 0x2000;
        private const ushort XINPUT_GAMEPAD_X = 0x4000;

        private static readonly Dictionary<FieldInfo, object> originalDamageValues =
            new Dictionary<FieldInfo, object>();

        private static readonly Dictionary<object, int> originalHealthMaxValues =
            new Dictionary<object, int>(new ReferenceEqualityComparer());

        private static object lastPlayerStatsManager;

        private void Awake()
        {
            Log = Logger;

            ModConfig.Load();

            modEnabledRuntime = ModConfig.EnableMod;

            harmony = new Harmony("opaaaaaaaaaaaa.cuphead.doubleassist");
            harmony.PatchAll();

            ApplyDamageState();

            SceneManager.sceneLoaded += OnSceneLoaded;

            ModLog("Cuphead Double Assist carregado.");
        }

        private void Update()
        {
            if (Time.realtimeSinceStartup >= nextConfigCheckTime)
            {
                nextConfigCheckTime = Time.realtimeSinceStartup + 2f;

                if (ModConfig.FileChangedOnDisk())
                    ReloadConfig();
            }

            if (ModConfig.EnableHotkeys)
            {
                if (
                    IsKeyPressed(ModConfig.ToggleModKey, KeyCode.F1) ||
                    IsXInputComboPressed(XINPUT_GAMEPAD_X, ref controllerToggleModWasDown)
                )
                {
                    ToggleMod();
                }

                if (
                    IsKeyPressed(ModConfig.ToggleInfiniteHealthKey, KeyCode.F2) ||
                    IsXInputComboPressed(XINPUT_GAMEPAD_A, ref controllerToggleInfiniteHealthWasDown)
                )
                {
                    ToggleInfiniteHealth();
                }

                if (
                    IsKeyPressed(ModConfig.ToggleInfiniteDamageKey, KeyCode.F3) ||
                    IsXInputComboPressed(XINPUT_GAMEPAD_B, ref controllerToggleInfiniteDamageWasDown)
                )
                {
                    ToggleInfiniteDamage();
                }
            }

            if (modEnabledRuntime && ModConfig.InfiniteHealth && lastPlayerStatsManager != null)
            {
                ApplyHealthSettings(lastPlayerStatsManager, false);
            }
        }

        private void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;

            RestoreDamageValues();

            if (harmony != null)
                harmony.UnpatchSelf();
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            ApplyDamageState();

            if (lastPlayerStatsManager != null)
                ApplyHealthSettings(lastPlayerStatsManager, false);
        }

        private void OnGUI()
        {
            if (!ModConfig.EnableScreenMessages)
                return;

            if (string.IsNullOrEmpty(toastText) || Time.realtimeSinceStartup > toastUntil)
                return;

            GUIStyle style = new GUIStyle(GUI.skin.label);
            style.fontSize = Mathf.Max(18, Screen.height / 30);
            style.fontStyle = FontStyle.Bold;
            style.alignment = TextAnchor.UpperCenter;

            Rect rect = new Rect(0f, Screen.height * 0.08f, Screen.width, style.fontSize * 2f);

            style.normal.textColor = Color.black;
            GUI.Label(new Rect(rect.x + 2f, rect.y + 2f, rect.width, rect.height), toastText, style);

            style.normal.textColor = Color.white;
            GUI.Label(rect, toastText, style);
        }

        internal static void ShowToast(string message)
        {
            toastText = message;
            toastUntil = Time.realtimeSinceStartup + 2.5f;
        }

        private static void ReloadConfig()
        {
            ModConfig.Load();

            modEnabledRuntime = ModConfig.EnableMod;

            ApplyDamageState();

            if (lastPlayerStatsManager != null)
                ApplyHealthSettings(lastPlayerStatsManager, true);

            ShowToast("Config reloaded");
            ModLog("Configuracao recarregada do arquivo.");
        }

        private static void ModLog(string message)
        {
            if (ModConfig.EnableLogs)
                Log.LogInfo(message);
        }

        private static bool IsKeyPressed(string keyName, KeyCode fallback)
        {
            KeyCode key = ParseKeyCode(keyName, fallback);

            if (key == KeyCode.None)
                return false;

            return Input.GetKeyDown(key);
        }

        private static bool IsXInputComboPressed(ushort actionButton, ref bool wasDown)
        {
            if (!ModConfig.EnableControllerHotkeys)
                return false;

            bool comboDown = IsXInputComboHeld(actionButton);
            bool justPressed = comboDown && !wasDown;

            wasDown = comboDown;

            return justPressed;
        }

        private static bool IsXInputComboHeld(ushort actionButton)
        {
            for (int i = 0; i < 4; i++)
            {
                XINPUT_STATE state;

                if (!TryGetXInputState(i, out state))
                    continue;

                bool ltHeld = state.Gamepad.bLeftTrigger >= ModConfig.ControllerTriggerThreshold;
                bool rtHeld = state.Gamepad.bRightTrigger >= ModConfig.ControllerTriggerThreshold;
                bool actionHeld = (state.Gamepad.wButtons & actionButton) != 0;

                if (ltHeld && rtHeld && actionHeld)
                    return true;
            }

            return false;
        }

        private static bool TryGetXInputState(int playerIndex, out XINPUT_STATE state)
        {
            state = new XINPUT_STATE();

            if (xinputBackend == 1)
                return XInputGetState14(playerIndex, out state) == 0;

            if (xinputBackend == 2)
                return XInputGetState13(playerIndex, out state) == 0;

            if (xinputBackend == 3)
                return XInputGetState910(playerIndex, out state) == 0;

            if (xinputBackend == -1)
                return false;

            try
            {
                int result = XInputGetState14(playerIndex, out state);
                xinputBackend = 1;
                return result == 0;
            }
            catch
            {
            }

            try
            {
                int result = XInputGetState13(playerIndex, out state);
                xinputBackend = 2;
                return result == 0;
            }
            catch
            {
            }

            try
            {
                int result = XInputGetState910(playerIndex, out state);
                xinputBackend = 3;
                return result == 0;
            }
            catch
            {
            }

            xinputBackend = -1;
            return false;
        }

        [DllImport("xinput1_4.dll", EntryPoint = "XInputGetState")]
        private static extern int XInputGetState14(int dwUserIndex, out XINPUT_STATE pState);

        [DllImport("xinput1_3.dll", EntryPoint = "XInputGetState")]
        private static extern int XInputGetState13(int dwUserIndex, out XINPUT_STATE pState);

        [DllImport("xinput9_1_0.dll", EntryPoint = "XInputGetState")]
        private static extern int XInputGetState910(int dwUserIndex, out XINPUT_STATE pState);

        [StructLayout(LayoutKind.Sequential)]
        private struct XINPUT_STATE
        {
            public uint dwPacketNumber;
            public XINPUT_GAMEPAD Gamepad;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct XINPUT_GAMEPAD
        {
            public ushort wButtons;
            public byte bLeftTrigger;
            public byte bRightTrigger;
            public short sThumbLX;
            public short sThumbLY;
            public short sThumbRX;
            public short sThumbRY;
        }

        private static KeyCode ParseKeyCode(string keyName, KeyCode fallback)
        {
            try
            {
                return (KeyCode)Enum.Parse(typeof(KeyCode), keyName, true);
            }
            catch
            {
                return fallback;
            }
        }

        private static void ToggleMod()
        {
            modEnabledRuntime = !modEnabledRuntime;
            ModConfig.EnableMod = modEnabledRuntime;

            ApplyDamageState();

            if (lastPlayerStatsManager != null)
                ApplyHealthSettings(lastPlayerStatsManager, true);

            ModConfig.Save();

            ShowToast(modEnabledRuntime ? "Mod enabled" : "Mod disabled");
            ModLog("Mod: " + (modEnabledRuntime ? "LIGADO" : "DESLIGADO"));
        }

        private static void ToggleInfiniteHealth()
        {
            ModConfig.InfiniteHealth = !ModConfig.InfiniteHealth;

            if (lastPlayerStatsManager != null)
                ApplyHealthSettings(lastPlayerStatsManager, true);

            ModConfig.Save();

            ShowToast(
                (ModConfig.InfiniteHealth ? "Infinite health enabled" : "Infinite health disabled") +
                (modEnabledRuntime ? "" : " (mod is disabled)")
            );
            ModLog("Vida infinita: " + (ModConfig.InfiniteHealth ? "LIGADA" : "DESLIGADA"));
        }

        private static void ToggleInfiniteDamage()
        {
            ModConfig.InfiniteDamage = !ModConfig.InfiniteDamage;

            ApplyDamageState();

            ModConfig.Save();

            ShowToast(
                (ModConfig.InfiniteDamage ? "Infinite damage enabled" : "Infinite damage disabled") +
                (modEnabledRuntime ? "" : " (mod is disabled)")
            );
            ModLog("Dano infinito: " + (ModConfig.InfiniteDamage ? "LIGADO" : "DESLIGADO"));
        }

        private static float GetDamageMultiplier()
        {
            if (ModConfig.InfiniteDamage)
                return 9999f;

            float value = ModConfig.DamageMultiplier;

            if (value < 2f)
                value = 2f;

            if (value > 10f)
                value = 10f;

            return value;
        }

        private static int GetHealthMultiplier()
        {
            int value = ModConfig.HealthMultiplier;

            if (value < 2)
                value = 2;

            if (value > 10)
                value = 10;

            return value;
        }

        internal static void ApplyDamageState()
        {
            if (modEnabledRuntime && ModConfig.EnableDamage)
                ApplyDamageMultiplier();
            else
                RestoreDamageValues();
        }

        internal static void ApplyDamageMultiplier()
        {
            try
            {
                Type weaponProperties = AccessTools.TypeByName("WeaponProperties");

                if (weaponProperties == null)
                    return;

                float multiplier = GetDamageMultiplier();

                ApplyDamageFieldsRecursive(weaponProperties, multiplier);

                ApplySpecificStaticField(
                    "AbstractPlaneWeapon",
                    "shrunkDamageMultiplier",
                    multiplier
                );
            }
            catch (Exception ex)
            {
                Log.LogWarning("Erro ao aplicar dano: " + ex.Message);
            }
        }

        private static void RestoreDamageValues()
        {
            try
            {
                foreach (KeyValuePair<FieldInfo, object> entry in originalDamageValues)
                {
                    try
                    {
                        entry.Key.SetValue(null, entry.Value);
                    }
                    catch
                    {
                    }
                }
            }
            catch (Exception ex)
            {
                Log.LogWarning("Erro ao restaurar dano original: " + ex.Message);
            }
        }

        private static int ApplyDamageFieldsRecursive(Type type, float multiplier)
        {
            int changed = 0;

            FieldInfo[] fields = type.GetFields(
                BindingFlags.Public |
                BindingFlags.NonPublic |
                BindingFlags.Static
            );

            foreach (FieldInfo field in fields)
            {
                string name = field.Name.ToLowerInvariant();

                if (!name.Contains("damage"))
                    continue;

                if (!IsSupportedNumber(field.FieldType))
                    continue;

                if (ApplyNumericField(field, multiplier))
                    changed++;
            }

            Type[] nestedTypes = type.GetNestedTypes(
                BindingFlags.Public |
                BindingFlags.NonPublic
            );

            foreach (Type nested in nestedTypes)
            {
                changed += ApplyDamageFieldsRecursive(nested, multiplier);
            }

            return changed;
        }

        private static int ApplySpecificStaticField(string typeName, string fieldName, float multiplier)
        {
            Type type = AccessTools.TypeByName(typeName);

            if (type == null)
                return 0;

            FieldInfo field = AccessTools.Field(type, fieldName);

            if (field == null)
                return 0;

            if (!field.IsStatic)
                return 0;

            if (!IsSupportedNumber(field.FieldType))
                return 0;

            return ApplyNumericField(field, multiplier) ? 1 : 0;
        }

        private static bool ApplyNumericField(FieldInfo field, float multiplier)
        {
            try
            {
                object original;

                if (!originalDamageValues.TryGetValue(field, out original))
                {
                    original = field.GetValue(null);

                    if (original == null)
                        return false;

                    originalDamageValues[field] = original;
                }

                object newValue = MultiplyValue(original, field.FieldType, multiplier);

                if (newValue == null)
                    return false;

                field.SetValue(null, newValue);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool IsSupportedNumber(Type type)
        {
            return type == typeof(float) ||
                   type == typeof(double) ||
                   type == typeof(int);
        }

        private static object MultiplyValue(object value, Type type, float multiplier)
        {
            if (type == typeof(float))
                return ((float)value) * multiplier;

            if (type == typeof(double))
                return ((double)value) * multiplier;

            if (type == typeof(int))
                return (int)Math.Round(((int)value) * multiplier);

            return null;
        }

        internal static void ApplyHealthSettings(object playerStatsManager, bool refillIfIncreasing)
        {
            if (playerStatsManager == null)
                return;

            lastPlayerStatsManager = playerStatsManager;

            try
            {
                int currentMaxHealth = GetIntAny(
                    playerStatsManager,
                    new string[] { "HealthMax", "healthMax", "maxHealth", "_healthMax" },
                    -1
                );

                int currentHealth = GetIntAny(
                    playerStatsManager,
                    new string[] { "Health", "health", "_health" },
                    -1
                );

                if (currentMaxHealth <= 0)
                    return;

                int originalMaxHealth;

                if (!originalHealthMaxValues.TryGetValue(playerStatsManager, out originalMaxHealth))
                {
                    originalMaxHealth = currentMaxHealth;
                    originalHealthMaxValues[playerStatsManager] = originalMaxHealth;
                }

                int targetMaxHealth = originalMaxHealth;

                if (modEnabledRuntime && ModConfig.EnableHealth)
                    targetMaxHealth = originalMaxHealth * GetHealthMultiplier();

                bool wasFullHealth = currentHealth >= currentMaxHealth;

                SetIntAny(
                    playerStatsManager,
                    new string[] { "HealthMax", "healthMax", "maxHealth", "_healthMax" },
                    targetMaxHealth
                );

                if (modEnabledRuntime && ModConfig.InfiniteHealth)
                {
                    SetIntAny(
                        playerStatsManager,
                        new string[] { "Health", "health", "_health" },
                        targetMaxHealth
                    );
                }
                else if (refillIfIncreasing && wasFullHealth && targetMaxHealth > currentMaxHealth)
                {
                    SetIntAny(
                        playerStatsManager,
                        new string[] { "Health", "health", "_health" },
                        targetMaxHealth
                    );
                }
                else if (currentHealth > targetMaxHealth)
                {
                    SetIntAny(
                        playerStatsManager,
                        new string[] { "Health", "health", "_health" },
                        targetMaxHealth
                    );
                }
            }
            catch (Exception ex)
            {
                Log.LogWarning("Erro ao aplicar vida: " + ex.Message);
            }
        }

        private static int GetIntAny(object instance, string[] names, int fallback)
        {
            foreach (string name in names)
            {
                object value = GetMemberValue(instance, name);

                if (value == null)
                    continue;

                try
                {
                    return Convert.ToInt32(value);
                }
                catch
                {
                }
            }

            return fallback;
        }

        private static void SetIntAny(object instance, string[] names, int value)
        {
            foreach (string name in names)
            {
                if (SetMemberValue(instance, name, value))
                    return;
            }
        }

        private static object GetMemberValue(object instance, string name)
        {
            Type type = instance.GetType();

            PropertyInfo property = AccessTools.Property(type, name);

            if (property != null && property.CanRead)
                return property.GetValue(instance, null);

            FieldInfo field = AccessTools.Field(type, name);

            if (field != null)
                return field.GetValue(instance);

            return null;
        }

        private static bool SetMemberValue(object instance, string name, object value)
        {
            Type type = instance.GetType();

            PropertyInfo property = AccessTools.Property(type, name);

            if (property != null && property.CanWrite)
            {
                property.SetValue(instance, value, null);
                return true;
            }

            FieldInfo field = AccessTools.Field(type, name);

            if (field != null)
            {
                field.SetValue(instance, value);
                return true;
            }

            return false;
        }

        private sealed class ReferenceEqualityComparer : IEqualityComparer<object>
        {
            public new bool Equals(object x, object y)
            {
                return object.ReferenceEquals(x, y);
            }

            public int GetHashCode(object obj)
            {
                return RuntimeHelpers.GetHashCode(obj);
            }
        }

        private static class ModConfig
        {
            internal static float DamageMultiplier = 2f;
            internal static int HealthMultiplier = 2;

            internal static bool EnableMod = true;
            internal static bool EnableDamage = true;
            internal static bool EnableHealth = true;
            internal static bool InfiniteDamage = false;
            internal static bool InfiniteHealth = false;

            internal static bool EnableHotkeys = true;
            internal static bool EnableControllerHotkeys = true;
            internal static int ControllerTriggerThreshold = 100;

            internal static bool EnableLogs = false;
            internal static bool EnableScreenMessages = true;

            internal static string ToggleModKey = "F1";
            internal static string ToggleInfiniteHealthKey = "F2";
            internal static string ToggleInfiniteDamageKey = "F3";

            private static DateTime lastWriteTimeUtc;

            private static string ConfigPath
            {
                get
                {
                    return Path.Combine(Paths.ConfigPath, "opaaaaaaaaaaaa.cuphead.doubleassist.cfg");
                }
            }

            internal static bool FileChangedOnDisk()
            {
                try
                {
                    return File.GetLastWriteTimeUtc(ConfigPath) != lastWriteTimeUtc;
                }
                catch
                {
                    return false;
                }
            }

            internal static void Load()
            {
                try
                {
                    Dictionary<string, string> values = File.Exists(ConfigPath)
                        ? ReadConfigFile()
                        : new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                    DamageMultiplier = ClampFloat(ReadFloat(values, "01 - Modificacoes", "DamageMultiplier", 2f), 2f, 10f);
                    HealthMultiplier = ClampInt(ReadInt(values, "01 - Modificacoes", "HealthMultiplier", 2), 2, 10);

                    EnableMod = ReadBool(values, "02 - Ativar ou Desativar", "EnableMod", true);
                    EnableDamage = ReadBool(values, "02 - Ativar ou Desativar", "EnableDamage", true);
                    EnableHealth = ReadBool(values, "02 - Ativar ou Desativar", "EnableHealth", true);
                    InfiniteDamage = ReadBool(values, "02 - Ativar ou Desativar", "InfiniteDamage", false);
                    InfiniteHealth = ReadBool(values, "02 - Ativar ou Desativar", "InfiniteHealth", false);

                    EnableHotkeys = ReadBool(values, "03 - Atalhos Teclado", "EnableHotkeys", true);

                    ToggleModKey = ReadString(values, "03 - Atalhos Teclado", "ToggleModKey", "F1");
                    ToggleInfiniteHealthKey = ReadString(values, "03 - Atalhos Teclado", "ToggleInfiniteHealthKey", "F2");
                    ToggleInfiniteDamageKey = ReadString(values, "03 - Atalhos Teclado", "ToggleInfiniteDamageKey", "F3");

                    EnableControllerHotkeys = ReadBool(values, "04 - Atalhos Controle", "EnableControllerHotkeys", true);
                    ControllerTriggerThreshold = ClampInt(ReadInt(values, "04 - Atalhos Controle", "ControllerTriggerThreshold", 100), 1, 255);

                    EnableLogs = ReadBool(values, "05 - Logs", "EnableLogs", false);
                    EnableScreenMessages = ReadBool(values, "05 - Logs", "EnableScreenMessages", true);

                    Save();
                }
                catch (Exception ex)
                {
                    Log.LogWarning("Erro ao carregar configuracao. Usando valores padrao: " + ex.Message);
                }
            }

            internal static void Save()
            {
                try
                {
                    if (!Directory.Exists(Paths.ConfigPath))
                        Directory.CreateDirectory(Paths.ConfigPath);

                    string content = BuildConfigContent();

                    string existing = File.Exists(ConfigPath) ? File.ReadAllText(ConfigPath) : null;

                    if (existing != content)
                    {
                        // guarda o arquivo original antes da primeira reescrita (migração de formato antigo)
                        if (existing != null && !File.Exists(ConfigPath + ".backup"))
                        {
                            try
                            {
                                File.WriteAllText(ConfigPath + ".backup", existing);
                            }
                            catch
                            {
                            }
                        }

                        File.WriteAllText(ConfigPath, content);
                    }

                    lastWriteTimeUtc = File.GetLastWriteTimeUtc(ConfigPath);
                }
                catch (Exception ex)
                {
                    Log.LogWarning("Erro ao salvar configuracao: " + ex.Message);
                }
            }

            private static string BuildConfigContent()
            {
                return
"[01 - Modificacoes]\n" +
"DamageMultiplier = " + DamageMultiplier.ToString(CultureInfo.InvariantCulture) + "\n" +
"HealthMultiplier = " + HealthMultiplier + "\n" +
"\n" +
"[02 - Ativar ou Desativar]\n" +
"EnableMod = " + BoolText(EnableMod) + "\n" +
"EnableDamage = " + BoolText(EnableDamage) + "\n" +
"EnableHealth = " + BoolText(EnableHealth) + "\n" +
"InfiniteDamage = " + BoolText(InfiniteDamage) + "\n" +
"InfiniteHealth = " + BoolText(InfiniteHealth) + "\n" +
"\n" +
"[03 - Atalhos Teclado]\n" +
"EnableHotkeys = " + BoolText(EnableHotkeys) + "\n" +
"ToggleModKey = " + ToggleModKey + "\n" +
"ToggleInfiniteHealthKey = " + ToggleInfiniteHealthKey + "\n" +
"ToggleInfiniteDamageKey = " + ToggleInfiniteDamageKey + "\n" +
"\n" +
"[04 - Atalhos Controle]\n" +
"EnableControllerHotkeys = " + BoolText(EnableControllerHotkeys) + "\n" +
"ControllerTriggerThreshold = " + ControllerTriggerThreshold + "\n" +
"\n" +
"[05 - Logs]\n" +
"EnableLogs = " + BoolText(EnableLogs) + "\n" +
"EnableScreenMessages = " + BoolText(EnableScreenMessages) + "\n";
            }

            private static string BoolText(bool value)
            {
                return value ? "true" : "false";
            }

            private static Dictionary<string, string> ReadConfigFile()
            {
                Dictionary<string, string> values =
                    new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                string currentSection = "";

                string[] lines = File.ReadAllLines(ConfigPath);

                foreach (string rawLine in lines)
                {
                    string line = rawLine.Trim();

                    if (line.Length == 0)
                        continue;

                    if (line.StartsWith("#") || line.StartsWith(";"))
                        continue;

                    if (line.StartsWith("[") && line.EndsWith("]"))
                    {
                        currentSection = line.Substring(1, line.Length - 2).Trim();
                        continue;
                    }

                    int equalsIndex = line.IndexOf('=');

                    if (equalsIndex <= 0)
                        continue;

                    string key = line.Substring(0, equalsIndex).Trim();
                    string value = line.Substring(equalsIndex + 1).Trim();

                    values[currentSection + "." + key] = value;
                }

                return values;
            }

            private static string ReadString(Dictionary<string, string> values, string section, string key, string fallback)
            {
                string value;

                if (values.TryGetValue(section + "." + key, out value))
                    return value;

                // cfg de versão antiga pode ter outra seção; procura a chave em qualquer uma
                foreach (KeyValuePair<string, string> entry in values)
                {
                    if (entry.Key.EndsWith("." + key, StringComparison.OrdinalIgnoreCase))
                        return entry.Value;
                }

                return fallback;
            }

            private static bool ReadBool(Dictionary<string, string> values, string section, string key, bool fallback)
            {
                string value = ReadString(values, section, key, fallback ? "true" : "false").ToLowerInvariant();

                if (value == "true" || value == "1" || value == "yes" || value == "sim" || value == "on")
                    return true;

                if (value == "false" || value == "0" || value == "no" || value == "nao" || value == "não" || value == "off")
                    return false;

                return fallback;
            }

            private static int ReadInt(Dictionary<string, string> values, string section, string key, int fallback)
            {
                string value = ReadString(values, section, key, fallback.ToString());

                int parsed;

                if (int.TryParse(value, out parsed))
                    return parsed;

                return fallback;
            }

            private static float ReadFloat(Dictionary<string, string> values, string section, string key, float fallback)
            {
                string value = ReadString(values, section, key, fallback.ToString(CultureInfo.InvariantCulture));
                value = value.Replace(",", ".");

                float parsed;

                if (float.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
                    return parsed;

                return fallback;
            }

            private static int ClampInt(int value, int min, int max)
            {
                if (value < min)
                    return min;

                if (value > max)
                    return max;

                return value;
            }

            private static float ClampFloat(float value, float min, float max)
            {
                if (value < min)
                    return min;

                if (value > max)
                    return max;

                return value;
            }
        }
    }

    [HarmonyPatch]
    internal static class PlayerStatsManagerCalculateHealthMaxPatch
    {
        private static MethodBase TargetMethod()
        {
            return AccessTools.Method("PlayerStatsManager:CalculateHealthMax");
        }

        private static void Postfix(object __instance)
        {
            Plugin.ApplyHealthSettings(__instance, true);
        }
    }
}