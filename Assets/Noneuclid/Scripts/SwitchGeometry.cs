using UnityEngine;

public class SwitchGeometry : MonoBehaviour
{
    GeometryControl geomControl;

    void Start()
    {
        if (geomControl == null)
        {
            geomControl = FindObjectOfType<GeometryControl>();
        }
        if (geomControl == null)
        {
            enabled = false;
        }
    }

    void Update()
    {
        if (Input.GetKey(KeyCode.Alpha1))
        {
            geomControl.geometry = GeometryControl.Geometry.Euclidean;
        }
        if (Input.GetKey(KeyCode.Alpha2))
        {
            geomControl.geometry = GeometryControl.Geometry.Elliptic;
        }

        if (Input.GetKey(KeyCode.Alpha3))
        {
            geomControl.geometry = GeometryControl.Geometry.Hyperbolic;
        }

        if (Input.GetKey(KeyCode.PageUp))
        {
            geomControl.globalScale *= 1.03f;
        }
        if (Input.GetKey(KeyCode.PageDown))
        {
            geomControl.globalScale /= 1.03f;
        }
    }
}
