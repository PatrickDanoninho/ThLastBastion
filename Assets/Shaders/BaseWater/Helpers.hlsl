#pragma once

#ifndef TWO_PI
static const float TWO_PI = 6.28318530718;
#endif

// Gerstner wave helper (same signature as in your shader)
float3 GerstnerWave(
    float2 position,
    float2 direction,
    float wavelength,
    float amplitude,
    float steepness,
    float speed)
{
    direction = normalize(direction);
    float k = TWO_PI / max(wavelength, 1e-5);
    float omega = sqrt(9.8 * k);
    float Q = steepness / (k * max(amplitude, 1e-6));
    float phase = k * dot(direction, position) - omega * speed * _WaveSpeed * _Time.y;
    float s = sin(phase);
    float c = cos(phase);
    return float3(direction.x * Q * amplitude * c, amplitude * s, direction.y * Q * amplitude * c);
}

// Compose displacement from multiple waves
float3 CalculateWaveDisplacement(float2 position)
{
    float3 wave = float3(0, 0, 0);
    wave += GerstnerWave(position, float2(1, 0.3), 1.8, _WaveAmplitude, 0.25, 1.0);
    wave += GerstnerWave(position, float2(-0.6, 1), 3.7, _WaveAmplitude, 0.15, 0.8);
    wave += GerstnerWave(position, float2(0.2, -1), 5.6, _WaveAmplitude, 0.2, 1.3);
    // add other octaves as needed (keep consistent with shader)
    return wave;
}

// Analytic normals computed from Gerstner partials (object space -> world transform available)
float3 CalculateNormal(float2 worldPos)
{
    // Tangents ∂P/∂x and ∂P/∂z (object space)
    float3 Tx = float3(1, 0, 0);
    float3 Tz = float3(0, 0, 1);

    // For each wave: accumulate contributions (example for three waves)
    {
        float2 dir = normalize(float2(1.0, 0.3));
        float A = _WaveAmplitude;
        float lambda = 1.8;
        float steep = 0.25;
        float speed = 1.0;
        float k = TWO_PI / lambda;
        float omega = sqrt(9.8 * k);
        float Q = steep / (k * max(A, 1e-6));
        float phase = k * dot(dir, worldPos) - omega * speed * _WaveSpeed * _Time.y;
        float s = sin(phase);
        float c = cos(phase);
        float common = -Q * A * k * s;
        Tx.x += common * dir.x * dir.x;
        Tx.y += k * A * dir.x * c;
        Tx.z += common * dir.x * dir.y;
        Tz.x += common * dir.x * dir.y;
        Tz.y += k * A * dir.y * c;
        Tz.z += common * dir.y * dir.y;
    }

    // repeat per-wave blocks or factor into a helper to match CalculateWaveDisplacement

    float3 normalOS = normalize(cross(Tx, Tz));
    // transform to world space (Core.hlsl provides unity_ObjectToWorld)
    float3 normalWS = normalize(mul((float3x3) unity_ObjectToWorld, normalOS));
    return normalWS;
}