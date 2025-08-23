vec3 distortShadowClipPos(vec3 shadowClipPos){
  shadowClipPos.xy /= 0.8*abs(shadowClipPos.xy) + 0.2;
  
  return shadowClipPos;
}

#define PIXELSHADOW true // [true false]
const bool shadowtex0Nearest = PIXELSHADOW;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;
