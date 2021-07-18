#ifndef COMMONINC_INCLUDED
#define COMMONINC_INCLUDED

// - We can perform shading computations correctly in the curved space
// - Or, we can compute shading in Euclidean geometry and transform only the geometry (benefits: we can reuse shading routines written for Euclidean geometry)
#define SHADE_IN_CURVED_SPACE

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
#ifdef SHADE_IN_CURVED_SPACE
	float4 N : NORMAL;
	float4 L : TEXCOORD1;
	float4 V : TEXCOORD2;
#else // euclidean space shading
	float3 N : NORMAL;
	float3 L : TEXCOORD1;
	float3 V : TEXCOORD2;
#endif
	float3 wPos : TEXCOORD3;
};

#endif // COMMONINC_INCLUDED