---
title: "Android 软键盘删除键触发问题分享"
description: "本文分享了 Android 软键盘删除键触发 BuG 的处理过程"
keywords: "Android,软键盘,搜狗输入法,百度输入法"

date: 2022-10-21 19:01:00 +08:00
lastmod: 2022-10-21 19:01:00 +08:00

categories:
  - Android
  - 输入法
tags:
  - Android
  - 软键盘
  - 输入法
  - 搜狗输入法
  - 百度输入法

url: post/9854C9E720584FBB85865163183737FE.html
toc: true
---

本文分享了 Android 软键盘删除键触发 BuG 的处理过程。

<!--More-->

**本文解决的问题：Android 输入法软键盘删除键点击多次，只触发一次删除事件**

**本文示例代码地址：[Android 软键盘删除键触发示例代码](https://github.com/xWenChen/WebViewInputTest.git)**

## 背景

笔者维护的 app 功能中，有个图文编辑器，由 Web 端和客户端共同维护。内容区域(使用 WebView 承载)由 Web 端维护，Web 端使用了三方框架，以在 WebView 中模拟实现 EditText 的功能；而客户端则维护键盘等功能。

线上有用户反馈了一个 bug：Android 输入法上软键盘的删除键，用户点击多次，但是只会触发一次删除键的响应。导致用户多次点击删除键，只能删除一个文本。

如图，在手机中，删除键的位置一般在输入法的右下角：

<img src=/imgs/删除键的位置一般在输入法的右下角.png width=40% height=40% />

有用户反馈问题，就得进行排查。

经过一番排查，发现用户反馈的问题，和具体的输入法有关系。不同的输入法之间相同功能可能会存在不同表现，而同一个输入法内的不同输入模式，可能也会存在不同表现。

以搜狗输入法和百度输入法为例。搜狗输入法和百度输入法之间存在不同的表现，搜狗输入法内的不同模式下也存在着不同的表现。

- 百度输入法没问题

- 搜狗输入法开启预测模式有问题，其他情况没问题，和百度输入法保持一致

   - 搜狗输入法一般预测模式的设置路径如下图所示(如果是英文 9 键的设置，就到英文 9 键下设置。示例手机为黑鲨手机)：

      <img src=/imgs/搜狗输入法一般预测模式的设置路径.gif width=40% height=40% />

   - 搜狗输入法专业版设置路径如下图所示(示例手机为黑鲨手机)：

      <img src=/imgs/搜狗输入法专业版设置路径.gif width=40% height=40% />

为了解决用户反馈的问题，就得专门研究一下输入法删除键的触发逻辑。下面是笔者整理出的一些知识点。

## 常规操作

在 Android 系统中，按键事件的触发主要分为两种。外设触发以及软键盘触发：

- 外设触发是走 KeyEvent 的下发流程。具体节点有 View.setOnKeyListener、Activity.dispatchKeyEvent、Activity.onKeyUp、Activity.onKeyDown 等等。本文不分析该流程。

- 软键盘触发不一定会走 KeyEvent 的流程，而是走 InputConnection 的流程。因为在 Android 系统中，输入法一般是一个单独的应用程序(App)，和硬件外设有所区别。在 android中，输入法与接收输入的应用程序，一般是两个单独的app。而 InputConnection 就是连接两个 app 的桥梁——输入法提供用户选择的字符，然后通过 InputConnection 交由接收 app 显示。InputConnection 接口是从 InputMethod 返回到当前应用程序的通信通道。它用于执行诸如读取光标周围的文本，将文本提交到文本框以及将原始键事件发送到应用程序之类的事情。如下图所示：

   ![InputConnection接口是从InputMethod返回到当前应用程序的通信通道](/imgs/InputConnection接口是从InputMethod返回到当前应用程序的通信通道.png)

   **文重点分析 InputConnection 的这个流程**

## 官方说明

**注：InputConnection 的中文 API 见：[InputConnection - Android中文版](https://www.apiref.com/android-zh/android/view/inputmethod/InputConnection.html)**

对于 InputConnection 类，官方的说明如下：

### 1. 创建 IME 或者编辑器

文本输入是两个重要组件的协同作用的结果：输入法引擎(IME)和编辑器。

- IME 可以是软件键盘、手写界面、表情符号、语音录入到文本引擎等，可以等价理解为输入法。通常在任何给定的 Android 设备上都安装了多种 IME。在 Android 中，IME 可以扩展 InputMethodService 。有关如何创建 IME 的更多信息，可以查阅官方的输入法创建指南。

- 编辑器是接收文本并显示它的组件。通常是一个 EditText 实例，但由于各种原因，某些应用程序可能会选择实现自己的编辑器。编辑器需要与IME交互，通过此 InputConnection 接口接收命令，并通过 InputMethodManager 发送命令。编辑器应该首先执行 onCreateInputConnection(EditorInfo) 来返回自己的 InputConnection。

如果要实现自己的编辑器，则需要提供自己的 InputConnection 示例以响应来自 IME 的命令。

- 应使用尽可能多的 IME 测试编辑器，因为不同的 IME 的行为可能会有很大差异。

- 应使用各种语言进行测试，包括CJK语言和阿拉伯语等从右至左的语言，因为这些语言可能会有不同的输入要求。

- 如果对某个特定调用应该采用的行为有疑问，可以参考最新的 Android 版本中的 TextView 的默认实现。

View 中定义了 onCreateInputConnection() 方法和 onCheckIsTextEditor() 方法，在 View 和输入法建立连接的时候，View 的 onCreateInputConnection() 方法会被调用。

- onCreateInputConnection() 为 InputMethod 创建一个新的 InputConnection，以便与视图进行交互。其默认实现返回 null，因为默认不支持输入法。可以覆盖它以实现这种支持，当然，应该仅对于具有焦点和文本输入的视图才需要。

- onCheckIsTextEditor() 表明视图 View 将返回非 null 的 InputConnection。

- 正确且完整地填写 EditorInfo 对象，以使连接的 IME 可以依赖其值。例如，必须使用正确的光标位置填充 initialSelStart 和 initialSelEnd 成员，IME 才能正确地与应用程序一起使用。

### 2. 光标、文本选择和文本预测

在 Android 中，光标和文本选择是同一件事。"光标" 只是零长度文本选择的特殊情况。因此，光标和文本选择的说明可以互换使用。任何在"光标"之前执行的方法，都将在"文本选择"开始之前执行；同理，任何在"光标"之后执行的方法将在"文本选择"结束后执行。

编辑器通常需要像标准组件一样跟踪当前的 "预测" 区域。"预测" 区域以 SPAN_COMPOSING 风格标记。IME 用该标记来帮助用户跟踪哪些文本是他们目前关注的一部分；并使用 setComposingText(CharSequence, int)、setComposingRegion(int, int) 和 finishComposingText() 方法与编辑器进行交互。"文本选择" 和 "文本预测区域"是互相独立的存在，IME 可以按照自己认为的合适的方式来使用二者。

## InputConnection 类图

在 AndroidX 和 TextView 中，都有 InputConnection 的实现类，通常我们不会使用它们。我们一般继承 InputConnectionWrapper，InputConnectionWrapper 提供了 InputConnection 中方法定义的默认实现，我们可以按需重写对应方法，而不必实现 InputConnection 中定义的所有方法。

<img src=/imgs/InputConnection类图.png width=60% height=60% />

## 实现说明

在介绍了官方说明和 InputConnection 的知识后，我们就可以来分析和解决问题了

### 1. 不同 WebView 的影响

解决问题之前，我们需要注意不同的 WebView，对于事件的生成，是有非常大的影响的。因为部分框架并不会调用 View.onCreateInputConnection() 方法，自然便无法走我们自定义的逻辑。比如著名的 X5 WebView 框架便不会调用 onCreateInputConnection() 方法，而 Android 系统自带的 WebView 会调用 onCreateInputConnection() 方法。

### 2. 不同输入法的影响

上面说明过，不同的输入法，对软键盘删除键的触发是有不同影响的，我们需要先梳理下软键盘删除键的触发逻辑，再解决问题。

按照网上的解释，一般的输入法，触发删除动作的位置有两个：sendKeyEvent、deleteSurroundingText。网上的解释可见链接：[Android 触发删除键 - Stack Overflow](https://stackoverflow.com/questions/14560344/android-backspace-in-webview-baseinputconnection)

笔者在使用了网上的方案后，发现搜狗输入法还是存在问题。所以要想真正的解决问题，我们还需要先梳理下搜狗输入法和百度输入法的逻辑差异。再尝试对症下药。

#### 测试代码定义

- 第 1 步，新建一个项目

- 第 2 步，新建一个类，类名为：WebInputConnection，继承自 InputConnectionWrapper，并重写父类中的所有方法，重写方式如下图例子所示。仅加上日志输出，不更改逻辑。用以梳理方法的触发流程

   ```kotlin
   override fun commitCompletion(text: CompletionInfo?): Boolean {
       Log.d(TAG, "commitCompletion, text = $text")
       return super.commitCompletion(text)
   }
   ```

- 第 3 步，新增一个类，类名为：TestWebView，继承自 WebView，并继承重写 onCreateInputConnection 方法

   ```kotlin
   class TestWebView : WebView {
       var inputConnection = WebInputConnection(context.applicationContext, null, true)
 
       constructor(context: Context) : this(context, null)
       // defStyle 不能传 0，否则会导致键盘无法弹出
       constructor(context: Context, attrs: AttributeSet?) : super(context, attrs)
       constructor(context: Context, attrs: AttributeSet?, defStyle: Int) : super(context, attrs, defStyle)
 
       override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection? {
           val target = super.onCreateInputConnection(outAttrs)
           if (target == null) {
               return target
           }
           inputConnection.setTarget(target)
           return inputConnection
       }
   }
   ```

- 第 4 步，在 activity_main 布局中使用 TestWebView

   ```kotlin
   <LinearLayout
       xmlns:android="http://schemas.android.com/apk/res/android"
       xmlns:tools="http://schemas.android.com/tools"
       android:layout_width="match_parent"
       android:layout_height="match_parent"
       tools:context=".MainActivity">
 
       <com.example.webviewinputtest.TestWebView
           android:id="@+id/webView"
           android:layout_width="match_parent"
           android:layout_height="match_parent"/>
 
   </LinearLayout>
   ```

- 第 5 步，在 MainActivity 中配置 TestWebView

   ```kotlin
   class MainActivity : AppCompatActivity() {
       companion object {
           const val TAG = "MainActivity"
       }
 
       lateinit var webView: TestWebView
 
       override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)
           setContentView(R.layout.activity_main)
 
           webView = findViewById(R.id.webView)
 
           webView.inputConnection.callback = {
               Log.d(TAG, "trigger del event")
               // TODO 通知观察者软键盘删除键点击事件触发了
               false
           }
 
           webView.webViewClient = object : WebViewClient() {
               override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                   val url = request.url.toString()
                   return try {
                       if (url.startsWith("http:") || url.startsWith("https:")) {
                           view.loadUrl(url)
                           false
                       } else {
                           val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                           startActivity(intent)
                           true
                       }
                   } catch (e: Exception) {
                       Log.e(TAG, "", e)
                       true
                   }
               }
           }
 
           webView.settings.apply {
               domStorageEnabled = true
               javaScriptEnabled = true
           }
 
           //访问网页
           webView.loadUrl("https://www.baidu.com");
       }
 
       override fun onDestroy() {
           // 加载空页面
           webView.loadDataWithBaseURL(null, "", "text/html", "utf-8", null)
           webView.clearHistory()
           (webView.parent as ViewGroup).removeView(webView)
           webView.destroy()
 
           super.onDestroy()
       }
   }
   ```

- 第 6 步，运行项目

完成了以上几步的代码创建工作后，我们就可以来梳理不同输入法的代码触发逻辑了。

我们执行不同的操作，以进行对比实验。操作流程如下图，我们先输入确定的文本(a、b)，再选择预测的文本(about)、然后点击删除键和长按删除键。

![对比实验操作流程](/imgs/对比实验操作流程.png)

清楚了如何操作后，我们就可以调试得到对应的方法调用链路了。结果如下。

#### 百度输入法

- 流程1

   - debug日志：

      ![百度输入法流程1日志](/imgs/百度输入法流程1日志.png)

   - 触发方法流程：commitText >>> sendKeyEvent

      ![百度输入法流程1图](/imgs/百度输入法流程1图.png)

- 流程2
   流程 2 的表现和流程 1 一致

- 流程3

   - debug日志：

      ![百度输入法流程3日志](/imgs/百度输入法流程3日志.png)

   - 触发方法流程：commitText >>> deleteSurroundingText

      ![百度输入法流程3图](/imgs/百度输入法流程3图.png)

- 流程4

   流程 4 和流程 3 的代码执行大同小异 

   - debug日志：

      ![百度输入法流程4日志](/imgs/百度输入法流程4日志.png)

   - 触发方法流程：commitText >>> deleteSurroundingText

      ![百度输入法流程4图](/imgs/百度输入法流程4图.png)

综上，百度输入法的删除键，主要是由两个方法触发：sendKeyEvent、deleteSurroundingText。这也符合网上一般文章的讲解。所以百度输入法的操作结果是正常的

#### 搜狗输入法

##### 一般模式说明

搜狗输入法开启一般模式的流程和百度输入法的流程3、流程4基本一致，可正常触发删除键。并且点击五次删除键和长按删除键流程一致：

- debug日志：

   ![搜狗输入法开启一般模式日志](/imgs/搜狗输入法开启一般模式日志.png)

- 触发方法流程：commitText >>> deleteSurroundingText >>> sendKeyEvent(空文本时触发)

##### 预测模式说明

搜狗输入法开启预测模式后，流程和上面的流程相比，就不太一样了。

- 流程1：
   
   - debug日志：

      ![搜狗输入法预测模式流程1日志](/imgs/搜狗输入法预测模式流程1日志.png)

   - 触发方法流程：setComposingText >>> finishComposingText >>> deleteSurroundingText >>> setComposingRegion >>> setComposingText >>> commitText >>> sendKeyEvent

      ![搜狗输入法预测模式流程1图](/imgs/搜狗输入法预测模式流程1图.png)

- 流程2：
   
   - debug日志：

      ![搜狗输入法预测模式流程2日志](/imgs/搜狗输入法预测模式流程2日志.png)

   - 触发方法流程：setComposingText >>> finishComposingText >>> deleteSurroundingText >>> sendKeyEvent

      ![搜狗输入法预测模式流程2图](/imgs/搜狗输入法预测模式流程2图.png)


- 流程3：
   
   - debug日志：

      ![搜狗输入法预测模式流程3日志](/imgs/搜狗输入法预测模式流程3日志.png)

   - 触发方法流程：setComposingText >>> commitText >>> sendKeyEvent

      ![搜狗输入法预测模式流程3图](/imgs/搜狗输入法预测模式流程3图.png)

- 流程4：

   和流程 3 逻辑一致

#### 结论

- 百度输入法，删除键触发的流程有两个，分别是 sendKeyEvent 和 deleteSurroundingText

- 搜狗输入法，根据设置项的不同，流程会有所不同

   - 正常情况下触发的方法和百度输入法一致

   - 预测模式下，会走 setComposingText 方法

综上，百度输入法和搜狗输入法，触发删除动作的位置有三个地点，前两个是已知的位置点，而第三个是搜狗输入法预测模式特有的位置点。

- sendKeyEvent

- deleteSurroundingText

- setComposingText

按照目前得到的信息，我们可以分析下用户反馈的问题的原因了：

- 一般的输入法，触发删除动作的位置有两个：sendKeyEvent、deleteSurroundingText。

- WebView 编辑器使用的第三方框架

   - 在输入法为百度输入法，以及搜狗输入法正常模式时，是没问题的。这两个场景，删除键触发的方法为：sendKeyEvent、deleteSurroundingText

   - 搜狗输入法预测模式下，选择某个预测文本后，点击多次删除键，只会触发一次 deleteSurroundingText，然后就进入预测模式，使用 setComposingText 代替删除操作(参考搜狗输入法-预测模式-流程1说明)。这符合用户反馈的说明(点击多次删除键，只删除一个字符)。

- 根据以上信息，我们可以推断：WebView编辑器使用的第三方框架，只适配了 sendKeyEvent、deleteSurroundingText 的流程，而没适配 setComposingText 的流程。在搜狗输入法为预测模式时，就出现了多次点击删除键，只能触发一次的问题

### 问题修复具体实现

既然框架没适配，那我们就主动适配，手动触发删除动作，并通知 Web 端删除字符。要达到这个效果，需要解决两个问题

- 过滤搜狗输入法：因为只有搜狗输入法预测模式有问题，为了不影响其他输入法的正常使用。我们需要对搜狗输入法做特殊处理。此时我们需要判断系统当前的输入法为搜狗输入法。

- 主动回调删除动作：当处于搜狗输入法预测模式时，主动回调删除动作

#### 过滤搜狗输入法

系统的当前输入法信息，我们可以从系统的设置信息中获取，代码如下：

   ```kotlin
   class WebInputConnection(context: Context, target:InputConnection?, mutable: Boolean): InputConnectionWrapper(target, mutable) {
       init {
           // 在构造函数中获取输入法 id 信息
           val inputId = try {
               Settings.Secure.getString(
                   context.contentResolver,
                   Settings.Secure.DEFAULT_INPUT_METHOD
               )
       } catch (e: Exception) {
           Log.e(TAG, "", e)
           ""
       }
       // 打印出输入法 id，方便判断
       Log.d(TAG, "System input type = $inputId")
   }
   ```

根据上述代码，我们得到搜狗输入法的 id 如下：

- 黑鲨搜狗输入法：com.sohu.inputmethod.sogou/.SogouIME

- 小米搜狗输入法：com.sohu.inputmethod.sogou.xiaomi/.SogouIME

可以看出，两个 id 都是以：com.sohu.inputmethod.sogou 开头，以 SogouIME 结尾。借此，我们就可以针对搜狗输入法做单独处理。定义一个变量，表明是否需要手动生成删除动作。当是搜狗输入法时，该变量值赋值为 true

   ```kotlin
   // 是否需要手动触发 Del 事件
   private var generateDelEvent = false
   // 搜狗输入法，英文输入场景下，预测输入时需要单独生成软键盘 Del 键的点击
   // 前后缀都判断，双重保险
   if (inputId.startsWith(SOU_GOU_NAME_PREFIX) || inputId.endsWith(SOU_GOU_NAME_SUFFIX)) {
       generateDelEvent = true
   }
 
   companion object {
       // 黑鲨搜狗输入法描述：com.sohu.inputmethod.sogou/.SogouIME
       // 小米搜狗输入法描述：com.sohu.inputmethod.sogou.xiaomi/.SogouIME
       const val SOU_GOU_NAME_PREFIX = "com.sohu.inputmethod.sogou"
       const val SOU_GOU_NAME_SUFFIX = "SogouIME"
   }
   ```

#### 主动回调删除事件

通过上面的实验，我们了解到流程 1 和流程 3 的调用链路是有区别的，并且通过流程 1，我们可以得到预测模式开始截止的调用方法：

- 进入预测模式的标志：setComposingRegion 或者 setComposingText 方法的调用

- 退出预测模式的标志：commitText 或者 finishComposingText 方法的调用

最终，我们就得到检测回调删除事件触发的全场景：

![回调删除事件触发的全场景](/imgs/回调删除事件触发的全场景.png)

场景中涉及到的函数，其说明如下：

- boolean sendKeyEvent(KeyEvent event)

   - 函数说明：通过当前 InputConnection 将 KeyEvent 发送到应用所在进程，该事件会像正常的 KeyEvent 一样分发到当前具有焦点的 View(通常这个 View 就是提供 InputConnection 的 View)

   - 重写说明：我们可以不重写该方法，因为框架已经适配；如果要重写，则不打断已有的下发流程，只是在 DOWN 和 DEL 键时做拦截。主要代码如下：

      ```kotlin
      override fun sendKeyEvent(event: KeyEvent?): Boolean {
          val result = super.sendKeyEvent(event)
          if (event?.keyCode == KeyEvent.KEYCODE_DEL
              && event.action == KeyEvent.ACTION_DOWN
              && keyBackIntercepted() // 是否拦截的标志
          ) {
               return true
          }
          return result
      }
      ```

- boolean deleteSurroundingText(int beforeLength, int afterLength)

   - 函数说明：删除当前光标(cursor)之前的 beforeLength 个字符，以及删除当前光标(cursor)之后的 afterLength 个字符(用户选中的字符不包含在其中)。长度是 Java 字符的长度，不是字符编码类型的长度

   - 重写说明：我们可以不重写该方法，因为框架已经适配；如果要重写，则不打断已有的下发流程。主要代码如下：

      ```kotlin
      override fun deleteSurroundingText(beforeLength: Int, afterLength: Int): Boolean {
          val result = super.deleteSurroundingText(beforeLength, afterLength)
          val intercepted = keyBackIntercepted() // 是否拦截的标志
          return if (intercepted) {
              intercepted
          } else {
              result
          }
      }
      ```

boolean setComposingRegion(int start, int end)

   - 函数说明：设定区间 [start, end) 内的文本为预测文本，在搜狗输入法中，start通常为 0，end 通常看作预测文本的长度。

   - 重写说明：重写方法，触发自定义的删除键逻辑检测。主要代码如下：

      ```kotlin     
      // 预测模式下选择文本后，再次点击删除按钮，会重新触发预测，走到该方法
      override fun setComposingRegion(start: Int, end: Int): Boolean {
          // 开始预测模式，触发检测
          checkWhenComposingStart(end)
          return super.setComposingRegion(start, end)
      }
      ```

- boolean setComposingText(CharSequence text, int newCursorPosition)

   - 函数说明：使用新的预测文本 text 替换当前的预测文本。搜狗输入法预测模式下，如果当前的预测文本长度比上次的短，则应视作一次删除

   - 重写说明：重写方法，触发自定义的删除键逻辑检测。主要代码如下：
      ```kotlin
      // 预测模式下设置文本
      override fun setComposingText(text: CharSequence?, newCursorPosition: Int): Boolean {
          // 开始预测模式，触发检测
          checkWhenComposingStart(text)
          return super.setComposingText(text, newCursorPosition)
      }
      ```

- boolean finishComposingText()

   - 函数说明：在搜狗输入法中，此函数的调用可以标识完成预测文本输入

   - 重写说明：重写方法，触发自定义的删除键检测逻辑。主要代码如下：

      ```kotlin
      // 预测模式结束会出发这个方法
      override fun finishComposingText(): Boolean {
          checkWhenComposingEnd(lastComposingTextLength)
          return super.finishComposingText()
      }
      ```

- boolean commitText(CharSequence text, int newCursorPosition)

   - 函数说明：将文本提交到文本框并设置新的光标位置。在搜狗输入法的预测模式下，输入框中的文本一直删，删到为空后会调用这个方法

   - 重写说明：重写方法，触发自定义的删除键检测逻辑。主要代码如下：

      ```kotlin
      // 预测模式下，输入框中的文本一直删，删到为空，最后会调用这个方法
      override fun commitText(text: CharSequence?, newCursorPosition: Int): Boolean {
          checkWhenComposingEnd(text)
          return super.commitText(text, newCursorPosition)
      }
      ```

- 自定义的开始检测是否触发删除键的代码逻辑如下：

   ```kotlin
   private fun checkWhenComposingStart(obj: Any?) {
       // 预测模式下，输入框中直接输入文本，会直接调用这个方法
       if (generateDelEvent && !inComposingMode) {
           // 不在预测模式，则进入预测模式
           inComposingMode = true
       }
       // 不在预测模式，不做处理
       if (!inComposingMode) {
           return
       }
 
       val nowLength = when(obj) {
           is CharSequence? -> {
               // setComposingText 传过来的新文本
               obj.lengthOrZero
           }
           is Int -> {
               // setComposingRegion 传过来的新的文本长度
               obj
           }
           else -> 0
       }
       // 上次的文本大于此次的文本
       if (lastComposingTextLength > nowLength) {
           keyBackIntercepted()
       }
 
       lastComposingTextLength = nowLength
   }
   ```

- 自定义的结束检测是否触发删除键的代码逻辑如下：

   ```kotlin
   private fun checkWhenComposingEnd(obj: Any?) {
       if (!generateDelEvent || !inComposingMode) {
           return
       }
       inComposingMode = false
 
       val nowLength = when(obj) {
           is CharSequence? -> {
               // commitText 传过来的最新的文本的长度
               obj.lengthOrZero
           }
           is Int -> {
               // finishComposingText 传过来的上次的文本长度
               obj
           }
           else -> 0
       }
 
       // 上次的文本大于此次的文本
       if (lastComposingTextLength > nowLength) {
           keyBackIntercepted()
       }
 
       lastComposingTextLength = 0
   }
   ```

自此，主要的自定义检测逻辑就说明完毕了。上述代码，经过验证，可以解决搜狗输入法预测模式下删除键只触发一次的问题。

## 额外补充-事件分发说明

上面的代码中，判断了 KeyEvent 的键值和动作，心血来潮，想补充点 KeyEvent 和 MotionEvent 的使用说明。

1. MotionEvent 和 KeyEvent 都是 InputEvent 的子类。但二者所持有的事件类型不大一样。

   - KeyEvent 通常只有 KeyDown 和 KeyUp 两种，KeyEvent 无 Cancel 事件、一般都是以 Up 事件结束事件流；KeyEvent 可能同时有多个按键触发(比如键盘同时按多个键)。不能完全使用 MotionEvent 的开发经验来开发 KeyEvent

   - MotionEvent 有 ActionButtonPress/Release 和 ActionDown/Up/Move/Cancel 两套，前者走 onGenericMotionEven 方法，后者走 onTouchEvent 方法。并且 MotionEvent 也有多指事件的流程。

2. 针对按键事件(KeyEvent 和走 MotionEvent 的按键事件)，需要额外判断事件来源。使用 InputEvent 的 isFromSource 方法判断来源。如同时接入鼠标和键盘，需要判断事件来自哪个设备。

3. 针对来源信息，ActionButtonPress 方法可能会带上来源信息，而 ActionButtonRelease 则不一定，此时需要在 ActionButtonPress 方法到来时，将来源信息缓存起来(具体得和事件生成方负责人员(如硬件工程师或者系统工程师)联调)。

4. 系统的 back 键动作可以被拦截。但是 Home 键动作无法被拦截，只能监听。两者都走 KeyEvent 的分发流程。