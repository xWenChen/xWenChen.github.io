---
title: "Android防劫持-界面覆盖检测"
description: "本文记录了在 Android 如何检测当前界面被覆盖"
keywords: "Android,界面覆盖检测"
weight: 1

date: 2021-05-12 10:02:00 +08:00
lastmod: 2021-05-12 10:02:00 +08:00

categories:
  - Android
tags:
  - Android
  - 界面覆盖检测

url: post/94721E25B5C14B1191088BF2A553F33E.html
toc: true
---

本文记录了在 Android 如何检测当前界面被覆盖。

<!--More-->

## 说明

Android 的防劫持是门大学问。涉及到众多高深的知识。本文不会阐述这些。本文只是会讨论其中的一个小部分---**如何检测界面被覆盖，或者说如何检测用户离开了应用。**

## 功能目的

最近需要实现一个功能：当用户退出 APP 时，如果用户处于某些特定的界面(比如登录、注册、修改密码界面)，需要提示用户退出了应用。以满足合规要求。实现效果可以参考"建设银行 APP"。做这个功能主要是为了满足以下两个目的：

- 满足合规要求
- 增强应用安全性

经过几天的预研，也算是搞懂了一些东西。话不多说，开讲。

## 知识讲解

首先，我们需要知道以下几个概念：

- Activity 生命周期：完整的生命周期过程就不讲了，网上一大堆资料。这里就提几个场景：用户按 Home 键退出当前 APP 或者点击了 menu 键，Activity 生命周期会走到 onStop。
- Activity 栈：通常情况下，处于 Activity 栈栈顶的 Activity，才能跟用户交互。这里我把它叫做交互界面。注意前台界面和交互界面的区别，前台界面是可见的，但并不一定是可以和用户交互的
- 不透明 Activity 和透明 Activity：假设 Activity A 被 Activity B 覆盖，那么会出现两种情况：B 透明，B 不透明。具体说明看下面的图。

### 说明

假设当前在 APP 1 的 A 界面，进入了 APP 2 的 B 界面，那么相应的生命周期为：

- 如果 B 界面是非透明的。那么 A 界面的生命周期函数会走到 onStop
- 如果 B 界面是透明的。那么 A 界面的生命周期函数会走到 onPause

下面几张图片是关于生命周期的说明：

1. 单个生命周期示意图

![单个生命周期示意图](/imgs/单个生命周期示意图.png)

2. A 进入 B 时的生命周期

- 当 B 不透明时

![页面切换生命周期1](/imgs/页面切换生命周期1.png)

- 当 B 透明时

![页面切换生命周期2](/imgs/页面切换生命周期2.png)

## 代码预设

既然我们已经知道了启动透明界面和非透明界面(2 种界面)的不同，那么就需要针对性的做些设计了。而又因为需要检测其它 APP，所以需要设计多个 APP (2 个)及多个对应的界面(2 * 2 = 4 个界面)。

下面是设计的两个 APP。

## ------------------------ APP 1 设计开始 -------------------------

新建 1 个项目，我把他起名叫 ThisApp，意思是当前需要检测界面覆盖的 APP。这个 APP 代表着实际工作中我们需要维护的 APP。

### 生命周期变化监听

自定义 Application，在初始化时注册生命周期变化监听：

```java
/**
 * LifeCycleApplication: 监听生命周期变化的 Application
 * */
public class ThisLCApplication extends Application {
    private static final String TAG = "ThisLCApplication";
    
    private ActivityLifecycleCallbacks callback = new ActivityLifecycleCallbacks() {
        @Override
        public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
            Log.d(TAG, "  onActivityCreated           ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivityStarted(@NonNull Activity activity) {
            Log.d(TAG, "  onActivityStarted           ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivityResumed(@NonNull Activity activity) {
            Log.d(TAG, "  onActivityResumed           ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivityPaused(@NonNull Activity activity) {
            Log.d(TAG, "  onActivityPaused            ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivityStopped(@NonNull Activity activity) {
            Log.d(TAG, "  onActivityStopped           ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {
            Log.d(TAG, "  onActivitySaveInstanceState ---> " + activity.getClass().getSimpleName());
        }

        @Override
        public void onActivityDestroyed(@NonNull Activity activity) {
            Log.d(TAG, "  onActivityDestroyed         ---> " + activity.getClass().getSimpleName());
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();

        registerActivityLifecycleCallbacks(callback);
    }
}
```

