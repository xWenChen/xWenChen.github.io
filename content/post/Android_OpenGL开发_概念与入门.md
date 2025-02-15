---
title: "Android OpenGL 开发---概念与入门"
description: "本文略讲了 Android OpenGL 开发的概念与入门"
keywords: "Android,OpenGL"

date: 2020-04-18T17:32:00+08:00

categories:
  - Android
  - OpenGL
tags:
  - Android
  - OpenGL

url: post/F8881A08F40A4BBB8D2E517024E7CDAE.html
toc: true
---

本文略讲了 Android OpenGL 开发的概念与入门。

<!--More-->

内容参考自 官方资料 和 [Android OpenGL ES从白痴到入门](https://www.jianshu.com/p/5b9556c9237f)。

下篇博文：[Android OpenGL 开发---EGL 的使用](7177C8F7FDD54C869B9526C47B17F62D.html)

## OpenGL 与 OpenGL ES

OpenGL（Open Graphics Library，译名：开放图形库或者“开放式图形库”）是用于渲染 2D、3D 矢量图形的跨语言、跨平台的应用程序编程接口（API）。OpenGL 不仅语言无关，而且平台无关。OpenGL 纯粹专注于渲染，而不提供输入、音频以及窗口相关的 API。这些都有硬件和底层操作系统提供。OpenGL 的高效实现（利用了图形加速硬件）存在于 Windows，部分 UNIX 平台和 Mac OS，可以便捷利用显卡等设备。

OpenGL ES (OpenGL for Embedded Systems) 是 OpenGL 三维图形 API 的子集，针对手机、PDA和游戏主机等嵌入式设备而设计。经过多年发展，现在主要有两个版本，OpenGL ES 1.x 针对固定管线硬件的，OpenGL ES 2.x 针对可编程管线硬件。Android 2.2 开始支持 OpenGL ES 2.0，OpenGL ES 2.0 基于 OpenGL 2.0 实现。一般在 Android 系统上使用 OpenGL，都是使用 OpenGL ES 2.0，1.0 仅作了解即可。

## EGL

EGL（Embedded Graphics Library）实际上是OpenGL和设备(又或者叫操作系统)间的中间件，因为 OpenGL 是平台无关的，是标准的，但设备是千奇百怪的，要对接就需要一个中间件做协调。也就是说一个设备要支持 OpenGL，那么它需要开发一套相对应的 API 来对接。在 Android 中就是 EGL。EGL 主要负责初始化 OpenGL 的运行环境和设备间的交互，简单的说就是 OpenGL 负责绘图，EGL 负责和设备交互。

实际上，OpenGL ES 定义了一个渲染图形的 API，但没有定义窗口系统。因为不同的操作系统，窗口机制可能不相同。

为了让 GLES 能够适合各种平台，通常 GLES 都与特定库结合使用，这些库可创建和访问操作系统的窗口。在 Android 系统中，这个库是 EGL。调用 GLES 渲染纹理多边形，调用 EGL 将渲染放到屏幕上。

由上面的内容可知，在 Android 系统中，GLESxxx（如 GLES20、GLES30 等等）实现的是标准的 OpenGL 接口，而 EGLxxx(如 EGL10、EGL14 等等)实现的是 OpenGL 如何与 Android 系统交互。

## 坐标系

作为一个 Android 小开发。应该知道坐标系的概念，物体的位置都是通过坐标系确定的。OpenGL ES 采用的是右手坐标，选取屏幕中心为原点，从原点到屏幕边缘默认长度为 1，也就是说默认情况下，从原点到（1,0,0）的距离和到（0,1,0）的距离在屏幕上展示的并不相同。坐标系向右为 X 正轴方向，向左为 X 负轴方向，向上为 Y 轴正轴方向，向下为 Y 轴负轴方向，屏幕面垂直向上为 Z 轴正轴方向，垂直向下为 Z 轴负轴方向。

![OpenGL坐标系](/imgs/OpenGL坐标系.png)

通俗的讲，在 OpenGL 中，世界就是一个坐标系，一个只有 X、Y 和 Z 三个纬度的世界，其它的东西都需要你自己来建设，你能用到的原材料就只有点、线和面(三角形)，当然还会有其他材料，比如阳光(光照)和颜色(材质)。

## 相机

OpenGL 中的“相机”和现实世界中的相机不是一个东西，但概念的相同的，都是捕获世界的景像呈现到二维平面上。可以将这里的“相机”想像成人眼，人眼看到的是什么样子，相机呈现的就是什么样子。

## 纹理

纹理是表示物体表面的一幅或几幅二维图形，也称纹理贴图（texture）。当把纹理按照特定的方式映射到物体表面上的时候，能使物体看上去更加真实。当前流行的图形系统中，纹理绘制已经成为一种必不可少的渲染方法。在理解纹理映射时，可以将纹理看做应用在物体表面的像素颜色。在真实世界中，纹理表示一个对象的颜色、图案以及触觉特征。**纹理只表示对象表面的彩色图案，它不能改变对象的几何结构**。

## 简单使用

本文中，我们主要是使用 GLSurfaceView。并且了解 OpenGL ES 的使用流程，其使用主流程可以概括如下：

![OpenGL_ES_的使用流程](/imgs/OpenGL_ES_的使用流程.png)

在 Android 中，使用 OpenGL 最简单的办法便是使用官方提供的 GLSurfaceView 组件。其功能包括但不限于：

1. 管理一个 surface，这个 surface 就是一块特殊的内存，能直接排版到 android 的视图 view 上。
2. 管理一个 EGL display，它能让 opengl 把内容渲染到上述的 surface 上。
3. 用户可以自定义渲染器(render)。
4. 让渲染器在独立的线程里运作，和 UI 线程分离。传统的 View 及其实现类，渲染等工作都是在主线程上完成的。
5. 支持按需渲染(on-demand)和连续渲染(continuous)。
6. 一些可选功能，如调试。

SurfaceView 实质是将底层显存 Surface 显示在界面上，而 GLSurfaceView 做的就是在这个基础上增加 OpenGL 绘制环境。

### 使用 GLSurfaceView

首先，在 MainActivity 中使用 GLSurfaceView。可以将 GLSurfaceView 理解成画布。

```java
public class MainActivity extends Activity {
    GLSurfaceView glsv;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        glsv = findViewById(R.id.glsv);
        // 设置 OpenGL 版本(一定要设置)
        glsv.setEGLContextClientVersion(2); 
        // 设置渲染器(后面会讲，可以理解成画笔)
        glsv.setRenderer(new MyRenderer());
        // 设置渲染模式为连续模式(会以 60 fps 的速度刷新)
        glsv.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
    }
}
```

xml 布局如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <android.opengl.GLSurfaceView
        android:id="@+id/glsv"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

</LinearLayout>
```

现在，OpenGL 的基本环境已经搭好了(即画布已经有了)，便可以作画了(定义画笔)。在 OpenGL 中，着色器 shader 就相当于画笔。主要有两种着色器：**顶点着色器(Vertex Shader)和片元着色器(Fragment Shader)。顶点着色器可以叫做点着色器，其负责定义待渲染(绘制)的图形的顶点信息；而片元着色器也可以叫做片着色器，其定义了如何填充图形**。比如现在我们想要绘制一个三角形，那么可以使用点着色器来定义三角形的三个顶点，三个顶点确定了，三角形的形状也就确定了。而片着色器可以定义填充颜色，即可以定义三角形三条边围成的区域，所呈现出的样子。

使用 GLSurfaceView 时，如果我们想要定义着色器，就得继承 GLSurfaceView.Renderer 类(Renderer 的意思便是渲染，即渲染器)。而 OpenGL ES 2.0 是针对可编程管线硬件的，自然与编程息息相关。

首先，我们需要定义着色器的构建程序。程序如何写，后面后详讲。

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    // 点着色器的脚本
    private static final String VERTEX_SHADER_SOURCE
            = "attribute vec2 vPosition;\n" // 顶点位置属性vPosition
            + "void main(){\n"
            + "   gl_Position = vec4(vPosition,0,1);\n" // 确定顶点位置
            + "}";

    // 片着色器的脚本
    private static final String FRAGMENT_SHADER_SOURCE
            = "precision mediump float;\n" // 声明float类型的精度为中等(精度越高越耗资源)
            + "uniform vec4 uColor;\n" // uniform的属性uColor
            + "void main(){\n"
            + "   gl_FragColor = uColor;\n" // 给此片元的填充色
            + "}";
}
```

然后，我们定义三个变量，其代表 OpenGL 中相关的索引。

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    // 程序索引
    private int program;
    // 顶点位置索引
    private int vPosition;
    // 片元所用颜色
    private int uColor;
}
```

第三步，定义构建着色器的方法，代码比较固定。

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    /**
     * 使用指定代码构建 shader
     *
     * @param shaderType shader 的类型，包括 GLES20.GL_VERTEX_SHADER(点着色器)和 GLES20.GL_FRAGMENT_SHADER(片着色器)
     * @param sourceCode shader 的创建脚本
     * 
     * @return 创建的 shader 的索引，创建失败会返回 0
     */
    private int loadShader(int shaderType,String sourceCode) {
        // 创建一个空的 shader 对象，并返回一个非 0 的引用标识。
        int shader = GLES20.glCreateShader(shaderType);
        // 创建失败
        if(shader == 0) {
            return 0;
        }
        // 若创建成功则加载 shader，指定源码
        GLES20.glShaderSource(shader, sourceCode);
        // 编译 shader 的源代码。
        GLES20.glCompileShader(shader);
        // 存放编译成功 shader 的数量的数组
        int[] compiled = new int[1];
        // 获取 Shader 的编译情况
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            //若编译失败则显示错误日志并删除此shader
            Log.e("ES20_ERROR", "Could not compile shader " + shaderType + ":");
            Log.e("ES20_ERROR", GLES20.glGetShaderInfoLog(shader));
            GLES20.glDeleteShader(shader);
            shader = 0;
        }
        return shader;
    }
}
```

