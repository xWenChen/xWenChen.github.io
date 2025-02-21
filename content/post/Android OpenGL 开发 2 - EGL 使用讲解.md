---
title: "Android OpenGL 开发 2 - EGL 使用讲解"
description: "本文略讲了 EGL 的知识"
keywords: "Android,OpenGL,EGL"

date: 2023-07-01T16:19:00+08:00

categories:
  - Android
  - OpenGL
tags:
  - Android
  - OpenGL
  - EGL

url: post/5AAAADBA29DD4CCCBC3FBAB9ACE20FAD.html
toc: true
---

本文略讲了 EGL 的知识。

<!--More-->

## EGL 内容介绍

说明：Khronos 是 OpenGL, OpenGL ES, OpenVG 和 EGL 等规范的定义者。以下的代码主要是用 Android 书写，但规范是 EGL 规范。

EGL 是 Khronos 组织定义的用于管理绘图表面(窗口只是绘图表面的一种类型，还有其他的类型)的 API，EGL 提供了 OpenGL ES(以及其他 Khronos 图形 API(如 OpenVG))和不同操作系统(Android、Windows 等)之间的一个 “结合层次”。即 EGL 定义了 Khronos API 如何与底层窗口系统交流，是 Khronos 定义的规范，相当于一个框架，具体的实现由各个操作系统确定。它是在 OpenGL ES 等规范中讨论的概念，故应和这些规范的文档结合起来阅读，且其 API 的说明文档也应在 Khronos 网站上寻找。注意：IOS 提供了自己的 EGL API 实现，称为 EAGL。

通常，在 Android 中，EGL14 实现的是 EGL 1.4 规范。其相当于 Google 官方对 JAVA 的 EGL10(EGL 1.0 规范)的一次重新设计。通常，我们使用 EGL14 中的函数。而 EGL15 是 EGL 1.5 规范，其在设计时，仅仅是做了规范的补充，并未重新设计。通常 EGL14、EGL15 与 GLES20 等一起使用。GLES20 是 OpenGL ES 2.0 规范的实现。OpenGL ES 1.x 规范因为是早期版本，受限于机器性能和架构设计等，基本可以不再使用。而 OpenGL ES 2.x 规范从 Android 2.3 版本后开始支持，目前市面上的所有手机都支持。相比于 1.0，OpenGL ES 2.0 引入了可编程图形管线，具体的渲染相关使用专门的着色语言来表达。

## EGL 术语解释

- Command：意为命令，也可叫 Function(函数、方法)。表示的是 EGL 定义的函数，是我们调用 EGL 能力的基本单元。如 eglCreateContext、eglCreateSurface 等。EGL 命令、EGL 函数和 EGL 方法指的都是同一个东西。
- Address Space：可翻译为地址空间。Address Space 是单个命名空间(name space)可以访问的对象集合(object set)或者内存位置(memory location set)集合。换句话说，它是一个或多个线程通过指针共享的数据区域。
- Platform：Platform 以前也叫 native window systems，包括 X11 和 Microsoft Windows 等窗口系统；而 EGL 1.5 也支持无显示器渲染（例如 GBM）和多个运行时平台。
- Client：Client 表示一个应用程序(app)，其通过连接(connection)(另称通信路径(communication path))与底层 EGL 实现和底层平台(platform)通信。app 称为平台服务(platform server)的 Client。对于服务来说，客户端就是连接本身。如果一个 app 与服务之间存在着多个连接，则每个连接都被视为一个客户端。相关资源的生命周期由连接的生命周期控制，而不是 app 生命周期控制。
- Client API：翻译为客户端 API，如果把 EGL 比作连接，则使用 EGL 与底层通信的 API 则被成为 Client API。目前 EGL 支持的 Client API 包括 OpenGL、OpenGL ES 和 OpenVG。EGL 定义了上下文创建/管理、渲染语义以及 Client API 之间的交互。同时 EGL 也支持 non-client(native) 渲染 API 渲染到 EGL surface(可能功能会受限)，当然这种支持的语义更加依赖于 EGL 实现。
- Compatible：Compatible 表示的是兼容性。其指的是 OpenGL 和 OpenGL ES 的 context 和 surface 之间的兼容性。如果 OpenGL 或 OpenGL ES 的渲染上下文(context)满足指定的约束，则它们与 surface 兼容，可用于渲染到表面 surface。
- Connection：Connection 表示连接。Connection 指的是 Client 和 platform server 之间的携带 EGL 和其他某种协议的双向字节流。Client 通常只有一个到 server 的连接。
- Context：Context 也可叫 Rendering Context，意为上下文或者渲染上下文。Context 指的是 OpenGL 或 OpenGL ES 的渲染上下文，其一个虚拟机和状态机。所有 OpenGL 和 OpenGL ES 的渲染都要根据上下文完成。一个上下文维护的状态不受另一个上下文的影响，除非在创建上下文时显式指定了可以共享状态(例如纹理)。
- Current Context：意为当前上下文。在调用 EGL 命令之前，我们可以为每个线程的 EGL 命令流设置一个隐式上下文，这样后续要用到 Context 的命令就不用再单独传入一个 Context 参数了。Current Context 是 Client API 使用的隐式上下文。
- EGLContext：EGLContext 是 EGL 规范中代表渲染上下文。EGLContext 是个状态机，OpenGL 和 OpenGL ES 的渲染上下文由客户端状态和服务器端状态组成(client side state and server side stat)。OpenVG 的渲染上下文不区分客户端状态和服务器端状态。
- EGLImage：由 Client API 创建的，在 EGL 层包装的共享资源。可能是图像数据的 2D 数组。
- EGLImage Source：最初在 CLient API 中创建的对象或子对象(例如 OpenGL 或 OpenGL ES 中的 texture mipmap，或 OpenVG 中的 VGImage)，在调用 eglCreateImage 时作为参数。
- EGLImage Target：CLient API 根据 EGLIImage 创建的对象(例如 OpenGL 或 OpenGL ES 中的 texture mipmap，或 OpenVG 中的 VGImage)，一个 EGLImage 可以创建多个 EGLImage Target。
- EGLImage Sibling：与同一 EGLImage 关联的 EGLImage Source 和 EGLImage Targe 统称为 EGLImage Sibling。
    ![EGLImage_Sibling](/imgs/EGLImage_Sibling.webp)
- Orphaning：Orphaning 指的是重新指定或删除 EGLImage sibling 的过程，该过程不会导致与 EGLImage 关联的内存被重新分配，也不会影响使用 EGLImage siblings 的其他渲染结果。
- Referencing：Referencing 指的是从 EGLImage 创建 EGLImage target 的过程。
- Respecification：Respecification 指的是 EGLImage sibling 的尺寸、格式或其他属性因为 Client API 的命令调用(例如 gl*TexImage*)而改变。Respecification 通常会触发 EGLImage sibling 的 Orphaning 动作。注意更改 EGLImage sibling 的像素数据(例如通过渲染或调用 gl*TexSubImage* 命令)并不会触发 Respecification。
- Surface：Surface 可翻译为表面，也称 Drawing Surface(绘图表面)。指的 onscreen 或者 offscreen buffer，其中可以写入由 OpenGL ES 或其他 API 渲染产生的像素数据。
- Thread：意为线程，指的是共享相同地址空间(address space)的一组执行单元之一。通常，每个线程都有自己的程序计数器和堆栈指针。对于单线程的进程而言，线程就代表着进程。
- Display 和 EGLDisplay：大多数 EGL 调用都包含 EGLDisplay 参数。这代表了用于现实和绘制图形的抽象显示器。在大多数情况下，Display 对应单个物理屏幕，可以使用基于特定于平台的 EGL 扩展来获取其他 Display。所有 EGL 对象都与 EGLDisplay 关联，并存在于该 Display 定义的命名空间中。EGL 对象始终由 EGLDisplay 参数与表示实际对象句柄参数的组合来指定。
- Buffer：可翻译为缓冲区或者缓存，指的是用于存储数据的特定内存区域。Buffer 包括 Color Buffer，Depth Buffer 等。

## 理解 EGL

EGL 的整体定义如图：

![EGL的整体定义](/imgs/EGL的整体定义.webp)

- Display 是对实际显示设备的抽象。在 Android 中的实现类是 EGLDisplay
- Surface 是对用来存储图像的内存区域 FrameBuffer 的抽象，包括颜色缓冲区(Color Buffer)、深度缓冲区(Depth Buffer)、模版缓冲区(Stencil Buffer)。在 Android 上的实现类是 EGLSurface
- Context 存储 OpenGL ES 的状态信息。在 Android 上的实现类是 EGLContext

OpenGL ES 由一百多个 API 组成，只要明白了这一百多个 API 的意义和用途，就掌握了 OpenGL ES。这个道理在 EGL 上也同样适用。EGL 包含了 45 个 API。API 文档可以从 Khronos 网站查看：https://registry.khronos.org/EGL/sdk/docs/man/

首先，EGL 有用于与手机关联并获取手机支持的配置信息的 API。我们知道现在手机种类是各种各样，从操作系统来说，有 iOS、Android 等。同是 Android 手机，手机品牌和型号也是各种各样。所以当我们使用 EGL 与某款手机硬件进行关联的时候，首先要做的就是查看一下这款手机支持什么样的配置信息。而所谓的配置信息，就是手机支持多少种格式的绘制 buffer、每种格式对应着的 RGBA 如何划分、以及是否支持 depth、stencil 等操作等等。

然后，EGL 有用于根据需要生成手机支持的 surface 和 context、对 surface 和 context 进行关联、并将 surface 对应的绘制 FrameBuffer 显示到手机屏幕上的 API。当我们知道了手机支持什么样格式的 FrameBuffer 之后，我们就要根据需求对这些格式进行筛选，找到一个能满足我们需求且手机支持的格式，然后通过 EGL 生成一块该格式的 FrameBuffer。生成 FrameBuffer 的过程，其实就是我们通过 API 生成一块 surface。surface 是一个抽象概念，但是这个 surface 包含了 FrameBuffer，假如我们所选择的格式是支持 RGBA、depth、stencil 的。那么 surface 对应的 FrameBuffer 就会有一个 color buffer，用于保存图片的颜色信息。color buffer 会对应上百万个像素点，每个像素点有自己的颜色值，这些颜色值按照像素点的顺序保存在 color buffer 中。FrameBuffer 还包括一个 depth buffer、depth buffer 也按照同样的方法，按照顺序保存了所有像素点的 depth 值，当然还包括一个 stencil buffer，stencil buffer 也是按照顺序保存了所有像素点的 stencil 值。

EGL 还会根据格式生成一块 context。我们知道，OpenGL ES 本质上是状态机的集合，在绘制中会牵扯到各种各样的状态，这些状态全部都有默认值，我们可以通过 OpenGL ES 提供的 API 对这些状态进行改变。而这些状态值就保存在 context 中。比如 OpenGL ES 所用到的混合模式、纹理图片等信息。

EGL 可以创建多个 surface 和 context，每个 surface 在创建的时候就包含了对应的 FrameBuffer，而每个 context 创建的时候其包含的所有状态都会初始化为默认值。我们可以根据自己的需要选择启动任意一套 surface 和 context，然后对选中的 surface 和 context 进行操作。相同格式的 surface 和对应的 context，一个进程同一时间只能启用一套，而一个 context 同时也只能被一个进程启用。

之后，EGL 有用于指定使用哪个版本的 OpenGL ES、并与 OpenGL ES 建立关联的 API。由于 EGL 生成的 FrameBuffer 终归还是要提供给 OpenGL ES 使用。所以需要通过 EGL 来指定使用哪个版本的 OpenGL ES。

再之后，EGL 有用于操作 EGL 上的纹理的 API，以及与多线程相关的高级功能。纹理图片又称为纹理贴图，一般在 OpenGL ES 中，当顶点已经固定，具体形状已经成型的时候，可以将纹理贴上去，把虚拟的形状变成一个可以看见的物体。比如我们用 OpenGL ES 绘制地球时，可以用顶点坐标勾勒出一个球形，然后把世界地图作为纹理贴上去，那么这个球看上去就变成了地球。所以纹理基本就是在绘制的时候进行使用，但是在 EGL 中也有可能使用到。

EGL 生成 FrameBuffer 给 OpenGL ES 使用，有时候也会设计到多线程操作。每个 thread 都可以拥有自己的 surface 和 context，但是也要满足上面我们提到的限制，一个 thread 同一时间只能启动有相同格式的一个 surface 和一个对应的 OpenGL ES context，一个 context 同时也只能被一 个 thread 启动。

最后 EGL 还有用于初始化某个版本的 EGL 以及检测在执行上述 EGL API 的时候是否产生错误和产生了什么错误的 API。

上述讲解的 API 中有部分属于基本 API，就是在任何手机应用程序中都会使用到的 API，本文会对这部分 API 做详细讲解。剩下一些属于进阶版的 API，后续文章在介绍 OpenGL ES 的相关功能时，会介绍到。

EGL 的总体使用流程如下：

![EGL的总体使用流程](/imgs/EGL的总体使用流程.webp)

而 EGL 的初始化流程如下：

![EGL的初始化流程](/imgs/EGL的初始化流程.webp)

## 1. EGL 与操作系统窗口系统通信

在 EGL 能够确定可用的绘制表面类型之前，它必须打开和窗口系统的通信渠道。因为每个窗口系统都有不同的语义，所以 EGL 提供了基本的不透明类型---EGLDisplay。该类型封装了所有系统相关性，用于和原生窗口系统交流。任何使用 EGL 的应用程序，第一个操作必须是创建和初始化与本地 EGL 显示的连接。

EGL 提供了 3 个 API 用于获取 EGLDisplay：

![获取EGLDisplay](/imgs/获取EGLDisplay.webp)

- eglGetDisplay
- eglGetPlatformDisplay
- eglGetCurrentDisplay

开发过程中，我们频繁使用的是 eglGetDisplay 函数。

### eglGetDisplay 函数

eglGetDisplay 函数的定义如下：

```c
EGLDisplay eglGetDisplay(NativeDisplayType display_id)
```

eglGetDisplay 函数用于获取 native display 的 EGL 显示连接。调用该函数通常是初始化 EGL 的第一步。

display_id 如果是 EGL_DEFAULT_DISPLAY，则会返回默认的 display。

根据平台的不同，NativeDisplayType 可是不同的类型，比如指针，整型等。定义 NativeDisplayType 的目的是为了匹配原生窗口系统的显示类型。例如在 Microsoft Windows 上，NativeDisplayType 将被定义为一个 HDC - Microsoft Windows 设备上下文的句柄；而在 Android 系统上，其会被定义为 int 类型。

多次调用 eglGetDisplay 函数时，如果使用的参数相同，则将返回相同的 EGLDisplay 句柄。

如果没有与 display_id 匹配的可用 display 连接，，则将返回 EGL_NO_DISPLAY，此时下不会引发错误情况。但是需要我们在初始化时判断下，避免业务出现错误。

### eglGetPlatformDisplay 函数

eglGetPlatformDisplay 函数的定义如下：

 ```c
EGLDisplay eglGetPlatformDisplay(
    EGLenum platform,
    void * display_id, 
    const EGLAttrib * attrib_list
)
```

eglGetPlatformDisplay 函数仅在 EGL 1.5 及之后的版本可用。对于 Android 系统，EGL 1.5 规范的实现类为 EGL15，此类在 Android 10(API 29) 版本加入到 SDK 中，未覆盖百分百的设备，故该方法的使用仅作参考。

eglGetPlatformDisplay 函数用于获取基于指定 platform 和 display_id 的 EGLDisplay，作用与 eglGetDisplay 函数类似。

platform 和 display_id 参数的有效值定义在 EGL extensions 中。例如 X11 平台支持的 extension 规范可能要求 display_id 是指向 X11 Display 的指针，而 Microsoft Windows 平台支持的 extension 规范可能要求 display_id 是指向 Windows 设备上下文的指针。

attrib_list 参数的有效值也定义在 EGL extensions 中。attrib_list 中的所有属性(包括布尔属性)都需要戴上相应的值，并以 EGL_NONE 终止。例如 [attr1, attr1Value, attr2, attr2Value, EGL_NONE]。如果 attrib_list 中未指定某个属性，但指定 platform 需要该属性，则该属性将使用默认值(隐式指定)。

多次调用 eglGetPlatformDisplay 函数时，如果使用的参数相同，则将返回相同的 EGLDisplay 句柄。

如果 platform 不是有效值，则将产生 EGL_BAD_PARAMETER 错误；如果 platform 是有效值，但是没有与 display_id 匹配的可用 display，则将返回 EGL_NO_DISPLAY，此时下不会引发错误情况，但是需要我们在初始化时判断下，避免业务出现错误。

### eglGetCurrentDisplay 函数

eglGetCurrentDisplay 函数的定义如下：

```c
EGLDisplay eglGetCurrentDisplay(void)
```

eglGetCurrentDisplay 函数用于返回使用 eglMakeCurrent 函数所指定的当前 EGL Rendering Context 的当前 EGL display 连接。如果没有可用的当前 EGL Rendering Context，则返回 EGL_NO_DISPLAY 错误。

任何 EGL 函数需要的 EGLDisplay 入参如果传了 EGL_NO_DISPLAY 参数，都将生成 EGL_BAD_DISPLAY 错误，或者生成不可控的行为。唯一例外是在使用 eglQueryString 函数查询客户端扩展字符串时可以接受 EGLDisplay 参数的值为 EGL_NO_DISPLAY(EGL 1.5 扩展规范)。

void 参数表示不需要入参。

### 代码示例

