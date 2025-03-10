---
title: "Android零碎知识点记录"
description: "本文记录了作者在Android日常开发中学到的一些知识点，比较零散"
keywords: "Android,知识点"
weight: 1

date: 2021-06-21T15:11:00+08:00

categories:
  - Android
tags:
  - Android
  - 知识点

url: post/CF45D7AB819A406AB98E9D6EFFFC2F42.html
toc: true
---

本文记录了作者在Android日常开发中学到的一些知识点，比较零散。

<!--More-->

**注：本博客不定期更新**

1. transient使用小结
   1. 一旦变量被 transient 修饰，变量将不再是对象持久化的一部分，该变量内容在序列化后无法获得访问
   2. transient 关键字只能修饰变量，而不能修饰方法和类。注意，局部变量(又叫本地变量，如方法内的变量)是不能被 transient 关键字修饰的。变量如果是用户自定义的类变量，则该类需要实现 Serializable 接口
   3. 被 transient 关键字修饰的变量不再能被序列化，一个静态变量不管是否被 transient 修饰，均不能被序列化
2. 在 JAVA 中，被 synchronized 关键字修饰的 代码块 或 方法块，在同一时刻只允许 一个线程执行。当有线程获取该内存锁后，其它线程无法访问该内存，从而实现 JAVA 中简单的同步、明白这个原理，就能理解 synchronized(this)、synchronized(Object) 和 synchronized(T.class) 的区别了。
   1. synchronized(this) 锁住的是 this 所指代的对象，如果已有线程获取的 this 指代对象的内存锁，其它任何访问该对象的线程都会被阻塞，直到同步代码块执行完成。
   2. synchronized(Object) 锁住的对象是 Object 对象，这样当某线程正在执行同步代码块时，其它线程只是会被 Object 阻塞，但是仍然可能访问 this 指代的对象的其它方法。
   3. synchronized(T.class) 锁住的是 T 类的所有实例对象， 只要有任意一个线程在访问 T 类， 其它线程都会被阻塞住。这种方式效率比较低，不建议使用。
3. Object.wait()，与 Object.notify() 必须要与 synchronized(Obj) 一起使用，也就是 wait,与 notify 是针对已经获取了 Object 锁进行操作，从语法角度来说就是 Object.wait(), Object.notify() 必须在 synchronized(Obj){...} 语句块内。从功能上来说 wait 就是 A 线程在获取到对象 Object 的对象锁后(wait 在 synchronized 代码块内，进来就表示已经获取到对象锁)，主动释放对象锁，同时 A 线程休眠。直到有其它线程 B 调用对象 Object 的 notify() 唤醒 A 线程，才能继续获取对象锁，并继续执行。notify() 会使 B 线程失去对象锁。有一点需要注意的是 notify() 调用后，并不是马上就释放对象锁的，而是在相应的 synchronized() 代码块执行结束，自动释放锁后，JVM 会在 wait() Object 的对象锁的线程中随机选取一线程，赋予其对象锁，唤醒线程，继续执行。Thread.sleep() 与 Object.wait() 二者都可以暂停当前线程，释放 CPU 控制权，主要的区别在于 Object.wait() 在释放 CPU 同时，释放了对象锁的控制。
4. 分享功能(如分享图片到 QQ)如果不知道具体的页面，可以用以下方法可以确定具体的Activity。其核心代码如下：

   ```java
   Intent shareIntent = new Intent();
   // Intent 意为意图，表示将要做的事，Action 设置为 SEND，则表示想要进行发送
   shareIntent.setAction(Intent.ACTION_SEND);
   // 设置 MIME type，表示将要发送的数据类型。
   shareIntent.setTypeAndNormalize("image/*");
   
   PackageManager packageManager = getPackageManager();
   // 查询目标信息
   List<ResolveInfo> tempList = packageManager.queryIntentActivities(shareIntent, PackageManager.GET_META_DATA);
   ```

   要得到所有的包名与类名，

   首先我们可以定义一个数据结构：

   ```java
   public class AppInfo {
       // 包名
       private String packageName;
       // activity 名
       private String activityName;
   }
   ```

   然后，通过 Context 拿到 PackageManager：

   ```java
   PackageManager packageManager = context.getPackageManager();
   ```

   第 3 步，我们定义一个 Intent，Intent 意为意图，表示将要做的事。我们将动作设置为 SEND，数据类型设置为图片。表示告诉系统，我们想要发送类型为图片的东西。

   ```java
   Intent shareIntent = new Intent();
   shareIntent.setAction(Intent.ACTION_SEND);
   shareIntent.setTypeAndNormalize("image/*");
   ```

   Android 中使用的 MIME Type 是 RFC 定义的标准格式，是大小写敏感的。`setTypeAndNormalize` 可以在 `setType`的基础上，将用户的异常输入抹消(通通变为小写)。所有的图片类型，可以用 * 指代。`image/*`泛指图片，不涉及具体的图片类型。

   第 4 步，根据  Intent 筛选出我们想要的信息。

   ```java
   private Vector<AppInfo> getAppInfoList() {
       Intent shareIntent = new Intent();
       shareIntent.setAction(Intent.ACTION_SEND);
       shareIntent.setTypeAndNormalize("image/*");
   
       PackageManager packageManager = getPackageManager();
   
       // 根据上面的设置，筛选出的结果
       List<ResolveInfo> tempList = packageManager.queryIntentActivities(shareIntent, PackageManager.GET_META_DATA);
       // 将所有的数据打印出来，方便我们人为辨别
       Log.d(TAG, "查询到的列表: " + tempList);
       if(tempList.size() <= 0) {
           return new Vector<>(0);
       }
       Vector<AppInfo> appInfoList = new Vector<>();
       AppInfo appInfo;
       for(ResolveInfo info : tempList) {
           if(info == null) {
               continue;
           }
           // 将数据筛入我们自定义的数据结构中
           appInfo = new AppInfo();
           appInfo.setPackageName(info.activityInfo.packageName);
           appInfo.setActivityName(info.activityInfo.name);
           appInfoList.add(appInfo);
       }
   
       return appInfoList;
   }
   ```

   下面以筛选 QQ 为例，首先，我们拿到了所有的包名、类名：

   ```java
   [
       ResolveInfo{728890e com.android.bluetooth/.opp.BluetoothOppLauncherActivity m=0x608000}, 
       ResolveInfo{4d8cf2f com.android.mms/.ui.ComposeMessageRouterActivity m=0x608000}, 
       ResolveInfo{72956c5 cn.wps.moffice_eng/cn.wps.moffice.main.scan.ui.ThirdpartyImageToPdfActivity m=0x608000}, 
       ResolveInfo{668281a cn.wps.moffice_eng/cn.wps.moffice.main.scan.ui.ThirdpartyImageToTextActivity m=0x608000}, 
       ResolveInfo{4ad2f4b cn.wps.moffice_eng/cn.wps.moffice.main.scan.ui.ThirdpartyImageToXlsActivity m=0x608000}, 
       ResolveInfo{1282d28 cn.wps.moffice_eng/cn.wps.moffice.main.scan.ui.ThirdpartyImageToPptActivity m=0x608000}, 
       ResolveInfo{cd9a41 cn.wps.moffice_eng/cn.wps.moffice.main.cloud.drive.upload.UploadFileActivity m=0x608000}, 
       ResolveInfo{bd0abe6 com.android.email/com.kingsoft.mail.compose.ComposeActivity m=0x608000}, 
       ResolveInfo{e67b35 com.qiyi.video/org.qiyi.android.video.MainActivity m=0x608000}, 
       ResolveInfo{baacbca com.qiyi.video/com.qiyi.scan.ARWrapperActivity m=0x608000}, 
       ResolveInfo{a0c813b com.quark.browser/com.ucpro.MainActivity m=0x608000}, 
       ResolveInfo{5553058 com.sina.weibo/.composerinde.ComposerDispatchActivity m=0x608000}, 
       ResolveInfo{61095b1 com.sina.weibo/.story.publisher.StoryDispatcher m=0x608000}, 
       ResolveInfo{a91da96 com.sina.weibo/.weiyou.share.WeiyouShareDispatcher m=0x608000}, 
       ResolveInfo{6b7f617 com.taobao.taobao/com.etao.feimagesearch.IrpActivity m=0x608000}, 
       ResolveInfo{618fa04 com.tencent.androidqqmail/com.tencent.qqmail.launcher.third.LaunchComposeNote m=0x608000}, 
       ResolveInfo{7e7dbed com.tencent.androidqqmail/com.tencent.qqmail.launcher.third.LaunchComposeMail m=0x608000}, 
       ResolveInfo{9090a22 com.tencent.androidqqmail/com.tencent.qqmail.launcher.third.LaunchFtnUpload m=0x608000}, 
       ResolveInfo{23bdcb3 com.tencent.mm/.ui.tools.ShareImgUI m=0x608000}, 
       ResolveInfo{62db270 com.tencent.mm/.ui.tools.AddFavoriteUI m=0x608000},
       ResolveInfo{7349e9 com.tencent.mm/.ui.tools.ShareToTimeLineUI m=0x608000}, 
       ResolveInfo{4d1a66e com.tencent.mobileqq/.activity.JumpActivity m=0x608000}, 
       ResolveInfo{50d910f com.tencent.mobileqq/.activity.qfileJumpActivity m=0x608000}, 
       ResolveInfo{993859c com.tencent.mobileqq/cooperation.qlink.QlinkShareJumpActivity m=0x608000}, 
       ResolveInfo{92d9ba5 com.tencent.mobileqq/cooperation.qqfav.widget.QfavJumpActivity m=0x608000}, 
       ResolveInfo{475bb7a com.tencent.mtt/.businesscenter.intent.IntentDispatcherActivity m=0x608000}, 
       ResolveInfo{f9c2f2b com.tencent.mtt/.external.reader.thirdcall.ThirdCallDispatchActivity m=0x608000}, 
       ResolveInfo{2215f88 com.tencent.mtt/.external.imageedit.ImageEditActivity m=0x608000}, 
       ResolveInfo{e814d21 com.tencent.wework/.launch.AppSchemeLaunchActivity m=0x608000}, 
       ResolveInfo{b141546 com.tmall.wireless/.splash.TMSplashActivity m=0x608000}, 
       ResolveInfo{2c9307 com.xiaomi.scanner/.app.ScanActivity m=0x608000}, 
       ResolveInfo{630ec34 net.windcloud.explorer/.FileExplorerTabActivity m=0x608000}
   ]
   ```

   找到了目标的几个页面：

   ```java
   ResolveInfo{4d1a66e com.tencent.mobileqq/.activity.JumpActivity m=0x608000}, 
   ResolveInfo{50d910f com.tencent.mobileqq/.activity.qfileJumpActivity m=0x608000}, 
   ResolveInfo{993859c com.tencent.mobileqq/cooperation.qlink.QlinkShareJumpActivity m=0x608000}, 
   ResolveInfo{92d9ba5 com.tencent.mobileqq/cooperation.qqfav.widget.QfavJumpActivity m=0x608000}, 
   ```

   此时仍然不知道是哪个页面，我们需要去网上查资料。大功告成，得到了最终的 Activity：

   ```java
   // 包名：com.tencent.mobileqq
   // 类名：com.tencent.mobileqq.activity.JumpActivity
   ```

   值得注意的是，SetAction 为 SEND 后的查询，得到的是一个列表，如果我们不用查询Activity，而是直接用 chooseDialog 打开，就会出现下面这种选择框，表示系统要我们选择哪个应用。这些应用其实也就是系统查询出来，然后展示的。

   <img src="/imgs/系统展示可用应用.webp" style="zoom:50%;" />

   上面要我们选择，是因为我们并没有指定具体的应用，具体的类。用的也是通用的动作(Action)，而不是私有的动作(Action)。
