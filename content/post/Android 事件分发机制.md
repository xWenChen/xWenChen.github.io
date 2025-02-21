---
title: "Android 事件分发机制"
description: "本文略讲了 Android 的事件分发机制"
keywords: "Android,事件分发机制"

date: 2019-12-01T00:12:00+08:00

categories:
  - Android
tags:
  - Android
  - 事件分发

url: post/A32C6B8D505F409F96955A7A9A88A649.html
toc: true
---

本文略讲了 Android 的事件分发机制

<!--More-->

**概念**

如果事件被处理了，返回 true，否则返回 false。有些文章说事件被消费了，其实意思和被处理了一样。

本文会首先讲解正常的处理流程，包括 Down、Move、Up、Cancel 等事件。然后会讲解如长按事件、多指事件等事件的分发和处理。看到这里，你会想，文章是不是很长？没错，正如你所料想的一样，这篇文章就像老太婆的裹脚布，又臭又长。其实就我个人经历而言，网上那么多的文章，其实都是大同小异。什么分发流程，值的返回流程，看了也解决不了问题，反而让人头晕，所以我才下定决心好好研究一番源码。看懂了源码，我才能真正的解决实际项目中遇到的问题。所以这篇文章就是基于源码角度的。但是别担心，涉及到分发流程的方法不会删减代码，并且会做到几乎每行代码都有注释的程度，所以别担心看不懂。

Tips:建议每位读者自己观看源码，遇到不懂的地方再看我文章中代码的注释，这样有助于加深印象，理解流程

## 主流程

对于所有的事件分发中的调用，都有一个明确的逻辑返回关系（如下）。差异只是在得到返回值之后的后续处理过程。

![事件处理的返回值](/imgs/事件处理的返回值.webp)

对于得到返回值之后的处理方式，本文会分段讲解，最后进行汇总。

对于所有的事件分发，都是从最外层 Activity 向里面的 View 传递，在事件分发的过程中，其涉及到的层次结构如下：

![事件分发中的层次](/imgs/事件分发中的层次.webp)

各层次讲解：

- Activity：在一次事件分发过程中，Activity 是分发流程的起点。其最先接收事件。
- Window：每个 Activity 都包含一个 Window，Window 是一个抽象类，其有唯一的实现类 PhoneWindow。涉及到 Window 的操作，都应在 PhoneWindow 里面寻找具体实现。
- DecorView：是每一个视图层次体系中的根布局，所有的事件必然经过它。
- ViewGroup：一个视图层次结构中可以有一个或者多个 ViewGroup，它是事件分发流程中的双主角之一。
- View：和 ViewGroup一样，一个视图层次结构中可以有一个或者多个 View，它是事件分发流程中的双主角之二。

而事件分发流程中，主要涉及三个 方法：

- dispatchTouchEvent：该方法负责将屏幕触摸事件分发到指定的目标视图上，事件的分发机制主要是因它而得名。
- onInterceptTouchEvent：该方法是 ViewGroup 独有，其作用同名字一样，主要是用来拦截事件的分发，该方法可以拦截传递到 ViewGroup 的事件，使其不向 View 分发。
- onTouchEvent：顾名思义，该方法用来处理事件。

### 事件分发的起点，Activity 中的事件分发

对于所有的事件分发，分发的起点和终点都是 Activity。Activity 中需要关注两个方法：dispatchTouchEvent、onTouchEvent。一个负责事件的分发，一个负责事件的处理。Activity.dispatchEvent 是事件分发流程的起点，其分发代码如下：

```java
public boolean dispatchTouchEvent(MotionEvent ev) {
    // 进入 Window
    if (getWindow().superDispatchTouchEvent(ev)) {
        // 事件被消费，返回 true
        return true;
    }
    // 事件未被消费，调用自身的 onTouchEvent 方法，该方法默认实现永远返回 false
    return onTouchEvent(ev);
}
```

其流程如下：

![Activity 中的事件分发](/imgs/Activity中的事件分发.webp)

当子 View 都没有处理事件时，Activity 自身会调用 onTouchEvent 处理事件，不过 Activity 的 onTouchEvent 的**默认实现永远返回 false**。别问我从哪里知道的，方法注释里写的清清楚楚的。

### 事件分发流程之二，window 的事件分发

在上面 Activity 的分发流程中，其会首先调用`getWindow().superDispatchTouchEvent(ev)`方法，其中 getWindow 会返回当前 Activity 的 Window 对象，然后调用 Window 的 superDispatchTouchEvent 方法，但 Window 中的方法如下：

```java
public abstract boolean superDispatchTouchEvent(MotionEvent event);
```

可以看到，该方法是一个抽象方法，只是被定义了，并未被实现。具体的方法实现应该到实现类去寻找。前面我们讲过 Window 有一个唯一的 实现类 PhoneWindow (该知识点可以通过阅读 Window 的说明文档得到)，那我们便看看 PhoneWindow 中的 superDispatchTouchEvent 方法是怎么实现的。

```java
@Override
public boolean superDispatchTouchEvent(MotionEvent event) {
    // mDecor 是当前 Window 持有的 DecorView 实例
    return mDecor.superDispatchTouchEvent(event);
}
```

可以看到，PhoneWindow 继续调用 DecorView 的 superDispatchTouchEvent 方法。由此我们可以得出，事件能否被处理，是取决于 DecorView 中的处理方式的。让我们看看 DecorView 中的处理。

### 事件分发流程之三，DecorView 的事件分发

```java
public boolean superDispatchTouchEvent(MotionEvent event) {
    return super.dispatchTouchEvent(event);
}
```

可以看出，DecorView 继续调用父类的 dispatchTouchEvent 方法，而 DecorView 是继承自 FrameLayout 的，那让我们去 FrameLayout 中找找看。很遗憾，FrameLayout 中是没有实现 dispatchTouchEvent 方法的。而在 DecorView 中点击跳转，最终会跳到 ViewGroup 的 dispatchTouchEvent 方法中，说明 FrameLayout 将事件的分发交给了父类 ViewGroup 处理。**ViewGroup 可是事件分发的主角之一**，让我们看看 ViewGroup 的 dispatchTouchEvent 方法。

