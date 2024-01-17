---
title: "Android状态栏和导航栏设置"
description: "本文主要讲解在 Android 中如何更改状态栏和导航栏的样式"
keywords: "Android,状态栏,导航栏"

date: 2023-12-28 11:25:00 +08:00
lastmod: 2023-12-28 11:25:00 +08:00

categories:
  - Android
tags:
  - Android
  - 状态栏
  - 导航栏

url: post/E92C824F59FE4FE4BC13D8D919A98F10.html
toc: true
---

本文主要讲解在 Android 中如何更改状态栏和导航栏的样式。


<!--More-->

## 概念定义

在 Android 中，ActionBar、StatusBar 和 NavigationBar 是用户界面的三个重要组件，它们的区别如下：

- ActionBar(操作栏)：ActionBar 是 Android App 界面顶部的一个横向条状区域，用于显示应用的标题、图标、菜单等。它可以提供导航、搜索、分享等功能，方便用户快速操作。ActionBar 的样式和功能可以根据应用的需求进行定制。

- StatusBar(状态栏)：StatusBar 是 Android 设备屏幕顶部的一个横向条状区域，用于显示系统状态信息，如时间、电池电量、网络信号等。在某些情况下，StatusBar 也可以显示应用的通知信息。StatusBar 的样式可以根据应用的需求进行调整，如改变背景颜色、透明度等。

- NavigationBar(导航栏)：NavigationBar 是 Android 设备屏幕底部的一个横向条状区域，用于显示系统导航按钮，如返回、主页和最近任务等。NavigationBar 的样式可以根据应用的需求进行调整，如改变背景颜色、透明度等。在某些设备上，NavigationBar 可能被实体按键替代。

总结一下，ActionBar 是应用程序界面顶部的操作区域，用于提供应用相关的功能；StatusBar 是设备屏幕顶部的状态信息区域，用于显示系统状态和通知；NavigationBar 是设备屏幕底部的导航区域，用于提供系统导航功能。这三者共同构成了 Android 用户界面的基本框架。

## 样式分类

Android 状态栏和导航栏的样式主要可以分为以下几种：

- 默认样式：状态栏显示时间、电池电量、信号强度等信息，导航栏显示返回、主页和最近任务等按钮。

- 透明样式：状态栏和导航栏的背景是透明的，可以看到下面的应用界面。

- 沉浸式样式：状态栏和导航栏与应用界面颜色一致，给人一种沉浸式的体验。透明样式和沉浸式样式有点类似，只是前者的颜色是透明的，后者的颜色是应用的主色。

- 半透明样式：状态栏和导航栏的背景是半透明的，可以看到下面的应用界面，但颜色会有一定的变化。

- 全屏样式：状态栏和导航栏完全隐藏，全屏显示应用界面。

- 浮动样式：导航栏不再固定在屏幕底部，而是可以浮动在应用界面上。

- 模糊样式：状态栏和导航栏的背景是模糊的，可以看到下面的应用界面，但不是很清晰。

- 暗黑模式样式：状态栏和导航栏的颜色变为深色，适合在暗环境下使用。

以上就是Android状态栏和导航栏的主要样式，不同的样式可以根据应用的需求和设计来选择。

## 透明样式设置

虽然透明状态栏和导航栏的概念最早出现在 ios，但不否认效果还是很赞的。Android 从 4.4 开始引进透明状态栏和导航栏，并且在 5.0 进行了改进，将透明变成了半透明的效果。所以我们通常只考虑兼容 5.0 及以上版本的手机。至于 5.0 以下的手机，就不要考虑此特性了，好在 5.0 以下的手机份额已经非常小了。

设置透明状态栏的核心代码如下：

```kotlin
fun transparentStatusBar(activity: Activity?) {
    activity ?: return
    transparentStatusBar(activity.getWindow())
}

fun transparentStatusBar(window: Window?) {
    window ?: return
    // Android 4.4
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) return
    // 小于 Android 5.0
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
        window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
        return
    }
    // 清除半透明的状态栏标识
    window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
    // 添加绘制状态栏背景色的标识
    window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
    
    int option = View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN

    int vis = window.getDecorView().getSystemUiVisibility()
    window.getDecorView().setSystemUiVisibility(option | vis)
    window.setStatusBarColor(Color.TRANSPARENT)
}
```