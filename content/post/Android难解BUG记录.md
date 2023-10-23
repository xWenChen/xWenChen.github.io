---
title: "Android难解BUG记录"
description: "本文记录了作者在Android日常开发中碰到的已解的或未解的BUG"
keywords: "Android,BUG记录"
weight: 1

date: 2021-02-21 18:08:00 +08:00
lastmod: 2021-02-21 18:08:00 +08:00

categories:
  - Android
tags:
  - Android

url: post/10427F5683084886867B43F21F6C1736.html
toc: true
---

本文记录了作者在Android日常开发中碰到的已解的或未解的BUG。

<!--More-->

**注：本博客不定期更新**

1. Window失去焦点，导致点击事件无法分发。进而导致点击界面无反应。操作方式是：点击进入下个 Activity 时，迅速按下电源键息屏(下个 Activity 刚走到 onCreate)，然后再次打开手机，下个 Activity 就失去焦点了，所有点击事件都无效了(系统的回退键还能用)。
2. 裁剪方式不一致，图片大小不一致。导致转场动画后的View显示闪动
3. activity 主题不同，导致状态栏和虚拟导航栏未记录在内，导致的测量有误差，出现的 BUG
4. 繁体的标点一般字体是默认居中的。并且引号不是 ""，而是「」(或者『』)
5. Dialog 和 Activity 的生命周期关系，以及焦点问题，导致的键盘隐藏问题(需要梳理源码)
6. EditText 的焦点问题与系统软键盘的隐藏、显示
7. 从当前聊天界面，进入另一个聊天界面(会话不同，Activity 是一样的)，如果是走通知栏，并且是 SingleTask，则不会走 onCreate 方法。相关初始化操作需要放在 onNewIntent 中执行。
8. 对于标准的 Android 系统的通知栏，通常**左边(或者左上角)是通知栏的大图标，右边(或右下角)是通知栏的小图标**。但是对于国内的厂商，通常定制了系统，通知栏的样式有所区别。比如华为手机的通知栏，图标是小图标。而小米手机的图标就是大图标。Android 原生系统的设计中，小图标默认不支持彩色(官方建议使用灰色)，大图标随意。而国内的厂商，因为定制的原因，小图标可能也支持彩色，此时如果设置灰色的话，可能就会有用户投诉。这点应注意。同时，同一手机的不同系统版本，通知栏样式也有可能不同。这也是值得注意的一点，不太会引起 BUG，但是可能会有用户投诉。
9. 系统不返回 UP 事件，在 Activity 的事件分发方法上加监听，发现的。
10. SortedList 方法缺少如 contains, replace, removeAll 等一般列表都有的方法。导致集合的交集、并集、差集等的处理有付出额外的精力。
11. 排查权限申请的不合规之处(合规调整)。发现百度的语音转文字 SDK，在不授予录音权限的情况下，无法将语音文件中的内容转成文字。经过日志分析，发现是在未授权的情况下，直接结束了转译的过程。遂明白百度 SDK 虽没有申请录音权限，但仍然有检查权限的操作。这个问题导致了用户反馈。经过讨论，确定了修改方案。下面先讲思路与原理。
- 首先我们应该知道，Context 有检查权限的方法。其中最主要的就是 `checkPermission`，`checkSelfPermission`。而我们检查权限，通常都会通过传入的 Context 检查。这就给了我们操作的空间。
- 思路如下。创建一个假的 Context，命名为 `BDFakeContext`，继承自 `ContextWrapper`，从名称便可知，是专门用来处理百度的这个问题的。此处也建议专人专事。其他 SDK 有问题，也一样建个新类，而不是重复使用一个类。
- 下面贴上完整代码：

```java
public class FakeContext extends ContextWrapper {
    public FakeContext(Context base) {
        super(base);
    }

    @Override
    public Context getApplicationContext() {
        return this;
    }

    @Override
    public int checkPermission(String permission, int pid, int uid) {
        // 如果是检测音频权限，则不管有没有授权，直接返回已授权
        if(Manifest.permission.RECORD_AUDIO.equals(permission)) {
            return PackageManager.PERMISSION_GRANTED;
        }
        return super.checkPermission(permission, pid, uid);
    }
}
```

然后用上这个类：

