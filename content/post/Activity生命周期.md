---
title: "Activity生命周期"
description: "本文略讲了 Android Activity 的生命周期"
keywords: "Android,生命周期"

date: 2020-01-08T21:08:00+08:00

categories:
  - Android
tags:
  - Activity
  - Android
  - 生命周期

url: post/E0FC4A10C8594482A74088A7611FD436.html
toc: true
---

本文略讲了 Android Activity 的生命周期

<!--More-->

本篇博客是个备忘录，是我工作中遇到的生命周期方法调用的一些总结。

讲Activity的声明周期之前，先讲讲Actiivty的启动模式。其与Activity的声明周期和启动流程息息相关。

## 四大启动模式

### 1、Standard 模式

默认启动模式，每次启动一个activity都会重新创建一个新的实例，放入栈顶。因此启动时`onCreate、onStart、onResume`方法都会被调用。

```java
// 伪代码
// 标准模式：走onCreate ---> onStart ---> onResume
if(isStandard) {
    // 创建新的Activity实例
    createNewActivity();
}
```

### 2、singleTop模式

singleTop模式，又叫栈顶复用模式，当前栈中已有该activity实例并且该实例位于栈顶，复用该activity，调用onNewIntent，onResume方法；其他都是重新创建实例。走`onCreate、onStart、onResume`流程。

```java
// 伪代码
if(isStackTop) {
    // 已存在实例并且在任务栈栈顶，复用当前实例，走 onNewIntent ---> onResume
    reuseExistActivity();
} else {
    // 创建新的Activity实例，走onCreate ---> onStart ---> onResume
    createNewActivity();
}
```

### 3、singleTask模式

singleTask模式，又叫栈内单例模式。该模式根据`AndroidManifest`中activity的`taskAffinity`属性去寻找当前是否存在一个对应名字的任务栈，如果任务栈存在，并且有目标Activity的实例在栈中，则会复用该实例，走`onNewIntent、onRestart、onStart、onResume`方法，否则便会创建新的实例，如果任务栈不存在，还会创建新的任务栈。

```java
// 伪代码
Stack stack = getStackByTaskAffinity(taskAffinity);
if(stack != null && isTargetActivityInStack) {
    // 任务栈存在，并且Activity有实例在任务栈中，则复用该实例
	// 走onNewIntent ---> onRestart ---> onStart ---> onResume
    reuseExistActivity();
} else {
    if(stack == null) {
        // 创造任务栈
        createStack();
    }
    createNewActivity();
}
```

### 4、singleInstance模式

singleInstance模式，又叫堆内单例模式。该模式下系统只有一个实例，且实例独享一个task任务栈。即整个系统中就这么一个实例。如果实例不存在，则会创建一个新的实例，并单独放入一个栈中，如果实例已经存在，则会复用该实例。

```java
// 伪代码
if(isInstanceExist) {
    // 复用当前实例
    reuseExistActivity();
} else {
    // 创建新的实例
	createNewActivity();
}
```

### 启动模式总结

从栈操作的角度来看，standard模式不会考虑任务栈，而singleTop模式会考虑栈顶，singleTask会考虑整个栈，寻找实例时存在遍历，而singleInstance会考虑多个栈，存在遍历行为。从耗时的角度来讲：standard <= singleTop <= singleTask <= singleInstance。singleInstance 模式创建实例有可能是最耗时的一个，因为他可能会遍历所有任务栈，做的事是最多的（在不考虑其他创建操作的情况下（比如栈的创建，standard每次都会创建一个stack））。

如何记忆这4种模式呢？配合下面这张图，并结合名字的长度：名字的长度越长，模式越复杂，做的事越多。

![4种启动模式图解](/imgs/4种启动模式图解.webp)

## 生命周期方法

Activity的声明周期与启动流程中，涉及到的方法如下：`onCreate、onStart、onResume、onPause、onStop、onDestroy、onRestart、onNewIntent、onSaveInstanceState、onRestoreInstanceState`，当然没有写完全，但是大部分情况下，我们都只用的到这些方法。

下面是一张很经典的声明周期图：

![Android基本生命周期](/imgs/Android基本生命周期.png)

此处建议：看的再多也不如实际的敲下代码。可以实现各个生命周期方法打印日志，也可以实现其他形式的流程呈现方式。此处采用监听回调的方法：