**说明**

- 使用 glShaderSource 方法指定着色器对象的源码时，着色器对象的原有内容将被完全替换
- 使用 glCompileShader 编译 shader 的源代码时。应了解以下内容 --- Shader 编译器是可选的，如果不确定是否支持，可以调用 glGet 方法。使用参数 GL_SHADER_COMPILER 来查询。当 **glShaderSource、glCompileShader、glGetShaderPrecisionFormat 和 glReleaseShaderCompiler** 不支持时，会生成 GL_INVALID_OPERATION。
- glCompileShader 会编译已存储在由着色器指定的着色器对象中的源代码字符串，并将编译结果保存。可以通过 glGetShaderiv 来查询。无论编译是否成功，有关编译的信息都可以通过调用 glGetShaderInfoLog 从着色器对象的信息日志中获取。
- glGetShaderiv 可以查询 shader 对象的状态信息。参数包括 **GL_SHADER_TYPE、GL_DELETE_STATUS、GL_COMPILE_STATUS、GL_INFO_LOG_LENGTH（存储日志信息所需的字符缓冲区大小）、GL_SHADER_SOURCE_LENGTH（存储着色器源码所需的字符缓冲区的大小）**。

第四步，定义创建 program 的方法。

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    /**
     * 创建程序的方法
     */
    private int createProgram(String vertexSource, String fragmentSource) {
        //加载顶点着色器
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        if (vertexShader == 0) {
            return 0;
        }

        // 加载片元着色器
        int pixelShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (pixelShader == 0) {
            return 0;
        }

        // 创建程序
        int program = GLES20.glCreateProgram();
        if(program == 0){
            return 0;
        }
        // 若程序创建成功则向程序中加入顶点着色器与片元着色器
        // 向程序中加入点着色器
        GLES20.glAttachShader(program, vertexShader);
        // 向程序中加入片着色器
        GLES20.glAttachShader(program, pixelShader);
        // 链接程序
        GLES20.glLinkProgram(program);
        // 存放链接成功 program 数量的数组
        int[] linkStatus = new int[1];
        // 获取 program 的链接情况
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
        // 若链接失败则报错并删除程序
        if (linkStatus[0] != GLES20.GL_TRUE) {
            Log.e("ES20_ERROR", "Could not link program: ");
            Log.e("ES20_ERROR", GLES20.glGetProgramInfoLog(program));
            GLES20.glDeleteProgram(program);
            program = 0;
        }
        return program;
    }    
}
```

**说明**

 - glCreateProgram 函数将创建一个空的 program 对象，并返回一个非零的引用标识。program 对象可以附加和移除着色器对象，一般包含顶点着色器和片元着色器。program 会根据附加的着色器对象创建一些可执行文件，并使之成为当前渲染环境的一部分。
 - glAttachShader 将着色器对象附加到指定的 program 对象上，以便在链接时生成可执行文件。附加操作在着色器对象生成后，就可以进行。这意味着可以在着色器对象加载源码之前，就将它附加到 program 对象。
 - 多个相同类型的着色器对象可能不会附加到单个程序对象。但是，单个着色器对象可能会附加到多个程序对象。
 - 如果着色器对象在附加到程序对象时被删除，它将被标记为删除状态(实际未被删除)。调用 glDetachShader 方法，将它从所连接的所有程序对象中分离出来之后，删除操作才会进行。
 - glLinkProgram 执行链接操作，并保存链接状态。shader 将根据源码创建可执行文件，所有与 program 相关的用户定义的 uniform 变量将被初始化为 0，并且生成一个可以访问的地址。可以通过调用 glGetUniformLocation 来查询。所有未绑定到顶点属性索引的 attribute(属性)，此时都将被链接器绑定。分配的位置可以通过调用 glGetAttribLocation 来查询。
 - 对于附加的着色器对象，链接操作之后，program 可以自由修改、编译、分离、删除以及附加其他着色器对象。

第五步，获取图形顶点，此步骤用来定义图形形状：

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    /**
     * 获取图形的顶点
     *
     * @return 顶点 Buffer
     */
    private FloatBuffer getVertices() {
        float vertices[] = {
                0.0f,   0.5f,
                -0.5f, -0.5f,
                0.5f,  -0.5f,
        };

        // 创建顶点坐标数据缓冲
        // vertices.length*4是因为一个float占四个字节
        ByteBuffer vbb = ByteBuffer.allocateDirect(vertices.length * 4);
        // 设置字节顺序
        vbb.order(ByteOrder.nativeOrder());
        // 转换为Float型缓冲             
        FloatBuffer vertexBuf = vbb.asFloatBuffer();
        // 向缓冲区中放入顶点坐标数据    
        vertexBuf.put(vertices);
        // 设置缓冲区起始位置                        
        vertexBuf.position(0);                          
        // 返回数据结果
        return vertexBuf;
    }    
}
```

