---
title: "Android 使用 camera2 拍照"
description: "本文讲解了在 Android 中如何使用 camera2 拍照"
keywords: "Android,音视频开发,camera2,拍照"

date: 2023-05-14 18:18:00 +08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - camera2
  - 拍照

url: post/87B1186D69954900869DE7F54B269091.html
toc: true
---

本文讲解了在 Android 中如何使用 camera2 拍照。

<!--More-->

本文示例代码可见：[Github - Android Camera2 Take Photo](https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/image/Camera2TakePhotoFragment.kt)

## camera2 基础

从 Android 5.0 开始，Google 重新设计了相机功能的架构，并提供了 camera2 API，以取代已弃用的 camera API。android.hardware.camera2 包是提供了用于连接 Android 设备和各个相机设备的 API，这些 API 不仅大幅提高了Android 系统拍照的功能，还能支持 RAW 照片输出，甚至允许程序调整相机的对焦模式、曝光模式、快门等。

camera2 将相机设备建模为管道(pipeline)，该管道接受用于拍摄(capture)图像的 input request，并根据每个请求拍摄单个图像，然后输出一个捕获结果数据包(capture result metadata packet)，以及一组输出图像(output image buffers)。输入请求将按顺序处理，多个请求可以并行处理。在大多数 Android 设备上，通常有多个请求时，相机才能以完整的帧速率运行。Camera2 中的几个核心类如下：

![Camera2核心类](/imgs/Camera2核心类.png)

Camera2 的整体架构如图所示：

![Camera2整体架构图](/imgs/Camera2整体架构图.png)

上图已标记出出了使用 Camera2 拍照的整体流程：

![Camera2拍照整体流程](/imgs/Camera2拍照整体流程.png)

总得来讲，就是 Camera APP 通过 CameraManager 获取 CameraDevice，使用 CameraDevice 创建 CameraCaptureSession，CameraCaptureSession 发送 CaptureRequest, CameraDevices 收到请求后返回对应数据到对应的 Surface 中，Camera2 中预览/拍照/录像数据统一由 Surface 来接收，预览数据一般都是 SurfaceView, 拍照数据则在 ImageReader，录像则在 MediaCodec 中。整体来说就是一个请求--响应过程；请求完成后, 可以在回调中查询到相应的请求参数和 CameraDevice 的当前状态。CaptureRequest 代表请求控制的 Camera 参数, CameraMetadata(CaptureResult) 则表示当前返回帧中 Camera 使用的参数以及当前状态。

## 总体说明

要列举、查询和打开可用的相机设备，我们需要使用 CameraManager 类。

CameraDevice 类提供了一组静态属性信息，用于描述硬件设备，及其可用设置和输出参数。这些属性信息通过 CameraCharacteristics 类提供。我们可以通过调用 CameraManager.getCameraCharacteristics(cameraId) 方法获得。

想要从相机设备捕获图像或流式传输图像，app 必须首先使用 CameraDevice.createCaptureSession(SessionConfiguration) 创建一个相机捕获会话，该会话包含一组 output Surfaces，这些 surface 由相机设备使用。

每个 Surface 都必须预先配置适当的大小和格式，以匹配相机设备可用的大小和格式，这些格式和大小可以使用 StreamConfigurationMap 类获取。

我们可以从各种类中获取目标 Surface，包括 SurfaceView、MediaCodec、MediaRecorder、Allocation、ImageReader，以及通过 Surface(SurfaceTexture) 获取 SurfaceTexture 的 Surface。

通常，相机的预览图像会发送到 SurfaceView，或通过 SurfaceTexture 发送到 TextureView。

我们可以使用 JPEG 和 RAW_SENSOR 格式的 ImageReader，为 DngCreator(Dng 格式文件生成类)捕获 JPEG 图像或 RAW buffers。DngCreator 是个工具类，用于将 RAW Images 转成 Dng 图像。

在 RenderScript、OpenGL ES、native code 中或远程处理相机数据时，应用程序最好使用 YUV 类型的 Allocation 对象、SurfaceTexture、YUV_420_888 格式的 ImageReader。

捕获会话创建成功之后，app 需要构造一个 CaptureRequest，该请求定义了相机设备用于捕获单个图像所需的所有捕获参数。请求还列出了此次捕获已配置了的目标 output Surfaces。CameraDevice 有一个用于创建 CaptureRequest 的工厂方法 createCaptureRequest，该方法会返回 CaptureRequest.Builder。不过注意该方法会针对 Android 设备进行优化。

一旦设置了请求，就可以将其交给活跃的捕获会话，以进行图像捕获，捕获操作可以是一次性的(CameraCaptureSession.capture 方法)或无限重复的(CameraCaptureSession.setRepeatingRequest 方法)。重复请求的优先级低于一次性捕获，因此如果同时配置了一次和重复请求，则通过 capture() 提交的请求将在重复捕获之前被执行。capture 和 setRepeatingRequest 两种方法还有变体方法，其接受一个请求列表(Burst)。一次性列表捕获的优先级高于重复列表捕获。

