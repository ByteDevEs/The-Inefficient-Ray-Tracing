using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public struct Sphere
{
    public Vector3 position;
    public float radius;
    public RayTracingMaterial material;
}