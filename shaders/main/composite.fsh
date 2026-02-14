#version 330 compatibility

#include /lib/distort.glsl
#include /settings.glsl

uniform sampler2D shadowtex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

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
const vec3 sunlightColor = vec3(1.20, 1.10, 0.95);

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        color = texture(colortex0, texcoord);
        return;
    }

    vec2 lightmap = texture(colortex1, texcoord).rg;
    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

    // 昼夜循环
    float timeNormalized = mod((worldTime + 8000.0) / 24000.0, 1.0);
#if BRIGHTNESS_GAIN >= 0.1
    float dayNightStrength = (0.5 + BRIGHTNESS_GAIN) + 0.5 * cos((timeNormalized - 0.5) * 6.2832);
#else
    float dayNightStrength = 0.5 + 0.5 * cos((timeNormalized - 0.5) * 6.2832);
#endif

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
    float shadowRadius = 0.0008; // 模糊半径

    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius, -shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius, -shadowRadius)).r);
    shadow /= 4.0;
    // -----------------------
    #endif

    // --- 光照合成 ---
    vec3 blocklight = pow(lightmap.r, 3.0) * blocklightColor * 2.0;
    vec3 skylight = lightmap.g * skylightColor * dayNightStrength * 0.55;

    float directLight = dot(worldLightVector, normal);
    float diffuse = clamp(directLight * 0.8 + 0.2, 0.0, 1.0);
    vec3 sunlight = sunlightColor * (diffuse * shadow * (1.0 - rainStrength) * dayNightStrength * 2.5);

    color = texture(colortex0, texcoord);

    // 基础光照合成
    vec3 sceneLight = blocklight + skylight + sunlight + vec3(0.05); // 0.05 是基础环境微光
    color.rgb *= sceneLight;

    color.rgb = pow(color.rgb, vec3(1.8));

    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(vec3(luma), color.rgb, 1.0);

    vec3 x = color.rgb * 0.3; // 曝光补偿
    color.rgb = clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14), 0.0, 1.0);

    //color.rgb = pow(color.rgb, vec3(1.0/2.2));

    float noise = fract(sin(dot(texcoord, vec2(12.9898, 78.233))) * 43758.5453);
    //color.rgb *= mix(vec3(1.), vec3(1.15, 0.95, 0.8), 1.0);
    color.rgb += (noise - 0.5) * (1.0/255.0);
}