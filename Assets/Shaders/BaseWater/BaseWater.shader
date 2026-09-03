Shader "Custom/BaseWater"
{
    Properties
    {
        _WaterColor ("Deep Water Color", Color) = (0.02,0.20,0.38,1)
        _CrestColor ("Crest Water Color", Color) = (0.05,0.55,0.80,1)
        _CrestStrength ("Crest Color Strength", Range(0,2)) = 1

        _ColorTransitionStart ("Color Transition Start", Range(0,1)) = 0.15
        _ColorTransitionEnd ("Color Transition End", Range(0,1)) = 0.8  


        [Space(10)]
        _WaveHeight ("Wave Height", Range(0,10)) = 0.15
        _WaveAmplitude ("Wave Amplitude", Range(0,10)) = 0.15
        _WaveSpeed ("Wave Speed", Range(0,5)) = 1

        _AmbientStrength("Ambient Strength", Range(0,1)) = 0.35

        //foam
        // [Space(10)]
        // _FoamColor("Foam Color", Color) = (1,1,1,1)
        // _FoamThreshold("Foam Threshold", Range(0,1)) = 0.8
        // _FoamSharpness("Foam Sharpness", Range(1,20)) = 8

        // [Space(10)]
        // _FoamTex("Foam Noise", 2D) = "white" {}
        // _FoamScale("Foam Scale", Float) = 3
        // _FoamSpeed("Foam Speed", Range(0,5)) = 0.1

        [Space(10)]
        _SparkleColor ("Sparkle Color", Color) = (1,1,1,1)
        _SparkleTex ("Sparkle Noise", 2D) = "white" {}
        _SparkleScale ("Sparkle Scale", Float) = 8
        _SparkleSpeed ("Sparkle Speed", Range(0,5)) = 0.15
        _SparkleThreshold ("Sparkle Threshold", Range(0,1)) = 0.85
        _SparkleSharpness ("Sparkle Sharpness", Range(1,20)) = 8
        _SparkleStrength ("Sparkle Strength", Range(0,2)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        Cull Off
        ZWrite On

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);

            CBUFFER_START(UnityPerMaterial)

            float4 _WaterColor;
            float4 _CrestColor;
            float _CrestStrength;

            float _ColorTransitionStart;
            float _ColorTransitionEnd;

            float _WaveHeight;
            float _WaveAmplitude;
            float _WaveSpeed;

            float _AmbientStrength;

            //foam
            float4 _FoamColor;
            float _FoamThreshold;
            float _FoamSharpness;
            float _FoamScale;
            float _FoamSpeed;

            //Sparkle
            float4 _SparkleColor;
            TEXTURE2D(_SparkleTex);
            SAMPLER(sampler_SparkleTex);
            float _SparkleScale;
            float _SparkleSpeed;
            float _SparkleThreshold;
            float _SparkleSharpness;
            float _SparkleStrength;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                float wave : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            //----------------------------------------------------------
            // Directional Wave
            //----------------------------------------------------------

            float3 GerstnerWave(
                float2 position,
                float2 direction,
                float wavelength,
                float amplitude,
                float steepness,
                float speed)
            {
                direction = normalize(direction);

                float k = TWO_PI / wavelength;
                float c = sqrt(9.8 * k);

                float Q = steepness / (k * amplitude);

                float phase =
                    k * dot(direction, position)
                    - c * speed * _WaveSpeed * _Time.y;

                float s = sin(phase);
                float co = cos(phase);

                return float3(
                    direction.x * Q * amplitude * co,
                    amplitude * s,
                    direction.y * Q * amplitude * co
                );
            }

            //----------------------------------------------------------
            // HELPERS
            //----------------------------------------------------------

            float CalculateWaveHeight(float2 pos)
            {
                float height = 0;

                // Small waves
                height += GerstnerWave(
                    pos,
                    float2(1,0.3),
                    1.8,
                    _WaveAmplitude,
                    0.25,
                    1).y;

                height += GerstnerWave(
                    pos,
                    float2(-0.6,1),
                    3.7,
                    _WaveAmplitude,
                    0.15,
                    0.8).y;

                // Medium waves
                height += GerstnerWave(
                    pos,
                    float2(0.2,-1),
                    5.6,
                    _WaveAmplitude,
                    0.2,
                    1.3).y;

                // Large rolling wave
                height += GerstnerWave(
                    pos,
                    float2(0.8,0.6),
                    8.5,
                    _WaveAmplitude * 0.55,
                    0.15,
                    0.55).y;

                // Very broad wave
                height += GerstnerWave(
                    pos,
                    float2(-0.4,0.9),
                    13.0,
                    _WaveAmplitude * 0.35,
                    0.1,
                    0.35).y;

                return height;
            }

            float3 CalculateWaveDisplacement(float2 position)
            {
                float3 wave = float3(0,0,0);

                // Small waves
                wave += GerstnerWave(
                    position,
                    float2(1,0.3),
                    1.8,
                    _WaveAmplitude,
                    0.25,
                    1);

                wave += GerstnerWave(
                    position,
                    float2(-0.6,1),
                    3.7,
                    _WaveAmplitude,
                    0.15,
                    0.8);

                // Medium waves
                wave += GerstnerWave(
                    position,
                    float2(0.2,-1),
                    5.6,
                    _WaveAmplitude,
                    0.2,
                    1.3);

                // Large rolling wave
                wave += GerstnerWave(
                    position,
                    float2(0.8,0.6),
                    8.5,
                    _WaveAmplitude * 0.55,
                    0.15,
                    0.55);

                // Very broad wave
                wave += GerstnerWave(
                    position,
                    float2(-0.4,0.9),
                    13.0,
                    _WaveAmplitude * 0.35,
                    0.1,
                    0.35);

                return wave;
            }

            float3 CalculateNormal(float2 worldPos)
            {
                float epsilon = 0.05;
                
                float hL = CalculateWaveHeight(worldPos - float2(epsilon,0));
                float hR = CalculateWaveHeight(worldPos + float2(epsilon,0));

                float hD = CalculateWaveHeight(worldPos - float2(0,epsilon));
                float hU = CalculateWaveHeight(worldPos + float2(0,epsilon));

                float3 normal = 
                    normalize(float3(hL - hR,
                                     2.0 * epsilon,
                                     hD - hU));
                
                return normal;
            }

            float CalculateCrest(float waveHeight)
            {
                float crest = saturate(waveHeight / _WaveHeight);

                // Smooth transition into the crest
                crest = smoothstep(0.0, 1.0, crest);

                return crest;
            }

            float3 CalculateWaterColor(float crest)
            {
                float blend = smoothstep(_ColorTransitionStart, _ColorTransitionEnd, saturate(crest * _CrestStrength));

                return lerp(
                    _WaterColor.rgb,
                    _CrestColor.rgb,
                    blend
                );
            }            

            float CalculateDiffuseLighting(float3 normalWS, Light mainLight)
            {
                float NdotL = saturate(dot(normalWS, mainLight.direction));

                return NdotL;
            }

            //----------------------------------------------------------
            // FOAM
            //----------------------------------------------------------

            // float CalculateFoam(float crest, float3 normalWS, float2 uv)
            // {
            //     float slope = 1.0 - saturate(dot(normalWS, float3(0,1,0)));

            //     float2 foamUV =
            //         uv * _FoamScale +
            //         float2(_Time.y * _FoamSpeed, 0);

            //     float noise =
            //         SAMPLE_TEXTURE2D(
            //             _FoamTex,
            //             sampler_FoamTex,
            //             foamUV).r;

            //     float foam = crest * slope;

            //     foam = saturate((crest - 0.2) / 0.8);

            //     foam *= noise;

            //     foam = smoothstep(_FoamThreshold, 1, foam);

            //     foam = pow(foam, _FoamSharpness);

            //     return foam;
            // }

            //----------------------------------------------------------
            // SPARKLE
            //----------------------------------------------------------

            float CalculateSparkle(
                float3 normalWS,
                float2 uv,
                Light mainLight)
            {
                float lightFacing =
                    saturate(dot(normalWS, mainLight.direction));

                float2 sparkleUV =
                    uv * _SparkleScale +
                    float2(
                        _Time.y * _SparkleSpeed,
                        _Time.y * _SparkleSpeed * 0.35
                    );

                float noise =
                    SAMPLE_TEXTURE2D(
                        _SparkleTex,
                        sampler_SparkleTex,
                        sparkleUV
                    ).r;

                float sparkle =
                    lightFacing * noise;

                sparkle = smoothstep(
                    _SparkleThreshold,
                    1.0,
                    sparkle
                );

                return sparkle * _SparkleStrength;
            }

            //----------------------------------------------------------

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 position = IN.positionOS.xyz;

                float2 wavePos = position.xz;

                float3 displacement = CalculateWaveDisplacement(wavePos);
                
                position += displacement;

                VertexPositionInputs vertex =
                    GetVertexPositionInputs(position);

                OUT.positionCS = vertex.positionCS;
                OUT.normalWS = CalculateNormal(wavePos);
                OUT.wave = displacement.y;
                OUT.uv = IN.uv;

                return OUT;
            }

            //----------------------------------------------------------

            half4 frag(Varyings IN) : SV_Target
            {
                float crest = CalculateCrest(IN.wave);

                // float foam = CalculateFoam(
                //     crest,
                //     IN.normalWS,
                //     IN.uv
                // );

                float3 color = CalculateWaterColor(crest);

                Light mainLight = GetMainLight();

                float lighting =
                    CalculateDiffuseLighting(
                        IN.normalWS,
                        mainLight
                    );

                lighting = lerp(
                    _AmbientStrength,
                    1.0,
                    lighting
                );

                float sparkle = CalculateSparkle
                (
                    IN.normalWS,
                    IN.uv,
                    mainLight
                );

                color *= mainLight.color;
                color *= lighting;

                color = lerp(
                    color,
                    _FoamColor.rgb,
                    //foam
                    0.3
                );

                float3 sparkleLight = _SparkleColor.rgb * sparkle * _SparkleStrength;

                color += sparkleLight;

                return float4(color, 1);
            }

            ENDHLSL
        }
    }
}