### 事件分发流程之四，ViewGroup 的事件分发

毫不客气的讲，Android 的事件分发流程主体就是在这个方法中。理解了这个方法的逻辑，就可以理解 Android 的事件分发机制。首先我们先看看 dispatchTouchEvent 的代码行数：

![ViewGroup_dispatchTouchEvent代码行数](/imgs/ViewGroup_dispatchTouchEvent代码行数.webp)

从 2541 到 2755，ViewGroup 的 dispatchTouchEvent 方法跨越了整整 214 行，是相当多了，那么便说明这个方法是非常复杂的。但是不担心，让我们来一步步梳理。

**ViewGroup.dispatchTouchEvent 方法讲解开始**

```java
// 分发的主流程
public boolean dispatchTouchEvent(MotionEvent ev) {
    // 方法开头的两个 if 判断，不重要，但此处还是讲讲作用
    // 1、该变量在 View 中定义，用于调试。其作用是用于一致性确认，与主流程无关
    // 在事件分发流程中，找不到的变量和方法可以到View和MotionEvent中寻找。因为索引不一定建立，在源码中才会标红
    if (mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onTouchEvent(ev, 1);
    }
    // 2、该判断主要是为无障碍功能准备
    if (ev.isTargetAccessibilityFocus() && isAccessibilityFocusedViewOrHost()) {
        ev.setTargetAccessibilityFocus(false);
    }
    // 事件是否被处理的标志
    boolean handled = false;
    // 当具备安全性时，事件可以进入主流程继续分发。安全性主要是指当前 Window 是否被隐藏或者遮挡
    // 当窗口被遮挡，并且设置了被遮挡时事件不能向下传递。事件便会不被处理
    if (onFilterTouchEventForSecurity(ev)) {
        // 此处主流程代码省略，下面单独讲解
    }
    // 此代码用于调试，与主流程无关
    if (!handled && mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onUnhandledEvent(ev, 1);
    }
    return handled;
}
```

上面的代码中需要注意的几个点：

1. 最终的返回值是 handled，故我们只需要了解 handled 的值在什么地方改变，便可以确定哪里是分发的主要流程。
2. 剩下的几个 if 判断，除了明确标注的是主流程的 if 判断，其余的此处都是无关紧要的代码。因为他们并未改变 handled 的值，并且没有可以立即退出分发的返回值。
3. handled 为 true，表示事件被处理了，否则是没有处理。
4. 当 View 是被遮挡，并且被遮挡时会过滤掉触摸事件，这种情况下，就说该事件不符合安全策略。此时会直接返回 false，表示事件未被处理。

看了总体流程，让我们来看看主流程：

