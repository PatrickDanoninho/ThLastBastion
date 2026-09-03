Shader "Custom/Gerstner"
{
    Properties
    {
         _WaterColor ("Water Color", Color) = (0.02, 0.25, 0.45, 1)

        [Space(10)]
        [Header(Cel Shading)]
        _WaterShadowColor ("Shadow Color", Color) = (0.01, 0.08, 0.15, 1)
        _WaterMidColor ("Mid Color", Color) = (0.02, 0.25, 0.45, 1)
        _WaterLightColor ("Light Color", Color) = (0.15, 0.55, 0.75, 1)

        _ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.35
        _ShadowSoftness ("Shadow Softness", Range(0,0.2)) = 0.02

        _LightThreshold ("Light Threshold", Range(0,1)) = 0.70
        _LightSoftness ("Light Softness", Range(0,0.2)) = 0.02

        [Space(10)]
        _AmbientStrength ("Ambient Strength", Range(0,1)) = 0.35

        [Space(10)]
        _WaveHeight ("Wave Height", Range(0,10)) = 0.15

        [Space(15)]
        _Wave1Direction ("Direction", Vector) = (1, 0.3, 0, 0)
        _Wave1Wavelength ("Wavelength", Float) = 5.6
        _Wave1Amplitude ("Amplitude", Float) = 0.18
        _Wave1Steepness ("Steepness", Range(0,1)) = 0.25
        _Wave1Speed ("Speed", Float) = 0.7

        [Space(10)]
        _Wave2Direction ("Direction", Vector) = (-0.6, 1, 0, 0)
        _Wave2Wavelength ("Wavelength", Float) = 3.7
        _Wave2Amplitude ("Amplitude", Float) = 0.12
        _Wave2Steepness ("Steepness", Range(0,1)) = 0.2
        _Wave2Speed ("Speed", Float) = 0.9

        [Space(10)]
        _Wave3Direction ("Direction", Vector) = (0.2, -1, 0, 0)
        _Wave3Wavelength ("Wavelength", Float) = 1.8
        _Wave3Amplitude ("Amplitude", Float) = 0.07
        _Wave3Steepness ("Steepness", Range(0,1)) = 0.15
        _Wave3Speed ("Speed", Float) = 1.2

        [Space(10)]
        _Wave4Direction ("Direction", Vector) = (-1, -0.2, 0, 0)
        _Wave4Wavelength ("Wavelength", Float) = 0.9
        _Wave4Amplitude ("Amplitude", Float) = 0.025
        _Wave4Steepness ("Steepness", Range(0,1)) = 0.1
        _Wave4Speed ("Speed", Float) = 1.5

        [Space(10)]
        [Header(Normal)]
        _NormalEpsilon ("Normal Epsilon", Range(0.001,0.2)) = 0.05
            
        [Space(15)]
        _DetailNormal ("Detail Normal", 2D) = "bump" {}
        _DetailScale ("Detail Scale", Float) = 4
        _DetailSpeed ("Detail Speed", Float) = 0.05
        _DetailStrength ("Detail Strength", Range(0,2)) = 0.5
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

            CBUFFER_START(UnityPerMaterial)

            float4 _WaterColor;
            float _AmbientStrength;
            float _WaveHeight;
            // Fresnel fields removed

            float4 _Wave1Direction;
            float _Wave1Wavelength;
            float _Wave1Amplitude;
            float _Wave1Steepness;
            float _Wave1Speed;

            float4 _Wave2Direction;
            float _Wave2Wavelength;
            float _Wave2Amplitude;
            float _Wave2Steepness;
            float _Wave2Speed;

            float4 _Wave3Direction;
            float _Wave3Wavelength;
            float _Wave3Amplitude;
            float _Wave3Steepness;
            float _Wave3Speed;

            float4 _Wave4Direction;
            float _Wave4Wavelength;
            float _Wave4Amplitude;
            float _Wave4Steepness;
            float _Wave4Speed;

            float _NormalEpsilon;

            TEXTURE2D(_DetailNormal);
            SAMPLER(sampler_DetailNormal);
            float4 _DetailNormal_ST;
            float _DetailScale;
            float _DetailSpeed;
            float _DetailStrength;

            float4 _WaterShadowColor;
            float4 _WaterMidColor;
            float4 _WaterLightColor;

            float _ShadowThreshold;
            float _ShadowSoftness;
            
            float _LightThreshold;
            float _LightSoftness;

            CBUFFER_END


            //----------------------------------------------------------
            // GERSTNER WAVE
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

                float c = sqrt(9.8 / k);

                float Q = steepness / (k * amplitude);

                float phase =
                    k * dot(direction, position)
                    - c * speed * _Time.y;

                float s = sin(phase);
                float co = cos(phase);

                return float3(
                    direction.x * Q * amplitude * co,
                    amplitude * s,
                    direction.y * Q * amplitude * co
                );
            }


            //----------------------------------------------------------
            // TOTAL WAVE HEIGHT
            //----------------------------------------------------------

            float CalculateWaveHeight(float2 position)
            {
                float height = 0;

                height += GerstnerWave(
                    position,
                    _Wave1Direction.xy,
                    _Wave1Wavelength,
                    _Wave1Amplitude,
                    _Wave1Steepness,
                    _Wave1Speed
                ).y;

                height += GerstnerWave(
                    position,
                    _Wave2Direction.xy,
                    _Wave2Wavelength,
                    _Wave2Amplitude,
                    _Wave2Steepness,
                    _Wave2Speed
                ).y;

                height += GerstnerWave(
                    position,
                    _Wave3Direction.xy,
                    _Wave3Wavelength,
                    _Wave3Amplitude,
                    _Wave3Steepness,
                    _Wave3Speed
                ).y;

                height += GerstnerWave(
                    position,
                    _Wave4Direction.xy,
                    _Wave4Wavelength,
                    _Wave4Amplitude,
                    _Wave4Steepness,
                    _Wave4Speed
                ).y;

                return height;
            }


            //----------------------------------------------------------
            // TOTAL DISPLACEMENT
            //----------------------------------------------------------

            float3 CalculateWaveDisplacement(float2 position)
            {
                float3 displacement = float3(0,0,0);

                displacement += GerstnerWave(
                    position,
                    _Wave1Direction.xy,
                    _Wave1Wavelength,
                    _Wave1Amplitude,
                    _Wave1Steepness,
                    _Wave1Speed
                );

                displacement += GerstnerWave(
                    position,
                    _Wave2Direction.xy,
                    _Wave2Wavelength,
                    _Wave2Amplitude,
                    _Wave2Steepness,
                    _Wave2Speed
                );

                displacement += GerstnerWave(
                    position,
                    _Wave3Direction.xy,
                    _Wave3Wavelength,
                    _Wave3Amplitude,
                    _Wave3Steepness,
                    _Wave3Speed
                );

                displacement += GerstnerWave(
                    position,
                    _Wave4Direction.xy,
                    _Wave4Wavelength,
                    _Wave4Amplitude,
                    _Wave4Steepness,
                    _Wave4Speed
                );

                return displacement;
            }


            //----------------------------------------------------------
            // NORMAL
            //----------------------------------------------------------

            float3 CalculateNormal(float2 worldPos)
            {
                float epsilon = max(_NormalEpsilon, 0.001);

                float2 posL = worldPos - float2(epsilon, 0);
                float2 posR = worldPos + float2(epsilon, 0);
                float2 posD = worldPos - float2(0, epsilon);
                float2 posU = worldPos + float2(0, epsilon);

                float3 dL = CalculateWaveDisplacement(posL);
                float3 dR = CalculateWaveDisplacement(posR);
                float3 dD = CalculateWaveDisplacement(posD);
                float3 dU = CalculateWaveDisplacement(posU);

                float3 pL = float3(
                    posL.x + dL.x,
                    dL.y,
                    posL.y + dL.z
                );

                float3 pR = float3(
                    posR.x + dR.x,
                    dR.y,
                    posR.y + dR.z
                );

                float3 pD = float3(
                    posD.x + dD.x,
                    dD.y,
                    posD.y + dD.z
                );

                float3 pU = float3(
                    posU.x + dU.x,
                    dU.y,
                    posU.y + dU.z
                );

                float3 tangentX = pR - pL;
                float3 tangentZ = pU - pD;

                // World-space normal.
                float3 normalWS =
                    normalize(
                        cross(tangentZ, tangentX)
                    );

                return normalWS;
            }


            //----------------------------------------------------------
            // LIGHTING
            //----------------------------------------------------------

            float3 CalculateStylizedLighting(float3 normalWS, Light mainLight)
            {
                float light = saturate(dot(normalWS, mainLight.direction));

                float shadowBand =
                    smoothstep(
                        _ShadowThreshold - _ShadowSoftness,
                        _ShadowThreshold + _ShadowSoftness,
                        light
                    );
                float lightBand =
                    smoothstep(
                        _LightThreshold - _LightSoftness,
                        _LightThreshold + _LightSoftness,
                        light
                    );

                float3 shadowColor = _WaterShadowColor.rgb;
                float3 midColor = _WaterMidColor.rgb;
                float3 lightColor = _WaterLightColor.rgb;

                float3 color = shadowColor;

                color = lerp(color, midColor, shadowBand);

                color = lerp(color, lightColor, lightBand);

                return color;
            }

            //----------------------------------------------------------
            // FRESNEL
            //----------------------------------------------------------

            // Fresnel removed for debugging. Keep shading simple.

            //----------------------------------------------------------
            // SURFACE DETAIL
            //----------------------------------------------------------

            float3 ApplyDetailNormal(
                float3 baseNormal,
                float2 uv)
            {
                float2 detailUV =
                    uv * _DetailScale;

                detailUV +=
                    float2(
                        _Time.y * _DetailSpeed,
                        _Time.y * _DetailSpeed * 0.35
                    );

                float3 detailNormal =
                    SAMPLE_TEXTURE2D(
                        _DetailNormal,
                        sampler_DetailNormal,
                        detailUV
                    ).xyz * 2.0 - 1.0;

                detailNormal.xy *= _DetailStrength;

                float3 combinedNormal =
                    normalize(
                        baseNormal +
                        float3(
                            detailNormal.x,
                            0,
                            detailNormal.y
                        )
                    );

                return combinedNormal;
            }


            //----------------------------------------------------------
            // VERTEX
            //----------------------------------------------------------

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float wave : TEXCOORD3;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Original object-space position
                float3 positionOS = IN.positionOS.xyz;

                // Convert to world space first
                float3 positionWS =
                    TransformObjectToWorld(positionOS);

                // Waves are now evaluated in WORLD space
                float2 wavePos =
                    positionWS.xz;

                // Calculate displacement using world coordinates
                float3 displacement =
                    CalculateWaveDisplacement(wavePos);

                // Apply displacement in world space
                positionWS += displacement;

                // Convert the displaced position back to object space
                float3 displacedPositionOS =
                    TransformWorldToObject(positionWS);

                VertexPositionInputs vertex =
                    GetVertexPositionInputs(displacedPositionOS);

                OUT.positionCS =
                    vertex.positionCS;

                // Keep the actual displaced world position
                OUT.positionWS = positionWS;

                OUT.uv = IN.uv;

                // compute and pass world-space normal (at displaced position)
                OUT.normalWS = CalculateNormal(positionWS.xz);

                // pass vertical displacement to fragment
                OUT.wave = displacement.y;

                return OUT;
            }


            //----------------------------------------------------------
            // FRAGMENT
            //----------------------------------------------------------

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();

                float3 surfaceNormal =
                    ApplyDetailNormal(
                        IN.normalWS,
                        IN.uv
                    );

                float3 color =
                    CalculateStylizedLighting(
                        surfaceNormal,
                        mainLight
                    );

                return float4(color, 1);
            }

            ENDHLSL
        }
    }
}