---
title: "RecyclerView左滑删除"
description: "本文略讲了RecyclerView如何实现左滑删除"
keywords: "Android,富文本"

date: 2021-05-12 16:13:00 +08:00
lastmod: 2021-05-12 16:13:00 +08:00

categories:
  - Android
  - 自定义 View
  - RecyclerView
tags:
  - Android
  - 自定义 View
  - RecyclerView

url: post/51AF79571B3A46E2B7FB4D0A66605228.html
toc: true
---

本文略讲了 RecyclerView 如何实现左滑删除。

<!--More-->

## 说明

QQ 和 IOS 的应用都有一种功能，那就是左滑弹出删除选项。如下图：

未左滑时 QQ 会员的显示样式：

![未左滑时QQ会员的显示样式](/imgs/未左滑时QQ会员的显示样式.jpg)

左滑后 QQ 会员的显示样式：

![左滑后QQ会员的显示样式](/imgs/左滑后QQ会员的显示样式.jpg)

IOS 系统存在这种效果。这个功能在 Android 系统中默认是没有的，需要我们自定义 View 才能实现。本篇博文讲讲如何使用 RecyclerView 实现 QQ 的侧滑效果。

讲逻辑之前，先假定一些内容。

- 默认情况下，RecyclerView 显示的内容，称为内容布局(content)
- 侧滑后出现的布局，称为菜单布局(menu)，菜单布局中的每个功能项，称为菜单项(menu item)

![RecyclerView左滑删除菜单项布局示例](/imgs/RecyclerView左滑删除菜单项布局示例.png)

**QQ 的效果**

定义了上面的内容，就可以描述 QQ 的侧滑功能了。经过本人实测，QQ 的侧滑功能包含如下：

1. 显示内容布局时：
   1. 可点击，点击时进入对应的 item
   2. 可侧滑，侧滑时弹出对应的 item
      1. 最大侧滑距离为菜单宽度
      2. 如果侧滑距离不足阙值，则不显示菜单栏(滚动隐藏)
      3. 如果侧滑距离大于阙值，但不足最大菜单宽度，则显示菜单栏(滚动以显示剩下未显示的内容)
   3. 可长按，长按执行对应的操作
   4. 长按、侧滑动作相互排斥
2. 显示菜单布局时：
   1. 可点击，点击隐藏已显示的菜单布局
   2. 可侧滑，只有按住当前显示菜单栏的位置(Position)，才能侧滑，否则按下时就隐藏菜单栏，并且不响应后续事件
3. 侧滑和竖向滑动，一次点击事件流中，只响应一个方向。

明确了 QQ 具有的交互之后，就可以考虑如何实现侧滑了。如果使用 RecyclerView，则有以下两种方式实现侧滑，主要是从解决滑动冲突的角度考虑，分为外部拦截和内部拦截两种模式：

1. 使用 RecyclerView + OnItemTouchHelper
2. 自定义 RecyclerView

本文使用的是第 2 种方式(外部拦截)，虽然第 1 种更简单，但是第 2 种涉及到的知识更多，实现侧滑功能后能掌握更多的知识。有助于学习。

## 知识预热

### Scroll 与 Fling

使用过 ScrollView 的小伙伴应该知道，ScrollView 有两种滚动方式：手指按下时的拖动和手指松开时的自动滚动。**在 Android 中，手指按下时的拖动被称为 Scroll，手指松开时的自动滚动被称为 Fling。**

在了解了 Scroll 和 Fling 的概念后，我们就要思考两者的触发条件和处理方式了。想不通？没关系。我们知道 ScrollView 有这两个功能，看看 ScrollView 的源码。

在看 ScrollView 的源码之前，我们需要了解事件的分发机制。因为手指的拖动本质上是事件分发和 MotionEvent 的处理。

Android 的事件分发主要有三个方法：dispatchTouchEvent/onInterceptTouchEvent/onTouchEvent。三者对应的顺序是 分发/拦截/处理。对于 ScrollView，我们看下 onTouchEvent 方法。

在 ScrollView 源码中搜索 Scroll，发现下面两个变量。见名知意，就是用于 Scroll 和 Fling 的。

![Scroll和Fling的变量示意](/imgs/Scroll和Fling的变量示意.png)

搜索两个变量的使用位置，很轻松的定位到了 onTouchEvent 方法。分析  onTouchEvent 方法，找到了很多有用的知识：

![ScrollView的onTouchEvent方法](/imgs/ScrollView的onTouchEvent方法.png)

从上面的代码中，我们得到了最重要的知识点便是：

- Scroll 动作是在 Move 事件中触发的，在 Up 事件(Cancel 事件可选)中结束的
- Fling 动作是在 Up 事件中触发的，并且需要搭配速度追踪器
- Scroll 和 Fling 是互斥的两个动作
- 计算 Scroll 和 Fling 的过程中，不能忘了多指事件
- Down 事件来临时，应结束上一次未完成的滚动
- 使用 Scroller + VelocityTracker 来完成 Fling 动作，使用 Scroller 可以避免无动画直接闪现到目标位置的问题。使用 View 的 scrollTo 方法，完成 Scroll 动作。关于这两个使用说明，官方也提供了一个例子，以及 Scroller 的一个固定使用模版。有兴趣的可以谷歌一下。

### scrollX 和 scrollY