下面的代码是可以运行在 Android 平台中的代码。除了多出 EGL14 类的前缀，其余与 C 语言风格的标准 EGL 代码完全相同。

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
    // 接下来的操作省略
}
```

## 2. 检查错误

通过上面的代码，我们知道 EGL 会发生错误。自然地，我们也可以通过 EGL 提供的接口获取错误。

EGL 中的大部分函数，在成功时会返回 EGL_TRUE，否则返回 EGL_FALSE。但是，EGL 所做的不仅是告诉我们调用是否失败，它还将记录错误，指示故障原因。不过，这个错误代码并不会直接告诉我们。我们需要查询规范，才能知道每个错误的含义。

我们可以调用 eglGetError() 函数获取错误。

```c
EGLint eglGetError(void)
```

eglGetError 函数返回当前线程中最新调用的 EGL 函数的错误。错误会被初始化为 EGL_SUCCESS，即没有任何 EGL 函数执行时，eglGetError 函数会返回 EGL_SUCCESS。

EGL 函数可能存在多个不同的错误，例如同时传递了错误的属性名称和错误的属性值，此时 EGL 的实现平台可以选择生成任何一个适用的错误。

void 参数表示不需要入参。

截止到 EGL 1.5 版本，EGL 中已定义的错误如下

以下是错误代码的说明：

![eglGetError说明](/imgs/eglGetError说明.webp)

以下是 Android 中获取 EGL 的示例代码：

```java
private void getError() {
    int errorCode = EGL14.eglGetError();
    switch (errorCode) {
        case EGL14.EGL_SUCCESS:
            println("函数执行成功，没有任何错误");
            break;
        case EGL14.EGL_NOT_INITIALIZED:
            println("对于指定的 EGL display 连接，EGL 未初始化或无法初始化");
            break;
        case EGL14.EGL_BAD_ACCESS:
            println("EGL 无法访问目标资源(例如 Context 被绑定在另一个线程中)");
            break;
        case EGL14.EGL_BAD_ALLOC:
            println("EGL 无法为目标操作分配资源");
            break;
        case EGL14.EGL_BAD_ATTRIBUTE:
            println("属性列表中传递了无法识别的属性或属性值");
            break;
        case EGL14.EGL_BAD_CONTEXT:
            println("EGLContext 参数不是有效的 EGL 渲染上下文");
            break;
        case EGL14.EGL_BAD_CONFIG:
            println("EGLConfig 参数不是有效的 EGL 帧缓冲区配置");
            break;
        case EGL14.EGL_BAD_DISPLAY:
            println("EGLDisplay 参数不是有效的 EGL display 连接");
            break;
        case EGL14.EGL_BAD_SURFACE:
            println("EGLSurface 参数不是有效的 surface(window、pixel buffer、pixmap)");
            break;
        case EGL14.EGL_BAD_CURRENT_SURFACE:
            println("调用线程的当前 surface 不是有效的 surface(window、pixel buffer、pixmap)");
            break;
        case EGL14.EGL_BAD_MATCH:
            println("参数不一致(例如有效的 context 需要缓冲区，但缓冲区不是由有效的 surface 提供)");
            break;
        case EGL14.EGL_BAD_PARAMETER:
            println("一个或多个参数值无效");
            break;
        case EGL14.EGL_BAD_NATIVE_PIXMAP:
            println("NativePixmapType 参数不是有效的 native pixmap");
            break;
        case EGL14.EGL_BAD_NATIVE_WINDOW:
            println("NativeWindowType 参数不是有效的 native window");
            break;
        case EGL14.EGL_CONTEXT_LOST:
            println("发生了电源管理事件。app 必须销毁所有 context，并重新初始化 OpenGL ES 状态和对象才能继续渲染-上下文丢失");
            break;
        default:
            break;
    }
}

private void println(String s) {
    System.out.println(s);
}
```

## 3. 初始化 EGL

EGL 提供了两个函数，用于 EGL 的初始化以及资源销毁。

![初始化EGL](/imgs/初始化EGL.webp)

### eglInitialize 函数

成功打开连接之后，需要初始化 EGL。可以调用 eglInitialize 函数进行初始化：

```c
EGLBoolean eglInitialize(
    EGLDisplay display, 
    EGLint *majorVersion, 
    EGLint *minorVersion
);
```

通过 eglGetDisplay 函数获得 EGL display 连接后，我们需要使用 eglInitialize 函数初始化该 EGLDisplay。除了返回版本号外，初始化已经初始化过的 EGLDisplay 没有任何作用。

majorVersion 和 minorVersion 参数存储的是指定 EGL 实现的主版本号和次版本号，可传入 NULL。如果 majorVersion 和 minorVersion 指定为了 NULL，则它们不会返回值。

调用了此函数后，如果想要销毁资源，则可以使用 eglTerminate 函数释放与 EGLDisplay 关联的资源。

如果 eglInitialize 方法调用失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。当返回 EGL_FALSE 时，major 和 minor 不会被设值。

如果 display 不是 EGL display 连接，则会生成 EGL_BAD_DISPLAY 错误；如果无法初始化 display，则会生成 EGL_NOT_INITIALIZED 错误。

### eglTerminate 函数

调用了 eglInitialize 函数后，如果想要销毁资源，则可以使用 eglTerminate 函数释放与 EGLDisplay 关联的资源。eglTerminate 函数的定义如下：

```c
EGLBoolean eglTerminate(EGLDisplay display)
```

eglTerminate 函数用于释放与 EGL 显示连接关联的资源。调用此函数后，与 EGL 显示连接关联的所有 EGL 资源将被标记为删除。与 display 关联的、被任何线程设置为了当前正在使用的 context 或 surface 不会被释放，直到调用了 eglMakeCurrent 函数设置了其他的 context 和 surface后，他们才会被释放。

终止已终止了的 EGL 显示连接没有任何效果。终止了的 display 可以通过再次调用 eglInitialize 函数来重新初始化。

如果 eglTerminate 函数调用失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。

如果 display 不是 EGL 显示连接，则会生成 EGL_BAD_DISPLAY 错误。

### 代码示例

在 Android 中，上述函数的具体示例代码如下：

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

// 无用了，进行销毁
isSuccess = EGL14.eglTerminate(eglDisplay);

if(!isSuccess) {
    switch (EGL14.eglGetError()) {
        case EGL14.EGL_BAD_DISPLAY:
            println("销毁 display 失败，无效的 EGLDisplay 参数");
            break;
        default:
            println("发生错误!!!");
            break;
    }
    return;
}
```

## 4. 确定可用表面配置

一旦初始化了 EGL，就可以确定可用渲染表面的类型和配置，这有两种方法：

1. 查询每个表面配置，找出最好的选择
2. 指定一组需求，让 EGL 推荐最佳匹配

在许多情况下，我们只用使用第二种方法，第二种方法更简单，而且最有可能得到用第一种方法找到的匹配。

在任何一种情况下，EGL 都将返回一个 EGLConfig，这是包含有关特定 surface 及其特征(如每个颜色分量的位数、与 EGLConfig 相关的深度缓冲区(如果有的话))的 EGL 内部数据结构的标识符。可以用 eglGetConfigAttrib 函数查询 EGLConfig 的任何属性，EGL 定义的与 Config 有关的函数有三个：eglGetConfigs、eglGetConfigAttrib、eglChooseConfig。

![确定可用表面配置](/imgs/确定可用表面配置.webp)

### eglGetConfigs 函数

调用 eglGetConfigs 函数，我们可以查询系统支持的所有 EGL surface 配置：

```c
EGLBoolean eglGetConfigs(
    EGLDisplay display,
    EGLConfig * configs,
    EGLint config_size,
    EGLint * num_config
)
```

eglGetConfigs 函数会返回 display 支持的所有 EGL frame buffer 配置。返回的配置信息放在 configs 列表中，configs 列表的尺寸为 config_size。系统实际支持的配置数量由 num_config 记录，因为系统支持的配置数量可能小于 configs 列表的尺寸。

configs 列表中的每个数据都可以在任何需要 EGL frame buffer 配置参数的 EGL 函数中使用。configs 可以指定为 NULL。如果指定为了 NULL，则 configs 不会返回值。仅查询所有 frame buffer 配置的数量时，可以将 configs 可以指定为 NULL。

一般我们应该首先设置 configs = NULL，并作为参数传递给 eglGetConfigs 函数，以获取系统支持的 frame buffer 配置数量。然后根据该数量初始化 configs 数组，再次调用 eglGetConfigs 函数，获取到相应的配置列表。

我们可以使用 eglGetConfigAttrib 函数检查 frame buffer 配置中的各个属性值。

如果函数调用失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。返回 EGL_FALSE 时，configs 和 num_config 不会被修改。

如果显示器不是 EGL display 连接，则会生成 EGL_BAD_DISPLAY 错误；如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误；如果 num_config 参数为 NULL，则生成 EGL_BAD_PARAMETER 错误。

### eglGetConfigAttrib 函数

我们可以使用 eglGetConfigAttrib 函数检查 EGLConfig 中的各个属性值。eglGetConfigAttrib 函数的定义如下：

```c
EGLBoolean eglGetConfigAttrib(
    EGLDisplay display,
    EGLConfig config,
    EGLint attribute,
    EGLint * value
)
```

eglGetConfigAttrib 函数会查询指定 display 的指定 config 的指定 attribute 的值，查询结果使用 value 字段承载。attribute 的可选项如表格：

![eglGetConfigAttrib函数](/imgs/eglGetConfigAttrib函数.webp)

eglGetConfigAttrib 函数执行失败时会返回 EGL_FALSE，否则返回 EGL_TRUE。当返回 EGL_FALSE 时，value 字段不会被修改。

对于 eglGetConfigAttrib 函数的入参，如果 display 不是 EGL 的 display 连接，则 EGL 会生成 EGL_BAD_DISPLAY 错误；如果 display 尚未初始化，则 EGL 会生成 EGL_NOT_INITIALIZED 错误；如果 config 不是 EGL frame buffer configuration，则 EGL 会生成 EGL_BAD_CONFIG 错误；如果 attribute 不是有效的 frame buffer configuration attribute，则 EGL 会生成 EGL_BAD_ATTRIBUTE 错误。

### eglChooseConfig 函数

如果我们不关心所有的属性，那么可以使用 eglChooseConfig 函数。我们可以指定我们关心的重要的属性，此函数会返回最佳匹配结果。返回的 EGLConfigs 列表中的每个数据可用在任何需要 EGL frame buffer 配置参数的 EGL 函数中。eglChooseConfig 函数的定义如下：

```c
EGLBoolean eglChooseConfig(
    EGLDisplay display,
    EGLint const * attrib_list,
    EGLConfig * configs,
    EGLint config_size,
    EGLint * num_config
)
```

我们需要在 eglChooseConfig 函数的入参中传入用于接受结果的 configs 参数，以及自定义属性 attrib_list 参数。eglChooseConfig 函数会在 configs 中返回所有与 attrib_list 匹配的 EGL frame buffer 配置。返回的 EGLConfigs 列表中的每个数据都可用在任何需要 EGL frame buffer 配置参数的 EGL 函数中。

如果 configs 不为 NULL，则 configs 列表的尺寸为 config_size。因为系统支持的配置数量可能小于 configs 列表的尺寸，所以系统返回的实际支持的配置数量由一个单独的变量 num_config 记录。

如果 configs 为 NULL，则 configs 中不会返回任何配置，此时匹配 attrib_list 的配置数量将在 num_config 中返回。此时 config_size 被忽略。我们可以将 configs 设置为 NULL，以确定匹配的 frame buffer 配置的数量。拿到数量后分配对应大小的 EGLConfig 数组，其他参数不变，再次调用 eglChooseConfig 函数，获取到准确的配置列表。

attrib_list 中的所有属性(包括布尔属性)都要带上对应的值，列表以 EGL_NONE 终止。比如\[属性1, 属性值1, 属性2, 属性值2, EGL_NONE]。下面的例子表示配置支持的颜色缓冲区中的 RGB 颜色通道的位数至少是 4 位。

```c
EGLint const attrib_list[] = {
    EGL_RED_SIZE, 4,
    EGL_GREEN_SIZE, 4,
    EGL_BLUE_SIZE, 4,
    EGL_NONE
};
```

如果 attrib_list 中未指定某个必须的属性，则 EGL 会使用默认值(隐式指定)。例如，如果未指定 EGL_DEPTH_SIZE，则假定其为 0。部分其他属性的默认值是 EGL_DONT_CARE，意为对于该属性，设置任何值都可以，因此 EGL 不会检查该属性。属性以属性特定的方式进行匹配。某些属性(例如 EGL_LEVEL)必须与指定值完全匹配，其他的如 EGL_RED_SIZE 属性则是必须大于等于指定的最小值。对于 EGL_CONFORMANT、EGL_RENDERABLE_TYPE 和 EGL_SURFACE_TYPE 三种 bitmask attribute，在进行属性匹配时会仅考虑掩码的非零 bit 数据，每个 bit 的取值可能为 0 或 1。

可出现在 attrib_list 中的属性为(此处不再使用表格截图，防止不好搜索)：

- EGL_CONFIG_ID：表示所需的 EGL frame buffer configurations(帧缓冲区配置) 的 ID。使用时必须指定值，值为有效的整数 ID。当指定 EGL_CONFIG_ID 时，所有其他属性都将被忽略。默认值为 EGL_DONT_CARE。config ID 的具体含义取决于 EGL 实现。它们仅用于唯一标识不同的帧缓冲区配置。
- EGL_ALPHA_MASK_SIZE：表示 alpha mask buffer 的尺寸(单位为 bit)，使用时必须指定值，值为非负整数，默认值为零。如果有多个配置的尺寸大于等于目标尺寸，则会从中优先选择最小符合尺寸的配置。alpha mask buffer 仅在 OpenVG 中使用。
- EGL_RED_SIZE：表示 color buffer 中红色通道的尺寸(单位为 bit)。使用时必须指定值，值为非负整数，默认值为零。如果该值为零，则会优先选择具有最小红色通道的 color buffer。当有多个尺寸大于等于目标尺寸时，会从中优先选择最大符合尺寸的配置。
- EGL_GREEN_SIZE：表示 color buffer 中绿色通道的尺寸(单位为 bit)。使用时必须指定值，值为非负整数，默认值为零。如果该值为零，则会优先选择具有最小绿色通道的 color buffer。当有多个尺寸大于等于目标尺寸时，会从中优先选择最大符合尺寸的配置。
- EGL_BLUE_SIZE：表示 color buffer 中蓝色通道的尺寸(单位为 bit)。使用时必须指定值，值为非负整数，默认值为零。如果该值为零，则会优先选择具有最小蓝色通道的 color buffer。当有多个尺寸大于等于目标尺寸时，会从中优先选择最大符合尺寸的配置。
- EGL_ALPHA_SIZE：表示 color buffer 中 alpha 通道的尺寸(单位为 bit)。使用时必须指定值，值为非负整数，默认值为零。如果该值为零，则会优先选择具有最小 alpha 通道的 color buffer。当有多个尺寸大于等于目标尺寸时，会从中优先选择最大符合尺寸的配置。
- EGL_BUFFER_SIZE：表示所需的 color buffer 的大小(单位为 bit)。该值是 EGL_RED_SIZE、EGL_GREEN_SIZE、EGL_BLUE_SIZE 和 EGL_ALPHA_SIZE 的总和。通常最好单独指定这些颜色分量的尺寸。使用该属性时必须指定值，值为非负整数，默认值为零。如果有多个配置的尺寸大于等于目标尺寸，则会从中优先选择最小符合尺寸的配置。
- EGL_DEPTH_SIZE：表示所需的 depth buffer(深度缓冲区)的尺寸(单位为 bit)。使用时必须指定值，值为非负整数，默认值为零。如果所需大小为零，则会优先选择没有深度缓冲区的帧缓冲区配置。如果有多个配置的尺寸大于等于目标尺寸，则会从中优先选择最小符合尺寸的配置。深度缓冲区仅由 OpenGL 和 OpenGL ES 客户端 API 使用。
- EGL_STENCIL_SIZE：表示配置所需的 stencil buffer (模板缓冲区)的尺寸(单位为 bit)，使用时必须指定值，值为非负整数，默认值为零。如果有多个配置的尺寸大于等于目标尺寸，则会从中优先选择最小符合尺寸的配置。如果所需的尺寸为零，则会优先选择没有模板缓冲区的帧缓冲区配置。模板缓冲区仅由 OpenGL 和 OpenGL ES 客户端 API 使用。
- EGL_LUMINANCE_SIZE：表示颜色缓冲区的亮度分量的尺寸(单位为 bit)。使用时必须指定值，默认值为零。如果为零，则会优先选择具有最小亮度分量尺寸的颜色缓冲区。当有多个尺寸大于等于目标尺寸时，会从中优先选择最大符合尺寸的颜色缓冲区。
- EGL_BIND_TO_TEXTURE_RGB：表示选择支持将 color buffer 绑定到 OpenGL ES RGB 纹理的 frame buffer configurations。使用该属性时必须指定值，值为 EGL_DONT_CARE、EGL_TRUE 或 EGL_FALSE。默认值为 EGL_DONT_CARE。目前只有支持 pbuffer 的 frame buffer configurations 允许这样做。
- EGL_BIND_TO_TEXTURE_RGBA：表示选择支持将 color buffer 绑定到 OpenGL ES RGBA 纹理的 frame buffer configurations。使用该属性时必须指定值，值为 EGL_DONT_CARE、EGL_TRUE 或 EGL_FALSE。默认值为 EGL_DONT_CARE。目前只有支持 pbuffer 的 frame buffer configurations 允许这样做。
- EGL_COLOR_BUFFER_TYPE：表示 color buffer 的类型，使用时必须指定值，值为 EGL_RGB_BUFFER 或 EGL_LUMINANCE_BUFFER。
    - EGL_RGB_BUFFER：表示 RGB 颜色缓冲区。指定了 EGL_RGB_BUFFER 时，EGL_RED_SIZE、EGL_GREEN_SIZE 和 EGL_BLUE_SIZE 必须非零，并且 EGL_LUMINANCE_SIZE 必须为零。
    - EGL_LUMINANCE_BUFFER：表示亮度颜色缓冲区。指定了 EGL_LUMINANCE_BUFFER 时，EGL_RED_SIZE、EGL_GREEN_SIZE、EGL_BLUE_SIZE 必须为零，并且 EGL_LUMINANCE_SIZE 必须非零。
    - 对于 RGB 和亮度颜色缓冲区，EGL_ALPHA_SIZE 可以为零或非零。

