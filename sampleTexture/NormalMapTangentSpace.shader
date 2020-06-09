Shader "Unity Shaders Book/Chapter 7/NormalMapTangentSpace"
{
	Properties
	{
		_Color("Color Tint",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white" {}
		_BumpMap("Normal Map",2D) = "bump" {}
		_BumpScale("Bump Scale",Float) = 1.0
		_Specular ("Specular",Color) = (1,1,1,1)
		_Gloss ("Gloss",Range(8.0,256)) = 20
	}
	SubShader
	{

		Pass
		{
			Tags {"LightingMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; //切线方向
				float4 texcoord : TEXCOORD0; 
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
	
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw; 
				TANGENT_SPACE_ROTATION;
// 				float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
// 　　			float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz; //切换到切线空间
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				fixed4 packedNormal = tex2D(_BumpMap , i.uv.zw);
				fixed3 tangentNormal;
				//packedNormal.xy *2 - 1 将像素的值映射会法线的值 像素范围[0,1] 法线范围[-1,1]
				//tangentNormal.xy = (packedNormal.xy *2 - 1) * _BumpScale; 
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangetNormal.xy)));
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				//让tangentNormal为单位向量 向量模为1
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));
				fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(tangentNormal,halfDir)),_Gloss);
				return fixed4(ambient + diffuse + specular,1.0); 
			}
			ENDCG
		}
	}
	Fallback "Specular"
}