```java
public class BDManager {
    private BDSDKManager m;
    public BDManager(Context context) {
        // 传入 SDK 的地方包装一次，就是这么简单
        m = new BDSDKManager(new FakeContext(context));
    }
}
```

- 但是，很不幸的是，没改好。反编译了源码，发现百度检查权限，调用的不是 `checkPermission` 方法，而是另一个 `checkCallingOrSelfPermission` 方法，这就好办了。依葫芦画瓢。

```java
// 省略部分代码
 @Override
public int checkCallingOrSelfPermission(String permission) {
    // 如果是检测音频权限，则不管有没有授权，直接返回已授权
    if(Manifest.permission.RECORD_AUDIO.equals(permission)) {
        return PackageManager.PERMISSION_GRANTED;
    }
    return super.checkCallingOrSelfPermission(permission);
}
```

这次的结果就很 OK 了。又学到了一招，专门对付第三方 SDK 的权限检查。

12. 列表布局，最好不要加入什么特殊的头部布局，因为指不定中间又要插入什么东西。单独添加头布局，不利于扩展。当然视情况而论，下拉刷新啥的是可以加的。
13. 设想有个场景，有个 Activity A，如果某个外设操作，导致 Activity 之上，弹出了一个 dialog，此时没有 View 消费事件。那么事件会被 dialog 消费，而走不到 Activity A 那里，此时需要给 dialog 添加标志位，则可以让 dialog 不消费事件，事件继续下传。并且设置了以下代码之后，弹出 dialog，并不会引起 Activity 的焦点变化，即`onWindowFocusChanged`方法不会调用。代码如下：

```java
getWindow().addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE);
getWindow().addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL);
```

14. 对于不同尺寸的设备，不同屏幕大小的设备。要想图片缩放不失真，而又至少一边填充 ImageView，则可以用下面代码计算宽高，并给 ImageView 设置计算出来的宽高，然后在显示图片时给图片重设大小(不重设也行，ImageView 的裁剪方式可设置成 FIT_XY)。

```java
private void resizeImageView(ImageView imageView, String path) {
    // 只解码图片大小，不解码图片数据
    BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = true;
    BitmapFactory.decodeFile(path, options);
    // 屏幕宽高
    int screenWidth = ScreenUtil.getScreenWidth(imageView.getContext());
    int screenHeight = ScreenUtil.getScreenHeight(imageView.getContext());
    // 屏幕与图片的宽高比例
    float widthRatio = (float)screenWidth / options.outWidth;
    float heightRation = (float)screenHeight / options.outHeight;
    
    int finalWidth = options.outWidth;
    int finalHeight = options.outHeight;
    // 1. 如果图片小于屏幕尺寸，则取较小值
    if(widthRatio > 1 && heightRation > 1) {
        float minRatio = Math.min(widthRatio, heightRation);
        // 图片长宽扩大这个倍数
        finalWidth = (int)(options.outWidth * minRatio);
        finalHeight = (int)(options.outHeight * minRatio);
    } else if (widthRatio < 1 || heightRation < 1) {
        // 2. 如果图片大于屏幕尺寸，则取较大值
        float maxRatio = Math.max(widthRatio, heightRation);
        // 图片长宽缩小这个倍数
        finalWidth = (int)(options.outWidth / maxRatio);
        finalHeight = (int)(options.outHeight / maxRatio);
    }
    // 有相等的情况则不管，view 的尺寸，glide 的 resize，赋值finalWidth，finalHeight
    ViewGroup.LayoutParams layoutParams = imageView.getLayoutParams();
    layoutParams.width = finalWidth;
    layoutParams.height = finalHeight;
    imageView.setLayoutParams(layoutParams);
}
```