```java
if (onFilterTouchEventForSecurity(ev)) {
    // 获取事件动作，是 Down、Move、Up、Cancel 等事件
    final int action = ev.getAction();
    // 获取 Action 表示的动作(此处有疑问？没事，代码下面会做解释)
    // 简单的说，就是一个 Event 分为动作的信息和手指的信息，此处只取动作的信息
    final int actionMasked = action & MotionEvent.ACTION_MASK;

    // 初始化按下事件。按下事件是一个事件序列的起始点。当系统监测到有按下事件时，都会去做相应的初始化操作
    if (actionMasked == MotionEvent.ACTION_DOWN) {
        // mFirstTouchTarget 是可处理触摸事件目标形成的链表的头指针，TouchTarget 可以使 View 与触摸事件形成映射关系
        // 事件序列结束时，可能会出现因为一些特殊原因，如 ANR，导致 mFirstTouchTarget 指向的链表未被清空
        // 此处在新的事件序列开始前清空链表，并重置点击状态
        cancelAndClearTouchTargets(ev);
        resetTouchState();
    }

    // 是否中断事件分发的标志
    final boolean intercepted;
    // mFirstTouchTarget 不为空表示，此时已经存在可以处理事件的目标 View
    if (actionMasked == MotionEvent.ACTION_DOWN || mFirstTouchTarget != null) {
        // 判断是否允许父 View 拦截事件，为 true 表示不允许父 View 拦截事件
        // 详情可以阅读 ViewParent.requestDisallowInterceptTouchEvent(false) 的方法说明
        final boolean disallowIntercept = (mGroupFlags & FLAG_DISALLOW_INTERCEPT) != 0;
        // 父 View 可以拦截事件
        if (!disallowIntercept) {
            // 判断是否需要拦截事件，默认会对鼠标的左键按下拖动滚动条事件作拦截
            intercepted = onInterceptTouchEvent(ev);
            // 设置 Action，防止触摸动作因为特殊原因改变
            ev.setAction(action);
        } else {
            intercepted = false;
        }
    } else {
        // 不是按下事件，且事件序列链表头指针为空（不存在处理触摸事件的目标 View）。则拦截事件，不向下分发
        intercepted = true;
    }
    // 无障碍相关，此处跳过
    if (intercepted || mFirstTouchTarget != null) {
        ev.setTargetAccessibilityFocus(false);
    }
    // 是否需要取消事件的标志
    final boolean canceled = resetCancelNextUpFlag(this)
        || actionMasked == MotionEvent.ACTION_CANCEL;

    // 是否将一个MotionEvent拆分到多个子View的标志，
    // 视图可能存在上下重叠的情况，此变量为 true 时表示重叠处的所有子 View 都可以处理触摸事件
    final boolean split = (mGroupFlags & FLAG_SPLIT_MOTION_EVENTS) != 0;
    // 新的可以处理触摸事件的目标对象。
    TouchTarget newTouchTarget = null;
    // 是否已经将事件分发到新的 TouchTarget 的标识
    boolean alreadyDispatchedToNewTouchTarget = false;
    // 事件不被拦截，并且不被取消
    if (!canceled && !intercepted) {

        // 无障碍时接收触摸事件的 View，此处不讲
        View childWithAccessibilityFocus = ev.isTargetAccessibilityFocus()
            ? findChildWithAccessibilityFocus() : null;

        // 是按下事件或者多指按下事件。第三个事件不用关注，不在 onTouchEvent 的处理范围内，感兴趣的可以查看此变量的源码说明
        if (actionMasked == MotionEvent.ACTION_DOWN
            || (split && actionMasked == MotionEvent.ACTION_POINTER_DOWN)
            || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
            // 对于按下事件，actionIndex 的值总为 0
            final int actionIndex = ev.getActionIndex();
            // 待分配的id位，final型，不可更改，可以理解将这个变量为一个 mask（不懂 mask，代码下面会讲）
            final int idBitsToAssign = split ? 1 << ev.getPointerId(actionIndex) : TouchTarget.ALL_POINTER_IDS;

            // 清除之前的 touch targets（映射关系），重新获取
            removePointersFromTouchTargets(idBitsToAssign);

            // 拿到此 ViewGroup 的所有孩子数，准备遍历，找到目标 View
            final int childrenCount = mChildrenCount;

            if (newTouchTarget == null && childrenCount != 0) {
                // 获取触摸点的位置信息
                final float x = ev.getX(actionIndex);
                final float y = ev.getY(actionIndex);
                // 获取可以接收触摸事件的 View 的列表
                final ArrayList<View> preorderedList = buildTouchDispatchChildList();
                // 是否是自定义顺序的标志，为 true 表示用户自定义了 View 的绘制顺序
                final boolean customOrder = preorderedList == null
                    && isChildrenDrawingOrderEnabled();
                final View[] children = mChildren;
                // 开始循环遍历，找出目标 View
                for (int i = childrenCount - 1; i >= 0; i--) {
                    // 拿到子 View 在列表中的索引。如果没有自定义绘制顺序，索引的返回值就是默认传入的 i
                    final int childIndex = getAndVerifyPreorderedIndex(
                        childrenCount, i, customOrder);
                    // 拿到第 i 个位置的子 View，如果自定义顺序列表为空，就从默认的列表中获取，否则从自定义列表中获取
                    final View child = getAndVerifyPreorderedView(
                        preorderedList, children, childIndex);

                    // 无障碍相关，此处不关注
                    if (childWithAccessibilityFocus != null) {
                        if (childWithAccessibilityFocus != child) {
                            continue;
                        }
                        // 设置为 null，下次不会走此处的 if 判断
                        childWithAccessibilityFocus = null;
                        i = childrenCount - 1;
                    }
                    // 如果子 View 不能接收事件，并且触摸事件没有在子 View 的范围内
                    // 则跳过本次执行，开始下一次执行
                    if (!canViewReceivePointerEvents(child)
                        || !isTransformedTouchPointInView(x, y, child, null)) {
                        ev.setTargetAccessibilityFocus(false);
                        continue;
                    }
                    
                    // 子 View 能够接收事件，并且触摸事件在子 View 的范围内
                    // 获取映射关系
                    newTouchTarget = getTouchTarget(child);
                    // 映射关系不为空，有能处理事件的child，中断循环
                    if (newTouchTarget != null) {
                        newTouchTarget.pointerIdBits |= idBitsToAssign;
                        break;
                    }
                    // 还没有形成映射关系，目前没有能处理事件的child
                    // 取消 View 暂时不能接收触摸事件的限制。CancelNextUpFlag 表示子 View 与 parent 暂时分离，不接收触摸事件
                    resetCancelNextUpFlag(child);
                    // 前面讲过，如果需要，目标 MotionEvent需要被分发到多个子 View 中，
                    // 但是目标 MotionEvent 并不一定满足能被分发到多个子 View 的条件，所以需要转换事件，再尝试分发
                    // 如果传入的子 View 为空，便会将事件交给父类（View）处理
                    // dispatchTransformedTouchEvent 第一处被调用的地方
                    if (dispatchTransformedTouchEvent(ev, false, child, idBitsToAssign)) {
                        // mLastTouchDownTime 是个用于调试的变量，不用在意
                        // ----------不用在意的代码开始----------
                        mLastTouchDownTime = ev.getDownTime();
                        if (preorderedList != null) {
                            for (int j = 0; j < childrenCount; j++) {
                                if (children[childIndex] == mChildren[j]) {
                                    mLastTouchDownIndex = j;
                                    break;
                                }
                            }
                        } else {
                            mLastTouchDownIndex = childIndex;
                        }
                        mLastTouchDownX = ev.getX();
                        mLastTouchDownY = ev.getY();
                        // ----------不用在意的代码结束----------

                        // 事件成功分发到子 View，建立映射关系
                        newTouchTarget = addTouchTarget(child, idBitsToAssign);
                        alreadyDispatchedToNewTouchTarget = true;
                        // 退出循环
                        break;
                    }

                    // 无障碍相关，不用关注
                    ev.setTargetAccessibilityFocus(false);
                }
                if (preorderedList != null) preorderedList.clear();
            }

            // 如果仍然没有找到合适的子 View，就从已有的映射关系中寻找一个最近的 TouchTarget 赋值
            // 如果上面已经找到了合适的子 View，此处便不会执行
            if (newTouchTarget == null && mFirstTouchTarget != null) {
                newTouchTarget = mFirstTouchTarget;
                // 这里是链表的操作
                while (newTouchTarget.next != null) {
                    newTouchTarget = newTouchTarget.next;
                }
                newTouchTarget.pointerIdBits |= idBitsToAssign;
            }
        }
    }

    // 非Down事件，直接进入这里，当有可以处理事件的对象时（处理Down事件时已经进行赋值），在这里寻找。
    if (mFirstTouchTarget == null) {
        // 没有可处理触摸事件的子 View，进行分发，交给父类处理（传入的 child 为空）
        // dispatchTransformedTouchEvent 第二处被调用的地方
        handled = dispatchTransformedTouchEvent(ev, canceled, null, TouchTarget.ALL_POINTER_IDS);
    } else {
        // 此处代码代表了一个重要的细节，就是如果Down事件被分发到了子View(mFirstTouchTarget != null)，那么后续的非Down事件都会直接交给此View处理。不走分发流程
        TouchTarget predecessor = null;
        TouchTarget target = mFirstTouchTarget;
        while (target != null) {
            final TouchTarget next = target.next;
            // 事件已经被分发处理
            if (alreadyDispatchedToNewTouchTarget && target == newTouchTarget) {
                handled = true;
            } else {
                final boolean cancelChild = resetCancelNextUpFlag(target.child) || intercepted;
                // 事件被处理，dispatchTransformedTouchEvent 第三处被调用的地方
                if (dispatchTransformedTouchEvent(ev, cancelChild, target.child, target.pointerIdBits)) {
                    handled = true;
                }
                // 链表操作，不关心
                if (cancelChild) {
                    if (predecessor == null) {
                        mFirstTouchTarget = next;
                    } else {
                        predecessor.next = next;
                    }
                    target.recycle();
                    target = next;
                    continue;
                }
            }
            predecessor = target;
            target = next;
        }
    }

    // 抬起事件，重置状态
    if (canceled
        || actionMasked == MotionEvent.ACTION_UP
        || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
        resetTouchState();
    } else if (split && actionMasked == MotionEvent.ACTION_POINTER_UP) {
        // 多指触摸事件下的状态重置
        final int actionIndex = ev.getActionIndex();
        final int idBitsToRemove = 1 << ev.getPointerId(actionIndex);
        removePointersFromTouchTargets(idBitsToRemove);
    }
}
```

