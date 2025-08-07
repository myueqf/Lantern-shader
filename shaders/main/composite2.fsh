#version 330 compatibility
/* bloom */
uniform sampler2D colortex0;
in vec2 texcoord;

/* RENDERTARGETS: 0,3,4 */
layout(location = 0) out vec4 color;
layout(location = 3) out vec4 bloom;
layout(location = 4) out vec4 farbloom;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(41.935, 99.122))) * 87153.6598);
}

float softThreshold(float lum, float threshold, float knee) {
    float soft = clamp((lum - threshold + knee) / knee, 0.0, 1.0);
    return max(soft, lum > threshold ? 1.0 : 0.0);
}

void main() {
    vec3 srcColor = texture(colortex0, texcoord).rgb;
    float lum = dot(srcColor, vec3(0.2126, 0.7152, 0.0722));

    float threshold     = 0.3;     // 发光最小亮度
    float knee            = 0.5;     // 软阈值范围
    float bloomScale  = 0.03;   // 发光强度缩放
    float noiseScale1 = 0.005;  // 近距离噪声幅度
    float noiseScale2 = 0.012;  // 远距离噪声幅度
    float exponent     = 2.0;     // 发光强度指数

    float weight = softThreshold(lum, threshold, knee);

    vec2 noise = vec2(
        rand(texcoord),
        rand(texcoord + vec2(1.0))
    ) * 2.0 - 1.0;

    vec2 uv1 = texcoord + noise * noiseScale1;
    vec2 uv2 = texcoord + noise * noiseScale2;

    color = vec4(srcColor, 1.0);

    vec3 c1 = texture(colortex0, uv1).rgb;
    vec3 c2 = texture(colortex0, uv2).rgb;

    bloom.rgb    = pow(c1, vec3(exponent)) * bloomScale * weight;
    farbloom.rgb = pow(c2, vec3(exponent)) * bloomScale * weight;

    color.rgb += bloom.rgb + farbloom.rgb;
}

