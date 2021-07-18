Shader "NonEuclid/NonEuclideanGeometry"
{
    Properties
    {
        LorentzSign("Curve", Float) = 0
        globalScale("globalScale", Float) = 0.001
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "" {}
        _EmissionColor("EmissionColor", Color) = (0,0,0,1)
		_EmissionMap("EmissionMap", 2D) = "" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.1
		_Metallic("Metallic", Range(0,1)) = 0.1
		_MetallicGlossMap("Metallic", 2D) = "" {}
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.0
    }

	SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }

			Cull Off

            CGPROGRAM

            #pragma vertex vertNonEuclid
            #pragma geometry geomNonEuclid // comment this to avoid rendering twice in elliptic geometry (similarly to spherical geometry)
            #pragma fragment frag

            #include "NonEuclid.cginc"
            #include "Shading.cginc"
           
            ENDCG
        }

        Pass
        {
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One

			Cull Off

            CGPROGRAM

            #pragma vertex vertNonEuclid
            #pragma geometry geomNonEuclid // comment this to avoid rendering twice in elliptic geometry (similarly to spherical geometry)
            #pragma fragment frag

            #include "NonEuclid.cginc"
            #include "Shading.cginc"
           
            ENDCG
        }
    }
}
