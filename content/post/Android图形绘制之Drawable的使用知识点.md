---
title: "Android图形绘制之Drawable的使用知识点"
description: "本文讲解了在 Android 中使用 Drawable 时，需要注意的一些知识点"
keywords: "Android,图片加载,SeekBar,Glide"

date: 2024-03-19 09:34:00 +08:00
lastmod: 2024-03-19 09:34:00 +08:00

categories:
  - Android
tags:
  - Android
  - Drawable

url: post/012E20D2274C400AB87FFACFD9E18309.html
toc: true
---

本文讲解了在 Android 中使用 Drawable 时，需要注意的一些知识点。

<!--More-->

1. 在 xml 中定义 drawable 资源时，<bitmap> 的 src 资源不能指向 xml 文件。否则运行时会崩溃。比如下面的 img_like_new 图标不能是 svg 或者其他 xml 资源。

```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:left="@dimen/dp_11"
        android:right="@dimen/dp_11"
        android:top="@dimen/dp_11"
        android:bottom="@dimen/dp_11">

        <bitmap 
            android:src="@drawable/img_like_new"
            android:tint="@color/red"
        />

    </item>
</layer-list>
```