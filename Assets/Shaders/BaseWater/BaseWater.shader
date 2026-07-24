Shader "Custom/BaseWater"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.18,0.45,0.75,0.75)

        _WaveHeight ("Wave Height", Range(0,10)) = 0.15
        _WaveAmount ("Wave Amount", Range(0.5,8)) = 2
        _WaveSpeed ("Wave Speed", Range(0,5)) = 1

        _TipTranperancy("Tip Tranperancy", Range(0, 1)) = 0.15
        _AmbientStrength("Ambient Strength", Range(0,1)) = 0.35
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _WaterColor;

            float _WaveHeight;
            float _WaveAmount;
            float _WaveSpeed;

            float _TipTranperancy;
            float _AmbientStrength;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                float wave : TEXCOORD0;
                float3 normalWS : TEXCOORD2;
            };

            //----------------------------------------------------------
            // Directional Wave
            //----------------------------------------------------------

            float CalculateWave(float2 pos)
            {
                float t = _Time.y * _WaveSpeed;

                float w = 0;

                w += sin(dot(pos, normalize(float2(1.0,0.3))) * _WaveAmount + t) * 0.55;

                w += sin(dot(pos, normalize(float2(-0.6,1.0))) * (_WaveAmount * 1.8) + t * 0.8) * 0.25;

                w += sin(dot(pos, normalize(float2(0.2,-1.0))) * (_WaveAmount * 0.6) + t * 1.3) * 0.2;

                w = sign(w) * pow(abs(w), 1.6);

                return w;
            }

            //----------------------------------------------------------
            // HELPERS
            //----------------------------------------------------------

            float3 CalculateNormal(float2 worldPos)
            {
                float epsilon = 0.05;
                
                float hL = CalculateWave(worldPos - float2(epsilon,0)) * _WaveHeight;
                float hR = CalculateWave(worldPos + float2(epsilon,0)) * _WaveHeight;

                float hD = CalculateWave(worldPos - float2(0,epsilon)) * _WaveHeight;
                float hU = CalculateWave(worldPos + float2(0,epsilon)) * _WaveHeight;

                float3 normal = 
                    normalize(float3(hL - hR,
                                     2.0 * epsilon,
                                     hD - hU));
                
                return normal;
            }

            float CalculateCrest(float waveHeight)
            {
                float crest = saturate((waveHeight + 1.0) * 0.5);
                return crest;
            }

            float3 CalculateWaterColor(float crest)
            {
                float3 color = _WaterColor.rgb;

                float3 crestTint = 
                    float3(
                            0.06,
                            0.1,
                            0.2
                        );
                
                color += crestTint * crest;
                return color;
            }            

            float CalculateDiffuseLighting(float3 normalWS, Light mainLight)
            {
                float NdotL = saturate(dot(normalWS, mainLight.direction));

                return NdotL;
            }

            //----------------------------------------------------------

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 position = IN.positionOS.xyz;

                float3 world = TransformObjectToWorld(position);

                float wave = CalculateWave(world.xz);

                position.y += wave * _WaveHeight;

                VertexPositionInputs vertex =
                    GetVertexPositionInputs(position);

                OUT.normalWS = CalculateNormal(vertex.positionWS.xz);
                OUT.positionCS = vertex.positionCS;
                OUT.wave = wave;

                return OUT;
            }

            //----------------------------------------------------------

            half4 frag(Varyings IN) : SV_Target
            {
                float crest = CalculateCrest(IN.wave);

                float alpha =
                    lerp(
                        _WaterColor.a,
                        _TipTranperancy,
                        crest
                    );

                float3 color = CalculateWaterColor(crest);

                Light mainLight = GetMainLight();

                float lighting = CalculateDiffuseLighting(IN.normalWS, mainLight);

                lighting = lerp(_AmbientStrength, 1.0, lighting);

                color *= mainLight.color;
                color *= lighting;

                return float4(color, alpha);
            }

            ENDHLSL
        }
    }
}