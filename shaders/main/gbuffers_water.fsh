#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);
    
    // 水面颜色
    vec3 waterTint = vec3(0.8, 1.0, 0.6);
    color.rgb *= waterTint;
    
    if (color.a < alphaTestRef) discard;
}