5. 下面的代码也有可能报空指针：

   ```java
   public class Bean {
       Long id;
       
       public Long getId() {
           return id;
       }
   }
   
   public boolean isOne(Bean bean) {
       if(bean == null) {
           return false;
       }
       return bean.getId() == 1L;
   }
   ```
   原因就是`bean.getId()`拿到的是一个 Long(装箱后的数据)，而 1L 是一个基本类型 long。如果用`==`的形式，则 Long 需要先拆箱，拆箱过程中，如果 id 为空，也会报空指针。所以仍然需要加上`bean.getId() == null`的判断。
6. 声音分贝值的计算：dB = 20 * lg(幅度 / 0.00002)，0.00002 是 20 微帕，通常被人为是人能听到的最小声音。原始公式：1dB = 20 * log(A1 / A2)，其中 A1 和 A2 是两个声音的振幅。采样大小为 8bit 也就是 1 个字节时，最大振幅是最小振幅的 256 倍。因此，动态范围是 48 分贝，计算公式如下：dB = 20 * log(256)。48 分贝的动态范围大约是一个安静房间和一台运行着电动割草机之间的区别。如果将声音采样大小增加一倍到 16bit，产生的动态范围则为 96 分贝，计算公式如下：dB = 20 * log(65536)。这非常接近听力最低阈值和产生痛感之间的区别，这个范围被认为非常适合还原音乐。
7. 仓库使用阿里云

   ```groovy
   buildscript {
       //阿里云镜像
       repositories {
           maven{ url 'https://maven.aliyun.com/repository/central'}
           maven{ url'https://maven.aliyun.com/repository/public'}
           maven{ url "https://maven.aliyun.com/repository/google"}
           //google()
           //mavenCentral()
           //jcenter()
       }
   }
   
   allprojects {
       //阿里云镜像
       repositories {
           maven{ url 'https://maven.aliyun.com/repository/central'}
           maven{ url'https://maven.aliyun.com/repository/public'}
           maven{ url "https://maven.aliyun.com/repository/google"}
           //google()
           //mavenCentral()
           //jcenter()
       }
   }
   ```
8. 音视频大神：雷霄晔，闫令琪
9. SpannableString + ImageSpan 可以在 TextView 实现富文本的效果
10. 字节码增强技术：ASM。ASM 是一个 java 字节码操纵框架。
11. CountDownLatch 可以让异步操作变成同步操作。
12. Scroller 的代码模版：
```java
/**
 * 一般的滑动是瞬时的，可以通过 Scroller 进行平滑
 * 
 * 下面的是 Scroller 的代码模版
 */
public class TestView extends View {
    Scroller scroller;

    public TestView(Context context) {
        super(context);
        scroller = new Scroller(getContext());
    }

    @Override
    public void computeScroll() {
        if (scroller.computeScrollOffset()) {
            scrollTo(scroller.getCurrX(), scroller.getCurrY());
            postInvalidate();
        }
    }

    // 缓慢滚动到指定位置
    private void smoothScrollTo(int destX, int destY) {
        int scrollX = getScrollX();
        int delta = destX - scrollX;
        // 1000ms内滑向destX，效果就是慢慢滑动
        scroller.startScroll(scrollX, 0, delta, 0, 1000);
        invalidate();
    }
}
```
13. 负数以其正值的补码表示(补码 = 反码 + 1)，负数的无符号右移，高位补0，出来的数会很大
14. 每个 Activity、Dialog、Toast、PopUpWindow 都对应了一个 window。
15. 渲染部分的性能优化
   
   - 渲染操作通常依赖于两个核心组件：CPU 与 GPU。CPU 负责包括 Measure，Layout，Record，Execute 的计算操作，GPU 负责 Rasterization(栅格化)操作。CPU 通常存在的问题的原因是存在非必需的视图组件，它不仅仅会带来重复的计算操作，而且还会占用额外的 GPU 资源。
   - CPU 负责把 UI 组件计算成 Polygons，Texture 纹理，然后交给 GPU 进行栅格化渲染。每次从CPU转移到GPU是一件很麻烦的事情。
   - 解决过度绘制(某个像素在同一帧的时间内被绘制了多次)的方法为：
      - 移除 Window 默认的 Background
      - 移除 XML 布局文件中非必需的 Background
      - 按需显示占位背景图片(比如 imageView 拿到 drawable 就不显示 background 了，拿不到才显示)
      - 自定义 view 时，使用 canvas.clipRect() 来帮助系统识别那些可见的区域。这个方法可以指定一块矩形区域，只有在这个区域内才会被绘制，其他的区域会被忽视。这个 API 可以很好的帮助那些有多组重叠组件的自定义 View 来控制显示的区域。同时 clipRect 方法还可以帮助节约 CPU 与 GPU 资源，在 clipRect 区域之外的绘制指令都不会被执行，那些部分内容在矩形区域内的组件，仍然会得到绘制。
      - 自定义 view 时，还可以使用 canvas.quickreject() 来判断是否没和某个矩形相交，从而跳过那些非矩形区域内的绘制操作。
      - Android 需要把 XML 布局文件转换成 GPU 能够识别并绘制的对象。这个操作是在 DisplayList 的帮助下完成的。DisplayList 持有所有将要交给 GPU 绘制到屏幕上的数据信息。在某个 View 第一次需要被渲染时，Display List 会因此被创建，当这个 View 要显示到屏幕上时，我们会执行 GPU 的绘制指令来进行渲染。如果 View 的 Property 属性发生了改变（例如移动位置），我们就仅仅需要 Execute Display List 就够了。然而如果你修改了 View中 的某些可见组件的内容，那么之前的 DisplayList 就无法继续使用了，我们需要重新创建一个 DisplayList 并重新执行渲染指令更新到屏幕上。
      - 任何时候 View 中的绘制内容发生变化时，都会需要重新创建 DisplayList，渲染 DisplayList，更新到屏幕上等一系列操作。这个流程的表现性能取决于你的 View 的复杂程度，View 的状态变化以及渲染管道的执行性能。举个例子，假设某个 Button 的大小需要增大到目前的两倍，在增大 Button 大小之前，需要通过父 View 重新计算并摆放其他子 View 的位置。修改 View 的大小会触发整个 HierarcyView 的重新计算大小的操作。如果是修改 View 的位置则会触发 HierarchView 重新计算其他 View 的位置。如果布局很复杂，这就会很容易导致严重的性能问题。
      - 提升布局性能的关键点是尽量保持布局层级的扁平化，避免出现重复的嵌套布局。RelativeLayout 在 measure 这一步耗时贼严重。是因为相对布局需要给所有子 View 水平方向测量一次，再竖直方向测量一次，才能确定每个子 View 的大小。层级一旦太深，measure 时间以指数上升。LinearLayout 如果子 View 的 LayoutParams 里有使用 weight 属性的话，measure 时间和 RelativeLayout 几乎接近，因为也需要给每个子 View 测量两次。尽量少写层级深的布局，能减少一个视图节点就少一些 measure 时间

