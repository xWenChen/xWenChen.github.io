---
title: "Android OpenGL 开发---EGL 的使用"
description: "本文略讲了 Android OpenGL 开发中 EGL 的使用"
keywords: "Android,OpenGL,EGL"

date: 2020-07-24 23:16:00 +08:00
lastmod: 2020-07-24 23:16:00 +08:00

categories:
  - Android
  - OpenGL
tags:
  - Android
  - OpenGL
  - EGL

url: post/7177C8F7FDD54C869B9526C47B17F62D.html
toc: true
---

本文略讲了 Android OpenGL 开发中 EGL 的使用

<!--More-->

上篇博文：[Android OpenGL 开发---概念与入门](F8881A08F40A4BBB8D2E517024E7CDAE.html)

## EGL 内容介绍

说明：Khronos 是 OpenGL, OpenGL ES, OpenVG 和 EGL 等规范的定义者。以下的代码主要是用 Android 书写，但规范是 EGL 规范。

EGL 是 Khronos 组织定义的用于管理绘图表面(窗口只是绘图表面的一种类型，还有其他的类型)的 API，EGL 提供了 OpenGL ES(以及其他 Khronos 图形 API(如 OpenVG))和不同操作系统(Android、Windows 等)之间的一个 “结合层次”。即 EGL 定义了 Khronos API 如何与底层窗口系统交流，是 Khronos 定义的规范，相当于一个框架，具体的实现由各个操作系统确定。它是在 OpenGL ES 等规范中讨论的概念，故应和这些规范的文档结合起来阅读，且其 API 的说明文档也应在 Khronos 网站上寻找。注意：IOS 提供了自己的 EGL API 实现，称为 EAGL。

通常，在 Android 中，EGL14 实现的是 EGL 1.4 规范。其相当于 Google 官方对 JAVA 的 EGL10(EGL 1.0 规范)的一次重新设计。通常，我们使用 EGL14 中的函数。而 EGL15 是 EGL 1.5 规范，其在设计时，仅仅是做了规范的补充，并未重新设计。通常 EGL14、EGL15 与 GLES20 等一起使用。GLES20 是 OpenGL ES 2.0 规范的实现。OpenGL ES 1.x 规范因为是早期版本，受限于机器性能和架构设计等，基本可以不再使用。而 OpenGL ES 2.x 规范从 Android 2.3 版本后开始支持，目前市面上的所有手机都支持。相比于 1.0，OpenGL ES 2.0 引入了可编程图形管线，具体的渲染相关使用专门的着色语言来表达。

下面，介绍一下 EGL 的使用流程。

### 1. EGL 与操作系统窗口系统通信

在 EGL 能够确定可用的绘制表面类型之前，它必须打开和窗口系统的通信渠道。因为每个窗口系统都有不同的语义，所以 EGL 提供了基本的不对操作系统透明的类型---EGLDisplay。该类型封装了所有系统相关性，用于和原生窗口系统交流。任何使用 EGL 的应用程序，第一个操作必须是创建和初始化与本地 EGL 显示的连接。以下代码展示如何创建连接：

```java
/**
 * EGL14 实现了 EGL1.4 定义的规范
 * EGL15 等主要是 EGL 新增规范的补充
 * 
 * eglGetDisplay 方法定义了如何获取本地 EGL 显示。
 *
 * EGL_DEFAULT_DISPLAY 是默认的连接。
 * EGL_NO_DISPLAY 表示连接不可用，进而说明 EGL 与 OpenGL ES 不可用
 * */
private void initEGLDisplay() {
    // 获取本地默认的显示
    EGLDisplay display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
    if(display == EGL14.EGL_NO_DISPLAY) {
        // 具体的错误查询方法下面讲述
        Log.e("NO", "Link Error");
        return;
    }
    // 做接下来的操作
}
```

### 2. 检查错误

上面的代码中，我们已经知道 EGL 会发生错误，也可以获取错误。

EGL 中的大部分函数，在成功时会返回 EGL_TRUE，否则返回 EGL_FALSE。但是，EGL 所做的不仅是告诉我们调用是否失败，它还将记录错误，指示故障原因。不过，这个错误代码并不会直接告诉我们，我们需要查询规范，才能知道每个的含义。可以调用 eglGetError() 函数获取错误，以下是错误的说明：

