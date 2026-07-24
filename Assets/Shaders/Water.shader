Shader "Custom/Water"
{
    Properties
    {
        _DeepColor("Deep Water Color", Color) = (0.15,0.45,0.75,1)
        _ShallowColor("Shallow Water Color", Color) = (0.15,0.45,0.75,1)

        _WaveHeight("Wave Height", Range(0,1)) = 0.15
        _WaveScale("Wave Scale", Range(0.1,10)) = 2
        _WaveSpeed("Wave Speed", Range(0,5)) = 1

        _CrestSharpness ("Crest Sharpness", Range(0.5, 10)) = 3

        //_BaseMap("Cloud Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _DeepColor;
            float4 _ShallowColor;

            float _WaveHeight;
            float _WaveScale;
            float _WaveSpeed;

            float _CrestSharpness;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float waveHeight : TEXCOORD2;
            };

            ///Helper
            float Wave(float2 pos)
            {
                float t = _Time.y;

                float wave1 =
                    sin(pos.x * _WaveScale + t * _WaveSpeed);

                float wave2 =
                    cos(pos.y * (_WaveScale * 1.6)
                    - t * (_WaveSpeed * 0.8));

                float wave3 =
                    sin((pos.x + pos.y) * (_WaveScale * 0.8)
                    + t * (_WaveSpeed * 1.3));

                float wave =
                    wave1 * 0.6 +
                    wave2 * 0.3 +
                    wave3 * 0.2;

                // Sharpen the peaks
                wave = sign(wave) * pow(abs(wave), 1.5);

                return wave * _WaveHeight;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 pos = IN.positionOS.xyz;

                float wave = Wave(pos.xz);

                pos.y += wave; //Shape

                VertexPositionInputs vertexInput =
                    GetVertexPositionInputs(pos);

                OUT.positionCS = vertexInput.positionCS;
                OUT.worldPos = vertexInput.positionWS;
                OUT.uv = IN.uv;
                OUT.waveHeight = wave;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;

                float crest = saturate(0.5 + IN.waveHeight / (_WaveHeight * 2));
                crest = pow(crest, _CrestSharpness);

                float3 color = lerp(_DeepColor.rgb, _ShallowColor.rgb, crest);

                return float4(color, 1.0);
            }

            ENDHLSL
        }
    }
}