16. 写 gradle 时，如果想要添加上代码提示和 API 说明，可以使用以下代码：
```groovy
// 根项目的 build.gradle 文件中加入以下代码
buildscript {
    repositories {
        maven {
            url "https://repo.gradle.org/gradle/libs-releases-local"
        }
    }
    dependencies {
        // 引入 Android 插件，具体版本号见 maven 仓库
        classpath 'com.android.tools.build:gradle:${version}'
        // 引入 Android 插件 API
        classpath "com.android.tools.build:gradle-api:${version}"
        // classpath "com.android.tools.build:gradle-core:${version}"
        // 引入 Groovy
        // classpath "org.codehaus.groovy:groovy-all:${version}"
        // version 为 gradle-core-api 的版本，如：6.1.1
        classpath "org.gradle:gradle-core-api:${version}"
    }
}
```

17. 根项目下新建 buildSrc 文件夹，当做一个新的 module(具备 src/main/java 目录和 build.gradle 文件)，这个 module 默认会被根项目依赖。在其他模块和根项目的 build.gradle 文件中，可以使用 buildSrc 模块中定义的类。
18. gradle 包的缓存目录：C:\Users\用户名\.gradle\wrapper\dists\gradle版本号\wrapper\dists；  Android gradle plugin 包的缓存目录：C:\Users\用户名\.gradle\wrapper\dists\gradle版本号\caches\modules-2\files-2.1\com.android.tools.build\gradle。gradle 和 Android 插件具体是哪个版本，以 build.gradle 中的声明为准。
19. RecyclerView 的使用包含以下几个方面：
    1. Adapter+ViewHolder
    2. ItemDecoration
    3. ItemAnimator
    4. LayoutManager
    5. ItemTouchHelper
    6. SnapHelper
    7. Cache
    8. notify and refresh
20. Kotlin 回调转协程的方法：
```kotlin
// 回调转 Flow 第 1 种方法，使用 suspendCancellableCoroutine
uspend fun awaitCallback(): T = suspendCancellableCoroutine { continuation ->
	// 定义异步回调
    val callback = object : Callback {
        override fun onCompleted(value: T) {
            // 异步执行成功，发送值
            continuation.resume(value)
        }
        override fun onApiError(cause: Throwable) {
            // 异步执行出错，发送异常
            continuation.resumeWithException(cause)
        }
    }
    // 注册异步回调
    api.register(callback)
    // 取消回调
    continuation.invokeOnCancellation { api.unregister(callback) }
}

flow{emit(awaitCallback())}
```


```kotlin
// 回调转 Flow 第 2 种方法，使用 callbackFlow
fun flowFrom(api: CallbackBasedApi): Flow<T> = callbackFlow {
    // 定义异步回调
    val callback = object : Callback {
        override fun onNextValue(value: T) {
            try {
                // 异步执行成功，发送值
                sendBlocking(value)
            } catch (e: Exception) {
            }
        }
        override fun onApiError(cause: Throwable) {
            // 取消异步动作
            cancel(CancellationException("API Error", cause))
        }
        override fun onCompleted() = channel.close()
    }
    // 注册异步回调
    api.register(callback)
    // 'onNextValue'/'onApiError' 触发或者 flow 被结束，则回调会被取消
    awaitClose { api.unregister(callback) }
}
```

21. Material Design 1.2 之后，有个 ShapeableImageView，可以实现圆角、圆、菱形，箭头等 ImageView 的效果。

22. 如果需要执行 3 个任务：A、B、C。A、B 可以并行执行，C 需要等到 A、B 都执行完后再执行。则在 Kotlin 中，协程的实现如下：

```kotlin
fun test() = view.lifecycleOwner.lifecycleScope.launch(Dispatchers.Main) {
    runCatching {
        val list = mutableListOf<TestItem>()
        withContext(Dispatchers.IO) {
            // task1 和 task2 并行执行
            // 而 task3 得等到 task1 和 task2 都执行完后才执行
            val task1Deferred = async { task1() }
            val task2Deferred = async { task2() }
            list.addAll(task3(task1Deferred.await(), task2Deferred.await()))
        }
        if(list.isEmpty()) {
            error("init: list is null")
        }
        list
    }.onSuccess { list ->
        view.onSuccess(list)
    }.onFailure { error ->
        Log.e(TAG, "", error)
        view.onFailure(emptyList())
    }
}
```

23. Kotlin 中，如果想要读取文件，可以使用 File 提供的相关方法；如果想要像打印控制台一样将内容打印到文件，则可以使用下面的语句：

```kotlin
// 测试 writeToFile 方法
fun main() {
    // 写入文件中
    writeToFile(pathName) { fileWriter ->
        map.toSortedMap().forEach {
            // 写入一行到文件中
            fileWriter.println("${it.key.padEnd(120)} - ${it.value.sorted()}")
        }
    }
}

/**
 * 打开文件，写入数据
 * */
private fun writeToFile(
    fileName: String, 
    writeCallback: ((PrintWriter) -> Unit)
) {
    File(fileName).apply {
        val p = parentFile
        // 父目录不存在，则创建
        if(!p.exists()) {
            p.mkdirs()
        }
        // 文件不存在，则创建
        if (!exists()) {
            createNewFile()
        }
        this.printWriter(StandardCharsets.UTF_8).use { out ->
            // 1. 每次写入前清空文件内容
            out.print("")
                                                      
            // 2. 打印首行提示文本
            out.println()
            // 格式化字符串
            // 格式化时需要注意，中文在 String 中被当作一个字符计算长度
            // 但是在显示时会占用 2 到 3 个字符长度(编码不同，长度会有所不同)
            out.println("测试项：".padEnd(110) + " - 说明：")
            out.println()
                                                      
            // 3. 打印正文内容
            writeCallback.invoke(out)
        }
    }
}
```

24. RecyclerView 加了 ItemDecoration 后，Item 为 Gone 时，ItemDecoration 也会生效。这会导致可见的 Item 的间距显示异常。

25. Android 使用 Base64 编码时，如果标志位设置不当，编码后的 Base64 数据的末尾可能多出一个多余的 \n 换行符。其他端在解析时可能会出错。解决办法是在转 Base64 时，或上 `Base64.NO_WRAP` 标志位，使 Base64 数据是一行数据，不换行。

   ```kotlin
   return Base64.encodeToString(
       outputStreams.toByteArray(),
       Base64.DEFAULT.or(Base64.NO_WRAP)
   )
   ```

26. 使用 GSON 将数据转成 JSON 字符串时，GSON 可能会优化输出，将 = & 等字符优化成 unicode 编码，比如理想输出是 `ac=`，但优化后变成了 `ac\u003d`，其他端在解析时，可能会出错。解决办法是使用 `disableHtmlEscaping` 方法，禁止优化。

   ```kotlin
   private fun toJsonDisableAutoConvert(src: Any): String {
       return GsonBuilder()
           // 禁用字符转换
           .disableHtmlEscaping()
           .create()
           .toJson(src)
   }
   ```

27. ffmpeg -i videoPath %d.jpg 可以将视频转为图片，图片名为 1.jpg, 2.jpg, 3.jpg ......

