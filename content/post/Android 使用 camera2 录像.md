---
title: "Android 使用 camera2 录像"
description: "本文讲解了在 Android 中如何使用 camera2 录像"
keywords: "Android,音视频开发,camera2,录像"

date: 2024-01-06T17:11:00+08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - camera2
  - 录像

url: post/0A86B58BB65D4E43B303DEE899E11A5D.html
toc: true
---

本文讲解了在 Android 中如何使用 camera2 录像。

<!--More-->

## 日记暂时记录

### 预览步骤

1 - SurfaceView.getHolder.surfaceCreated >>> Surface 创建时进行配置

2 - StreamConfigurationMap.isOutputSupportedFor(SurfaceHolder::class.java) >>> 判断视频流是否支持输出到 SurfaceHolder

3 - context.getSystemService(Context.CAMERA_SERVICE) >>> 获取 CameraManager 类

4 - CameraManager.getCameraIdList() 和 CameraManager.getCameraCharacteristics(cameraId) >>> 获取所有的相机列表，并筛选出其中可用的相机

```kotlin
val cameraIds = cameraIdList.filter {
    val characteristics = cameraManager.getCameraCharacteristics(it)
    val capabilities = characteristics.get(
        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES
    )
    // 过滤出向后兼容(又叫向下兼容，兼容旧代码)的功能集
    capabilities?.contains(
        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_BACKWARD_COMPATIBLE
    ) ?: false
}
```

5 - CameraCharacteristics.get(key) >>> 使用诸如相机朝向等信息筛选出目标相机：

```kotlin
val facing = characteristics.get(
    CameraCharacteristics.LENS_FACING
) ?: CameraMetadata.LENS_FACING_FRONT

val facingDesc = lensOrientationString(facing)

// 返回相机朝向的说明文本
private fun lensOrientationString(
    facing: Int
) = when(facing) {
    CameraCharacteristics.LENS_FACING_BACK -> "Back"
    CameraCharacteristics.LENS_FACING_FRONT -> "Front"
    CameraCharacteristics.LENS_FACING_EXTERNAL -> "External"
    else -> "Unknown"
}
```

**3/4/5 步和 1/2 步可以并行**

6 - CameraCharacteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) >>> 获取 StreamConfigurationMap 配置集

7 - StreamConfigurationMap.getOutputSizes >>> 获取输出流支持的尺寸，并筛选出支持的可用尺寸

```kotlin
// 根据尺寸的面积从小到大排序
val validSizes = allSizes
    .sortedBy { it.height * it.width }

// 获取小于等于目标最大值的尺寸
return validSizes.first { it.long <= maxSize.long && it.short <= maxSize.short }.size
```

8 - 初始化 EGL 配置

8.1 - EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY) >>> 获取默认的 EGL 输出

```kotlin
private var eglDisplay = EGL14.EGL_NO_DISPLAY
eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
    throw RuntimeException("unable to get EGL14 display")
}
```

8.2 - EGL14.eglInitialize >>> 初始化 EGL

```kotlin
val version = intArrayOf(0, 0)
if (!EGL14.eglInitialize(eglDisplay, version, 0, version, 1)) {
    eglDisplay = null
    throw RuntimeException("unable to initialize EGL14")
}
```

8.3 - EGL14.eglChooseConfig >>> 确定合适的 EGL 属性

- EGL_RENDERABLE_TYPE 表示 EGL 配置支持的使用 eglCreateContext 函数创建的 client API 上下文的类型，此处设置为 OPENGL_ES 2。
- EGL_RED_SIZE/EGL_GREEN_SIZE/EGL_BLUE_SIZE/EGL_ALPHA_SIZE 表示 RGBA 颜色缓冲区中各颜色分量的颜色位数，此处颜色格式设置为 ARGB_8888。
- EGL_DEPTH_SIZE 表示所需的 depth buffer(深度缓冲区)的尺寸(单位为 bit)。
- EGL_STENCIL_SIZE 表示所需的 stencil buffer (模板缓冲区)的尺寸(单位为 bit)。
- EGL_RECORDABLE_ANDROID 表示 Android 指定的标志。此标志告诉 EGL 它创建的 surface 必须和视频编解码器兼容。没有这个标志，EGL 可能会使用一个 MediaCodec 不能理解的 Buffer。这个变量在 api 26 以后系统才自带有。
- EGL_NONE 表示属性列表的数组结束标记。

