Shader "Custom/CrystalShader"
{
    Properties
    {
        _MainColor("Tint Color", Color) = (0.5, 0.8, 1, 1)
        _CrystalTex("Crystal Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}

        _RefractionStrength("Refraction Strength", Range(0, 0.1)) = 0.03
        _Gloss("Gloss", Range(0, 1)) = 0.8
        _FresnelPower("Fresnel Power", Range(1, 8)) = 4.0

        _Emission("Emission", Float) = 1.5
        _Alpha("Alpha", Range(0,1)) = 0.7
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back

        Pass
        {
            Name "Crystal"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            float4 _MainColor;
            float _Gloss;
            float _Emission;
            float _Alpha;
            float _RefractionStrength;
            float _FresnelPower;

            TEXTURE2D(_CrystalTex);
            SAMPLER(sampler_CrystalTex);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 posWS = TransformObjectToWorld(IN.positionOS);
                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                OUT.positionCS = TransformWorldToHClip(posWS);
                OUT.normalWS = normalWS;

                float3 camPos = _WorldSpaceCameraPos;
                OUT.viewDirWS = normalize(camPos - posWS);

                OUT.uv = IN.uv;
                return OUT;
            }

            float4 Frag(Varyings IN) : SV_Target
            {
                
                float4 baseTex = SAMPLE_TEXTURE2D(_CrystalTex, sampler_CrystalTex, IN.uv);

                
                float3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                float3 normal = normalize(IN.normalWS + normalTex * 0.5);

              
                float fresnel = pow(1.0 - saturate(dot(IN.viewDirWS, normal)), _FresnelPower);

               
                float2 refractUV = IN.uv + normal.xy * _RefractionStrength;
                float4 refractedCol = SAMPLE_TEXTURE2D(_CrystalTex, sampler_CrystalTex, refractUV);

                
                float3 color = lerp(baseTex.rgb, refractedCol.rgb, 0.5);
                color *= _MainColor.rgb;

                
                color += fresnel * _Gloss;

                
                color += fresnel * _Emission;

                return float4(color, _Alpha + fresnel * 0.2);
            }

            ENDHLSL
        }
    }
}
