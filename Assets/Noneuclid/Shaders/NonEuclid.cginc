#ifndef NONEUCLID_INCLUDED
#define NONEUCLID_INCLUDED

#include "UnityStandardCore.cginc"
#include "CommonIncludes.cginc"

float LorentzSign;
float globalScale;

float dotProduct(float4 u, float4 v) {
	return u.x * v.x + u.y * v.y + u.z * v.z + LorentzSign * u.w * v.w;
	// or equivalently:
	//return dot(u,v) - ((LorentzSign < 0) ? 2 * u.w * v.w : 0);
}

float4 direction(float4 to, float4 from) {
	if (LorentzSign > 0) {
		float cosd = dotProduct(from, to);
		float sind = sqrt(1 - cosd * cosd);
		return (to - from * cosd) / sind;
	}
	if (LorentzSign < 0) {
		float coshd = -dotProduct(from, to);
		float sinhd = sqrt(coshd * coshd - 1);
		return (to - from * coshd) / sinhd;
	}
	return normalize(to - from);
}

float4 portEucToCurved(float4 eucPoint) {
	float3 P = eucPoint.xyz;
	float distance = length(P);
	if (distance < 0.0001f) return eucPoint;
	if (LorentzSign > 0) return float4(P / distance * sin(distance), cos(distance));
	if (LorentzSign < 0) return float4(P / distance * sinh(distance), cosh(distance));
	return eucPoint;
}

float4 portEucToCurved(float3 eucPoint) {
	return portEucToCurved(float4(eucPoint, 1));
}

float4x4 TranslateMatrix(float4 to) {
	if (LorentzSign != 0) {
		float denom = 1 + to.w;
		return transpose(float4x4(1 - LorentzSign * to.x * to.x / denom, -LorentzSign * to.x * to.y / denom, -LorentzSign * to.x * to.z / denom, -LorentzSign * to.x,
			-LorentzSign * to.y * to.x / denom, 1 - LorentzSign * to.y * to.y / denom, -LorentzSign * to.y * to.z / denom, -LorentzSign * to.y,
			-LorentzSign * to.z * to.x / denom, -LorentzSign * to.z * to.y / denom, 1 - LorentzSign * to.z * to.z / denom, -LorentzSign * to.z,
			to.x, to.y, to.z, to.w));
	}
	return transpose(float4x4(1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		to.x, to.y, to.z, 1));
}

float4x4 ViewMat()
{
	float4 ic = float4(UNITY_MATRIX_V[0].xyz, 0);
	float4 jc = float4(UNITY_MATRIX_V[1].xyz, 0);
	float4 kc = float4(UNITY_MATRIX_V[2].xyz, 0);
	
	float4 geomEye = portEucToCurved(_WorldSpaceCameraPos * globalScale);

	float4x4 eyeTranslate = TranslateMatrix(geomEye);
	float4 icp, jcp, kcp;
	icp = mul(eyeTranslate, ic);
	jcp = mul(eyeTranslate, jc);
	kcp = mul(eyeTranslate, kc);

	if (abs(LorentzSign) < 0.001)
	{
		return UNITY_MATRIX_V;

		// For Euclidean geometry this is equal to Unity's view matrix
		/*
		return transpose(float4x4(
			icp.x, jcp.x, kcp.x, 0,
			icp.y, jcp.y, kcp.y, 0,
			icp.z, jcp.z, kcp.z, 0,
			-dotProduct(icp, geomEye), -dotProduct(jcp, geomEye), -dotProduct(kcp, geomEye), 1
			));
		//*/
	}
	return transpose(float4x4(
		icp.x, jcp.x, kcp.x, LorentzSign * geomEye.x,
		icp.y, jcp.y, kcp.y, LorentzSign * geomEye.y,
		icp.z, jcp.z, kcp.z, LorentzSign * geomEye.z,
		LorentzSign * icp.w, LorentzSign * jcp.w, LorentzSign * kcp.w, geomEye.w
		));
}

float4x4 ProjMat()
{
	float sFovX = UNITY_MATRIX_P._m00;
	float sFovY = UNITY_MATRIX_P._m11;
	float fp = max(0.005, _ProjectionParams.y * globalScale); // scale front clipping plane according to the global scale factor of the scene

	if (LorentzSign <= 0.00001)
	{
		return UNITY_MATRIX_P;
	}
	return transpose(float4x4(
		sFovX, 0, 0, 0,
		0, sFovY, 0, 0,
		0, 0, 0, -1,
		0, 0, -fp, 0
		));
}

v2f vertNonEuclid(appdata v)
{
	v2f o;

	float4 eucVtxPos = v.vertex; // v.vertex : model space coordinates, euclidean geometry
	eucVtxPos = mul(unity_ObjectToWorld, eucVtxPos);
	float3 wPos = eucVtxPos.xyz; // world space, euclidean geometry
	eucVtxPos.xyz *= globalScale; // scale the whole scene uniformly
	float4 geomPoint = portEucToCurved(eucVtxPos);

	o.pos = mul(ViewMat(), geomPoint);
	o.pos = mul(ProjMat(), o.pos);
	o.wPos = wPos;

	float3 wNormal = mul(float4(v.normal, 0), unity_WorldToObject).xyz; // world space normal, euclidean geometry
#ifdef SHADE_IN_CURVED_SPACE
	o.N = mul(TranslateMatrix(eucVtxPos), wNormal);
	o.L = direction(portEucToCurved(_WorldSpaceLightPos0.xyz * globalScale), (_WorldSpaceLightPos0.w == 0) ? portEucToCurved(float3(0,0,0)) : geomPoint);
	o.V = direction(portEucToCurved(_WorldSpaceCameraPos.xyz * globalScale), geomPoint);
#else
	// in the fragment shader we can pretend if we were in Euclidean geometry, so we compute vectors accordingly
	o.N = normalize(wNormal);
	o.L = normalize(_WorldSpaceLightPos0.xyz - wPos * _WorldSpaceLightPos0.w);
	o.V = normalize(_WorldSpaceCameraPos.xyz - wPos);
#endif

	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

	return o;
}

[maxvertexcount(6)]
void geomNonEuclid(
	triangle v2f IN[3],
	inout TriangleStream<v2f> stream)
{
	stream.Append(IN[0]);
	stream.Append(IN[1]);
	stream.Append(IN[2]);

	stream.RestartStrip();

	// in elliptic geometry antipodal points are equivalent so we render each point twice
	if (LorentzSign > 0.001)
	{
		float4x4 VP = ProjMat() * ViewMat();

		for (int i = 0; i < 3; ++i)
		{
			float4 eucVtxPos = float4(IN[i].wPos, 1);
			eucVtxPos.xyz *= globalScale;
			float4 geomPoint = -portEucToCurved(eucVtxPos); // note the minus sign

			IN[i].pos = mul(VP, geomPoint);
			IN[i].N *= -1;

			stream.Append(IN[i]);
		}

		stream.RestartStrip();
	}
}

#endif // NONEUCLID_INCLUDED