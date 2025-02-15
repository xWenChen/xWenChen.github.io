---
title: "Android 特定页面实现进入退出动画"
description: "本文讲解了如何在 Android 的特定页面中实现特定的页面进入和退出转场动画"
keywords: "Android,动画,转场动画"

date: 2023-12-04T00:10:31+08:00

categories:
  - Android
tags:
  - Android
  - 动画
  - 转场动画

url: post/766B300B2BF646DFB38CD7FF60E56B0A.html
toc: true
---

本文讲解了如何在 Android 的特定页面中实现特定的页面进入和退出转场动画。

<!--More-->

在 Android 中，要进入退出页面的动画，可以有两种方式：转场动画和共享元素动画。而转场的实现方式有多种，分为全局的转场动画和特定页面的转场动画。全局生效的转场动画

## 特定页面的转场动画

当从 A 页面进入 B 页面，如果需要在 B 页面设置从下往上弹出的转场动画，则可以使用以下方式设置：

1. 从下往上的进入动画，可以在 Activity 的 onCreate 方法中设置；从上往下的退出动画，可以在 Activity 的 onBackPressed 和 finish 方法中设置：

```kotlin
class BActivity : BaseActivity {
    override fun onCreate(savedInstanceState: Bundle?) {
        overrideInOutAnim()
        super.onCreate(savedInstanceState)
    }

    override fun onBackPressed() {
        super.onBackPressed()
        overrideInOutAnim()
    }

    override fun finish() {
        super.finish()
        overrideInOutAnim()
    }

    // 设置进入退出动画
    private fun overrideInOutAnim() {
        overridePendingTransition(R.anim.bottom_in, R.anim.bottom_out)
    }
}
```

2. 转场动画的定义如下，`@android:integer/config_mediumAnimTime` 的值为 400 毫秒：

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- 文件名 bottom_in -->
<set xmlns:android="http://schemas.android.com/apk/res/android"
    android:interpolator="@android:anim/accelerate_decelerate_interpolator">

    <translate
        android:duration="@android:integer/config_mediumAnimTime"
        android:fromYDelta="100%p"
        android:toYDelta="0" />
</set>
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- 文件名 bottom_out -->
<set xmlns:android="http://schemas.android.com/apk/res/android"
    android:interpolator="@android:anim/accelerate_decelerate_interpolator">

    <translate
        android:duration="@android:integer/config_mediumAnimTime"
        android:fromYDelta="0"
        android:toYDelta="100%p" />
</set>
```

3. 显示转场动画时，B 页面可能会遇到黑屏。此时我们可以将 BActivity 的背景色设置为透明，将 BActivity 里的布局的背景设置成 Activity 的背景。

```xml
<!-- 文件名：AndroidManifest.xml -->
<activity
    android:name="com.myandroid.test.BActivity"
    android:screenOrientation="portrait"
    android:theme="@style/transparentWithStatusBar" 
/>
```

在主题中使用 `<item name="android:windowBackground">@android:color/transparent</item>` 可以设置 Activity 背景为透明；`android:windowFullscreen` 可以设置状态栏是否展示，true 为不展示，false 为展示：

```xml
<!-- 文件名：styles.xml -->
<style name="transparentWithStatusBar" parent="Theme.MaterialComponents.Light.NoActionBar.Bridge">
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowFullscreen">false</item>
        <item name="windowNoTitle">true</item>
    </style>
```

而 BActivity 的背景可以设置在 View 中：

```xml
<!-- 文件名：activity_b.xml -->
<layout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:padding="16dp"
        android:orientation="vertical"
        android:gravity="start"
        android:background="@color/activity_background"
        tools:context=".BActivity">

    </LinearLayout>

</layout>
```

