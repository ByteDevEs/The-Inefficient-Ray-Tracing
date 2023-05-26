using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public struct RayTracingMaterial
{
    public Color color;
    public Color emissionColor;
    public float emissionStrength;
}