```java
private void getError() {
    int errorCode = EGL14.eglGetError();
    switch (errorCode) {
        case EGL14.EGL_SUCCESS:
            println("函数执行成功，无错误---没有错误");
            break;
        case EGL14.EGL_NOT_INITIALIZED:
            println("对于特定的 Display, EGL 未初始化，或者不能初始化---没有初始化");
            break;
        case EGL14.EGL_BAD_ACCESS:
            println("EGL 无法访问资源(如 Context 绑定在了其他线程)---访问失败");
            break;
        case EGL14.EGL_BAD_ALLOC:
            println("对于请求的操作，EGL 分配资源失败---分配失败");
            break;
        case EGL14.EGL_BAD_ATTRIBUTE:
            println("未知的属性，或者属性已失效---错误的属性");
            break;
        case EGL14.EGL_BAD_CONTEXT:
            println("EGLContext(上下文) 错误或无效---错误的上下文");
            break;
        case EGL14.EGL_BAD_CONFIG:
            println("EGLConfig(配置) 错误或无效---错误的配置");
            break;
        case EGL14.EGL_BAD_DISPLAY:
            println("EGLDisplay(显示) 错误或无效---错误的显示设备对象");
            break;
        case EGL14.EGL_BAD_SURFACE:
            println("未知的属性，或者属性已失效---错误的Surface对象");
            break;
        case EGL14.EGL_BAD_CURRENT_SURFACE:
            println("窗口，缓冲和像素图(三种 Surface)的调用线程的 Surface 错误或无效---当前Surface对象错误");
            break;
        case EGL14.EGL_BAD_MATCH:
            println("参数不符(如有效的 Context 申请缓冲，但缓冲不是有效的 Surface 提供)---无法匹配");
            break;
        case EGL14.EGL_BAD_PARAMETER:
            println("错误的参数");
            break;
        case EGL14.EGL_BAD_NATIVE_PIXMAP:
            println("NativePixmapType 对象未指向有效的本地像素图对象---错误的像素图");
            break;
        case EGL14.EGL_BAD_NATIVE_WINDOW:
            println("NativeWindowType 对象未指向有效的本地窗口对象---错误的本地窗口对象");
            break;
        case EGL14.EGL_CONTEXT_LOST:
            println("电源错误事件发生，Open GL重新初始化，上下文等状态重置---上下文丢失");
            break;
        default:
            break;
    }
}

private void println(String s) {
    System.out.println(s);
}
```

### 3. 初始化 EGL

成功打开连接之后，需要初始化 EGL。可以调用如下函数完成：

```c
// 标准的 EGL 定义

EGLBoolean eglInitialize(EGLDisplay display, EGLint *majorVersion, EGLint *minorVersion);

// display:      指定 EGL 的显示连接
// majorVersion: 存储指定 EGL 实现，返回的主版本号，可能为 NULL
// minorVersion: 存储指定 EGL 实现，返回的次版本号，可能为 NULL
```

在 Android 中，其具体实现如下：

```java
// 定义一个 2 维数组，用于存放获取到的版本号，主版本号放在 version[0]，次版本号放在 version[1]
int[] version = new int[2];

// 初始化 EGL, eglDisplay 的获取在上面讲述了
boolean isSuccess = EGL14.eglInitialize(eglDisplay, version, 0, version, 1);

if(!isSuccess) {
    switch (EGL14.eglGetError()) {
        case EGL14.EGL_BAD_DISPLAY:
            println("无效的 EGLDisplay 参数");
            break;
        case EGL14.EGL_NOT_INITIALIZED:
            println("EGL 不能初始化");
            break;
        default:
            println("发生错误：" + EGL14.eglGetError());
            break;
    }
    return;
}
// 初始化成功，往下走
// ......
```

这个函数初始化 EGL 内部数据结构，返回 EGL 实现的主版本号和次版本号。如果 EGL 无法初始化，函数会返回 EGL_FALSE，并将 EGL 错误代码设置为：

- EGL_BAD_DISPLAY     --- 如果 display 不是有效的 EGLDisplay
- EGL_NOT_INITIALIZED --- 如果 EGL 不能初始化

### 4. 确定可用表面配置

一旦初始化了 EGL，就可以确定可用渲染表面的类型和配置，这有两种方法：

- 查询每个表面配置，找出最好的选择
- 指定一组需求，让 EGL 推荐最佳匹配

在许多情况下，使用第二种方法更简单，而且最有可能得到用第一种方法找到的匹配。

在任何一种情况下，EGL 都将返回一个 EGLConfig，这是包含有关特定表面及其特征(如每个颜色分量的位数、与 EGLConfig 相关的深度缓冲区(如果有的话))的 EGL 内部数据结构的标识符。可以用 eglGetConfigAttrib 函数查询 EGLConfig 的任何属性。后面会讲。

调用以下函数，可以查询系统支持的所有 EGL 表面配置：

```java
boolean eglGetConfigs(EGLDisplay display, EGLConfig[] configs, int configsOffset, int config_size, int[] num_config, int num_configOffset);
// display:          EGL 连接的显示
// configs:          指定的 configs 列表(第 2 个参数)
// configsOffset:    列表取值的起始偏移值
// config_size:      指定的 configs 列表的尺寸
// num_config:       存放获取到的配置数量。一般来说，此列表仅存放大小，列表长度设置为 1 即可(第 5 个参数)
// num_configOffset: 存值时的起始偏移值(第 6 个参数)
```

函数在调用成功时，会返回 EGL_TRUE。失败时，会返回 EGL_FALSE，并将 EGL 错误代码设置为：

