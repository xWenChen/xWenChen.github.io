---
title: "Android 富文本知识点记录"
description: "本文主要讲解 Android 系统富文本相关的知识点"
keywords: "Android,富文本"

date: 2024-01-04 09:35:00 +08:00
lastmod: 2024-01-04 09:35:00 +08:00

categories:
  - Android
tags:
  - Android
  - 富文本

url: post/294A1580CF5A4627A1C28DC7EAE1B7CA.html
toc: true
---

本文主要讲解 Android 系统富文本相关的知识点。

<!--More-->

其他相关文章：[TextView 显示富文本&部分点击生效](6A8E8E3AD581427DB99794A1680C7F57.html)

在 Android 系统中，想要实现富文本效果，主要通过两种方式：Span 和 Html Text。而 Html Text 底层仍然使用的 Sapn。所以我们掌握 Sapn 的使用即可。

## 更改文本的大小

我们可以使用 AbsoluteSizeSpan 更改部分文本的尺寸。AbsoluteSizeSpan 需要两个入参：尺寸以及是否使用 dip 值。当使用 dip 时，传入的尺寸就是 dp(比如 5 dp)，否则就是 px 值。比如emoji 表情的尺寸可以使用以下代码设置为 11dp：`emojiStr.setSpan(AbsoluteSizeSpan(11, true), startPos, emoji.length, SpannableStringBuilder.SPAN_EXCLUSIVE_EXCLUSIVE)`。

## 点击事件的问题

富文本 span 在最后时，不点击 span，也会触发 span 的点击事件。原因暂未查，源码可以看 MovementMethod 和 SpannableStringInternal.getSpans 相关的代码。

## 文本尺寸和位置调整

要调整 Emoji 尺寸和纵向偏移，我们可以自定义 span，其继承自 AbsoluteSizeSpan。通过调整 baselineShift，可以实现文本的纵向偏移，baselineShift 大于 0 表示向底部偏移，baselineShift 小于 0 表示向顶部偏移。代码如下：

```kotlin
class AbsoluteSizeMarginSpan(size: Int, useDp: Boolean, val bottomMargin: Int) : AbsoluteSizeSpan(size, useDp) {
    override fun updateDrawState(ds: TextPaint) {
        super.updateDrawState(ds)
        // baselineShift 为文本纵向偏移，大于 0 向底部偏移，小于 0 向顶部偏移
        ds.baselineShift = -bottomMargin
    }

    override fun updateMeasureState(ds: TextPaint) {
        super.updateMeasureState(ds)
        // baselineShift 为文本纵向偏移，大于 0 向底部偏移，小于 0 向顶部偏移
        ds.baselineShift = -bottomMargin
    }
}
```