在清单文件 AndroidManifest.xml 中使用 ThisLCApplication：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.wellcherish.thisapp">
    <application
        android:name=".ThisLCApplication"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 设计 MainActivity

首先设计主界面 MainActivity。包含几个按钮：

![设计MainActivity](/imgs/设计MainActivity.jpg)

xml 代码如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".MainActivity">

    <!-- 第 1 个 Button -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_020"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.20" />
    <Button
        android:id="@+id/btn_1"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="启动本 APP 的非透明界面"
        android:textColor="@android:color/white"
        android:textSize="20sp"
        android:background="@color/colorAccent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintBottom_toTopOf="@id/gl_020"
        android:onClick="startThisOpaqueActivity" />
	
    <!-- 第 2 个 Button -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_040"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.40" />
    <Button
        android:id="@+id/btn_2"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="启动本 APP 的透明界面"
        android:textColor="@android:color/white"
        android:textSize="20sp"
        android:background="@color/colorPrimary"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintBottom_toTopOf="@id/gl_040"/>
    
	<!-- 第 3 个 Button -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_060"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.60" />
    <Button
        android:id="@+id/btn_3"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="启动其他 APP 的非透明界面"
        android:textColor="@android:color/white"
        android:textSize="20sp"
        android:background="@android:color/holo_green_light"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintBottom_toTopOf="@id/gl_060"
        android:onClick="startOtherOpaqueActivity"/>
    
	<!-- 第 4 个 Button -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_080"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.80" />
    <Button
        android:id="@+id/btn_4"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="启动其他 APP 的透明界面"
        android:textColor="@android:color/white"
        android:textSize="20sp"
        android:background="@android:color/holo_orange_light"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintBottom_toTopOf="@id/gl_080"
        android:onClick="startOtherTransparentActivity"/>
</androidx.constraintlayout.widget.ConstraintLayout>
```

上面的几个点击方法实现如下：

```java
public void startThisOpaqueActivity(View view) {
    Intent i = new Intent(MainActivity.this, ThisOpaqueActivity.class);
    startActivity(i);
}

public void startThisTransparentActivity(View view) {
    Intent i = new Intent(MainActivity.this, ThisTransparentActivity.class);
    startActivity(i);
}

public void startOtherOpaqueActivity(View view) {
    Intent i = new Intent();
    i.setComponent(new ComponentName("com.wellcherish.otherapp", 
        "com.wellcherish.otherapp.OtherOpaqueActivity"));
    startActivity(i);
}

public void startOtherTransparentActivity(View view) {
    Intent i = new Intent();
    i.setComponent(new ComponentName("com.wellcherish.otherapp", 
        "com.wellcherish.otherapp.OtherTransparentActivity"));
    startActivity(i);
}
```

### 设计 ThisApp 的 ThisOpaqueActivity

ThisApp 的非透明界面(ThisOpaqueActivity)显示内容如下：

![ThisOpaqueActivity](/imgs/ThisOpaqueActivity.jpg)

XML 代码如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".ThisOpaqueActivity">

    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_020"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.20"/>

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="本 APP 的非透明界面"
        android:textSize="30sp"
        android:textColor="@android:color/holo_purple"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toBottomOf="@id/gl_020"/>

</androidx.constraintlayout.widget.ConstraintLayout>
```

### 设计 ThisApp 的 ThisTransparentActivity

ThisApp 的透明界面(ThisTransparentActivity)显示内容如下：

![ThisTransparentActivity](/imgs/ThisTransparentActivity.jpg)

xml 代码如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".ThisTransparentActivity">

    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/gl_025"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        app:layout_constraintGuide_percent="0.25"/>

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="5dp"
        android:text="本 APP 的透明界面"
        android:textSize="30sp"
        android:textColor="#BD4ED2"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toBottomOf="@id/gl_025"/>
</androidx.constraintlayout.widget.ConstraintLayout>
```

然后自定义透明主题，并在 AndroidManifest 中为 Activity 设置：

```xml
<style name="translucent" parent="Theme.AppCompat.NoActionBar">
    <!-- 设置背景透明度及其颜色值 -->
    <item name="android:windowBackground">#0000</item>
    <!-- 设置当前Activity是否透明-->
    <item name="android:windowIsTranslucent">true</item>
    <!-- 设置当前Activity进出方式-->
    <item name="android:windowAnimationStyle">@android:style/Animation.Translucent</item>