- EGL_NOT_INITIALIZED --- 如果 display 不能初始化
- EGL_BAD_PARAMETER   --- 如果 num_config(用于存放 返回结果的大小 的列表(上述说明中的第 5 个参数))为空

调用 eglGetConfigs 有两种方法。

1. 如果指定的入参 configs 为 NULL，则将返回 EGL_TRUE，并将返回可用的 EGLConfig 的数量。在足够谨慎的情况下，当没有返回任何 EGLConfig 的信息，但是知道了可用配置的数量时，我们可以分配足够的内存，来获得完成的 EGLConfig 集合
2. 在更普遍的情况下，我们一般会分配一个未初始化的 EGLConfig 值的数组((上述说明中的第 2 个参数))，并作为参数传递给 eglGetConfigs 函数。函数调用完成时，会获取到配置列表((上述说明中的第 2 个参数，此参数被修改过，存放了结果))，并根据上述说明中的第 5 和第 6 个参数来确定列表中可用的配置数量和位置(即根据 5、6 确定结果在 2 中的位置)。当然，获取到的配置结果的大小不会超过传入的未初始化的 EGLConfig 值的数组的大小。

### 5. 查询 EGLConfig 属性

此处，说明一下与 EGLConfig 相关的 EGL 值，并说明如果检索这些值。

EGLConfig 包含关于 EGL 启用的表面的所有信息。其包括关于可用颜色、与配置相关的其他缓冲区(深度和模板缓冲区)、表面类型等等。可以用下面的函数查询与 EGLConfig 相关的特定属性：

```java
boolean eglGetConfigAttrib(EGLDisplay display, EGLConfig config, int attribute, int[] value, int offset);

// display:   EGL 的显示连接
// config:    待查询的配置
// attribute: 指定返回的特定属性
// value:     指定的返回值
// offset:    结果放入数组时的偏移值，一般为 0
```

上述函数在调用成功时返回 EGL_TRUE，失败时返回 EGL_FALSE，并将 EGL 错误代码设置为：

- EGL_BAD_DISPLAY：     显示无效
- EGL_NOT_INITIALIZED:  显示未初始化
- EGL_BAD_CONFIG：      配置无效
- EGL_BAD_ATTRIBUTE：   属性无效

下面是在 eglGetConfigAttrib 函数中所有的可用的 EGLConfig 属性列表：