处理了一个请求后，相机设备将生成一个 TotalCaptureResult 对象，其中包含了相机设备在捕获时的状态，以及最终采用的设置项。如果采用了近似的参数或解决了矛盾的参数，则 TotalCaptureResult 对象中的信息可能与 CaptureRequest 中的有所不同。相机设备同时还将向 CaptureRequest 中包含的每个 output Surfaces 发送一帧图像数据。这些图像数据的生成相对于 output CaptureResult 是异步的，有时会晚很多。

下面讲解下使用 Camera2 API 拍照的具体流程：

## 1. 获取 CameraManager

CameraManager 是 Android 系统提供的工具类，以方便 app 开发者管理和使用相机设备。我们可以使用 Context.getSystemService 方法获取 CameraManager 对象

```kotlin
val cameraManager = context.getSystemService(
    Context.CAMERA_SERVICE
) as CameraManager
```

## 2. 获取目标相机

要想通过 Camera2 API 获取到目标相机，我们需要列举所有相机并遍历、获取到每个相机的属性集，根据属性拿到我们需要的相机，

### 2-1. 获取相机 id 列表

要列举所有相机，我们可以使用 CameraManager.getCameraIdList 方法，该方法可以拿到所有相机的 id 列表。这些 id 包括其他 app 正在使用的、可拆卸的、不可拆卸的相机。不可拆卸相机使用从 0 开始的整数作为 id，而每个可拆卸相机都有一个唯一的 id。

```kotlin
// 1. 拿到所有相机的 id 列表
val cameraIdList = cameraManager.cameraIdList
```

### 2-2. 获取可用相机列表

拿到 id 列表后，我们就可以遍历 cameraIdList，并根据每个相机的描述信息，拿到可用的相机 id 列表。

