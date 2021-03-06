﻿Shader "Unity Shaders Book/Chapter 8/AlphaBlendZwrite"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white" {}
		_AlphaScale("Alpha Scale",Range(0,1)) = 1
	}
	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent"  "IgnoreProjector" = "True"}
		Pass
		{
			ZWrite On
			ColorMask 0 //ColorMask RGB | A | 0 | 其他任何R、G、B、A的组合
			//ColorMask用于设置颜色通道的写掩码。 当ColorMask设置为0的时候，该pass不写入任何颜色通道
		}
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			//DstColor(new) = SrcAlpha*SrcColor//片元着色器颜色 + (1-SrcAlpha)*DstColor(old)//颜色缓冲区的颜色
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float4 texColor = tex2D(_MainTex,i.uv);
				// if((texColor.a - _Cutoff)<0.0)
				// 	discard;
				fixed3 abledo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abledo;
				fixed3 diffuse = _LightColor0.rgb * abledo * max(0,dot(worldNormal,worldLightDir));
				return fixed4(ambient + diffuse , texColor.a * _AlphaScale);
			}
			ENDCG
		}
	}
	Fallback "Transparent/Cutout/VertexLit"
}
