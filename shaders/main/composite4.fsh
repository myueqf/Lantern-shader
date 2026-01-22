#version 330 compatibility

#include "/settings.glsl"
#include "/lib/dofoffsets.glsl"

varying vec2 TexCoords;

uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;
uniform mat4 gbufferProjection;
uniform sampler2D colortex0;
uniform sampler2D depthtex1;

vec3 DepthOfField(vec3 color, float z) {
    float hand = float(z < 0.56);
    if (hand > 0.5) return color;

    float coc = abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01;
    if (coc <= 0.0) return color;

    coc = coc * inversesqrt(coc * coc + 0.1);

    float fovScale = gbufferProjection[1][1] * 0.72992700729927;
    vec2 cocScale = vec2(coc * 0.015 * fovScale / aspectRatio, coc * 0.015 * fovScale);
    float lod = log2(viewHeight * aspectRatio * coc * fovScale * 0.003125);

    vec3 dof = vec3(0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < DOF_SAMPLE; i++) {
        vec2 offset = dofOffsets[min(i << 1, 59)];
        vec2 sampleCoord = TexCoords + offset * cocScale;

        float weight = 1.0 - length(offset) * 0.08695652173913043;
        weight = max(weight, 0.0);

        dof += texture2DLod(colortex0, sampleCoord, lod).rgb * weight;
        totalWeight += weight;
    }

    return totalWeight > 0.0 ? dof / totalWeight : color;
}

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;
    float z = texture2D(depthtex1, TexCoords).r;

    #if DOFDEBUG == 1
    float coc = abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01;
    coc = max(coc, 0.0) * inversesqrt(max(coc * coc + 0.1, 0.1));
    gl_FragData[0] = vec4(vec3(coc), 1.0);
    #elif DOF == 1
    gl_FragData[0] = vec4(DepthOfField(color, z), 1.0);
    #else
    gl_FragData[0] = vec4(color, 1.0);
    #endif
}