</style>

<!-- 在 AndroidManifest 中设置主题 -->
<activity android:name=".ThisTransparentActivity"
    android:theme="@style/translucent" />
```

## ------------------------ APP 1 设计结束 -------------------------

## ------------------------ APP 2 设计开始 -------------------------

新建 2 个项目，我把他起名叫 OtherApp，意思是需要覆盖当前 APP 的其它 APP。这个 APP 可以理解成实际使用中的恶意 APP。这个 APP 我们只需要模拟两个界面即可。

### 生命周期变化监听

自定义 Application，在初始化时注册生命周期变化监听，代码和 ThisApp 的完全一样，只是改了下 TAG，就不放代码了。

### 设计 OtherApp 的 OtherOpaqueActivity

OtherApp 的非透明界面(OtherOpaqueActivity)显示内容如下：

![OtherOpaqueActivity](/imgs/OtherOpaqueActivity.jpg)

XML 代码就不放了，和 ThisApp 的 ThisOpaqueActivity 布局完全相同，只是改了下 TextView 的文案，文案从图中可以知晓。

### 设计 OtherApp 的 OtherTransparentActivity

OtherApp 的透明界面(OtherTransparentActivity)显示内容如下：

![OtherTransparentActivity](/imgs/OtherTransparentActivity.jpg)

xml 代码和主题代码就不放了，和 ThisApp 的 ThisTransparentActivity 布局完全相同，只是改了下 TextView 的文案，文案从图中可以知晓。而 xml 中也只多了一个允许其他应用访问的设置。

```xml
<!-- OtherApp 需要设置 exported 项为 true -->
<activity android:name=".OtherOpaqueActivity"
    android:exported="true"/>
<activity android:name=".OtherTransparentActivity"
    android:theme="@style/translucent"
    android:exported="true"/>