|           属性名            |                             描述                             |                             默认值                             |
| :-------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|       EGL_ALPHA_SIZE        |                 颜色缓冲区中的 Alpha 值位数                  |                 0                  |
|     EGL_ALPHA_MASK_SIZE     |                掩码缓冲区中的 Alpha 掩码位数0，掩码缓冲区只被 OpenVG 使用                |             0            |
|   EGL_BIND_TO_TEXTURE_RGB   | 如果可以绑定到 RGB 纹理，则返回 EGL_TRUE，否则返回 EGL_FALSE |             EGL_DONT_CARE            |
|  EGL_BIND_TO_TEXTURE_RGBA   | 如果可以绑定到 RGBA 纹理，则返回 EGL_TRUE，否则返回 EGL_FALSE |             EGL_DONT_CARE            |
|        EGL_BLUE_SIZE        |                  颜色缓冲区中蓝色分量的位数                  |             0            |
|       EGL_BUFFER_SIZE       | 颜色缓冲区中所有颜色分量的位数，其值是 EGL_RED_SIZE, EGL_GREEN_SIZE, EGL_BLUE_SIZE, 和 EGL_ALPHA_SIZE 的位数之和 |    0   |
|    EGL_COLOR_BUFFER_TYPE    |   颜色缓冲区类型：EGL_RGB_BUFFER 或者 EGL_LUMINANCE_BUFFER   |             EGL_RGB_BUFFER            |
|      EGL_CONFIG_CAVEAT      | 和配置相关的任何注意事项，可取的值为：EGL_NONE, EGL_SLOW_CONFIG, 和 EGL_NON_CONFORMANT |             EGL_DONT_CARE            |
|        EGL_CONFIG_ID        |                  EGLConfig的唯一标识符的值                   |             EGL_DONT_CARE            |
|       EGL_CONFORMANT        |          如果用此配置创建的上下文是有效的，则返回真          |             ---            |
|       EGL_DEPTH_SIZE        |                        深度缓冲区位数                        |             0            |
|       EGL_GREEN_SIZE        |                  颜色缓冲区中绿色分量的位数                  |             0            |
|          EGL_LEVEL          |                        帧缓冲区的级别                        |             0            |
|     EGL_LUMINANCE_SIZE      |                    颜色缓冲区中的亮度位数                    |             0            |
|    EGL_MAX_PBUFFER_WIDTH    |        像素缓冲区表面(pixel buffer surface)的最大宽度        |             ---            |
|   EGL_MAX_PBUFFER_HEIGHT    |        像素缓冲区表面(pixel buffer surface)的最大高度        |             ---            |
|   EGL_MAX_PBUFFER_PIXELS    |        像素缓冲区表面(pixel buffer surface)的最大尺寸        |             ---            |
|    EGL_MAX_SWAP_INTERVAL    |        最大缓冲区交换间隔(参见 eglSwapInterval 函数)         |             EGL_DONT_CARE            |
|    EGL_MIN_SWAP_INTERVAL    |        最小缓冲区交换间隔(参见 eglSwapInterval 函数)         |             EGL_DONT_CARE            |
|    EGL_NATIVE_RENDERABLE    |   如果原生渲染 API 可以渲染此 EGLConfig 创建的表面，则为真   |             EGL_DONT_CARE            |
|    EGL_NATIVE_VISUAL_ID     |                 原生窗口系统的可视 ID 的句柄                 |             EGL_DONT_CARE            |
|   EGL_NATIVE_VISUAL_TYPE    |                    原生窗口系统的可视类型                    |             EGL_DONT_CARE            |
|        EGL_RED_SIZE         |                  颜色缓冲区中红色分量的位数                  |             0            |
|     EGL_RENDERABLE_TYPE     | 位掩码，代表 EGL 支持的渲染类型的接口。由 EGL_OPENGL_ES_BIT、EGL_OPENGL_ES2_BIT、EGL_OPENGL_ES3 _BIT_KHR(需要 EGL_KHR_create_context 扩展)、EGL_OPENGL_BIT 或 EGL_OPENVG_BIT 组成 |             EGL_OPENGL_ES_BIT            |
|     EGL_SAMPLE_BUFFERS      |                  可用的多重采用缓冲区的数量                  |             0            |
|         EGL_SAMPLES         |                      每个像素的样本数量                      |             0            |
|      EGL_STENCIL_SIZE       |                        模板缓冲区位数                        |             0            |
|      EGL_SURFACE_TYPE       | 支持的 EGL 表面类型。可能是：EGL_WINDOW_BIT、EGL_PIXMAP_BIT、EGL_PBUFFER_BIT、EGL_MULTISAMPLE_RESOLVE_BOX_BIT、EGL_SWAP_BEHAVIOR_PRESERVED_BIT、EGL_VG_COLORSPACE_LINEAR_BIT 或 EGL_VG_ALPHA_FORMAT_PRE_BIT |             EGL_WINDOW_BIT            |
|    EGL_TRANSPARENT_TYPE     |     支持的透明度类型：EGL_NONE 或者 EGL_TRANSPARENT_RGB      |             EGL_NONE            |
|  EGL_TRANSPARENT_RED_VALUE  |                         透明的红色值                         |             EGL_DONT_CARE            |
| EGL_TRANSPARENT_GREEN_VALUE |                         透明的绿色值                         |             EGL_DONT_CARE            |
| EGL_TRANSPARENT_BLUE_VALUE  |                         透明的蓝色值                         |             EGL_DONT_CARE            |
| EGL_MATCH_NATIVE_PIXMAP     |      匹配本地的像素图，该属性只能通过 eglChooseConfig 获取到，无法通过 eglGetConfigAttrib 获取到    |              EGL_NONE            |

### 6. 选择 EGLCONFIG 属性

如果我们不关心所有的属性，那么可以使用 eglChooseConfig 函数，此函数可以指定我们关心的重要的属性，并返回最佳匹配结果：

```java
boolean eglChooseConfig(EGLDisplay display, int[] attrib_list, int attrib_listOffset, EGLConfig[] configs, int configsOffset, int config_size, int[] num_config, int num_configOffset);

// display:            连接的 EGL 显示
// attrib_list:        指定待查询的 EGLConfig 匹配的属性列表
// attrib_listOffset:  属性列表的取值位移
// configs:            EGLConfig 的配置列表
// configsOffset:      配置的取值偏移
// config_size:        配置列表的尺寸
// num_config:         指定返回的配置大小，数组长度一般设置为 1 即可
// num_configOffset:   取值偏移0
```

函数调用成功时，返回 EGL_TRUE，否则返回 EGL_FALSE，并将错误码置为以下的值：

- EGL_BAD_DISPLAY 显示无效
- EGL_BAD_ATTRIBUTE 属性错误或无效
- EGL_NOT_INITIALIZED 显示(EGLDisplay)未初始化
- EGL_BAD_PARAMETER num_config 为空

我们在设置属性列表时，需要设置相关属性的默认值。如果不设置，则会使用上述表格中的默认值。例如，我们需要获取支持 5 位红色和蓝色分量、6 位绿色分量(常用的 RGB565 格式)的渲染表面、一个深度缓冲区和 OpenGL 3.0 的 EGLConfig，则可以指定以下的数组：