- EGL_CONFIG_CAVEAT：表示根据 EGL 的警告信息选择配置。使用时必须指定值，值为 EGL_DONT_CARE、EGL_NONE、EGL_SLOW_CONFIG 或 EGL_NON_CONFORMANT_CONFIG。默认值为 EGL_DONT_CARE。
    - 如果指定了 EGL_DONT_CARE，则在根据属性匹配相关配置时，会忽略掉该属性。
    - 如果指定了 EGL_NONE，则在根据属性匹配相关配置时，会匹配此属性，但只会考虑没有警告的配置(即 EGL_CONFIG_CAVEAT 的值非 EGL_SLOW_CONFIG 和 EGL_NON_CONFORMANT_CONFIG)。
    - 如果指定了 EGL_SLOW_CONFIG，则在根据属性匹配相关配置时，仅考虑慢速配置。 "慢速配置"的含义取决于 EGL 实现，但通常表示的是非硬件加速(软件)实现的配置。
    - 如果指定了 EGL_NON_CONFORMANT_CONFIG，则在根据属性匹配相关配置时，仅考虑支持不符合 OpenGL ES 上下文的配置。如果 EGL 版本为 1.3 或更高版本，则 EGL_NON_CONFORMANT_CONFIG 已过时，因为可以使用 EGL_CONFORMANT 属性为每个 client API 指定相同的信息，而不仅仅是针对 OpenGL ES。

- EGL_CONFORMANT：后面必须跟一个 bitmask，表示根据帧缓冲区配置创建的哪些类型的客户端 API 上下文必须通过该 API 所需的一致性测试。默认值为零。例如，如果 bitmask 设置为 EGL_OPENGL_ES_BIT，则只有支持创建 OpenGL ES 上下文的帧缓冲区配置才会匹配上，大多数 EGLConfig 应与所有受支持的客户端 API 一致，并且很少需要选择不合格的配置。一致性要求限制了 EGL 实现可以定义的不一致配置的数量。掩码位包括：
    - EGL_OPENGL_BIT：Config 支持创建 OpenGL 上下文
    - EGL_OPENGL_ES_BIT：Config 支持创建 OpenGL ES 1.0 或 1.1 上下文
    - EGL_OPENGL_ES2_BIT：Config 支持创建 OpenGL ES 2.0 上下文
    - EGL_OPENVG_BIT：Config 支持创建 OpenVG 上下文
- EGL_LEVEL：表示 frame buffer 的级别。使用必须指定值，值为整数缓冲区级别信息(integer buffer level specification)，默认值为零。缓冲区级别为 0 表示显示器的默认帧缓冲区。等级大于 0 表示 frame buffer 覆盖在默认 frame buffer 的上方，等级小于 0 表示 frame buffer 位于默认 frame buffer  的下方。缓冲区级别为 1 表示是第 1 个覆盖的 frame buffer，缓冲区级别为 2 表示是第 2 个覆盖的 frame buffer，依此类推。大多数平台不支持 0 以外的缓冲区级别。覆盖和被覆盖平面的窗口的行为取决于底层平台。
- EGL_MATCH_NATIVE_PIXMAP：表示配置支持使用 eglCreatePixmapSurface 函数创建 pixmap(像素图)对应的 pixmap surfaces。使用时必须指定值，值为有效的 native pixmap 的句柄，类型为 EGLint 或 EGL_NONE，默认值为 EGL_NONE。如果值为 EGL_NONE，则进行属性匹配时，会忽略该属性。引入 EGL_MATCH_NATIVE_PIXMAP 属性是因为仅使用颜色通道大小(R、G、B、A、亮度)来确定 EGLConfig 与 native pixmap 的兼容性比较困难。
- EGL_NATIVE_RENDERABLE：表示 frame buffer configuration 支持从 native 渲染到 surface。使用时必须指定值，值为 EGL_DONT_CARE、EGL_TRUE 或 EGL_FALSE。默认值为 EGL_DONT_CARE。
- EGL_MAX_SWAP_INTERVAL：表示可以传递给 eglSwapInterval 函数的最大值。使用时必须指定值，值为整数，默认值为 EGL_DONT_CARE。
- EGL_MIN_SWAP_INTERVAL：表示可以传递给 eglSwapInterval 函数的最小值。使用时必须指定值，值为整数，默认值为 EGL_DONT_CARE。
- EGL_SAMPLE_BUFFERS：表示配置可接受的 multisample buffers(多重采样缓冲区) 的数量。使用时必须指定值，值为可接受的最小多重采样缓冲区的数量。默认值为零。如果有多个配置的数量大于等于目标数，则会从中优先选择最小符合数量的配置。目前，EGL 并未定义使用多个 multisample buffers 的操作，因此 multisample buffers 的数量只有指定为 0 或 1 才是有效的。
- EGL_SAMPLES：表示 multisample buffers 中所需的最小样本数。使用时必须指定值。如果有多个配置的数量大于等于目标数，则会从中优先选择最小符合数量的配置。注意 multisample buffers 中的颜色样本 bit 尺寸可能比主 color buffer 的颜色具有更少的位数。但是通常其总体上至少保持与主 color buffer 一样多的颜色分辨率。
- EGL_RENDERABLE_TYPE：表示配置支持的使用 eglCreateContext 函数创建的 client API 上下文的类型，使用时必须指定值，值为一个 bitmask，bitmask 的取值与属性 EGL_CONFORMANT 相同(EGL_OPENGL_BIT、EGL_OPENGL_ES_BIT、EGL_OPENGL_ES2_BIT、EGL_OPENVG_BIT)。默认值为EGL_OPENGL_ES_BIT。
- EGL_SURFACE_TYPE：表示 frame buffer configuration 必须支持的 EGL surface 的类型和能力。使用时必须指定值，值为一个 bitmask。默认值为 EGL_WINDOW_BIT。例如，如果 bitmask 设置为 EGL_WINDOW_BIT | EGL_PIXMAP_BIT，则返回的配置仅考虑支持窗口和像素图的帧缓冲区配置。bitmask 的取值包括：
    - EGL_MULTISAMPLE_RESOLVE_BOX_BIT：Config 允许使用 eglSurfaceAttrib 函数指定 box 过滤 multisample 解析行为。
    - EGL_PBUFFER_BIT：Config 支持创建 pixel buffer surfaces。
    - EGL_PIXMAP_BIT：Config 支持创建 pixmap surfaces。
    - EGL_SWAP_BEHAVIOR_PRESERVED_BIT：配置允许使用 eglSurfaceAttrib 函数设置 color buffers 的交换行为。
    - EGL_VG_ALPHA_FORMAT_PRE_BIT：Config 允许在 surface 创建时使用预乘(premultiplied)的 alpha 值指定 OpenVG 渲染(具体可以参考 eglCreatePbufferSurface、eglCreatePixmapSurface 和 eglCreateWindowSurface 函数的说明文档)。
    - EGL_VG_COLORSPACE_LINEAR_BIT：Config 允许在 surface 创建时使用线性色彩空间(linear colorspace)进行 OpenVG 渲染(具体可以参考 eglCreatePbufferSurface、eglCreatePixmapSurface 和 eglCreateWindowSurface 函数的说明文档)。
    - EGL_WINDOW_BIT：Config 支持创建 window surfaces.

- EGL_TRANSPARENT_TYPE：表示选择不透明帧缓冲区配置还是透明帧缓冲区配置。使用时必须指定值，值为 EGL_NONE 或 EGL_TRANSPARENT_RGB 之一。默认值为 EGL_NONE。如果指定了 EGL_NONE，则返回的配置仅考虑不透明帧缓冲区配置。如果指定了 EGL_TRANSPARENT_RGB，则返回的配置仅考虑透明帧缓冲区配置。注意大多数 EGL 实现仅支持不透明帧缓冲区配置(即 EGL_NONE)。
- EGL_TRANSPARENT_RED_VALUE：表示配置支持的透明红色值。使用时必须指定值，值为 EGL_DONT_CARE 或表示透明红色值的整数值。该值必须介于零和最大红色值之间。默认值为 EGL_DONT_CARE。此属性只有在 EGL_TRANSPARENT_TYPE 被包含在 attrib_list 中并且指定为了 EGL_TRANSPARENT_RGB 时才生效，否则将被忽略。
- EGL_TRANSPARENT_GREEN_VALUE：表示配置支持的透明绿色值。使用时必须指定值，值为 EGL_DONT_CARE 或表示透明绿色值的整数值。该值必须介于零和最大绿色值之间。默认值为 EGL_DONT_CARE。此属性只有在 EGL_TRANSPARENT_TYPE 被包含在 attrib_list 中并且指定为了 EGL_TRANSPARENT_RGB 时才生效，否则将被忽略。
- EGL_TRANSPARENT_BLUE_VALUE：表示配置支持的透明蓝色值。使用时必须指定值，值为 EGL_DONT_CARE 或表示透明蓝色值的整数值。该值必须介于零和最大蓝色值之间。默认值为 EGL_DONT_CARE。此属性只有在 EGL_TRANSPARENT_TYPE 被包含在 attrib_list 中并且指定为了 EGL_TRANSPARENT_RGB 时才生效，否则将被忽略。

当存在多个匹配的 EGL frame buffer 配置结果时，EGL 会根据以下匹配标准对结果排序(即定义优先级)：

1. 比较 EGL_CONFIG_CAVEAT，其中优先级为 EGL_NONE > EGL_SLOW_CONFIG > EGL_NON_CONFORMANT_CONFIG。
2. 比较 EGL_COLOR_BUFFER_TYPE，其中优先级为 EGL_RGB_BUFFER > EGL_LUMINANCE_BUFFER。
3. 比较颜色位数总和，根据位数降序排序(值较大的在前面)。对于 RGB 颜色缓冲区，这是 EGL_RED_SIZE、EGL_GREEN_SIZE、EGL_BLUE_SIZE 和 EGL_ALPHA_SIZE 的总和；对于亮度颜色缓冲区，这是 EGL_LUMINANCE_SIZE 和 EGL_ALPHA_SIZE 的总和。如果 attrib_list 中传入的特定颜色分量的位数为 0 或 EGL_DONT_CARE，则不考虑该分量的位数。此排序规则将具有较深颜色缓冲区的配置放置在具有较浅颜色缓冲区的配置之前，是违反直觉的。因为这条规则的存在，我们可能需要额外的逻辑来检查返回的结果。例如如果我们需要的是 "565" RGB 格式，那么 "888" 格式将先出现在结果列表中。
4. 比较 EGL_BUFFER_SIZE，较小的值在前面(升序排列)。
5. 比较 EGL_SAMPLE_BUFFERS，较小的值在前面(升序排列)。
6. 比较 EGL_SAMPLES，较小的值在前面(升序排列)。
7. 比较 EGL_DEPTH_SIZE，较小的值在前面(升序排列)。
8. 比较 EGL_STENCIL_SIZE，较小的值在前面(升序排列)。
9. 比较 EGL_ALPHA_MASK_SIZE，较小的值在前面(升序排列)，这仅适用于 OpenVG surface。
10. 比较 EGL_NATIVE_VISUAL_TYPE，实际的排序顺序由 EGL 实现定义，主要取决于 native 视觉类型的含义
11. 比较 EGL_CONFIG_ID，较小的值在前面(升序排列)，该属性的比较始终是最后的排序规则，并保证排序的唯一性。

其他未提到的参数不用于排序过程。

#### 注意事项

1. 如果亮度颜色缓冲区支持 OpenGL 或 OpenGL ES 渲染，则将其视为 RGB 渲染。其中 GL_RED_BITS 的值等于 EGL_LUMINANCE_SIZE，GL_GREEN_BITS 和 GL_BLUE_BITS 的值等于 0。红色分量被写入颜色缓冲区的亮度通道，而绿色和蓝色分量被丢弃。

2. eglGetConfigs 函数和 eglGetConfigAttrib 函数可用于实现除 eglChooseConfig 函数实现的通用算法之外的其他选择算法。调用eglGetConfigs 函数会检查所有的帧缓冲区配置。接着调用 eglGetConfigAttrib 函数检查帧缓冲区配置的其他属性，根据二者的选择结果做选择。

3. EGL 工作组虽然强烈建议 EGL 实现不要更改 eglChooseConfig 函数使用的选择算法，但并未禁止这种做法。因此，配置的选择结果可能会随着 client 版本的变化而变化。

#### 函数产生的错误

eglChooseConfig 函数执行失败时会返回 EGL_FALSE，否则返回 EGL_TRUE。返回 EGL_FALSE 时，configs 和 num_config 参数的值不会被修改。

eglChooseConfig 函数可能会抛出以下错误

- EGL_BAD_DISPLAY 错误：display 不是 EGL display 连接。
- EGL_BAD_ATTRIBUTE 错误：attribute_list 列表包含无效的或无法识别的或超出范围的帧缓冲区配置属性和属性值。
- EGL_NOT_INITIALIZED 错误：display 尚未初始化。
- EGL_BAD_PARAMETER 错误：num_config 参数为 NULL。

## 5. 绑定目标平台 API

### eglBindAPI 函数

确定好了配置之后，在创建 context 和 surface 之前，我们需要先设置一下当前调用 EGL 的线程的当前渲染 API。我们可以使用 eglBindAPI 函数进行绑定，**当然，因为当前渲染 API 的默认值就是 OpenGL ES API，所以在 Android 中，这一步骤实际上可以省略。**

eglBindAPI 函数的定义如下：

```c
EGLBoolean eglBindAPI(EGLenum api);
```

eglBindAPI 函数用于指定调用 EGL 的线程的当前渲染 API，该 API 必须是 EGL 具体实现支持的渲染 API 之一。

- 如果 api 为 EGL_OPENGL_API，则当前渲染 API 设置为 OpenGL API
- 如果 api 为 EGL_OPENGL_ES_API，则当前渲染 API 设置为 OpenGL ES API
- 如果 api 为 EGL_OPENVG_API，则当前渲染 API 设置为 OpenVG API

当前渲染 API 的初始值为 EGL_OPENGL_ES_API，当实现不支持 OpenGL ES 时，当前渲染 API 的初始值为 EGL_NONE(但是 EGL_NONE 不是 eglBindAPI 的有效 api 参数)。可以通过调用 eglQueryAPI 函数来查询当前的渲染 API。

调用 eglBindAPI 函数会影响其他 EGL 命令的行为，这些命令包括：

- eglCreateContext
- eglGetCurrentContext
- eglGetCurrentDisplay
- eglGetCurrentSurface
- eglMakeCurrent
- eglSwapInterval
- eglWaitClient
- eglWaitNative

如果调用 eglBindAPI 函数时发生了错误，则当前渲染 API 不变。绑定失败时会返回 EGL_FALSE。

如果 api 不是有效的入参，或者 EGL 实现不支持指定的客户端 API，则会生成 EGL_BAD_PARAMETER 错误。

### eglQueryAPI 函数

如果需要查询调用 EGL 的当前线程的当前渲染 API，可以使用 eglQueryAPI 函数。eglQueryAPI 函数的定义如下：

```c
EGLenum eglQueryAPI(void)
```

eglQueryAPI 函数会返回调用 EGL 的线程中的当前渲染 API 的值。当前渲染 API 由 eglBindAPI 设置，并影响其他 EGL 命令的行为。

返回的值是 eglBindAPI 的有效 api 参数之一，或者是 EGL_NONE。当前渲染 API 的初始值为 EGL_OPENGL_ES_API。当实现不支持 OpenGL ES 时，会返回 EGL_NONE。

void 参数表示不需要入参。该函数不会产生错误。

## 6. 创建渲染区域：EGL Surface

如果 eglChooseConfig 函数执行成功，我们就有足够的信息来创建绘图表面。

EGL 提供了众多函数以创建 Surface：
- eglCreatePbufferSurface
- eglCreatePixmapSurface
- eglCreateWindowSurface
- eglCreatePlatformPixmapSurface
- eglCreatePlatformWindowSurface

另外EGL 还提供了与 Surface 相关的辅助函数：
- eglDestroySurface
- eglGetCurrentSurface
- eglQuerySurface
- eglSurfaceAttrib。

![EGL_Surface](/imgs/EGL_Surface.webp)

与 Platform 相关的方法仅 EGL 1.5 及更高版本支持，本文就暂时不讲了。我们讲讲剩下的方法。

### eglGetCurrentSurface 函数

eglGetCurrentSurface 函数用于获取由 eglMakeCurrent 指定的，添加到当前 EGL 渲染上下文的只读或绘制表面。如果当前没有上下文，则会返回 EGL_NO_SURFACE。eglGetCurrentSurface 函数的定义如下：

```c
EGLSurface eglGetCurrentSurface(EGLint readdraw)
```

调用 eglGetCurrentSurface 函数时，我们需要传入 readdraw 参数，用于指定获取的是只读表面(EGL_READ)还是绘制表面(EGL_DRAW)。

### eglDestroySurface 函数

