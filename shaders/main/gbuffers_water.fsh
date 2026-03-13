#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform int isEyeInWater;
uniform float alphaTestRef = 0.1;
in vec2 lmcoord;
in vec2 texcoord;
in vec3 normal;
in vec4 glcolor;

/* RENDERTARGETS: 5,6,7 */
layout(location = 0) out vec4 translucentColor;
layout(location = 1) out vec4 translucentLightmap;
layout(location = 2) out vec4 translucentNormal;

void main() {
    translucentColor = texture(gtexture, texcoord) * glcolor;

    if (translucentColor.a <= 0.05) discard;

    if (isEyeInWater == 1) {
        translucentColor.a = 0.9;
    }

    translucentLightmap = vec4(lmcoord, 0.0, 1.0);
    translucentNormal = vec4(normal * 0.5 + 0.5, 1.0);
}
