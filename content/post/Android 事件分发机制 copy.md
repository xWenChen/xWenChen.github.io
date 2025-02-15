---
title: "Android ViewGroup 与 EditText 点击事件冲突解决"
description: "本文主要讲解了 ViewGroup 中包含 EditText 时，碰到的两个点击事件的问题"
keywords: "Android,事件分发机制,事件冲突处理"

date: 2023-11-21T19:06:00+08:00

categories:
  - Android
tags:
  - Android
  - 事件分发

url: post/93A148F065214A6CA304B65956CEC794.html
toc: true
---

本文主要讲解了 ViewGroup 中包含 EditText 时，碰到的两个点击事件的问题。

<!--More-->

当 ViewGroup 中设置 EditText 时，通过调用 View.setOnClickListener 方法为 ViewGroup 或者 EditText 设置点击事件响应，可能会碰到问题。主要有两个：

- TextView 首次点击无响应，再次点击才响应
- 为 ViewGroup 设置点击事件响应，无法生效

TextView 出现首次点击无响应，再次点击才响应的问题，通常是因为我们在代码中使用 TextView 时设置了 `android:focusableInTouchMode="true"`。此时首次点击 TextView，会先获取焦点，所以点击事件不生效。只要改为 `android:focusableInTouchMode="true"`。点击事件就能正常响应了。

而出现为 ViewGroup 设置点击事件响应，无法生效的问题，主要是 EditText 会消费事件。如果想要 ViewGroup 的点击事件监听正常生效，一个解决方案是自定义 ViewGroup。自定义 ViewGroup 需要重写 onInterceptTouchEvent 和 onTouchEvent 两个方法。示例代码如下：

```kotlin
class MyFrameLayout : FrameLayout {
    var frameLayoutClickListener: OnClickListener? = null

    val tapListener = GestureDetector(context, object : SimpleOnGestureListener() {

        override fun onDown(e: MotionEvent?): Boolean {
            // 该方法处理 DOWN 事件，默认返回 false，如果自己处理，需要返回 true
            if (frameLayoutClickListener != null) {
                return true
            }
            return super.onDown(e)
        }

        override fun onSingleTapUp(e: MotionEvent?): Boolean {
            if (frameLayoutClickListener != null) {
                // 触发 frameLayoutClickListener
                frameLayoutClickListener?.onClick(binding.clMainSearchBar)
                return true
            }
            return super.onSingleTapUp(e)
        }
    })

    constructor(context: Context) : this(context, null)
    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)
    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr)

    override fun onInterceptTouchEvent(ev: MotionEvent?): Boolean {
        // 为 ViewGroup 设置了 ClickListener，则拦截事件，防止 EditText 消费掉了
        if (frameLayoutClickListener != null) {
            return true
        }
        return super.onInterceptTouchEvent(ev)
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        if (frameLayoutClickListener != null) {
            return tapListener.onTouchEvent(event)
        }
        return super.onTouchEvent(event)
    }
}
```

上述代码核心逻辑是 onInterceptTouchEvent 和 onTouchEvent。官方的建议就是重写了 onInterceptTouchEvent，则需要重写 onTouchEvent，但在 onTouchEvent 方法中，如果自己处理点击事件的话，则太麻烦了。所以我们将点击事件交给 GestureDetector 处理，并且为它设置 SimpleOnGestureListener。SimpleOnGestureListener 提供了大多数操作的默认实现，我们只需要重写我们想要的方法即可。

此处我们重写了 onDown 和 onSingleTapUp，重写 onDown 是因为该方法会处理 DOWN 事件，默认返回 false。表示自己不处理事件。如果需要自己处理，则该方法需要返回 true。

重写 onSingleTapUp 表示我们只关心单击事件。其他操作不关心。