```

## ------------------------ APP 2 设计结束 -------------------------

## 方案验证

在设计好了 APP 之后，就可以做方案验证了。根据网上现有的资料，我总结了界面覆盖检测有以下几种方法：

![界面覆盖检测方案总结](/imgs/界面覆盖检测方案总结.png)

这些方案我一个个说明。

### 栈顶 Activity 检测方案

在 Android 中，与用户交互的界面，一定是处于任务栈的栈顶。所以可以使用这个方案来检测栈顶 Activity，判断页面是否被其他 APP 的界面覆盖。方案主要是在生命周期变化时(启动其他界面时，当前栈顶的 Activity 的生命周期状态一定会改变)，检测栈顶 Activity 是否属于当前 APP，进而判断出当前 APP 是否被其他应用覆盖。但是**鉴于启动透明界面和非透明界面时存在着不同的生命周期流程，所以需要验证不同的生命周期流程是否会影响到上述检测方案的准确性**。

先上方案的核心实现代码：

```java
public static boolean checkByTopActivity(Activity activity) {
    ActivityManager activityManager = (ActivityManager) activity
        .getSystemService(Context.ACTIVITY_SERVICE);

    try {
        ComponentName cn = activityManager.getRunningTasks(1).get(0).topActivity;
        // 不相等，说明被覆盖了
        return !activity.getPackageName().equals(cn.getPackageName());
    } catch (Exception e) {
        Log.e(TAG, "", e);
        return false;
    }
}
```

将该检测方法放到自定义 Application 的生命周期监听的 onStop 中，则可以检测 APP 是否在前台了。

但是如果你直接在 Android Studio 中使用上述的代码，Android Studio 会给出提示，如下。这说明了该方案存在高低版本兼容问题。

![栈顶Activity检测方案高低版本兼容问题](/imgs/栈顶Activity检测方案高低版本兼容问题.jpg)

**经过验证，生命周期的确会影响到检测的准确性**。假设是从 A 界面进入 B 界面。

- 当 B 是透明 Activity 时，A 的生命周期会走到 onPause，此时栈顶 Activity 仍然是 A。这就意味着**栈顶 Activity 检测方案**失效了。
- 当 B 是非透明 Activity 时，A 的生命周期会走到 onStop，此时栈顶 Activity 变成了非 A。**栈顶 Activity 检测方案**生效。

### 应用重要性检测方案

在 Android 中，每一个应用都有一个优先级，进程的优先级分类有：前台进程、可见进程、服务进程、后台进程、空进程。可以通过这个标识来判断进程是否在前台，进而判断是否退出了应用，或者应用是否被其他 App 覆盖。

核心代码如下：

```java
public static boolean checkByProcessImportance(Activity activity) {
    ActivityManager activityManager = (ActivityManager) activity
        .getSystemService(Context.ACTIVITY_SERVICE);
    try {
        List<ActivityManager.RunningAppProcessInfo> appProcesses = activityManager
            .getRunningAppProcesses();
        for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
            // 非当前 APP
            if(!appProcess.processName.equals(activity.getPackageName())) {
                continue;
            }
            /**
             * 前台进程：100
             * 可见进程：200
             * 服务进程：300
             * 后台进程：400
             * 空进程：  500
             */
            return appProcess.importance != ActivityManager
                .RunningAppProcessInfo.IMPORTANCE_FOREGROUND;
        }
        return false;
    } catch (Exception e) {
        Log.e(TAG, "", e);
        return false;
    }
}
```

经过验证，该方案也无法检测透明界面的覆盖情况

### 应用使用记录检测方案与辅助服务检测前台应用

上述两种常见的方案都存在失效的场景的情况，我也一筹莫展。但是经过一段时间的探索后，我发现我装的一个叫做 "当前 Activity" 的应用，可以检测出半透明界面。一道曙光乍现，我将这个 APK 反编译了出来。经过一番探索之后，我发现了 "UsageStatsManager" 这个类，上网一搜，发现这个类是和 "应用使用记录统计" 这个功能强关联的。关于这个类的使用，可以看下这几篇文章：[Android 5.0 应用使用情况统计信息](https://blog.csdn.net/LoveDou0816/article/details/77983400)、[（Android 9.0）应用使用数据统计服务——UsageStatsManager](https://www.jianshu.com/p/3b6bcf9cec67)、[4种获取前台应用的方法（肯定有你不知道的）](https://www.jianshu.com/p/a513accd40cd)。这几个文章里讲的就比较清楚了，这里就不重复叙述了。直接上代码。

#### 1. 在 AndroidManifest.xml 中声明权限。

```xml
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
```

#### 2. 核心代码

```java
public static boolean checkByUsage(Activity activity) {
    if(!checkPermission(activity)) {
        try {
            activity.startActivity(new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    UsageStatsManager statsManager = (UsageStatsManager) activity
        .getSystemService(Context.USAGE_STATS_SERVICE);
    long endTime = System.currentTimeMillis();
    List<UsageStats> usageStatsList = statsManager
        .queryUsageStats(UsageStatsManager.INTERVAL_DAILY, endTime - 1000*10, endTime);
    if(usageStatsList == null || usageStatsList.size() <= 0) {
        return false;
    }
    return !usageStatsList.get(0).getPackageName().equals(activity.getPackageName());
}

public static boolean checkPermission(Activity activity) {
    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.LOLLIPOP) {
        return false;
    }
    AppOpsManager appOpsManager = (AppOpsManager) activity
        .getSystemService(Context.APP_OPS_SERVICE);

    int mode;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        mode = appOpsManager.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(), activity.getPackageName());
    } else {
        mode = appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(), activity.getPackageName());
    }
    return mode == AppOpsManager.MODE_ALLOWED;
}
```

#### 辅助服务获取前台应用

上面的第三篇文章链接中，有指出可以与使用应用使用记录统计达到相同目的的一个功能，就是 辅助服务获取前台应用，这个辅助服务，是无障碍的相关功能。而 "当前 Activity" 这个 APK，在使用时，需要申请辅助服务的相关权限。这也就是说，"当前 Activity" 这个 APK 就是使用的这种方式检测的前台应用。

辅助服务获取前台应用的使用步骤如下：

首先定义辅助服务。

```java
public class AccessibilityMonitorService extends AccessibilityService {
    private CharSequence mWindowClassName;
    private String mCurrentPackage;
    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        int type=event.getEventType();
        switch (type){
            // 核心代码
            case AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED:
                mWindowClassName = event.getClassName();
                mCurrentPackage = event.getPackageName()==null ? "" : event.getPackageName().toString();
                break;
            default:
                break;
        }
    }
}
```

然后在 AndroidManifest 清单文件中申明服务。

```xml
<service
    android:name=".service.AccessibilityMonitorService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    >
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>

    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility" />