当我们创建的 surface 不再使用时，我们可以调用 eglDestroySurface 函数销毁该 surface。eglDestroySurface 函数的定义如下：

```c
EGLBoolean eglDestroySurface(EGLDisplay display, EGLSurface surface)
```

如果 EGL surface 不是任何线程的当前 surface，则 eglDestroySurface 函数会立即销毁该 surface。否则销毁操作会直到 surface 不再是任何线程的当前 surface 时再进行。此外，在绑定到纹理对象的 pbuffer 的所有 color buffers 都被释放之前，与 pbuffer surface 关联的资源不会被释放。

- 如果 surface 销毁失败，则 eglDestroySurface 函数会返回 EGL_FALSE，否则返回 EGL_TRUE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 surface 不是 EGL surface，则会生成 EGL_BAD_SURFACE 错误。

### eglQuerySurface 函数

eglGetCurrentSurface 函数用于获取指定 surface 的信息，这些信息主要是 surface attributes。eglGetCurrentSurface 函数的定义如下：

```c
EGLBoolean eglQuerySurface(
    EGLDisplay display,
    EGLSurface surface,
    EGLint attribute,
    EGLint * value
)
```

eglGetCurrentSurface 函数用于获取与 display 关联的 surface 的 attribute，attribute 的值由 value 接收。attribute 的可取值有：

- EGL_CONFIG_ID：返回创建 surface 时所用的 EGL frame buffer configuration 的 ID。
- EGL_GL_COLORSPACE：返回渲染到 surface 时，OpenGL 和 OpenGL ES 使用的颜色空间，可取值为 EGL_GL_COLORSPACE_SRGB 或 EGL_GL_COLORSPACE_LINEAR。注意仅当 EGL 版本为 1.5 或更高时才支持该属性。
- EGL_WIDTH：返回 surface 的宽度(单位为像素)。
- EGL_HEIGHT：返回 surface 的高度(单位为像素)。
- EGL_HORIZONTAL_RESOLUTION：返回与可见 window surface 关联的 display 的水平 dp 值。返回的值 = 实际 dp(单位 pixels/meter) * 常量值 EGL_DISPLAY_SCALING。
- EGL_VERTICAL_RESOLUTION：返回与可见 window surface 关联的 display 的垂直 dp 值。返回的值 = 实际 dp(单位 pixels/meter) * 常量值 EGL_DISPLAY_SCALING。
- EGL_LARGEST_PBUFFER：返回使用 eglCreatePbufferSurface 函数创建 surface 时指定的相同属性值。对于 window 或者 pixmap surface，属性值不可变。
- EGL_MIPMAP_LEVEL：如果纹理具有 mipmap，则返回要渲染 mipmap 的级别。
- EGL_MIPMAP_TEXTURE：如果纹理具有 mipmap，则返回 EGL_TRUE，否则返回 EGL_FALSE。
- EGL_MULTISAMPLE_RESOLVE：返回解析 multisample buffer 时使用的 filter。filter  可以是 EGL_MULTISAMPLE_RESOLVE_DEFAULT  或 EGL_MULTISAMPLE_RESOLVE_BOX。更详细的解释可以看 eglSurfaceAttrib 函数的说明。注意仅当 EGL 版本为 1.4 或更高时才支持该属性。
- EGL_PIXEL_ASPECT_RATIO：返回像素的宽高比。返回的值 = 实际宽高比 * 常量值 EGL_DISPLAY_SCALING。
- EGL_RENDER_BUFFER：返回 client API 渲染使用的 buffer。对于 window surface，返回值与创建 surface 时指定的属性值相同。对于 pbuffer surface，返回值始终是 EGL_BACK_BUFFER。对于 pixmap surface，返回值始终是 EGL_SINGLE_BUFFER。要确定上下文渲染时使用的实际 buffer，可以调用 eglQueryContext 函数。
- EGL_SWAP_BEHAVIOR：返回使用 eglSwapBuffers 函数激活 surface 时该 surface 的 color buffer 的效果。Swap behavior 可以是 EGL_BUFFER_PRESERVED 或 EGL_BUFFER_DESTROYED。更详细的解释可以看 eglSurfaceAttrib 函数的说明。
- EGL_TEXTURE_FORMAT：返回纹理的格式。可取值为 EGL_NO_TEXTURE、EGL_TEXTURE_RGB 和 EGL_TEXTURE_RGBA。
- EGL_TEXTURE_TARGET：返回纹理的类型。可取值为 EGL_NO_TEXTURE 或 EGL_TEXTURE_2D。
- EGL_VG_ALPHA_FORMAT：返回渲染到 surface 时，OpenVG 使用的 alpha 值的解释器，可取值为 EGL_VG_ALPHA_FORMAT_NONPRE 或 EGL_VG_ALPHA_FORMAT_PRE。
- EGL_VG_COLORSPACE：返回渲染到 surface 时，OpenVG 使用的颜色空间，可取值为 EGL_VG_COLORSPACE_sRGB 或 EGL_VG_COLORSPACE_LINEAR。

针对上述属性值，一些注意事项如下：

- 查询非 pbuffer surface 的 EGL_TEXTURE_FORMAT、EGL_TEXTURE_TARGET、EGL_MIPMAP_TEXTURE 或 EGL_MIPMAP_LEVEL 属性不会出错，但是返回的结果是不可变的。

- EGL_DISPLAY_SCALING 是常量值 10000。浮点值(例如分辨率和像素宽高比)在作为整数返回之前按此值进行缩放，以便在返回值中保留足够的有意义的精度。

- 对于离屏(pbuffer 或 pixmap)surface，或者是 dp 或宽高比未知的 surface，查询 EGL_HORIZONTAL_RESOLUTION、EGL_PIXEL_ASPECT_RATIO 或 EGL_VERTICAL_RESOLUTION 属性时将返回常量值 EGL_UNKNOWN (-1)。

#### 函数错误

- eglGetCurrentSurface 函数执行失败时会返回 EGL_FALSE，否则返回 EGL_TRUE。当返回 EGL_FALSE 时，valuse 入参中的数据不会被修改。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 surface 不是 EGL surface，则会生成 EGL_BAD_SURFACE 错误。
- 如果 attribute 不是有效的 surface 属性，则会生成 EGL_BAD_ATTRIBUTE 错误。

### eglSurfaceAttrib 函数

我们可以使用 eglSurfaceAttrib 函数设置与 display 关联的 surface 的 attribute 的值。eglSurfaceAttrib 函数的定义如下：

```c

EGLBoolean eglSurfaceAttrib(
    EGLDisplay display,
    EGLSurface surface,
    EGLint attribute,
    EGLint value
)
```

attribute 的取值如下：

- EGL_MIPMAP_LEVEL：对于 mipmap 纹理，EGL_MIPMAP_LEVEL 属性指定 mipmap 应渲染到哪个级别。如果此属性的值超出受支持的 mipmap 级别范围，则会选择最接近的有效的 mipmap 级别进行渲染。默认值为 0。注意如果 surface 不是 pbuffer，仍然可以设置 EGL_MIPMAP_LEVEL 属性，但没有效果。
- EGL_MULTISAMPLE_RESOLVE：指定解析 multisample buffer 时要使用的 filter。解析操作可能发生在 swap 或者 copy surface 时，或者在更改绑定到 surface 的 client API context 时)。该属性的值可设为 EGL_MULTISAMPLE_RESOLVE_DEFAULT 或者 EGL_MULTISAMPLE_RESOLVE_BOX。EGL_MULTISAMPLE_RESOLVE_DEFAULT 表示使用默认实现的过滤方法，而 EGL_MULTISAMPLE_RESOLVE_BOX 表示选择一像素宽的盒式过滤器，给予所有 multisample 相同的权重。EGL_MULTISAMPLE_RESOLVE 的默认值为EGL_MULTISAMPLE_RESOLVE_DEFAULT。注意仅当 EGL 版本为 1.4 或更高时才支持该属性。
- EGL_SWAP_BEHAVIOR：指定使用 eglSwapBuffers 函数激活 surface 时该 surface 的 color buffer 的效果。该属性的值可以设置为 EGL_BUFFER_PRESERVED 或者 EGL_BUFFER_DESTROYED。EGL_BUFFER_PRESERVED 表示 color buffer 内容不受影响，而 EGL_BUFFER_DESTROYED 表示颜色缓冲区内容可能会被操作破坏或更改。EGL_SWAP_BEHAVIOR 的初始值由 EGL 实现决定。

注意如果 pbuffer 的 EGL_TEXTURE_FORMAT 属性的值为 EGL_NO_TEXTURE，属性 EGL_TEXTURE_TARGET 的值为 EGL_NO_TEXTURE。

#### 函数错误

- eglSurfaceAttrib 函数执行失败时会返回 EGL_FALSE，否则会返回 EGL_TRUE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 attribute 入参值为 EGL_MULTISAMPLE_RESOLVE，value 入参值为 EGL_MULTISAMPLE_RESOLVE_BOX，并且用于创建 surface 的 EGLConfig 的 EGL_SURFACE_TYPE 属性不包含 EGL_MULTISAMPLE_RESOLVE_BOX_BIT，则会生成 EGL_BAD_MATCH 错误。
- 如果 attribute 入参值为 EGL_SWAP_BEHAVIOR，value 入参值为 EGL_BUFFER_PRESERVED，并且用于创建 surface 的 EGLConfig 的 EGL_SURFACE_TYPE 属性不包含 EGL_SWAP_BEHAVIOR_PRESERVED_BIT，则会生成 EGL_BAD_MATCH 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 surface 不是 EGL surface，则会生成 EGL_BAD_SURFACE 错误。
- 如果 attribute 不是有效的 surface 属性，则会生成 EGL_BAD_ATTRIBUTE 错误。

### eglCreateWindowSurface 函数

eglCreateWindowSurface 函数用于创建一个在屏幕上渲染的 EGL window surface 并返回它的句柄。eglCreateWindowSurface 函数的行为与 eglCreatePlatformWindowSurface 的行为相同，只是后者的 display 以及 native_window 的实际类型是视所属的平台而定，而前者是特定于 EGL 实现而定。eglCreateWindowSurface 函数的定义如下：

```c
EGLSurface eglCreateWindowSurface(
    EGLDisplay display,
    EGLConfig config,
    NativeWindowType native_window,
    EGLint const * attrib_list
)
```

eglCreateWindowSurface 函数会使用 display、config、native_window 和 attrib_list 创建对应的 EGLSurface。

- config 表示 EGL 帧缓冲区配置，该配置定义了 EGLSurface 可用的 frame buffer configuration 资源；
- native_window 的类型视 EGL 实现而定。在 Android 中，我们可以传入 SurfaceHolder 对象
- attrib_list 表示 window surface 的属性。可以为 NULL 或空(仅包含一个 EGL_NONE 属性值)。可用的 surface 属性有：
    - EGL_GL_COLORSPACE：指定渲染到 surface 时 OpenGL 和 OpenGL ES 使用的颜色空间。EGL_GL_COLORSPACE 的默认值为EGL_GL_COLORSPACE_LINEAR。请注意 EGL_GL_COLORSPACE 属性仅在支持 sRGB 帧缓冲区的 OpenGL 和 OpenGL ES 上下文中使用。EGL 本身不区分多个色彩空间模型。有关详细信息，可以阅读 OpenGL 4.6 和 OpenGL ES 3.2 规范的 "sRGB 转换" 部分。
       - 如果 EGL_GL_COLORSPACE 值为 EGL_GL_COLORSPACE_SRGB，则使用的是非线性、感知均匀的颜色空间，并且 GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 对应的值为 GL_SRGB。
       - 如果 EGL_GL_COLORSPACE 值为 EGL_GL_COLORSPACE_LINEAR，则使用的是线性颜色空间，并且 GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 对应的值为 GL_LINEAR。
   
    - EGL_RENDER_BUFFER：指定 client API 使用哪个 buffer(缓冲区)呈现数据到 window。EGL_RENDER_BUFFER 的默认值为 EGL_BACK_BUFFER。client API 可能不会重视此属性设置的渲染缓冲区。要确定 context 使用的实际缓冲区，可以调用 eglQueryContext 函数查询。
       - 如果其值为 EGL_SINGLE_BUFFER，则 client API 应直接呈现到可见窗口中。
       - 如果其值为 EGL_BACK_BUFFER，则 client API 应渲染到后台缓冲区中。

    - EGL_VG_ALPHA_FORMAT：指定渲染到 surface 时 OpenVG 如何解释 alpha 值。EGL_VG_ALPHA_FORMAT 的默认值为 EGL_VG_ALPHA_FORMAT_NONPRE。
       - 如果其值为 EGL_VG_ALPHA_FORMAT_NONPRE，则不预乘(premultipled) alpha 值。
       - 如果其值为 EGL_VG_ALPHA_FORMAT_PRE，则预乘 alpha 值。

    - EGL_VG_COLORSPACE：指定渲染到 surface 时 OpenVG 使用的颜色空间。EGL_VG_COLORSPACE 的默认值为 EGL_VG_COLORSPACE_sRGB。
       - 如果其值为 EGL_VG_COLORSPACE_sRGB，则使用的是非线性、感知均匀的颜色空间，并具有 VG_s* 形式的对应的 VGImageFormat。
       - 如果其值为 EGL_VG_COLORSPACE_LINEAR，则使用的是线性颜色空间，并具有 VG_l* 形式的对应的 VGImageFormat。

任何根据 config 入参创建的 EGL 渲染上下文都可用于渲染到 surface 中。可以使用 eglMakeCurrent 函数可以将 EGL 渲染上下文添加到 surface，可以使用 eglQuerySurface 函数获取 config 的 ID，可以使用 eglDestroySurface 函数销毁 surface。

#### 函数错误

- 如果 eglCreateWindowSurface 创建 window surface 失败，则会返回 EGL_NO_SURFACE。
- 如果 display 和 native_window 不属于同一平台，则会出现未知的行为。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 config 不是有效的 EGL frame buffer configuration，则会生成 EGL_BAD_CONFIG 错误。
- 如果 native_window 不是与 display 相同平台的有效 native window，则可能会生成 EGL_BAD_NATIVE_WINDOW 错误。
- 如果 attrib_list 包含无效的 window 属性，或者属性值无法识别，或着属性值超出范围，则会生成 EGL_BAD_ATTRIBUTE 错误。
- 如果已经存在与 native_window 关联的 EGLSurface(即针对该 native_window，已经调用过 eglCreateWindowSurface 函数，并且调用成功)，则生成 EGL_BAD_ALLOC 错误。
- 如果 EGL 实现无法为新的 EGL window 分配资源，则会生成 EGL_BAD_ALLOC 错误。
- 如果 native_window 的像素格式与 config 所需的 color buffers 的格式、类型和尺寸不匹配，则会生成 EGL_BAD_MATCH 错误。
- 如果 config 不支持渲染到 window(EGL_SURFACE_TYPE 属性不包含 EGL_WINDOW_BIT)，则会生成 EGL_BAD_MATCH 错误。
- 如果 config 不支持指定的 OpenVG alpha format 属性或者 colorspace 属性。则会生成 EGL_BAD_MATCH 错误。
    - 不支持 OpenVG alpha format 属性是指 EGL_VG_ALPHA_FORMAT 的值为 EGL_VG_ALPHA_FORMAT_PRE，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_ALPHA_FORMAT_PRE_BIT。
    - 不支持 OpenVG colorspace 属性是指 EGL_VG_COLORSPACE 的值为 EGL_VG_COLORSPACE_LINEAR，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_COLORSPACE_LINEAR_BIT。

#### 代码示例

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

### eglCreatePbufferSurface 函数

eglCreatePbufferSurface 函数的定义如下：

```c
EGLSurface eglCreatePbufferSurface(
    EGLDisplay display,
    EGLConfig config,
    EGLint const * attrib_list
)
```

eglCreatePbufferSurface 用于创建一个离屏像素缓冲区表面(off-screen pixel buffer surface)并返回其句柄。如果 eglCreatePbufferSurface 函数无法创建 Pbuffer Surface，则会返回 EGL_NO_SURFACE。

OpenGL ES 除了可以渲染在屏幕上的窗口外，还可以渲染被称为 Pbuffer(像素缓冲区 Pixel buffer 的简写) 的屏幕外不可见表面(离屏 Surface)。和 window 一样，Pbuffer 可以利用 OpenGL ES 中的任何硬件加速。Pbuffer 常用于生成纹理贴图。当然，如果想要渲染到一个纹理，建议使用 frame buffer 对象代替 Pbuffer，因为 frame buffer 更高效。不过，在某些 frame buffer 无法使用的情况下，Pbuffer 仍然有效。比如用 OpenGL ES 渲染屏幕外 surface，然后将其作为其他 API(如 OpenVG)中的纹理。

和 window 一样，Pbuffer 支持 OpenGL ES 的所有渲染机制。主要的区别是：

- 窗口：渲染的内容可以在屏幕上显示，渲染完成时，需要交换缓冲区。
- Pbuffer：渲染的内容无法在屏幕上显示，渲染完成时，无需交换缓冲区。而是从 Pbuffer 中将数值直接复制到应用程序，或者是将 Pbuffer 的绑定更改为纹理，则 Pbuffer 的渲染对目标纹理生效。

config 入参代表了 surface 需要用到的 EGL frame buffer configuration，config 中定义了 surface 可用的 frame buffer 资源。config 的 EGL_SURFACE_TYPE 需要包含 EGL_PBUFFER_BIT 值。

attrib_list 入参代表 surface 的属性列表，属性列表内容的格式为键值对，以 EGL_NONE 终止。例如：\[attr1, attr1Value, attr2, attr2Value, EGL_NONE]。属性列表接受的属性有：

