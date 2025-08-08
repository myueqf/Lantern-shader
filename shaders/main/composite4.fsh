#version 130

#include "/settings.glsl"
#include "/lib/dofoffsets.glsl"

varying vec2 TexCoords;

uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;

uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;


vec3 DepthOfField(vec3 color, float z) {
    vec3 dof = vec3(0.0);
    float totalWeight = 0.0;
    float hand = float(z < 0.56);

    float fovScale = gbufferProjection[1][1] / 1.37;
    float coc = max(abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
    coc = coc / sqrt(coc * coc + 0.1);

    if (coc > 0.0 && hand < 0.5) {
        for(int i = 0; i < DOF_SAMPLE; i++) {
            int offsetIndex = i * 2;
            offsetIndex = min(offsetIndex, 59);
            vec2 offset = dofOffsets[offsetIndex] * coc * 0.015 * fovScale * vec2(1.0 / aspectRatio, 1.0);
            float lod = log2(viewHeight * aspectRatio * coc * fovScale / 320.0);
            vec3 sampleColor = texture2DLod(colortex0, TexCoords + offset, lod).rgb;

            float weight = 1.0 - length(dofOffsets[offsetIndex]) / 11.5;
            weight = max(weight, 0.0);

            dof += sampleColor * weight;
            totalWeight += weight;
        }

        if (totalWeight > 0.0) {
            dof /= totalWeight;
        } else {
            dof = color;
        }
    } else {
        dof = color;
    }
    return dof;
}

void main() {
    vec3 color = texture2D(colortex0, TexCoords).rgb;
    float z = texture2D(depthtex1, TexCoords).r;

    #if DOFDEBUG == 1
    float fovScale = gbufferProjection[1][1] / 1.37;
    float coc = max(abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
    coc = coc / sqrt(coc * coc + 0.1);
    gl_FragData[0] = vec4(vec3(coc), 1.0);
    #elif DOF == 1
    color = DepthOfField(color, z);
    gl_FragData[0] = vec4(color, 1.0);
    #endif
}
