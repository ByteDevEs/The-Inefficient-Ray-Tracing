using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using static Unity.VisualScripting.Member;
using static UnityEngine.GraphicsBuffer;

[ExecuteAlways, ImageEffectAllowedInSceneView]
public class RayTracingManager : MonoBehaviour
{
    [Header("Ray Tracing Settings")]
    [SerializeField] bool useShaderInSceneView;
    [SerializeField] int MaxBounceCount;
    [SerializeField] int NumRaysPerPixel;

    [Header("Accumulation Settings")]
    [SerializeField] bool isProgressive;
    [SerializeField] int Frame;

    [Header("Sky Settings")]
    [SerializeField] Color SkyColorHorizon;
    [SerializeField] Color SkyColorZenith;
    [SerializeField] Transform sun;
    [SerializeField] float SunIntensity;
    [SerializeField] float SunFocus;
    [SerializeField] Color GroundColor;


    [SerializeField] Shader rayTracingShader;
    [SerializeField] Shader progressiveShader;
    Material rayTracingMaterial;
    Material progressiveMaterial;

    static List<Sphere> spheres = new List<Sphere>();


    private void OnEnable()
    {
        UpdateSphereBuffer();
        SphereList.instance.GetSpheres();
    }

    private void OnRenderImage(RenderTexture src, RenderTexture target)
    {
        if(Camera.current.name != "SceneCamera" || useShaderInSceneView)
        {
            ShaderHelper.InitMaterial(rayTracingShader, ref rayTracingMaterial);
            ShaderHelper.InitMaterial(progressiveShader, ref progressiveMaterial);
            UpdateCameraParams(Camera.current);
            if (isProgressive)
            {
                RenderTexture temp = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);

                // Render the current frame to temp using rayTracingMaterial
                Graphics.Blit(null, temp, rayTracingMaterial);

                // Update progressiveMaterial with the old frame
                progressiveMaterial.SetTexture("_MainTexOld", target);
                progressiveMaterial.SetTexture("_MainTex", temp);

                // Accumulate the results in a temporary RenderTexture
                RenderTexture accumTemp = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
                Graphics.Blit(null, accumTemp, progressiveMaterial);

                // Copy the accumulated results back to the target RenderTexture
                Graphics.Blit(accumTemp, target);

                // Clean up temporary RenderTextures
                RenderTexture.ReleaseTemporary(temp);
                RenderTexture.ReleaseTemporary(accumTemp);

                Frame++;
            }
            else
            {
                Graphics.Blit(src, target, rayTracingMaterial);
                Frame = 0;
            }
        }
        else
        {
            Graphics.Blit(src, target);
        }
    }

    static ComputeBuffer sphereBuffer;

    private void UpdateCameraParams(Camera cam)
    {
        float planeHeight = cam.nearClipPlane * Mathf.Tan(cam.fieldOfView * 0.5f * Mathf.Deg2Rad) * 2;
        float planeWidth = planeHeight * cam.aspect;
        rayTracingMaterial.SetVector("ViewParams", new Vector3(planeWidth, planeHeight, cam.nearClipPlane));
        rayTracingMaterial.SetMatrix("CamLocalToWorldMatrix", cam.transform.localToWorldMatrix);
        rayTracingMaterial.SetInt("MaxBounceCount", MaxBounceCount);
        rayTracingMaterial.SetInt("NumRaysPerPixel", NumRaysPerPixel);

        rayTracingMaterial.SetInt("Frame", Frame);
        progressiveMaterial.SetInt("Frame", Frame);

        rayTracingMaterial.SetBuffer("Spheres", sphereBuffer);
        rayTracingMaterial.SetInt("NumSpheres", spheres.Count);

        rayTracingMaterial.SetColor("SkyColorHorizon", SkyColorHorizon);
        rayTracingMaterial.SetColor("SkyColorZenith", SkyColorZenith);
        rayTracingMaterial.SetVector("SunLightDirection", sun.forward);
        rayTracingMaterial.SetFloat("SunIntensity", SunIntensity);
        rayTracingMaterial.SetFloat("SunFocus", SunFocus);
        rayTracingMaterial.SetColor("GroundColor", GroundColor);
        
    }

    public static void UpdateSphereBuffer()
    {
        // Liberar el buffer de computación
        if (sphereBuffer != null)
        {
            sphereBuffer.Release();
        };
        spheres = FindObjectsOfType<SphereObject>().Where(s => s.enabled = true).Select(s => s.GetSphere()).ToList();
        sphereBuffer = new ComputeBuffer(Mathf.Max(spheres.Count,1), sizeof(float) * 13); 
        sphereBuffer.SetData(spheres.ToArray());
        
    }
}