- EGL_GL_COLORSPACE：指定渲染到 surface 时 OpenGL 和 OpenGL ES 使用的颜色空间。EGL_GL_COLORSPACE 的默认值为 EGL_GL_COLORSPACE_LINEAR。注意仅当 EGL 版本为 1.5 或更高时才支持该属性。另外注意 EGL_GL_COLORSPACE 属性仅由支持 sRGB 帧缓冲区的 OpenGL 和 OpenGL ES 上下文使用。EGL 本身不区分多个色彩空间模型。更详细的讲解可以参阅 OpenGL 4.6 和 OpenGL ES 3.2 规范的 "sRGB 转换" 部分。
    - 如果其值为 EGL_GL_COLORSPACE_SRGB，则为非线性、感知均匀的颜色空间，对应的 GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 值为 GL_SRGB。
    - 如果其值为 EGL_GL_COLORSPACE_LINEAR，则为线性颜色空间，对应的 GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 值为 GL_LINEAR。

- EGL_WIDTH：指定 Pbuffer Surface 所需的宽度。默认值为 0。注意如果 config 的 EGL_TEXTURE_FORMAT 属性的值不是 EGL_NO_TEXTURE，则 level 为 0 的纹理图像的大小会使用 pbuffer 的宽度和高度。
- EGL_HEIGHT：指定 Pbuffer Surface 所需的高度。默认值为 0。注意如果 config 的 EGL_TEXTURE_FORMAT 属性的值不是 EGL_NO_TEXTURE，则 level 为 0 的纹理图像的大小会使用 pbuffer 的宽度和高度。
- EGL_LARGEST_PBUFFER：当分配失败时请求最大可用的 Pbuffer Surface。可以使用 eglQuerySurface 函数获取分配的像素缓冲区的尺寸。属性默认值为 EGL_FALSE。注意如果指定了 EGL_LARGEST_PBUFFER，并且 pbuffer 将用作纹理(即 EGL_TEXTURE_TARGET 的值为 EGL_TEXTURE_2D，并且 EGL_TEXTURE FORMAT 的值为 EGL_TEXTURE_RGB 或 EGL_TEXTURE_RGBA)，则将保留宽高比，并且新的宽度和高度将是纹理目标的有效大小(例如底层 OpenGL ES 实现不支持非 2 的幂的纹理，则新宽高都是 2 的幂)。
- EGL_MIPMAP_TEXTURE：指定是否应为 mipmap 分配存储空间。如果属性值为 EGL_TRUE 并且 EGL_TEXTURE_FORMAT 不是 EGL_NO_TEXTURE，则将预留 mipmap 的空间。属性默认值为 EGL_FALSE。
- EGL_TEXTURE_FORMAT：指定当 pbuffer 绑定到纹理贴图时将创建纹理的格式。可取值为 EGL_NO_TEXTURE、EGL_TEXTURE_RGB 和 EGL_TEXTURE_RGBA。属性默认值为 EGL_NO_TEXTURE。
- EGL_TEXTURE_TARGET：指定当使用 EGL_TEXTURE_RGB 或 EGL_TEXTURE_RGBA 纹理格式创建 pbuffer 时将创建纹理的目标。可能的值为 EGL_NO_TEXTURE 或 EGL_TEXTURE_2D。属性默认值为 EGL_NO_TEXTURE。
- EGL_VG_ALPHA_FORMAT：指定渲染到 surface 时，OpenVG 对 alpha 值的解释器。如果其值为 EGL_VG_ALPHA_FORMAT_NONPRE，则不预乘 alpha 值。如果其值为 EGL_VG_ALPHA_FORMAT_PRE，则预乘 alpha 值。默认值为 EGL_VG_ALPHA_FORMAT_NONPRE。
- EGL_VG_COLORSPACE：指定渲染到 surface 时，OpenVG 使用的颜色空间。如果其值为 EGL_VG_COLORSPACE_sRGB，则为非线性、感知均匀的颜色空间，并具有 VG_s* 形式的 VGImageFormat。如果其值为 EGL_VG_COLORSPACE_LINEAR，则为线性颜色空间，并具有 VG_l* 形式的 VGImageFormat。默认值为EGL_VG_COLORSPACE_sRGB。

注意当将纹理渲染到 pbuffer 并切换纹理的渲染图像时(例如从渲染一个 mipmap level 切换到渲染另一 level)，深度和模板缓冲区的内容可能不会被保留。

另外任何根据 config 入参创建的 EGL 渲染上下文都可用于渲染到 surface 中。可以使用 eglMakeCurrent 函数可以将 EGL 渲染上下文添加到 surface，可以使用 eglQuerySurface 函数获取 config 的 ID，可以使用 eglDestroySurface 函数销毁 surface。

注：eglCreatePixmapSurface 函数的功能和定义与 eglCreatePbufferSurface 函数类似，二者都是创建离屏 Surface，只不过一个是 Pixmap Surface，一个是 Pbuffer Surface。本文就不细讲了，感兴趣的可以看官方文档：https://registry.khronos.org/EGL/sdk/docs/man/html/eglCreatePixmapSurface.xhtml

#### 函数错误

- 如果函数执行失败，则会返回 EGL_NO_SURFACE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 config 不是有效的 EGL frame buffer configuration，则会生成 EGL_BAD_CONFIG 错误。
- 如果 attrib_list 包含无效的属性或者属性值无法识别或超出范围，则会生成 EGL_BAD_ATTRIBUTE 错误。
- 如果 attrib_list 包含 EGL_MIPMAP_TEXTURE、EGL_TEXTURE_FORMAT 或 EGL_TEXTURE_TARGET 属性中的任何一个，并且 config 不支持 OpenGL ES 渲染(例如 EGL 版本为 1.2 或更高版本，并且 config 的 EGL_RENDERABLE_TYPE 属性不包含 EGL_OPENGL_ES_BIT、EGL_OPENGL_ES2_BIT 或 EGL_OPENGL_ES3_BIT 之一)，则会生成 EGL_BAD_ATTRIBUTE 错误,
- 如果没有足够的资源来分配新 surface，则会生成 EGL_BAD_ALLOC 错误。
- 如果 config 不支持渲染到像素缓冲区(EGL_SURFACE_TYPE 属性不包含 EGL_PBUFFER_BIT)，则会生成 EGL_BAD_MATCH 错误。
- 如果 EGL_TEXTURE_FORMAT 属性不是 EGL_NO_TEXTURE，并且 EGL_WIDTH 和 EGL_HEIGHT 指定了无效的大小(例如底层 OpenGL ES 实现不支持非 2 的幂的纹理，但纹理尺寸指定了非 2 的幂的宽高)，则会生成 EGL_BAD_MATCH 错误。
- 如果 EGL_TEXTURE_FORMAT 属性是 EGL_NO_TEXTURE，并且 EGL_TEXTURE_TARGET 不是 EGL_NO_TEXTURE；或者 EGL_TEXTURE_FORMAT 不是 EGL_NO_TEXTURE，并且 EGL_TEXTURE_TARGET 是 EGL_NO_TEXTURE。则会生成 EGL_BAD_MATCH 错误。
- 如果 config 不支持指定的 OpenVG alpha format 属性或 colorspace 属性，则会生成 EGL_BAD_MATCH 错误。
    - 不支持 OpenVG alpha format 属性是指 EGL_VG_ALPHA_FORMAT 的值为 EGL_VG_ALPHA_FORMAT_PRE，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_ALPHA_FORMAT_PRE_BIT。
    - 不支持 OpenVG colorspace 属性是指 EGL_VG_COLORSPACE 的值为 EGL_VG_COLORSPACE_LINEAR，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_COLORSPACE_LINEAR_BIT。

### eglCreatePlatformPixmapSurface 函数

EGL 还支持渲染 color buffers 存储在 native pixmaps 中的 surface。
- Pixmaps 与 windows 的不同之处在于，其通常被分配在离屏(不可见)的显存或者内存中。
- Pixmaps 与 pbuffer 的不同之处在于，其确实具有关联的 native pixmap 和 native pixmap 类型，并且可以使用 client API 以外的 API 渲染数据到 pixmaps，即 client API 和 native API。

要创建 Pixmap Surface，我们可以使用 eglCreatePlatformPixmapSurface 或者 eglCreatePixmapSurface 函数。二者的功能除了  display 限定的范围外，完全相同。前者的 display 参数限定了平台集，后者的 display 的实际类型是取决于特定的 EGL 实现。本文以 eglCreatePlatformPixmapSurface 函数为例，说明下相关内容。注意 eglCreatePlatformPixmapSurface 仅支持 EGL 1.5 及以上的版本。

要创建 pixmap rendering surface，需要使用以下步骤：
- 首先要创建 native platform pixmap
- 然后使用包含 EGL_MATCH_NATIVE_PIXMAP 的属性列表，调用 eglChooseConfig 函数获取与属性列表中指定的 pixmap 的 pixel format 匹配的 EGLConfig
- 最后调用 eglCreatePlatformPixmapSurface 函数，创建 pixmap rendering surface。

eglCreatePlatformPixmapSurface 函数的定义如下：

```c
EGLSurface eglCreatePlatformPixmapSurface(
    EGLDisplay display,
    EGLConfig config,
    void * native_pixmap,
    EGLint const * attrib_list
)
```

```c
EGLSurface eglCreatePixmapSurface(
    EGLDisplay display,
    EGLConfig config,
    NativePixmapType native_pixmap,
    EGLint const * attrib_list
)
```

eglCreatePlatformPixmapSurface 函数创建一个离屏 EGLSurface，并返回它的句柄。使用兼容的 EGLConfig 创建的任何 EGL 上下文都可以渲染到此 surface。

native_pixmap 必须与 display、返回的 EGLSurface 属于同一平台。定义 display 所属平台的扩展也需要指定 native_pixmap 参数的要求。如果 native_pixmap 和 display 不属于同一平台，则会出现未知行为(EGL 未定义这部分行为)。

attrib_list 用于指定 pixmap 的属性列表。该列表的结构与 eglChooseConfig 中使用的结构相同(属性键值对，以 EGL_NONE 结尾)。可以在 attrib_list 中指定的属性包括 EGL_GL_COLORSPACE、EGL_VG_COLORSPACE 和 EGL_VG_ALPHA_FORMAT。attrib 列表可以为 NULL 或空(第一个属性为 EGL_NONE)，在这种情况下，所有属性均采用其默认值。注意，某些平台可能会定义额外的附加属性，作为 EGL 的扩展。

EGL_GL_COLORSPACE、EGL_VG_COLORSPACE 和 EGL_VG_ALPHA_FORMAT 的含义和默认值与在 eglCreatePlatformWindowSurface 中使用时相同。

生成的 pixmap surface 包含由 config 指定的颜色和辅助缓冲区。pixmap 中存在的缓冲区(通常只是颜色缓冲区)将绑定到 EGL。pixmap 中不存在的缓冲区(例如深度和模板缓冲区(config 需要包含这些缓冲区))将由 EGL 进行分配，其分配方式与使用 eglCreatePbufferSurface 函数创建的 surface 相同。

#### 函数错误

- 如果 display 和 native_pixmap 不属于同一平台，则会发生未知行为。
- 如果 surface 创建失败，则返回 EGL_NO_SURFACE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 config 不是 EGL config，则会生成 EGL_BAD_CONFIG 错误。
- 如果 native_pixmap 不是有效的 native pixmap，则可能会生成 EGL_BAD_NATIVE_PIXMAP 错误。
- 如果 attrib_list 包含无效的 pixmap 属性或者属性的值无法识别或超出范围，则会生成 EGL_BAD_ATTRIBUTE 错误。
- 如果已经存在与 native_pixmap 关联的 EGLSurface(先前调用 eglCreatePlatformPixmapSurface 生成的结果)，则会生成 EGL_BAD_ALLOC 错误。
- 如果 EGL 实现无法为新的 EGL window 分配资源，则会生成 EGL_BAD_ALLOC 错误。
- 如果 native_pixmap 的属性与 config 中的不对应或者 config 不支持渲染到 pixmap(EGL_SURFACE_TYPE属性不包含EGL_PIXMAP_BIT)，则会生成 EGL_BAD_MATCH 错误。
- 如果 config 不支持指定的 OpenVG alpha format 属性或 colorspace 属性，则会生成 EGL_BAD_MATCH 错误。
    - 不支持 OpenVG alpha format 属性是指 EGL_VG_ALPHA_FORMAT 的值为 EGL_VG_ALPHA_FORMAT_PRE，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_ALPHA_FORMAT_PRE_BIT。
    - 不支持 OpenVG colorspace 属性是指 EGL_VG_COLORSPACE 的值为 EGL_VG_COLORSPACE_LINEAR，并且 config 的 EGL_SURFACE_TYPE 属性未设置 EGL_VG_COLORSPACE_LINEAR_BIT。

## 7. 创建一个渲染上下文

渲染上下文是 OpenGL ES 的内部数据结构，包含 OpenGL ES 操作所需的所有状态信息。在 OpenGL ES 中，必须要有个上下文才能绘图。OpenGL ES 提供了下列函数，用于和 Context 交互：

- eglCreateContext
- eglDestroyContext
- eglGetCurrentContext
- eglQueryContext

![创建一个渲染上下文](/imgs/创建一个渲染上下文.webp)

### eglCreateContext 函数

我们可以使用 eglCreateContext 函数创建上下文，eglCreateContext 函数的定义如下：

```c
EGLContext eglCreateContext(
    EGLDisplay display,
    EGLConfig config,
    EGLContext share_context,
    EGLint const * attrib_list
)
```
eglCreateContext 函数为当前渲染 API (使用eglBindAPI 设置)创建一个 EGL 渲染上下文并返回该上下文的句柄。然后可以使用上下文渲染到 EGL 绘图表面。函数执行成功时，会返回一个指向新创建上下文的句柄。如果失败，则会返回 EGL_NO_CONTEXT，并设置如以下错误码(不全，官方文档未说明。以实际返回为准)：

- EGL_BAD_CONFIG   配置无效

如果 share_context 不是 EGL_NO_CONTEXT，则当前创建的上下文中的所有可共享数据(由当前渲染 API 的 client API 规范定义)都与上下文 share_context 共享，这种共享是可传递的，即与 share_context 共享数据的所有其他上下文共享。但是，共享数据的所有渲染上下文本身必须存在于同一地址空间中。如果两个渲染上下文都由单个进程拥有，则它们需共享一个地址空间。EGL_NO_CONTEXT 表示不共享。

attrib_list 指定 EGLContext 的属性列表。该列表具有与 eglChooseConfig 所描述的结构相同的结构。可以指定的属性和属性值如下：

- EGL_CONTEXT_MAJOR_VERSION：指定所请求的 OpenGL 或 OpenGL ES 上下文的主版本。后面必须跟一个整数，默认值为 1。此属性是旧版 EGL_CONTEXT_CLIENT_VERSION 的别名，并且可以互换使用。
- EGL_CONTEXT_MINOR_VERSION：指定所请求的 OpenGL 或 OpenGL ES 上下文的次版本。后面必须跟一个整数，默认值为 0。
- EGL_CONTEXT_OPENGL_PROFILE_MASK：指定 OpenGL 上下文的配置。后面必须跟一个整数 bitmask，可以设置的 bitmask 包括用于核心配置的 EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT 和用于兼容性配置的 EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT。默认值为 EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT。所有 OpenGL 3.2 及更高版本的实现都需要实现 EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT，但 EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT 的实现是可选的。
- EGL_CONTEXT_OPENGL_DEBUG：指定是否创建 OpenGL 或 OpenGL ES 调试上下文。EGL_TRUE 表示创建调试上下文，EGL_FALSE 表示创建非调试上下文。默认值为 EGL_FALSE。
- EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE：指定是否创建向前兼容的 OpenGL 上下文。EGL_TRUE 表示创建向前兼容的上下文，EGL_FALSE 表示创建非向前兼容的上下文。默认值为 EGL_FALSE。
- EGL_CONTEXT_OPENGL_ROBUST_ACCESS：指定是否创建支持访问 robust buffer 的上下文。EGL_TRUE 表示支持访问 robust buffer，EGL_FALSE 表示不支持。默认值为 EGL_FALSE。
- EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY：可取值为 EGL_LOSE_CONTEXT_ON_RESET、EGL_NO_RESET_NOTIFICATION。如果 EGL_CONTEXT_OPENGL_ROBUST_ACCESS 属性未设置为 EGL_TRUE，则指定了重置策略的上下文创建不会失败，但生成的上下文可能不支持访问 robust buffer，因此可能不支持指定的重置通知策略。EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY 的默认值为 EGL_NO_RESET_NOTIFICATION。
    - EGL_LOSE_CONTEXT_ON_RESET 表示应创建具有重置通知行为 GL_LOSE_CONTEXT_ON_RESET_ARB 的 OpenGL 或 OpenGL ES 上下文。
    - EGL_NO_RESET_NOTIFICATION 表示指定应创建具有重置通知行为 GL_NO_RESET_NOTIFICATION_ARB 的 OpenGL 或 OpenGL ES 上下文

注意上下文的属性之间有许多其他可能的交互，具体取决于 EGL 实现支持的 API 版本和扩展。这些交互在 EGL 1.5 规范中进行了详细描述，但为了简洁起见，此处未列出。当所请求的属性可能无法满足时，上下文创建仍可能成功。应用程序应确保 OpenGL 或 OpenGL ES 上下文在使用之前支持所需的功能，方法是使用运行时查询确定实际上下文版本、支持的扩展和支持的上下文标志。

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

### eglDestroyContext 函数

我们可以使用 eglDestroyContext 函数销毁创建出来的 EGLContext。eglDestroyContext 函数的定义如下：

