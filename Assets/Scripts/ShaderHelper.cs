using UnityEngine;

public static class ShaderHelper
{
    public static void InitMaterial(Shader shader, ref Material material)
    {
        if (material == null || material.shader != shader)
        {
            material = new Material(shader);
        }
    }
    public static void InitMaterial(Color color, ref Material material)
    {
        if (material == null || material.color != color)
        {
            material = new Material(Shader.Find("Standard"));
            material.color = color;
        }
    }
}
