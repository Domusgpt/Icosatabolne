#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uChaos;
uniform float uGeometry; // 0=Holo, 1=Quantum (Morphable)
uniform float uHue;
uniform float uSaturation;
uniform float uIntensity;

// New Parameters
uniform float uRotXY;
uniform float uRotXZ;
uniform float uRotYZ;
uniform float uRotXW;
uniform float uRotYW;
uniform float uRotZW;
uniform float uDistortion;
uniform float uZoom;

out vec4 fragColor;

const float PI = 3.14159265359;
const int MAX_STEPS = 40;
const float MAX_DIST = 10.0;
const float SURF_DIST = 0.001;

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

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// --------------------------------------------------------
// 4D / Geometry
// --------------------------------------------------------

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

// Tesseract (Hypercube) SDF approximation with 4D rotations
float sdTesseract(vec3 p) {
    // Apply 4D rotations (projected to 3D)
    // We simulate 4D rotation by deforming the 3D space based on "W"
    // W is approximated by time and specific rotation parameters

    // Standard 3D rotations
    p.xy *= rotate2d(uRotXY + uTime * 0.1);
    p.xz *= rotate2d(uRotXZ);
    p.yz *= rotate2d(uRotYZ);

    // 4D Rotations (simulated as oscillating deformations)
    // XW rotation: rotates X into W.
    float xw = sin(uRotXW + uTime) * 0.5;
    float yw = sin(uRotYW + uTime * 0.7) * 0.5;
    float zw = sin(uRotZW + uTime * 1.3) * 0.5;

    // Morph the box dimensions based on W-plane interactions
    vec3 dims = vec3(0.5) + vec3(xw, yw, zw) * 0.3;

    // Wireframe logic requires specialized rendering,
    // but here we just return the solid shape for SDF
    return sdBox(p, dims);
}

float sdQuantumCloud(vec3 p) {
    // Sphere with heavy noise/distortion
    float base = sdSphere(p, 0.6);

    // 4D noise approximation
    float noise = sin(p.x * 10.0 + uRotXW) * sin(p.y * 10.0 + uRotYW) * sin(p.z * 10.0 + uRotZW);
    noise *= uDistortion * 0.2;

    return base + noise;
}

float GetDist(vec3 p) {
    // Apply overall distortion/chaos to position
    if (uChaos > 0.0) {
        float noise = sin(p.x * 20.0) * sin(p.y * 20.0 + uTime * 5.0);
        p += noise * 0.01 * uChaos;
    }

    // Morph between Tesseract (Holo) and Cloud (Quantum)
    float dHolo = sdTesseract(p);
    float dQuant = sdQuantumCloud(p);

    // Smooth blend based on uGeometry (0.0 to 1.0)
    return mix(dHolo, dQuant, smoothstep(0.2, 0.8, uGeometry));
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(0.001, 0);
    vec3 n = d - vec3(
        GetDist(p - e.xyy),
        GetDist(p - e.yxy),
        GetDist(p - e.yyx));
    return normalize(n);
}

void main() {
    vec2 uv = (FlutterFragCoord().xy - 0.5 * uSize.xy) / uSize.y;

    // Camera Zoom
    vec3 ro = vec3(0.0, 0.0, -2.0 - uZoom);
    vec3 rd = normalize(vec3(uv, 1.0));

    // Camera jitter (Chaos)
    if (uChaos > 0.5) {
        ro.xy += (vec2(sin(uTime * 50.0), cos(uTime * 43.0)) * 0.02 * (uChaos - 0.5));
    }

    float d = 0.0;
    vec3 p = ro;
    bool hit = false;
    float steps = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        p = ro + rd * d;
        float ds = GetDist(p);
        d += ds;
        steps += 1.0;
        if (d > MAX_DIST || abs(ds) < SURF_DIST) {
            if (abs(ds) < SURF_DIST) hit = true;
            break;
        }
    }

    vec3 col = vec3(0.0);
    vec3 baseColor = hsv2rgb(vec3(uHue / 360.0, uSaturation, uIntensity));

    if (hit) {
        vec3 n = GetNormal(p);
        vec3 l = normalize(vec3(1.0, 2.0, -2.0));

        float diff = max(0.0, dot(n, l));
        float rim = 1.0 - max(0.0, dot(n, -rd));
        rim = pow(rim, 2.0);

        // Material mixing
        if (uGeometry < 0.5) {
            // Holographic: Wireframe-ish, Rim-heavy
            float grid = sin(p.x * 20.0) * sin(p.y * 20.0) * sin(p.z * 20.0);
            float wire = smoothstep(0.9, 1.0, grid);

            col = baseColor * (diff * 0.3 + rim * 1.5);
            col += vec3(wire) * 0.5 * uIntensity;
        } else {
            // Quantum: Soft, glowing, internal energy
            float innerGlow = 1.0 / (steps * 0.5);
            col = baseColor * (diff + rim + innerGlow * 2.0);
        }
    } else {
        // Background
        // Vaporwave Grid
        float gridY = 1.0 / abs(uv.y + 0.5); // Perspective plane
        float gridX = sin(uv.x * gridY * 10.0 + uTime);
        float grid = smoothstep(0.95, 1.0, abs(sin(gridY * 10.0 - uTime)));

        vec3 bgCol = hsv2rgb(vec3((uHue + 180.0) / 360.0, 0.6, 0.2));

        // Moiré Glitch
        float moire = sin(uv.x * 100.0 + uTime) * sin(uv.y * 100.0);
        if (uChaos > 0.2) bgCol += vec3(moire) * uChaos * 0.2;

        // Grid lines
        if (uv.y < 0.0) {
            col += bgCol * (grid + smoothstep(0.9, 1.0, gridX)) * 0.5;
        }

        // Glow center
        col += baseColor * (0.05 / length(uv)) * uIntensity;
    }

    // Chromatic Aberration
    float aberration = uChaos * 0.05 + uDistortion * 0.02;
    if (aberration > 0.001) {
        // Very simple simulated aberration by offsetting color
        // In a single pass, we can't easily sample neighbors without texture,
        // so we just shift the current color based on screen pos
        col.r *= 1.0 + aberration * sin(uTime * 10.0);
        col.b *= 1.0 - aberration * cos(uTime * 10.0);
    }

    // Scanlines
    if (mod(FlutterFragCoord().y, 4.0) < 2.0) col *= 0.9;

    // Output
    fragColor = vec4(col, 1.0);
}
