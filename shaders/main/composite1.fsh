#version 330 compatibility

#include "/lib/distort.glsl"
#include /settings.glsl

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform float rainStrength;
uniform float far;
uniform int isEyeInWater;

uniform vec3 fogColor;

uniform mat4 gbufferProjectionInverse;

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  
  /* 雾效 */
  if(isEyeInWater == 1) {
    vec3 underwaterFogColor = vec3(0.1, 0.3, 0.5);
    
    if(depth == 1.0) {
      color.rgb = mix(color.rgb, underwaterFogColor, 0.95);
    } else {
      vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
      vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
      float dist = length(viewPos) / far;
      
      // 水下雾
      float underwaterFogFactor = 1.0 - exp(-dist * 15.0);
      color.rgb = mix(color.rgb, underwaterFogColor, clamp(underwaterFogFactor, 0.0, 0.9));
    }
  } else {
    #if FOG_COVER_SKY == 0
    if(depth == 1.0) {
      return;
    }
    #endif
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    float dist = length(viewPos) / far;
    // float fogFactor = exp(-10 * (0.3 - dist)); // 值越小雾越浓
    // color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));

    // ===== 雨雾 =====
    float fogFactor = mix(
    exp(-10 * (FOG_SIZE - dist)),   // 普通雾
    exp(-10 * (0.3 - dist)),   // 雨雾
    smoothstep(0.0, 0.3, rainStrength)
    );
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    color.rgb = mix(color.rgb, fogColor, fogFactor);
    // ==============
  }
}