15. 头条 SDK 引入后，可能会被检测出含有广告插件，引入需慎重。
16. EditText 有焦点，并且键盘被隐藏，在退出界面重新进入时，会再次弹出焦点，可能会造成布局异常。Android 端微信在退出时，会清除 EditText 的焦点。可以参考这种做法。
17. 现有一个语音按钮，功能是按钮区域内松开，即发送语音，区域外松开是取消发送。测试两个手指按下，一个在区域内，一个在区域外，松开区域内的手指，文本不更新。经查，是因为松开手指时，ACTION_POINTER_UP 仍然会带两个手指的信息，而区域内的手指如果 Index 是 0，则按照老的逻辑，判断 rawX，rawY 的位置，则手指仍在区域内，导致更新错误，解决办法是遍历所有按下的时候，判断按下的手指是否在区域内，代码如下：
```java
case MotionEvent.ACTION_POINTER_UP:
    // 多指事件，只判断 rawX，rawY 不准确，判断所有手指的区域
    boolean isInRecordArea = false;
    for(int i = 0; i < motionEvent.getPointerCount(); i++) {
        if(motionEvent.getActionIndex() == i) {
            // 跳过抬起的手指的计算
            continue;
        }
        if(isInRecordArea(recordView, motionEvent.getX(i), motionEvent.getY(i))) {
            // 有手指在区域内，就够了
            isInRecordArea = true;
            break;
        }
    }
    return getRecordCallback().updateRecordState(isInRecordArea, DeviceType.DEFAULT);
```

18. APP的混淆主要包括以下几个方面：
   
    - Android 系统的四大组件/View/自定义 View/Manifest文件不能被混淆，但 Android Studio 会帮我们处理，我们不需要单独配置。
    - 在反射中用到的类、方法、字段，不能被混淆
    - Native 方法必须和 JNI 中的方法同名，不能被混淆
    - 可以序列化的类型、方法、字段，不能被混淆
    - 枚举不能被混淆
    - WebView 和 JS 接口，不能混淆
    - 回调的相关监听类、方法、字段，建议不要混淆。
    - 资源文件不能被混淆
    - 注解、泛型不能混淆
    - 被打上 `android.support.annotation.Keep` 注解的内容，不能被混淆
    - 三方库指定的混淆规则

19. canvas 画圆时，需要注意圆的实际半径是 radius + strokeWidth，即需要额外加上画笔的宽度。画任何图形，计算尺寸时，都需要考虑 画笔的宽度 是否有影响。
20. Android 系统中，屏幕触摸事件和键盘按键事件是两个不同的事件流。前者是 MotionEvent，后者是 KeyEvent。如果前者的事件流还没有结束，就来了后者的事件，则中间会被插入一个 cancel 事件。即 MotionEvent ---> CancelEvent ---> KeyEvent。如果要交叉两个事件流，需要忽略掉 Cancel 事件(Cancel 事件无法判断事件源，只能忽略)，这可能会导致其他很多的异常场景无法处理(比如三指按下后，系统下发了 Cancel 事件啥的，当然也与系统魔改有关)。需要注意。
21. Android 文件系统的目录结构大致如下：
   ![Android文件系统的目录结构](/imgs/Android文件系统的目录结构.png)
22. Home 键虽然无法被`onKeyDown`、`onKeyUp`监听到，但是可以通过广播知道 Home 键被按下了，代码如下：
   ```java
   private void initHomeKeyReceiver() {
       IntentFilter homeKeyFilter = new IntentFilter(Intent.ACTION_CLOSE_SYSTEM_DIALOGS);
   
       BroadcastReceiver homeKeyEventReceiver = new BroadcastReceiver() {
           @Override
           public void onReceive(Context context, Intent intent) {
               judgeAndDealHomeKeyEvent(intent);
           }
       };
   
       registerReceiver(homeKeyEventReceiver, homeKeyFilter);
   }
   
   private void judgeAndDealHomeKeyEvent(Intent intent) {
       if(presenter.isCurrentConversationNull()) {
           return;
       }
   
       String action = intent.getAction();
       LogUtil.d(TAG, "action: " + action);
       if(!Intent.ACTION_CLOSE_SYSTEM_DIALOGS.equals(action)) {
           return;
       }
   
       String reason = intent.getStringExtra("reason");
   
       if(reason == null) {
           return;
       }
       if(reason.equals("homekey") // 点击 Home 键
          || reason.equals("recentapps") // 长按 Home 键
         ) {
           doSomething();
       }
   }
   ```
