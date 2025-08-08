#version 330 compatibility
#include "/settings.glsl"

uniform sampler2D gtexture;
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
    lightmapData = vec4(lmcoord, 0.0, 1.0);
    normalData = vec4(normal * 0.5 + 0.5, 1.0);
    #if LIGHT_ONLY == 1
    color.rgb = vec3(1);
    #endif
    if (color.a < alphaTestRef) discard;
}