**ViewGroup.dispatchTouchEvent 方法讲解结束**

是不是觉得上面的代码很多，很绕？没事，下面会对主流程进行更加细致的探讨。

- 主流程中，有一个判断是否符合安全策略的方法：onFilterTouchEventForSecurity(MotionEvent)，此方法的作用是判断事件是否符合安全策略。所谓的安全策略，主要由两个因素判定：一是当前窗口是否被遮挡，二是窗口被遮挡时是否过滤事件。如果窗口被遮挡，并且被遮挡时需要过滤事件。那么此时的事件就是不符合安全策略的。事件会被过滤，不再向下分发。事件处理结果直接返回 false，表示事件未被处理。通常，一个触摸事件是符合安全策略的，事件会正常向下分发
- 对于 mFirstTouchTarget 这个变量，我们需要重点关注一下。因为主流程中的许多流程分支都是与它有关的。上面的注释中讲过，它是一个头指针，在Down事件到来的时候，它会被重新置空，进行Down事件的处理。而不是Down事件的时候，mFirstTouchTarget 已不为空，便会从已有的映射关系中选择合适的child分发事件。由此我们可以知道2点信息，Down事件是一个事件序列的起点，并且如果一个Down事件被分发到某个子View，那么后续的所有的非Down都会直接被该View处理，不再走分发流程。
- 对于 mask，中文翻译是掩码的意思。在事件分发流程中，通过与掩码进行运算，我们可以分离出目标触摸动作的类型，因为 Android 将 TouchEvent 存储在一个整型中，但是一个整型 4 个字节，可表示的范围太大了，远远超过了动作和种类和数量范围。故 Android 将一个整型拆开，2个字节存储动作，2个字节存储按下手指的数量。那么这是如何做到的呢？就是通过掩码。MotionEvent 中有两个掩码，通过与运算，可以得到对应的数据：

```java
// 一个 Action 通过与该掩码进行与运算，便可以得到对应的动作类型
// 0xff = 0x00ff，故动作类型是存储在低位的2个字节中的
public static final int ACTION_MASK = 0xff;
// 一个 Action 通过与该掩码进行与运算，便可得到对应的手指信息
// 由值可知手指信息是存储在高位的2个字节中的
public static final int ACTION_POINTER_INDEX_MASK = 0xff00;
// 暂时就讲这么多，更具体的会在后面的多指事件处理中讲解
```

- dispatchTransformedTouchEvent 在分发流程中是一个非常重要的方法，它负责将触摸事件分发到对应的View，是**分发的具体执行者**。它会对事件进行包装、转换，以包含多个事件或者分发到多个视图。该方法不止会处理Down事件，其他事件也可以使用它判断。在上面代码的注释中，提到 dispatchTransformedTouchEvent 有三处被调用的地方，第一处是在判断 Down 事件，后面两处都是非 Down 事件的判断处理。 

让我们来看看 dispatchTransformedTouchEvent 都干了哪些事：

