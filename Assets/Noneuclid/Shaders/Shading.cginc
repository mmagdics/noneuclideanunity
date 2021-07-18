#ifndef SHADING_INCLUDED
#define SHADING_INCLUDED

#include "UnityStandardCore.cginc"
#include "CommonIncludes.cginc"

fixed4 frag(v2f i) : SV_Target
{
#ifdef SHADE_IN_CURVED_SPACE
	float4 N = normalize(i.N);
	float4 L = normalize(i.L);
	float4 V = normalize(i.V);
#else
	float3 N = normalize(i.N);
	float3 L = normalize(i.L);
	float3 V = normalize(i.V);
#endif

	// Albedo, Emission, Alpha, etc are defined in UnityStandardInput.cginc

	float4 uv = float4(i.uv, 0, 0);
	fixed4 col;
	fixed3 emission = tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb;
	col.rgb = emission;
	float3 albedo = Albedo(uv);

	//float4 specGloss = SpecularGloss(i.uv);
	//half3 specColor = specGloss.rgb;
	//half smoothness = specGloss.a;
	//half oneMinusReflectivity;
	//albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	half2 metallicGloss = MetallicGloss(i.uv);
	half metallic = metallicGloss.x;
	half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.
	half oneMinusReflectivity;
	half3 specColor;
	half3 diffColor = DiffuseAndSpecularFromMetallic(albedo, metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	half outputAlpha;
	albedo = PreMultiplyAlpha(albedo, Alpha(uv), oneMinusReflectivity, /*out*/ outputAlpha);

#ifdef SHADE_IN_CURVED_SPACE // shading correctly in the curved geometry: use the redefined dot product
	// some very simple shading, diffuse + specular
	float4 H = normalize(L + V);
	float cost = max(dotProduct(N, L), 0);
	float cosd = max(dotProduct(N, H), 0);
	float3 mat = albedo * cost + specColor * pow(cosd, 128*smoothness);
	half4 c = half4(mat * _LightColor0, outputAlpha);
#else // euclidean geometry shading, we can use any shader code from e.g. the unity shader library
	UnityGI gi = (UnityGI)0; // TODO: figure out how to access this in the fragment shader
	UnityLight light = (UnityLight)0;
	light.dir = L;
	light.color = _LightColor0;

	half4 c = UNITY_BRDF_PBS(albedo, specColor, oneMinusReflectivity, smoothness, N, V, light, gi.indirect);
	c.a = outputAlpha;
#endif

	if (c.a < _Cutoff) discard;

	c.rgb += emission;
	//c.rgb += UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
	return c;
}

#endif // SHADING_INCLUDED