```c

EGLBoolean eglDestroyContext(EGLDisplay display, EGLContext context)
```

如果 context 入参不是任何线程的当前 context，则 eglDestroyContext 函数会立即销毁该 context。否则，该 context 会一直到不再是任何线程的当前 context 时才销毁。

- 如果 eglDestroyContext 执行失败，上下文销毁失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。
- 如果 display 不是 EGL display connectio，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 context 不是 EGL 渲染上下文，则会生成 EGL_BAD_CONTEXT 错误。

### eglGetCurrentContext 函数

eglGetCurrentContext 函数用于返回当前的由 eglMakeCurrent 指定的 EGL 渲染上下文。如果没有当前上下文，则会返回 EGL_NO_CONTEXT。eglGetCurrentContext 函数的定义如下：

```c
EGLContext eglGetCurrentContext(void)
```

### eglQueryContext 函数

我们可以使用 eglQueryContext 函数获取 context 的相关信息。eglQueryContext 函数的定义如下：

```c
EGLBoolean eglQueryContext(
    EGLDisplay display,
    EGLContext context,
    EGLint attribute,
    EGLint * value
)
```

eglQueryContext 函数会返回与 display 关联的 context 的 attribute 的值，结果由 value 承载。attribute 的可取值有：

- EGL_CONFIG_ID：返回创建 context 时用到的 EGL frame buffer configuration 的 ID。
- EGL_CONTEXT_CLIENT_TYPE：返回 context 支持的客户端 API 类型，取值为 EGL_OPENGL_API、EGL_OPENGL_ES_API 或 EGL_OPENVG_API 之一。
- EGL_CONTEXT_CLIENT_VERSION：返回 context 支持的创建时指定的客户端 API 版本。该结果值仅对 OpenGL ES 上下文有意义。
- EGL_RENDER_BUFFER：返回通过 context 渲染的客户端 API 将使用的缓冲区。返回的值取决于 context 的属性以及 context 所绑定到的 surface：
    - 如果上下文绑定到 pixmap surface，则将返回 EGL_SINGLE_BUFFER。
    - 如果上下文绑定到 pbuffer surface，则将返回 EGL_BACK_BUFFER。
    - 如果上下文绑定到 window surface，则可以返回 EGL_BACK_BUFFER 或 EGL_SINGLE_BUFFER。返回的值取决于 surface 的 EGL_RENDER_BUFFER 属性设置的缓冲区(可以通过调用 eglQuerySurface 来查询)和客户端 API(并非所有客户端 API 都支持 single-buffer 渲染到 window surface)。
    - 如果上下文未绑定到 surface，例如 OpenGL ES 上下文绑定到了 framebuffer对象，则将返回 EGL_NONE。

#### 函数错误

- 函数执行失败时返回 EGL_FALSE，否则返回 EGL_TRUE。返回 EGL_FALSE 时，value 的值不会被修改。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 context 不是 EGL 渲染上下文，则会生成 EGL_BAD_CONTEXT 错误。
- 如果 attribute 不是有效的上下文属性，则会生成 EGL_BAD_ATTRIBUTE 错误。

## 8. 指定某个 EGLContext 为当前上下文

终于，我们来到了最后一步，完成这一步后，我们就能开始渲染了。

因为一个应用程序可能创建多个 EGLContext 用于不同的用途，所以我们需要关联特定的 EGLContext 和渲染表面。这一步骤通常叫做 "指定当前上下文"。我们可以使用 eglMakeCurrent 函数关联特定的 EGLContext 和 EGLSurface。eglMakeCurrent 函数的定义如下：

```c
EGLBoolean eglMakeCurrent(
    EGLDisplay display,
    EGLSurface draw,
    EGLSurface read,
    EGLContext context
)
```

eglMakeCurrent 将 context 绑定到当前渲染线程，以及绑定到 draw 和 read surface。注意 eglMakeCurrent 函数需要两个 EGLSurface 表面。尽管这种方法具有灵活性(在 EGL 的高级用法中将被利用到)，但是通常我们把 draw 和 read 设置为同一个值，即我们前面创建的渲染表面(window surface或者 Pbuffer surface)。注意，因为 EGL 规范要求 EGL 实现 eglMakeCurrent 函数时需要进行一次刷新，所以这一调用对于基于图块的架构代价很高。

对于 OpenGL 或 OpenGL ES 上下文，draw surface 可用于所有数据操作，除了读回或复制的任何像素数据之外(见 glReadPixels、glCopyTexImage2D 和 glCopyTexSubImage2D 函数)，这些数据取自 read surface 的 frame buffer。注意 EGLSurface 同时 read 和 draw。

对于 OpenVG 上下文，必须为 read 和 draw 操作指定相同的 EGLSurface。

如果调用线程已经具有当前渲染上下文，并且该上下文与 context 入参的 client API 类型相同，则该上下文将被 flush 并标记为不再是当前上下文。context 入参将被设置为调用线程的当前上下文。出于 eglMakeCurrent 函数的目的，OpenGL ES 和 OpenGL context 的所有 client API 的类型被视为相同。换句话说，就 eglMakeCurrent 函数而言，OpenGL ES 上下文和 OpenGL 上下文是类型兼容的。

OpenGL 和 OpenGL ES 的例如由 glMapBuffer 函数创建的缓冲区映射不受 eglMakeCurrent 函数影响；无论拥有该缓冲区的上下文是否是当前上下文，它们都会一直存在。

如果调用 eglMakeCurrent 函数后 draw surface 被销毁，那么后续的渲染命令仍然将被处理，并且 context 的状态仍将更新，但 surface 的行为会不可知(变成未定义的状态)。如果在调用 eglMakeCurrent 函数后 read surface 被破坏，则从帧缓冲区读取的像素值(例如调用 glReadPixels 函数的结果数据)是未定义的。如果 read 或 draw surface 下的 native window 或 pixmap 被破坏，则渲染和读回操作将按上述方式处理。

如果要释放当前上下文而不分配一个新的上下文，需要将上下文设置为 EGL_NO_CONTEXT 并将 read 和 draw surface 设置为 EGL_NO_SURFACE。在这之后，当前渲染 API 指定的客户端 API 的当前绑定上下文将被 flush 并标记为不再是当前上下文，并且在eglMakeCurrent 函数返回后，该客户端 API 将不再有当前上下文。

如果 context 入参的值不是 EGL_NO_CONTEXT，则 read 和 draw surface 都不能是 EGL_NO_SURFACE，除非 context 是支持在没有 read 和 draw surface 时可以绑定的上下文。此时 context 将变为当前上下文，而无需默认帧缓冲区。其含义由客户端 API 定义(详细说明请参阅 OpenGL 3.0 规范的第 4 章和 GL_OES_surfaceless_context OpenGL ES 扩展)。

第一次将 OpenGL 或 OpenGL ES 上下文设为当前上下文时，视口和裁剪区域的尺寸会设置为 draw surface 的大小，就好像调用了 glViewport(0,0,w,h) 和 glScissor(0,0,w,h) 函数一样，其中 w 和 h 是表面的宽度和高度。但是，后续的当前上下文设置操作不会改变视口和裁剪区域的尺寸。此时由客户端负责重置视口和裁剪区域。

第一次将上下文设置为当前上下文时，如果它没有默认帧缓冲区(例如，read 和 draw surface 都是 EGL_NO_SURFACE)，则视口和裁剪区域将被设置为如调用了 glViewport(0,0,0,0) 和 glScissor(0,0,0,0) 一样的效果。

EGL 的实现可能会延迟 surface 的辅助缓冲区的分配，直到 context 需要它们为止(这可能会导致前面提到的 EGL_BAD_ALLOC 错误)。然而，一旦辅助缓冲区被分配，则辅助缓冲区及其内容将持续存在，直到 surface 被删除为止。

我们可以使用 eglGetCurrentContext、eglGetCurrentDisplay 和 eglGetCurrentSurface 函数查询当前渲染 Context 以及关联的 Display 和Surface。

### 函数错误

- 如果 Surface 与 Context 不兼容，则会生成 EGL_BAD_MATCH 错误。
- 如果 Context 已被其他线程设置为当前上下文，或者如果 Surface 已被绑定到另一个线程中的当前上下文，则会生成 EGL_BAD_ACCESS 错误。
- 如果绑定上下文超出 EGL 实现支持的对应客户端 API 类型的当前上下文数量，则会生成 EGL_BAD_ACCESS 错误。
- 如果 read 和 draw surface (入参 Surface)是使用 eglCreatePbufferFromClientBuffer 创建的 pbuffer，并且底层的缓冲区正在由创建它们的客户端 API 使用，则会生成 EGL_BAD_ACCESS 错误。
- 如果 Context 不是有效的上下文并且不是 EGL_NO_CONTEXT，则会生成 EGL_BAD_CONTEXT 错误。
- 如果 Surface 不是有效的 EGL Surface 且不是 EGL_NO_SURFACE，则会生成 EGL_BAD_SURFACE 错误。
- 如果上下文是 EGL_NO_CONTEXT 并且 Surface 不是 EGL_NO_SURFACE，则会生成 EGL_BAD_MATCH 错误。
- 如果 read 和 draw surface 中的一个是有效 Surface，而另一个是 EGL_NO_SURFACE，则会生成 EGL_BAD_MATCH 错误。
- 如果 Context 不支持在没有 read 和 draw surface 的情况下进行绑定，并且 read 和 draw surface 都是 EGL_NO_SURFACE，则会生成 EGL_BAD_MATCH 错误。
- 如果 read 和 draw surface 底层的 native window 不再有效，则会生成 EGL_BAD_NATIVE_WINDOW 错误。
- 如果 read 和 draw surface 无法同时装入显存，则会生成 EGL_BAD_MATCH 错误。
- 如果调用线程的前一个当前上下文是未 flush 的，并且先前的 surface 不再有效，则会生成 EGL_BAD_CURRENT_SURFACE 错误。
- 如果无法分配用于 read 和 draw surface 的辅助缓冲区，则会生成 EGL_BAD_ALLOC 错误。
- 如果发生电源管理事件，则会生成 EGL_CONTEXT_LOST 错误。
- 如果 display 是有效但未初始化的，并且同时出现以下情况之一，会生成 EGL_NOT_INITIALIZED 错误：
    - 上下文不是 EGL_NO_CONTEXT
    - read surface 不是 EGL_NO_SURFACE
    - draw surface 不是 EGL_NO_SURFACE
- 如果 display 不是有效的 EGLDisplay 句柄，则会生成 EGL_BAD_DISPLAY 错误(某些 EGL 实现允许 EGL_NO_DISPLAY 作为 eglMakeCurrent 的有效显示参数。此行为不能移植到所有 EGL 实现，并且应被视为未记录的供应商扩展)。

讲述完用 EGL 渲染前的所有准备后，我们就可以开始渲染了。

## 步骤整合与代码示范

从 1 到 8 步为 EGL 的初始化流程。下面是一段 EGL 初始化示范代码。可能无法运行，但是说明了 EGL 执行与初始化的流程。总体流程如下：

![步骤整合与代码示范](/imgs/步骤整合与代码示范.webp)

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

EGL 初始化完成后，后面的内容是如何渲染数据到 EGL。

## 9. 渲染数据到 Textures

### 绑定 Surface 到 OpenGL ES Texture

本节介绍如何使用 pbuffer surface 渲染到 OpenGL ES 纹理(texture)。注意，如果 pbuffer surface 不支持 OpenGL ES 渲染，或者如果平台上没有实现 OpenGL ES，则调用 eglBindTexImage 或 eglReleasTexImage 函数将始终生成 EGL_BAD_SURFACE 错误。

我们可以使用 eglBindTexImage 函数绑定纹理图像，eglBindTexImage 函数的定义如下：

```c
EGLBoolean eglBindTexImage(
    EGLDisplay display,
    EGLSurface surface,
    EGLint buffer
)
```

eglBindTexImage 函数定义了二维纹理图像(two-dimensional texture image)，会将 surface 绑定为纹理。纹理图像由指定 surface 的 buffer 中的图像数据组成，不需要复制。截止 EGL 1.5 版本，buffer 唯一接受的值是 EGL_BACK_BUFFER，它表示该缓冲区中正在进行 OpenGL ES 渲染。

纹理目标(texture target)、纹理格式(texture format)和纹理组件的尺寸(texture components size)源自指定 surface 的属性，该 surface 必须是支持 EGL_BIND_TO_TEXTURE_RGB 或 EGL_BIND_TO_TEXTURE_RGBA 属性之一的 pbuff。注意，调用 eglBindTexImage 函数后，与纹理对象的不同 mipmap 级别关联的任何现有图像都将被释放。

pbuffer 的 EGL_TEXTURE_FORMAT 属性用于确定纹理的基本内部格式。下列 pbuffer 的属性也用于决定纹理组件的尺寸：

![pbuffer](/imgs/pbuffer.webp)

纹理目标源自 surface 的 EGL_TEXTURE_TARGET 属性。如果属性值为 EGL_TEXTURE_2D，则 buffer 为绑定到 current context 的二维纹理对象(two-dimensional texture，以下简称当前纹理对象(current texture object))定义一个纹理。

如果 display 和 surface 是调用线程当前上下文的 display 和 Surface，则 eglBindTexImage 函数会执行隐式 glFlush 函数。对于其他 surface，eglBindTexImage 函数会在定义纹理图像之前，等待所有先前发出的绘制到 surface 的 client API 命令完成，就像在该 surface 绑定的最后一个上下文上调用 glFinish 一样。

调用 eglBindTexImage 函数后，指定的 surface 不可再用于 reading 或 writing。任何从 surface 的颜色缓冲区或辅助缓冲区读取数据的读取操作(例如 glReadPixels 和 eglCopyBuffers)，都将产生不确定的结果。此外，在从纹理释放颜色缓冲区之前对 surface 执行的绘制操作，也会产生不确定的结果。具体来说，如果 surface 对于上下文和线程来说是当前的，则渲染命令仍将被处理，上下文状态仍将更新，但数据可能会也可能不会被写入 surface。对绑定到纹理的 surface 调用 eglSwapBuffers 函数，不会有效果。

OpenGL ES 以外的 client API 也可以渲染到之后绑定为纹理的 surface。如果 surface 对于 OpenGL ES 以外的 client API 的上下文来说，是当前的 surface 时，将 surface 绑定为 OpenGL ES 纹理的效果通常与上述效果类似，但可能存在其他限制。要执行这种绑定操作，所有 client API 的上下文中都应解除与该 surface 的绑定，然后 app 才可以使用混合模式渲染到纹理。

注意，如果颜色缓冲区被绑定到纹理对象，并且纹理对象在上下文之间共享，则颜色缓冲区也会被共享。如果在调用 eglReleaseTexImage 之前删除纹理对象，则颜色缓冲区会被释放，并且 surface 会变为可读写。

当调用 eglBindTexImage 时，如果满足以下所有条件，则会自动生成纹理 mipmap 级别(texture mipmap levels)：

- 被绑定的 pbuffer 的 EGL_MIPMAP_TEXTURE 属性为 EGL_TRUE
- 对于当前被绑定的纹理，OpenGL ES 的 GL_GENERATE_MIPMAP 纹理参数为 GL_TRUE
- 绑定的 pbuffer 的 EGL_MIPMAP_LEVEL 属性的值等于 GL_TEXTURE_BASE_LEVEL 纹理参数的值

虽然调用 glTexImage2D 或 glCopyTexImage2D 函数来替换，绑定了颜色缓冲区的纹理对象的图像，不是一个错误。然而，这些调用将导致颜色缓冲区被释放回 surface，并且将为纹理分配新的内存。

注意，如果没有当前渲染上下文，则 eglBindTexImage 命令将被忽略。

#### 函数错误

- 如果 buffer 已经绑定为了一个 texture，则会生成 EGL_BAD_ACCESS 错误。
- 如果 surface 的 EGL_TEXTURE_FORMAT 属性设置为 EGL_NO_TEXTURE，则会生成 EGL_BAD_MATCH 错误。
- 如果 buffer 不是有效的 buffer，则生成 EGL_BAD_MATCH 错误(目前只能指定 EGL_BACK_BUFFER 类型的 buffer)。
- 如果 surface 不是 EGL surface，或者不是支持纹理绑定的 pbuffer surface，则会生成 EGL_BAD_SURFACE 错误。

### 从 OpenGL ES Texture 释放 Surface

我们可以调用 eglReleaseTexImage 函数释放用作纹理的颜色缓冲区。eglReleaseTexImage 函数的定义如下：

```c
EGLBoolean eglReleaseTexImage(
    EGLDisplay display,
    EGLSurface surface,
    EGLint buffer
)
```

调用 eglReleaseTexImage 函数后，指定的颜色缓冲区会被释放回 surface。当 surface 不再有任何绑定为纹理的颜色缓冲区时，该 surface 即变的可读写。

颜色缓冲区的内容在第一次释放时是未定义的，EGL 不保证纹理图像此时仍然存在。但是，其他颜色缓冲区(other color buffers)的内容不受 eglReleaseTexImage 函数调用的影响。此外，深度和模板缓冲区的内容不受 eglBindTexImage 和 eglReleaseTexImage 函数的影响。

如果指定的颜色缓冲区不再绑定到纹理(例如纹理对象被删除)，则 eglReleaseTexImage 函数将不起作用，并且不会产生错误。

从纹理中释放颜色缓冲区后(显式调用 eglReleaseTexImage 或通过隐式调用如 glTexImage2D 函数这样的 routine)，由颜色缓冲区定义的所有纹理图像都会变为 NULL(就好像使用零宽度的图像调用 glTexImage 函数一样)。

#### 函数错误