```kotlin
// 2. 遍历每个相机，根据描述信息筛选出目标信息
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

- CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES 属性表示的是此相机设备声明的完全支持的功能列表。此 key 在所有设备上均可用。

   查询此键值，可以返回的值为：

      - BACKWARD_COMPATIBLE
      - MANUAL_SENSOR
      - MANUAL_POST_PROCESSING
      - RAW
      - PRIVATE_REPROCESSING
      - READ_SENSOR_SETTINGS
      - BURST_CAPTURE
      - YUV_REPROCESSING
      - DEPTH_OUTPUT
      - CONSTRAINED_HIGH_SPEED_VIDEO
      - MOTION_TRACKING
      - LOGICAL_MULTI_CAMERA
      - MONOCHROME
      - SECURE_IMAGE_DATA
   
   在 android.info.supportedHardwareLevel == FULL 时，以下功能保证可用： 
   
      - MANUAL_SENSOR
      - MANUAL_POST_PROCESSING 
      
   其他功能在 FULL 或 LIMITED 设备上可能可用，app 应查询此 key 以进行最终确定。

   列出功能列表是为了保证支持公共使用的功能都可用，特定的相机设备可能存在特定的功能子集。要查询这些特定的功能子集，需要查询以下每个内容：

   - android.request.availableRequestKeys
   - android.request.availableResultKeys
   - android.request.availableCharacteristicsKeys

- CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_BACKWARD_COMPATIBLE 属性表示每个相机设备支持的最小功能集。此功能会被所有普通相机设备列出，并表明相机设备具有与旧版 android.hardware.Camera API 的基础功能相兼容的功能集(即具备向后兼容的最小功能集)

   注意具有 DEPTH_OUTPUT 功能的设备可能不会列出此功能，以表明它们仅支持 depth 测量，而不支持标准颜色输出。

### 2-3. 筛选目标相机

拿到可用相机列表后，我们就可以从中筛选出我们想要的相机。通常我们会从相机朝向、相机输出格式(尺寸、颜色等信息)等方面进行筛选。

对于朝向信息，我们可以使用 CameraCharacteristics.LENS_FACING 从 CameraCharacteristics 中获得。camera2 中定义三种类型：前置相机、后置相机、外部相机。

- 前置相机的朝向和手机屏幕的方向相同。其对应的值为 CameraMetadata.LENS_FACING_FRONT
- 后置相机的朝向和手机屏幕的方向相反。其对应的值为 CameraMetadata.LENS_FACING_BACK
- 外部相机相对于手机屏幕来讲，朝向不固定，可前可后。其对应的值为 CameraMetadata.LENS_FACING_EXTERNAL

我们可以通过以下方法判断手机朝向：

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

对于输出格式，CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP 键对应的值列举了此相机设备支持的可用流配置、每个格式尺寸组合的最小帧持续时间和停顿持续时间。此 key 在所有设备上均可用。可参考 android.request.availableCapabilities 和 CameraDevice.createCaptureSession 的文档，以了解基于每个 Capability 的额外强制流配置

   所有相机设备都支持由 android.sensor.info.activeArraySize 定义的， 传感器的最大JPEG 格式分辨率。对于给定的用例，实际支持的最大分辨率可能低于 CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP 列出的分辨率，具体取决于图像数据的用途和图像数据的目标 Surface。例如，对于录制视频，视频 encoder 的最大尺寸限制(例如 1080p)可能小于相机可以提供的尺寸(例如最大分辨率为 3264x2448)。具体的信息需要参考图像数据的目标的文档，确定它是否限制了图像数据的最大尺寸。

   对于 JPEG 格式，尺寸可能受到以下条件的限制：

   - HAL 可能会为每个 Jpeg 尺寸选择合适的宽高比，这些宽高比通常是众所周知的宽高比(例如 4:3、16:9、3:2 等)。如果由 android.sensor.info.activeArraySize 定义的，传感器的最大分辨率的宽高比不是上述众所周知的宽高比，则此最大分辨率可以不用包含在被支持的 JPEG 尺寸列表中

   - 一些硬件 JPEG 编码器可能有像素边界对齐要求，例如 JPEG 的尺寸必须是 16 的倍数。因此，实际最大的 JPEG 尺寸可能会小于传感器最大分辨率。注意虽然尺寸会小，但是会尽可能向上述限制条件下的传感器最大分辨率靠齐。靠齐的要求为：在调整宽高比后，缩小的面积必须小于 3%。例如传感器最大分辨率为 3280x2464，如果最大 JPEG 尺寸的宽高比为 4:3，并且 JPEG 编码器对齐要求为 16，则最大 JPEG 尺寸将为 3264x2448。

   注意有时高分辨率图像传感器的相机设备对 QCIF 分辨率(176x144)的支持不完全，此时会出现不支持将 QCIF 分辨率的流与大于 1920x1080(1080x1920) 分辨率的任何其他流一起配置的情况；若一起配置了，捕获会话的创建将会失败。

我们可以使用 StreamConfigurationMap.getOutputFormats 方法获取流配置中的图像格式。此方法返回的所有图像格式都在 ImageFormat 或 PixelFormat 中定义，这两个类中定义的格式不会冲突。如果使用 isOutputSupportedFor(int) 查询是否支持对应的格式，则此方法返回的所有图像格式将返回 true。

如果想要判断相机设备是否支持输出 RAW buffers 及其对应的 metadata，可以使用 CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW 键值在 CameraCharacteristics 中进行查询。

支持 RAW 功能的设备允许数据直接保存为 DNG 文件，或者直接把 raw sensor images 交给 app 处理。

- 支持输出格式 ImageFormat.RAW_SENSOR
- RAW_SENSOR 流的最大可用分辨率是 android.sensor.info.pixelArraySize 或 android.sensor.info.preCorrectionActiveArraySize 中的一个值
- 所有与 DNG 相关的可选 metadata 均由相机设备提供

```kotlin
private data class FormatItem(
    val title: String, 
    val cameraId: String, 
    val format: Int
)

