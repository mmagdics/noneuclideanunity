using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[RequireComponent(typeof(GeometryControl))]
public class MultiView : MonoBehaviour
{
    public GeometryControl.Geometry leftCamGeometry = GeometryControl.Geometry.Euclidean;
    public GeometryControl.Geometry midCamGeometry = GeometryControl.Geometry.Elliptic;
    public GeometryControl.Geometry rightCamGeometry = GeometryControl.Geometry.Hyperbolic;
    public bool synchronizeScale = true;
    public float borderWidth = 0.005f;
    public Color borderColor = Color.black;
    public float hyperbolicScale = 3.0f; // usually it looks better if the scale is higher for hyperbolic than for elliptic

    Camera camLeft;
    Camera camMid;
    Camera camRight;
    Camera camBorder; // for rendering the border between camera views
    GeometryControl ctrlLeft;
    GeometryControl ctrlMid;
    GeometryControl ctrlRight;

    void Start()
    {
        camLeft = GetComponent<Camera>();
        ctrlLeft = GetComponent<GeometryControl>();
        Shader shader = ctrlLeft.shader;

        GameObject goMid = new GameObject("2nd camera for multiview");
        goMid.transform.parent = transform;
        camMid = goMid.AddComponent<Camera>();
        camMid.CopyFrom(camLeft);
        ctrlMid = goMid.AddComponent<GeometryControl>();
        ctrlMid.globalScale = ctrlLeft.globalScale;
        ctrlMid.shader = shader;
        camMid.SetReplacementShader(shader, "");

        GameObject goRight = new GameObject("3rd camera for multiview");
        goRight.transform.parent = transform;
        camRight = goRight.AddComponent<Camera>();
        camRight.CopyFrom(camLeft);
        ctrlRight = goRight.AddComponent<GeometryControl>();
        ctrlRight.globalScale = ctrlLeft.globalScale;
        ctrlRight.shader = shader;
        camRight.SetReplacementShader(shader, "");

        GameObject goBorder = new GameObject("Border camera for multiview");
        goBorder.transform.parent = transform;
        camBorder = goBorder.AddComponent<Camera>();
        camBorder.clearFlags = CameraClearFlags.Color;
        camBorder.backgroundColor = borderColor;
        camBorder.cullingMask = 0; // render nothing
        camBorder.depth = -100;
    }

    void Update()
    {
        float OneThird = 1.0f / 3.0f;

        Rect rectLeft = camLeft.rect;
        rectLeft.width = OneThird - borderWidth;
        camLeft.rect = rectLeft;

        Rect rectMid = camMid.rect;
        rectMid.width = OneThird - borderWidth;
        rectMid.x = OneThird;
        camMid.rect = rectMid;

        Rect rectRight = camRight.rect;
        rectRight.width = OneThird - borderWidth;
        rectRight.x = 2.0f * OneThird;
        camRight.rect = rectRight;

        ctrlLeft.geometry = leftCamGeometry;
        ctrlMid.geometry = midCamGeometry;
        ctrlRight.geometry = rightCamGeometry;

        if (synchronizeScale)
        {
            ctrlRight.globalScale = ctrlMid.globalScale = ctrlLeft.globalScale;
            if (ctrlRight.geometry == GeometryControl.Geometry.Hyperbolic) ctrlRight.globalScale *= hyperbolicScale;
            if (ctrlMid.geometry == GeometryControl.Geometry.Hyperbolic) ctrlMid.globalScale *= hyperbolicScale;
            if (ctrlLeft.geometry == GeometryControl.Geometry.Hyperbolic) ctrlLeft.globalScale *= hyperbolicScale;
        }

        camBorder.backgroundColor = borderColor;
    }

    void OnEnable()
    {
        if (camMid) camMid.enabled = true;
        if (camRight) camRight.enabled = true;
        if (camBorder) camBorder.enabled = true;
    }

    void OnDisable()
    {
        Rect fullRect = new Rect(0, 0, 1, 1);
        camLeft.rect = fullRect;

        camMid.enabled = false;
        camRight.enabled = false;
        camBorder.enabled = false;
    }
}
