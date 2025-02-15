---
title: "Android 鼠标外设适配方法摘要"
description: "本文讲解了如何为 Android 适配鼠标外设"
keywords: "Android,硬件适配,鼠标适配"

date: 2021-05-18T11:54:00+08:00

categories:
  - Android
  - 硬件适配
tags:
  - Android
  - 硬件适配
  - 鼠标适配

url: post/351E81B2851B431DB47A06AAEE586ED4.html
toc: true
---

本文讲解了如何为 Android 适配鼠标外设。

<!--More-->

## 说明

鼠标的适配，此处介绍两种适配方式(可能不全)。具体的适配需要请教相关人员，或者是拿到硬件设备一个个的调试。但是不管怎么，基本上还是走的事件的分发流程。或者`dispatchKeyEvent`，或者`dispatchTouchEvent`，前者代表按键事件`KeyEvent`的分发流程，后者代表`MotionEvent`的分发流程。两个事件都是`InputEvent`的子类，所以流程和方法等，都存在着极大的相似性。

通常，鼠标的使用是搭配界面来的，在 Android 中，界面就是 Activity。而监听鼠标的按键操作，是配合着事件分发来的。Activity 一路下发到 View。

通常，鼠标会有左、中、右三个键，但是因为左右键可以互相切换，所以鼠标的三个键通称为主键(Primary  Button)、二键(Secondary Button)、三键(Tertiary Button)。某些鼠标可能还有更多的键，如控制键、录音键等，这些键的判断方式可能需要自定义，视硬件的不同而改变，通常需要和硬件、系统开发等协商确定。

## 通用适配方案

### 判断事件来源

每个事件都有个事件源，标准的鼠标事件源是 `InputDevice.SOURCE_MOUSE`，可以通过 `InputEvent.isFromSource` 方法判断：

```java
// 方法：InputEvent.isFromSource。MotionEvent 继承自 InputEvent。
// 事件源是鼠标时，返回 true，否则返回 false。
motionEvent.isFromSource(InputDevice.SOURCE_MOUSE);
```

### 判断鼠标键按下抬起

上面讲过，鼠标通常会有左、中、右三个键，但是因为左右键可以互相切换，所以鼠标的三个键通称为主键(Primary Button)、二键(Secondary Button)、三键(Tertiary Button)。一般情况下，其键位对应情况是：主键 <---> 左键，二键 <---> 右键，三键 <---> 中键。在 Android 中，三个键对应的常量是：

- 主键：MotionEvent.BUTTON_PRIMARY
- 二键：MotionEvent.BUTTON_SECONDARY
- 三键：MotionEvent.BUTTON_TERTIARY

某些鼠标还有更多的键，如控制键、录音键等，这些键的判断方式可以使用系统的判断方式，也可能需要自定义，视硬件的不同而改变，通常需要和硬件、系统开发等协商确定。以系统的录音键为例，其按键常量为：

- 录音键：KeyEvent.KEYCODE_MEDIA_RECORD

要判断鼠标键被按下了，需要经过两步：

1. 判断是否有按键被按下或者抬起了
2. 判断被按下的键是鼠标的按键

针对第 1 点：我们知道在触摸事件中，ACTION_DOWN 标识了按下动作。而对于按钮，也对应者一个动作 ACTION_BUTTON_PRESS。而对于抬起动作，则对应了 ACTION_UP 和 ACTION_BUTTON_RELEASE，所以要判断是否有鼠标按钮被按下和抬起，我们可以使用以下的代码：

```java
// 事件 MotionEvent 从 Activity 或者 View 的 onTouchEvent 方法获取
public boolean onMouseEvent(MotionEvent motionEvent) {
    if(!motionEvent.isFromSource(InputDevice.SOURCE_MOUSE)) {
        // 事件不来自鼠标，不处理
        Log.d(TAG, "事件源不是鼠标");
        return false;
    }
    switch (motionEvent.getActionMasked()) {
        // 判断两个动作，基本上能保证准确
        case MotionEvent.ACTION_BUTTON_PRESS:
        case MotionEvent.ACTION_DOWN:
            // 鼠标按键按下
            judgeButtonPress(motionEvent);
            Log.d(TAG, "消费来自鼠标的事件");
            return true;
        case MotionEvent.ACTION_BUTTON_RELEASE:
        case MotionEvent.ACTION_UP:
            // 鼠标按键抬起
            judgeButtonRelease(motionEvent);
            Log.d(TAG, "消费来自鼠标的事件");
            return true;
    }
    return false;
}
```