**说明**

 - Android 的 OpenGL 底层是用 C/C++ 实现的，所以和 Java 的数据类型字节序列有一定的区别，主要是数据的[大小端问题](https://baike.baidu.com/item/%E5%A4%A7%E5%B0%8F%E7%AB%AF%E6%A8%A1%E5%BC%8F/6750542?fr=aladdin)。ByteBuffer.order() 方法设置以下数据的大小端顺序，顺序设置为 native 层的数据顺序。使用 ByteOrder.nativeOrder() 可以得到 native 层的大小端数据顺序。

第六步，使用，进行具体绘制操作。主要是实现继承自 GLSurfaceView.Renderer 的三个方法：

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    /**
     * 当 GLSurfaceView 中的 Surface 被创建的时候(界面显示)回调此方法，一般在这里做一些初始化
     *
     * @param gl10 1.0 版本的 OpenGL 对象，这里用于兼容老版本，用处不大
     * @param eglConfig egl 的配置信息(GLSurfaceView 会自动创建 egl，这里可以先忽略)
     */
    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
        // 初始化着色器
        // 基于顶点着色器与片元着色器创建程序
        program = createProgram(verticesShader, fragmentShader);
        // 获取着色器中属性的位置引用 id(传入的字符串是着色器脚本中定义的属性名)
        vPosition = GLES20.glGetAttribLocation(program, "vPosition");
        uColor = GLES20.glGetUniformLocation(program, "uColor");

        // 设置清屏颜色，格式 RGBA，真正执行清屏是在 glClear() 方法调用后
        GLES20.glClearColor(1.0f, 0, 0, 1.0f);
    }

    /**
     * 当 GLSurfaceView 中的 Surface 被改变的时候回调此方法(一般是大小变化)
     *
     * @param gl10 同 onSurfaceCreated()
     * @param width Surface 的宽度
     * @param height Surface 的高度
     */
    @Override
    public void onSurfaceChanged(GL10 gl10, int width, int height) {
        // 设置绘图的窗口大小
        GLES20.glViewport(0,0,width,height);
    }

    /**
     * 当 Surface 需要绘制的时候回调此方法，根据 GLSurfaceView.setRenderMode() 设置的渲染模式不同回调的策略也不同：
     *     GLSurfaceView.RENDERMODE_CONTINUOUSLY : 固定一秒回调60次(60fps)
     *     GLSurfaceView.RENDERMODE_WHEN_DIRTY   : 当调用GLSurfaceView.requestRender()之后回调一次
     *
     * @param gl10 同 onSurfaceCreated()
     */
    @Override
    public void onDrawFrame(GL10 gl10) {
        // 获取图形的顶点坐标
        FloatBuffer vertices = getVertices();

        // 清屏
        GLES20.glClear(GLES20.GL_DEPTH_BUFFER_BIT | GLES20.GL_COLOR_BUFFER_BIT);

        // 使用某套shader程序
        GLES20.glUseProgram(program);
        // 为画笔指定顶点位置数据(vPosition)，数据传入 GPU 中。vPosition 可以理解成在 GPU 中的位置，而 vertices 是在 CPU 缓冲区中的数据
        GLES20.glVertexAttribPointer(vPosition, 2, GLES20.GL_FLOAT, false, 0, vertices);
        // 设置渲染器允许访问 GPU 中的数据
        GLES20.glEnableVertexAttribArray(vPosition);
        // 设置属性 uColor(颜色 索引,R,G,B,A) 的数值
        GLES20.glUniform4f(uColor, 0.0f, 1.0f, 0.0f, 1.0f);
        // 绘制
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 3);
    }
}
```

**说明**

- glGetAttribLocation 用于获取顶点属性索引(分配的位置)
- glClearColor 只是设置清屏颜色，格式 RGBA，并不会执行清屏操作。真正执行清屏是在 glClear(GLbitfield mask) 方法调用后。标准 OpenGL 中，该方法有 4 种标志位。但是在 Android 中，只有三种标志位。
    - GL_COLOR_BUFFER_BIT:    颜色缓冲
    - GL_DEPTH_BUFFER_BIT:    深度缓冲
    - GL_STENCIL_BUFFER_BIT:  模板缓冲
    - GL_ACCUM_BUFFER_BIT:    累积缓冲(Android 的 OpenGL ES 版本中不存在这种标志位)
- glUseProgram 设置 program 为当前渲染状态的一部分。如果 program 为 0，则当前渲染状态指向无效的 program，任何 glDrawArrays 或 glDrawElements 命令都会提示未定义。program 对象和与之关联的数据，可以在共享上下文的环境中共享。调用 glUseProgram 之后，program 已在使用中，此时会执行链接操作。如果链接成功，glLinkProgram 还会将生成的可执行文件安装为当前渲染状态的一部分。如果链接失败，其链接状态将设置为 GL_FALSE。但可执行文件和关联状态将保持为当前上下文状态的一部分。直到 program 将其删除为止。program 将其删除后，在成功重新链接之前，它不能成为当前状态的一部分。在 OpenGL ES 中，以下情况链接可能会失败：
    - 点着色器和片着色器都不在程序对象中
    - 超过支持的活动属性变量的数量
    - 超出统一变量(uniform)的存储限制和数量限制
    - 点着色器或片着色器的主要功能缺失
    - 在片着色器中实际使用的变量在点着色器中没有以相同方式声明（或者根本没有声明）
    - 未正确赋值函数或变量名称的引用
    - 共享的全局声明有两种不同的类型或两种不同的初始值
    - 一个或多个附加的着色器对象尚未成功编译(glCompileShader 方法)，或者未成功加载预编译的着色器二进制文件(通过 glShaderBinary 方法)
    - 绑定通用属性矩阵会导致，矩阵的某些行落在允许的最大值 GL_MAX_VERTEX_ATTRIBS 之外，找不到足够的连续顶点属性槽来绑定属性矩阵
 - **默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的。这意味着数据在着色器端是不可见的，哪怕数据已经上传到 GPU，由 glEnableVertexAttribArray 启用指定属性之后，才可在顶点着色器中访问顶点的属性数据**。我们可以将 CPU 看作客户端，GPU 看作服务器端。glVertexAttribPointer 只是建立了 CPU 和 GPU 之间的逻辑连接，从而实现了 CPU 数据上传至 GPU。但是，数据在 GPU 端是否可见，即着色器能否读取到数据。是由是否启用了对应的属性决定，这就是 glEnableVertexAttribArray 的功能，允许顶点着色器读取 GPU（服务器端）的数据。
 - glUniform4f 是 glUniform 的带后缀形式，因为 OpenGL ES 是由 C 语言编写的，但是 C 语言不支持函数的重载(native 层)，所以会有很多名字相同后缀不同的函数版本存在。
 - glDrawArrays 采用顶点数组方式绘制图形。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。OpenGL ES 2.0 以后，参数有如下几种(每种模式后都会带上一张图说明)：
    - GL_POINTS：点模式。单独的将顶点画出来
    - GL_LINES：直线模式。单独地将直线画出来
    - GL_LINE_LOOP：环线模式。连贯地将直线画出来，会自动将最后一个顶点和第一个顶点通过直线连接起来
    - GL_LINE_STRIP：连续直线模式。连贯地将直线画出来。即 P0、P1 确定一条直线，P1、P2 确定一条直线，P2、P3 确定一条直线。
    - GL_TRIANGLES：三角形模式。这个参数意味着 OpenGL 使用三个顶点来组成图形。所以，在开始的三个顶点，将用顶点1，顶点2，顶点3来组成一个三角形。完成后，再用下一组的三个顶点(顶点4，5，6)来组成三角形，直到数组结束。
    - GL_TRIANGLE_STRIP：连续三角形模式。用上个三角形开始的两个顶点，和接下来的一个点，组成三角形。也就是说，P0，P1，P2这三个点组成一个三角形，P1，P2，P3这三个点组成一个三角形，P2，P3，P4这三个点组成一个三角形。
    - GL_TRIANGLE_FAN：三角形扇形模式。跳过开始的2个顶点，然后遍历每个顶点，与它们的前一个，以及数组的第一个顶点一起组成一个三角形。也就是说，对于 P0，P1，P2，P3，P4 这 5 个顶点。绘制逻辑如下：
        - 跳过P0, P1, 从 P2 开始遍历
        - 找到 P2, 与 P2 前一个点 P1，与列表第一个点 P0 组成三角形：P0、P1、P2
        - 找到 P3, 与 P3 前一个点 P2，与列表第一个点 P0 组成三角形：P0、P2、P3
        - 找到 P4, 与 P4 前一个点 P3，与列表第一个点 P0 组成三角形：P0、P3、P4

最后，附上完整版的 Renderer 代码：

```java
public class MyRenderer implements GLSurfaceView.Renderer {
    private int program;
    private int vPosition;
    private int uColor;

