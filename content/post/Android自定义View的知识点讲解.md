---
title: "Android自定义View的知识点讲解"
description: "本文主要讲解在 Android 中碰到的各种效果的实现"
keywords: "Android,自定义View"

date: 2023-11-22 12:53:00 +08:00
lastmod: 2023-11-22 12:53:00 +08:00

categories:
  - Android
tags:
  - Android
  - 自定义View

url: post/D3B578B38D7A44398F66A33AFFCAD38C.html
toc: true
---

本文主要讲解在 Android 中碰到的各种效果的实现。


<!--More-->

## 轮廓和阴影

`Paint.setShadowLayer`、`Paint.setMaskFilter` 和 BlurMaskFilter 是 Android 中用于实现阴影和模糊效果的方法和类。以下是它们的作用和用法：

Paint.setShadowLayer(float radius, float dx, float dy, int shadowColor)：setShadowLayer 方法用于为绘制的图形添加阴影效果。它接受四个参数：

- radius：阴影的模糊半径，值越大，阴影越模糊。
- dx：阴影在水平方向上的偏移量，正值表示向右偏移，负值表示向左偏移。
- dy：阴影在垂直方向上的偏移量，正值表示向下偏移，负值表示向上偏移。
- shadowColor：阴影的颜色。

在使用 setShadowLayer 时，需要关闭硬件加速。我们可以在 AndroidManifest.xml 文件中的 \<application> 标签中添加 android:hardwareAccelerated="false" 属性，或者在自定义 View 的构造函数中调用 setLayerType(View.LAYER_TYPE_SOFTWARE, null) 方法。下面一个示例代码：

```java
setLayerType(View.LAYER_TYPE_SOFTWARE, null);
Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
paint.setColor(Color.parseColor("#FF5722"));
paint.setStyle(Paint.Style.FILL);
paint.setShadowLayer(20, 0, 10, Color.parseColor("#4D000000"));
```

Paint.setMaskFilter(MaskFilter maskfilter)：setMaskFilter 方法用于为绘制的图形添加一个遮罩滤镜。它接受一个 MaskFilter 对象作为参数。MaskFilter 是一个抽象类，有两个子类：BlurMaskFilter 和 EmbossMaskFilter。

BlurMaskFilter(float radius, BlurMaskFilter.Blur style)：BlurMaskFilter 是 MaskFilter 的一个子类，用于实现模糊效果。它接受两个参数：

- radius：模糊半径，值越大，模糊效果越明显。
- style：模糊样式，可以是 BlurMaskFilter.Blur.NORMAL、BlurMaskFilter.Blur.SOLID、BlurMaskFilter.Blur.OUTER 或 BlurMaskFilter.Blur.INNER。

在使用 BlurMaskFilter 时，需要关闭硬件加速。我们可以在 AndroidManifest.xml 文件中的 \<application> 标签中添加 android:hardwareAccelerated="false" 属性，或者在自定义 View 的构造函数中调用 setLayerType(View.LAYER_TYPE_SOFTWARE, null) 方法。

以下代码为一个矩形添加模糊效果：

```java
Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
paint.setColor(Color.parseColor("#FF5722"));
paint.setStyle(Paint.Style.FILL);
paint.setMaskFilter(new BlurMaskFilter(20, BlurMaskFilter.Blur.NORMAL));
```

