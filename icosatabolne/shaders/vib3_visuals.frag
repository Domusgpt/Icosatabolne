#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uChaos;
uniform float uGeometry; // 0=Holo, 1=Quantum
uniform float uHue;
uniform float uSaturation;
uniform float uIntensity;

out vec4 fragColor;

const float PI = 3.14159265359;
const int MAX_STEPS = 32; // Reduced for performance
const float MAX_DIST = 10.0;
const float SURF_DIST = 0.01;

// --------------------------------------------------------
// Utilities
// --------------------------------------------------------

mat2 rotate2d(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Simple hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// --------------------------------------------------------
// SDFs
// --------------------------------------------------------

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

// 4D Hypercube Projection (Approximate)
float sdTesseract(vec3 p) {
    // 4D Rotation (ZW plane rotation affects 3D projection size/shape)
    float angle = uTime * 0.5;
    float s = sin(angle);
    float c = cos(angle);

    // Rotate in 3D first
    p.xz *= rotate2d(uTime * 0.3);
    p.xy *= rotate2d(uTime * 0.2);

    // 4D projection effect: The "W" slice changes the 3D box size
    // Imagine W oscillating.
    float w = sin(uTime) * 0.5;

    // Inner/Outer box logic for "Holographic" wireframe feel
    // We render a solid box but use lighting to make it look wireframe-ish
    return sdBox(p, vec3(0.5 + w * 0.1));
}

float GetDist(vec3 p) {
    float d = 0.0;

    // Chaos Jitter
    if (uChaos > 0.1) {
        p += vec3(hash(p.xy + uTime) - 0.5) * 0.02 * uChaos;
    }

    if (uGeometry < 0.5) {
        // Holographic: Tesseract
        d = sdTesseract(p);
        // Subtract inner to make hollow?
        // float inner = sdBox(p, vec3(0.4));
        // d = max(d, -inner);
    } else {
        // Quantum: Sphere/Cloud
        // Distort sphere with noise
        float displacement = sin(5.0 * p.x + uTime) * sin(5.0 * p.y) * sin(5.0 * p.z) * 0.1;
        d = sdSphere(p, 0.6) + displacement * uChaos;
    }

    return d;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(0.01, 0);
    vec3 n = d - vec3(
        GetDist(p - e.xyy),
        GetDist(p - e.yxy),
        GetDist(p - e.yyx));
    return normalize(n);
}

void main() {
    vec2 uv = (FlutterFragCoord().xy - 0.5 * uSize.xy) / uSize.y;
    vec3 ro = vec3(0.0, 0.0, -2.0); // Camera back
    vec3 rd = normalize(vec3(uv, 1.0)); // Ray forward

    float d = 0.0;
    vec3 p = ro;
    bool hit = false;

    // Raymarch
    for (int i = 0; i < MAX_STEPS; i++) {
        p = ro + rd * d;
        float ds = GetDist(p);
        d += ds;
        if (d > MAX_DIST || abs(ds) < SURF_DIST) {
            if (abs(ds) < SURF_DIST) hit = true;
            break;
        }
    }

    vec3 col = vec3(0.0);

    if (hit) {
        vec3 n = GetNormal(p);
        vec3 l = normalize(vec3(1.0, 2.0, -2.0));

        // Lighting
        float diff = max(0.0, dot(n, l));
        float amb = 0.1 + 0.2 * uChaos;

        // Rim light (for holographic look)
        float rim = 1.0 - max(0.0, dot(n, -rd));
        rim = pow(rim, 3.0);

        // Color
        vec3 baseColor = hsv2rgb(vec3(uHue / 360.0, uSaturation, uIntensity));

        if (uGeometry < 0.5) {
            // Holo: mostly rim + edge
            col = baseColor * (diff * 0.2 + rim * 2.0);
            // Grid lines on object
            if (mod(p.x * 10.0, 1.0) < 0.1 || mod(p.y * 10.0, 1.0) < 0.1) {
                col += vec3(1.0) * 0.5;
            }
            col.a = 0.8; // Transparent? (Not in shader output usually)
        } else {
            // Quantum: smooth + chaos
            col = baseColor * (diff + amb);
            col += baseColor * rim * uChaos; // Glow more with chaos
        }
    } else {
        // Background Glow
        float glow = 0.02 / length(uv);
        col = hsv2rgb(vec3(uHue / 360.0, 0.5, 0.5)) * glow * uChaos;
    }

    // Chromatic Aberration / Scanlines
    if (mod(FlutterFragCoord().y, 4.0) < 1.0) col *= 0.8;

    fragColor = vec4(col, 1.0);
}