28. Uri 的结构

   ```
   基本结构：
   [scheme:]scheme-specific-part[#fragment]
   
   进一步划分的形式：
   [scheme:][//authority][path][?query][#fragment]
   
   最详细的划分：
   [scheme:][//host:port][path][?query][#fragment]
   ```

   在 Android 中，scheme、authority 是必须要有的，其它的几个 path、query、fragment，可以选择性的要或不要，但顺序不能变。

   - path可以有多个，每个用 / 连接，比如：

     scheme://authority/path1/path2/path3?query#fragment

   - query参数可以带有对应的值，也可以不带，如果带对应的值用 = 表示。query参数可以有多个，每个用 & 连接，比如：

     scheme://authority/path1/path2/path3?id=1&name=abc&old#fragment

     这里有 3 个参数：

     - 参数 1：id，其值是: 1

     - 参数 2：name，其值是: abc

     - 参数 3：old，没有值，所以它的值是 null

   举个例子：
   
   ```
   http://www.java2s.com:8080/yourpath/fileName.htm?stove=10&path=32&id=4#harvic
   ```
   
   | 方法 | 作用 | 值 |
   | :-: | :-: | :-: |
   | getScheme() | 获取 Uri 中的 scheme 部分 | http |
   | getSchemeSpecificPart() | 获取 Uri 中的 scheme-specific-part 部分 |  [//www.java2s.com:8080/yourpath/fileName.htm](https://www.java2s.com:8080/yourpath/fileName.htm)? |
   | getFragment() | 获取 Uri 中的 fragment 部分 | harvic |
   | getAuthority() | 获取 Uri 中 Authority 部分 | www.java2s.com:8080 |
   | getPath() | 获取 Uri 中 path 部分 | /yourpath/fileName.htm |
   | getQuery() |  获取 Uri 中的 query 部分 | stove=10&path=32&id=4 |
   | getHost() | 获取 Authority 中的 Host 部分 | www.java2s.com |
   | getPost() | 获取 Authority 中的 Port 部分 | 8080 |
   | getPathSegments() | 依次提取出 Path 的各个部分的字符串，以字符串数组的形式输出 | yourpath、fileName.htm |
   | getQueryParameter(String key) | 通过传进去 path 中某个 Key 的字符串，返回他对应的值 | |

29. StateFlow 发射事件时，自带去重。如果需要重复的发射，可以用 ShareStateFlow。

30. 小窗模式、画中画模式、分屏模式下，可能会出现一些平时见不到的问题。此时 View 的尺寸很容易模拟出宽大于高的场景。

31. Android TextView 局部文字点击空用下面的方法：

   ```kotlin
   private fun showTvTip() = binding.tvTip.takeIf {
       it.text?.length ?: 0 > 10
   }?.also { tv ->
       SpannableStringBuilder(tv.text).also { builder ->
           val start = tv.text.length - 10 // 需要变色的文本长度为 10
           val end = tv.text.length

           builder[start, end] = object : ClickableSpan() {
               override fun onClick(widget: View) {
                   ToastUtil.showToast("变色文本点击")
               }

               override fun updateDrawState(ds: TextPaint) {
                   // 待点击的文本变色
                   ds.color = R.color.yellow.colorRes
               }
           }

           // 解决点击不生效的问题
           tv.movementMethod = LinkMovementMethod.getInstance()
           // 富文本赋值
           tv.text = builder
           // 赋值后重设颜色，解决点击后点击区域出现背景色的问题
           // Android4.0 以上默认是淡绿色，低版本的是黄色
           tv.highlightColor = R.color.transparent.colorRes
       }
   }
   ```

32. Android 系统小组件支持的效果有限：不支持自定义 View，View 的种类受限；动态设置数据受制于 RemoteView 提供的方法。

33. 如果写 gradle 插件时，gradle 没有代码提示，可能是因为 gradle-wrapper.properties 文件中的 distributionUrl 指定的 gradle 包有误，指定成了 bin 包。改成 src 或者 all 包就好了。如果改了后，gradle 编译出错，可能是因为同个版本存在 bin/src/all 等不同的包。删掉多余的，保留一个 all 包就好。gradle 缓存地址：C:\Users\用户名\.gradle\wrapper\dists

34. 如果想要以单独模块的形式引入 gradle 插件，则可以使用 buildSrc 的形式，如果需要暴露给其他项目，再使用单独 module 的形式，配置 maven publish。否则可能出现插件无法找到的问题。

35. buildSrc 的 repositories 需要单独配置。buildSrc 的 build.gradle 脚本先于 rootProject 的 build.gradle 脚本执行

36. Kotlin 中，CharSequence.isNullOrBlank() 方法能判断字符是否为空，或者纯空格(全角空格、半角空格以及二者混合的场景都能检测)。

37. 小组件可以是单独的进程。直接adb dump一下进程就是内存占用了。一些基础运行时会在启动第一个小组件的时候初始化，内存部分就算到第一个里了。可以对一下增量，就知道每个的大小了。比如，第二个小组件添加后的内存-第一个小组件的内存。命令：adb shell dumpsys meminfo [进程名]

38. JS 调用的无参方法，客户端在 JavascriptInterface 中声明时，也需要传个参数，否则无法识别。

39. 如果遇到 Fragment 的 Transaction 正在执行，导致的状态不对的问题，可以试试使用 View.post 执行 Fragment 的增删改操作，说不定有奇效。

40. Android 中，可以自定义 InputConnection，继承自 InputConnectionWrapper，以监听软键盘的删除键按下。外设会走 KeyEvent 的流程，软键盘的按键事件，并不一定会走 KeyEvent 的流程：

```kotlin
class MyEditText : AppCompatEditText {
    var myCheckIC: MyInputConnection = MyInputConnection(null, true)

    constructor(context: Context) : this(context, null)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr)

    override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection {
        myCheckIC.setTarget(super.onCreateInputConnection(outAttrs))
        return myCheckIC
    }
}

class MyInputConnection(target: InputConnection?, mutable: Boolean) : InputConnectionWrapper(target, mutable) {
    // return true 表示拦截删除事件，否则不拦截
    var myDelListener: ((String) -> Boolean)? = null

    // 部分输入法删除键会走这个方法，取决于输入法自身如何定义
    override fun deleteSurroundingText(beforeLength: Int, afterLength: Int): Boolean {
        if (myDelListener?.invoke("deleteSurroundingText") == true) {
            return true
        }
        return super.deleteSurroundingText(beforeLength, afterLength)
    }

    // 部分输入法删除键会走这个方法，取决于输入法自身如何定义
    override fun sendKeyEvent(event: KeyEvent?): Boolean {
        if (KeyEvent.KEYCODE_DEL == event?.keyCode
            && KeyEvent.ACTION_DOWN == event.action
            && myDelListener?.invoke("sendKeyEvent") == true
        ) {
            return true
        }
        return super.sendKeyEvent(event)
    }
}
```

41. bsdiff 差分打包技术工具。apktool 反编译 manifest 文件和资源文件。dex2jar 配置 jd-gui 查看 dex 编译后的 class 文件。

42. kotlin flow 无法直接使用链式写法，使用 "flow {}" 必须创建一个新方法，才能进行链式写法。

43. public、private 等可见性操作符对 native 层来讲都一样，只有 java 调用层会有区别。

44. 搜狗输入法预测模式用的 setComposingText 方法，而百度输入法预测模式使用的是 commitText 方法。

45. Android SDK 的路径里不能带空格，否则配置 Flutter 等的环境的时候，会出现问题。

46. Android 系统 native 源码对应位置为：\frameworks\base\core\jni\android\

47. Android 中 Dialog 的显示隐藏，必须在主线程操作

48. Fragment 的生命周期可以用状态控制，比如设置了 STARTED 后，生命周期方法最多执行到 onStart(执行了 onStart 后，状态变成了 ON_STARTED，并不接着向下执行方法)。
![Fragment生命周期状态](/imgs/Fragment生命周期状态.webp)
Lifecycle框架定义状态流程如下：
![Fragment生命周期状态2](/imgs/Fragment生命周期状态2.svg)

49. dart 的语法，方法前加下划线(_)表示方法是私有方法，外部无法访问

50. adb 启动 activity:  adb shell am start -n 包名/类名全路径。其中 activity　的 xml 属性，exported 需要设为 true。

51. kotlin 中，return@foreach 相当于 continue。foreach 中并没有 break 的直接等价语法。想要跳出循环，只能返回更上一层。

52. Looper 和 Handler 销毁前都需要停止，Handler 是 removeCallbacksAndMessages(null)，Looper 是 quitSafely()。

53. Databinding 中，如果想要 LiveData 动态更新数据，则需要在创建 Databinding 时，设置 setLifecycleOwner，否则 LiveData 不会触发 UI 刷新。另外 xml 中通过 databinding + livedata 设置宽高时，需要设置 default 才能正常，否则会崩溃报错。

54. 使用协程实现 view post 时阻塞，post 后恢复执行：

   ```kotlin
   suspend fun View.wait() = suspendCancellableCoroutine<Unit> { cc ->
       val runnable = {
           cc.resume(Unit)
       }
       post(runnable)
       cc.invokeOnCancellation {
           removeCallbacks(runnable)
       }
   }
   // post 执行后继续执行后续代码
   titleBar.wait()
   ```

55. 使用 View 的 cache，可以实现给 view 截图的效果。下面的代码将 View 的 cache 转为 Bitmap：

   ```kotlin
   // 找到具体 View
   val view = activity.findViewById<View>(id)
   // 构建 View 的 cache
   view.isDrawingCacheEnabled = true
   view.buildDrawingCache()
   // View 的 cache 转成 Bitmap
   val cache = view.drawingCache
   val bitmap = Bitmap.createBitmap(
       cache, 
       0, 
       0, 
       cache.width,
       (cache.width * 0.8).roundToInt()
   )
   ```

56. Android Room 数据库不允许直接在 Entity 中嵌套 POJO，如要使用 POJO，则需要在该类型上标注 @Embedded。并且 POJO 中的字段，不可以 Entity 中的字段重名。

57. 要将 activity 和 dialog 联系起来，一个简单的方法是可以使用静态 map。但要注意生命周期和内存泄漏的问题。如下面的代码：
   ```kotlin
   companion object {
       val dialogMap = HashMap<Activity, Dialog>()
   }
    
   fun showDialog(activity: Activity, dialog: Dialog) {
       dialogMap[activity] = dialog
       dialog.show()
   }
    
   fun hideDialog(activity: Activity) {
       val dialog = dialogMap.remove(activity)
       dialog?.hide()
   }
   ```

58. Android 启动程序，卡在启动页，系统提示 waiting for debugger。则可能是打开了开发者选项的等待调试。关闭就好了。

<img src="/imgs/开发者选项的等待调试1.webp" style="zoom:80%" />

<img src="/imgs/开发者选项的等待调试2.webp" style="zoom:60%" />

59. CheckBox 和 RadioButton 有个自动刷新 check 状态的逻辑(toggle 方法)，这可能会导致一些交互方面的 bug。

60. 抓包技术如果在应用中使用，抓别人的包，可能涉及到灰产，存在法律风险。就说不会，免得坐牢。

61. 即使是 debug 版本，也应该避免调试日志疯狂打印，否则会导致别人的日志被覆盖，影响别人的开发

62. kotlin Flow 中，onCompletion 操作符会在 catch 操作符之前执行，即使没有发射任何数据。

```kotlin
// 下面的代码，done 一定会打印出来
runBlocking {
    flow<Unit> { error("test") }
        .onCompletion { println("done") }
        .catch { it.printStackTrace() }
        .collect { println("unit") }
}
```

63. 页面位于后台时，View.post 可能不会执行

64. Bitmap.compress() 方法，当格式选择为 Bitmap.CompressFormat.JPEG 时，EXIF 信息会保留下来，不会丢失。

65. git worktree 可以用于同仓库，不同分支的开发。

66. 浮窗 View 跟随 Activity 时，可以将 View 添加到 Activity 的 DecorView 上；如果浮窗 View 需要跨 Activity，则可以使用 WindowManager.addView 添加 View，WindowManager 的 type 设置的越大，则 View 的层级越靠上。Window 默认是每个 Activity 一个，Activity 包含 Window，Window 包含 DecorView 这种关系。WindowManager.addView 方法本质上会对 View 创建单独的新 Window，此时 View 就可以不用跟随 Activity 了。不过需要注意几个点：
   - WindowManager.LayoutParams 的双参构造方法的含义不是传入宽高，而是传入 type 和 flags。
   - 通常情况下，WindowManager.LayoutParams 中需要传入 type，但 type 只能是应用级的 type，不能是 System 级的 type，所以一般的悬浮窗不能做到应用内跨界面。悬浮窗只能与 Activity 关联。可以使用 type_toast，传入自定义布局，通过反射修改 toast 的显示时长，以实现应用内跨界面的悬浮窗效果。但是此种方案存在不确定性。在国内手机厂商众多的情况下，可能存在兼容性问题。具体可见文章：https://www.jianshu.com/p/18cbc862ba7b
   
67. 以下代码打印结果为 1：
   
   ```kotlin
   fun main(args: Array<String>) {
       var num=0
        ++num
        println(num)
   }
   ```

68. Fragment 中调用 startActivityForResult时，从哪里发起调用，最终就会走到哪里。
   - 用 getActivity 方法发起调用，只有父 Activity 的 onActivityResult 会调用，Fragment 中的 onActivityResult 不会被调用
   - Fragment 直接发起startActivityForResult调用，当前的 Fragment 的 onActivityResult，和父 Activity 的 onActivityResult 都会调用
   - 用 getParentFragment 发起调用，则只有父 Activity 和父 Fragment 的 onActivityResult 会被调用，当前的 Fragment 的 onActivityResult 不会被调用

69. BitmapFactory inPreferredConfig 什么情况下会出现不满足的情况？总结如下：

   - 所有情况下ARGB_8888配置都可以满足
   - 所有情况下ALPHA_8配置都不满足
   - 绝大多数情况下RGB565选项都不满足

   不满足时，会使用 ARGB_8888 配置。所以，所谓设置 RGB565 选项可以减少内存的说法根本不成立。而且在所有 RGB565 选项满足的场景中，除 Android4.4 系统以上的 8 位 RGB 编码的 JPG 图片(即灰度图)外，其他情况使用 null 选项也会使用 RGB565 选项。所以，基本上指定 inPreferredConfig 为 RGB565 和不设置 inPreferredConfig 的效果是一样的。

70. ImageView 设置 background 时，图片会被拉伸到宽高的尺寸，与 scaleType 无关。

71. Retrofit 低版本使用协程，无返回值（后台response body = null）的情况，请求 SUCCESS 时也可能会抛 KotlinNullPointerException 异常。有需要使用协程，又不需要返回值的场景，可以考虑如下办法绕过这个 bug：申明返回值类型为 Response，数据类型为 Any？，即可正常完成请求，同时也能正常检测到其他业务异常。如：
   
   ```kotlin
   suspend fun testRequest(@Body req: Request): Response<Any?>
   ```
   
72. 外层协程没死的情况下是可以 catch 住的，如果外层协程挂掉了，并且没有设置默认的异常处理器的话，异常会逃走，无法 catch 住

73. Objects.equals 能比较列表，子类可以调用父类的比较方法

74. android:clipChildren="false"  android:clipToPadding="false" 两个属性必须在更外层 ViewGroup(如爷爷 ViewGroup)也设置，否则可能会出现 View 无法超出父 ViewGroup 的范围的问题。

75. Clang、LLVM、CMake 之间的关系，和 Java 编译器、JVM、Gradle 之间的关系类似。
      - Gradle 是 Java 项目的项目管理工具；Java 编译器用于编译 Java 源代码；JVM 是 Java 语言底层的虚拟机，JVM 与语言无关，更多的是一种规范。JVM 上的语言可以有 Java、Groovy、Kotlin 等。
	  - CMake 是 C 项目的项目管理工具；Clang 编译器用于编译 C 源代码；LLVM 是 C 语言底层的虚拟机，LLVM 与语言无关，更多的是一种规范。LLVM 上的语言可以有 C、C++、Object-C 等。
	  
76. Glide 内部会处理针对相同请求的并发操作(当然是因为图片只能在主线程发起加载)。
77. StateFlow 类似于 LiveData，相同的值不会重复发射，可以使用时间戳，保证值不同。debounce 会限频，只发送最后一次值。StateFlow 在后台页面时也可以刷新。

78. RecyclerView 如何实现最大 N 行的 LayoutManager:
    1. 首先，创建一个名为MaxRowGridLayoutManager的新类，并继承自GridLayoutManager：
    
    ```java
    @Override
    protected void onMeasure(RecyclerView.Recycler recycler, RecyclerView.State state, int widthSpec, int heightSpec) {
        int maxHeight = 0;
        int maxRow = 3; // 设置最大行数
        int totalItems = getItemCount();
        int totalRows = (int) Math.ceil((double) totalItems / getSpanCount());

        if (totalRows > maxRow) {
            totalRows = maxRow;
        }

        for (int i = 0; i < totalRows * getSpanCount(); i++) {
            View view = recycler.getViewForPosition(i);
            if (view != null) {
                measureChild(view, widthSpec, heightSpec);
                int measuredHeight = view.getMeasuredHeight() + getDecoratedBottom(view);
                maxHeight += measuredHeight;
            }
        }

        setMeasuredDimension(View.MeasureSpec.getSize(widthSpec), maxHeight);
    }
    ```

79. 在Android WebView中，当用户长按并选择文本时，系统会自动显示一个上下文操作栏（Contextual Action Bar，简称CAB），其中包含与所选文本相关的操作（如复制、粘贴等）。当用户点击屏幕上的其他按钮或区域时，系统会自动取消文本选择并隐藏CAB，因为这表示用户已经完成了文本选择操作并希望进行其他操作。

    这种行为是为了提高用户体验，让用户能够在完成文本选择操作后，轻松地继续进行其他操作。如果您希望在点击其他按钮时保持文本选择和CAB，请注意，这可能会导致用户界面变得混乱和难以操作。

    然而，如果您确实需要在点击其他按钮时保持文本选择，可以尝试使用JavaScript来实现。例如，您可以在WebView中注入JavaScript代码，捕获用户的文本选择操作，并在用户点击其他按钮时，使用JavaScript代码来保持文本选择。但请注意，这种方法可能会导致与原生Android体验不一致的用户界面行为。
	
80. 谷歌地图不允许隐藏Logo。

81. ffmpeg 提取第一个关键帧：ffmpeg -i <input_file> -vf "select=eq(pict_type\,I)" -vframes 1 <output_file>
82. ffmpeg 视频转图片：ffmpeg -i <input_file> "%04d.png"。
83. Android View 判断 attachToWindow 不能在 addView 之前判断。view 没 add 就不知道哪个 window。
84. 要让某张图片变色，除了自定义 View、ImageView.colorFilter，Drawable.colorFilter、ImageView.tint/tintMode 之外，还可以使用 xml。样例代码如下：

    ```xml
    <selector xmlns:android="http://schemas.android.com/apk/res/android">
        <item android:drawable="@drawable/a" />
        <item android:state_enabled="false">
            <bitmap android:src="@drawable/a" android:tint="@color/red" />
        </item>
        <item android:state_pressed="true">
            <bitmap android:src="@drawable/a" android:tint="@color/green" />
        </item>
    </selector>
    ```

85. RecyclerView 要实现点击 item 滚动，以及滑动状态监听，可以使用以下代码：

```kotlin
// 为 RecyclerView 的每个 item 增加点击监听，检测点击首个和最后一个 item 的滚动逻辑
rv.addOnItemTouchListener(object : RecyclerView.OnItemTouchListener {
    override fun onInterceptTouchEvent(rv: RecyclerView, e: MotionEvent): Boolean {
        dealItemClick(rv, e)
        return false
    }
    override fun onTouchEvent(rv: RecyclerView, e: MotionEvent) {}
    override fun onRequestDisallowInterceptTouchEvent(disallowIntercept: Boolean) {}
})
// 监听 RecyclerView 的滚动状态变化
rv.addOnScrollListener(object : RecyclerView.OnScrollListener() {
    override fun onScrollStateChanged(recyclerView: RecyclerView, newState: Int) {
        super.onScrollStateChanged(recyclerView, newState)
        // 停止了滚动
        if (newState == RecyclerView.SCROLL_STATE_IDLE) {
            dealRVStopScroll(rv)
        }
    }
})

private fun dealItemClick(rv: RecyclerView, event: MotionEvent) {
    val manager = rv.layoutManager
    if (manager !is LinearLayoutManager) {
        return
    }
    val item = rv.findChildViewUnder(event.x, event.y) ?: return
    // 点击的 item 的 index
    val clickPos = rv.getChildAdapterPosition(item)
    if (clickPos == RecyclerView.NO_POSITION) {
       return
    }

    val itemCount = manager.itemCount
    // 第一个完全可见的 item 的 index
    val firstCompletePos = manager.findFirstCompletelyVisibleItemPosition()
    // 第一个可见的 item 的 index(可能部分可见)
    val firstPos = manager.findFirstVisibleItemPosition()
    // 最后一个完全可见的 item 的 index
    val lastCompletePos = manager.findLastCompletelyVisibleItemPosition()
    // 最后一个可见的 item 的 index(可能部分可见)
    val lastPos = manager.findLastVisibleItemPosition()

    // 点击了第一个不完全可见的按钮，则滑动到第一个 item
    if (clickPos == firstPos && firstPos != firstCompletePos) {
        // 调用 scrollToPosition 方法不会触发 RecyclerView.OnScrollListener 的 onScrollStateChanged，
        // 手动显示提示布局
        isShadowHint.value = true
        rv.scrollToPosition( 0)
        return
    }
    // 点击了最后一个不完全可见的按钮，则滑动到最后一个 item
    if (clickPos == lastPos && lastPos != lastCompletePos) {
        // 调用 scrollToPosition 方法不会触发 RecyclerView.OnScrollListener 的 onScrollStateChanged，
        // 手动隐藏提示布局
        isShadowHint.value = false
        rv.scrollToPosition(itemCount - 1)
        return
    }

    // 点击的中间的 item，最后一个 item 未完全展示时显示提示
    // 停止滚动，以及点击 item 时检测是否需要显示提示布局
    isShadowHint.value = itemCount != lastCompletePos + 1
}

private fun dealRVStopScroll(rv: RecyclerView,) {
    val manager = rv.layoutManager
    if (manager !is LinearLayoutManager) {
        return
    }

    val itemCount = manager.itemCount
    // 最后一个完全可见的 item 的 index
    val lastCompletePos = manager.findLastCompletelyVisibleItemPosition()
    // 最后一个 item 未完全展示时显示提示
    // 停止滚动，以及点击 item 时检测是否需要显示提示布局
    contentViewModel.isShadowShow.value = itemCount != lastCompletePos + 1
}
```

86. ViewGroup addView 和 removeView 时要播放动画，可以使用下面的代码：

```kotlin
// 检查设置共享元素动画
private fun checkTransition(viewGroup: ViewGroup) {
    val transitionSet = TransitionSet()
    transitionSet.addTransition(ChangeBounds())
    // transitionSet.addTransition(ChangeTransform());
    // transitionSet.addTransition(ChangeImageTransform());
    transitionSet.setDuration(300); // 设置动画持续时间

    TransitionManager.beginDelayedTransition(viewGroup, transitionSet)
}
```

87. Flutter 切换版本，直接使用 git checkout 3.7.6 这种命令即可

88. 要感知 Android 的亮屏和熄屏，可以使用屏幕监听广播，或者电源管理器。

```kotlin
// 使用屏幕监听广播
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);

    // 创建并注册 BroadcastReceiver
    screenReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction().equals(Intent.ACTION_SCREEN_OFF)) {
                isScreenOn = false;
            } else if (intent.getAction().equals(Intent.ACTION_SCREEN_ON)) {
                isScreenOn = true;
            }
        }
    };
    IntentFilter filter = new IntentFilter();
    filter.addAction(Intent.ACTION_SCREEN_OFF);
    filter.addAction(Intent.ACTION_SCREEN_ON);
    registerReceiver(screenReceiver, filter);
}

@Override
protected void onDestroy() {
    super.onDestroy();
    // 取消注册 BroadcastReceiver
    unregisterReceiver(screenReceiver);
}
```

```kotlin
// 使用电源管理器
private boolean isScreenOn() {
    PowerManager powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
        return powerManager.isInteractive();
    } else {
        return powerManager.isScreenOn();
    }
}
```

89. 当Android设备旋转时，Activity会被销毁并重新创建。在这个过程中，系统会自动保存和恢复Activity的实例状态，包括传递给Activity的Intent数据。然而，系统保存的是原始的Intent数据，而不是在Activity运行过程中修改后的数据。因此，当Activity重建时，修改后的数据不会生效。为了解决这个问题，可以在Activity的onSaveInstanceState()方法中保存修改后的数据，并在onCreate()方法中恢复这些数据。

90. ViewDataBinding 的 root 就是 layout 布局文件中的最外层布局

91. 正则表达式的范例：

```kotlin
fun main() {
    val input = "[+hello+abc123+]哈哈哈哈[+gbig+3dgacd+]"
    // val input = "[+][+++]"
    // ? 代表非贪婪模式，可以解析多个。贪婪模式会解析尽可能长的字符串
    // + 代表数据至少出现一次，即非空，* 代表数据可空，如果用 *, 则 [+][+++] 也能被解析
    val regex = "\\[\\+(.+?)\\+([a-zA-Z0-9]+?)\\+\\]".toRegex()
    // val regex = "\\[\\+(.*?)\\+([a-zA-Z0-9]*?)\\+\\]".toRegex()

    val matches = regex.findAll(input)

    println("匹配成功！, size = ${input.length}, matches size = ${matches.count()}")

    println()

    matches.forEach { match ->
        println("groups = ${match.groups}, groupValues = ${match.groupValues}")
        println("matches group size = ${match.groupValues.size}\n")

        // groups = [MatchGroup(value=[+hello+abc123+], range=0..15), MatchGroup(value=hello, range=2..6), MatchGroup(value=abc123, range=8..13)]
        // groupValues = [[+hello+abc123+], hello, abc123]
        val full = match.groupValues[0]
        val one = match.groupValues[1]
        val two = match.groupValues[2]
        println("range = ${match.range}")
        println("捕获的第0个子串：$full")
        println("捕获的第1个子串：$one")
        println("捕获的第2个子串：$two")
        println()
    }
}
```

92. 在Android中，FragmentManager用于管理Fragment的添加、删除、替换等操作。在使用FragmentManager添加Fragment的过程中，不会切换线程或进程。
    Android中的UI操作都是在主线程（UI线程）中进行的，因此FragmentManager的操作也是在主线程中执行的。在进行Fragment事务操作时，需要确保在主线程中执行，否则可能会导致程序崩溃或者UI不一致的问题。
    在Android中，进程是一个应用程序的运行环境，一个进程中可以包含多个线程。FragmentManager的操作不会涉及到进程切换，因为它是在同一个应用程序的上下文中进行的

93. 在 Android 中，垃圾回收（Garbage Collection，简称 GC）是由系统的 Dalvik/ART 虚拟机自动管理的。垃圾回收的主要目的是回收不再使用的内存，以便在需要时重新分配给其他对象。垃圾回收的执行时机是由虚拟机决定的，通常在以下情况下触发：

    - 内存不足：当系统内存不足时，垃圾回收器会被触发，以回收不再使用的对象所占用的内存。
    
    - 系统空闲：当系统处于空闲状态时，垃圾回收器可能会被触发，以提前回收不再使用的内存，从而提高系统性能。
    
    - 显式调用：虽然不推荐，但开发者可以通过调用 System.gc() 方法来显式触发垃圾回收。需要注意的是，调用 System.gc() 并不保证立即执行垃圾回收，而是向系统发出一个建议，具体执行时机仍然由虚拟机决定。
    
    垃圾回收的执行时机并不确定，因此在编写 Android 应用时，开发者应尽量避免产生过多的短期对象，以减少垃圾回收的频率和影响。同时，避免在关键性能路径上执行耗时操作，以免在垃圾回收过程中导致应用卡顿。

94. 在 Android 系统中，当应用退出时，虚拟机（Dalvik/ART）不会立即被杀掉。实际上，Android 系统会尽量保留应用的进程和虚拟机实例，以便在用户再次启动应用时能够更快地加载和运行。

    当系统内存不足或需要为其他应用分配资源时，Android 系统会根据应用的优先级和状态来决定是否结束应用的进程。当应用进程被结束时，与之关联的虚拟机实例也会被销毁。

    需要注意的是，虽然虚拟机实例在应用退出时不会立即被销毁，但应用的组件（如 Activity、Service 等）和相关资源会在应用退出时被释放。因此，在编写 Android 应用时，开发者应确保在组件的生命周期方法中正确地管理资源，以避免内存泄漏和其他潜在问题。

95. Android 使用的垃圾回收算法随着虚拟机的演进而发生了变化。在早期的 Android 版本中，Dalvik 虚拟机主要使用了分代垃圾回收（Generational Garbage Collection）和标记-清除（Mark-Sweep）算法。从 Android 5.0（Lollipop）开始，Android 引入了 ART（Android Runtime）虚拟机，它采用了更先进的垃圾回收算法，包括标记-清除-整理（Mark-Sweep-Compact）和并发垃圾回收（Concurrent Garbage Collection）。

    以下是 Android 垃圾回收算法的简要概述：

    分代垃圾回收（Generational Garbage Collection）：这种算法将内存分为不同的代（如新生代、老年代等），并根据对象的生命周期将其分配到不同的代中(新生代和老年代的内存比通常是:8:1，永久代在高版本已被移除)。新创建的对象通常分配到新生代，经过多次垃圾回收仍然存活的对象会被提升到老年代。分代垃圾回收的优势在于可以针对不同代采用不同的回收策略，从而提高垃圾回收的效率。

    标记-清除（Mark-Sweep）：这种算法首先标记所有从根对象（如全局变量、线程栈中的局部变量等）可达的对象，然后清除所有未被标记的对象。标记-清除算法的缺点是在回收过程中会产生内存碎片，可能导致后续内存分配的效率降低。

    标记-清除-整理（Mark-Sweep-Compact）：这种算法在标记-清除的基础上增加了整理（Compact）阶段，将存活的对象移动到内存的一端，从而消除内存碎片。这种算法可以提高内存分配的效率，但在整理阶段可能会产生较大的性能开销。

    并发垃圾回收（Concurrent Garbage Collection）：这种算法允许垃圾回收器在应用线程运行的同时进行垃圾回收，从而减少垃圾回收对应用性能的影响。并发垃圾回收需要虚拟机和应用线程之间进行协同，以确保在回收过程中不会出现数据不一致的问题。

    随着 Android 系统的发展，垃圾回收算法也在不断优化，以提高垃圾回收的效率和减少对应用性能的影响。

96. Java 中，String 底部使用 Array 存储，Array 的最大长度为 Integer.MAX_VALUE。为 65535。

97. View.dispatchKeyEvent 事件会在有焦点的 View 路径上分发。如果目标 View 无焦点，则分发不成功。解决方案是在调用 View.dispatchKeyEvent 之前，先申请下焦点 View.requestFocus()

98. 调用 InputMethodManager.toggleSoftInput 显示键盘时，不能重复调用，否则已显示的键盘会被隐藏。
    ![InputMethodManager_toggleSoftInput方法说明](/imgs/InputMethodManager_toggleSoftInput方法说明.webp)

99. Android 的进程保活方案有：
    - 前台服务（Foreground Service）：通过将应用设置为前台服务，可以提高其优先级，使其不容易被系统杀死。前台服务会在通知栏显示一个通知，告知用户应用正在运行。

    - 双进程守护：创建两个进程，一个用于运行应用的主要功能，另一个用于监控主进程。当主进程被杀死时，守护进程会重新启动主进程。

    - JobScheduler：使用 JobScheduler 定时执行任务，可以在特定条件下（如网络可用、设备充电等）触发应用的运行。

    - 利用系统广播：监听系统广播（如网络状态变化、屏幕解锁等），在接收到广播时启动应用。

    - 账户同步（Account Sync）：通过创建一个同步适配器，将应用与系统的账户同步功能关联，定期执行同步操作，从而保持应用进程的活跃。

    - 利用第三方推送服务：使用第三方推送服务（如极光推送、个推等）保持应用进程的活跃。

    - 1像素 Activity：在应用进入后台时，启动一个 1 像素的 Activity，使应用保持在前台状态，降低被系统杀死的概率。

    - 使用 AlarmManager：使用 AlarmManager 定时唤醒应用，保持进程的活跃。

    - 利用系统漏洞：在某些 Android 系统版本中，可能存在一些漏洞可以用于保活。但这种方法并不稳定，且可能在新版本系统中失效。

100. TextView 中，MovementMethod 和 OnClickListener 同时设置时，会冲突。MovementMethod.onTouchEvent 方法即使返回 true，也无法阻止 TextView 的 OnClickListener 执行，因为 View.onTouchEvent 方法会先于 MovementMethod 执行。需要解决二者的冲突，MovementMethod 可以继承自 MovementMethod。注意系统提供的LinkMovementMethod在选中时，会选中点击区域，想要干掉，就需要自定义。TextView 设置了 MovementMethod 后，会更改 focusable 等属性的值。
    ![TextView的OnTouchEvent和Movement冲突](/imgs/TextView的OnTouchEvent和Movement冲突.webp)

101. Android 5.0(API级别21)以上，可以使用以下代码设置底部导航栏颜色：

   ```java
   protected void onCreate(Bundle savedInstanceState) {
       super.onCreate(savedInstanceState);
       setContentView(R.layout.activity_main);

       if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
           Window window = getWindow();
           window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
           window.setNavigationBarColor(ContextCompat.getColor(this, R.color.your_color));
       }
   }
   ```

   Android setnavigationBarColor 没生效的原因可能有：

   1. 低版本 Android 系统不支持：setNavigationBarColor 方法是在 Android 5.0（API 级别 21）引入的。如果你的设备运行的是低于 5.0 的 Android 版本，该方法将不起作用。你可以通过检查当前设备的 API 级别来处理这种情况：

        ```java
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setNavigationBarColor(Color.RED);
        }
        ```

   2. 应用主题设置了 android:windowTranslucentNavigation：如果你的应用主题设置了 android:windowTranslucentNavigation 为 true，则 setNavigationBarColor 可能不起作用。你需要将其设置为 false：

       ```xml
       <item name="android:windowTranslucentNavigation">false</item>
       ```

   3. 应用主题设置了 android:navigationBarColor：如果你的应用主题已经设置了 android:navigationBarColor，则在运行时调用 setNavigationBarColor 可能不会覆盖主题中的设置。你可以尝试在主题中删除 android:navigationBarColor 设置，或者更改其值。
   
   4. 系统 UI 可见性设置：如果你的应用更改了系统 UI 可见性设置，例如设置了沉浸式状态栏或全屏模式，这可能会影响导航栏颜色。你需要确保在设置导航栏颜色时不使用这些模式。

   5. 设备制造商定制的 Android 系统：某些设备制造商可能会对 Android 系统进行定制，导致 setNavigationBarColor 方法不起作用。在这种情况下，你可能无法解决这个问题。

   如果以上方法都无法解决问题，请检查你的代码是否正确调用了 setNavigationBarColor 方法，并确保在设置导航栏颜色之前已经正确初始化了窗口。

102. 在 Android 中，当两个视图或者一个视图的两个背景色叠加在一起时，它们的颜色会根据各自的透明度（alpha 值）进行混合。这个过程称为 alpha 合成（alpha compositing）。

    假设有两个颜色，分别是前景色（RGBA1）和背景色（RGBA2），它们的颜色值可以表示为：

        RGBA1 = (R1, G1, B1, A1)

        RGBA2 = (R2, G2, B2, A2)

        其中 R、G、B 分别表示红、绿、蓝三原色的值，A 表示透明度。这些值的范围通常在 0 到 1 之间。

    当这两个颜色叠加时，可以使用以下公式计算它们的混合颜色（RGBA）：
    
        计算 alpha 值：A = A1 + A2 * (1 - A1)
        
        计算红、绿、蓝三原色的值：R = (R1 * A1 + R2 * A2 * (1 - A1)) / A G = (G1 * A1 + G2 * A2 * (1 - A1)) / A B = (B1 * A1 + B2 * A2 * (1 - A1)) / A

        最后，混合后的颜色值为：RGBA = (R, G, B, A)

    这个过程会逐层进行，直到所有叠加的颜色都被合成为一个最终的颜色值。在 Android 中，这个过程由系统的绘图框架（如 OpenGL ES 或者 Vulkan）自动处理。

103. Android中的startService和bindService是两种启动Service的方式，它们之间有一些区别：

    启动方式不同：
    
        startService：通过调用Context的startService()方法启动Service。这种方式启动的Service，会在后台长期运行，即使启动它的组件已经被销毁，Service仍然会继续运行。
        
        bindService：通过调用Context的bindService()方法启动Service。这种方式启动的Service，与启动它的组件绑定在一起，当启动它的组件被销毁时，Service也会被销毁。

    生命周期不同：

        startService：Service的生命周期与启动它的组件无关，只要没有调用stopService()或stopSelf()，Service就会一直运行。

        bindService：Service的生命周期与启动它的组件绑定在一起，当所有与之绑定的组件都被销毁时，Service也会被销毁。

    通信方式不同：

        startService：启动Service后，组件与Service之间通常通过Intent传递数据，但是Service无法直接返回结果给组件。
        
        bindService：启动Service后，组件与Service之间可以通过IBinder接口进行双向通信，Service可以直接返回结果给组件。

    使用场景不同：

        startService：适用于需要在后台长期运行的任务，例如下载、播放音乐等。

        bindService：适用于需要与组件进行交互的任务，例如获取数据、执行操作等。
    
    总之，startService和bindService在启动方式、生命周期、通信方式和使用场景上都有所不同，根据实际需求选择合适的方式启动Service。

104. View 的 padding 不会影响 background 的填充，margin 会影响 background 的填充。

105. Android SurfaceView、TextureView、GLSurfaceView、GLTextureView 的区别：

    SurfaceView：

        SurfaceView 是一个提供绘制图形的视图，它拥有一个独立的绘图表面，不与主线程共享。

        SurfaceView 的绘制操作在一个单独的线程中进行，因此不会阻塞主线程，适用于需要高性能绘制的场景，如视频播放、游戏等。

        SurfaceView 不支持 View 层级中的动画和透明度变化。

        SurfaceView 的刷新频率不受系统限制，可以实现高帧率的绘制。

    TextureView：

        TextureView 是一个支持硬件加速的视图，它可以将内容绘制到一个硬件纹理中。

        TextureView 可以在主线程中进行绘制，也可以在单独的线程中进行。

        TextureView 支持 View 层级中的动画和透明度变化。

        TextureView 适用于需要与其他 View 共享层级关系的场景，如视频播放、动画等。

    GLSurfaceView：

        GLSurfaceView 是一个基于 OpenGL ES 的 SurfaceView，它提供了一个 OpenGL ES 的渲染环境。

        GLSurfaceView 的绘制操作在一个单独的线程中进行，因此不会阻塞主线程。

        GLSurfaceView 支持 OpenGL ES 的各种特性，如 3D 图形、纹理映射等。

        GLSurfaceView 适用于需要使用 OpenGL ES 进行高性能绘制的场景，如 3D 游戏、图形处理等。

    GLTextureView：

        GLTextureView 是一个结合了 TextureView 和 GLSurfaceView 特点的视图，它提供了一个 OpenGL ES 的渲染环境，并将内容绘制到一个硬件纹理中。

        GLTextureView 可以在主线程中进行绘制，也可以在单独的线程中进行。

        GLTextureView 支持 View 层级中的动画和透明度变化。

        GLTextureView 适用于需要使用 OpenGL ES 进行绘制，并与其他 View 共享层级关系的场景，如 3D 动画、图形处理等。

    总结：

        SurfaceView 和 TextureView 主要用于 2D 图形绘制，其中 SurfaceView 更适用于高性能绘制，而 TextureView 更适用于与其他 View 共享层级关系的场景。
        
        GLSurfaceView 和 GLTextureView 主要用于 3D 图形绘制，其中 GLSurfaceView 更适用于高性能绘制，而 GLTextureView 更适用于与其他 View 共享层级关系的场景。

106. EditText设置弹出键盘时，Activity 根布局需要设置 "android:fitsSystemWindows="true" 属性，并且在 AndroidManifest.xml 中给 Activity 设置 "android:windowSoftInputMode="adjustResize"。

107. java.net.URL 类构造时会进行 dns 解析，如果 url 无效，则会抛异常。可以通过构造 java.net.URL 类的方式判断 url 是否有效。此方案仅对网络链接有效。

108. Android 中要设置竖向渐变的，可以使用以下代码。

```kotlin
// 设置竖向渐变色
GradientDrawable(GradientDrawable.Orientation.BOTTOM_TOP, intArrayOf(startColor, endColor)).apply {
    gradientType = GradientDrawable.LINEAR_GRADIENT
    view.background = this
}
```

109. native debug 的部分知识点：
    - 符号（Symbol）常用来表示一个地址，这个地址可能是一端程序的起始地址，也可能是一个变量的起始地址，简而言之，将它当做是标记或名称即可。
    - 链接过程中，我们将 函数 和 变量 统一称作为符号，函数名与变量名称就是符号名，其记录的地址信息就是其符号值。
    - strip操作：在linux中，strip有脱衣服的含义，具体就是从特定文件中剥掉一些符号信息和调试信息。strip后，文件会变小，其中的符号信息会失去。输出时会只有内存地址。
    - android中可以通过以下代码禁用 strip 操作：`android { packagingOptions { doNotStrip "*/*/libxxx.so" }`。
    - 当在local.properties中配置ndk.dir，或者设置ANDROID_NDK_HOME时，可以让Android studio知道ndk路径的时候,此时构建系统会增加一个名为transformNativeLibsWithStripDebugSymbolForXXX的任务, 这个任务会执行strip so 操作,当没有设置 ndk 路径的时候就不会进行strip so。
    - addr2line：addr2line是用于将程序的地址转换为源代码中的文件名和行号的工具，通常用于调试和分析崩溃日志。addr2line的用法为 `addr2line -f -e libmylibrary.so 0x12345678`。-f 选项表示输出函数名。-e 选项后面跟的是要解析的可执行文件或共享库的路径。结果会输出形如：`my_function   /path/to/source/file.cpp:42` 的内容，表示在 my_function 函数中，崩溃发生在 /path/to/source/file.cpp 文件的第 42 行。
    - LLDB：在Android开发中，LLDB 是一个强大的调试器，主要用于调试 C、C++ 和 Objective-C 代码。它是 LLVM 项目的一部分，旨在提供高效的调试功能，支持多种平台和编程语言。而 gdb 是基于 gcc 的，在Android中，高版本目前已弃用，低版本设备上可能会用到。
    - Android手机中有个debuggerd进程，当发生Native Crash，系统会自动调用debuggerd来将信息dump到tombstone文件中。另外也可以主动执行debuggerd(前提是手机要root，可能还需要关闭selinux)。debuggerd可以直接打印native调用栈，用法是`debuggerd [-b] PID`。
    - `int my_counter __attribute__((aligned(8)))`用于给my_counter变量分配的内存块添加的监视点。我们必须将变量的内存地址边界分别按照 4 字节（对于 32 位处理器）或 8 字节（对于 64 位处理器）对齐。