- 如果 surface 的 EGL_TEXTURE_FORMAT 属性设置为了 EGL_NO_TEXTURE，则会生成 EGL_BAD_MATCH 错误。
- 如果 buffer 不是有效的 buffer，则生成 EGL_BAD_MATCH 错误(当前只能指定 EGL_BACK_BUFFER 类型的 buffer)。
- 如果 surface 不是 EGL surface，或者不是被绑定的 pbuffer surface，则会生成 EGL_BAD_SURFACE 错误。

### 注意事项

注意，不一定存在支持纹理渲染的 OpenGL ES 实现。也就是说，可能没有支持 EGL_BIND_TO_TEXTURE_RGB 或 EGL_BIND_TO_TEXTURE_RGBA 属性的 EGLConfig。渲染到纹理的功能包含在 OpenGL ES 的较新 framebuffer 对象的扩展中，并且最终可能会被弃用。OpenGL 的上下文不支持渲染到纹理。

## 10. 同步渲染

有时我们会碰到，协调多个图形 API 在单个窗口中渲染的情况。在这种情况下，需要让 app 允许多个库渲染到共享窗口。EGL 提供了几个函数来处理这种同步任务。

![同步渲染函数](/imgs/同步渲染函数.webp)

EGL 不保证上下文之间的渲染顺序，即使在同一线程内也是如此。例如，同一个线程的当前上下文 A 的渲染操作的执行，不一定在后面指定的当前上下文 B 的渲染操作完成之前完成。当一个上下文的绘制结果被另一个上下文依赖时，app 有责任确保正确的同步，否则结果是不确定的。

为了实现同步，app 可以使用特定于 client API 的命令(例如 glFinish)来保证渲染操作在切换当前上下文操作之前完成。或者如果底层实现支持，则 app 可以使用同步对象(synchronization objects)来确定上下文之间的渲染操作的顺序。同步对象由 EGL_KHR_fence_sync 和 EGL_KHR_wait_sync EGL 扩展定义，或者它们可以作为底层 client API 的功能提供。使用同步对象允许异步执行渲染操作，从而获得比 glFinish 等同步等待函数更好的性能。

### eglWaitClient 函数

如果 native rendering API 和 client API 的渲染操作会影响同一 surface。那么我们可以调用 eglWaitClient 函数，以预防 native rendering API 在 client API 渲染操作完成之前执行。

eglWaitClient 函数的定义如下：

```c
EGLBoolean eglWaitClient(void)
```

eglWaitClient 函数用于保证在后续 native rendering 操作被调用之前，完成 client API 的渲染操作。

在 eglWaitClient 之前创建的当前上下文和当前渲染 API 的所有渲染调用，都会在 eglWaitClient 之后创建的 native 渲染调用之前执行，这会影响与该上下文关联的 read 或 draw surfaces。

在 eglWaitClient 之前进行的当前绑定上下文和当前渲染API的所有渲染调用都保证在eglWaitClient之后进行的本机渲染调用之前执行，这会影响与该上下文关联的读取或绘制表面。

使用特定于 client API 的调用(例如 glFinish 或 vgFinish)可以实现相同的结果。

渲染到 single-buffered surfaces(例如 pixmap surfaces)的客户端操作，应在客户端访问 native pixmap 之前调用 eglWaitClient。

- eglWaitClient 调用成功时返回 EGL_TRUE。如果当前的渲染 API 没有当前上下文，则调用该函数没有任何效果，但仍然会返回 EGL_TRUE。

如果与当前上下文关联的 surface 具有无效的 native window 或 native pixmap，则会生成 EGL_BAD_CURRENT_SURFACE 错误。

### eglWaitNative 函数

如果 native rendering API 和 client API 的渲染操作会影响同一 surface。那么我们可以调用 eglWaitNative 函数，以预防 client API 在 native rendering API 渲染操作完成之前执行。。

eglWaitNative 函数的定义如下：

```c
EGLBoolean eglWaitNative(EGLint engine)
```

在 eglWaitNative 之前进行的 native rendering 调用，都会在 eglWaitNative 之后创建的 GL 渲染调用之前执行，这会影响与调用线程的当前上下文关联的 read 或 draw surfaces。

使用 native 层定义的同步操作，可以达到相同的效果(但不一定)。

对于当前 native rendering API 调用，EGL 使用 engine 进行指定。engine 表示要等待的特定引擎(另一个绘图 API，例如 GDI 或 Xlib)，有效的引擎值由特定的 EGL 实现定义，但 EGL 将始终取值 EGL_CORE_NATIVE_ENGINE 常量

#### 函数错误

- eglWaitNative 函数执行成功时，会返回 EGL_TRUE。
- 如果没有当前上下文，则执行 eglWaitNative 函数没有任何作用，但仍然会返回 EGL_TRUE。
- 如果 surface 不支持 native rendering，则执行 eglWaitNative 函数没有任何效果，但仍然会返回 EGL_TRUE。
- 如果 engine 不是 EGL_CORE_NATIVE_ENGINE，则会生成 EGL_BAD_PARAMETER。
- 如果与当前上下文关联的 surface 具有无效的 native window 或 native pixmap，则会生成 EGL_BAD_CURRENT_SURFACE 错误。

### 同步对象(Sync Objects)

#### 创建 Sync Objects

上面讲解的同步函数同步了线程内 client 和 native API 之间的渲染操作。除此之外，EGL 还提供了同步对象(Sync Objects)来实现 client API 的线程之间、上下文之间的操作的同步。

同步对象的状态有两种：有信号(signaled)和无信号(unsignaled)。同步对象最开始是无信号的。EGL 可以会被要求等待 Sync Objects 变成 signaled(发出信号)。我们也可以查询 Sync Objects 的状态。

根据同步对象的类型，其状态可以通过外部事件或显式发送和取消同步信号来更改。

同步对象在创建时与 EGLDisplay 关联，并具有定义该同步对象其他方面内容的 attributes。所有同步对象都包含代表其类型和状态的 attributes。下面要讨论的是不同类型同步对象的额外属性。

栅栏同步对象(Fence sync objects)是与 client API 中的栅栏命令(fence command)关联创建的。栅栏同步对象无法显式地变成 signaled 状态，并且只能更改一次状态(从初始的 unsignaled 状态变为 signaled 状态)。当 client API 执行栅栏命令时，会生成一个事件，该事件会让相应的栅栏同步对象变成 signaled 状态。栅栏同步对象作为 glFinish 或 vgFinish 的更灵活形式，可用于等待 client API 命令流的部分命令执行完成。

我们可以使用 eglCreateSync 函数创建同步对象，eglCreateSync 函数的定义如下：

```c
EGLSync eglCreateSync(
    EGLDisplay display,
    EGLEnum type,
    EGLAttrib const * attrib_list
)
```

eglCreateSync 函数用于创建与指定 display 关联的特定 type 的同步对象，并返回新的 sync objects 的句柄。attrib_list 是指定同步对象的其他属性的属性值列表，以 EGL_NONE 终止。列表中未指定的属性将被分配为默认值。

一旦满足同步对象的条件，同步对象就会变成 signaled 状态，发出同步信号，从而解除同步对象上阻塞的任何 eglClientWaitSync 或eglWaitSync 命令。

如果 type 的值为 EGL_SYNC_FENCE，则会创建栅栏同步对象。此时 attrib_list 必须为 NULL 或空(仅包含 EGL_NONE)。栅栏同步对象的属性设置如下表所示。

当创建栅栏同步对象时，eglCreateSync 函数还会插一条栅栏命令到 client API 的当前上下文的命令流中(由 eglGetCurrentContext 返回的上下文)，并将该栅栏命令与新创建的同步对象关联。

![栅栏对象属性](/imgs/栅栏对象属性.webp)

栅栏同步对象支持的唯一条件是 EGL_SYNC_PRIOR_COMMANDS_COMPLETE，要满足该条件，需要完成与同步对象关联的栅栏命令，以及与之关联的 client API 的当前上下文的命令流中的所有栅栏命令之前的命令。在这些命令对 client API 的内部和帧缓冲区(framebuffer)状态的所有更新完成之前，同步对象不会发出信号。执行栅栏命令不会影响其他状态。

创建栅栏同步对象需要绑定的 client API 的支持，满足 client API 以下条件之一，创建操作才会成功。请注意，调用 eglWaitSync 函数也需要满足这些条件。

- client API 是 OpenGL，并且 OpenGL 的版本为 3.2 或更高版本，或者 OpenGL 支持 GL_ARB_sync 扩展。
- client API 是 OpenGL ES，并且 OpenGL ES 的版本为 3.0 或更高版本，或者 OpenGL ES 支持 GL_OES_EGL_sync 扩展。
- client API 是 OpenVG，并且 OpenVG 支持 VG_KHR_EGL_sync扩展。

##### 函数错误

- eglCreateSync 执行失败时，会返回 EGL_NO_SYNC。
- 如果 display 不是有效的、已初始化的 EGLDisplay，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 attrib_list 包含指定类型的同步对象不需要的属性，则会生成 EGL_BAD_ATTRIBUTE 错误。
- 如果 type 不是受支持的同步对象类型，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 type 为 EGL_SYNC_FENCE，并且绑定的 client API 没有当前上下文(即 eglGetCurrentContext 返回 EGL_NO_CONTEXT)，则会生成 EGL_BAD_MATCH 错误。
- 如果 type 为 EGL_SYNC_FENCE，并且 display 与当前绑定的 client API 的当前上下文的 EGLDisplay(即 eglGetCurrentDisplay 返回的 EGLDisplay)不匹配，则会生成 EGL_BAD_MATCH 错误。
- 如果 type 为 EGL_SYNC_FENCE，并且当前绑定的 client API 的当前上下文不支持 fence commands，则会生成 EGL_BAD_MATCH 错误。

#### 等待 Sync Objects

创建了 Sync Objects 后，我们就可以使用 Sync Objects 进行同步操作。我们可以使用 eglClientWaitSync 进行等待操作。eglClientWaitSync 函数的定义如下：

```c
EGLint eglClientWaitSync(
    EGLDisplay display,
    EGLSync sync,
    EGLint flags,
    EGLTime timeout
)
```

eglClientWaitSync 函数会阻塞调用线程，直到指定的同步对象 sync 的状态变成 signaled，或者直到超时，超时时长为 timeout 纳秒。

在任何时间，同一 sync 对象上都可能有多个 eglClientWaitSync 未完成。如果多个线程在同一个 sync 对象上阻塞，则当 sync 对象的状态变成 signaled 时，所有线程都会被释放，但它们释放的先后顺序未定义。

如果 timeout 为 0，则 eglClientWaitSync 仅检测 sync 的状态。如果 timeout 的值为特殊值 EGL_FOREVER，则 eglClientWaitSync 函数永远不会超时。对于其他所有的超时值，timeout 将调整为实际 EGL 实现的超时精度允许的最接近值，该值可远长于一纳秒。

eglClientWaitSync 返回的值时描述返回原因的三个状态值之一：
- EGL_TIMEOUT_EXPIRED 表示在发出同步信号之前等待已超时；如果 timeout 为 0，则表示 sync 对象的状态是 unsignaled。
- EGL_CONDITION_SATISFIED 表示在超时之前 sync 对象发出了同步信号，其中包括调用 eglClientWaitSync 时 sync 已经发出同步信号的情况。
- 如果发生错误，则会生成错误并返回 EGL_FALSE。

在某些错误情况下，被阻塞的 sync object 永远不会发出信号(status become signaled)。为了防止这种情况出现，如果在 flags 设置了 EGL_SYNC_FLUSH_COMMANDS_BIT，并且在调用 eglClientWaitSync 时 sync 的状态是 unsignaled(未发出同步信号)，则当前绑定的 client API 的上下文(即由 eglGetCurrentContext 返回的上下文)会在进入 sync 阻塞之前执行 Flush() 的等效调用。如果绑定的 client API 没有当前上下文，则忽略 EGL_SYNC_FLUSH_COMMANDS_BIT 标记。

##### 函数错误

- eglClientWaitSync 执行失败时，会返回 EGL_FALSE。
- 如果 sync 不是与 display 关联的有效同步对象，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 display 与创建 sync 时传递给 eglCreateSync 的 EGLDisplay 不匹配，则后续行为是未知的。

#### eglWaitSync 函数

eglWaitSync 函数的定义如下：

```c
EGLBoolean eglWaitSync(
    EGLDisplay display,
    EGLSync sync,
    EGLint flags
)
```

eglWaitSync 函数与 eglClientWaitSync 函数类似，前者是在服务中等待同步对象发出信号，后者是在客户端中等待同步对象发出信号。但 eglWaitSync 会立即返回，而不是阻塞并且直到发出同步信号才返回到 app。注意，仅当 EGL 版本为 1.5 或更高时，eglWaitSync 函数才可用。

eglWaitSync 执行成功时，会返回 EGL_TRUE，并且 client API 的上下文的服务将阻塞，直到 sync 的状态变成 signaled(发出同步信号)。eglWaitSync 函数允许 app 继续对来自 app 的命令进行排队，以预期发出同步信号，从而可能增加 app、client API 服务代码和 GPU 之间的并行性。服务仅阻塞执行 eglWaitSync 的特定上下文的命令；同一服务实现的其他上下文不受影响。

sync 参数的含义与 eglClientWaitSync 函数中对应参数的含义相同。

eglWaitSync 函数中 flags 必须为 0。

eglWaitSync 需要绑定的 client API 的支持，并且满足 eglCreateSync 函数中所描述的条件时才能执行成功，否则不会成功。

##### 函数错误

- eglWaitSync 在失败时返回 EGL_FALSE，并且不会导致 client API 的上下文的服务阻塞。
- 如果当前绑定的 client API 的当前上下文不支持服务等待，则会生成 EGL_BAD_MATCH 错误。
- 如果当前绑定的 client API 没有当前上下文(即 eglGetCurrentContext 返回 EGL_NO_CONTEXT)，则会生成 EGL_BAD_MATCH 错误。
- 如果 display 与创建 sync 对象时传递给 eglCreateSync 的 EGLDisplay 不匹配，则后续行为是未知的。
- 如果 sync 不是与 display 关联的有效同步对象，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 flags 不为 0，则会生成 EGL_BAD_PARAMETER 错误。

#### 多个等待

调用 client API 的 app 线程可能会在调用 eglClientWaitSync 命令时阻塞在 sync 对象上，而该 client API 上下文的服务可能会因先前的 eglWaitSync 命令而被阻塞，并且其他的 eglWaitSync 命令页可能被阻塞。所有的命令都阻塞在了单个 sync 对象上。此时，当 sync 对象发出信号时，客户端将解除阻塞，服务将解除阻塞，并且所有此类排队的 eglWaitSync 命令将在执行到时立即解除阻塞。

尽管某些 client API 可能不支持  eglWaitSync，但是同步对象可以同时在多个线程中等待不同的 client API 类型的多个上下文，或者从多个上下文发出信号。此支持由 client API 的特定扩展决定

#### 查询同步对象的属性

我们可以使用 eglGetSyncAttrib 函数来查看同步对象的属性。eglGetSyncAttrib 函数的定义如下：

```c
EGLBoolean eglGetSyncAttrib(
    EGLDisplay display,
    EGLSync sync,
    EGLint attribute,
    EGLAttrib *value
)
```

eglGetSyncAttrib 函数用于查询与 display 关联的 sync 对象的 attribute 属性的值，结果由 value 承载。attribute 的可取值取决于 sync 对象的类型，如下表。

![eglGetSyncAttrib函数](/imgs/eglGetSyncAttrib函数.webp)

##### 函数错误

- 如果 eglGetSyncAttrib 函数执行成功，则返回 EGL_TRUE，并在 *value 中返回查询属性的值。如果 eglGetSyncAttrib 函数执行失败，则会返回 EGL_FALSE，并且 *value 的值不会被修改。
- 如果 sync 对象不是与 display 关联的有效同步对象，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 attribute 不是有效的属性，则会生成 EGL_BAD_ATTRIBUTE 错误。
- 如果 sync 对象的类型不支持 attribute，则会生成 EGL_BAD_MATCH 错误。
- 如果 display 与创建 sync 对象时传递给 eglCreateSync 的 display 不匹配，则结果是未知的。

#### 销毁同步对象

当 sync 对象使用完成后，我们可以使用 eglDestroySync 函数进行销毁。但是注意 eglDestroySync 函数只有在 EGL 1.5 或者更高版本才可用。

eglDestroySync 函数的定义如下：

```c
EGLBoolean eglDestroySync(
    EGLDisplay display,
    EGLSync sync
)
```

eglDestroySync 函数用于销毁与 display 关联的 sync 对象。

如果调用 eglDestroySync 函数时没有任何 eglClientWaitSync 或 eglWaitSync 命令在 sync 上阻塞，则 sync 对象将立即被销毁。否则 sync 会被标记为删除，直到关联的 fence 命令或 OpenCL 事件对象(本文未讲解 OpenCL 的相关知识点)完成时才被删除，并且 sync 不再用于阻塞任何 egl*WaitSync 类型的命令。

##### 函数错误

- 如果 eglDestroySync 函数执行成功，则会返回 EGL_TRUE，并且 sync 句柄将时效。否则会返回 EGL_FALSE。
- 如果 sync 对象不是与 display 关联的有效同步对象，则返回 EGL_FALSE，并生成 EGL_BAD_PARAMETER 错误。
-  如果 display 与创建 sync 对象时传递给 eglCreateSync 的 display 不匹配，则结果是未知的。

## 11. EGLImage 的管理

EGLImage 是由 Client API 创建的，在 EGL 层包装过的共享资源。可能是图像数据的 2D 数组。