```java
private boolean dispatchTransformedTouchEvent(MotionEvent event, boolean cancel, View child, int desiredPointerIdBits) {
    // final 型，只能被赋值一次，代表着分发是个一次性操作
    final boolean handled;

    final int oldAction = event.getAction();
    // 取消事件是个特殊的事件，本方法不会对该事件进行转换或者过滤。取消事件重要的不是事件的内容，而是事件本身的意义
    // 取消事件会被分配到对应的View进行处理，Down 事件到来时不会走这个 if 判断，只有后面两个调用才会走这里。
    // 当没有找到对应的 View 时(child==null)，会将事件交给父类(View)处理，否则就交给对应的 View(child) 处理
    if (cancel || oldAction == MotionEvent.ACTION_CANCEL) {
        event.setAction(MotionEvent.ACTION_CANCEL);
        if (child == null) {
            // 此处复用父类的方法实现，ViewGroup的父类是View，View的分发方法后面会讲到，现在只要知道这个方法会最终调用到自身的OnTouchListener和onTouchEvent(继承自View)方法即可
            handled = super.dispatchTouchEvent(event);
        } else {
            handled = child.dispatchTouchEvent(event);
        }
        event.setAction(oldAction);
        return handled;
    }

    // 计算需要传递的事件需要包含的手指的数量
    final int oldPointerIdBits = event.getPointerIdBits();
    final int newPointerIdBits = oldPointerIdBits & desiredPointerIdBits;

    // 如果因为某些原因导致不正常的计算结果，比如一个触摸事件没有手指数量，那么此事件将被遗弃，不进行处理
    if (newPointerIdBits == 0) {
        return false;
    }

    /**
     * 如果满足以下条件，我们可以使用原触摸事件(传入的触摸事件)。否则我们就应该对该事件进行拷贝后使用：
     * 1、计算得到的新旧手指数量相同
     * 2、我们不需要对原触摸事件进行额外的不可逆的转换
     * 3、每一个对原触摸事件做出的更改，我们都进行还原
     * */
    // 进行 Down、Move、Up事件的分发处理，Cancel 已经在上面进行处理
    final MotionEvent transformedEvent;
    if (newPointerIdBits == oldPointerIdBits) {
        // 进入此 if 语句体有两种情况
        // 1、没有可以处理事件的 View(child==null)
        // 2、有可以尝试进行分发的View(child!=null，注意此处与上面cancel事件描述的区别)，并且View有单位矩阵(任何矩阵与单位矩阵相乘都等于其本身)
        if (child == null || child.hasIdentityMatrix()) {
            if (child == null) {
                handled = super.dispatchTouchEvent(event);
            } else {
                // 因为有 Move 事件，所以得进行偏移值处理
                final float offsetX = mScrollX - child.mLeft;
                final float offsetY = mScrollY - child.mTop;
                event.offsetLocation(offsetX, offsetY);
                // 分发给子 View
                handled = child.dispatchTouchEvent(event);

                event.offsetLocation(-offsetX, -offsetY);
            }
            return handled;
        }
        // 两种情况都不满足，获取拷贝
        transformedEvent = MotionEvent.obtain(event);
    } else {
        // 对触摸事件进行拆分，以满足触摸事件中含有指定数量的手指的信息
        transformedEvent = event.split(newPointerIdBits);
    }

    // 没有可处理事件的 View 时，都交给自身处理
    if (child == null) {
        handled = super.dispatchTouchEvent(transformedEvent);
    } else {
        final float offsetX = mScrollX - child.mLeft;
        final float offsetY = mScrollY - child.mTop;
        transformedEvent.offsetLocation(offsetX, offsetY);
        if (! child.hasIdentityMatrix()) {
            // 没有单位矩阵，就使用逆矩阵转换事件(逆矩阵与原矩阵相乘等于单位矩阵)
            transformedEvent.transform(child.getInverseMatrix());
        }
        // 尝试分发转换后的事件
        handled = child.dispatchTouchEvent(transformedEvent);
    }

    // 回收时间，主要是回收代码中使用 C/C++ 写的部分，说明TouchEvent的实现相当底层
    transformedEvent.recycle();
    return handled;
}
```

梳理了上面的主流程，我们可以看出，当没有可以处理触摸事件的子View(child==null)时，触摸事件会交给父类View处理。否则就交给对应的子View处理。

支持，ViewGroup的分发也算是梳理的告一段落了。下面，让我们看看ViewGroup中的拦截方法，拦截方法很简单，默认的实现对大多数事件都不拦截：

```java
/**
 * 当事件源是鼠标，并且鼠标左键按下，在滚动条的按钮上时（这个条件不确定），才进行拦截（条件太苛刻）
 * 故一般的事件，都不会拦截（姑且可以算是默认不拦截）
 * */
public boolean onInterceptTouchEvent(MotionEvent ev) {
    if (ev.isFromSource(InputDevice.SOURCE_MOUSE)
        && ev.getAction() == MotionEvent.ACTION_DOWN
        && ev.isButtonPressed(MotionEvent.BUTTON_PRIMARY)
        && isOnScrollbarThumb(ev.getX(), ev.getY())) {
        return true;
    }
    return false;
}
```

- 在 dispatchTouchEvent 方法中，判断是否需要拦截方法，需要满足两个条件之一：是Down事件，或者存在可处理事件的子View(mFirstTouchTarget != null)，如果两个条件都不满足，默认便会拦截事件。想像一个场景，当我们重写了拦截方法，默认返回true时，会发生什么情况？当Down事件到来时，被拦截了，此时不存在可以处理事件的子View，便会将事件交给父类View处理，父类View最终会分发到onTouchEvent方法上，这也就是官方的拦截方法文档注释提示，我们重写拦截方法onInterceptTouchEvent时，就应该一起重写处理方法onTouchEvent的原因。如果mFirstTouchTarget 不更新，为空。后续的事件到来，会默认被拦截，仍然会交给父View处理。这时，所有的触摸事件都被拦截了。如果Down事件未被拦截，正常分发给子类，此时已经存在处理事件的子View(child)，那么后续的所有的非Down事件都会交给该View处理，不走分发流程。拦截方法此时是失效的，这与上面我们分析 mFirstTouchTarget 变量时提到的观点相互印证。分析到这里，我们似乎可以得出一个结论，**mFirstTouchTarget 为空，表示没有拦截过Down事件，或者没有合适的处理事件的对象；不为空，表示拦截过Down事件，并且有合适的处理触摸事件的对象。**

讲完了 onInterceptTouchEvent 方法，我们来讲讲 onTouchEvent 方法。但是很可惜，**ViewGroup 中并没有定义 onTouchEvent 方法**。**onTouchEvent 方法是 View 中定义的**，后面我们会讲到。现在先总结下ViewGroup中的分发过程。

- 触摸事件的分发流程讲到这里，其实我们已经知道了**触摸事件是否被处理，取决于 ViewGroup 的 dispatchTouchEvent 方法的返回值**。dispatchTouchEvent 方法返回 true，事件就被处理了；dispatchTouchEvent 方法返回 false，事件就未被处理。前面的源码查看已经可以得出 Activity 的处理默认是返回 false 的，而 Window、DecorView 的处理又是简单的调用一个方法，所以返回值实际上实际上取决于 ViewGroup 的 dispatchTouchEvent 方法。
- 看完上面这么多，我们来画个 ViewGroup 的流程图：

![ViewGroup分发流程](/imgs/ViewGroup分发流程.webp)

经过一大段分析，画了个流程图出来，如果其中有不对的方法，欢迎大家指正。来总结一下：

