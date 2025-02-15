---
title: "Android获取屏幕尺寸的知识点"
description: "本文讲解了 Android 获取屏幕尺寸的知识点"
keywords: "Android,屏幕尺寸"

date: 2024-02-05T15:37:00+08:00

categories:
  - Android
  - 屏幕尺寸
tags:
  - Android
  - 屏幕尺寸
  - 多窗口模式

url: post/F092CD66D82F45DD91AA8DDCEC14EECC.html
toc: true
---

本文讲解了 Android 获取屏幕尺寸的知识点。

<!--More-->

## Android 的多窗口模式

在 Android 7.0 及更高版本中，Android 设备可以使用多窗口模式同时显示多个应用。Android 支持三种多窗口模式配置：

- 分屏：分屏是默认的多窗口模式实现，可为用户提供两个 activity 窗格来放置应用。
- 自由窗口：自由窗口允许用户动态调整 activity 窗格大小，并在屏幕上显示两个以上的应用。
- 画中画：画中画 (picture in picture, PIP) 模式允许 Android 设备在用户与其他应用互动时，在小窗口中播放视频内容。

官方相关文档链接如下：

- 支持多窗口模式：https://source.android.google.cn/docs/core/display/multi-window?hl=zh-cn
- 多窗口支持：https://developer.android.google.cn/guide/topics/large-screens/multi-window-support?hl=zh-cn#testing
- 画中画：https://source.android.google.cn/docs/core/display/pip?hl=zh-cn
- 分屏交互：https://source.android.google.cn/docs/core/display/split-screen?hl=zh-cn

## 屏幕尺寸获取

下面方式获取屏幕尺寸，不适用于分屏、自由窗口、画中画模式等情况。因为该代码获取的是整个屏幕的尺寸，不是 Activity 的尺寸：

```kotlin
var manager = getSystemService(WINDOW_SERVICE) as? WindowManager ?: return
fun getScreenWidth(): Int {
    val point = Point()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
        manager.defaultDisplay.getRealSize(point)
    } else {
        manager.defaultDisplay.getSize(point)
    }
    return point.x
}
fun getScreenHeight(): Int {
    val point = Point()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
        manager.defaultDisplay.getRealSize(point)
    } else {
        manager.defaultDisplay.getSize(point)
    }
    return point.y
}
```

获取屏幕尺寸的 API 通常有两套：DisplayMetrics 和 Configuration。非分屏、自由窗口、画中画模式下，这两套 API 都可以正常使用，但是如果是分屏、自由窗口、画中画模式，则可能会出现问题。

```kotlin
var displayMetrics: DisplayMetrics = Resources.getSystem().displayMetrics ?: return
var configuration: Configuration = resources.configuration ?: return

// 分屏下可能有误
val displayMetricsInfo = StringBuilder("").apply {
    append("DisplayMetrics Info: \n\n")
    append("density = ${displayMetrics.density}\n")
    append("densityDpi = ${displayMetrics.densityDpi}\n")
    append("xdpi = ${displayMetrics.xdpi}\n")
    append("ydpi = ${displayMetrics.ydpi}\n")
    append("widthPixels = ${displayMetrics.widthPixels}\n")
    append("heightPixels = ${displayMetrics.heightPixels}\n")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        manager.currentWindowMetrics.let {
            append("current size = ${it.bounds.width()} x ${it.bounds.height()} \nbounds = ${it.bounds}\n")
            //append("currentWindowMetrics windowInsets = ${it.windowInsets}\n")
        }
    }
}

val configurationInfo = StringBuilder("").apply {
    append("Configuration Info: \n\n")
    append("screenSize = ${getScreenWidth()} x ${getScreenHeight()}\n")
    append("densityDpi = ${configuration.densityDpi}\n")
    append("sp = ${configuration.fontScale}\n")
    append("screenWidthDp = ${configuration.screenWidthDp}\n")
    append("screenHeightDp = ${configuration.screenHeightDp}\n")
    append("smallestScreenWidthDp = ${configuration.smallestScreenWidthDp}\n")
}

binding.display.text = displayMetricsInfo
binding.config.text = configurationInfo
```

以小米 9 手机为例，全屏模式下，得到的数据如下：

![全屏模式下的相关尺寸数据](/imgs/全屏模式下的相关尺寸数据.jpg)

其中 392 = 1080 / 2.75，即 screenWidthDp = widthPixels / density； 807 = 2221 / 2.75，即 screenHeightDp = heightPixels / density。

而切换为分屏、自由窗口等场景，要精准获取 Activity 的尺寸，就只有用 WindowManager 的 WindowMetrics 了。

每个 Activity 都与一个 Window 关联。Window 负责的内容如下：

1. 创建和管理视图层次结构：Window 负责创建和管理 Activity 中的视图层次结构，包括布局、控件和其他 UI 元素。它还负责处理视图的测量、布局和绘制。
2. 处理用户输入事件：Window 负责接收和分发用户输入事件，例如触摸、按键和手势等。它将这些事件传递给相应的视图和控件，以便它们可以响应用户的操作。
3. 管理系统UI：Window 负责管理与系统 UI 相关的一些功能，例如状态栏、导航栏和软键盘等。它可以控制这些 UI 元素的显示和隐藏，以及处理与它们的交互。
4. 管理窗口属性：Window 还负责管理 Activity 的窗口属性，例如窗口的大小、位置、透明度和动画等。这些属性可以通过 WindowManager 和 Window 类的方法进行设置和修改。
5. 管理窗口焦点：Window 负责管理 Activity 中的焦点，例如确定哪个视图或控件应该接收输入焦点。这对于处理键盘输入和导航事件非常重要。

而 WindowManager 是一个系统服务，WindowManager 的主要作用如下：

1. 创建和管理窗口：WindowManager 负责创建和管理应用程序中的窗口。当一个 Activity 或 Dialog 被创建时，它会通过 WindowManager 来创建一个对应的 Window 对象。WindowManager 还负责管理窗口的生命周期，例如在窗口被销毁时释放资源。
2. 管理窗口层次关系：WindowManager 负责管理应用程序中窗口的层次关系。它可以将窗口分为不同的层次，例如状态栏、导航栏、应用程序窗口和系统窗口等。这些层次可以用于控制窗口的显示顺序和可见性。
3. 管理窗口布局：WindowManager 负责处理窗口的布局。它可以根据窗口的属性和层次关系来确定窗口的位置和大小。此外，WindowManager 还可以处理窗口的动画和过渡效果。
4. 处理窗口事件：WindowManager 负责处理与窗口相关的事件，例如窗口的创建、销毁、显示和隐藏等。它还可以处理窗口之间的交互，例如窗口的焦点变化和触摸事件传递等。
5. 管理系统窗口：WindowManager 还负责管理系统级别的窗口，例如状态栏、导航栏和软键盘等。它可以控制这些窗口的显示和隐藏，以及处理与它们的交互。

对于分屏、自由窗口等场景，我们可以使用以下代码获取 Activity 的尺寸：

```kotlin
val configurationInfo = StringBuilder("").apply {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        val m = manager.currentWindowMetrics
        append("window metrics Info: \n\n")
        append("screenSize = ${getScreenWidth()} x ${getScreenHeight()}\n")
        append("bounds = ${m.bounds}\n")
        append("size = ${m.bounds.width()} x ${m.bounds.height()}\n")
    }
}
```