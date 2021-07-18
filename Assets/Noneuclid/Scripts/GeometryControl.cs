using UnityEngine;

[RequireComponent(typeof(Camera))]
public class GeometryControl : MonoBehaviour
{
    public enum Geometry { Euclidean = 0, Elliptic = 1, Hyperbolic = -1 };
    public Geometry geometry;
    [Range(0.001f, 1.0f)]
    public float globalScale = 0.1f;
    public Shader shader;

    float LorentzSign
    {
        get { return (int)geometry; }
    }

    Camera cam;

    void Start()
    {
        if (SystemInfo.graphicsDeviceType != UnityEngine.Rendering.GraphicsDeviceType.OpenGLCore)
        {
            Debug.LogError("Currently only OpenGL rendering API is supported");
        }

        if (shader == null)
        {
            shader = Shader.Find("NonEuclid/NonEuclideanGeometry");
        }
        if (shader == null)
        {
            enabled = false;
        }

        cam = GetComponent<Camera>();
        cam.SetReplacementShader(shader, "RenderType");
    }

    void OnEnable()
    {
        if (cam != null && shader != null)
        {
            cam.SetReplacementShader(shader, "RenderType");
        }
    }

    void OnPreCull()
    {
        if (globalScale != 1)
        {
            // disable frustum culling
            cam.cullingMatrix = Matrix4x4.Ortho(-99999, 99999, -99999, 99999, 0.001f, 99999) *
                                Matrix4x4.Translate(Vector3.forward * -99999 / 2f) *
                                cam.worldToCameraMatrix;
        }
        if (globalScale < 1)
        {
            cam.nearClipPlane = 0.01f;
        }
    }

    // Passing shader parameters in OnPreRender instead of Update makes sure that Shader.SetGlobal works with multiple cameras
    //void Update()
    void OnPreRender()
    {
        Shader.SetGlobalFloat("LorentzSign", LorentzSign);
        if (geometry == Geometry.Elliptic)
        {
            Shader.SetGlobalFloat("globalScale", globalScale);
        }
        else if (geometry == Geometry.Hyperbolic)
        {
            Shader.SetGlobalFloat("globalScale", globalScale);
        }
        else if (geometry == Geometry.Euclidean)
        {
            Shader.SetGlobalFloat("globalScale", 1.0f);
        }
    }

    void OnDisable()
    {
        if (cam != null)
        {
            cam.ResetReplacementShader();
            cam.ResetCullingMatrix();
        }
    }
}
