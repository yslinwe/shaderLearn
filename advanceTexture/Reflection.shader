Shader "Unity Shaders Book/Chapter 10/Reflection"
{
	Properties
	{
		_Color ("Color Tint",Color) = (1,1,1,1)
		_ReflectColor("Reflection Color",Color)=(1,1,1,1)
		_ReflectAmount("Reflection Amount",Range(0,1))=1
		_Cubemap ("Reflection Cubemap",Cube) = "_Skybox"{}
	}
	SubShader
	{

		Pass
		{
		Tags {"LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			fixed3 _Color;
			fixed3 _ReflectColor;
			samplerCUBE _Cubemap;
			float4 _Cubemap_ST;
			fixed _ReflectAmount;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldViewDir : TEXCOORD2;
				float3 worldRefl : TEXCOORD3;
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 reflection = texCUBE(_Cubemap,i.worldRefl).rgb * _ReflectColor.rgb;
				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
				fixed3 diffuse = _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir));
				fixed3 color = ambient + lerp( diffuse , reflection, _ReflectAmount )*atten;
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
}