- 拦截事件的情况下，如果是Down事件，此时必定不存在可以处理事件的子View（每个Down事件都被经过初始，相关变量已被重置），事件会被自身的onTouchEvent处理；但是如果是非Down事件，那么此时可能会存在可以处理事件的子View，此时仍会将事件分发给子View
- 非拦截事件的情况下，如果是Down事件，就会正常尝试分发，这是主流程分发流程。如果分发成功，结果取决于子View的处理（子View返回false，表示不处理，会继续尝试分发，如果返回true，则停止分发），如果分发不成功，结果取决于自身的onTouchEvent；如果是非Down事件，就会将事件直接分发给之前处理Down事件的子View，结果取决于子View的处理。

### 事件分发流程之五，View 的事件分发

上面将ViewGroup中的事件分发梳理了一次，还剩下一个View的分发流程未梳理。作为事件分发的双主角之二，让我们先来看看`View.dispatchTouchEvent`方法，此方法会在`ViewGroup.dispatchTransformedTouchEvent`方法中被调用到，他是事件分发在View中的起始部分：

```java
public boolean dispatchTouchEvent(MotionEvent event) {
    // 无障碍功能相关，此处不关注
    if (event.isTargetAccessibilityFocus()) {
        // We don't have focus or no virtual descendant has it, do not handle the event.
        if (!isAccessibilityFocusedViewOrHost()) {
            return false;
        }
        // We have focus and got the event, then use normal event dispatch.
        event.setTargetAccessibilityFocus(false);
    }
    // 事件是否被处理掉的标识
    boolean result = false;
    // 调试相关，此处不关注
    if (mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onTouchEvent(event, 0);
    }

    final int actionMasked = event.getActionMasked();
    if (actionMasked == MotionEvent.ACTION_DOWN) {
        // 是按下事件时，停止滑动
        stopNestedScroll();
    }
    // 分发主流程
    if (onFilterTouchEventForSecurity(event)) {
        // 输入源是鼠标时，此处代码生效，一般情况下忽略它
        if ((mViewFlags & ENABLED_MASK) == ENABLED && handleScrollBarDragging(event)) {
            result = true;
        }

        ListenerInfo li = mListenerInfo;
        if (li != null && li.mOnTouchListener != null
            && (mViewFlags & ENABLED_MASK) == ENABLED
            // 事件最先由 onTouch 方法处理
            && li.mOnTouchListener.onTouch(this, event)) {
            result = true;
        }
        // onTouch 方法没有处理成功，由自己的 onTouchEvent 方法处理
        if (!result && onTouchEvent(event)) {
            result = true;
        }
    }
    // 调试相关
    if (!result && mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onUnhandledEvent(event, 0);
    }

    // 非Move事件，停止滑动
    if (actionMasked == MotionEvent.ACTION_UP ||
        actionMasked == MotionEvent.ACTION_CANCEL ||
        (actionMasked == MotionEvent.ACTION_DOWN && !result)) {
        stopNestedScroll();
    }

    return result;
}
```

`View.dispatchTouchEvent`方法是相当简单的，它主要就做了两件事。

- 将事件首先交给的onTouch方法处理，OnTouchListener.onTouch 方法一般是由开发者在代码中自行实现，如果 onTouch 方法返回true，则表示事件被处理了，否则就表示事件未被处理。
- 如果事件没有被处理，事件接着会交给`View.onTouchEvent`方法处理，该方法返回 true，表示事件被处理了，否则事件未被处理

那让我们接着来看看`View.onTouchEvent`方法，这个方法和`ViewGroup.dispatchTouchEvent`方法可是事件分发中最重要的两个方法，并且它也是事件分发流程中的终点，所以这里就只关注主要的流程：

