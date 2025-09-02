//////////////////////
// === settings === //
//////////////////////
/* DEBUG */
#define LIGHT_ONLY 0 //[0 1]

/* 像素化 */
#define PIXEL 4 //[0 1 2 3 4]

/* 动态模糊 */
#define MOTIONBLUR 0 // [0 1]
/* 景深 */
#define DOF 0 //[0 1]
#define DOF_STRENGTH 8.0  //[1.0 2.0 4.0 8.0 16.0 32.0]
#define DOFDEBUG 0 //[0 1]
#define DOF_SAMPLE 24 //[8 16 24 32 64]
/* bloom */
#define THRESHOLD 0.3 // [0.1 0.2 0.3 0.4 0.5] 最小触发泛光亮度
float threshold = THRESHOLD;
float knee = 0.5; // 软阈值范围
float bloomScale = 0.03; // 发光强度缩放
float noiseScale1 = 0.005; // 近距离噪声幅度
float noiseScale2 = 0.012; // 远距离噪声幅度
#define EXPONENT 1.0 // [0.5 1.0 1.5 2.0 2.5] 强度
float exponent = EXPONENT;

/* 昼夜亮度增益 */
#define BRIGHTNESS_GAIN 0.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7]

/* 普通雾大小 */
#define FOG_SIZE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 100.0]
#define FOG_COVER_SKY 0 // [0 1] 雾覆盖天空

/* 天空颜色样式 */
#define SKYCOLORSTYLE 0 // [0 1]

/* Gamma */
#define GAMMA 0.95 // [0.55 0.65 0.75 0.85 0.95 1.00 1.25 1.33 1.40 1.55]