针对第 2 点：MotionEvent 传递下来时，会有对应的所有 Button 的状态。通过 `MotionEvent.getButtonState()` 方法，可以得到所有的状态，特定的状态可以通过位运算得到。

但是注意，虽然我们能够通过判断 ACTION_BUTTON_RELEASE 来确定有抬起事件，但是我们并不知道是鼠标的哪个键被抬起了(`MotionEvent.getButtonState() 方法无法确定)，我们只能知道按键的按下状态。所以我们需要在按键被按下时，记录按键被按下了，以便后续判断抬起状态，抬起时重置变量。在一个鼠标的事件序列中，抬起动作应该总在按下动作之后。所以我们在按下时记录，在抬起时重置，是可行的。

下面是判断按键按下的方法：

```java
public void judgeButtonPress(MotionEvent motionEvent) {
    // 几个键可能同时被按下(概率较低)
    if (isButtonPress(motionEvent, MotionEvent.BUTTON_PRIMARY)) {
        // 主键被按下了，此处变量缓存，用于后面判断抬起
        isPrimaryPressed = true;
    }
    if (isButtonPress(motionEvent, MotionEvent.BUTTON_SECONDARY)) {
        // 二键被按下了
        isSecondPressed = true;
    }
    if (isButtonPress(motionEvent, MotionEvent.BUTTON_TERTIARY)) {
        // 三键被按下了
        isTertiaryPressed = true;
    }
}

/**
 * 判断是否按键被按下
 * 两种场景：
 * 1. 大于目标 SDK 版本，如果按下，则不管(1)；如果没按下，则需要用低版本的检测方法再检测一
 *    次，双重保险，不会出错。对于国内厂商的魔改系统，这是很重要的一点经验(2)
 * 2. 小于目标 SDK 版本，则用低版本的检测方法(3)
 * 综上，可以把 (2)、(3) 合为一种判断
 * */
public boolean isButtonPress(MotionEvent motionEvent, int button) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP
        && motionEvent.isButtonPressed(button)) {
        return true;
    }
    // 位运算，下面两种写法等效
    // 写法 1：(motionEvent.getButtonState() & MotionEvent.BUTTON_PRIMARY) != 0
    // 下面是写法 2，是 Google 官方采用的写法，详见 MotionEvent.isButtonPressed() 方法
    if (button == 0) {
        return false;
    }
    return (motionEvent.getButtonState() & button) == button;
}
```

上面的代码定义了用方法`isButtonPress`来判断鼠标按键的状态，true 表示按下，false 表示未按下。以主键为例，判断鼠标抬起的逻辑如下：

```java
private void judgeButtonRelease(MotionEvent motionEvent) {
    // 通过当前事件，判断鼠标键是否被按下
    boolean nowPrimaryPressState = 
        isButtonPress(motionEvent, MotionEvent.BUTTON_PRIMARY);
    // 鼠标可能同时被按下，也有可能同时被松开
    // 之前主键被按下了，这次事件，主键没按下。则表明主键松开了
    if(isPrimaryPressed && !nowPrimaryPressState) {
        // 重置变量
        isPrimaryPressed = false;
    }
}
```

### 判断抬起状态

在 Android 中，可以通过判断 MotionEvent.ACTION_BUTTON_RELEASE，来确定是不是鼠标的抬起动作，代码使用如下：

```java
public boolean onMouseEvent(MotionEvent motionEvent) {
    if(!motionEvent.isFromSource(InputDevice.SOURCE_MOUSE)) {
        // 事件不来自鼠标
        Log.d(TAG, "事件源不是鼠标");
        return false;
    }
    switch (motionEvent.getActionMasked()) {
        case MotionEvent.ACTION_BUTTON_RELEASE:
            // 按键抬起
            judgeButtonRelease(motionEvent);
            Log.d(TAG, "消费来自鼠标的事件");
            return true;
    }
    return false;
}
```

然后通过按下时记录的变量，进行对比，以判断是否有按键抬起：

```java
private void judgeButtonRelease(MotionEvent motionEvent) {
    // ACTION_BUTTON_RELEASE 事件，不会携带按键信息，只能通过按下的状态来判断。
    // 通过当前事件，判断鼠标键是否被按下
    boolean nowPrimaryPressState = isButtonPress(motionEvent, MotionEvent.BUTTON_PRIMARY);
    boolean nowSecondaryPressState = isButtonPress(motionEvent, MotionEvent.BUTTON_SECONDARY);
    // 鼠标可能同时被按下，也有可能同时被松开
    if(isPrimaryPressed && isSecondPressed && !nowPrimaryPressState && !nowSecondaryPressState) {
        // 之前两个键按下，现在两个键没按下(两个键的 Release)
        isPrimaryPressed = false;
        isSecondPressed = false;
    } else if(isPrimaryPressed && !nowPrimaryPressState) {
        // 之前主键按下，现在按键没按下(单个键的 Release)
        isPrimaryPressed = false;
        // Release 后，可以触发相关动作，此处省略
    } else if(isSecondPressed && !nowSecondaryPressState) {
        // 之前二键按下，现在二键没按下(单个键的 Release)
        isSecondPressed = false;
        // Release 后，可以触发相关动作，此处省略
    }
    // 三键的判断逻辑类似，此处省略
}
```

### 鼠标的移动

鼠标的移动，主要是通过鼠标的指针位置来判断的，下面的方法用来获取鼠标指针的位置：

```java
public boolean onMouseEvent(MotionEvent motionEvent) {
    if(!motionEvent.isFromSource(InputDevice.SOURCE_MOUSE)) {
        // 事件不来自鼠标
        Log.d(TAG, "事件源不是鼠标");
        return false;
    }
    switch (motionEvent.getActionMasked()) {
        case MotionEvent.ACTION_MOVE:
        case MotionEvent.ACTION_HOVER_MOVE:
            // 获取指针在屏幕上 X 轴的位置，值的单位是 dp
            float axisX = motionEvent.getAxisValue(MotionEvent.AXIS_X);
            // 获取指针在屏幕上 Y 轴的位置，值的单位是 dp
            float axisY = motionEvent.getAxisValue(MotionEvent.AXIS_Y);
            // 另一种写法：int x = (int)motionEvent.getRawX(); int y = (int)motionEvent.getRawY();
            Log.d(TAG, "消费来自鼠标的事件");
            return true;
    }
    return false;
}
```

### 鼠标的滚动

鼠标的滚动，采用以下方法判断

```java
public boolean onMouseEvent(MotionEvent motionEvent) {
    if(!motionEvent.isFromSource(InputDevice.SOURCE_MOUSE)) {
        // 事件不来自鼠标
        Log.d(TAG, "事件源不是鼠标");
        return false;
    }
    switch (motionEvent.getActionMasked()) {
        case MotionEvent.ACTION_SCROLL:
            // 一般的鼠标，这个用不上。获取水平方向上的滚动距离，值从 -1(向左滚动) 到 1(向右滚动)
            float hScroll = motionEvent.getAxisValue(MotionEvent.AXIS_HSCROLL);
            // 获取垂直方向上的滚动距离，值从 -1(向下滚动) 到 1(向上滚动)
            float vScroll = motionEvent.getAxisValue(MotionEvent.AXIS_VSCROLL);
            Log.d(TAG, "消费来自鼠标的事件");
            return true;
    }
    return false;
}
```

### 外设关注的方法

在事件分发流程中，要判断外设的事件，还有几个方法值得关注：

```java
public class TestView extends View {
    /**
     * 分发通用触摸事件
     */
    @Override
    public boolean dispatchGenericMotionEvent(MotionEvent event) {
        return handle;
    }
    /**
     * 分发按键事件
     */
    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        return handle;
    }
    /**
     * Android 8.0+ 支持鼠标捕获(鼠标的指针捕获)
     */
    @Override
    public boolean dispatchCapturedPointerEvent(MotionEvent event) {
        return handle;
    }
}
```

### 指针捕获

指针捕获就不讲了，可以参考以下两篇文章：

```java
// 参考链接：https://developer.android.com/training/gestures/movement#pointer-capture
// 参考链接：https://blog.csdn.net/yeshennet/article/details/105802579
```

### 注意点

1. 按键事件(KeyEvent)和触摸事件(MotionEvent)，可以同时存在，并不互斥。所以，项目中，针对鼠标的标准键和额外键。需要同时处理两个事件分发流程(dispatchKeyEvent，dispatchTouchEvent)，二者都是 Activity ---> ViewGroup ---> View 这样的顺序分发。为了防止异步带来的影响，处理时，二者最好处于同一线程，并定义好各种情况的处理逻辑。
2. KeyEvent 并没有 Cancel 事件，所以走 KeyEvent 的事件流是以 Up 动作作为事件流的结尾(我从我们公司的系统工程师那里了解到的)。这样会带来一个问题：可能某些异常场景兼容不了。举个例子，有个按住说话，松开发送的功能(类似于微信的语音消息录制)。如果你用一根手指按住屏幕说话，然后说话时按下第二根、第三根手指。那么在按到第三根手指时，系统会下发一个 Cancel 事件，结束事件流，此时，当前被录制的语音就会被取消掉，不会发送出去。但是，如果你使用了像话筒这样的外设，话筒有个录音键，录音键按下录音，松开发送。这个录音键走了 KeyEvent 的流程，那么无论什么场景，话筒录制的语音都会被发送出去。因为 KeyEvent 没有 Cancel 事件，只有 Up 事件，每个 KeyEvent 的事件流都是以 Up 事件结束的。而 Up 动作对应的是 松开录音键发送语音消息 这条规则。

------------------------------------------

------------------------------------------

------------------------------------------

------------------------------------------

------------------------------------------

## 实际适配逻辑

好了，以上是理论上适配鼠标的主要知识点。下面来讲讲实际的适配过程。

理想中的鼠标适配逻辑是很清晰的，但是实际上，鼠标的不同键，可能对应不同的功能。假如鼠标二键需要实现 Android 系统 back 键的功能，该怎么办呢？这种功能当然是由系统工程师和专门的硬件工程师去做啦。我们这些应用小开发，只能根据他们定的规则去适配。

但是如果鼠标二键真的实现了 Android 系统 back 键的功能。该怎么适配呢？我们需要根据以下的知识点来适配：

1. back 键下发，走的是 KeyEvent 的流程
2. back 键的键值是`KeyEvent.KEYCODE_BACK`
3. 鼠标键的按下、抬起状态，在 keyEvent 中，对应的是`KeyEvent.ACTION_DOWN`/`KeyEvent.ACTION_UP`
4. `KeyEvent.ACTION_DOWN`/`KeyEvent.ACTION_UP`对应 Activity 的`onKeyDown`/`onKeyUp`方法

下面是部分代码：

```java
// 自定义的 Activity 类中
// 此方法的参数，向下传递时，可剔除 keyCode，少传一个参数
// keyCode 可以使用 event.getKeyCode() == keyCode 判断
public boolean onKeyDown(int keyCode, KeyEvent event) {
    // DOWN 和 UP 聚合起来，统一处理
    if(handleKeyEvent(event)) {
        // 被处理了
        return true;
    }
    return super.onKeyDown(keyCode, event);
}
@Override
public boolean onKeyUp(int keyCode, KeyEvent event) {
    if(handleKeyEvent(event)) {
        // 被处理了
        return true;
    }
    return super.onKeyUp(keyCode, event);
}
/**
 * true 表示处理事件，false 表示不处理事件
 * */
boolean handleKeyEvent(KeyEvent keyEvent) {
    if(keyEvent.getKeyCode() != KeyEvent.KEYCODE_BACK) {
        return false;
    }
    if(keyEvent.getAction() == KeyEvent.ACTION_DOWN) {
        // 按键按下
        return onButtonPress(keyEvent);
    } else if (keyEvent.getAction() == KeyEvent.ACTION_UP) {
        // 按键抬起
        return onButtonRelease(keyEvent);
    }

    return false;
}
```

### 注意点

- 对于 home 键的事件，我们无法做到拦截，只能通过生命周期或者 home 键的广播处理一些需要在 home 键触发时处理的业务流程
- 对于 back 事件，我们可以拦截，只需要在 KeyEvent 下发时消费掉事件即可

上面的适配逻辑只是一种思路，具体的场景，具体的问题，具体处理。