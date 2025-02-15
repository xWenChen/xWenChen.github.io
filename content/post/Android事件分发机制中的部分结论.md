---
title: "Android事件分发机制中的部分结论"
description: "本文略讲了Android事件分发机制中的部分结论"
keywords: "Android,事件分发机制"

date: 2021-05-12T16:39:00+08:00

categories:
  - Android
tags:
  - Android
  - 事件分发

url: post/76FC7F0064E047D3AF3473AA7C14A1E0.html
toc: true
---

本文略讲了Android事件分发机制中的部分结论。

<!--More-->

结论选自《Android 开发艺术探索》。

关于事件传递的机制，这里给出一些结论，根据这些结论可以更好地理解整个传递机制，如下所示。

1. 同一个事件序列是指从手指接触屏幕的那一刻起，到手指离开屏幕的那一刻结束，在这个过程中所产生的一系列事件，这个事件序列以 down 事件开始，中间含有数量不定的 move 事件，最终以 up 事件结束。
2. 正常情况下，一个事件序列只能被一个 View 拦截且消耗。这一条的原因可以参考 3，因为一旦一个元素拦截了某此事件，那么同一个事件序列内的所有事件都会直接交给它处理，因此同一个事件序列中的事件不能分别由两个 View 同时处理，但是通过特殊手段可以做到，比如一个 View 将本该自己处理的事件通过 onTouchEvent 强行传递给其他 View 处理。
3. 某个 View 一旦决定拦截，那么这一个事件序列都只能由它来处理(如果事件序列能够传递给它的话)，并且它的 onInterceptTouchEvent 不会再被调用。这条也很好理解，就是说当一个 View 决定拦截一个事件后，那么系统会把同一个事件序列内的其他方法都直接交给它来处理，因此就不用再调用这个 View 的 onInterceptTouchEvent 去询问它是否要拦截了。
4. 某个 View 一旦开始处理事件，如果它不消耗 ACTION_DOWN 事件(onTouchEvent 返回了 false)，那么同一事件序列中的其他事件都不会再交给它来处理，并且事件将重新交由它的父元素去处理，即父元素的 onTouchEvent 会被调用。意思就是事件一旦交给一个 View 处理，那么它就必须消耗掉，否则同一事件序列中剩下的事件就不再交给它来处理了，这就好比上级交给程序员一件事，如果这件事没有处理好，短期内上级就不敢再把事情交给这个程序员做了，二者是类似的道理。
5. 如果 View 不消耗除 ACTION_DOWN 以外的其他事件，那么这个点击事件会消失，此时父元素的 onTouchEvent 并不会被调用，并且当前 View 可以持续收到后续的事件，最终这些消失的点击事件会传递给 Activity 处理。
6. ViewGroup 默认不拦截任何事件。Android 源码中 ViewGroup 的 onInterceptTouchEvent 方法默认返回 false。
7. View 没有 onInterceptTouchEvent 方法，一旦有点击事件传递给它，那么它的 onTouchEvent 方法就会被调用。
8. View 的 onTouchEvent 默认都会消耗事件（返回 true），除非它是不可点击的(clickable 和 longClickable 同时为 false)。View 的 longClickable 属性默认都为 false, clickable 属性要分情况，比如 Button 的 clickable 属性默认为 true，而 TextView 的 clickable 属性默认为 false。
9. View 的 enable 属性不影响 onTouchEvent 的默认返回值。哪怕一个 View 是 disable 状态的，只要它的 clickable 或者 longClickable 有一个为 true，那么它的 onTouchEvent 就返回 true。
10. onClick 会发生的前提是当前 View 是可点击的，并且它收到了 down 和 up 的事件。
11. 事件传递过程是由外向内的，即事件总是先传递给父元素，然后再由父元素分发给子 View，通过 requestDisallowInterceptTouchEvent 方法可以在子元素中干预父元素的事件分发过程，但是ACTION_DOWN 事件除外。