```java
int[] attrs = new int[] {
    // 属性名                     默认值
    EGL14.EGL_RENDERABLE_TYPE, EGLExt.EGL_OPENGL_ES3_BIT_KHR,
    EGL14.EGL_RED_SIZE, 5,
    EGL14.EGL_GREEN_SIZE, 6,
    EGL14.EGL_BLUE_SIZE, 5,
    EGL14.EGL_DEPTH_SIZE, 1,
    // 属性定义结束
    EGL14.EGL_NONE
};

// 注：使用 EGL_OPENGL_ES3_BIT_KHR 需要使用 EGL_KHR_create_context 扩展。该属性在 eglext.h (EGL v1.4) 中定义
```

下面是一个查询的代码示范：

```java
// 存储返回的配置数量
int []numConfigs = new int[1];
EGLConfig[]configs = new EGLConfig[1];
if (!EGL14.eglChooseConfig(eglDisplay, attrs, 0, configs, 0, configs.length, numConfigs, 0)) {
    // 获取属性出错
    return;
}
// 获取属性成功
```

如果 eglChooseConfig 匹配成功，则将返回一组匹配相应属性列表的标准的 EGLConfig。如果 EGLConfig 的数量超过一个(最多是我们指定的最大配置数量)，则将按如下顺序排列：

1. 按照 EGL_CONFIG_CAVEAT 的值。如果没有配置注意事项(EGL_CONFIG_CAVEAT 的值为 EGL_NONE)的配置优先，然后是慢速渲染配置(EGL_SLOW_CONFIG)，最后是不兼容的配置(EGL_NON_CONFORMANT_CONFIG)
2. 按照 EGL_COLOR_BUFFER_TYPE 指定的缓冲区类型
3. 按照颜色缓冲区位数降序排列。缓冲区的位数取决于 EGL_COLOR_BUFFER_TYPE，至少是为特定颜色通道指定的值。当缓冲区类型为 EGL_RGB_BUFFER 时，位数是 EGL_RED_SIZE、EGL_GREEN_SIZE、EGL_BLUE_SIZE的和。当颜色缓冲区类型为 EGL_LUMINANCE_BUFFER 时，位数是 EGL_LUMINANCE_SIZE 与 EGL_ALPHA_SIZE 的和。
4. 按照 EGL_BUFFER_SIZE 值的升序排列
5. 按照 EGL_SAMPLE_BUFFERS 值的升序排列
6. 按照 EGL_SAMPLES 数量的升序排列
7. 按照 EGL_DEPTH_SIZE 值的升序排列
8. 按照 EGL_STENCIL_SIZE 值的升序排列
9. 按照 EGL_ALPHA_MASK_SIZE 的值排序(这仅适用于 OpenVG)
10. 按照 EGL_NATIVE_VISUAL_TYPE，以实现相关的方式排序
11. 按照 EGL_CONFIG_ID 值的升序排列

上述列表中未提及到的参数不用于排列过程

同时，需要注意以下事项：

- 因为第 3 条排序规则的存在，为了匹配最佳的属性格式，必须添加额外的逻辑检查。如：我们要求的是 RGB565，但是 RGB888 会先出现在返回结果中。
- 如果指定属性列表时，没有设置对应的默认值，则默认的渲染表面是屏幕上的窗口(EGL_SURFACE_TYPE 属性对应的值)。

### 7. 创建屏幕上的渲染区域：EGL 窗口

一旦我们有了符合渲染需求的 EGLConfig，就为创建窗口做好了准备。可以调用以下函数来创建窗口：

```java
EGLSurface eglCreateWindowSurface(EGLDisplay display, EGLConfig config, Object window, int[] attrib_list, int offset);

// display      指定 EGL 的显示连接
// config       指定的配置
// window       指定原生窗口，在 Android 中，可传入 SurfaceHolder 对象
// attrib_list  指定窗口属性列表，可能为 NULL
// offset       属性列表的取值偏移
```

上面的属性列表可以取以下值，因为 EGL 还可以支持其他 API(如 Open VG)，故创建时，有些属性不适用。下面是 OpenGL ES 支持的属性：

|           属性名            |                             描述                             |                             默认值                             |
| :-------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|       EGL_RENDER_BUFFER        |    指定渲染用的缓冲区(EGL_SINGLE_BUFFER，或者后台缓冲区 EGL_BACK_BUFFER)     |   EGL_BACK_BUFFER   |
|       EGL_GL_COLORSPACE        |    指定 Open GL 和 Open GL ES 渲染表面时，用到的颜色空间，此属性在 EGL1.5 中被定义    |    EGL_GL_COLORSPACE_SRGB   |

说明，对于 OpenGL ES 3.0，只支持双缓冲区窗口。

当属性列表 attrib_list 为空，或者 EGL_NONE 作为属性第一个元素时，所有的属性值都将使用默认值。当调用失败时，函数会返回 EGL_NO_SURFACE，并设置以下错误：

- EGL_BAD_DISPLAY       显示错误
- EGL_NOT_INITIALIZED   显示未初始化
- EGL_BAD_CONFIG        配置错误，配置未得到系统支持
- EGL_BAD_NATIVE_WINDOW 本地原生窗口错误
- EGL_BAD_ATTRIBUTE     属性错误
- EGL_BAD_ALLOC         分配错误，如无法分配窗口资源，或者已有 EGLSurface 与本地原生窗口关联时
- EGL_BAD_MATCH         匹配错误 EGLConfig 不匹配原生窗口系统。或者 EGLConfig 不支持渲染到窗口(EGL_SURFACE_TYPE 属性没有设置 EGL_WINDOW_BIT)

