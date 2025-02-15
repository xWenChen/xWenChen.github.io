---
title: "Android中ViewPager2的onPageScrolled方法不触发的问题处理"
description: "本文记录了处理 Android 中 ViewPager2 的 onPageScrolled 方法不触发的问题"
keywords: "Android,ViewPager2"

date: 2024-01-17T16:09:00+08:00

categories:
  - Android
tags:
  - Android
  - ViewPager2

url: post/8676CD4652BA43F3B406FF98C9DB8C0F.html
toc: true
---

本文记录了处理 Android 中 ViewPager2 的 onPageScrolled 方法不触发的问题。

<!--More-->

问：Android Viewpager2 为什么从第一个item跳转到第三个item时，onPageSelected  方法触发了，而 onPageScrolled 没有触发。但是相同操作时，Viewpager 的 onPageScrolled 能触发。这是为什么？

## ViewPager2 触发 onPageScrolled 方法的回调

在 ViewPager2 中，onPageSelected 和 onPageScrolled 是两个不同的回调方法，它们在不同的情况下触发。

- onPageSelected 方法在页面被选中时触发，无论是通过滑动还是通过代码调用 setCurrentItem 方法。所以当从第一个 item 跳转到第三个 item 时，onPageSelected 方法会被触发。

- onPageScrolled 方法在页面滑动过程中触发，它会在滑动过程中多次调用，以提供滑动过程中的位置信息。当通过代码调用 setCurrentItem 方法来跳转页面时，onPageScrolled 方法不会被触发，因为这种情况下没有滑动过程。

- 如果希望在跳转页面时触发 onPageScrolled 方法，可以尝试使用 setCurrentItem 方法的另一个重载版本，它接受一个布尔参数 smoothScroll。将 smoothScroll 设置为 true，这样在跳转页面时会有滑动动画，onPageScrolled 方法也会被触发。

例如：

```java
viewPager2.setCurrentItem(2, true);
```

这样在从第一个 item 跳转到第三个 item 时，onPageScrolled 方法也会被触发。

## ViewPager2 和 ViewPager 的区别

在 ViewPager2 中，当使用 setCurrentItem 方法跳转页面时，确实可能不会触发 onPageScrolled 方法。这是因为 ViewPager2 的实现与 ViewPager 不同，ViewPager2 使用了 RecyclerView 来实现页面滚动，而 ViewPager 使用的是自定义的滚动逻辑。

- 在 ViewPager 中，当使用 setCurrentItem 方法跳转页面时，无论 smoothScroll 参数是否为 true，onPageScrolled 方法都会被触发。这是因为 ViewPager 在处理页面跳转时，会触发滚动事件，从而导致 onPageScrolled 方法被调用。

- 在 ViewPager2 中，当使用 setCurrentItem 方法跳转页面时，如果 smoothScroll 参数为 false，则不会触发滚动事件，因此 onPageScrolled 方法不会被调用。如果将 smoothScroll 参数设置为 true，则会触发滚动事件，但是 onPageScrolled 方法可能在某些情况下不会被调用，这是因为 RecyclerView 的滚动事件处理与 ViewPager 不同，可能导致 onPageScrolled 方法没有被正确触发。

总之，这是由于 ViewPager2 和 ViewPager 的实现差异导致的。如果你需要在 ViewPager2 中监听页面滚动事件，可以尝试将 smoothScroll 参数设置为 true，或者考虑使用其他方法来实现你的需求。