// 3. 筛选出目标相机：包括支持 JPEG/RAW/JPEG DEPTH 格式的相机列表
cameraIds.forEach { id ->
    // 根据 id 获取相机信息
    val characteristics = cameraManager.getCameraCharacteristics(id)
    val facingDesc = lensOrientationString(
        characteristics.get(CameraCharacteristics.LENS_FACING)!!
    )

    // 查询可用的能力和输出格式
    val capabilities = characteristics.get(
        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES
    )!!
    val outputFormats = characteristics.get(
        CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP
    )!!.outputFormats

    // 所有相机都必须支持 JPEG 格式，availableCameras 是目标相机列表
    targetCameras.add(
        FormatItem("$facingDesc JPEG ($id)", id, ImageFormat.JPEG)
    )

    // 判断是否支持 RAW，需要判断 capability 和 ImageFormat 两项
    if (capabilities.contains(
            CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW
        ) && outputFormats.contains(
            ImageFormat.RAW_SENSOR
        )
    ) {
        targetCameras.add(
            FormatItem("$facingDesc RAW ($id)", id, ImageFormat.RAW_SENSOR)
        )
    }

    // 判断支持 JPEG DEPTH capability 的相机
    if (capabilities.contains(
            CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT
        ) && outputFormats.contains(
            ImageFormat.DEPTH_JPEG
        )
    ) {
        targetCameras.add(
            FormatItem("$facingDesc DEPTH ($id)", id, ImageFormat.DEPTH_JPEG)
        )
    }
}
```

拿到相机列表后，我们就可以展示列表中，供用户选择。本文实例使用的是后置相机。

## 3. 打开相机设备

camera2 中，每个相机设备都用 CameraDevice 表示。

在拿到目标相机的 id 后，我们就可以打开相机了。使用 CameraManager.openCamera 方法打开相机，并设置 CameraDevice.StateCallback 回调监听相机设备的连接情况。

### StateCallback 讲解

调用 CameraManager.openCamera 方法打开相机设备时，必须提供 CameraDevice.StateCallback 回调实例。CameraDevice.StateCallback 用于接收相机设备状态的���新。这些状态更新包括：

- 设备完成启动，收到此事件后才能调用 createCaptureSession 方法创建会话
- 设备断开连接
- 设备关闭
- 设备出错

CameraDevice.StateCallback 回调的定义如下：

```java
public static abstract class StateCallback {
    // 由 onError 返回的错误码，表明相机设备已在使用中
    // 当其他更高优先级的 app 已在使用相机时，再打开对应相机会失败，并返回此错误
    public static final int ERROR_CAMERA_IN_USE = 1;
    // 由 onError 返回的错误码，表明打开的相机设备太多，无法再打开更多设备
    public static final int ERROR_MAX_CAMERAS_IN_USE = 2;
    // 由 onError 返回的错误码，表明由于设备策略而无法打开相机设备
    // 另见 DevicePolicyManager.setCameraDisabled(ComponentName, boolean)
    public static final int ERROR_CAMERA_DISABLED = 3;
    // 由 onError 返回的错误码，表明相机设备遇到了致命错误
    // 遇到此错误，相机设备需要重新调用 openCamera 方法才能再次使用
    public static final int ERROR_CAMERA_DEVICE = 4;
    // 由 onError 返回的错误码，表明相机服务出错，或者手机可能存在硬件问题
    // 遇到此错误，手机可能需要关机重启才能��复相机功能
    public static final int ERROR_CAMERA_SERVICE = 5;


    // 当相机完全开启后，此回调生效。此时相机设备就可以使用了。
    // 之后可以调用 createCaptureSession 方法来创建 capture session。
    //
    // 方法的入参是已打开的相机设备。
    public abstract void onOpened(@NonNull CameraDevice camera);
    // 调用 CameraDevice.close 方法关闭相机设备时，此回调生效
    //
    // close 后，调用此 CameraDevice 上的任何方法，
    // 都将抛出 IllegalStateException。此方法的默认实现不执行任何操作。
    //
    // 方法的入参是已关闭的相机设备。
    public void onClosed(@NonNull CameraDevice camera) {
    }
    // 当相机设备断开连接不再可用，或者可能打开相机失败时，此回调生效
    // 
    // disconnect 后，调用此 CameraDevice 上的任何方法，
    // 都将引发 CameraAccessException。
    // 
    // 相机断开连接的原因可能有：
    //   - 安全策略或权限的更改
    //   - 可移动相机设备物理断开连接
    //   - 更高优先级的相机 app 需要使用此相机蛇别
    //
    // 调用此方法后，capture callbacks 可能仍会调用，或者
    // 新的 image buffers 仍会被传递到 active outputs。
    // 
    // 收到此回调后，我们应该调用 CameraDevice.close 方法关闭相机，进行清理
    //
    // 方法的入参是已经断开连接的相机设备
    public abstract void onDisconnected(@NonNull CameraDevice camera);
    // 当相机设备遇到严重错误时调用的方法。如果相机打开失败，可能会调用此回调。
    //
    // error 时，调用此 CameraDevice 上的任何方法都将抛出 CameraAccessException。
    //
    // 收到此错误后，可能仍会调用 capture completion，
    // 或者可能仍会调用 camera stream callbacks
    //
    // 收到此错误后，我们应该调用 CameraDevice.close 方法关闭相机，进行清理。
    // 恢复操作的尝试应该根据 errorCode 进行判断
    //
    // 方法的入参为出错的相机设备，及其对应的错误码
    public abstract void onError(
        @NonNull CameraDevice camera,
        @ErrorCode int error
    );
}
```

### 打开操作

因为打开相机是个异步的操作，所以在 kotlin 中，可以使用回调转协程的能力，摆脱回调地狱。

```kotlin
fun open() {
    // 相机操作运行的线程
    val cameraThread = HandlerThread(
        "CameraThread"
    ).apply { 
        start() 
    }

    val cameraHandler = Handler(cameraThread.looper)
    // 打开相机，类型是 CameraDevice
    var camera = openCamera(cameraId, cameraHandler)
}


