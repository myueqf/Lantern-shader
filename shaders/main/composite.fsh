#version 330 compatibility

#include /lib/distort.glsl
#include /settings.glsl

uniform sampler2D shadowtex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;

uniform vec3 shadowLightPosition;
uniform float rainStrength;
uniform int worldTime;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// 颜色
const vec3 blocklightColor = vec3(1.30, 0.85, 0.50);
const vec3 skylightColor = vec3(0.85, 0.95, 1.10) + 1.5;
const vec3 sunlightColor = vec3(1.30, 0.80, 0.70);

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 translucentOut;

vec3 computeLighting(vec3 albedo, float depth, vec2 lightmap, vec3 normal) {
    float t = mod(worldTime, 24000.0);
    float dayNightStrength;

    if (t > 12000.0 && t < 13000.0) {
        dayNightStrength = smoothstep(13000.0, 12000.0, t);
    }
    else if (t >= 13000.0 && t <= 23000.0) {
        dayNightStrength = 0.01;
    }
    else if (t > 23000.0 && t < 24000.0) {
        dayNightStrength = smoothstep(23000.0, 24000.0, t);
    }
    else {
        dayNightStrength = 1.0;
    }

    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

    // 阴影坐标转换
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

    // 应用畸变
    shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

    float cosTheta = clamp(dot(normal, worldLightVector), 0.0, 1.0);
    float bias = 0.001 + 0.004 * (1.0 - cosTheta);
    shadowScreenPos.z -= bias;

    #if SHADOW_SOFT == 0
    float shadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
    #elif SHADOW_SOFT == 1
    // --- 软阴影 ---
    float shadow = 0.0;
    float shadowRadius = 0.0008;

    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius, -shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius, -shadowRadius)).r);
    shadow /= 4.0;
    #endif

    // --- 光照合成 ---
    vec3 blocklight = pow(lightmap.r, 3.0) * blocklightColor * 2.0;
    vec3 skylight = lightmap.g * skylightColor * dayNightStrength * 0.55;

    float directLight = dot(worldLightVector, normal);
    float diffuse = clamp(directLight * 0.8 + 0.2, 0.0, 1.0);
    vec3 sunlight = sunlightColor * (diffuse * shadow * (1.0 - rainStrength) * dayNightStrength * 2.5);

    vec3 result = albedo;

    // 基础光照合成
    vec3 sceneLight = blocklight + skylight + sunlight + vec3(0.05);
    result *= sceneLight;

    result = pow(result, vec3(1.8));

    float luma = dot(result, vec3(0.2126, 0.7152, 0.0722));
    result = mix(vec3(luma), result, 1.0);

    vec3 x = result * 0.3; // 曝光补偿
    result = clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14), 0.0, 1.0);

    if (t > 10000.0 && t < 13000.0) {
        result *= mix(vec3(1.), vec3(1.1, 0.98, 0.75), 1.5);
    }
    else if (t >= 13000.0 && t <= 23000.0) {
        result *= mix(vec3(1.), vec3(1.15, 0.95, 0.8), 1.7);
    }
    else if (t > 22000.0 && t < 24000.0) {
        result *= mix(vec3(1.), vec3(1.1, 0.98, 0.75), 1.5);
    }
    else {
        result *= mix(vec3(1.), vec3(1.15, 0.95, 0.8), 0.43);
    }
    float gray = dot(result, vec3(0.299, 0.587, 0.114));
    result = mix(vec3(gray), result, 1.1);

    return result;
}

void main() {
    float opaqueDepth = texture(depthtex1, texcoord).r;
    vec4 translucentData = texture(colortex5, texcoord);

    // === 不透明物体光照 ===
    if (opaqueDepth == 1.0) {
        color = texture(colortex0, texcoord);
    } else {
        vec2 lightmap = texture(colortex1, texcoord).rg;
        vec3 encodedNormal = texture(colortex2, texcoord).rgb;
        vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

        vec3 albedo = texture(colortex0, texcoord).rgb;
        vec3 litOpaque = computeLighting(albedo, opaqueDepth, lightmap, normal);

        float noise = fract(sin(dot(texcoord, vec2(12.9898, 78.233) * float(worldTime))) * 43758.5453);
        litOpaque += noise * 0.003;

        color = vec4(litOpaque, 1.0);
    }

    // === 半透明物体光照 ===
    translucentOut = vec4(0.0);
    if (translucentData.a > 0.01) {
        float transDepth = texture(depthtex0, texcoord).r;
        vec2 transLightmap = texture(colortex6, texcoord).rg;
        vec3 transEncodedNormal = texture(colortex7, texcoord).rgb;
        vec3 transNormal = normalize((transEncodedNormal - 0.5) * 2.0);

        vec3 litTrans = computeLighting(translucentData.rgb, transDepth, transLightmap, transNormal);

        translucentOut = vec4(litTrans, translucentData.a);
    }
}