```kotlin
// 我们需要的 EGL 配置列表
val configAttribList = intArrayOf(
    EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
    EGL14.EGL_RED_SIZE, 8,
    EGL14.EGL_GREEN_SIZE, 8,
    EGL14.EGL_BLUE_SIZE, 8,
    EGL14.EGL_ALPHA_SIZE, 8,
    EGL14.EGL_DEPTH_SIZE, 0,
    EGL14.EGL_STENCIL_SIZE, 0,
    EGLExt.EGL_RECORDABLE_ANDROID, 1,
    EGL14.EGL_NONE
)
// 用于接收结果的列表
val configs = arrayOfNulls<EGLConfig>(1)
// 查询结果的数量
val numConfigs = intArrayOf(1)
// 查询 EGL 属性
EGL14.eglChooseConfig(eglDisplay, configAttribList, 0, configs,
        0, configs.size, numConfigs, 0)
eglConfig = configs[0]
if (eglConfig == null) {
    eglDisplay = null
    throw RuntimeException("unable to initialize EGL14")
}
```

8.4 - EGL14.eglCreateContext >>> 创建 EGLContext

- EGL_CONTEXT_CLIENT_VERSION 用于指定与我们所使用的 OpenGL ES 版本相关的上下文类型。默认值是1(即指定 OpenGL ES 1.X 版本的上下文类型)，此处指定为 2，表示 OpenGL ES 2.x 版本。

```kotlin
val contextAttribList = intArrayOf(
    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
    EGL14.EGL_NONE
)

eglContext = EGL14.eglCreateContext(eglDisplay, eglConfig, EGL14.EGL_NO_CONTEXT,
        contextAttribList, 0)
if (eglContext == EGL14.EGL_NO_CONTEXT) {
    // 执行变量重置操作
    throw RuntimeException("Failed to create EGL context")
}
```

8.5 - EGL14.eglCreatePbufferSurface >>> 创建离屏像素缓冲区表面(off-screen pixel buffer surface)并返回其句柄。

```kotlin
val tmpSurfaceAttribs = intArrayOf(
    EGL14.EGL_WIDTH, 1, 
    EGL14.EGL_HEIGHT, 1, 
    EGL14.EGL_NONE
)
val tmpSurface = EGL14.eglCreatePbufferSurface(
    eglDisplay, 
    eglConfig, 
    tmpSurfaceAttribs, 
    /*offset*/ 0
)
```

8.6 - EGL14.eglMakeCurrent >>> 将 EGL 渲染上下文添加到离屏 surface。

```kotlin
EGL14.eglMakeCurrent(eglDisplay, tmpSurface, tmpSurface, eglContext)
```

8.7 - EGL14.eglCreateWindowSurface >>> 用于创建一个在屏幕上渲染的 EGL window surface 并返回它的句柄。

```kotlin
val surfaceAttribs = intArrayOf(EGL14.EGL_NONE)
eglWindowSurface = EGL14.eglCreateWindowSurface(
    eglDisplay, 
    eglConfig, 
    /*SurfaceHolder 的 Surface*/ surface,
    surfaceAttribs, 
    /*offset*/ 0
)
if (eglWindowSurface == EGL14.EGL_NO_SURFACE) {
    throw RuntimeException("Failed to create EGL texture view surface")
}
```

8.8 - EGL14.eglMakeCurrent >>> 将 EGL 渲染上下文添加到 window surface。

```kotlin
EGL14.eglMakeCurrent(eglDisplay, eglWindowSurface, eglWindowSurface, eglContext)
```

9 - 初始化用于相机的 OpenGL ES 配置

9.1 - 创建提供给相机的 OpenGL Texture。

- GL_TEXTURE_EXTERNAL_OES 是一个特殊的纹理目标，它是 OpenGL ES 的一个扩展，主要用于访问不直接存储在 OpenGL ES 内存中的纹理，例如视频帧或者相机预览帧等。这个 纹理目标 与常见的 GL_TEXTURE_2D 纹理目标 类似，但是它有一些特殊的限制和特性，例如它不支持 mipmap，只支持 GL_LINEAR 和 GL_NEAREST 两种纹理过滤方式，等等。
- GLES20.glTexParameteri 函数用于设置纹理参数。纹理参数用于控制纹理对象的一些属性，例如纹理过滤方式、纹理环绕方式等。
- GL_TEXTURE_MIN_FILTER 表示要设置的纹理参数。此处我们设置的是纹理对象的缩小过滤方式(minification filter)。缩小过滤方式用于控制当纹理被缩小时，如何从纹理图像中采样颜色。
- GL_TEXTURE_MAG_FILTER 纹理放大过滤方式(magnification filter)。放大过滤方式用于控制当纹理被放大时，如何从纹理图像中采样颜色。
- GL_NEAREST 表示要设置的纹理参数的值。GL_NEAREST 表示使用最近邻过滤，即从纹理图像中选择距离采样点最近的纹理像素(texel)的颜色。这种过滤方式速度较快，但是在纹理被显著缩小时，可能会导致锯齿状的边缘和不平滑的过渡。
- GL_LINEAR 线性过滤表示在纹理图像中选择距离采样点最近的四个纹理像素(texel)进行双线性插值，以获得更平滑的颜色过渡。这种过滤方式在纹理被放大时，可以得到更好的视觉效果，但是速度稍慢。
- GL_TEXTURE_WRAP_S & GL_TEXTURE_WRAP_T 表示纹理 S轴(水平轴) 和 T轴(垂直轴) 的环绕方式。
- GL_CLAMP_TO_EDGE 表示边缘延伸。边缘延伸表示当纹理坐标超出[0, 1]范围时，纹理将使用边缘的颜色进行填充。这种环绕方式可以避免纹理边缘的颜色与相邻边缘的颜色混合，从而避免出现不希望的边缘缝隙。

