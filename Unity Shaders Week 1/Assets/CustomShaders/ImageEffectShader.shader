Shader "Hidden/ImageEffectShader"
{
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Tex2 ("Texture", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _Tex2;

            float hash21(float2 v){
                 return frac(23425.32 * sin(v.x*5542.02 + v.y * 456.834));
            }

            float noise21(float2 uv){
  
                 float2 scaleUV = floor(uv);
                 float2 unitUV = frac(uv);
  
                 float2 noiseUV = scaleUV;
  
                 float value1 = hash21(noiseUV);
                 float value2 = hash21(noiseUV + float2(1.,0.));
                 float value3 = hash21(noiseUV + float2(0.,1.));
                 float value4 = hash21(noiseUV + float2(1.,1.));
  
                 unitUV = smoothstep(float2(0., 0.),float2(1., 1.),unitUV);
  
                 float bresult = lerp(value1,value2,unitUV.x);
                 float tresult = lerp(value3,value4,unitUV.x);
  
                 return lerp(bresult,tresult,unitUV.y);
            }

            float4 frag(v2f_img i) : COLOR {
                float4 c = tex2D(_MainTex, i.uv);
                float4 tex = tex2D(_Tex2, i.uv);

                float scale = 10.;

                float2 scaledST = i.uv * scale;

                float lum = tex.r*.3 + tex.g*.59 + tex.b*.11;

                float4 bw = float4(lum, lum, lum, 1.);

                float4 texForBlack = 1. - bw;

                tex = lerp(tex, bw, 0.8);

                // normalize cuz I think I had wack math.
                c.rgb = float3(clamp(c.x, 0., 1.), clamp(c.y, 0., 1.), clamp(c.z, 0., 1.));
  
                

                float blackMask = step(0., 1. - c.r);

                texForBlack = texForBlack * blackMask * noise21(scaledST);

                float4 result = c * tex * 2.3 + texForBlack / 13.
                //* ((float4(1., 1., 1., 1.) - bw) * blackMask)
                ;

                //result = float4(noise21(scaledST),noise21(scaledST),noise21(scaledST),noise21(scaledST));

                return result;
            }
            ENDCG
        }
    }
}