</service>
```

然后在 res/xml/ 文件夹下新建文件 accessibility.xml，内容如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagRetrieveInteractiveWindows"
    android:canRetrieveWindowContent="true"
    android:canRequestFilterKeyEvents ="true"
    android:notificationTimeout="10"
    android:packageNames="@null"
    android:description="@string/accessibility_des"
    android:settingsActivity="com.pl.recent.MainActivity"
/>
```

关键是 typeWindowStateChanged 这个事件的声明。

这样就可以检测前台应用的改变，并获取前台应用的包名了。

总结一下：**应用使用情况统计 和 辅助服务 两种方法虽然能检测出半透明应用的覆盖情况，但是需要申请额外权限。这两个权限及其敏感的权限，一般过不了合规检查。所以这两种方法，知道就行了，不会用的。**

### 第三方 SDK 检测方案

这个没啥好讲的。我们公司跟梆梆交流过。梆梆的 SDK 能满足要求，但是很贵，就先放弃了。因为找到了其他方法(就是下面讲的 自定义检测方案)。

在讲自定义检测方案之前，我们需要先总结一下现有方案的优缺点：

1. 无须任何额外权限的方案，检测不了透明界面覆盖的场景，方案代表：栈顶 Activity 检测，应用重要性检测
2. 能够检测透明界面覆盖的方案，需要申请额外权限。这些额外权限存在以下问题。方案代表：应用使用记录统计检测，辅助服务获取前台应用检测。
   1. 权限很敏感，并且无法动态分配
   2. 检测权限状态时得用更底层的 API
   3. 分配权限时用户需要主动前往设置界面分配。
3. 无须权限，且能够检测透明界面的方案，又需要钱。方案代表：第三方 SDK 检测

### 自定义检测方案

既然上面的方案都有明显的缺点，那肯定只有我们自定义了。还好，自定义的方案是能实现的(否则只能使用第三方 SDK 了)。

在做界面覆盖检测这个功能的研究中，我发现了一件事。**那就是在未授权的状态下，一个应用无法获取前台应用的相关信息。我们可以理解成应用无法获取其他应用的信息**。既然如此，那我们就不关注其他应用，只关注本应用就行了。原因如下：

1. 所有的 APP 被覆盖或者退出应用时，都会走生命周期的流程，其中 Activity 的 onPause 方法是必定执行的。
2. 在进入 APP 时，Activity 的生命周期方法也必定执行：
   1. 如果是 Activity 已创建，则肯定会执行 Activity 的 onResume 方法
   2. 如果 Activity 未创建，则肯定会执行 Activity 的 onCreate 方法。
3. 通常 Activity 的切换不会太耗时(太耗时容易 ANR)，假设每个 Activity 的切换是在 500 ms 以内
4. Application 中设置的生命周期回调，虽然不能检测到其他 APP 的 Activity 的生命周期变化，但本 APP 的 Activity 的生命周期变化，是可以感知到的

基于上述逻辑，我设计了一个方案：**在 Activity 生命周期走到 onPause 时，延时发送一个事件，该事件会触发一个 Toast 提醒，该 Toast 用于提示用户已离开本应用。然后在 onCreate、onResume 中移除延时事件**。设在 A 界面启动 B，该方案的解释如下：

- 如果 B 与 A 属于同一个应用，那么 B 的生命周期变化时，是肯定能触发生命周期回调的。我们在 onCreate、onResume 中移除 Toast 提醒，是完全可行的。onCreate 对应新 Activity 创建的场景，onResume 对应已创建的 Activity 重回栈顶的场景。
- 如果 B 与 A 不属于同一个应用，那么在 B 的 onPause 中触发的延时动作，在 A 走到 onCreate、onResume 时是取消不了的。延时事件取消不了，时间一到，肯定就触发提示了。
- 在 A 的 onPause 中进行延时处理的前提是，A 的 onPause 过后，就是 B 的生命周期回调。并且二者切换所用的时间间隔小于设定的延时。以 500 ms 为例，加入延时 500 ms，那么当 A.onPause ---> B.onCreate 的耗时，是在 500 ms 以内的话，就可以满足要求了。而谷歌官方的建议是不要在 onPause 中做耗时操作，因为会影响到界面切换，如果 APP 遵循了这个规则，那么通常在 500 ms 以内，是可以完成 A.onPause ---> B.onCreate/A.onPause ---> B.onResume 动作的。
- 不在 onDestroy 中移除回调的原因是有这么一个场景，A ---> B ---> A，此时按下 back 键，栈顶的 A 会被销毁，退到 B，但是 A 所属应用并未被杀死，仍然需要提醒用户。