最初在 CLient API 中创建的对象或子对象，例如 OpenGL 或 OpenGL ES 中的 texture mipmap，或 OpenVG 中的 VGImage，称为 EGLImage Source。EGLImage Source 在调用 eglCreateImage 函数时作为参数。

CLient API 根据 EGLIImage 创建的对象，例如 OpenGL 或 OpenGL ES 中的 texture mipmap，或 OpenVG 中的 VGImage，称为 EGLImage Target。一个 EGLImage 可以创建多个 EGLImage Target。

与同一 EGLImage 关联的 EGLImage Source 和 EGLImage Targe 统称为 EGLImage Sibling。

![EGLImage_Sibling](/imgs/EGLImage_Sibling.webp)

EGL 主要提供了 eglCreateImage 和 eglDestroyImage 两个函数来管理 EGLImage。eglCreateImage 函数仅在 EGL 1.5 及更高版本可用。

### eglCreateImage 函数

eglCreateImage 函数的定义如下：

```c
EGLImage eglCreateImage(
    EGLDisplay display,
    EGLContext context,
    EGLenum target,
    EGLClientBuffer buffer,
    const EGLAttrib *attrib_list
)
```

eglCreateImage 函数使用 buffer(现有的 client API 的图像资源) 创建 EGLImage 对象。Client API 可以引用 eglCreateImage 返回的 EGLImage 对象。

创建的 EGLImage 对象与 display 和 context 关联。如果不需要与 client API 上下文关联，则 context 参数可以传 EGL_NO_CONTEXT。display 必须是有效的 EGLDisplay，并且 context 必须是该 display 上的有效的 OpenGL 或 OpenGL ES API 上下文。

target 是用于创建 EGLImage 的 EGLImage Source 的资源类型，例如 OpenGL ES 上下文中的二维纹理和 OpenVG 上下文中的 VGImage 对象。

buffer 是用于创建 EGLImage 的 EGLImage Source 的资源的名称或句柄，EGLImage Source 会被转换为 EGLClientBuffer 类型。

attrib_list 是属性键值对的列表，用于选择 buffer 的子数据以作为 EGLImage source，例如 OpenGL ES 纹理贴图资源的 mipmap 级别，以及 behavioral。如果 attrib_list 是非 NULL，则列表中必须以 EGL_NONE 结尾。

由 display、context、target、buffer 和 attrib_list 指定的资源本身不能是 EGLImage sibling，也不能绑定到 pbuffer EGLSurface 资源，即不能用于 eglBindTexImage 和 eglCreatePbufferFromClientBuffer。

target 的可取值如下表：

![eglCreateImage函数](/imgs/eglCreateImage函数.webp)

- 如果 target 是 EGL_GL_TEXTURE_2D，则 buffer 必须是非 0 GL_TEXTURE_2D 类型的纹理对象的名称，并转换为 EGLClientBuffer 类型。
- 如果 target 是 EGL_GL_TEXTURE_CUBE_MAP_* 类型的枚举之一，则 buffer 必须是非 0  GL_TEXTURE_CUBE_MAP 或 GL 扩展中的等效项类型的纹理对象的名称，并转换为 EGLClientBuffer 类型。
- 如果 target 是 EGL_GL_TEXTURE_3D，则 buffer 必须是非 0 GL_TEXTURE_3D 或 GL 扩展中的等效项类型的纹理对象的名称，转换为 EGLClientBuffer 类型。
- 如果 target 是 EGL_GL_RENDERBUFFER，则 buffer 必须是完整、非零、非多重采样的 GL_RENDERBUFFER 或扩展中的等效项 类型的对象的名称，并转换为 EGLClientBuffer 类型。 此时 attrib_list 中指定的值将被忽略。

attrib_list 中接受的属性名称、描述、有效值、默认值说明如下表，如果 attrib_list 中不包含相关 attribute，则会使用默认值：

![eglCreateImage函数attrib_list](/imgs/eglCreateImage函数attrib_list.webp)

- attrib_list 应指定 EGL_GL_TEXTURE_LEVEL(mipmap 级别)；如果适用的话，还需要设置 EGL_GL_TEXTURE_ZOFFSET(z-offset)；如果未指定，则将使用默认值。必须存在一些 x 和 y levels，使得请求的 mipmap 级别位于 x 和 y 之间。如果 x 是 base level，y  是 max level，则 mipmap level 的完整有效范围是 x 和 y 之前。对于立方体贴图，一对 x 和 y 必须应用于所有面。对于三维纹理，指定的  z-offset 必须小于指定的 mipmap 级别的深度。
- 如果 EGL_IMAGE_PRESERVED 属性的值为 EGL_FALSE，则在 eglCreateImage 函数返回后，与 buffer  入参关联的所有像素数据都将失效。如果 EGL_IMAGE_PRESERVED 属性的值为 EGL_TRUE，则会保留与 buffer 入参关联的所有像素数据。

#### 函数错误

- eglCreateImage 执行失败时会返回 EGL_NO_IMAGE。buffer 中的内容将不受影响。
- 如果 display 不是有效的 EGLDisplay 对象，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 context 既不是 display 上的有效的 EGLContext，也不是 EGL_NO_CONTEXT，则会生成 EGL_BAD_CONTEXT 错误。
- 如果 target 不是有效的 target，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 target 是有效的 target，并且 context 不是有效的 GL 上下文或者与 display 不匹配，则会生成 EGL_BAD_MATCH 错误。
- 如果 target 是非 EGL_GL_RENDERBUFFER 类型的 target，并且 buffer 和 target 类型不匹配，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 target 是 EGL_GL_RENDERBUFFER 类型的 target，并且 buffer 不是有效的 renderbuffer，或者 buffer 是 multisampled renderbuffer，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 EGL_GL_TEXTURE_LEVEL 属性不为零，target 是非 EGL_GL_RENDERBUFFER 的 target，并且 buffer 不是完整的 GL 纹理对象，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 EGL_GL_TEXTURE_LEVEL 为 0，target 是非 EGL_GL_RENDERBUFFER 的 target，并且 buffer 为不完整的 GL 纹理对象且指定了非 0 的 mipmap level，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 EGL_GL_TEXTURE_LEVEL 为 0，target 是 EGL_GL_TEXTURE_CUBE_MAP_*，并且 buffer 不是完整的 GL 纹理对象，且一个或多个面指定了非 0 的 mipmap level，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 target 是有效的 target，并且 buffer 是默认 GL 纹理对象(0)，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 target 是非 EGL_GL_RENDERBUFFER 类型的 target，并且 attrib_list 中 EGL_GL_TEXTURE_LEVEL 指定的值不是指定 buffer 的有效 mipmap 级别，则会生成错误 EGL_BAD_MATCH 错误。
- 如果 target 是 EGL_GL_TEXTURE_3D，并且 attrib_list 中为 EGL_GL_TEXTURE_ZOFFSET 指定的值超出 buffer 中指定级别 mipmap 的深度，则会生成 EGL_BAD_PARAMETER 错误。
- 如果 attrib_list 中指定的属性不是有效值，则会生成 EGL_BAD_PARAMETER 错误。
- 如果由 display、context、target、buffer 和 attrib_list 指定的资源已绑定了一个 off-screen buffer(例如之前调用过 eglBindTexImage 和 eglCreatePbufferFromClientBuffer)，则会生成 EGL_BAD_ACCESS 错误。
- 如果由 display、context、target、buffer 和 attrib_list 指定的资源本身已经是 EGLImage sibling，则会生成 EGL_BAD_ACCESS 错误。
- 如果没有足够的内存来完成指定的操作，则会生成 EGL_BAD_ALLOC 错误。
- 如果 attrib_list 中 EGL_IMAGE_PRESERVED 的值为 EGL_TRUE，并且无法从指定资源创建 EGLImage，保留 buffer 入参中的像素数据，则会生成 EGL_BAD_ACCESS 错误。

### EGLImage 的生命周期和使用

一旦从 EGLImage Source 创建了 EGLImage，那么只要满足以下任一条件，与 EGLImage Source 关联的内存将不会被回收，并且所有 Client API 上下文中的所有 EGLImage siblings 都将可用。

- EGLImage siblings 存在于任何 client API context
- EGLImage 对象存在于 EGL 内部

指定、删除和使用 EGLImage siblings 的语义是特定于 client API 的，并在相应的 API 规范中进行了描述。

如果 app 指定 EGLImage sibling 作为渲染和像素下载操作的目标，例如作为 OpenGL 或 OpenGL ES 帧缓冲区对象、glTexSubImage2D 等，则所有 client API 上下文中的所有 EGLImage sibling 都将观察到修改后的图像结果。如果 client API 上下文在修改图像数据时访问 EGLImage sibling 资源，则所有相关上下文中的渲染结果都是未知的。即处理和访问 EGLImage siblings 存在线程同步问题。

### eglDestroyImage 函数

我们可以使用 eglDestroyImage 函数来销毁 EGLImage 对象。eglDestroyImage 函数的定义如下：

```c
EGLBoolean eglDestroyImage(
    EGLDisplay display,
    EGLImage image
)
```

eglDestroyImage 函数用于销毁与 display 关联的指定 image 对象。一旦 image 被销毁，image 就不能用于创建任何 EGLImage target，尽管已有的 EGLImage siblings 仍然可以继续使用。

- eglDestroyImage 函数执行成功时返回 EGL_TRUE，否则返回 EGL_FALSE。
- 如果 display 不是有效的 EGLDisplay 对象，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 image 不是 display 创建的有效的 EGLImage 对象，则会生成 EGL_BAD_PARAMETER 错误。

##  12. 使 Color Buffer 数据生效

完成渲染后，可以让 Color Buffer 中的内容在 native window 中可见，或者可以复制到 native pixmap。

egl 默认支持双缓冲(三缓冲)显示。即与显示相关的 buffer 存在两个，一个可见的，一个不可见的(后台 buffer)，渲染时，我们是把内容渲染到不可见的 Buffer，渲染完成后，我们需要交换不可见 buffer 与可见 buffer 的内容，使用不可见 buffer 中的内容变得可见。此操作被称为 Post Color Buffer(发布 Color Buffer)，更直观的说法是使 Color Buffer 数据生效。

### eglSwapBuffers 函数

要让 color buffer 中的内容在 window 中可见。我们可以使用 eglSwapBuffers 函数，eglSwapBuffers 函数的定义如下：

```c
EGLBoolean eglSwapBuffers(
    EGLDisplay display,
    EGLSurface surface
)
```

eglSwapBuffers 函数用于交换指定 display 的 surface 的内容到前台。

如果 surface 是 back-buffered window surface，则 color buffer 将被复制(发布)到与该 surface 关联的 native window。如果 surface 是 single-buffered window、pixmap、或者 pbuffer surface，则调用 eglSwapBuffers 函数是没有效果的。

调用 eglSwapBuffers 后，辅助缓冲区的内容变得未知。如果 surface 的 EGL_SWAP_BEHAVIOR 属性的值不是 EGL_BUFFER_PRESERVED，则 color buffer 的内容也会变得未知。可以使用 eglSurfaceAttrib 为某些 surface 设置 EGL_SWAP_BEHAVIOR。EGL_SWAP_BEHAVIOR 属性仅适用于 color buffer。EGL 无法查询或指定是否保留辅助缓冲区的内容(并且 app 也不应依赖此行为)。

对绑定到 surface 的上下文，eglSwapBuffers 在交换之前会执行一次隐式刷新操，对于 OpenGL ES 或 OpenGL 上下文，是 glFlush；对于 OpenVG 上下文，是 vgFlush。调用 eglSwapBuffers 后，后续的 client API 命令可以立即在该上下文上触发，但直到 buffer 交换完成后才会真正执行。

#### Native Window Resizing

如果与 surface 关联的 native window 在交换之前尺寸发生了变化，则必须调整 surface 的尺寸以进行匹配。EGL 实现通常会在 native window 的尺寸发生变化时，也一起调整 surface 的尺寸。如果 EGL 实现无法执行此操作，则 eglSwapBuffers 必须在将像素复制到 native window 之前检测变化，并调整 surface 的尺寸。如果 surface 因调整而缩小，则一些渲染的像素会丢失。如果 surface 的尺寸变大，则新分配的 buffer 的内容是未知的。这里描述的调整尺寸行为仅保持 EGL surface 和 native window 的一致性；client API 仍然负责检测 window 尺寸变化(使用特定平台的方法)，并相应地更改其视口和裁剪区域的尺寸。

#### 函数错误

- 如果 surface buffers 交换失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 surface 不是 EGL drawing surface ，则会生成 EGL_BAD_SURFACE 错误。
- 如果发生电源管理事件，则会生成 EGL_CONTEXT_LOST 错误。此时 app 必须销毁所有上下文，并重新初始化 OpenGL ES 状态和对象，才能继续渲染。

### eglCopyBuffers 函数

要将 color buffer 复制到 native pixmap，我们可以使用 eglCopyBuffers 函数，eglCopyBuffers 函数的定义如下：

```c
EGLBoolean eglCopyBuffers(
    EGLDisplay display,
    EGLSurface surface,
    NativePixmapType native_pixmap
)
```

eglCopyBuffers 函数将 surface 的 color buffer 复制到 native_pixmap。在返回结果之前，eglCopyBuffers 会隐式执行一次 glFlush。后续的 GL 命令可以在调用 eglCopyBuffers 后立即触发，但直到 color buffer 复制完成后才会真正执行。

注意调用 eglCopyBuffers 后，surface 的 color buffer 将保持不变。

#### 函数错误

- 如果 surface buffers 复制失败，则会返回 EGL_FALSE，否则返回 EGL_TRUE。
- 如果 display 不是 EGL display connection，则会生成 EGL_BAD_DISPLAY 错误。
- 如果 display 尚未初始化，则会生成 EGL_NOT_INITIALIZED 错误。
- 如果 surface 不是 EGL drawing surface，则会生成 EGL_BAD_SURFACE 错误。
- 如果 EGL 实现不支持 native pixmap，则会生成 EGL_BAD_NATIVE_PIXMAP 错误。
- 如果 native_pixmap 不是有效的 native pixmap，则可能会生成 EGL_BAD_NATIVE_PIXMAP 错误。
- 如果 native_pixmap 的格式与 surface 的 color buffer 不兼容，则会生成 EGL_BAD_MATCH 错误。
- 如果发生电源管理事件，则会生成 EGL_CONTEXT_LOST 错误。此时 app 必须销毁所有上下文，并重新初始化 OpenGL ES 状态和对象，才能继续渲染。

### Posting Semantics

对于当前的渲染 API，surface 必须绑定到调用线程的当前上下文的 draw surface。

eglSwapBuffers 和 eglCopyBuffers 会对上下文执行隐式 flush 操作：对于 OpenGL 或 OpenGL ES 上下文，是 glFlush；对于 OpenVG 上下文，是 vgFlush。后续的 client API 命令可以立即发出，但发布操作完成后才会真正执行。

发布操作的 target(对于 eglSwapBuffers 来说是  visible window，对于 eglCopyBuffers 来说是 native pixmap)应该具有与 surface 的 color buffer 相同的组件数量和组件尺寸(即 A、R、G、B 通道的数量的尺寸)。

注意在将亮度颜色缓冲区(luminance color buffer)发布到 RGB 目标时，亮度分量的值通常会复制到 target 的每个红色、绿色和蓝色分量中。只要实际的感知结果不变，EGL 实现就可以使用 color-space 转换算法将亮度映射到红色、绿色和蓝色值。不过此类替代实现转换应由 EGL 实施记录。

当 surface 和发布 target 不满足兼容性约束时，EGL 实现可以选择放宽约束，将数据转换为 target 的格式。如果 EGL 实现这样做了，则 EGL 实现应该定义一个 EGL 扩展来指定支持哪些目标格式，并指定所使用的转换算法。

### eglSwapInterval 函数

eglSwapInterval 函数指定了与当前上下文关联的 window 的每个 buffer 所交换的视频帧的最小间隔。使用此函数可以设置帧率。eglSwapInterval 函数的定义如下：

```c
EGLBoolean eglSwapInterval(
    EGLDisplay display,
    EGLint interval
)
```

eglSwapBuffers 函数在 eglSwapInterval 函数的调用之后调用后，interval 生效。

eglSwapInterval 函数指定的 interval 适用于绑定到调用线程上当前上下文的 draw surface。

如果 interval 设置为值 0，则 buffer 的交换节奏不会与视频帧同步，并且渲染完成后会立刻交换。在被存储之前，interval 会默认固定为最小和最大值；这些值分别由 EGLConfig 属性 EGL_MIN_SWAP_INTERVAL 和 EGL_MAX_SWAP_INTERVAL 定义。

注意设置 interval 对 eglCopyBuffers 函数没有影响，并且默认的 interval 是 1。

- eglSwapInterval 执行失败时，会返回 EGL_FALSE，否则返回 EGL_TRUE。
- 如果调用线程上没有当前上下文，则会生成 EGL_BAD_CONTEXT 错误。
- 如果没有 surface 绑定到当前上下文，则会生成 EGL_BAD_SURFACE 错误。

## 总结

以上就是关于 EGL 使用的相关知识点。主要讲解了 EGL 的概念、总体架构、初始化流程、如何渲染数据以及如何使数据生效。

如果有讲解不当、不易理解或者错误的地方，欢迎大家指出。

## 参考链接

- EGL 1.5 规范原文链接：extension://bfdogplmndidlpjfhoijckpakkdjkkil/pdf/viewer.html?file=https%3A%2F%2Fregistry.khronos.org%2FEGL%2Fspecs%2Feglspec.1.5.pdf
- 《OpenGL ES 3.0 编程指南》
- GPU 讲解：https://www.cnblogs.com/timlly/p/11471507.html