```kotlin
cameraTexId = createTexture()

private fun createTexture(): Int {
    // 检查 EGL 是否初始化 OK
    if (eglDisplay == null) {
        throw IllegalStateException("EGL not initialized before call to createTexture()");
    }

    // 获取存储 buffer id 的数组
    val bufferId = IntBuffer.allocate(1)
    // 生成数量为 1 的纹理对象，bufferId 的尺寸要 >= glGenTextures 函数的第一个参数
    GLES20.glGenTextures(1, bufferId)
    val texId = bufferId.get(0)
    // 将一个纹理对象 texId 绑定到 GL_TEXTURE_EXTERNAL_OES 纹理目标上，以便对这个纹理对象进行操作
    GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, texId)
    // 设置当前绑定到 GL_TEXTURE_EXTERNAL_OES 纹理目标的纹理对象的最小过滤方式为最近邻过滤
    GLES20.glTexParameteri(
        GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 
        GLES20.GL_TEXTURE_MIN_FILTER,
        GLES20.GL_NEAREST
    )
    // 绑定到 GL_TEXTURE_EXTERNAL_OES 纹理目标的纹理对象的纹理放大过滤方式为线性过滤
    GLES20.glTexParameteri(
        GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 
        GLES20.GL_TEXTURE_MAG_FILTER,
        GLES20.GL_LINEAR
    )
    // 绑定到 GL_TEXTURE_EXTERNAL_OES 纹理目标的纹理对象的S轴(水平轴)的纹理环绕方式为边缘延伸
    GLES20.glTexParameteri(
        GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 
        GLES20.GL_TEXTURE_WRAP_S,
        GLES20.GL_CLAMP_TO_EDGE
    )
    // 绑定到 GL_TEXTURE_EXTERNAL_OES 纹理目标的纹理对象的T轴(垂直轴)的纹理环绕方式为边缘延伸
    GLES20.glTexParameteri(
        GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 
        GLES20.GL_TEXTURE_WRAP_T,
        GLES20.GL_CLAMP_TO_EDGE
    )
    return texId
}
```

9.2 - 根据 textureId 创建表面纹理(SurfaceTexture)

```kotlin
cameraTexture = SurfaceTexture(cameraTexId)
```

9.3 - SurfaceTexture.setOnFrameAvailableListener >>> 设置视频帧可用时的监听

```kotlin
cameraTexture.setOnFrameAvailableListener(this)
```

9.4 - 设置输出帧的尺寸，如 1080 x 1920。

```kotlin
cameraTexture.setDefaultBufferSize(width, height)
```

9.5 - 根据 SurfaceTexture 创建 Surface。

```kotlin
cameraSurface = Surface(cameraTexture)
```

10 - 初始化用于存储渲染结果的 OpenGL ES 配置。相关讲解第 9 节的讲解。

10.1 - 创建纹理对象、SurfaceTexture、Surface

```kotlin
renderTexId = createTexture()
renderTexture = SurfaceTexture(renderTexId)
renderTexture.setDefaultBufferSize(width, height)
renderSurface = Surface(renderTexture)
```

10.2 - 创建与 renderSurface 关联的 window surface。

```kotlin
eglRenderSurface = EGL14.eglCreateWindowSurface(
    eglDisplay, 
    eglConfig, 
    renderSurface,
    surfaceAttribs, 
    0
)
if (eglRenderSurface == EGL14.EGL_NO_SURFACE) {
    throw RuntimeException("Failed to create EGL render surface")
}
```

10.3 - 检查着色器和着色器程序是否初始化 OK

```kotlin
if (passthroughShaderProgram == null) {
    createShaderResources()
}

private fun createShaderResources() {
    vertexShader = createShader(GLES20.GL_VERTEX_SHADER, TRANSFORM_VSHADER)
    passthroughFragmentShader = createShader(GLES20.GL_FRAGMENT_SHADER, PASSTHROUGH_FSHADER)
    portraitFragmentShader = createShader(GLES20.GL_FRAGMENT_SHADER, PORTRAIT_FSHADER)
    passthroughShaderProgram = createShaderProgram(passthroughFragmentShader)
    portraitShaderProgram = createShaderProgram(portraitFragmentShader)
}



```

11 - 初始化相机

