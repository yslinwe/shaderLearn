// Upgrade NOTE: replaced 'defined USING_DIRECTIONAL_LIGHT' with 'defined (USING_DIRECTIONAL_LIGHT)'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unity Shaders Book/Chapter 9/ForwardRendering"
{
	Properties
	{
		_Color("Color Tint",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss ("Gloss",Range(8.0,256)) = 20
	}
	SubShader
	{
		pass
		{
			Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed3 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			
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
				float3 worldPos :TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3) //  定义一个阴影纹理坐标变量 _ShadowCoord
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw; 
				TRANSFER_SHADOW(o); //计算_ShadowCoord 阴影纹理 需要使用o.pos 与 v.vertex 注意命名
				return o;
			} 

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 albedo = tex2D(_MainTex,i.uv).rgb *_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 halfLambert =dot(worldNormal, worldLightDir)*0.5+0.5;
				fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir =  normalize(viewDir + worldLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,viewDir)),_Gloss);
				fixed atten = 1.0;
				fixed shadow = SHADOW_ATTENUATION(i); //阴影纹理进行采样
				return fixed4(ambient + (diffuse + specular)*atten*shadow,1.0);
			}
			ENDCG
		}

		pass
		{
			Tags  {"LightMode" = "ForwardAdd"}
			Blend One One //叠加
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
		
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			fixed3 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;

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
				float3 worldPos :TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw; 
				return o;
			} 

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else 
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0; //衰减值
				#else
				    //unity_WorldToLight 世界空间到光源空间
					fixed3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos,1)).xyz; //光源位置
					//如果光源使用cookie 那么_LightTexture0 -> _LightTextureB0
					fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
					//float distance = length(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
					//atten = 1.0 / distance; // linear attenuation
				#endif

				fixed3 albedo = tex2D(_MainTex,i.uv).rgb *_Color.rgb;
				fixed3 halfLambert = dot(worldNormal, worldLightDir)*0.5+0.5;
				fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir =  normalize(viewDir + worldLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,viewDir)),_Gloss);
				return fixed4((diffuse + specular)*atten,1.0);
			}
			ENDCG
		}
		pass
		{
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
			};
			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	Fallback "Specular"
}
