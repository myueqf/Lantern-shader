#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform int isEyeInWater;
uniform float alphaTestRef = 0.1;
in vec2 lmcoord;
in vec2 texcoord;
in vec3 normal;
in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 normalData;

void main() {
    color = texture(gtexture, texcoord) * glcolor;

    if (isEyeInWater == 1) {
        color.a = 0.9;
        return;
    }
    if (color.a <= 0.05) discard;
    if (color.a < 0.75) {
        ivec2 px = ivec2(gl_FragCoord.xy) % 2;
        if ((px.x ^ px.y) == 0) discard;
    }

    color.a = 1.0;
    lightmapData = vec4(lmcoord, 0.0, 1.0);
    normalData = vec4(normal * 0.5 + 0.5, 1.0);
}