综上，下面讲讲自定义方案的具体实现。

首先，定义一个界面覆盖检测类。提供事件延时发送，取消等接口，延时 500 ms。

```java
public class CoverageChecker {
    private static final String TAG = "CoverageChecker";
    private static CoverageChecker INSTANCE;
    /**
     * 是否退出了当前 APP 的标志
     * */
    private boolean isQuit = false;
    // Application Context，防止内存泄漏
    private Context mContext;
    // 延时事件
    private Runnable r;
    // 延时事件发射器
    private Handler handler;
    // 单例模式
    private CoverageChecker(Context context) {
        this.mContext = context.getApplicationContext();
        handler = new Handler(Looper.getMainLooper());
        r = new Runnable() {
            @Override
            public void run() {
                if(isQuit()) {
                    Log.d(TAG, "app is covered, show notify");
                    showCoveredHint();
                }
            }
        };
    }
    public static CoverageChecker getInstance(Context context) {
        if(INSTANCE == null) {
            synchronized (CoverageChecker.class) {
                if(INSTANCE == null) {
                    INSTANCE = new CoverageChecker(context);
                }
            }
        }
        if(INSTANCE.mContext == null) {
            INSTANCE.mContext = context.getApplicationContext();
        }
        return INSTANCE;
    }

    public boolean isQuit() {
        return isQuit;
    }

    public void setQuit(boolean isQuit) {
        this.isQuit = isQuit;
    }

    /**
     * 退出界面时，延迟通知
     *
     * @param activity
     * */
    public synchronized void delayNotify(Activity activity) {
        // 不需要提示，则返回
        if(!isNeedNotify(activity)) {
            return;
        }
        setQuit(true);
        // 先移除已有的
        handler.removeCallbacks(r);
        handler.postDelayed(r, 500);
    }

    /**
     * 进入界面时，移除通知
     * */
    public synchronized void removeNotify() {
        if(isQuit()) {
            setQuit(false);
            handler.removeCallbacks(r);
        }
    }

    /**
     * 判断是否需要提示退出 APP
     * */
    public synchronized boolean isNeedNotify(Activity activity) {
        if(activity == null) {
            Log.w(TAG, "activity == null, not notify");
            return false;
        }
        String actName = activity.getClass().getName();
        if(TextUtils.isEmpty(actName)) {
            Log.w(TAG, "activity name is null, not notify");
            return false;
        }
        // 登录、注册、密码、用户信息等敏感界面才提示，其他界面不提示
        return actName.contains("login")          // 登录相关界面
            || actName.contains("register")       // 注册相关界面
            || actName.contains("password")       // 密码相关界面
            || actName.contains("userinfo");      // 信息相关界面
    }

    /**
     * 当应用被覆盖时，显示提示
     * */
    public void showCoveredHint() {
        if(mContext == null) {
            Log.d(TAG, "showCoveredHint---mContext == null");
            return;
        }
        Toast.makeText(mContext, "你已退出应用", Toast.LENGTH_SHORT).show();
    }
}
```

然后在 Application 的生命周期回调中触发延时发送，取消等逻辑。

```java
public class CustomApplication extends Application {
    private static final String TAG = "CustomApplication";

    @Override
    public void onCreate() {
        registerActivityLifecycleCallbacks(new ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
                // 移除通知
                CoverageChecker.getInstance(activity).removeNotify();
            }

            @Override
            public void onActivityStarted(Activity activity) {
            }

            @Override
            public void onActivityResumed(Activity activity) {
                // 移除通知                
                CoverageChecker.getInstance(activity).removeNotify();
            }

            @Override
            public void onActivityPaused(Activity activity) {
                // 延时通知
                CoverageChecker.getInstance(activity).delayNotify(activity);
            }

            @Override
            public void onActivityStopped(Activity activity) {
            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
            }

            @Override
            public void onActivityDestroyed(Activity activity) {
            }
        });
    }
}
```

在 AndroidManifest.xml 使用 CustomApplication 后，即可监测应用是否被覆盖了。

使用了自定义方案后，能检测透明界面的覆盖情况了；也顺利的通过了梆梆的检测，APP 满足了应用合规检测的要求。

至此，界面覆盖检测这个功能就讲的差不多了。