下面是一个创建 EGL 窗口的代码，参照了 GLSurfaceView：

```java
EGLSurface surface = EGL14.eglCreateWindowSurface(display, config, view.getHolder(), null, 0);
if(surface == null) {
    Log.e("Test", "窗口为空");
    return;
}
if(surface == EGL14.EGL_NO_SURFACE) {
    int error = EGL14.eglGetError();
    // 处理错误
    return;
}
// 函数执行成功，往下走
```

下面，介绍另外一种 EGL 渲染区域：EGL Pbuffer。

### 8. 创建屏幕外渲染区域：EGL Pbuffer

除了可以用 OpenGL ES 在屏幕上的窗口渲染之外，还可以渲染被称为 Pbuffer(像素缓冲区 Pixel buffer 的简写) 的不可见屏幕外表面。和窗口一样，Pbuffer 可以利用 OpenGL ES 中的任何硬件加速。Pbuffer 常用于生成纹理贴图。当然，如果想要的是渲染到一个纹理，建议使用帧缓冲区对象代替 Pbuffer，因为帧缓冲区更高效。不过，在某些帧缓冲区无法使用的情况下，Pbuffer 仍然有效，比如用 OpenGL ES 在屏幕外表面渲染，然后将其作为其他 API(如 OpenVG)中的纹理。

和窗口一样，Pbuffer 支持 OpenGL ES 的所有渲染机制。主要的区别是：

- 窗口：渲染的内容可以在屏幕上显示，渲染完成时，需要交换缓冲区
- Pbuffer：渲染的内容无法在屏幕上显示，渲染完成时，无需交换缓冲区。而是从 Pbuffer 中将数值直接复制到应用程序，或者是将 Pbuffer 的绑定更改为纹理，则 Pbuffer 的渲染对目标纹理生效

创建 Pbuffer 和创建 EGL 窗口非常类似。为了创建 Pbuffer，需要和窗口一样找到 EGLConfig，并作一处修改；我们需要扩增 EGL_SURFACE_TYPE 的值，使其包含 EGL_PBUFFER_BIT。拥有适用的 EGLConfig 之后，就可以用如下函数创建 Pbuffer:

```java
EGLSurface eglCreatePbufferSurface(EGLDisplay display, EGLConfig config, int[] attrib_list, int offset);

// display       指定的 EGL 显示
// config        指定的配置
// attrib_list   指定像素缓冲区的属性列表，可能为 NULL
// offset        属性数组取值的偏移值
```

在 OpenGL ES 中，下面是可用的属性列表：

|           属性名            |                             描述                             |                             默认值                             |
| :-------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|       EGL_WIDTH        |    指定 Pbuffer 的宽度(以像素表示)     |   0   |
|       EGL_HEIGHT        |    指定 Pbuffer 的高度(以像素表示)    |   0   |
|       EGL_LARGEST_PBUFFER        |    如果请求的大小不可用，则选择最大的可用 Pbuffer，有效值为 EGL_TRUE 和 EGL_FALSE     |   EGL_FALSE   |
|       EGL_TEXTURE_FORMAT        |    如果 Pbuffer 指定到一个纹理贴图，则指定纹理格式类型，有效值是 EGL_NO_TEXTURE, EGL_TEXTURE_RGB, 和 EGL_TEXTURE_RGBA    |    EGL_NO_TEXTURE(表示 Pbuffer 不能直接指定到纹理)   |
|       EGL_TEXTURE_TARGET        |    指定 Pbuffer 作为纹理贴图时，应该连接到的相关纹理目标，有效值是 EGL_NO_TEXTURE, 和 EGL_TEXTURE_2D     |   EGL_NO_TEXTURE   |
|       EGL_MIPMAP_TEXTURE        |    指定 是否应该为 纹理mipmap 分配存储，有效值是 EGL_TRUE 和 EGL_FALSE    |   EGL_FALSE   |
|       EGL_GL_COLORSPACE        |    指定 Open GL 和 Open GL ES 渲染表面时，用到的颜色空间，此属性在 EGL1.5 中被定义    |    EGL_GL_COLORSPACE_SRGB   |

和窗口创建一样，函数调用失败时，会返回 EGL_NO_SURFACE，并设置以下错误码：

