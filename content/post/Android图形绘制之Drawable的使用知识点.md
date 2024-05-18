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

## Kotlin 代码实现 xml selector 的效果

有一段 xml 代码的如下，其效果为不可用时显示灰色，正常状态下显示黑色，选中或者点击时显示黄色：

```kotlin
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_enabled="false" >
        <bitmap android:src="@drawable/photo" android:tint="@color/gray"/>
    </item>
    <item android:state_selected="true" >
        <bitmap android:src="@drawable/photo" android:tint="@color/yellow" />
    </item>
    <item>
        <bitmap android:src="@drawable/photo" android:tint="@color/black"/>
    </item>
</selector>
```

上面这段代码可以使用以下 kotlin 代码实现：

```kotlin
/**
  * 设置图标
  * */
private fun applyCampIcon(imageView: ImageView, isPressed: Boolean = false) {
    val defaultBitmap = getBmpDrawable(imageView, R.drawable.photo, R.color.black) ?: return
    val disabledBitmap = getBmpDrawable(imageView, R.drawable.photo, R.color.gray) ?: return
    val selectedBitmap = getBmpDrawable(imageView, R.drawable.photo, R.color.yellow) ?: return

    // 创建不同状态下的 Drawable
    val drawable = StateListDrawable().apply {
        // 为 StateListDrawable 添加不同状态下的 Drawable，正值为 true，负值为 false
        addState(intArrayOf(-android.R.attr.state_enabled), disabledBitmap)
        if (isPressed) {
            addState(intArrayOf(android.R.attr.state_pressed), selectedBitmap)
        } else {
            addState(intArrayOf(android.R.attr.state_selected), selectedBitmap)
        }
        addState(intArrayOf(), defaultBitmap)
    }

    imageView.setImageDrawable(drawable)
}
```

说明点：

1. StateListDrawable 可以实现 xml 中 selector 的效果。

2. 状态值为 true，则取正值(如 android.R.attr.state_pressed)；状态值为 false，则取负值(如 -android.R.attr.state_enabled)。

## Kotlin 代码实现 Drawable 变色

可以使用下面这段代码来给 Drawable 设置特定颜色：

```kotlin
fun createStateListDrawable(context: Context): StateListDrawable {
    val stateListDrawable = StateListDrawable()

    // 加载位图
    val bitmap = BitmapFactory.decodeResource(context.resources, R.drawable.photo)

    // 创建不同状态下的 Drawable
    val disabledDrawable = createTintedDrawable(context, bitmap, R.color.gray)
    val pressedDrawable = createTintedDrawable(context, bitmap, R.color.yellow)
    val defaultDrawable = createTintedDrawable(context, bitmap, R.color.black)

    // 为 StateListDrawable 添加不同状态下的 Drawable
    stateListDrawable.addState(intArrayOf(-android.R.attr.state_enabled), disabledDrawable)
    stateListDrawable.addState(intArrayOf(android.R.attr.state_pressed), pressedDrawable)
    stateListDrawable.addState(intArrayOf(), defaultDrawable)

    return stateListDrawable
}

private fun createTintedDrawable(context: Context, bitmap: Bitmap, tintColorResId: Int): Drawable {
    val drawable = BitmapDrawable(context.resources, bitmap)
    val wrappedDrawable = DrawableCompat.wrap(drawable)
    // 变色
    DrawableCompat.setTint(wrappedDrawable, ContextCompat.getColor(context, tintColorResId))
    // 设置 Drawable 的边界
    wrappedDrawable.setBounds(0, 0, 60, 60)
    return wrappedDrawable
}
```