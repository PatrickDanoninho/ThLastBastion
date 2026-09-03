Shader "Custom/CelShader"
{
    Properties
    {
        [MainColor]
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)

        [MainTexture]
        _BaseMap("Base Map", 2D) = "white" {}

        [Space(10)]
        [Header(Cel Shading)]

        _ShadowColor("Shadow Color", Color) = (0.15, 0.15, 0.15, 1)
        _MidColor("Mid Color", Color) = (0.5, 0.5, 0.5, 1)
        _LightColor("Light Color", Color) = (1, 1, 1, 1)

        _ShadowThreshold("Shadow Threshold", Range(0,1)) = 0.35
        _LightThreshold("Light Threshold", Range(0,1)) = 0.70

        [Space(10)]
        [Header(Lighting Offset)]

        _LightingOffsetTex("Lighting Offset Texture", 2D) = "gray" {}
        _LightingOffsetStrength("Offset Strength", Range(0,1)) = 0.15
        _LightingOffsetScale("Offset Scale", Float) = 4

        [Space(10)]
        [Header(Rim Light)]

        _RimColor("Rim Color", Color) = (0.3, 0.7, 1.0, 1)
        _RimThreshold("Rim Threshold", Range(0,1)) = 0.65
        _RimPower("Rim Power", Range(0.5,8)) = 3.0
        _RimStrength("Rim Strength", Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //----------------------------------------------------------
            // STRUCTS
            //----------------------------------------------------------

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            //----------------------------------------------------------
            // TEXTURES
            //----------------------------------------------------------

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_LightingOffsetTex);
            SAMPLER(sampler_LightingOffsetTex);

            //----------------------------------------------------------
            // MATERIAL PROPERTIES
            //----------------------------------------------------------

            CBUFFER_START(UnityPerMaterial)

                half4 _BaseColor;
                float4 _BaseMap_ST;

                float4 _ShadowColor;
                float4 _MidColor;
                float4 _LightColor;

                float _ShadowThreshold;
                float _LightThreshold;

                float4 _LightingOffsetTex_ST;
                float _LightingOffsetStrength;
                float _LightingOffsetScale;

                float4 _RimColor;
                float _RimThreshold;
                float _RimPower;
                float _RimStrength;

            CBUFFER_END

            //----------------------------------------------------------
            // LIGHTING
            //----------------------------------------------------------

            float CalculateLighting(float3 normalWS)
            {
                Light mainLight = GetMainLight();

                float light =
                    saturate(
                        dot(
                            normalWS,
                            mainLight.direction
                        )
                    );

                return light;
            }

            //----------------------------------------------------------
            // Fresnel
            //----------------------------------------------------------

            float CalculateFresnel(float3 normalWS, float3 positionWS)
            {
                float3 viewDirection = normalize(GetWorldSpaceViewDir(positionWS));

                float fresnel = 1.0 - saturate(dot(normalWS, viewDirection));

                return pow(fresnel, _RimPower);
            }

            float3 CalculateAmbient(float3 normalWS)
            {
                return SampleSH(normalWS);
            }

            float ApplyLightingOffset(float light, float2 uv)
            {
                float2 lightingUV =
                    TRANSFORM_TEX(
                        uv,
                        _LightingOffsetTex
                    );

                lightingUV *= _LightingOffsetScale;

                float lightingOffset =
                    SAMPLE_TEXTURE2D(
                        _LightingOffsetTex,
                        sampler_LightingOffsetTex,
                        lightingUV
                    ).r;

                lightingOffset =
                    lightingOffset * 2.0 - 1.0;

                light +=
                    lightingOffset *
                    _LightingOffsetStrength;

                return saturate(light);
            }

            float3 CalculateCelColor(float light)
            {
                float shadow =
                    step(
                        _ShadowThreshold,
                        light
                    );

                float highlight =
                    step(
                        _LightThreshold,
                        light
                    );

                float3 celColor =
                    _ShadowColor.rgb;

                celColor =
                    lerp(
                        celColor,
                        _MidColor.rgb,
                        shadow
                    );

                celColor =
                    lerp(
                        celColor,
                        _LightColor.rgb,
                        highlight
                    );

                return celColor;
            }

            float3 CalculateRim(float3 normalWS, float3 positionWS, float light)
            {
                float fresnel = CalculateFresnel(normalWS, positionWS);

                float rim = step(_RimThreshold, fresnel);

                float shadowMask = 1.0 - step(_ShadowThreshold, light);

                rim *= shadowMask;

                return _RimColor.rgb * rim * _RimStrength;
            }

            //----------------------------------------------------------
            // VERTEX
            //----------------------------------------------------------

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS =
                    TransformObjectToHClip(
                        IN.positionOS.xyz
                    );

                OUT.uv =
                    TRANSFORM_TEX(
                        IN.uv,
                        _BaseMap
                    );

                OUT.normalWS =
                    TransformObjectToWorldNormal(
                        IN.normalOS
                    );

                OUT.positionWS =
                    TransformObjectToWorld(
                        IN.positionOS.xyz
                    );

                return OUT;
            }

            //----------------------------------------------------------
            // FRAGMENT
            //----------------------------------------------------------
            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalWS =
                    normalize(IN.normalWS);

                // Base color
                float3 baseColor = SAMPLE_TEXTURE2D(
                        _BaseMap,
                        sampler_BaseMap,
                        IN.uv
                    ).rgb;

                baseColor *= _BaseColor.rgb;

                // Lighting
                float light =
                    CalculateLighting(
                        normalWS
                    );

                light =
                    ApplyLightingOffset(
                        light,
                        IN.uv
                    );

                // Cel shading
                float3 celColor =
                    CalculateCelColor(
                        light
                    );

                // Base + cel
                float3 finalColor =
                    baseColor *
                    celColor;

                // Environment lighting
                finalColor +=
                     baseColor *
                     CalculateAmbient(
                         normalWS
                     );


                // Rim light
                finalColor +=
                    CalculateRim(
                        normalWS,
                        IN.positionWS,
                        light
                    );

                return float4(
                    finalColor,
                    1
                );
            }

            ENDHLSL
        }
    }
}