- EGL_BAD_DISPLAY  EGL 显示连接错误
- EGL_NOT_INITIALIZED  EGL 显示未初始化
- EGL_BAD_CONFIG   配置无效
- EGL_BAD_ATTRIBUTE  如果指定了 EGL_MIPMAP_TEXTURE, EGL_TEXTURE_FORMAT, 或者 EGL_TEXTURE_TARGET，但是提供的 EGLConfig 不支持 OpenGL ES 渲染(如只支持 OpenVG 渲染)，则发生该错误
- EGL_BAD_ALLOC EGL Pbuffer 因为缺少资源而无法分配时，发生该错误
- EGL_BAD_PARAMETER  如果属性指定的 EGL_WIDTH 或 EGL_HEIGHT 是负值，则发生该错误
- EGL_BAD_MATCH  如果出现以下情况，则出现该错误：
   1. 提供的 EGLConfig 不支持 Pbuffer 表面
   2. Pbuffer 被用作纹理贴图(EGL_TEXTURE_FORMAT 不是 EGL_NO_TEXTURE)，且指定的 EGL_WIDTH 和 EGL_HEIGHT 时无效的纹理尺寸
   3. EGL_TEXTURE_FORMAT 和 EGL_TEXTURE_TARGET 设置为 EGL_NO_TEXTURE，而其他属性没有设置成 EGL_NO_TEXTURE

### 9. 创建一个渲染上下文

渲染上下文是 OpenGL ES 的内部数据结构，包含操作所需的所有状态信息。在 OpenGL ES 中，必须要有个上下文才能绘图。可以用如下函数创建上下文：

```java
EGLContext eglCreateContext(EGLDisplay display, EGLConfig config, EGLContext share_context, int[] attrib_list, int offset);

// display       指定的 EGL 显示
// config        指定的配置
// share_context 允许多个 EGL 上下文共享特定类型的数据，比如着色器程序和纹理贴图，使用 EGL_NO_CONTEXT 表示没有共享
// attrib_list   指定上下文使用的属性列表，只有一个可接受的属性： EGL_CONTEXT_CLIENT_VERSION。该属性用于指定与我们所使用的 OpenGL ES 版本相关的上下文类型。默认值是1(即指定 OpenGL ES 1.X 版本的上下文类型)
// offset        属性列表的取值偏移
```

函数执行成功时，会返回一个指向新创建上下文的句柄。如果失败，则会返回 EGL_NO_CONTEXT，并设置如以下错误码(不全，官方文档未说明。以实际返回为准)：

- EGL_BAD_CONFIG   配置无效

下面是创建上下文的一段示范代码：

```java
int []contextAttribs = {
    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, // EGL14 一般与 GLES20 结合使用
    EGL14.EGL_NONE
};
eglContext = EGL14.eglCreateContext(eglDisplay, eglConfig, EGL14.EGL_NO_CONTEXT, contextAttribs,0);
if(eglContext== EGL14.EGL_NO_CONTEXT) {
    throw new RuntimeException("EGL error "+EGL14.eglGetError());
}
```

### 10. 指定某个 EGLContext 为当前上下文

终于，我们来到了最后一步，完成这一步后，我们就能开始渲染了。

因为一个应用程序可能创建多个 EGLContext 用于不同的用途，所以我们需要关联特定的 EGLContext 和渲染表面。这一步骤通常叫做 "指定当前上下文"。使用下列函数，关联特定的 EGLContext 和 EGLSurface：

```java
boolean eglMakeCurrent(EGLDisplay display, EGLSurface draw, EGLSurface read, EGLContext context);

// display       指定的 EGL 显示
// draw          指定的 EGL 绘图表面
// read          指定的 EGL 读取表面
// context       指定连接到该表面的渲染上下文
```

函数执行成功时，会返回 EGL_TRUE，否则返回 EGL_FALSE，并设置以下错误码：

- EGL_BAD_MATCH     draw 或 read 与 context 上下文不兼容
- EGL_BAD_ACCESS    发生以下情况时，会产生该错误
   1. 当前未指定上下文
   2. 上下文的版本与客户端(手机实体)支持的版本不兼容
   3. 或者 draw 或 read 未绑定到当前上下文
   4. draw 或者 read 是由 eglCreatePbufferFromClientBuffer 函数创建的 Pbuffer，但是创建他们的底层客户端缓冲区正在被创建他们的客户端 API 使用 
- EGL_BAD_CONTEXT    上下文无效，并且上下文不是 EGL_NO_CONTEXT
- EGL_BAD_SURFACE    draw 或者 read 无效，并且不是 EGL_NO_SURFACE
- EGL_BAD_MATCH    出现以下情况时，会产生该错误：
   1. 上下文是 EGL_NO_CONTEXT，但是 draw 或者 read 不是 EGL_NO_SURFACE
   2. draw 或者 read 的其中一个有效，另一个是 EGL_NO_SURFACE
   3. 上下文不支持在没有 draw 或者 read 的情况下绑定，而 draw 和 read 都是 EGL_NO_SURFACE
   4. 如果 draw 和 read 的渲染内容无法同时放入图形内存
