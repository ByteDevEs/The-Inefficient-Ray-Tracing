using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteAlways, ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class SphereObject : MonoBehaviour
{

    [SerializeField] RayTracingMaterial m_Material;


    Material sphereMaterial;
    Sphere sphere = new Sphere();

    private void OnEnable()
    {
        Sphere();
    }

    private void OnDisable()
    {

    }

    //On any value changed
    private void OnValidate()
    {
        Sphere();
    }

    private void Start()
    {
        Sphere();
    }

    private void Update()
    {
        if (transform.hasChanged)
        {
            Sphere();
            transform.hasChanged = false;
        }
    }


    public void Sphere()
    {
        Sphere newSphere = new Sphere();
        newSphere.position = transform.position;
        newSphere.radius = transform.localScale.x / 2;
        newSphere.material = m_Material;
        if (!sphere.Equals(newSphere))
        {
            ShaderHelper.InitMaterial(m_Material.color, ref sphereMaterial);
            GetComponent<MeshRenderer>().material = sphereMaterial;
            sphere = newSphere;
        }
        RayTracingManager.UpdateSphereBuffer();
    }

    public Sphere GetSphere()
    {
        return sphere;
    }
}
