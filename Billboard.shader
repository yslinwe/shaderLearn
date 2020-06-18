Shader "Unity Shaders Book/Chapter 11/Billboard"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color",Color) = (1,1,1,1)
		_VerticalBillboarding ("Vertical Restraints",Range(0,1)) = 1 
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching"="True"}

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _VerticalBillboarding;
			fixed4 _Color;
			v2f vert (a2v v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				float3 center = float3(0,0,0);
				float3 viewer = mul(unity_ObjectToWorld,float4(_WorldSpaceCameraPos,1));
				float3 normalDir = viewer - center;
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);

				float3 upDir = abs(normalDir.y)>0.9?float3(0,0,1):float3(0,1,0); //保证法线与向上的方向不平行，保证叉积是正确的
				float3 rightDir = normalize(cross(normalDir,upDir));
				upDir = normalize(cross(normalDir,rightDir));
				float3 centerOffs = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
				o.pos = UnityObjectToClipPos(float4(localPos,1));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex,i.uv);
				c.rgb *= _Color.rgb;
				return c; 
			}
			ENDCG
		}
	}
	Fallback "Transparent/VertexLit"
}
