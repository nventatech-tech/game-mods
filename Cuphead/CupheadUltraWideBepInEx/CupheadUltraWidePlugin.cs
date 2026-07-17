using System;
using System.Collections.Generic;
using System.Reflection;
using System.Reflection.Emit;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using UnityEngine;

namespace CupheadUltraWideBepInEx
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public sealed class CupheadUltraWidePlugin : BaseUnityPlugin
    {
        public const string PluginGuid = "opaaaaaaaaaaaa.cuphead.ultrawide";
        public const string PluginName = "Cuphead UltraWide BepInEx";
        public const string PluginVersion = "1.1.0";

        internal static ManualLogSource Log;

        private const bool UseCurrentMonitorAspect = true;
        private const bool ForceCamerasEveryFrame = true;
        private const bool ForceNoOverscan = true;

        private const float CustomAspect = 2.3888888f;
        private const float MaxAspect = 2.3888888f;
        private const float MinAspect = 1.7777778f;

        private Harmony harmony;

        private void Awake()
        {
            Log = Logger;

            harmony = new Harmony(PluginGuid);

            PatchTranspiler("AbstractCupheadCamera", "CalculateContainsBounds");
            PatchTranspiler("AbstractCupheadCamera", "get_Bounds");
            PatchTranspiler("AbstractCupheadCamera", "UpdateRect");
            PatchTranspiler("AbstractCupheadGameCamera", "get_Width");

            PatchTranspiler("BlurGamma", "OnRenderImage");
            PatchTranspiler("ChromaticAberration", "OnRenderImage");
            PatchTranspiler("ChromaticAberrationFilmGrain", "OnRenderImage");
            PatchTranspiler("UnityStandardAssets.ImageEffects.BlurOptimized", "OnRenderImage");

            PatchTranspiler("FlyingGenieLevelGenieTransform", "OnDamageTaken");
            PatchTranspiler("ControlMapperResizer", "Update");

            PatchPostfix("AbstractCupheadCamera", "UpdateRect");
            PatchPostfix("AbstractCupheadCamera", "LateUpdate");

            ForceOverscanZero();

            Log.LogInfo("Cuphead UltraWide carregado. Aspect efetivo: " + GetEffectiveAspect());
        }

        private void LateUpdate()
        {
            if (ForceNoOverscan)
                ForceOverscanZero();

            if (ForceCamerasEveryFrame)
                ForceAllUnityCameras();
        }

        private void OnDestroy()
        {
            if (!object.ReferenceEquals(harmony, null))
            {
                harmony.UnpatchSelf();
                harmony = null;
            }
        }

        private void PatchTranspiler(string typeName, string methodName)
        {
            try
            {
                Type type = FindTypeSafe(typeName);

                if (object.ReferenceEquals(type, null))
                {
                    Log.LogWarning("Tipo nao encontrado: " + typeName);
                    return;
                }

                MethodInfo target = FindMethodSafe(type, methodName);

                if (object.ReferenceEquals(target, null))
                {
                    Log.LogWarning("Metodo nao encontrado: " + typeName + "." + methodName);
                    return;
                }

                MethodInfo transpiler = typeof(CupheadUltraWidePlugin).GetMethod(
                    "ReplaceAspectConstants",
                    BindingFlags.Static | BindingFlags.NonPublic
                );

                if (object.ReferenceEquals(transpiler, null))
                    return;

                harmony.Patch(
                    target,
                    null,
                    null,
                    new HarmonyMethod(transpiler)
                );

                Log.LogInfo("Transpiler aplicado: " + typeName + "." + methodName);
            }
            catch (Exception ex)
            {
                Log.LogWarning("Falha no transpiler " + typeName + "." + methodName + ": " + ex.Message);
            }
        }

        private void PatchPostfix(string typeName, string methodName)
        {
            try
            {
                Type type = FindTypeSafe(typeName);

                if (object.ReferenceEquals(type, null))
                {
                    Log.LogWarning("Tipo nao encontrado: " + typeName);
                    return;
                }

                MethodInfo target = FindMethodSafe(type, methodName);

                if (object.ReferenceEquals(target, null))
                {
                    Log.LogWarning("Metodo nao encontrado: " + typeName + "." + methodName);
                    return;
                }

                MethodInfo postfix = typeof(CupheadUltraWidePlugin).GetMethod(
                    "ForceCupheadCameraPostfix",
                    BindingFlags.Static | BindingFlags.NonPublic
                );

                if (object.ReferenceEquals(postfix, null))
                    return;

                harmony.Patch(
                    target,
                    null,
                    new HarmonyMethod(postfix),
                    null
                );

                Log.LogInfo("Postfix aplicado: " + typeName + "." + methodName);
            }
            catch (Exception ex)
            {
                Log.LogWarning("Falha no postfix " + typeName + "." + methodName + ": " + ex.Message);
            }
        }

        private static void ForceCupheadCameraPostfix(object __instance)
        {
            try
            {
                if (object.ReferenceEquals(__instance, null))
                    return;

                Camera cam = GetCameraFromCupheadCamera(__instance);

                if (object.ReferenceEquals(cam, null))
                    return;

                ForceCamera(cam);
            }
            catch
            {
            }
        }

        private static Camera GetCameraFromCupheadCamera(object instance)
        {
            Type type = instance.GetType();

            while (!object.ReferenceEquals(type, null))
            {
                PropertyInfo prop = type.GetProperty(
                    "camera",
                    BindingFlags.Instance |
                    BindingFlags.Public |
                    BindingFlags.NonPublic
                );

                if (!object.ReferenceEquals(prop, null))
                {
                    object value = prop.GetValue(instance, null);
                    return value as Camera;
                }

                FieldInfo field = type.GetField(
                    "_camera",
                    BindingFlags.Instance |
                    BindingFlags.Public |
                    BindingFlags.NonPublic
                );

                if (!object.ReferenceEquals(field, null))
                {
                    object value = field.GetValue(instance);
                    return value as Camera;
                }

                type = type.BaseType;
            }

            return null;
        }

        private static void ForceAllUnityCameras()
        {
            Camera[] cameras = Camera.allCameras;

            for (int i = 0; i < cameras.Length; i++)
            {
                Camera cam = cameras[i];

                if (object.ReferenceEquals(cam, null))
                    continue;

                ForceCamera(cam);
            }
        }

        private static void ForceCamera(Camera cam)
        {
            float aspect = GetEffectiveAspect();

            cam.rect = new Rect(0f, 0f, 1f, 1f);
            cam.pixelRect = new Rect(0f, 0f, Screen.width, Screen.height);
            cam.aspect = aspect;
        }

        private static void ForceOverscanZero()
        {
            try
            {
                Type settingsType = FindTypeSafe("SettingsData");

                if (object.ReferenceEquals(settingsType, null))
                    return;

                PropertyInfo dataProp = settingsType.GetProperty(
                    "Data",
                    BindingFlags.Static |
                    BindingFlags.Public |
                    BindingFlags.NonPublic
                );

                if (object.ReferenceEquals(dataProp, null))
                    return;

                object data = dataProp.GetValue(null, null);

                if (object.ReferenceEquals(data, null))
                    return;

                FieldInfo overscanField = settingsType.GetField(
                    "overscan",
                    BindingFlags.Instance |
                    BindingFlags.Public |
                    BindingFlags.NonPublic
                );

                if (!object.ReferenceEquals(overscanField, null))
                    overscanField.SetValue(data, 0f);
            }
            catch
            {
            }
        }

        private static Type FindTypeSafe(string typeName)
        {
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();

            for (int i = 0; i < assemblies.Length; i++)
            {
                try
                {
                    Type type = assemblies[i].GetType(typeName, false);

                    if (!object.ReferenceEquals(type, null))
                        return type;
                }
                catch
                {
                }
            }

            return null;
        }

        private static MethodInfo FindMethodSafe(Type type, string methodName)
        {
            try
            {
                return type.GetMethod(
                    methodName,
                    BindingFlags.Instance |
                    BindingFlags.Static |
                    BindingFlags.Public |
                    BindingFlags.NonPublic |
                    BindingFlags.FlattenHierarchy
                );
            }
            catch
            {
                return null;
            }
        }

        public static float GetEffectiveAspect()
        {
            float aspect;

            if (UseCurrentMonitorAspect && Screen.height > 0)
                aspect = Screen.width / (float)Screen.height;
            else
                aspect = CustomAspect;

            if (aspect < MinAspect)
                aspect = MinAspect;

            if (MaxAspect > 0f && aspect > MaxAspect)
                aspect = MaxAspect;

            return aspect;
        }

        private static IEnumerable<CodeInstruction> ReplaceAspectConstants(IEnumerable<CodeInstruction> instructions)
        {
            List<CodeInstruction> output = new List<CodeInstruction>();

            MethodInfo getAspect = typeof(CupheadUltraWidePlugin).GetMethod(
                "GetEffectiveAspect",
                BindingFlags.Static | BindingFlags.Public
            );

            foreach (CodeInstruction code in instructions)
            {
                if (code.opcode == OpCodes.Ldc_R4 && code.operand is float)
                {
                    float value = (float)code.operand;

                    if (IsAspectConstant(value))
                    {
                        output.Add(new CodeInstruction(OpCodes.Call, getAspect));
                        continue;
                    }
                }

                output.Add(code);
            }

            return output;
        }

        private static bool IsAspectConstant(float value)
        {
            if (Math.Abs(value - 1.7777778f) < 0.05f)
                return true;

            if (Math.Abs(value - 1.778f) < 0.05f)
                return true;

            if (Math.Abs(value - 1.777f) < 0.05f)
                return true;

            if (Math.Abs(value - 2.3889999f) < 0.05f)
                return true;

            if (Math.Abs(value - 2.3888888f) < 0.05f)
                return true;

            if (Math.Abs(value - 2.3703704f) < 0.05f)
                return true;

            if (Math.Abs(value - 2.3909912f) < 0.05f)
                return true;

            return false;
        }
    }
}