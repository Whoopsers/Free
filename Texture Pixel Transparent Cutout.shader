
// Special thanks to GMGregory from https://gamedev.stackexchange.com and gamedev.stackexchange itself for making this shader possible.
// WARNING: I havent checked if any content of this shader is copyrighted or patented, so use at your own risk!

// This shaders purpose is to use vertex colors as an input to determine transparency using the input texture's pixels.

Shader "Texture Pixel Transparent Cutout (Vertex colors)"
{
	Properties
	{
		_MainTex ("Main texture", 2D) = "white" {}
		_BlackValue ("Brightness when v = black", Range(0, 1)) = 0
		_AlphaThreshold ("Alpha threshold", Range(0, 1)) = 0
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjecter"="true"}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{				
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			float _AlphaThreshold, _BlackValue;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}
			
			float2x2 inverse(float2x2 mat) {
				float determinant = mat[0][0] * mat[1][1] - mat[0][1] * mat[1][0];
				float2x2 result = {mat[1][1], -mat[0][1], -mat[1][0], mat[0][0]};
				return result * 1.0f/determinant;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 tex = tex2D(_MainTex, i.uv);

				float2 gradient = float2(ddx(i.color.r), ddy(i.color.r));

				// Our current position in texel space (eg from 0,0 to 512, 512)
				float2 texelPos = i.uv * _MainTex_TexelSize.zw;

				// Rounded to the center of the texel
				float2 texelCenter = floor(texelPos) + 0.5f;

				// Compute the offset from there to here, and convert back to UV space.
				float2 delta = (texelCenter - texelPos) * _MainTex_TexelSize.xy;

				float2x2 uvToScreen;
				uvToScreen[0] = ddx(i.uv);
				uvToScreen[1] = ddy(i.uv);

				float2x2 screenToUV = inverse(uvToScreen);  

				gradient = mul(screenToUV, gradient);

				float snapped = 1 - (i.color.r + dot(gradient, delta));

				// discard fragments below the given threshold parameter.
				clip(snapped * tex.r - _AlphaThreshold);

				return fixed4(tex.rgb * clamp(i.color.r, _BlackValue, 1.0f), 1.0f);
			}
			ENDCG
		}
	}
}