- EGL_BAD_NATIVE_WINDOW    作为 draw 或者 read 的本机窗口不再有效
- EGL_BAD_CURRENT_SURFACE    如果之前调用线程的上下文未清除命令，并且之前的表面不再有效
- EGL_BAD_ALLOC    用于 draw 和 read 的辅助缓冲区无法分配
- EGL_CONTEXT_LOST    发生意外的电源事件
- EGL_NOT_INITIALIZED    如果指定的显示(EGLDisplay)有效但未初始化，并且存在以下的情形之一：
   1. context 不是 EGL_NO_CONTEXT
   2. draw 或者 read 不是 EGL_NO_SURFACE
- EGL_BAD_DISPLAY    EGL 指定的显示无效。部分 EGL 实现允许 EGL_NO_DISPLAY 作为 eglMakeCurrent 函数的有效显示参数。但这并不是 EGL 的标准定义，应被视为特定厂商的扩展。

我们注意到函数需要两个 EGLSurface 表面。尽管这种方法具有灵活性(在 EGL 的高级用法中将被利用到)，但是通常我们把 draw 和 read 设置为同一个值---我们前面创建的渲染表面(窗口或者 Pbuffer)。注意，因为 EGL 规范要求 eglMakeCurrent 实现进行一次刷新，所以这一调用对于基于图块的架构代价很高。

讲述完用 EGL 渲染前的所有准备后，我们正式整合所有步骤，输出一个完整的代码示范。

### 11. 同步渲染

此部分是扩展内容，不是必须的步骤。不想看的可以跳过，看下面的代码示范。

有时我们会碰到，协调多个图形 API 在单个窗口中渲染的情况。在这种情况下，需要让应用程序允许多个库渲染到共享窗口。EGL 提供了几个函数来处理这种同步任务。
- 1. 只用 OpenGL ES，可以调用 glFinish 函数来保证所有渲染已经发生。或者是更高级的同步对象和栅栏。
- 2. 不止一种 Khronos API。在切换窗口系统原生渲染 API 之前，可能不知道使用的是哪个 API。为此可以调用 eglWaitClient 函数延迟客户端的执行，直到某个 Khronos API 的所有渲染完成，再切换 API。该函数执行成功时，会返回 EGL_TRUE，失败时返回 EGL_FALSE，并设置错误码为 EGL_BAD_CURRENT_SURFACE。
- 3. 同样在不止一种 Khronos API 的情况，如果想要保证原生窗口系统的渲染完成，则可以调用 eglWaitNative(EGLInt engine)。参数可设置为 EGL_CORE_NATIVE_ENGINE，代表支持的最常见引擎，其他实现视为 EGL 扩展。函数执行成功，返回 EGL_TRUE，否则返回 EGL_FALSE，并设置错误码为 EGL_BAD_PARAMETER。

## 步骤整合与代码示范

下面是一段示范，可能无法运行，但是说明了 EGL 执行与初始化的流程。

```java
/**
  * 初始化 EGL，初始化成功，返回 true，否则返回 false
  * */
@RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
private boolean initWindow() {
    // 1. 获取 EAL 显示
    EGLDisplay eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
    if(eglDisplay == EGL14.EGL_NO_DISPLAY) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    // 2. 初始化 EGL
    int[] version = new int[2];
    if(!EGL14.eglInitialize(eglDisplay, version, 0, version, 1)) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    // 3. 确定配置
    int[] configAttribs = new int[] {
        EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_WINDOW_BIT,
        EGL14.EGL_RED_SIZE, 8,
        EGL14.EGL_GREEN_SIZE, 8,
        EGL14.EGL_BLUE_SIZE, 8,
        EGL14.EGL_DEPTH_SIZE, 24,
        EGL14.EGL_NONE
    };
    EGLConfig[] configs = new EGLConfig[1];
    int[] numConfigs = new int[1];
    if(!EGL14.eglChooseConfig(eglDisplay, configAttribs, 0, configs, 0,
                              configs.length, numConfigs, 0)) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    if(configs[0] == null) {
        return false;
    }
    // 4. 创建渲染表面，此处是创建窗口
    EGLSurface window = EGL14.eglCreateWindowSurface(eglDisplay,
                                                     configs[0], glSurfaceView.getHolder(), null, 0);
    if(window == EGL14.EGL_NO_SURFACE) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    // 5. 创建上下文
    int[] contextAttribs = new int[] {
        EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL14.EGL_NONE
    };
    EGLContext eglContext = EGL14.eglCreateContext(eglDisplay, configs[0],
                                                   EGL14.EGL_NO_CONTEXT, contextAttribs, 0);
    if(eglContext == EGL14.EGL_NO_CONTEXT) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    // 6. 绑定上下文与表面
    if(!EGL14.eglMakeCurrent(eglDisplay, window, window, eglContext)) {
        Log.e("initWindow", EGL14.eglGetError() + "");
        return false;
    }
    Log.d("initWindow", "初始化成功");
    return true;
}
```

## 小结

从上述的说明中，我们可以得到下面的关于 EGL 的使用的流程图：

![EGL使用流程图](/imgs/EGL使用流程图.png)

以上便是关于 EGL 的使用的一些基本介绍。
