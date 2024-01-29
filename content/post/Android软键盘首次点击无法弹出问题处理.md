---
title: "Android 软键盘首次点击无法弹出问题处理"
description: "本文介绍 Android 软键盘首次点击无法弹出的问题的处理"
keywords: "Android,软键盘,搜狗输入法,百度输入法"

date: 2024-01-29 18:33:00 +08:00
lastmod: 2024-01-29 18:33:00 +08:00

categories:
  - Android
  - 输入法
tags:
  - Android
  - 软键盘
  - 输入法

url: post/DDFB5FB366674F4592A71FB3D0D9DFFE.html
toc: true
---

本文介绍 Android 软键盘首次点击无法弹出的问题的处理。

<!--More-->

在 Android 中，点击 EditText 时，首次无法弹出键盘。可能是由以下两种原因：

1 - 设置了`android:focusableInTouchMode`属性为 true。

2 - 可能是手机厂商魔改了系统，导致部分 API 失效或者无法展示正常的行为。

## android:focusableInTouchMode 属性设置问题

`android:focusableInTouchMode`属性设置不当，会导致的 EditText 首次点击无法弹出键盘。如果我们设置了 EditText 点击时弹出键盘，同时又设置了`android:focusableInTouchMode="true"`。此时首次点击 TextView，TextView 会先获取焦点，然后再响应点击事件，所以点击事件不生效。只要改为`android:focusableInTouchMode="false"`。点击事件就能正常响应，键盘就能正常弹出了。

## 手机兼容问题

如果我们尝试了`android:focusableInTouchMode="false"`，键盘仍然无法正常弹出；或者键盘可以弹出，但是 EditText 的光标无法正常展示，则有可能是系统被手机厂商魔改了。在 oppo 手机上，我就碰到了这个问题。我的代码里，点击时会调用 show 方法，展示键盘，代码定义如下：

```kotlin
fun show() {
    editText?.run {
        visibility = View.VISIBLE
        showKeyboard()
    }
}

// 显示软键盘
fun View.showKeyboard(requestFocus : Boolean = false) {
    requestFocus()
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager?
    imm?.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, 0)
}
// 隐藏软键盘
fun View.hideKeyboard(clearFocus: Boolean = false) {
    clearFocus()
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager?
    imm?.hideSoftInputFromWindow(windowToken, 0)
}
```

实际上，Android 系统中可以控制软键盘显示与否的 API，主要有两种：

- **toggleSoftInput**：这个方法用于切换软键盘的显示状态。

    它需要两个参数：一个是用于控制软键盘显示行为的标志，另一个是用于控制软键盘隐藏行为的标志。

    **当调用此方法时，如果软键盘已经处于显示状态，它将隐藏；如果软键盘处于隐藏状态，它将显示出来。**

- **showSoftInput**：这个方法用于显示软键盘。

    它需要两个参数：一个是当前具有焦点的视图(通常是 EditText)，另一个是用于控制软键盘行为的标志(例如 InputMethodManager.SHOW_IMPLICIT 或 InputMethodManager.SHOW_FORCED)。
    
    **当调用此方法时，如果软键盘已经处于显示状态，它将保持显示状态。如果软键盘处于隐藏状态，它将显示出来。**

- **hideSoftInputFromWindow**：这个方法用于隐藏软键盘。

    它需要两个参数：一个是当前具有焦点的视图(通常是 EditText)的窗口令牌。可以通过调用 view.getWindowToken() 获取这个令牌。另一个是用于控制软键盘隐藏行为的标志。通常，可以使用 InputMethodManager.HIDE_IMPLICIT_ONLY(仅在用户没有明确请求隐藏键盘时隐藏键盘)或 InputMethodManager.HIDE_NOT_ALWAYS(无论用户是否请求，都隐藏键盘)。

在我的代码中，使用的是 toggleSoftInput 显示软键盘，但是使用这个方法有问题。在 oppo 手机上，首次点击 EditText，EditText 能正常获取焦点，但是无法弹出软键盘，后续再点击就正常了；在其他手机上就没这个问题。所以这是一个兼容问题。

经过一番排查，发现将 toggleSoftInput 的封装改为 showSoftInput 就可以了：

```kotlin
fun show() {
    editText?.run {
        visibility = View.VISIBLE
        showKeyboard()
    }
}

// 显示软键盘
fun View.showKeyboard(requestFocus : Boolean = false) {
    requestFocus()
    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.showSoftInput(editText, InputMethodManager.SHOW_IMPLICIT)
}
// 隐藏软键盘
fun View.hideKeyboard(clearFocus: Boolean = false) {
    clearFocus()
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager?
    imm?.hideSoftInputFromWindow(windowToken, 0)
}
```

综上，当出现 EditText 首次点击软键盘无法弹出的问题时，可以考虑换一个 API 试试。