23. 当按键事件触发时(KeyEvent)，如果此时按下 Home 键，则系统会自动触发按键的 UP 动作，即使按键并没有被松开。这是因为按下 Home 键之后，窗口的焦点发生变化，焦点变化导致事件触发，即 KeyEvent(Action up) ---> Home 键生效 ---> Activity onPause ---> Home 键广播生效 ---> Activity.onWindowFocusChanged() ---> Activity onStop。经过确认，有 UP 事件是因为 KeyEvent 没有 CANCEL 事件，所以失去焦点时，如果 KeyEvent 事件未结束，会发出 UP 事件，来结束掉 KeyEvent 事件流。这种情况下，系统工程师(Framework 层工程师)无法将 UP 事件替换成 CANCEL 事件(至少我求助的工程师不能)。
24. ScrollView 嵌套 ListView 会导致 ListView 只显示 1 行数据。解决方法之一是将需要和 ListView 一起滚动的上方或者下方布局，作为 header/footer 添加到 ListView 中，而不是一起塞入 ScrollView 中。
25. ListView 添加头布局时，会忽略 Margin，因为 ListView 的 LayoutParam 中并没有定义 margin，所以如果需要实现 Margin 效果，可以添加空白的 View 作为 Header，用来表示为 margin。或者在实际布局外再套一层布局(内层布局就可以加 margin 了)。
26. ListView 的动画也是个大坑，建议不要用 ListView。
27. Android 11(API 30) 读取网络状态(getDataNetworkType()/getNetworkType())，需要 READ_PHONE_STATE 权限。
28. 自己应用的各种文件，最好存在自己的目录下，存在系统目录下，可能会导致系统系统判定你删除系统文件(如拼多多被 VIVO 警告擅自删除系统文件)。
29. 应用的内部目录，会根据机型设备的不同而不同，并不一定是 "/data/data/包名" 目录。这个会根据系统支不支持多用户而变化，如果支持多用户，则可能不是这个目录，如果是单用户，可能厂商会内部处理，创建软连接，"/data/data/包名" 指向特定的目录。
30. 一个线程占 1040KB(1 M)，创建过多线程，可能导致 OOM。
31. bindService 失败的一个原因是包名不一致。
32. 透明背景，可能导致RecyclerView滚动时，绑定布局异常。也有可能导致其他的一些异常刷新问题。
33. 查了两天，终于解决了 fresco 解析部分 Gif 时，会闪烁的问题。相同的问题，使用 Android 原生方法解析则不会闪烁。设置一下解码器就行了。Android 原生的方法主要是：高版本(API >= 26)用 AnimatedImageDrawable 解析，低版本(API < 26)用 Movie 解析。两者都不会出现闪烁的问题。首先明确，fresco 加载 Gif。主要是有两种途径：一是借助 giflib 库在 Native 层进行解码，这个是 Fresco 默认的解码方式，另外一个就是使用 GifDecoder，GifDecoder 使用的是 Android 系统提供的 Movie 类解码 Gif。两种不同的解码方式涉及到不同的包。一般的GIF引入 animated-gif 这个包就够了，但是出现闪烁的 GIF，需要使用 GifDecoder 解码，GifDecoder 位于 animated-gif-lite 包下，所以需要把这两个包都导入，并指定解码 GIF 的解码器。代码如下：

```java
ImageRequest request = ImageRequestBuilder.newBuilderWithSource(uri)
    .setProgressiveRenderingEnabled(true)
    .setRotationOptions(RotationOptions.autoRotate())
    .setImageDecodeOptions(ImageDecodeOptions.newBuilder()
        // 手动指定 GIF 的解码器，Fresco 的版本是 2.3
        // 低版本GifDecoder构造函数入参可能不同，含义可以看源码注释
        .setCustomImageDecoder(new GifDecoder())
        // 优先加载GIF的第一帧
        .setDecodePreviewFrame(true)
        .build())
    .build();
```

