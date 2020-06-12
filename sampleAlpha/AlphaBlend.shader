Shader "Unity Shaders Book/Chapter 8/AlphaBlend"
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
// 其中LightMode标签指定该pass的渲染路径，Queue指定渲染顺序，IgnoreProjector指定是否忽略Projector(投影)的影响，PreviewType一般用于UIshader，PreviewType=Plane的话在材质面板看到的就是一个平面而不是材质球。
// 但是很多人对RenderType的了解可能相比其他标签要稍微淡薄一些，只知道比如渲染不透明物体使用Opaque，渲染透明物体使用Transparent等，而官网上有提到RenderType会用于材质替代渲染（RenderWithShader   SetReplacementShader)，但究竟是如何去使用的，今天我总结下自己的理解。
// ————————————————
// 版权声明：本文为CSDN博主「MrASL」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
// 原文链接：https://blog.csdn.net/mobilebbki399/java/article/details/50512059
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha//DstColor(new) = SrcAlpha*SrcColor + (1-SrcAlpha)*DstColor(old)
			
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