// 打开相机的方法，用到了回调转协程
private suspend fun openCamera(
    cameraId: String,
    handler: Handler? = null
): CameraDevice = suspendCancellableCoroutine { cont ->
    // CameraManager.openCamera 方法
    manager.openCamera(
        cameraId, object : CameraDevice.StateCallback() {
            override fun onOpened(
                device: CameraDevice
            ) = cont.resume(device)

            override fun onDisconnected(
                device: CameraDevice
            ) {
                activity.finish()
            }

            override fun onError(
                device: CameraDevice, 
                error: Int
            ) {
                val msg = when (error) {
                    // 错误码定义在 CameraDevice.StateCallback 中
                    ERROR_CAMERA_DEVICE -> "Fatal (device)"
                    ERROR_CAMERA_DISABLED -> "Device policy"
                    ERROR_CAMERA_IN_USE -> "Camera in use"
                    ERROR_CAMERA_SERVICE -> "Fatal (service)"
                    ERROR_MAX_CAMERAS_IN_USE -> "Maximum cameras in use"
                    else -> "Unknown"
                }
                val exc = RuntimeException(
                    "Camera $cameraId error: ($error) $msg"
                )
                Log.e(TAG, exc.message, exc)
                if (cont.isActive) {
                    cont.resumeWithException(exc)
                }
            }
        }, 
        handler
    )
}
```

## 4. 创建捕获会话

相机打开成功后，我们就可以创建 app 与相机之间的捕获会话了。因为相机被建模成了 pipeline。所以捕获会话可以认为是 app 与管道之间的会话。创建会话需要使用 CameraDevice.createCaptureSession 方法。

createCaptureSession 方法通过向相机设备提供 output Surfaces 列表来创建新的 CameraCaptureSession。

CameraCaptureSession 创建成功后，可以使用 CameraCaptureSession.capture、CameraCaptureSession.captureBurst、CameraCaptureSession.setRepeatingRequest 或 CameraCaptureSession.setRepeatingBurst 方法提交捕获请求。

虽然系统的相机服务是常驻的，但是底层的相机硬件也像软件一样，用时才开启，不用就关闭。故创建 CameraCaptureSession 时，会话配置可能需要数百毫秒才能完成，因为相机硬件可能需要开机或重新配置。一旦会话配置完成并且准备捕获数据，则 CameraCaptureSession.StateCallback 的 onConfigured 回调方法将被调用。

如果调用 createCaptureSession 方法时已经存在 CameraCaptureSession，则之前的 Session 将无法再接受新的 capture requests，但任何正在进行的捕获请求将继续执行完成。在没有捕获请求后，Session 将被 closed。新会话的 CameraCaptureSession.StateCallback.onConfigured 回调方法可能在旧会话的 CameraCaptureSession.StateCallback.onClosed 回调方法之前触发。为了尽量缩减过渡时间，可以在创建新会话之前使用 CameraCaptureSession.abortCaptures 方法丢弃旧会话的剩余请求。

注意一旦创建了新会话，则旧会话就无法再 abort captures。

注意使用更高分辨率或更多的输出，可能会导致相机设备的输出速率变慢。

活跃中的捕获会话会为相机设备的每个捕获请求确定一组 output Surfaces。每个捕获请求可以使用全部或部分的 output Surfaces。各种场景和目标都可以获取合适的可作为相机输出的 Surfaces：

- 如果相机图像要绘制到 SurfaceView 中，则可以通过以下步骤获取 Surface：

   1. 等待 SurfaceView 的 Surface 创建，创建成功的标志是 SurfaceHolder.Callback.surfaceCreated 方法被回调
   2. Surface 被创建后，使用 SurfaceHolder.setFixedSize 方法为 Surface 设置尺寸，尺寸是 StreamConfigurationMap.getOutputSizes(SurfaceHolder.class) 方法返回的值之一
   3. 调用 SurfaceHolder.getSurface 方法获取 Surface 实例。如果 app 未设置尺寸，则相机设备会将尺寸设置为小于但最接近 1080p 的受支持的尺寸

- 如果 OpenGL 纹理想要通过 SurfaceTexture 访问相机图像，则在使用 SurfaceTexture.setDefaultBufferSize 方法为 SurfaceTexture 设置尺寸后，可以使用 SurfaceTexture 创建 Surface。尺寸是 StreamConfigurationMap.getOutputSizes(SurfaceTexture.class) 方法返回的值之一。如果 app 未设置尺寸，则相机设备会将尺寸设置为小于 1080p 的最小的受支持的尺寸

- 如果想要使用 MediaCodec 录制视频，则在使用 StreamConfigurationMap.getOutputSizes(MediaCodec.class) 返回的一个尺寸配置 MediaCodec 后，需要调用 MediaCodec.createInputSurface 方法创建 Surface

- 如果想要使用 MediaRecorder 录制视频：则在使用 StreamConfigurationMap.getOutputSizes(MediaRecorder.class) 方法返回的一个尺寸配置 MediaRecorder 后，或在 MediaRecorder 被配置为使用被支持的 CamcorderProfiles 之一后，需要调用 MediaRecorder.getSurface 获取 Surface

- 如果想要 android.renderscript 进行高效的 YUV 处理：我们需要创建一个 RenderScript Allocation 对象，该对象具有 YUV 类型、IO_INPUT 标志与 StreamConfigurationMap.getOutputSizes(Allocation.class) 方法返回的尺寸，然后我们可以使用 Allocation.getSurface 获取 Surface。

- 如果想要在 app 中访问 RAW、YUV 或 JPEG 数据，我们需要创建一个 ImageReader 对象，该对象使用 StreamConfigurationMap.getOutputFormats() 方法返回的输出格式之一，并将其尺寸设置为 StreamConfigurationMap.getOutputSizes(int format) 方法返回的尺寸。然后使用 ImageReader.getSurface() 从中获取一个 Surface。如果 ImageReader 的尺寸未设置为合适的值，则尺寸会被相机设备四舍五入到小于 1080p 的被支持的大小。

相机设备在调用 Surface 时将查询每个 Surface 的大小和格式，因此必须为 Surface 设置有效的值。

使用 empty or null list 配置会话，将关闭当前会话。这可用于释放当前会话的 target surfaces，以供其他用途。

创建捕获会话的知识点暂时就讲这么多。

### 4-1. 确定目标尺寸

创建会话时，我们首先需要传入会话的配置参数，其中很重要的一项就是图片的尺寸。我们可以使用 CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP 键值通过 CameraCharacteristics.get(Key) 方法拿到 StreamConfigurationMap 配置表。然后使用 StreamConfigurationMap.getOutputSizes(int format) 方法格式的尺寸列表，并从中选出合适的尺寸。

```kotlin
val size = characteristics.get(
    CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP
)!!.getOutputSizes(pixelFormat).maxBy { 
    // 从尺寸列表中选出面积最大的尺寸
    it.height * it.width
}!!
```

### 4-2. 创建目标 surface

确定好尺寸后，我们就可以确定传给会话的 target surface，surface 的来源有很多。此处传入俩个：IamgeReader 和 SurfaceView 的 surface。其中 SurfaceView 用于画面预览，IamgeReader 用于保存实际的图片。

注意 SurfaceView 的 surface 需要在 SurfaceHolder.Callback.surfaceCreated 回调被触发时才能获取到。所以我们需要在 onCreate 一开始就设置监听。注意 surface 的回调监听不能设置的太晚，否则会出现间歇性黑屏(出现概率较高)：

```kotlin
binding.surfaceView.holder.addCallback(
    object : SurfaceHolder.Callback {
        override fun surfaceDestroyed(holder: SurfaceHolder) = Unit

        override fun surfaceChanged(
            holder: SurfaceHolder,
            format: Int,
            width: Int,
            height: Int
         ) = Unit

        override fun surfaceCreated(holder: SurfaceHolder) {
            realOpenCamera()
        }
})
```

在 Surface 创建完成后，打开 camera 之前，我们还需要确定权限是否被授予。因为录像会用到 CAMERA 和 RECORD_AUDIO 两个权限。这两个权限都是动态权限。需要走动态权限的申请流程。此处就不细讲了。

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

有了权限，打开相机后。创建 ImageReader、获取 target surfaces 的代码很简单。

```kotlin
val imageReader = ImageReader.newInstance(
    size.width, 
    size.height, 
    pixelFormat, 
    3 // image reader 的 buffer 中最多缓存 3 张图片
)