    private int loadShader(int shaderType,String sourceCode) {
        int shader = GLES20.glCreateShader(shaderType);
        if (shader != 0) {
            GLES20.glShaderSource(shader, sourceCode);
            GLES20.glCompileShader(shader);
            int[] compiled = new int[1];
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
            if (compiled[0] == 0) {
                Log.e("ES20_ERROR", "Could not compile shader " + shaderType + ":");
                Log.e("ES20_ERROR", GLES20.glGetShaderInfoLog(shader));
                GLES20.glDeleteShader(shader);
                shader = 0;
            }
        }
        return shader;
    }

    private int createProgram(String vertexSource, String fragmentSource) {
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        if (vertexShader == 0) {
            return 0;
        }

        int pixelShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (pixelShader == 0) {
            return 0;
        }

        int program = GLES20.glCreateProgram();
        if (program != 0) {
            GLES20.glAttachShader(program, vertexShader);
            GLES20.glAttachShader(program, pixelShader);
            GLES20.glLinkProgram(program);
            int[] linkStatus = new int[1];
            GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
            if (linkStatus[0] != GLES20.GL_TRUE) {
                Log.e("ES20_ERROR", "Could not link program: ");
                Log.e("ES20_ERROR", GLES20.glGetProgramInfoLog(program));
                GLES20.glDeleteProgram(program);
                program = 0;
            }
        }
        return program;
    }
    private FloatBuffer getVertices() {
        float vertices[] = {
                0.0f,   0.5f,
                -0.5f, -0.5f,
                0.5f,  -0.5f,
        };
        // vertices.length*4是因为一个float占四个字节
        ByteBuffer vbb = ByteBuffer.allocateDirect(vertices.length * 4);
        vbb.order(ByteOrder.nativeOrder());            
        FloatBuffer vertexBuf = vbb.asFloatBuffer();   
        vertexBuf.put(vertices);                        
        vertexBuf.position(0);                          

        return vertexBuf;
    }

