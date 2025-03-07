---
title: "Android 使用Camera2+MediaCodec实现录像并保存为mp4"
description: "本文讲解了在 Android 中如何使用 camera2 录像，并使用MediaCodec编码保存到mp4文件。"
keywords: "Android,音视频开发,camera2,MediaCodec,录像"

date: 2025-03-06T19:34:00+08:00
lastmod: 2025-03-06T19:34:00+08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - camera2
  - MediaCodec
  - 录像

url: post/D530DB2770DE4F9EAB299E7AB7C0B28E.html
toc: true
---

MediaCodec、MediaMuxer的讲解文章：[Android 使用 MediaCodec 解码 mp4](3A527688B2B346FD8911716A88CD4B9F.html)

Camera2的讲解文章：[Android 使用 Camera2 拍照](87B1186D69954900869DE7F54B269091.html)

示例代码链接：https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/video/Camera2RecordVideoFragment.kt

本文讲解了在 Android 中如何使用 camera2 录像，并使用MediaCodec编码保存到mp4文件。

<!--More-->

在Android中，要实现使用系统相机拍照，并保存为mp4文件，则需要实现以下操作：

1. 使用摄像头录像。
2. 获取到视频数据，进行编码。
3. 编码后的视频数据保存到mp4文件。

以上三个步骤，需要用到Android中三个不同的接口：

1. 可以使用Camera2 API实现摄像头录像。
2. 可以使用MediaCodec编码视频数据。
3. 可以使用MediaMuxer+File+OutputStream实现将编码后的视频数据保存到mp4文件。

![视频录制与编码API](/imgs/视频录制与编码API.webp)

关于Camera2、MediaCodec、MediaMuxer等如何使用，此处就不介绍了，以前的文章都有介绍过。不了解的朋友可以看以前的文章。此处只讲解下部分必要的知识点。

## 整体流程

Android使用Camera2+MediaCodec实现录像并保存为mp4功能的整体流程如下：

1. 初始化预览Surface。
2. 找到相机设备。
3. 确定合适的视频尺寸。
4. 创建编码视频时需要使用到的视频源Surface。
5. 打开相机。
6. 使用预览和编码视频的surfaces创建CaptureSession。
7. 创建预览请求，并重复发送。
8. 开始录像。重复发送录像请求。
9. 使用MediaCodec处理视频图像。
10. 使用MediaMuxer将视频图像写入到mp4文件。

相机效果想要呈现在页面上，通常要有个Surface用于承载预览画面，所以我们通常都是在Surface.Holder的surfaceCreated回调到来时，才进行相机的初始化操作。

而在相机的初始化过程中，我们需要进行视频的尺寸选择，视频受支持的尺寸列表可以使用`CameraCharacteristicss.get(CameraCharacteristicsSCALER_STREAM_CONFIGURATION_MAP).getOutputSizes(targetClass)`拿到，我们编译根据列表进行筛选，拿到我们想要的相机尺寸：

```kotlin
val SIZE_1080P = Size(1920, 1080)

// 3. 获取相机的属性集
val characteristics = cameraManager!!.getCameraCharacteristics(cameraId)
// 选择合适的尺寸，并配置 surface
videoSize = getPreviewOutputSize(
    // 获取屏幕尺寸
    surfaceView.display,
    characteristics!!,
    // 使用SurfaceHolder的类型获取尺寸列表
    SurfaceHolder::class.java
)

fun <T>getPreviewOutputSize(
    display: Display,
    characteristics: CameraCharacteristics,
    targetClass: Class<T>,
    format: Int? = null
): Size {
    // 取屏幕尺寸和 1080p 之间的较小值
    val maxSize = SIZE_1080P

    // 如果提供了 format，则根据 format 决定尺寸；否则使用目标 class 决定尺寸
    val config = characteristics.get(
        CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP
    ) ?: return maxSize.size

    // 查询可用的尺寸列表
    val allSizes = if (format == null) {
        config.getOutputSizes(targetClass)
    } else {
        config.getOutputSizes(format)
    }

    // 筛选条件自己定
    return allSizes.first()
}
```

注意上面的尺寸写法通常是 1920 * 1080，而不是 1080 * 1920。如果尺寸设置错误，录制出来的视频是无法识别的。当我们遇到视频无效的问题时，可以考虑是否是视频设置的有问题。

拿到了合适的尺寸后，我们就可以创建MediaCodec，以及创建用于编码视频的Surface。需要单独的Surface来编码视频是因为，视频预览和视频编码不是一个surface和线程。

![视频录制过程中Surface的作用](/imgs/视频录制过程中Surface的作用.webp)

我们可以使用下面的代码创建MediaCodec和对应的Surface。

```kotlin
val codec = MediaCodec.createEncoderByType(mimeType)
//　根据上面确定的视频尺寸，创建 MediaFormat，mimeType是 video/mp4。
val format = MediaFormat.createVideoFormat(mimeType, videoSize.width, videoSize.height)
// 设置视频的颜色格式
format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
// 设置比特率和帧率
format.setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
format.setInteger(MediaFormat.KEY_FRAME_RATE, FPS)
// 每秒一个关键帧
format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
codec?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
// 创建编码用的surface，视频预览和视频编码不是一个surface线程。
codecSurface = codec?.createInputSurface() ?: return
// 启动MediaCodec
codec?.start()
```

