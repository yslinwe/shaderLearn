Shader "Unity Shaders Book/Chapter 11/ImageSequenceAnimation"
{
	Properties
	{
		_Color ("Color Tint", Color) = (1,1,1,1)
		_MainTex("Image Sequence", 2D ) = "white" {}
		_HorizontialAmount ("Horizontal Amount", Float) = 4
		_VerticalAmount ("Vertical Amount", Float) = 4
		_Speed("Speed", Range(1,100)) = 30
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			fixed4 _Color;
			float _Speed;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontialAmount;
			float _VerticalAmount;
			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 pos : SV_POSITION;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float time = floor(_Time.y *_Speed);
				float row = floor(time / _HorizontialAmount);
				float column = time - row * _VerticalAmount; 
				// half2 uv = i.uv + half2(column, -row);
				// uv.x /= _HorizontialAmount;
				// uv.y /= _VerticalAmount;
				half2 uv = float2(i.uv.x / _HorizontialAmount ,i.uv.y / _VerticalAmount);//每个子图像的纹理坐标
				uv.x += column / _HorizontialAmount; 
				//unity 纹理坐标竖直方向的顺序是从下到上逐渐增加和序列帧纹理中的顺序（播放顺序是从上到下）是相反的。
				uv.y -= row / _VerticalAmount;

				fixed4 c = tex2D(_MainTex, uv);
				c.rgb *= _Color.rgb;
				return c;
			}
			ENDCG
		}
	}
}