```java
public boolean onTouchEvent(MotionEvent event) {
    final float x = event.getX();
    final float y = event.getY();
    final int viewFlags = mViewFlags;
    final int action = event.getAction();
    // View是否可点击的标识
    final boolean clickable = ((viewFlags & CLICKABLE) == CLICKABLE
                               || (viewFlags & LONG_CLICKABLE) == LONG_CLICKABLE)
        || (viewFlags & CONTEXT_CLICKABLE) == CONTEXT_CLICKABLE;

    if ((viewFlags & ENABLED_MASK) == DISABLED) {
        if (action == MotionEvent.ACTION_UP && (mPrivateFlags & PFLAG_PRESSED) != 0) {
            setPressed(false);
        }
        mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
        // 此处的代码代表着被设置为不可用的View仍然会消费事件，只是在触摸事件到来时不去响应
        // 想要不可用的View不消费事件，还需要将View的clickable属性设置为false
        return clickable;
    }
    // 如果View设置了触摸代理，则会消费事件，并将事件交给触摸代理处理。
    // TouchDelegate的作用可以百度，这里就不详述。其主要是用于扩大View的实际可点击区域。
    if (mTouchDelegate != null) {
        if (mTouchDelegate.onTouchEvent(event)) {
            return true;
        }
    }
    // 如果View是可点击的，或者在长按情况下可以显示tooltip，事件就被消费，否则不会被消费
    if (clickable || (viewFlags & TOOLTIP) == TOOLTIP) {
        switch (action) {
                // Up事件
            case MotionEvent.ACTION_UP:
                mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                // 处理 tooltip 相关事项
                if ((viewFlags & TOOLTIP) == TOOLTIP) {
                    handleTooltipUp();
                }
                // 不可点击时设置状态，移除监听
                if (!clickable) {
                    removeTapCallback();
                    removeLongPressCallback();
                    mInContextButtonPress = false;
                    mHasPerformedLongPress = false;
                    mIgnoreNextUpEvent = false;
                    break;
                }
                boolean prepressed = (mPrivateFlags & PFLAG_PREPRESSED) != 0;
                if ((mPrivateFlags & PFLAG_PRESSED) != 0 || prepressed) {
                    // 处理按压的相关事项，比如View颜色的变化
                    boolean focusTaken = false;
                    if (isFocusable() && isFocusableInTouchMode() && !isFocused()) {
                        focusTaken = requestFocus();
                    }

                    if (prepressed) {
                        // 更改状态，保证用户能够感知到
                        setPressed(true, x, y);
                    }
                    // 此处 mHasPerformedLongPress 起作用了，如果长按事件没有执行，则会执行点击事件，否则不执行点击事件
                    if (!mHasPerformedLongPress && !mIgnoreNextUpEvent) {
                        // 移除长按事件监听
                        removeLongPressCallback();

                        if (!focusTaken) {
                            if (mPerformClick == null) {
                                // 此对象用于执行点击方法，会调用会对象的OnClickListener，执行onClick方法。
                                mPerformClick = new PerformClick();
                            }
                            if (!post(mPerformClick)) {
                                performClickInternal();
                            }
                        }
                    }

                    if (mUnsetPressedState == null) {
                        mUnsetPressedState = new UnsetPressedState();
                    }

                    if (prepressed) {
                        // 与handler结合使用
                        postDelayed(mUnsetPressedState,
                                    ViewConfiguration.getPressedStateDuration());
                    } else if (!post(mUnsetPressedState)) {
                        // 消息发送失败，立即进入非按压状态
                        mUnsetPressedState.run();
                    }

                    removeTapCallback();
                }
                mIgnoreNextUpEvent = false;
                break;
                // 按下事件
            case MotionEvent.ACTION_DOWN:
                if (event.getSource() == InputDevice.SOURCE_TOUCHSCREEN) {
                    mPrivateFlags3 |= PFLAG3_FINGER_DOWN;
                }
                // 长按事件是否已经执行的标识
                mHasPerformedLongPress = false;
                // 不可点击
                if (!clickable) {
                    // 长按事件相关
                    checkForLongClick(0, x, y);
                    break;
                }
                // 鼠标相关的处理，不关注
                if (performButtonActionOnTouchDown(event)) {
                    break;
                }

                // View是否在可滑动的视图内
                boolean isInScrollingContainer = isInScrollingContainer();

                // 在可滑动试图内，延迟发送消息，改变状态，否则立即改变状态
                if (isInScrollingContainer) {
                    mPrivateFlags |= PFLAG_PREPRESSED;
                    if (mPendingCheckForTap == null) {
                        mPendingCheckForTap = new CheckForTap();
                    }
                    mPendingCheckForTap.x = event.getX();
                    mPendingCheckForTap.y = event.getY();
                    postDelayed(mPendingCheckForTap, ViewConfiguration.getTapTimeout());
                } else {

                    setPressed(true, x, y);
                    // 检查长按事件，当长按事件条件满足时，会执行长按事件
                    checkForLongClick(0, x, y);
                }
                break;

            case MotionEvent.ACTION_CANCEL:
                if (clickable) {
                    setPressed(false);
                }
                removeTapCallback();
                removeLongPressCallback();
                mInContextButtonPress = false;
                mHasPerformedLongPress = false;
                mIgnoreNextUpEvent = false;
                mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                break;

            case MotionEvent.ACTION_MOVE:
                if (clickable) {
                    drawableHotspotChanged(x, y);
                }

                if (!pointInView(x, y, mTouchSlop)) {
                    // 超出了视图的范围，就移除点击和长按事件的监听检查
                    removeTapCallback();
                    removeLongPressCallback();
                    if ((mPrivateFlags & PFLAG_PRESSED) != 0) {
                        setPressed(false);
                    }
                    mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                }
                break;
        }

        return true;
    }

    return false;
}
```

由上面的代码，我们可以得出以下结论：

- 点击事件是在 Up 事件到来时执行，长按事件是在 Down 事件到来时执行
- 长按事件是有返回值，而点击事件没有返回值。并且长按事件是在Down事件中执行，点击事件是在Up事件中执行，如果同时满足两个条件，那么长按事件会先于点击事件执行，因为Down事件在Up事件前面。
我们来看看长按事件执行的代码：

```java
private final class CheckForLongPress implements Runnable {
    private int mOriginalWindowAttachCount;
    private float mX;
    private float mY;
    private boolean mOriginalPressedState;

    @Override
    public void run() {
        if ((mOriginalPressedState == isPressed()) && (mParent != null)
            && mOriginalWindowAttachCount == mWindowAttachCount) {
            // 如果长按事件返回值为true，就不执行点击事件了
            if (performLongClick(mX, mY)) {
                // 该变量在点击事件执行时会用上，为true则点击事件不执行
                mHasPerformedLongPress = true;
            }
        }
    }
}
```
- 长按事件执行后，如果返回值为true，点击事件就不会执行了。为false，点击事件和长按事件都会执行
- 时间处理的流程，OnTouchListener.onTouch ---> View.onTouchEvent ---> OnLongClickListener.onLongClick ---> OnClickListener.onClick 方法，前三个方法都有返回值，在返回 false 的情况下会继续向下分发事件，进行处理；否则会结束分发，返回 true。

### 实际应用

看完了分发流程，让我们来看看实际的问题解决。现在我有个实际布局如下：

![实际例子示意图](/imgs/实际例子示意图.webp)

说明：

- **红色的部分是一个RecyclerView，绿色的部分代表着每个不同的消息item**，比如语音消息、视频消息、文本消息，语音消息点击可播放，视频消息点击可跳转另一个播放界面。**蓝色是每种消息的具体部分，紫色是多选框**。该消息列表有多选模式可以选择，实现多选的相关功能，比如多选删除。**黄色部分代表着输入法的布局**，该部分是可以隐藏的。
- 现在有一个需求场景，要求实现以下功能：多选模式下，无论点击绿色item的哪个部分，都只改变紫色item的状态---选中或者未选中，输入法布局状态不会改变；而非多选模式下，点击蓝色部分，会触发相关动作，比如语音播放，视频跳转其他界面。点击绿色其他部分：若输入法布局被隐藏，则不响应；如果输入法布局正在显示，则需要隐藏输入法布局。蓝色和紫色部分是绿色部分的子布局。绿色布局是红色部分的子布局。红色部分和黄色部分是并列关系，即RecyclerView在输入法布局的上方。输入法布局隐藏时，RecyclerView全屏显示，否则两者共同占满屏幕。
- 已知的设置，以VoiceItem为例：蓝色部分设置了`View.OnClickListener`，绿色部分设置了`View.OnClickListener`，红色部分设置了`View.OnTouchListener`。
- 上述的需求场景是我在接触开发多选模式功能时的一个BUG：非多选模式下&输入法布局显示时，点击绿色的其他部分，输入法应该隐藏，但实际输入法布局却没有隐藏。很明显，就是事件分发的BUG。虽然有其他方法规避。但是重写事件分发方法是最简单的处理方式，我在改的时候也是这么想的。但是很不幸，我改了一天也没改出来，被导师改了。即使我看过事件分发的流程解析，也没有解决问题，网上的文章反而误导了我。所以我痛下决心，一定要好好看下源码，这才写了这篇文章、

