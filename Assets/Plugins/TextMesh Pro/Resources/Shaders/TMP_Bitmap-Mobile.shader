// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Copyright (C) 2014 - 2016 Stephan Schaem - All Rights Reserved
// This code can only be used under the standard Unity Asset Store End User License Agreement
// A Copy of the EULA APPENDIX 1 is available at http://unity3d.com/company/legal/as_terms

Shader "TextMeshPro/Mobile/Bitmap" {

Properties {
	_MainTex		("Font Atlas", 2D) = "white" {}
	_Color			("Text Color", Color) = (1,1,1,1)
	_DiffusePower	("Diffuse Power", Range(1.0,4.0)) = 1.0

	_VertexOffsetX("Vertex OffsetX", float) = 0
	_VertexOffsetY("Vertex OffsetY", float) = 0
	_MaskSoftnessX("Mask SoftnessX", float) = 0
	_MaskSoftnessY("Mask SoftnessY", float) = 0

	_ClipRect("Clip Rect", vector) = (-10000, -10000, 10000, 10000)

	_StencilComp("Stencil Comparison", Float) = 8
	_Stencil("Stencil ID", Float) = 0
	_StencilOp("Stencil Operation", Float) = 0
	_StencilWriteMask("Stencil Write Mask", Float) = 255
	_StencilReadMask("Stencil Read Mask", Float) = 255

	_ColorMask("Color Mask", Float) = 15
}

SubShader {

	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

	Stencil
	{
		Ref[_Stencil]
		Comp[_StencilComp]
		Pass[_StencilOp]
		ReadMask[_StencilReadMask]
		WriteMask[_StencilWriteMask]
	}


	Lighting Off
	Cull Off
	ZTest [unity_GUIZTestMode]
	ZWrite Off
	Fog { Mode Off }
	Blend SrcAlpha OneMinusSrcAlpha
	ColorMask[_ColorMask]

	Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest

		#include "UnityCG.cginc"

		struct appdata_t {
			float4 vertex : POSITION;
			fixed4 color : COLOR;
			float2 texcoord0 : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
		};

		struct v2f {
			float4 vertex		: POSITION;
			fixed4 color		: COLOR;
			float2 texcoord0	: TEXCOORD0;
			float4 mask			: TEXCOORD2;
		};

		sampler2D 	_MainTex;
		fixed4		_Color;
		float		_DiffusePower;

		uniform float		_VertexOffsetX;
		uniform float		_VertexOffsetY;
		uniform float4		_ClipRect;
		uniform float		_MaskSoftnessX;
		uniform float		_MaskSoftnessY;

		#if UNITY_VERSION < 530
			bool _UseClipRect;
		#endif

		v2f vert (appdata_t v)
		{
			v2f o;
			float4 vert = v.vertex;
			vert.x += _VertexOffsetX;
			vert.y += _VertexOffsetY;

			o.vertex = UnityPixelSnap(UnityObjectToClipPos(vert));
			o.color = v.color;
			o.color *= _Color;
			o.color.rgb *= _DiffusePower;
			o.texcoord0 = v.texcoord0;

			float2 pixelSize = o.vertex.w;
			//pixelSize /= abs(float2(_ScreenParams.x * UNITY_MATRIX_P[0][0], _ScreenParams.y * UNITY_MATRIX_P[1][1]));

			// Clamp _ClipRect to 16bit.
			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
			o.mask = float4(vert.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy));

			return o;
		}

		fixed4 frag (v2f i) : COLOR
		{
			fixed4 c = fixed4(i.color.rgb, i.color.a * tex2D(_MainTex, i.texcoord0).a);

			#if UNITY_VERSION < 530
				if (_UseClipRect)
				{
					// Alternative implementation to UnityGet2DClipping with support for softness.
					half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(i.mask.xy)) * i.mask.zw);
					c *= m.x * m.y;
				}
			#else
				// Alternative implementation to UnityGet2DClipping with support for softness.
				half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(i.mask.xy)) * i.mask.zw);
				c *= m.x * m.y;
			#endif

			return c;
		}
		ENDCG
	}
}

SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Lighting Off Cull Off ZTest Always ZWrite Off Fog { Mode Off }
	Blend SrcAlpha OneMinusSrcAlpha
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord0
	}
	Pass {
		SetTexture [_MainTex] {
			constantColor [_Color] combine constant * primary, constant * texture
		}
	}
}

CustomEditor "TMPro.EditorUtilities.TMP_BitmapShaderGUI"
}