val targets = listOf(
    surfaceView.holder.surface, 
    imageReader.surface
)
```

### 4-3. 创建 CaptureSession

确定好需要传给会话的配置后，就可以调用 CameraDevice.createCaptureSession 方法创建会话了。

```kotlin
val session = createCaptureSession(
    camera, 
    targets, 
    cameraHandler
)
// 回调转协程
private suspend fun createCaptureSession(
    device: CameraDevice,
    targets: List<Surface>,
    handler: Handler? = null
): CameraCaptureSession = suspendCoroutine { cont ->
    device.createCaptureSession(
        targets, 
        object : CameraCaptureSession.StateCallback() {
            override fun onConfigured(
                session: CameraCaptureSession
            ) = cont.resume(session)

            override fun onConfigureFailed(
                session: CameraCaptureSession
            ) {
                val exc = RuntimeException(
                    "Camera ${device.id} session configure failed"
                )
                Log.e(TAG, exc.message, exc)
                cont.resumeWithException(exc)
            }
        }, 
        handler
    )
}
```

## 5. 创建预览请求并提交

捕获会话创建成功后，我们就可以创建捕获请求了。同拍照一样，预览画面也是相机十分重要的功能。所以我们需要优先创建用于预览的捕获请求。可通过以下步骤进行预览：

1. 创建 CameraDevice.TEMPLATE_PREVIEW 类型的 CaptureRequest

2. 将预览请求的画面输出到 SurfaceView

3. 设置重复请求图像数据。预览时的画面需要实时更新，所以我们需要设置重复请求，直到捕获会话断开，或者不再进行预览。

```kotlin
// camera 是 CameraDevice 实例
val captureRequest = camera.createCaptureRequest(
    // 1. 创建预览请求
    CameraDevice.TEMPLATE_PREVIEW
)
// 2. 画面输出到 SurfaceView
captureRequest.addTarget(surfaceView.holder.surface) 
// 3. 提交重复请求图像数据，直到会话断开或调用了 session.stopRepeating()
session.setRepeatingRequest(
    captureRequest.build(), 
    null, 
    cameraHandler
)
```

## 6. 创建拍照请求

开始预览画面后，我们就可以等待用户按下拍照按钮进行拍照。拍照时需要创建拍照请求。创建的代码很简单，使用 CameraDevice.TEMPLATE_STILL_CAPTURE type 即可，我们可以把 imageReader.surface 添加为拍照请求的目标输出：

```kotlin
val captureRequest = session.device.createCaptureRequest(
    CameraDevice.TEMPLATE_STILL_CAPTURE
)