言归正传，这个BUG要怎么改呢？首先，我们应该区分多选和非多选模式，这个好办，一个布尔型变量即可解决。其次，我们理清楚，在不同的模式下，谁响应点击事件。在多选模式下，应该是绿色部分响应点击事件。在非多选模式下，应该是红色部分、蓝色部分响应点击事件。

让我们继续捋捋，绿色部分是红色部分子布局，蓝色部分是绿色部分子布局，则蓝色部分是红色部分子布局。绿色部分要响应点击事件，事件就得从红色向下分发。蓝色部分要响应点击事件，事件就得从绿色向下分发。

现在我们得到了有用的信息。那让我们来看看未改正的有BUG的代码，绿色部分的布局代码(每个item的根布局)，设置了`View.OnClickListener`，`View.OnClickListener`执行后会返回 true，此处就不列举代码了。同时重写了拦截方法 onInterceptTouchEvent：

```java
public class CustomConstraintLayout extends ConstraintLayout {
    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        super.onInterceptTouchEvent(event);
        // 多选模式拦截事件，不向下分发，非多选模式向下分发
        // 即多选模式下，该变量为 true，非多选模式下为 false
        return mIsIntercept;
    }
}
```

而红色部分设置的代码如下：

```java
rv.setOnTouchListener(new View.OntouchListener{
    @Override
    public boolean onTouch(View v, MotionEvent event) {
        if(inputView.isVisible()) {
            inputView.setGone(true);
        }
        return true;
    }
});
```

而蓝色部分也设置了`View.OnClickListener`。

这样做实现了效果：非多选模式下，蓝色部分可以响应点击事件，多选模式下，绿色部分可以响应点击事件。但是问题来了，非多选模式下&输入法布局可见时，点击RecyclerView中非蓝色部分时，输入法应该隐藏，但实际却不会隐藏。为什么呢？

非多选模式下，点击绿色部分，事件会一直分发到绿色部分，而绿色部分设置了OnClickListener，它会消费掉事件。返回值为true，根据上面讲过的分发流程，消费掉事件后，父类便不会再进行处理。所以，父类的OnTouchListener此时没有效果，点击屏幕输入法布局不会隐藏。那如何才能让父类的OnTouchListener生效呢？答案便是非多选模式下，绿色部分的OnClickListener不应该生效。那怎么才能做到这种效果呢？让我们想想上面讲的onTouchEvent方法，onTouchEvent方法会调用OnClickListener和OnLongClickListener，消费掉事件，并返回true。这就是代表着事件被处理了。那么我们只要在非多选模式下，不处理事件（返回false），父类的OnTouch方法便可以执行了。所以重点是要重写 CustomConstraintLayout 的 onTouchEvent 方法，这也是官方在 onInterceptTouchEvent 的注释中特别强调的一点（重写 onInterceptTouchEvent 方法应该要同时重写 onTouchEvent 方法）。话不多说，上代码：

```java
public class CustomConstraintLayout extends ConstraintLayout {
    @Override
    public boolean onInTouchEvent(MotionEvent event) {
        if(mIsIntercept) {
            // 拦截模式下，复用父类的onTouchEvent，最终会调到自己的OnClickListener，返回结果即可
            return super.onTouchEvent(event);
        }
        // 非拦截模式下，不执行
        return false;
    }
}
```

经过这两步，BUG就算是修复了。让我们看看最终的代码：

```java
public class CustomConstraintLayout extends ConstraintLayout {
    @Override
    public boolean onInterceptTouchEvent(MotionEvent event) {
        // 多选模式拦截事件，不向下分发，非多选模式向下分发
        // 即多选模式下，该变量为 true，非多选模式下为 false
        return mIsIntercept;
    }
    @Override
    public boolean onInTouchEvent(MotionEvent event) {
        if(mIsIntercept) {
            // 拦截模式下，复用父类的onTouchEvent，最终会调到自己的OnClickListener，结果返回true，停止分发
            // 调用 super.onTouchEvent(event) 并不是说走父布局分发的流程，而是复用父类(View)的代码，事件的实际处理者还是当前View(即调用super.onTouchEvent方法相当于将ViewGroup当做View看待，相当于调用到自己的onTouchEvent方法(包括onTouchEvent方法, OnLongClickListener, OnClickListener，不包括OnTouchListener，此监听器在View的dispatchTouchEvent方法中起作用))
            return super.onTouchEvent(event);
        }
        // 非拦截模式下，不处理事件，父View没有找到合适的对象，会调用自身的onTouchEvent，自己处理事件，这就可以响应隐藏输入法的布局的要求了
        return false;
    }
}
```

综上，要写出上面的代码，需要明白以下几件事：

- 明白整体的业务流程
- 清楚各View设置的OnTouchListener、OnClickListener，以及onTouchEvent方法具体的实现如何
- 明白三种方法返回false、true、调用super.xxx方法分别代表的含义
- 理清楚事件分发的调用流程和值返回流程。就是网上到处都有的事件分发的流程图，此处就不列举了。

讲讲三种方法的含义吧，如图。

![Android事件分发方法描述](/imgs/Android事件分发方法描述.webp)

那么事件分发的基础就暂时讲到这里吧。后面如果有时间，我会把多指的触摸事件给好好讲讲。这部分需要重点研究 MotionEvent 类和 ScrollView 类。