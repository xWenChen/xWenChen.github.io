---
title: "Android动画相关知识点说明"
description: "本文主要说明在Android中与动画相关的一些知识点"
keywords: "Android,动画"

date: 2024-04-03T14:56:00+08:00

categories:
  - Android
  - 动画
tags:
  - Android
  - 动画

url: post/70D8C9503CC04F7DA872F05FA237B7AC.html
toc: true
---

本文主要说明在Android中与动画相关的一些知识点。

<!--More-->

## 加载属性动画

首先可以定义属性动画，比如View需要播放自下向上的移入动画，则可以定义如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <translate
        android:duration="@android:integer/config_shortAnimTime"
        android:fromYDelta="100%"
        android:interpolator="@android:anim/accelerate_interpolator"
        android:toXDelta="0" />
</set>
```

然后在代码中使用 AnimationUtils 加载并使用该动画资源：

```kotlin
val animation = AnimationUtils.loadAnimation(animView.context, R.anim.slide_up)
animation.setAnimationListener(object : Animation.AnimationListener {
    override fun onAnimationStart(animation: Animation?) = Unit

    override fun onAnimationEnd(animation: Animation?) {
        isPlayed.set(true)
    }

    override fun onAnimationRepeat(animation: Animation?) = Unit
})
animView.startAnimation(animation)
```