captureRequest.addTarget(imageReader.surface) 
```

## 7. 拍摄照片

创建好照片拍摄请求后，我们就可以进行拍照了。拍照涉及了几个方面的知识点。

### 7-1. 获取拍摄的图像数据

因为我们上面把 imageReader 的 surface 设置为了拍照请求的目标输出，所以我们可以通过 imageReader 获取拍摄到的图像数据，并使用列表将其缓存起来，此处使用阻塞队列 ArrayBlockingQueue 存储。要判断图像数据是否可用，我们可以通过 ImageReader.setOnImageAvailableListener 方法设置拍摄图像可用时的监听。

```kotlin
val imageReaderThread = HandlerThread("imageReaderThread").apply { 
    start() 
}
val imageReaderHandler = Handler(imageReaderThread.looper)
// 最多缓存 3 张图片
val imageQueue = ArrayBlockingQueue<Image>(3)
// 设置监听，在图像可用时，将图像存入队列中
imageReader.setOnImageAvailableListener({ reader ->
    val image = reader.acquireNextImage()
    Log.d(TAG, "Image available in queue: ${image.timestamp}")
    // 图片塞入阻塞队列中，如果已满则抛出异常
    imageQueue.add(image)
}, imageReaderHandler)
```

### 7-2. 状态回调

向会话提交的每个捕获请求都必须设置一个 CameraCaptureSession.CaptureCallback 类型的捕获状态回调。

CameraCaptureSession.CaptureCallback 是个 abstract 类，其目的是追踪提交到相机设备的 CaptureRequest 的处理进度。当 CaptureRequest 对应的 capture 开始以及完成时，此回调将被触发。如果捕获图像时出错，将触发错误回调而不是完成回调。

### 7-3. 提交拍照请求

创建了图像的监听回调，并创建了图片拍照请求后，我们就可以提交拍照请求了。拍摄请求的提交主要涉及以下 4 个方法，方法的具体含义本文就不细讲了，此处只讲下它们的作用：

```java
public abstract class CameraCaptureSession 
    implements AutoCloseable {
    // 提交一个 CaptureRequest
    public abstract int capture(
        @NonNull CaptureRequest request,
        @Nullable CaptureCallback listener, 
        @Nullable Handler handler
    ) throws CameraAccessException;
    // 提交一个 CaptureRequest 列表
    public abstract int captureBurst(
        @NonNull List<CaptureRequest> requests,
        @Nullable CaptureCallback listener, 
        @Nullable Handler handler
    ) throws CameraAccessException;
    // 提交一个 Repeat 模式的 CaptureRequest
    public abstract int setRepeatingRequest(
        @NonNull CaptureRequest request,
        @Nullable CaptureCallback listener, 
        @Nullable Handler handler
    ) throws CameraAccessException;
    // 提交一个 Repeat 模式的 CaptureRequest 列表
    public abstract int setRepeatingBurst(
        @NonNull List<CaptureRequest> requests,
        @Nullable CaptureCallback listener, 
        @Nullable Handler handler
    ) throws CameraAccessException;
}
```

此处我们使用 capture 方法提交请求：

```kotlin
session.capture(
    captureRequest.build(), 
    object : CameraCaptureSession.CaptureCallback() {
        override fun onCaptureStarted(
            session: CameraCaptureSession,
            request: CaptureRequest,
            timestamp: Long,
            frameNumber: Long
        ) {
            super.onCaptureStarted(
                session, 
                request, 
                timestamp, 
                frameNumber
            )
            // 拍摄开始时播放动画
            surfaceView.post(animationTask)
        }

        override fun onCaptureCompleted(
            session: CameraCaptureSession,
            request: CaptureRequest,
            result: TotalCaptureResult
        ) {
            // 拍照完成的代码后面单独讲
        }, 
    cameraHandler
)
```

### 7-4. 拍照完成，获取图片
 
提交拍照请求后，我们就可以通过 CameraCaptureSession.CaptureCallback 回调监测拍照完成，当拍照完成时，CameraCaptureSession.CaptureCallback.onCaptureCompleted 回调方法会被触发。我们可以在该方法中实现拍照完成的相关逻辑。拍照完成后，我们主要做以下事情：

1. 获取图片拍摄时间
2. 获取拍摄的图像
2. 返回结果，超时失败

```kotlin
override fun onCaptureCompleted(
    session: CameraCaptureSession,
    request: CaptureRequest,
    result: TotalCaptureResult
) {
    super.onCaptureCompleted(session, request, result)
    // 获取当前会话处理的 request 的图片的完成时间
    val resultTimestamp = result.get(
        CaptureResult.SENSOR_TIMESTAMP
    )
    Log.d(TAG, "Capture result received: $resultTimestamp")
    // 设置获取图片的等待时长，5 秒后取消获取图片的动作
    val exc = TimeoutException("Image dequeuing took too long")
    val timeoutRunnable = Runnable { throw exc }
    imageReaderHandler.postDelayed(timeoutRunnable, 5000)

    // 死循环获取目标图片数据
    lifecycleScope.launch(cont.context) {
        while (true) {
            // 将元素从出队，队列中无元素时会阻塞并等待
            val image = imageQueue.take()
            // 如果图片与当前回调对应的图片不同，则不处理
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q 
                && image.format != ImageFormat.DEPTH_JPEG 
                && image.timestamp != resultTimestamp
            ) {
                continue
            }
            Log.d(TAG, "Matching image dequeued: ${image.timestamp}")
            // 拿到图片后取消超时回调，并移除剩余图片数据
            imageReaderHandler.removeCallbacks(timeoutRunnable)
            imageReader.setOnImageAvailableListener(null, null)  
            while (imageQueue.size > 0) {
                imageQueue.take().close()
            }

            // 计算旋转角度与朝向
            val rotation = relativeOrientation.value ?: 0

            val mirrored = characteristics.get(
                CameraCharacteristics.LENS_FACING
            ) == CameraCharacteristics.LENS_FACING_FRONT

            val exifOrientation = computeExifOrientation(
                rotation, 
                mirrored
            )

            return CombinedCaptureResult(
                image, 
                result, 
                exifOrientation, 
                imageReader.imageFormat
            )
        }
    }
}
```

### 7-5. 保存图片

拿到图片相关数据后，我们就可以直接保存。保存图片主要经过以下几步：

1. 获取图片 File 对象
2. 获取图片数据
3. 图片数据写入 File
4. 处理图片的 Exif信息

```kotlin
private suspend fun saveResult(
    result: CombinedCaptureResult
): File = suspendCoroutine { cont ->
    when (result.format) {
        // 图片格式如果是 JPEG 或者 DEPTH JPEG
        // 则可以直接使用 inputStream 保存到 File
        ImageFormat.JPEG, 
        ImageFormat.DEPTH_JPEG -> {
            val buffer = result.image.planes[0].buffer
            // 使用 ByteBuffer 构建 ByteArray
            val bytes = ByteArray(buffer.remaining()).apply { 
                buffer.get(this) 
            }
            try {
                val output = createFile(requireContext(), "jpg")
                // 图片数据保存到文件
                FileOutputStream(output).use { 
                    it.write(bytes) 
                }
                cont.resume(output)
            } catch (e: IOException) {
                Log.e(TAG, "fail to write JPEG image to file", e)
                cont.resumeWithException(exc)
            }
        }

        // 图片格式如果是 RAW
        // 则需要使用 DngCreator 工具类将图片保存为 dng
        ImageFormat.RAW_SENSOR -> {
            // characteristics 是当前被打开相机的属性集
            val dngCreator = DngCreator(
                characteristics, 
                result.metadata
            )
            try {
                val output = createFile(requireContext(), "dng")
                FileOutputStream(output).use { 
                    dngCreator.writeImage(it, result.image) 
                }
                cont.resume(output)
            } catch (exc: IOException) {
                Log.e(TAG, "fail to write DNG image to file", exc)
                cont.resumeWithException(exc)
            }
        }

        // 本示例暂不支持其他格式
        else -> {
            val e = RuntimeException(
                "Unknown image format: ${result.image.format}"
            )
            Log.e(TAG, exc.message, e)
            cont.resumeWithException(e)
        }
    }
}
```

至此，使用 Camera2 拍照的步骤就讲解完成了。