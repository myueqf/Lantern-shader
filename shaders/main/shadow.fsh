#version 330 compatibility

const int shadowMapResolution = 1024; // 阴影图的分辨率XwX

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
  color = texture(gtexture, texcoord) * glcolor;
  if(color.a < 0.1){
    discard;
  }
}
