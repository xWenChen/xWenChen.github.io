---
title: "Android 使用 camera2 录像"
description: "本文讲解了在 Android 中如何使用 camera2 录像"
keywords: "Android,音视频开发,camera2,录像"

date: 2024-01-06 17:11:00 +08:00
lastmod: 2024-01-06 17:11:00 +08:00

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

4 - CameraManager.getCameraIdList() 和 CameraManager.getCameraCharacteristics(cameraId) >>> 获取所有的相机列表，并筛选出其中可用的

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

**2/3/4 步和 1/2 步可以并行**

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



9 - 初始化相机