34. 引入单测框架后，如果使用反射遍历对象的所有字段，可能会多出来一个`$jacocoData`字段。这个字段，不加判断的话，可能解析不了，进而导致功能异常。有几种解决方式：1 是使用的地方 try-catch，2 是使用`Field.isSynthetic()`方法过滤，这个方法标识字段是否是合成字段。`$jacocoData`字段是合成字段，可以过滤。
35. Android gradle 中，maven 插件分为两个，旧版 maven 插件和新版 maven publish 插件。旧版 Maven 插件会自动生成 pom.xml 文件及其依赖信息，新版不会，新版插件需要自己添加 pom.xml 里的依赖信息。但 Android gradle plugin 自动生成了 pom.xml 的依赖信息，简化了我们的工作，我们可以直接使用，不需要手动添加(详情见https://juejin.cn/post/7017608469901475847)。如果手动添加，可能会会导致问题，比如说：如果上传二方库时， pom 里只手动添加了 api 相关的三方库依赖，则 implementation 及其他相关的三方库依赖会丢失。以 implementation 为例，这会导致主工程在运行时，报 NoClassDefException 或者 ClassNotFoundException。但实际上，虽然 implementation 编译时不会导入，但运行时是会导入的。并不应该出现这种问题。这就是手动添加 pom 中的依赖配置，导致了 implementation 等配置项丢失。如果不熟悉或者没遇到过的人。肯定会第一时间怀疑官方文档有误，但实际上官方文档无误，是自己写的 maven 插件有问题。
36. Doraemon Kit 会拦截网络请求，导致异常(DoraemonIntercept 拦截错误，返回 400 的错误码)；并且会注入布局，导致 UI 异常，常见的一个场景就是 EditText 和软键盘；可能会出现 EditText 无焦点(光标)，但键盘弹出的场景；或者键盘不自动弹出的场景。
37. `view.setTypeface(view.typeface, style)` 使用时，view.typeface 作为首参传入，可能会导致字体效果不及预期。可传入 null 进行纠正。
38. ViewPager 使用 setCurrentItem(int item, boolean smoothScroll) 切换 item 时，如果第二个参数传入 true，可能导致页面闪烁。这是 ViewPager 的切换闪烁 Bug。
39. ViewPager 嵌套 ViewPager 时，想要滑动时响应外层 tab 栏，只需要设置以下代码即可: 
   ```kotlin
   class CustomViewPager @JvmOverloads constructor(
       context: Context, 
       attrs: AttributeSet? = null
   ) : ViewPager(context, attrs) {
       private var horizontalScrollable = true

       override fun onInterceptTouchEvent(ev: MotionEvent?): Boolean {
           if (horizontalScrollable) {
               return super.onInterceptTouchEvent(ev)
           } else {
               return false
           }
       }

       fun setHorizontalScrollable(enabled:Boolean) {
           horizontalScrollable = enabled
       }

       override fun canScrollHorizontally(direction: Int): Boolean {
           return if(horizontalScrollable) {
               super.canScrollHorizontally(direction)
           } else {
               false
           }
       }
   }
   ```

40. 调用 hide/show 切换 fragment，并不会触发 fragment 的生命周期变化，而是走 onHiddenChange 这个方法
41. CardView 有自己的属性，比如背景色，半径等等，使用 CardView 时应注意这个点，一个常用的使用模版是：
```xml
<androidx.cardview.widget.CardView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        app:cardBackgroundColor="@color/transparent"
        app:cardElevation="0dp"
        app:cardCornerRadius="@dimen/radius">
    <!-- 这里填充布局 -->
    
    <!-- 说明：
            1. cardBackgroundColor 才能设置 CardView 背景色透明，单纯 background 无效
            2. cardElevation 为 0 可以设置 CcardView 无边界
      -->
</androidx.cardview.widget.CardView>
```

42. xml 中定义 shape-gradient 渐变色 drawable 时，必须为其设置形状和 size，否则加载时可能出错。drawable 默认的尺寸为 -1，转 bitmap 或者用 glide 加载都会出错。用 glide 加载时，如果不想设置尺寸，则可以使用 centerCrop 等进行裁剪变换。
43. 图片比例、ImageView的ScaleType、Glide 的裁剪方式，混用时可能会导致圆角等形状缺失，此时需要调整图片的比例。
44. 图片上的圆角比代码裁的大，会导致圆角缺失(不平滑)。
45. SubsamplingScaleImageView 加载 HEIC 图片时，会有问题。需要做特殊设置。
46. Fragment 中，如果使用 childFragmentManager 展示 DialogFragment，大概率会出现闪退。此时的解决方案为，使用 activity 的 supportFragmentManager，并延迟展示。代码如下：

```kotlin
fragment.view?.post { // post 保证 FragmentTransaction 执行完成
    activity?.apply {
        // DialogFragment.show(fragmentManager: FragmentManager, tag: String)
        dialog.show(supportFragmentManager, "exit")
    }
}
```

47. 腾讯云人脸识别SDK(地址：https://cloud.tencent.com/document/product/1007/)，如果手机被 root 过，可能刷脸刷不过。存在系统劫持的风险，会被腾讯云的设备指纹拦截。
48. 目前没有百分百靠谱的方式，用于检测手机是否被 root 过。并且执行 su 命令可能导致 应用变卡。详见问题下 Devrim 的回答(第三个回答)：https://stackoverflow.com/questions/1101380/determine-if-running-on-a-rooted-device。
49. ffmpeg cut 视频，可能会出现音视频不同步的问题(被重编码了，音频或者视频有 delay)，在裁剪时不能重编码(re-encode)。
50. Android 系统 MediaStore 识别 mimeType 是根据文件后缀名来的，zip 的文件改为 jpg 后缀，也会被识别为 jpg 图片。
51. Android 项目同一个分支，一台电脑编的过，一台编不过。如果是 kapt 相关的问题![kapt编译相关问题](/imgs/kapt编译相关问题.png)
可以试试注掉 gradle.properties 中的代码：`kapt.use.worker.api=false`
52. fragment 可能不会走到 onResume 方法，具体原因待排查
53. 使用 DataBinding 时，@BindingAdapter 注解中属性声明的顺序，必须和方法里入参的声明顺序一样，否则会报错
54. Android 多工程组件化，依赖管理方式不会，就容易出现：java.lang.NoSuchMethodError。原因为：
   - Android 组件化后，出现了基础组件模块(base)、聊天模块(chat)和 App 主工程。
   - base 模块被 chat 模块和 App 主工程同时依赖。如果更改了 base 模块的函数(如增加了参数)并替换了 App 主工程的依赖，但并未替换 chat 模块的依赖。而该函数被 chat 模块和 app 主工程同时使用。
   - 因为 chat 模块的依赖并未更新，所以相关 kt 文件生成的 class 文件中，仍然引用的未更改的旧函数。app 主工程更新了依赖，所以是新的函数。
   - 因为 chat 模块的依赖并不会更随社区模块传入到主工程，所以主工程不会出现依赖冲突。chat 模块的 class 在 app 主工程中引用的就是新的函数(包名，类名，方法名相同)，能够编译通过(此时 chat 模块已是编译过的 class，不会重新编译源码)。
   - 在 app 实际运行过程中，定位函数时才会出错(chat 使用的旧函数，但定位到了新函数，所以报了 NoSuchMethodError)
55. 协程和 Flow 混用，可能导致 scope 的异常处理机制独自处理异常，然后出现在 scope 外捕获不到的崩溃
56. ConstraintLayout 中布局约束如果不写全，可能导致 item 显示不全
57. WebView 调用 addJavaSctiptInterface 方法添加的 javaScript 对象，当页面未重新加载时，并不会生效。如果 WebView 被缓存了以保证不重复加载网页，则下次重新进入页面后，重复注册新的 js 对象不会生效，这会导致 web 端调用客户端的方法失效，出现业务异常。所以缓存 WebView 需谨慎。

58. 在使用 Bitmap.compress() 方法时，如果格式选择为 Bitmap.CompressFormat.JPEG，EXIF 信息会保留下来，不会丢失。EXIF 信息规定图片可以有个旋转角的信息。如果图片旋转了90度或者270度，那么系统的方法在解析图片尺寸时，会默认把宽高信息颠倒下，高变成宽，宽变成高。

59. RecyclerView 的 itemAnimator 存在时，如果 item view 设置了 wrap_content，则在首次刷新时可能导致 itemview 宽高测量异常，进而导致 RecyclerView 的异常滑动或者闪烁。

60. BitmapFactory.Options.inJustDecodeBounds设置为 true 时，BitmapFactory.decodeStream 方法会返回 null。

   ![BitmapFactoryCpp内容](/imgs/BitmapFactoryCpp内容.png)

   ![BitmapFactoryCpp内容2](/imgs/BitmapFactoryCpp内容2.png)

61. jvm 中方法参数是值传递。在方法内创建对象时，对象使用的是方法参数的值，不是引用。如第三张图，使用的是 data.switch 的值，不是 data.switch 变量引用。

   ![jvm中方法参数值传递1](/imgs/jvm中方法参数值传递1.png)
   
   ![jvm中方法参数值传递2](/imgs/jvm中方法参数值传递2.png)

   ![jvm中方法参数值传递3](/imgs/jvm中方法参数值传递3.png)

62. AppBarLayout 实现吸顶效果时，设置了 app:layout_scrollFlags 的 view 还需要设置 minHeight，否则吸顶效果会不生效