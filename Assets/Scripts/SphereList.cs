using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class SphereList : MonoBehaviour
{
    public static SphereList instance;

    private void OnEnable()
    {
        if (instance == null)
        {
            instance = this;
        }
        else
        {
            Destroy(this);
        }
    }

    [SerializeField] public List<Sphere> spheres;

    public List<Sphere> GetSpheres()
    {
        spheres =  FindObjectsOfType<SphereObject>().Where(s => s.enabled = true).Select(s => s.GetSphere()).ToList(); ;
        return spheres;
    }
}