    @Override
    public void onSurfaceCreated(GL10 gl10, EGLConfig eglConfig) {
        program = createProgram(verticesShader, fragmentShader);
        vPosition = GLES20.glGetAttribLocation(program, "vPosition");
        uColor = GLES20.glGetUniformLocation(program, "uColor");
        GLES20.glClearColor(1.0f, 0, 0, 1.0f);
    }
    @Override
    public void onSurfaceChanged(GL10 gl10, int width, int height) {
        GLES20.glViewport(0,0,width,height);
    }

    @Override
    public void onDrawFrame(GL10 gl10) {
        FloatBuffer vertices = getVertices();
        GLES20.glClear(GLES20.GL_DEPTH_BUFFER_BIT | GLES20.GL_COLOR_BUFFER_BIT);
        GLES20.glUseProgram(program);
        GLES20.glVertexAttribPointer(vPosition, 2, GLES20.GL_FLOAT, false, 0, vertices);
        GLES20.glEnableVertexAttribArray(vPosition);
        GLES20.glUniform4f(uColor, 0.0f, 1.0f, 0.0f, 1.0f);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 3);
    }

    private static final String verticesShader
            = "attribute vec2 vPosition;            \n" 
            + "void main(){                         \n"
            + "   gl_Position = vec4(vPosition,0,1);\n" 
            + "}";

    private static final String fragmentShader
            = "precision mediump float;         \n" 
            + "uniform vec4 uColor;             \n"
            + "void main(){                     \n"
            + "   gl_FragColor = uColor;        \n"
            + "}";
}
```

下一篇，我们来讲讲 EGL 的使用。