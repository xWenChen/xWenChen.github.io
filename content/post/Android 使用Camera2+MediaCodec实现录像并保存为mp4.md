---
title: "Android 使用Camera2+MediaCodec实现录像并保存为mp4"
description: "本文讲解了在 Android 中如何使用 camera2 录像，并使用MediaCodec编码保存到mp4文件。"
keywords: "Android,音视频开发,camera2,MediaCodec,录像"

date: 2025-03-06T19:34:00+08:00
lastmod: 2025-03-08T16:04:00+08:00

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

示例代码链接：[Camera2RecordVideoFragment](https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/video/Camera2RecordVideoFragment.kt)

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
// 设置比特率和帧率，帧率可以设置为30
format.setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
format.setInteger(MediaFormat.KEY_FRAME_RATE, FPS)
// 每秒一个关键帧
format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
codec?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
// 创建编码用的surface，视频预览和视频编码不是一个surface线程。
val codecSurface = codec?.createInputSurface()
// 启动MediaCodec
codec?.start()
```

对于比特率，youtube推荐的数值为：

- 如果视频的分辨率是 720p 时，比特率最好设置为 5 Mbps (bit/sec)。
- 如果视频的分辨率是 1080p 时，比特率最好设置为 8 Mbps (bit/sec)。
- 如果视频的分辨率是 1080p，帧率是 60 帧(fps)，比特率最好提高为 12 Mbps。

在创建MediaCodec和Surface后，我们就可以打开相机设备，并使用下面的代码创建CaptureSession(此时传入预览用的surface和编码用的surface)，并发送预览请求(此时将预览用的surface设置为target)。

```kotlin
// 用于预览和录像的 target surfaces
val targets = listOf(previewSurface, codecSurface)
// 创建会话
session = createCaptureSession(camera!!, targets, cameraHandler) ?: return
// 创建预览请求
val previewRequest = camera!!.createCaptureRequest(
    CameraDevice.TEMPLATE_PREVIEW
).apply {
    // 预览画面输出到 SurfaceView
    addTarget(previewSurface)
}.build()
// 提交预览请求，重复发送请求，直到调用了 session.stopRepeating() 方法
session!!.setRepeatingRequest(previewRequest, null, cameraHandler)
// 创建会话的方法封装，实现回调转协程。
suspend fun createCaptureSession(
    device: CameraDevice,
    targets: List<Surface>,
    handler: Handler? = null,
    onClose: (() -> Unit)? = null,
): CameraCaptureSession? = suspendCoroutine { cont ->
    device.createCaptureSession(
        targets, 
        object : CameraCaptureSession.StateCallback() {
            override fun onConfigured(session: CameraCaptureSession) = cont.resume(session)
            override fun onConfigureFailed(session: CameraCaptureSession) = cont.resume(null)
            override fun onClosed(session: CameraCaptureSession) { 
                super.onClosed(session)
                onClose?.invoke() 
            } 
        }, 
        handler
    )
}
```

此时，我们便可以看到预览画面了。如果用户按下录像按钮，开始录像；用户抬起手指，结束录像。

```kotlin
// 监听拍照按钮的点击
binding.captureButton.setOnTouchListener { view, event ->
    dealRecordVideo(view, event)
    true // 拦截操作
}
// 处理录像操作
private fun dealRecordVideo(view: View?, event: MotionEvent?) {
    view ?: return
    event ?: return

    when (event.action) {
        MotionEvent.ACTION_DOWN -> {
            if (!recordingStarted) {
                // 按下开始录像
                startRecord()
            }
        }
        MotionEvent.ACTION_UP -> {
            // 抬起结束录像
            stopRecord()
        }
    }
}
```

## 录像操作

要实现录像，我们需要创建一个录像的Request，并将预览用的surface和编码用的surface设置为Request的target。这样，系统就会将画面数据塞给这两个surface，我们就可以实现在预览的同时编码mp4数据。

当然，相机录像是个跨进程操作，需要一个异步线程专门处理，在代码中，我们是使用cameraThread+cameraHandler承载。同时，录像的编码操作也是个异步操作，需要放到一个异步线程中处理。在代码中，我们是启动了一个异步协程处理(Dispatchers.IO)。

在设置了录像的请求后，我们可以在`CameraCaptureSession.CaptureCallback`的`onCaptureCompleted`回调中从MediaCodec里获取到已编码的数据。

```kotlin
private val cameraThread = HandlerThread("CameraThread").apply { start() }
private val cameraHandler = Handler(cameraThread.looper)

private fun startRecord() {
    // 预览和编码不在一个线程和 surface 上。
    val previewSurface = binding.surfaceView.holder.surface ?: return
    // 异步处理录像操作
    lifecycleScope.launch(Dispatchers.IO) {
        // 记录开始录像的时间。
        recordingStartMillis = System.currentTimeMillis()
        recordingStarted = true

        // 创建录像的CaptureRequest
        val recordRequest = mCamera.createCaptureRequest(CameraDevice.TEMPLATE_RECORD).apply {
            // 设置预览和编码的surface
            addTarget(previewSurface)
            addTarget(codecSurface)
        }.build()

        // 创建录像请求，并获取数据。
        session?.setRepeatingRequest(
            recordRequest,
            object : CameraCaptureSession.CaptureCallback() {
                override fun onCaptureCompleted(session: CameraCaptureSession, request: CaptureRequest, result: TotalCaptureResult) {
                    // 捕获一帧数据成功时的回调。
                    if (isCurrentlyRecording()) {
                        encodeData()
                    }
                }

                override fun onCaptureFailed(
                    session: CameraCaptureSession,
                    request: CaptureRequest,
                    failure: CaptureFailure
                ) = Unit
            },
            cameraHandler
        )
    }
}
```

在encodeData中，我们主要从MediaCodec中获取编码后的数据，并进行保存操作：

```kotlin
// 视频路径
private val outputFile: File by lazy {
    // 目标文件
    File("${context.externalCacheDir}/视频录制/camera2+MediaCodec录制.mp4")
}
private val mMuxer = MediaMuxer(outputFile.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4) // 保存为 mp4