在了解了 Scroll 和 Fling 动作的触发时机后，我们还需要了解下 Scroll 时需要用到的变量信息 scrollX，scrollY 的含义。具体可以看下**[这篇文章](https://blog.csdn.net/bigconvience/article/details/26697645)**。

对于 scrollX，scrollY，我们得明确这两个的意思，是滚动的距离，而不是滑动的距离。**滚动的英语是 Scroll，而滑动的英语是 Slide。我们可以把滑动看作是 View 本身的移动(平移)，在 View 中用 translate 表示。而滚动则是 View 的内容的移动，此时 View 本身是没有移动的**。明确了这两点，我们就能明白 scrollX，scrollY 的含义了。

### Scroller 与 OverScroller 与 VelocityTracker

在 Android 中，Fling 动作是一个比较特殊的动作。原生的 Fling 是一个闪现到目标位置的动作，并没有我们通常见到的那种自动滚动的丝滑感。所以 Google 提供了一个工具类：Scroller，可别被它的名字误导了。实际上，它的名称叫做 ScrollerUtil 更为贴切。Scroller 自身并不具备滚动能力。实际上，Scroller 的使用是有一个固定的模版代码的。

```java
public class TestView extends View {
    Scroller scroller;

    public TestView(Context context) {
        super(context);
        scroller = new Scroller(getContext());
    }

    @Override
    public void computeScroll() {
        if (scroller.computeScrollOffset()) {
            // 实际是调用 View 的 scrollTo/scrollBy 方法进行滚动
            scrollTo(scroller.getCurrX(), scroller.getCurrY());
            // View 的 scroll 并不会触发重绘，需要手动触发
            postInvalidate();
        }
    }

    // 缓慢滚动到指定位置
    private void smoothScrollTo(int destX, int destY) {
        int scrollX = getScrollX();
        int delta = destX - scrollX;
        // 1000ms 内滚向 destX
        scroller.startScroll(scrollX, 0, delta, 0, 1000);
        invalidate();
    }
}
```

Scroller 与 OverScroller 的区别就是是否支持过度滚动。过度滚动是指实际滚动距离会比 View 可滚动距离多出来一截，当 View 滚动到多出来的这一截时，可回弹，呈现出一个滚动回弹的视觉效果。

VelocityTracker，顾名思义，是 Google 提供的一个计算手指滑动速度的工具类。通常我们实现 Fling 效果时，都需要使用这个类，VelocityTracker 通常搭配 Scroller 使用，使用方法可以参考 ScrollView，也是一个固定的模版代码。

```java
public class ScrollView extends FrameLayout {
    private VelocityTracker mVelocityTracker;

    public boolean onInterceptTouchEvent(MotionEvent ev) {
        switch (action & MotionEvent.ACTION_MASK) {
            case MotionEvent.ACTION_DOWN: {
                if (mVelocityTracker == null) {
                    mVelocityTracker = VelocityTracker.obtain();
                } else {
                    mVelocityTracker.clear();
                }
                // 开始追踪
                mVelocityTracker.addMovement(ev);
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                mVelocityTracker.addMovement(ev);
                break;
            }
            case MotionEvent.ACTION_POINTER_UP: {
                onSecondaryPointerUp(ev);
                break;
            }
        }
        // 如果在 Scroll，则拦截事件
        return mIsBeingDragged;
    }

    public boolean onTouchEvent(MotionEvent ev) {
        if (mVelocityTracker == null) {
            mVelocityTracker = VelocityTracker.obtain();
        }
        switch (ev.getActionMasked()) {
            case MotionEvent.ACTION_MOVE: {
                // 如果成功滚动，则不需要跟踪速度了
                // 速度追踪用于 Fling，Scroll 用不上
                if(scrollSuccess()) {
                    mVelocityTracker.clear();
                }
                break;
            }
            case MotionEvent.ACTION_UP: {
                // 抬手时计算速度，用于 Fling 动作
                mVelocityTracker.computeCurrentVelocity(1000, mMaximumVelocity);
                int initialVelocity = (int) velocityTracker
                    .getYVelocity(mActivePointerId);
                // 大于速度阙值，才触发 Fling 动作
                if ((Math.abs(initialVelocity) > mMinimumVelocity)) {
                    fling(-initialVelocity);
                    // 结束 Scroll 动作
                    endDrag();
                }
                break;
            }
            case MotionEvent.ACTION_POINTER_UP: {
                // 多指事件的抬起动作
                /* 
                     * 如果抬起的是当前生效的手指，则需要结束速度追踪
                     * 即用于计算速度的手指改变了
                     */
                if (pointerId == mActivePointerId) {
                    if (mVelocityTracker != null) {
                        mVelocityTracker.clear();
                    }
                }
                break;
            }
        }
        if (mVelocityTracker != null) {
            mVelocityTracker.addMovement(ev);
        }
        return true;
    }
}
```

上面的代码参考自 ScrollView，部分逻辑需要说明下：

- VelocityTracker 在 Down 事件来临时需要重置状态，在 Up 事件时计算速度(Fling 动作在 Up 时触发，需要用到速度)
- computeCurrentVelocity 方法传入 1000 的作用是计算每秒的速度(比如生活中常见的 米/秒，就是一秒走了多少米)。1000 的单位是毫秒，通常我们传入 1000 即可
- VelocityTracker 需要追踪完整的事件流(Donw ---> Move ---> Up)，多指事件也要考虑在内。Down 时开始追踪事件，Up 时计算速度，并提供给 Scroller 使用
- Fling 的触发是有速度阙值的。速度阙值的获取下面讲解。

### 滑动中用到的阙值

我们知道，Android 系统是十分灵敏的，可能会在我们意想不到的时间点触发一些动作，比如 Move 事件。但是我们并不想在这种时候触发对应的动作。此时就需要给相关动作设置一个阙值，说是阙值，其实就是可接受的误差范围。在 Android 中，默认就定义了一些阙值，它们都存储在 ViewConfiguration 类中。在本文中，我们可能用到的阙值如下：

```java
// 下面只列举了部分，非全部
public class ViewConfiguration {
    /**
     * 长按事件的时间阙值，Up 和 Down 的时间间隔小于此值，被视为点击，否则是长按
     */
    private static final int DEFAULT_LONG_PRESS_TIMEOUT = 500;
    /**
     * Scroll 动作的距离阙值，Move 距离大于此阙值，才算是触发了 Scroll
     */
    private static final int TOUCH_SLOP = 8;
    /**
     * 触发 Fling 动作的最小速度，小于此速度，则不触发 Fling 动作
     */
    private static final int MINIMUM_FLING_VELOCITY = 50;
    /**
     * Fling 动作支持的最大速度
     */
    private static final int MAXIMUM_FLING_VELOCITY = 8000;
}
// 获取阙值的方法如下
private void test(Context context) {
    // 获取长按阙值
    ViewConfiguration.getLongPressTimeout();
    // 获取 Scroll 的距离阙值
    ViewConfiguration.get(context).getScaledTouchSlop();
    // 获取触发 Fling 的最小速度
    ViewConfiguration.get(context).getScaledMinimumFlingVelocity();
    // 获取 Fling 支持的最大速度
    ViewConfiguration.get(context).getScaledMaximumFlingVelocity();
}
```

### 事件拦截过程

本文中，对于事件的拦截机制，我们需要明白一点：在一次事件流中，ViewGroup 只会触发一次拦截动作，一旦拦截成功，后续便不会重复触发拦截。直到下一次事件流开始。即在 onInterceptTouchEvent 方法的返回值为 false 时，onInterceptTouchEvent 方法会在每个事件中都调用一下。如果 onInterceptTouchEvent 方法的返回值为 true，则事件会被当前 View 拦截，不会向下分发，并且后续事件来临时，onInterceptTouchEvent 不会再被调用。

附事件分发机制的一些结论。结论选自《Android 开发艺术探索》。根据这些结论可以更好地理解整个传递机制，如下所示：

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

### 多指事件的处理

多指事件，需要考虑 Index 和 id 的区别，就不细讲了。具体实现可以考虑 ScrollView 中 Google 的官方实现，ScrollView 中的实现可以看作一个模版代码：

```java
public class ScrollView extends FrameLayout {
    /**
     * 在多指事件中，生效的手指的 id，Scroll/Fling 只需要用到一个手指
     */
    private int mActivePointerId = MotionEvent.INVALID_POINTER_ID;

    public boolean onInterceptTouchEvent(MotionEvent ev) {
        switch (ev.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                // Down 来临时，取第一个手指
                mActivePointerId = ev.getPointerId(0);
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                // 拿取 X、Y 的固定模版
                int pointerIndex = ev.findPointerIndex(mActivePointerId);
                if (pointerIndex == MotionEvent.INVALID_POINTER_ID) {
                    break;
                }
                int y = (int) ev.getY(pointerIndex);
                break;
            }
            case MotionEvent.ACTION_CANCEL:
            case MotionEvent.ACTION_UP:
                // Up/Cancel 取消生效的手指
                mActivePointerId = MotionEvent.INVALID_POINTER_ID;
                break;
        }
        // ......
    }
    public boolean onTouchEvent(MotionEvent ev) {
        switch (ev.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                // 拦截方法可能不会执行，所以要在 onTouchEvent 中重复一次
                mActivePointerId = ev.getPointerId(0);
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                int activePointerIndex = ev.findPointerIndex(mActivePointerId);
                if (activePointerIndex == MotionEvent.INVALID_POINTER_ID) {
                    break;
                }
                int y = (int) ev.getY(activePointerIndex);
                break;
            }
            case MotionEvent.ACTION_POINTER_DOWN: {
                int index = ev.getActionIndex();
                mLastMotionY = (int) ev.getY(index);
                mActivePointerId = ev.getPointerId(index);
                break;
            }
            case MotionEvent.ACTION_POINTER_UP: {
                int pointerIndex = event.getActionIndex();
                int pointerId = ev.getPointerId(pointerIndex);
                if (pointerId == mActivePointerId) {
                    // index总是连续的，比如 0、1、2 三根手指，1 抬起了，此时 2 会变为 1，但 id 不变
                    int newPointerIndex = pointerIndex == 0 ? 1 : 0;
                    mLastMotionY = (int) ev.getY(newPointerIndex);
                    mActivePointerId = ev.getPointerId(newPointerIndex);
                }
                mLastMotionY = (int) ev.getY(ev.findPointerIndex(mActivePointerId));
                break;
            }
            case MotionEvent.ACTION_CANCEL:
            case MotionEvent.ACTION_UP:
                // Up/Cancel 取消生效的手指
                mActivePointerId = MotionEvent.INVALID_POINTER_ID;
                break;
        }
        // ......
    }
}
```

对上述代码的一些说明：

- 多指事件的判断横跨了多个事件类型，包括 Down、Move、Up、Cancel、Pointer Down、Pointer Up。
- 需要分清手指的 id 和 index 的区别。id 可以认为是一个手指的唯一标识，在一个事件流中是唯一的。而 index 则不然。
   - 想要通过 index 找 id，可以使用 MotionEvent.getPointerId 方法
   - 想要通过 id 找 index，可以使用 MotionEvent.findPointerIndex 方法
   - 使用 MotionEvent.getActionIndex 可以找到事件对应的手指的 index
   - 想要找到手指 id、x、y 等信息，都需要用到 pointerIndex
- 生效的 pointerId 默认是 index 为 0 的手指的 id，在 Down 事件中赋值，在 Up、Cancel 事件或者其他特定条件下重置。pointerDown 事件中，生效的 pointerId 会变更为 按下的手指的 id。在 pointerUp 事件中，会判断松开的手指是否是当前生效的手指。如果是，则会重新寻找一个可用的手指 id

一些基础的知识就了解这么多，下面开始造轮子。

## 实现过程

### 确定 item 位置

既然决定使用外部拦截的方式，那么就需要思考一个，如何确定当前点击的是哪个 item？既如何通过 MotionEvent 确定 item。幸运的是 RecyclerView(后面简称 RV) 已经提供了方法，如下：

```java
private ViewHolder findViewHolder(MotionEvent event) {
    // findChildViewUnder 是 RV 中的方法
    View view = findChildViewUnder(event.getX(), event.getY());
    if(view == null) {
        return null;
    }
    // findContainingViewHolder 是 RV 中的方法
    return findContainingViewHolder(view);
}
```

其具体思路就是通过 X/Y 坐标确定当前点击的 View，再通过 View 确定 ViewHolder，确定了 ViewHolder 后，我们就能确定点击的 position 等信息了。

### 定义侧滑菜单布局

在实际的实现过程中，为了简化难度(满足需求的情况下)，特做了如下处理：

- RV 的 ViewHolder 的布局，采用 LinearLayout 作为 Root ViewGroup(后面简称根 LL)，并将方向设置为 Horizontal
- 菜单布局的宽度尺寸必须确定，即测量模式必须是 EXACTLY。因为测量模式如果不是 EXACTLY，而是 AT_MOST 的话，那么在内容布局 Match_Parent 的情况下，根 LL 不会测量菜单布局的宽度。导致菜单布局的宽度为 0。不管菜单布局的子 item 声明的是怎样的尺寸，结果都一样
- 为了保证菜单布局中的选项可受开关动态控制，特将菜单布局的获取改为全 Java 代码获取。并且菜单布局的方向是 Horizontal。但是因为创建布局时，无法获取到 bean 类，所以将此菜单选项显示与否的判断移至数据绑定阶段(onBindViewHolder)，而不是在视图创建阶段(onCreateViewHolder)判断
- 内容布局、菜单布局、菜单选项等的 id 固定

下面的代码用于获取菜单布局，并将菜单布局加入 根 LL。菜单包含了两个选项：关注和删除。

```java
public class SwipeAdapter extends RecyclerView.Adapter<SwipeViewHolder> {
    @Override
    public SwipeViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        return new SwipeViewHolder(parent.getContext(), getItemView(parent, viewType));
    }

    private View getItemView(ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        ViewGroup rootView = (ViewGroup) inflater.inflate(R.layout.root, parent, false);
        // 获取菜单选项的布局
        List<View> itemList = buildMenuItemList(parent.getContext(), viewType);

        if(ListUtil.isEmpty(itemList)) {
            return rootView;
        }

        int width = 0;
        // 获取菜单布局的宽度
        View view;
        for(int i = 0; i < itemList.size(); i++) {
            view = itemList.get(i);
            if(view == null) {
                continue;
            }
            width += view.getLayoutParams().width;
        }
        // 构建菜单布局
        LinearLayout menuLayout = new LinearLayout(parent.getContext());
        menuLayout.setId(MenuFuncId.MENU);
        menuLayout.setOrientation(LinearLayout.HORIZONTAL);
        // 菜单布局的宽度固定为 width
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            width, LinearLayout.LayoutParams.MATCH_PARENT);
        menuLayout.setLayoutParams(params);
        // 添加菜单布局 item 到菜单布局中
        for(int i = 0; i < itemList.size(); i++) {
            view = itemList.get(i);
            if(view == null) {
                continue;
            }
            menuLayout.addView(view);
        }
        // 将菜单布局添加到根布局中
        rootView.addView(menuLayout);

        return rootView;
    }

    private List<View> buildMenuItemList(Context context, int viewType) {
        List<View> viewList = new Vector<>();
        // 菜单选项的宽度固定，为 82 dp
        // dp 转 px 的方法就不带了，网上一大堆
        // 关注选项
        TextView tvFollow = new TextView(context);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            dpToPx(context, 82)), LinearLayout.LayoutParams.MATCH_PARENT);
        tvFollow.setLayoutParams(params);
        tvFollow.setId(MenuFuncId.FOLLOW);
        tvFollow.setText("关注");
        tvFollow.setTextSize(17);
        tvFollow.setTextColor(Color.WHITE);
        tvFollow.setGravity(Gravity.CENTER);
        tvFollow.setBackgroundColor(Color.BLUE);
        // 删除选项
        TextView tvRemove = new TextView(context);
        params = new LinearLayout.LayoutParams(
            dpTopx(context, 82), LinearLayout.LayoutParams.MATCH_PARENT);
        tvRemove.setLayoutParams(params);
        tvRemove.setId(MenuFuncId.REMOVE);
        tvRemove.setText("删除");
        tvRemove.setTextSize(17);
        tvRemove.setTextColor(Color.WHITE);
        tvRemove.setGravity(Gravity.CENTER);
        tvRemove.setBackgroundColor(Color.RED);

        viewList.add(tvFollow);
        viewList.add(tvRemove);

        return viewList;
    }
}
```

R.layout.root 的布局样式如下，就是一个水平方向的 LL：

```xml
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="73dp"
    android:orientation="horizontal">
    <!-- 内容布局 -->
    <include layout="@layout/content"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
```

### 1. 实现 Scroll 动作

因为是仿 QQ 的交互，所以菜单的侧滑是水平侧滑。实现水平滚动 Scroll 动作的核心实现逻辑如下：

```java
public class TestView extends View {
    /**
     * Move 事件(上次事件)的坐标点，用于 Scroll 动作
     */
    private float lastX;

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                // Down 事件记录初始坐标
                pointerIndex = event.getActionIndex();
                lastX = event.getX(pointerIndex);
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                // Scroll 的核心逻辑
                // Move 时不停计算差值，并调用滚动的相关方法
                float x = event.getX(pointerIndex);
                int offsetX = (int) (lastX - x);
                scrollBy(offsetX, 0);
                // Scroll 不会自动刷新，需要手动刷新
                invalidate();
                lastX = x;
                break;
            }
        }
        return super.onTouchEvent(event);
    }
}
```

再配合上上面讲到的多指事件的处理模版，便可以输出第一版可 Scroll 的代码了。

第一版的交互逻辑为：手指移动时，item 可以跟着滚动，此时不考虑点击事件什么的。此时的代码逻辑为：

- 在拦截事件的方法 onInterceptTouchEvent 中，全部拦截事件
- 在 onTouchEvent 中处理 Scroll 动作。Down 时记录坐标、布局、手指等信息，Move 计算与上次事件的坐标的差值，此差值为需要滚动的距离。在 PointerDown 和 PointerUp 中变更手指的信息。在 Up/Cancel 中重置手指信息。

```java
public class SwipeRecyclerView extends RecyclerView {
    /**
     * 当前点击的 ViewHolder
     * */
    private ViewHolder curHolder;
    /**
     * Move 事件(上次事件)的坐标点，用于 Scroll 动作
     */
    private float lastX;
    /**
     * 在多指事件中，生效的手指的 id，Scroll/Fling 只需要用到一个手指
     */
    private int mActivePointerId;

    // 构造函数省略

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        return true;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int pointerIndex = event.getActionIndex();
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN: {
                // 重置坐标，手指id，ViewHolder 等变量
                mActivePointerId = event.getPointerId(pointerIndex);
                lastX = event.getX(pointerIndex);
                curHolder = findContainingViewHolder(findChildViewUnder(
                    event.getX(pointerIndex), event.getY(pointerIndex)));
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                // 处理滚动事件
                int tempPointerIndex = event.findPointerIndex(mActivePointerId);
                float value = event.getX(tempPointerIndex);
                int deltaX = (int)(lastX - value);
                curHolder.itemView.scrollBy(deltaX, 0);
                invalidate();
                lastX = value;
                break;
            }
            case MotionEvent.ACTION_POINTER_UP: {
                int id = event.getPointerId(pointerIndex);
                if(id == mActivePointerId) {
                    // index 总是连续的，比如 index 为 0、1、2 的三根手指。
                    // 1 抬起了，此时 2 手指的 index 会变为 1，但 id 不变
                    int newIndex = pointerIndex == 0 ? 1 : 0;
                    mActivePointerId = event.getPointerId(newIndex);
                }
                break;
            }
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL: {
                mActivePointerId = MotionEvent.INVALID_POINTER_ID;
                break;
            }
        }
        return true;
    }
}
```

### 2. 为 Scroll 动作添加边界值

上面的代码中，Scroll 动作是无拘无束的，没有限制。但是 QQ 的交互中，实际上是有最大和最小的滚动距离。那么我们也加入临界值的判断。

首先，我们需要确定可滚动的最大距离。从上文菜单布局的构建中，我们知道，菜单布局的宽度是固定的那么只需要拿到菜单布局即可。然后，我们在 SwipeRecyclerView 增加一个变量，用以表示可滚动的最大距离。并且在 Down 事件中更新，因为不同的 item，菜单布局宽度可能不同。代码逻辑如下：

```java
public class SwipeRecyclerView extends RecyclerView {
    // 其他的变量省略
    /**
     * 菜单栏的最大显示宽度，也是每个 item 可滚动的最大宽度
     * */
    private int maxScrollDistance;

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int pointerIndex = event.getActionIndex();
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN: {
                // 其他代码省略
                maxScrollDistance = calculateMaxScrollDistance(curHolder);
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                // 处理滚动事件
                int tempPointerIndex = event.findPointerIndex(mActivePointerId);
                float value = event.getX(tempPointerIndex);
                int deltaX = (int)(lastX - value);
                // 限制滚动距离
                // 手指从右向左移动，左移到达最大值
                if(deltaX > 0 && curHolder.itemView.getScrollX() 
                   + deltaX > maxScrollDistance) {
                    deltaX = maxScrollDistance - curHolder.itemView.getScrollX();
                }
                // 手指从左向右移动，右移到达最小值
                if(deltaX < 0 && curHolder.itemView.getScrollX() + deltaX < 0) {
                    deltaX = -holder.itemView.getScrollX();
                }
                curHolder.itemView.scrollBy(deltaX, 0);
                invalidate();
                lastX = value;
                break;
            }
                // 其他代码省略
        }
        return true;
    }
    /**
     * -1 代表不可滚动
     * */
    private int calculateMaxScrollDistance(ViewHolder viewHolder) {
        if(viewHolder == null) {
            return -1;
        }
        ViewGroup rootViewGroup = viewHolder.itemView.findViewById(MenuFuncId.MENU);
        if(rootViewGroup == null || rootViewGroup.getChildCount() < 0) {
            return -1;
        }
        int result = 0;
        // 根布局是水平方向的 LL，直接从左向右加 item 的宽度
        for(int i = 0; i < rootViewGroup.getChildCount(); i++) {
            View view = rootViewGroup.getChildAt(i);
            // 子布局为 Gone 时，不计入宽度
            if(view == null || view.getVisibility() == View.GONE) {
                continue;
            }
            result += view.getMeasuredWidth();
        }
        return result;
    }
}
```

### 3. 处理 Fling 动作?

在限制了最大滚动距离之后，我们来考虑下 Fling 动作，Fling 是松手后的自动滚动。我们就暂时称为自动滚动吧。传统的 Fling 动作，会结合 VelocityTracker，来模拟惯性移动。但是使用 QQ 的侧滑，并没有感觉到明显的惯性移动过程，松开手指时，即使没有速度，菜单也会自动滚动。本文也做类似处理。即**本文设计的 Fling 动作，不是真正的 Fling 动作，而是使用 Scroll 模拟的动作。并没有速度的概念，不会用到 VelocityTracker**。

QQ 的 Fling 动作的触发时机是菜单布局滚动的距离超过了阙值，这里也模仿这种处理。取距离阙值为菜单宽度的 1/3。

为了方便理解，将 Scroll 和 Fling 的处理抽取成单独的方法：

```java
/**
 * Scroll 动作是在 Move 事件中触发的
 *
 * @return true 表示需要滚动，false 不需要滚动
 * */
private boolean dealScroll(ViewHolder holder, MotionEvent event) {
    if (holder == null) {
        return false;
    }
    if(maxScrollDistance <= 0) {
        return false;
    }
    int pointerIndex = event.findPointerIndex(mActivePointerId);
    float x = event.getX(pointerIndex);
    int offsetX = (int) (lastX - x);
    // 限制滚动范围
    // 手指从右向左移动，布局也从右向左移动，左移到达最大值
    if(offsetX > 0 && holder.itemView.getScrollX() + offsetX > maxScrollDistance) {
        offsetX = maxScrollDistance - holder.itemView.getScrollX();
    }
    // 手指从左向右移动，布局也从左向右移动，右移到达最大值
    if(offsetX < 0 && holder.itemView.getScrollX() + offsetX < 0) {
        offsetX = -holder.itemView.getScrollX();
    }

    // 竖直方向不移动
    holder.itemView.scrollBy(offsetX, 0);
    invalidate();

    lastX = x;
    return true;
}

/**
 * 是否判定为水平方向的 Fling，如果是，则执行 Fling 动作
 *
 * Fling 动作是在 Up 事件中触发的
 * */
private boolean dealFling(ViewHolder holder, MotionEvent event) {
    float nowX = event.getX();
    // downX 只会在 Down 和 pointerDown 事件中更改
    float offsetX = downX - nowX;

    if(holder == null || holder.itemView.getScrollX() <= 0) {
        return false;
    }
    // 没有可滚动的距离
    if(maxScrollDistance < 0) {
        return false;
    }
    int dx;
    // 菜单栏显示
    // 拖动距离不足 1/3 时，已滚动距离不生效，回弹
    if(Math.abs(offsetX) < (float) maxScrollDistance / 3) {
        if(offsetX > 0) {
            dx = -holder.itemView.getScrollX();
        } else {
            dx = maxScrollDistance - holder.itemView.getScrollX();
        }
    } else {
        if(offsetX > 0) {
            dx = maxScrollDistance - holder.itemView.getScrollX();
        } else {
            dx = -holder.itemView.getScrollX();
        }
    }

    // 滚动到目标位置
    mScroller.startScroll(holder.itemView.getScrollX(), 0, dx, 0);
    invalidate();

    return true;
}
```

### 4. 水平滚动/竖直滚动 2 选 1

在 QQ 中，竖直滚动和水平滚动是互斥的，二者只能同时生效一个。本文也需要实现这种效果。

首先我们需要思考一个问题，水平方向和竖直方向上的滚动是哪里来的？水平方向很好理解，是我们自定义的。但是竖直方向呢？很明显，就是父类的实现了。所以，对于滚动的生效方向的判断与选择，可以用下面的代码实现。

```java
public class SwipeRecyclerView extends RecyclerView {
    /**
     * 一次事件流中，是水平滚动，还是竖直滚动的标识
     * */
    private boolean isVerScroll;
    /**
     * Down 事件的坐标，这两个变量的值，只会在 Down 和 PointerDown 中改变
     * */
    private float downX, downY;

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN: {
                downX = event.getX(pointerIndex);
                downY = event.getY(pointerIndex);
                // 避免自动 Scroll 的影响
                isVerScroll = false;
                break;
            }
            case MotionEvent.ACTION_MOVE: {
                // 状态只检查一次
                if(!isVerScroll) {
                    checkVerScrollState(event);
                }
                // 触发了竖直滚动，直接调用父类的实现
                if(isVerScroll) {
                    return super.onTouchEvent(event);
                }
                // 水平滚动
                dealScroll(curHolder, event);
            }
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL: {
                if(!isVerScroll) {
                    checkVerScrollState(event);
                }
                // 触发了竖直滚动，直接调用父类的实现
                if(isVerScroll) {
                    return super.onTouchEvent(event);
                }
                dealFling(curHolder, event);
            }
        }
        return true;
    }

    private void checkVerScrollState(MotionEvent event) {
        if(isVerScroll) {
            return;
        }
        int pointerIndex = event.findPointerIndex(mActivePointerId);
        float x = event.getX(pointerIndex);
        float y = event.getY(pointerIndex);
        // 检测竖直方向的滑动，如果滑动距离大于阙值，则竖直滑动生效
        if(!isVerScroll && Math.abs(x - downX) < Math.abs(y - downY) 
           && Math.abs(y - downY) > scrollSlop) {
            isVerScroll = true;
        }
    }
}
```

上面的流程比较简单，就是在需要 Scroll 或者 Fling 时，判断竖直方向的滚动是否生效，如果生效，则不执行 Scroll 或者 Fling 动作，这两个动作是自定义的逻辑；转而使用父类的逻辑，父类是 RecyclerView，已实现竖直滚动的逻辑。

### 5. 只显示 1 个菜单

现在我们已经实现了 拖动、自动滚动、滚动方向 2 选 1 的逻辑，菜单能正常显示与隐藏。但是存在一个问题，菜单栏能显示多个，即下个菜单显示时，上个菜单并不会主动隐藏。而 QQ 是会保证列表中只有 1 个菜单布局显示的。我们接下来实现这个逻辑。这个逻辑的实现挺复杂的，需要先梳理一下。

- 如何检测菜单布局是否显示？上面的代码逻辑中，有实现一个逻辑，那就是在 Up 时，会执行 Fling 动作，这就限定了 item 的 Scroll 范围：scrollX 要么为 0 (菜单布局隐藏)，要么为最大滚动距离(菜单布局显示)。不会出现中间值。我们就可以根据这个条件来判断是否有菜单布局显示。
- 定义拦截模式与非拦截模式：当 RV 中有菜单显示时，我们需要启用拦截模式。当 RV 中无菜单显示时，我们启用非拦截模式。拦截模式针对的是上个显示菜单布局的 item。而非拦截模式则是针对当前被点击的 item。

```java
public class SwipeRecyclerView extends RecyclerView {
    /**
     * lastHolder 为 Down 事件来临时，正在显示菜单栏的 ViewHolder。
     * curHolder 为 Down 事件来临时，对应的被点击的 ViewHolder。
     * */
    private ViewHolder curHolder, lastHolder;
    /**
     * RV 是否处于拦截模式的标识
     * */
    private boolean isInterceptMode;

    public TestRecyclerView(@NonNull Context context) {
        super(context);
    }

    public TestRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TestRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs,
                            int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                lastHolder = curHolder;
                curHolder = findViewHolder(event);
                isInterceptMode = isMenuShowing(lastHolder);
                break;
        }
        return isInterceptMode;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        // Scroll 与 LongClick 只生效一个
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                if(isInterceptMode && lastHolder != null) {
                    // 点击的不是正在显示菜单的 item，则菜单直接隐藏
                    hideMenu(lastHolder);
                }
                return true;
            case MotionEvent.ACTION_MOVE:
                if(isInterceptMode) {
                    return true;
                }
                if(isVerScroll) {
                    return super.onTouchEvent(event);
                }
                // 水平滚动
                return dealScroll(curHolder, event);
        }
        return super.onTouchEvent(event);
    }

    private ViewHolder findViewHolder(MotionEvent event) {
        View view = findChildViewUnder(event.getX(), event.getY());
        if(view == null) {
            return null;
        }
        return findContainingViewHolder(view);
    }

    private boolean isMenuShowing(ViewHolder holder) {
        if(holder == null) {
            return false;
        }
        return holder.itemView.getScrollX() > 0;
    }

    private boolean hideMenu(ViewHolder holder) {
        if(holder == null) {
            return false;
        }
        mScroller.startScroll(holder.itemView.getScrollX(), 0, -holder.itemView.getScrollX(), 0);
        invalidate();
        return true;
    }
}
```

### 6. item 区别对待

上面的拦截模式中，没有区分不同 item 的点击，而 QQ 是有的。QQ 的交互逻辑如下：

- 点击了没显示菜单布局的 item，菜单在 Down 时收回
- 点击了显示菜单的 item 的内容布局，菜单在 Up 时收回
- 点击了显示菜单的 item 的菜单布局，菜单不收回，菜单选项响应点击事件
- 按住了显示菜单的 item 的内容布局，响应 Scroll 动作

基于上面的逻辑，我们梳理下 RV 什么时候需要处于拦截模式，什么时候不需要：

- 未显示菜单布局时，不拦截
- 显示菜单布局时，点击了非菜单 item，拦截。Down 事件时菜单收回，后续事件全部消费
- 显示菜单布局时，点击了菜单 item 的内容布局，拦截。Up 事件时菜单收回，后续事件全部消费
- 显示菜单布局时，点击了菜单 item 的菜单布局，不拦截。Down 事件时菜单收回，事件交给对应的子 item 消费
- 显示菜单布局时，按住了菜单 item，拦截。处理 Scroll 动作

总结一下，分类图如下：

根据上述的分类图可知，只自定义 RV，是满足不了需求的，还需要配合自定义子 View，才能实现 OK 的功能。下面的代码实现了部分要求：

```java
public class SwipeRecyclerView extends RecyclerView {
    /**
     * RV 是否处于拦截模式的标识
     * */
    private boolean isInterceptMode;
    /**
     * 是否点击的菜单布局的标识
     * */
    private boolean isTouchMenu;

    public TestRecyclerView(@NonNull Context context) {
        super(context);
    }

    public TestRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TestRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs,
                            int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                isInterceptMode = isMenuShowing(lastHolder);
                isTouchMenu = false;
                if(lastHolder == null || curHolder == null) {
                    break;
                }
                if(lastHolder.getBindingAdapterPosition()
                   == curHolder.getBindingAdapterPosition()) {
                    // 判断点击的是否是菜单布局
                    isTouchMenu = isTouchMenu(event);
                }
                if(isInterceptMode && lastHolder.getBindingAdapterPosition()
                   != curHolder.getBindingAdapterPosition()) {
                    // 点击的不是正在显示菜单的 item，则菜单直接隐藏
                    hideMenu(lastHolder);
                }
                if(isInterceptMode && isTouchMenu) {
                    hideMenu(lastHolder);
                }
                break;
        }
        return isInterceptMode && !isTouchMenu;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        // Scroll 与 LongClick 只生效一个
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_MOVE:
                // 大于阙值，才进行滚动
                if(isInterceptMode && lastHolder.getBindingAdapterPosition()
                   == curHolder.getBindingAdapterPosition() 
                   && Math.abs(downX - event.getX(pointerIndex)) > scrollSlop) {
                    isInterceptMode = false;
                    return dealScroll(lastHolder, event);
                }
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if(isInterceptMode && !isTouchMenu && lastHolder.getBindingAdapterPosition()
                   == curHolder.getBindingAdapterPosition()) {
                    hideMenu(lastHolder);
                    return true;
                }
                break;
        }
        return super.onTouchEvent(event);
    }

    /**
     * 判断是否点击的是菜单
     * */
    private boolean isTouchMenu(MotionEvent event) {
        if(lastHolder == null) {
            return false;
        }
        View view = lastHolder.itemView.findViewById(MenuFuncId.MENU);
        if(view == null) {
            return false;
        }
        Rect rect = new Rect();
        view.getGlobalVisibleRect(rect);

        return rect.contains((int)event.getRawX(), (int)event.getRawY());
    }
}
```

### 7. 响应点击事件 + 菜单隐藏显示回调

上面的代码中，我们忽略了 item 的点击响应，现在加上，然后加上一些其他功能后，形成的完整代码如下：

```java
public class SwipeRecyclerView extends RecyclerView {
    private static final String TAG = "SwipeRecyclerView";
    /**
     * 滚动事件的阙值
     * */
    private int scrollSlop;
    /**
     * 拦截模式下，是否有滚动过
     * */
    private boolean isScrollInIntercept;
    /**
     * 滚动相关类
     * */
    private Scroller mScroller;
    /**
     * Down 事件的坐标点，用于 Fling 动作
     * */
    private float rawDownX, rawDownY;
    /**
     * Move 事件(上次事件)的坐标点，用于 Scroll 动作
     */
    private float lastX;
    /**
     * 记录的主手指
     * */
    private int pointerId;
    /**
     * 一次事件流中，是水平滑动，还是竖直滑动的标识
     * */
    private boolean isHorScroll, isVerScroll;
    /**
     * Down 事件按下时的 ViewHolder，lastHolder 为手指按下时，正在显示菜单栏的 ViewHolder
     * 拦截模式下，是对 lastHolder 进行操作，非拦截模式下，对 curHolder 进行操作
     * */
    private ViewHolder curHolder, lastHolder;
    /**
     * 菜单是否显示，将 RV 分成两种模式：拦截模式和非拦截模式
     * 菜单栏显示时，二次点击的不是当前显示菜单的 item，就是拦截模式，否则就是非拦截模式
     * */
    private boolean isInterceptMode;
    /**
     * 菜单栏的最大显示宽度，也是每个 item 可滚动的最大宽度
     * */
    private int maxScrollDistance;
    /**
     * 当前滑动的方向，大于 0 表示向左，小于 0 表示向右，等于 0 则表示既不左滑也不右滑
     * 此值还用于判断菜单显示隐藏的方法是否需要回调
     * */
    private int scrollDirection;

    private OnMenuStateChangeListener mOnMenuStateChangeListener;

    public SwipeRecyclerView(@NonNull Context context) {
        this(context, null);
    }

    public SwipeRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public SwipeRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init();
    }
    private void init() {
        ViewConfiguration configuration = ViewConfiguration.get(getContext());
        scrollSlop = configuration.getScaledTouchSlop();
        mScroller = new Scroller(getContext());
    }
    /**
     * 设置菜单栏状态变化的回调
     * */
    public SwipeRecyclerView setOnMenuStateChangeListener(OnMenuStateChangeListener listener) {
        mOnMenuStateChangeListener = listener;
        return this;
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        curHolder = null;
        lastHolder = null;
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        // 拦截模式下，事件全部拦截
        int pointerIndex;
        float x, y;
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                if(!mScroller.isFinished()) {
                    mScroller.forceFinished(true);
                }
                // 避免多指事件干扰
                pointerIndex = event.getActionIndex();
                x = event.getX(pointerIndex);
                y = event.getY(pointerIndex);

                ViewHolder holder = findViewHolder(event);
                // 显示菜单栏，就拦截
                lastHolder = curHolder;
                if(isMenuShowing(lastHolder)) {
                    maxScrollDistance = calculateMaxScrollDistance(lastHolder);
                    // 菜单栏显示时，如果二次点击的不是当前显示菜单栏的 item，则需要拦截事件，隐藏菜单栏
                    if(holder != null && lastHolder != null && holder.getBindingAdapterPosition()
                       != lastHolder.getBindingAdapterPosition()) {
                        hideMenu(lastHolder);
                        // ----------------------------拦截模式----------------------------
                    } else if(isClickMenu(lastHolder, event)) {
                        isInterceptMode = false;
                        return super.onInterceptTouchEvent(event);
                    }
                    isInterceptMode = true;
                } else {
                    // ----------------------------非拦截模式----------------------------
                    isInterceptMode = false;
                    maxScrollDistance = calculateMaxScrollDistance(holder);
                }
                curHolder = holder;
                // 二次点击时，点击的不是显示菜单的 item，则拦截，隐藏 item
                rawDownX = lastX = x;
                rawDownY = y;
                // Down 事件时，必定有至少一根手指，这个手指的 index 至少为 0
                pointerId = event.getPointerId(0);
                // 避免自动 Scroll 的影响
                isHorScroll = isVerScroll = false;
                isScrollInIntercept = false;
                scrollDirection = 0;

                if(isInterceptMode) {
                    return true;
                }
                return super.onInterceptTouchEvent(event);
            case MotionEvent.ACTION_MOVE:
                // 需要水平或者竖直滚动时，走到自身 View 的 onTouchEvent 方法
                // Move 拦截后，后续的 Up、Cancel 都会交给此 View 处理
                if(isVerScroll || isHorScroll) {
                    return true;
                }
                pointerIndex = event.findPointerIndex(pointerId);
                x = event.getX(pointerIndex);
                y = event.getY(pointerIndex);
                // 优先检测竖直方向的滑动
                if(!isVerScroll && Math.abs(x - rawDownX) < Math.abs(y - rawDownY) && Math.abs(y - rawDownY) > scrollSlop) {
                    isVerScroll = true;
                    return true;
                }
                if(!isHorScroll && Math.abs(x - rawDownX) > Math.abs(y - rawDownY) && Math.abs(x - rawDownX) > scrollSlop) {
                    isHorScroll = true;
                    return true;
                }
                break;
        }
        return super.onInterceptTouchEvent(event);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int pointerIndex;
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_MOVE:
                // ----------------------------拦截模式----------------------------
                if(isInterceptMode) {
                    if(lastHolder == null || curHolder == null) {
                        return true;
                    }
                    if(lastHolder.getBindingAdapterPosition() != curHolder.getBindingAdapterPosition()) {
                        return true;
                    } else {
                        pointerIndex = event.findPointerIndex(pointerId);
                        // 大于阙值，才进行滚动
                        if(Math.abs(rawDownX - event.getX(pointerIndex)) > scrollSlop) {
                            isScrollInIntercept = true;
                            return dealScroll(lastHolder, event);
                        }
                    }
                }
                // ----------------------------非拦截模式----------------------------
                // 竖直滚动，不额外实现逻辑
                if(isVerScroll) {
                    return super.onTouchEvent(event);
                }
                // 水平滚动
                return dealScroll(curHolder, event);
            case MotionEvent.ACTION_POINTER_UP:
                // 此段代码是 Google 官方写法
                // 抬起的手指的索引
                pointerIndex = event.getActionIndex();
                int tempPointerId = event.getPointerId(pointerIndex);
                // 如果抬起的手指是当前追踪的手指，则换下个手指追踪
                if(tempPointerId == pointerId) {
                    int newPointerIndex = pointerIndex == 0 ? 1 : 0;
                    lastX = event.getX(newPointerIndex);
                    pointerId = event.getPointerId(newPointerIndex);
                }
                return super.onInterceptTouchEvent(event);
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                // ----------------------------拦截模式----------------------------
                if(isInterceptMode) {
                    if(isMenuShowing(lastHolder)) {
                        if(isScrollInIntercept) {
                            // 滚动后当做 Fling 处理
                            dealFling(lastHolder, event);
                        } else {
                            hideMenu(lastHolder);
                        }
                    }
                    return true;
                }
                // ----------------------------非拦截模式----------------------------
                if(isVerScroll) {
                    return super.onTouchEvent(event);
                } else {
                    dealFling(curHolder, event);
                    return true;
                }
        }
        return super.onTouchEvent(event);
    }

    /**
     * Scroll 动作是在 Move 事件中触发的
     *
     * @return true 表示需要滚动，false 不需要滚动
     * */
    private boolean dealScroll(ViewHolder holder, MotionEvent event) {
        if (holder == null) {
            return false;
        }
        if(maxScrollDistance <= 0) {
            return false;
        }
        int pointerIndex = event.findPointerIndex(pointerId);
        float x = event.getX(pointerIndex);
        int offsetX = (int) (lastX - x);
        // 判断条件范围
        // 手指从右向左移动，布局也从右向左移动，左移到达最大值
        if(offsetX > 0 && holder.itemView.getScrollX() + offsetX > maxScrollDistance) {
            scrollDirection = offsetX;
            offsetX = maxScrollDistance - holder.itemView.getScrollX();
        }
        // 手指从左向右移动，布局也从左向右移动，右移到达最大值
        if(offsetX < 0 && holder.itemView.getScrollX() + offsetX < 0) {
            scrollDirection = offsetX;
            offsetX = -holder.itemView.getScrollX();
        }

        // 竖直方向不移动
        curHolder.itemView.scrollBy(offsetX, 0);
        invalidate();

        lastX = x;
        return true;
    }

    /**
     * 是否判定为水平方向的 Fling，如果是，则执行 Fling 动作
     *
     * Fling 动作是在 Up 事件中触发的
     * */
    private boolean dealFling(ViewHolder holder, MotionEvent event) {
        float nowX = event.getX();
        float offsetX = rawDownX - nowX;

        if(holder == null || holder.itemView.getScrollX() <= 0) {
            return false;
        }
        // 没有可滚动的距离
        if(maxScrollDistance < 0) {
            return false;
        }
        int dx;
        // 菜单栏显示
        // 拖动距离不足 1/3 时动作不生效
        if(Math.abs(offsetX) < (float) maxScrollDistance / 3) {
            if(offsetX > 0) {
                dx = -holder.itemView.getScrollX();
            } else {
                // 回弹不隐藏
                dx = maxScrollDistance - holder.itemView.getScrollX();
            }
        } else {
            scrollDirection = (int)offsetX;
            if(offsetX > 0) {
                dx = maxScrollDistance - holder.itemView.getScrollX();
            } else {
                dx = -holder.itemView.getScrollX();
            }
            // 不需要滑动，说明到达最大值，不再回调
            scrollDirection = dx;
        }

        // 滑动到目标位置
        mScroller.startScroll(holder.itemView.getScrollX(), 0, dx, 0);
        invalidate();

        return true;
    }

    @Override
    public void computeScroll() {
        if(mScroller.computeScrollOffset()) {
            // 拦截模式下，需要的是上个显示菜单的 item 滚动，而不是当前被点的 item 滚动
            if(isInterceptMode) {
                if(lastHolder == null) {
                    return;
                }
                lastHolder.itemView.scrollTo(mScroller.getCurrX(), mScroller.getCurrY());
                onScrolling(mScroller.getCurrX(), mScroller.getCurrY());
            } else {
                if(curHolder == null) {
                    return;
                }
                curHolder.itemView.scrollTo(mScroller.getCurrX(), mScroller.getCurrY());
                onScrolling(mScroller.getCurrX(), mScroller.getCurrY());
            }
            invalidate();
        }
    }

    private void onScrolling(int scrollX, int scrollY) {
        // 左滑达到最大值
        if(scrollDirection > 0 && scrollX >= maxScrollDistance) {
            notifyItem(true);
            // 回调一次之后，不再回调
            scrollDirection = 0;
        } else if(scrollDirection < 0 && scrollX <= 0) {
            notifyItem(false);
            scrollDirection = 0;
        }
    }

    /**
     * -1 代表不可滑动
     * */
    private int calculateMaxScrollDistance(ViewHolder viewHolder) {
        if(viewHolder == null) {
            return -1;
        }
        // TODO View 的 id 需要自己定义
        ViewGroup rootViewGroup = viewHolder.itemView.findViewById(MenuFuncId.MENU);
        if(rootViewGroup == null || rootViewGroup.getChildCount() < 0) {
            return -1;
        }
        int result = 0;
        View view;
        // 根布局是水平方向的 LL，直接从左向右加 item 的宽度
        for(int i = 0; i < rootViewGroup.getChildCount(); i++) {
            view = rootViewGroup.getChildAt(i);
            if(view == null || view.getVisibility() == View.GONE) {
                continue;
            }
            result += view.getMeasuredWidth();
        }
        return result;
    }

    private ViewHolder findViewHolder(MotionEvent event) {
        View view = findChildViewUnder(event.getX(), event.getY());
        if(view == null) {
            return null;
        }
        return findContainingViewHolder(view);
    }
    /**
     * 菜单栏是否在显示的标识
     *
     * @return true 表示菜单在显示，false 表示菜单未显示
     * */
    private boolean isMenuShowing(ViewHolder holder) {
        if(holder == null) {
            return false;
        }
        return holder.itemView.getScrollX() > 0;
    }
    /**
     * 隐藏菜单栏
     * */
    private boolean hideMenu(ViewHolder holder) {
        if(holder == null) {
            return false;
        }
        mScroller.startScroll(holder.itemView.getScrollX(), 0, -holder.itemView.getScrollX(), 0);
        invalidate();
        return true;
    }

    private void notifyItem(boolean isVisible) {
        ViewHolder holder;
        if(isInterceptMode) {
            holder = lastHolder;
        } else {
            holder = curHolder;
        }
        if(mOnMenuStateChangeListener != null && holder != null) {
            mOnMenuStateChangeListener.onMenuVisibilityChange(holder.getAdapterPosition(), isVisible);
        }
    }

    private boolean isClickMenu(ViewHolder holder, MotionEvent event) {
        if(!isMenuShowing(holder)) {
            return false;
        }
        View menuView = holder.itemView.findViewById(MenuFuncId.MENU);
        if(menuView == null) {
            return false;
        }

        int pointerIndex = event.getActionIndex();
        float x, y;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            x = event.getRawX(pointerIndex);
            y = event.getRawY(pointerIndex);
        } else {
            x = event.getRawX();
            y = event.getRawY();
        }

        Rect location = new Rect();
        menuView.getGlobalVisibleRect(location);
        return location.contains((int)x, (int)y);
    }

    public interface OnMenuStateChangeListener {
        /**
         * 菜单栏可见性变化时，会回调此接口
         *
         * @param menuPos 菜单栏变化的位置，对应  RV 中的 pos
         * @param isVisible true 表示菜单栏变的可见，false 表示菜单栏变的不可见
         * */
        void onMenuVisibilityChange(int menuPos, boolean isVisible);
    }
}
```

到目前为止，上面的代码，除了没有实现长按效果，其他的都实现了。就先讲到这吧。后面会出一篇内部拦截法实现 QQ 侧滑效果的文章。