```java
public class LifecycleApplication extends Application {
    public LifecycleApplication() {
        init();
    }

    private void init() {
        // 监听生命周期回调
        registerActivityLifecycleCallbacks(new ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
                Log.d(activity.getClass().getSimpleName(), "onCreate");
            }

            @Override
            public void onActivityStarted(Activity activity) {
                Log.d(activity.getClass().getSimpleName(), "onStart");
            }

            @Override
            public void onActivityResumed(Activity activity) {
                Log.d(activity.getClass().getSimpleName(), "onResume");
            }

            @Override
            public void onActivityPaused(Activity activity) {
                Log.d(activity.getClass().getSimpleName(), "onPause");
            }

            @Override
            public void onActivityStopped(Activity activity) {
                Log.d(activity.getClass().getSimpleName(), "onStop");
            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
                Log.d(activity.getClass().getSimpleName(), "onSaveInstanceState");
            }

            @Override
            public void onActivityDestroyed(Activity activity) {
                Log.d(activity.getClass().getSimpleName(), "onDestroy");
            }
        });
    }
}
```

## 场景详解

### `Activity`之间的跳转

现在有A、B两个`Activity`，当从A进入B时，执行的生命周期如下：

```java
// A进入B
// A.onPause ---> B.onCreate ---> B.onStart ---> B.onResume ---> A.onStop
```

所以在`onPause`方法中，不能执行耗时操作，因为它会影响到进入下个界面的速度。当从B返回A时，执行的生命周期方法如下：

```java
// B返回A
// B.onPause ---> A.onRestart ---> A.onStart ---> A.onResume ---> B.onStop ---> B.onDestroy
```

对于哪些生命周期方法做哪些事，官方给了以下几条建议：

- 不要在`onPause`方法中执行耗时操作，不要在`onDestroy`中执行持久化操作。当系统内存不足时，会杀死APP，此时生命周期方法只会走到`onStop`，并不会走`onDestroy`。如果在`onDestroy`中进行持久化操作(如数据库、文件存储等)，可能会导致操作失败或者未进行操作。当然，在`onDestroy`中执行资源的释放等操作是可行的。
- 在`onResume`和`onPause`方法中进行动画和部分资源申请(这些资源需要获取到焦点)，如传感器资源(例如相机硬件资源)的申请和释放。
- 初始化操作放在`onCreate`中进行，但是应该注意到部分需要重复初始化的操作需要放在`onStart`中进行，比如`Bundle`的数据恢复。因为`onCreate`在生命周期中只会被调用一次，而`onStart`却可以被多次调用。

### 点击`home`键或者`menu`键

当用户点击`home`键或者`menu`键时，会退出当前`Activity`，生命周期方法会调用到`onStop`，不会调用`onDestroy`。

### 弹出Dialog

一般情况下，`Dialog`是作为一种非全屏性质的视图`View`使用，当从`Activity`上弹出的时候，会部分遮挡`Activity`，此时，`Activity`经历的生命周期和一般情况是有点差异的。下面，让我们来细细说明一下，先上代码。

```java
// 按钮实现了一个点击事件
btn1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Dialog dialog = new AlertDialog.Builder(MainActivity.this)
                    .setTitle("温馨提示")
                    .setMessage("点击设置权限")
                    .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            // 确认按钮时会申请权限，申请到权限后会进入下一个界面（以下称为B）
                            ActivityCompat.requestPermissions(MainActivity.this,
                                new String[] {Manifest.permission.READ_EXTERNAL_STORAGE}, 111);
                            dialog.dismiss();
                        }
                    })
                    .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            // 取消按钮啥也不干
                            dialog.dismiss();
                        }
                    })
                    .setNeutralButton("中立", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            // 中立按钮啥也不干
                            dialog.dismiss();
                        }
                    }).create();
                dialog.setCancelable(false);
                dialog.setCanceledOnTouchOutside(false);
                dialog.show();
            }
        });
```

**点击中立、取消按钮**

编译上面的代码，分别点击中立、取消两个按钮，此时`Dialog`从弹出到隐藏的过程并不会改变`Activity`的生命周期，也就是说，`Activity`并不会调用`onPause`方法。

**点击确定按钮**

当点击确认按钮时，`Dialog`从弹出到隐藏的过程中，`Activity`经历的生命周期如下：

```java
// Activity.onPause ---> Activity.onResume ---> Activity.onPause ---> B.onCreate ---> B.onStart ---> B.onResume ---> Activity.onStop ---> Activity.onSaveInstanceState
```