private fun encodeData(): Boolean {
    val mEncoder = codec ?: return false
    var encodedFrame = false // 是否成功编码的标识。
    var mVideoTrack: Int = -1 // 视频的轨道
    var mEncodedFormat: MediaFormat? = null

    while (true) {
        // 这里catch下，startRecord 和 stopRecord 位于不同的线程。处理录像操作可能已停止，但仍在获取OutputBuffer的情况。
        val encoderStatus = try {
            mEncoder.dequeueOutputBuffer(mBufferInfo, -1)
        } catch (e: Exception) {
            MediaCodec.INFO_TRY_AGAIN_LATER
        }

        if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
            // 录像结束
            break;
        }

        if ((mBufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
            // 忽略 BUFFER_FLAG_CODEC_CONFIG
            continue
        }

        if (mBufferInfo.size == 0) {
            continue
        }

        if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
            // 在收到buffer数据前回调，这个状态通常只回调一次。MediaFormat包含MediaMuxer需要的csd-0和csd-1数据。
            mEncodedFormat = mEncoder.outputFormat
            continue
        }

        if (encoderStatus < 0 || mEncodedFormat == null) {
            // 状态有问题，跳过编码。
            continue
        }

        val encodedData = mEncoder.getOutputBuffer(encoderStatus)
        if (encodedData == null) {
            continue
        }

        // 限制 ByteBuffer 的数据量，以使其匹配上 BufferInfo
        encodedData.position(mBufferInfo.offset)
        encodedData.limit(mBufferInfo.offset + mBufferInfo.size)

        // mp4文件中没有视频轨道，进行创建。
        if (mVideoTrack == -1) {
            mVideoTrack = mMuxer.addTrack(mEncodedFormat)
            mMuxer.setOrientationHint(characteristics?.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0)
            mMuxer.start()
        }

        // 编码后的数据写入 mp4 文件.
        mMuxer.writeSampleData(mVideoTrack, encodedData, mBufferInfo)
        encodedFrame = true

        mEncoder.releaseOutputBuffer(encoderStatus, false)

        if ((mBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
            // 编码结束。
            break
        }
    }

    return encodedFrame
}
```

至此，数据已经能保存到 mp4 文件中了。接下来讲讲结束录像时的操作。

## 结束录像

结束录像的时机是用户抬起手指时。因为录像和结束录像是在两个线程操作，所以我们上面的代码有进行相应的处理。

要结束录像，我们需要通知 CaptrueSession、MediacCodec、MediaMuxer 结束数据的生成和写入。并通知系统扫描新生成的文件。

```kotlin
private fun stopRecord() {
    // 录像和结束录像是两个线程
    lifecycleScope.launch(Dispatchers.Main) {
        session?.apply {
            // 通知CaptrueSession结束录制
            stopRepeating()
            close()
        }
        // 计算录像的时长，通常至少需要1秒。
        val elapsedTimeMillis = System.currentTimeMillis() - recordingStartMillis
        if (elapsedTimeMillis < MIN_TIME_MILLIS) {
            // MIN_TIME_MILLIS 是1秒。
            delay(MIN_TIME_MILLIS - elapsedTimeMillis)
        }
        // 延时 100 毫秒结束 MediacCodec，因为 CaptrueSession 的关闭可能需要时间。
        delay(100L)
        codec?.apply {
            stop()
            release()
        }
        mMuxer.stop()
        mMuxer.release()
        // 录像结束后，通知系统扫描文件
        notifyEndRecord()
    }
}
```

通知系统扫描新生成的文件，并使用系统页面打开视频的代码如下：

```kotlin
private fun notifyEndRecord() {
    MediaScannerConnection.scanFile(requireView().context, arrayOf(outputFile.absolutePath), null, null)
    // 打开系统预览页
    if (outputFile.exists()) {
        val authority = "${BuildConfig.APPLICATION_ID}.provider"
        val uri = FileProvider.getUriForFile(requireView().context, authority, outputFile)
        // 使用系统页面打开新生成的 Mp4 文件。
        startActivity(Intent().apply {
            action = Intent.ACTION_VIEW
            setDataAndType(
                uri,
                MimeTypeMap.getSingleton().getMimeTypeFromExtension(outputFile.extension)
            )
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_CLEAR_TOP
        })
    }
    recordingStarted = false
}
```

## 总结

至此，使用Camera2+MediaCodec实现录像并保存为mp4的实现过程就讲解完了。可以看出，和使用Camera2照相的过程大同小异，其主要区别有：

- CaptureRequest 的类型不同。
- target Surface 的列表和来源不同。
- 使用了 MediaCodec 进行视频编码。
- 使用了 MediaMuxer 写入数据到mp4文件中。

当然，使用相机拍出的录像是不带声音的，并且 mp4 文件中只有视轨，没有音轨。如果要编码声音，我们需要使用 AudioRecord，获取 pcm 数据进行编码。这部分知识我们放在后续的文章中讲解。