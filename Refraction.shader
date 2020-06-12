Shader "Unity Shaders Book/Chapter 10/Refraction"
{
	Properties
	{
		_Color ("Color Tint",Color) = (1,1,1,1)
		_RefractColor("Refraction Color",Color)=(1,1,1,1)
		_RefractAmount("Refraction Amount",Range(0,1))=1
		_Cubemap ("Refraction Cubemap",Cube) = "_Skybox"{}
		_RefractRatio ("Refraction Ratio",Range(0.1,1)) = 0.5 
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
			fixed3 _RefractColor;
			samplerCUBE _Cubemap;
			float4 _Cubemap_ST;
			fixed _RefractAmount;
			fixed _RefractRatio;

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
				float3 worldRefr : TEXCOORD3;
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefr = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);
				//_RefractRatio 是入射光线所在介质的折射率和折射光线的折射率之间的比值。
				//o.worldRefr 是计算的得到的折射方向，它的模则等于入射光线的模。没有归一化
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 refraction = texCUBE(_Cubemap,i.worldRefr).rgb * _RefractColor.rgb;
				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
				fixed3 diffuse = _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir));
				fixed3 color = ambient + lerp( diffuse , refraction, _RefractAmount )*atten;
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
}
