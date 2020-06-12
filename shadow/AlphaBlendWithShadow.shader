Shader "Unity Shaders Book/Chapter 9/AlphaBlendWithShadow"
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
			Tags {"LightMode" = "ForwardBase"}
			Cull Front //剔除正面
			ZWrite Off //关闭深度写入
			Blend SrcAlpha OneMinusSrcAlpha//DstColor(new) = SrcAlpha*SrcColor + (1-SrcAlpha)*DstColor(old)
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

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
				SHADOW_COORDS(3)
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				TRANSFER_SHADOW(o)
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
				UNITY_LIGHT_ATTENUATION(atten , i , i.worldPos)
				return fixed4(ambient + diffuse *atten, texColor.a * _AlphaScale);
			}
			ENDCG
		}
		Pass
		{
			//Tags {"LightMode" = "ForwardBase"}
			Cull Back // 剔除背面
			ZWrite Off //关闭深度写入
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
	//没有内置shader中不会产生透明混合的阴影
	//Fallback "Transparent/Cutout/VertexLit" 
	//可以通过不透明物体使用的shader（VertexLit、diffuse） unity可以在他的FallBack上找到一个阴影投射的Pass，
	//然后通过Mesh Renderer组件上的Cast Shadows 和 Receive shadows 选项来控制是否需要向其他物体投射或接受阴影。
	//但得到的阴影不正确 其他物体投射的阴影不会穿透
	Fallback "VertexLit" 
}


