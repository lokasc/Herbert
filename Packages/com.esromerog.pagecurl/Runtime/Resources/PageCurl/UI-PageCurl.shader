// UI shader for the curling page. Based on Unity's UI/Default, so it keeps canvas tinting, RectMask2D soft
// clipping, stencil masks and alpha clip. Lighting is precomputed per vertex by PageCurlGraphic:
//   TEXCOORD0  front uv
//   TEXCOORD1  back uv (where the paper lands once turned)
//   TEXCOORD2  x: shade (or shadow opacity), y: highlight, z: 1 on the back face, w: 1 for shadow geometry
Shader "UI/Page Curl"
{
    Properties
    {
        [PerRendererData] _MainTex ("Front", 2D) = "white" {}
        [PerRendererData] _AlphaTex ("Back", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _PaperColor ("Paper Color", Color) = (1,1,1,1)
        _BackTint ("Back Tint", Color) = (1,1,1,1)
        _SeeThrough ("See Through", Range(0, 1)) = 0.2
        _UseBackTex ("Use Back Texture", Float) = 0
        _ShadowColor ("Shadow Color", Color) = (0,0,0,0.5)
        _HighlightColor ("Highlight Color", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex    : POSITION;
                float4 color     : COLOR;
                float2 texcoord  : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex        : SV_POSITION;
                fixed4 color         : COLOR;
                float4 uv            : TEXCOORD0;
                half4  data          : TEXCOORD1;
                float4 worldPosition : TEXCOORD2;
                float4 mask          : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;
            int _UIVertexColorAlwaysGammaSpace;

            half4 _PaperColor;
            half4 _BackTint;
            half _SeeThrough;
            half _UseBackTex;
            half4 _ShadowColor;
            half4 _HighlightColor;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                float4 vPosition = UnityObjectToClipPos(v.vertex);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                OUT.uv = float4(TRANSFORM_TEX(v.texcoord.xy, _MainTex), v.texcoord1.xy);
                OUT.data = v.texcoord2;

                if (_UIVertexColorAlwaysGammaSpace)
                {
                    if (!IsGammaSpace())
                    {
                        v.color.rgb = UIGammaToLinear(v.color.rgb);
                    }
                }

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                const half alphaPrecision = half(0xff);
                const half invAlphaPrecision = half(1.0/alphaPrecision);
                IN.color.a = round(IN.color.a * alphaPrecision)*invAlphaPrecision;

                half4 front = tex2D(_MainTex, IN.uv.xy) + _TextureSampleAdd;

                // Back face: either its own texture, or the front showing faintly through the paper, mirrored.
                half3 printed = lerp(_PaperColor.rgb, front.rgb, front.a);
                half4 seeThrough = half4(lerp(_PaperColor.rgb, printed, _SeeThrough), _PaperColor.a);
                half4 backTexture = tex2D(_AlphaTex, IN.uv.zw) + _TextureSampleAdd;
                half4 back = lerp(seeThrough, backTexture, _UseBackTex) * _BackTint;

                half4 page = lerp(front, back, IN.data.z) * IN.color;
                page.rgb = page.rgb * IN.data.x + _HighlightColor.rgb * (IN.data.y * page.a);

                half4 shadow = half4(_ShadowColor.rgb, _ShadowColor.a * IN.data.x * IN.color.a);
                half4 color = lerp(page, shadow, IN.data.w);

                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                color.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                color.rgb *= color.a;

                return color;
            }
        ENDCG
        }
    }
}