如上，`Activity`会先调用`onPause`，进入暂停状态，然后调用`onResume`恢复正常，再开始准备进入下个界面。注意`Activity`在点击了确认按钮后就调用了`onPause`方法，进入了暂停状态。不管我们是否授予权限。

**思考**

- 在上面的讨论，我们明确了三种按钮点击时的`Activity`的生命周期方法调用情况。接下来我们做点改动，将点击确认按钮后的处理代码，移到点击取消按钮后。确认按钮仅仅执行一个`dialog.dismiss()`即可。那么效果会是怎么样的呢？此时，你会有一个惊奇的发现，点击确认按钮，`Activity`竟然没有执行`onPause`方法，什么反应也没有，而点击取消按钮才执行`onPause`。同理，将代码移到点击中立按钮后,只有点击中立按钮才会执行`onPause`方法。
- 在上面的基础上，让我们再做做实验，现在我在三个按钮的点击响应中打印下日志，看是否结果是否和上面的一致：

```java
dialog.setPositiveButton("确定", new DialogInterface.OnClickListener() {
    @Override
    public void onClick(DialogInterface dialog, int which) {
        Log.d(TAG, "点击了确认按钮");
        ActivityCompat.requestPermissions(MainActivity.this,
            new String[] {Manifest.permission.READ_EXTERNAL_STORAGE}, 111);
        dialog.dismiss();
    }
})
    .setNegativeButton("取消", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialog, int which) {
            Log.d(TAG, "点击了取消按钮");
            dialog.dismiss();
        }
    })
    .setNeutralButton("中立", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialog, int which) {
            Log.d(TAG, "点击了中立按钮");
            dialog.dismiss();
        }
    })
```

经过测试，结果和上一点的结果一致。接着，我们再进行一点测试，再中立按钮的点击中加入Toast的显示：

```java
.setNeutralButton("中立", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialog, int which) {
            Log.d(TAG, "点击了中立按钮");
            Toast.makeText(MainActivity.this, "中立按钮被点击了", Toast.LENGTH_SHORT).show()
            dialog.dismiss();
        }
    })
```

结果仍然和上面一致。

- 经过上面的几次实验，我发现几个有趣的东西：
   - `Dialog`的`show`和`dismiss`方法不会改变`Activity`的生命周期
   - `Toast`也不会改变`Activity`的生命周期
   - 此外，我还尝试了透明主题的`Activity`，`Activity`只会调用`onPause`方法，并不会执行`onStop`和`onSaveInstanceState`方法。这也是需要注意的。

更多的非全屏的视图组件的效果，还需要尝试。这里就讲这些吧。当然，此处的生命周期，我只能保证系统原生`Dialog`的调用情况是这样，并不能保证自定义`Dialog`的调用情况是这样。

生命周期东西，在理解了四大启动启动模式的基础上，还是得结合实际情况具体分析。本篇没有分析多个Activity之间跳转，且启动模式不同的情况。加上这个情况就很复杂了。一句话，具体情况具体分析。下面，让我们看看另外一种案例：动画的展示，会不会影响到`Activity`的生命周期。

先上代码，具体的操作仍然是显示`Dialog`弹框，点击确认按钮时，显示1S的动画：

```java
btn2 = findViewById(R.id.btn2);
btn1.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View v) {
        Dialog dialog = new AlertDialog.Builder(MainActivity.this)
            .setTitle("温馨提示")
            .setMessage("点击显示1S动画")
            .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    // 点击确认按钮后显示一秒的动画
                    Log.d(TAG, "点击了确认按钮");
                    Animation rotateAnimation = new RotateAnimation(0, 270);
                    rotateAnimation.setDuration(1000);
                    btn1.setVisibility(View.INVISIBLE);
                    btn2.startAnimation(rotateAnimation); 
                    dialog.dismiss();
                }
            })
            .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    Log.d(TAG, "点击了取消按钮");
                    dialog.dismiss();
                }
            }).create();
        dialog.setCancelable(false);
        dialog.setCanceledOnTouchOutside(false);
        dialog.show();
    }
});
```

`btn2`的`XML`布局如下：

```xml
<!-- 是个居中显示的Button -->
<Button
        android:id="@+id/btn2"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="动画按钮"
        android:textSize="@dimen/dimen_24sp"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintBottom_toBottomOf="parent"/>
```

经过测试，发现，开始播放动画，并不会改变`Activity`的生命周期，因为动画的视图组件是声明在当前的`Activity`内的。
