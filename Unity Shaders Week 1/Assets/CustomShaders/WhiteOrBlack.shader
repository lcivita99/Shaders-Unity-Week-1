// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/WhiteOrBlack"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Tex2 ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Threshold ("Threshold", Range(0,1)) = 0.8
        _WithLines("With Lines", Range(0,1)) = 0
        _LineSize ("Line Size", float) = 10
        _ScreenTex ("Screen Texture", 2D) = "white" { }
    }
    SubShader
    {
        Pass {}
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Ramp

        sampler2D _Ramp;
        float _Threshold;
        float _LineSize;
        float _WithLines;
        sampler2D _Tex2;
        float4 _Tex2_ST;
        sampler2D _ScreenTex;

        half4 LightingRamp (SurfaceOutput s, half3 lightDir, half atten) {
            half NdotL = dot (s.Normal, lightDir);
            half diff = NdotL * 0.5 + 0.5;
            half3 ramp = tex2D (_Ramp, float2(diff, 0.)).rgb;
            half4 c;

            // !!!!!! BELOW IS WHAT I CHANGED (got this lighting model online)



            c.rgb =
                lerp(s.Albedo,
                    float3(1., 1., 1.) * 100.,
                    step(0.84, diff) * step(0.1, _WithLines))

                * _LightColor0.rgb 
                * ramp
                * atten
                * step(_Threshold, diff);
                c.a = s.Alpha;
            return c;
        }

        struct Input {
            float2 uv_MainTex;
            float4 screenPos;
        };
    
        sampler2D _MainTex;
    
        void surf (Input IN, inout SurfaceOutput o) {
            float2 textureCoordinate = IN.screenPos.xy / IN.screenPos.w;
            float aspect = _ScreenParams.x / _ScreenParams.y;
            textureCoordinate.x = textureCoordinate.x * aspect;
            textureCoordinate = TRANSFORM_TEX(textureCoordinate, _Tex2);

            fixed4 tex = tex2D (_Tex2, textureCoordinate * _LineSize);
            float texMask = step(1.0 * _WithLines, tex.x);

            float2 screenUV = IN.uv_MainTex.xy / _ScreenParams.xy;
            fixed4 screenColor = tex2D(_ScreenTex, screenUV);

            tex.rgb = lerp(tex.rgb, screenColor.rgb, screenColor.a);

            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = float3(1., 1., 1.) * 100. * texMask;
            //o.Albedo = tex.rgb * 100.;
            //o.Albedo = tex.rgb * 1. /* texMask*/;

        }
        ENDCG

        // Outline attempt
        Pass
        {
            Name "Outline"
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
 
                struct v2f {
                    float4 pos: POSITION;
                    float4 screenPos: TEXCOORD0;
                };
 
                v2f vert (appdata_full v)
                {
                    v2f o;
                    v.vertex.xyz += v.normal / 35.;
                    o.pos = UnityObjectToClipPos(v.vertex);   
                    o.screenPos = ComputeScreenPos(o.pos);
                    return o;
                }
 
                float4 frag( v2f i ) : COLOR
                {

                    return float4(1., 0., 0., 1.0);
                }
            ENDCG          
        }
    }
    FallBack "Diffuse"
}
