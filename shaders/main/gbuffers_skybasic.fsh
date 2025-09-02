#version 330 compatibility

#include /settings.glsl

uniform int renderStage;
uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunPosition;

in vec4 glcolor;

float fogify(float x, float w) {
    return w / (x * x + w);
}

const vec3 nightCol = vec3(0.0, 0.005, 0.02);
#if SKYCOLORSTYLE == 0
vec3 calcSkyColor(vec3 pos) {
    float upDot = dot(pos, gbufferModelView[1].xyz);
    float sunDot = dot(normalize(pos), normalize(sunPosition));
    // 基础天空颜色
    vec3 baseSkyColor = mix(skyColor * vec3(0.9, 0.6, 0.7), fogColor, fogify(max(upDot, 0.0), 0.1));
    // 夜晚颜色混合
    vec3 finalSkyColor = mix(nightCol, baseSkyColor, clamp(sunDot * 0.5 + 0.5, 0.0, 1.0));
    return finalSkyColor;
}
#else
vec3 calcSkyColor(vec3 pos) {
    float upDot = dot(pos, gbufferModelView[1].xyz);
    return mix(skyColor * vec3(0.7, 0.6, 0.7), fogColor, fogify(max(upDot, 0.0), 0.1));
}
#endif

vec3 screenToView(vec3 screenPos) {
    vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * ndcPos;
    return tmp.xyz / tmp.w;
}

layout(location = 0) out vec4 color;

void main() {
    if (renderStage == MC_RENDER_STAGE_STARS) {
        color = glcolor;
    } else {
        vec3 pos = screenToView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0));
        color = vec4(calcSkyColor(normalize(pos)), 1.0);
    }
    color *= pow(1.5, 1.3); // 调整下曝光XwX
}
