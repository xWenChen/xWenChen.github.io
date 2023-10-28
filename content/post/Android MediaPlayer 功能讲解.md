---
title: "Android MediaPlayer 功能讲解"
description: "本文讲解了 Android MediaPlayer 的功能"
keywords: "Android,音视频开发,MediaPlayer"

date: 2023-03-31 22:55:00 +08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - MediaPlayer

url: post/BD5946122B3348138BB493005FA20EBD.html
toc: true
---

本文讲解了 Android MediaPlayer 的功能。

<!--More-->

Android 提供的用于播放音视频的重要的 API 之一就是 MediaPlayer。本文将讲解 MediaPlayer 的相关知识点。MediaPlayer 类提供了准系统播放器的基本功能，支持最常见的音频/视频格式和数据源，的相关知识点。MediaPlayer 是比 VideoView 更底层的音视频处理实现。VideoView 内部使用的就是 MediaPlayer。

MediaPlayer 支持的数据源包括：

- 存储在应用资源(原始资源)内的媒体文件(resource/raw resource)

- 文件系统中的独立文件(file)

- 通过网络获得的音视频数据流(audio/video stream)

除了 MediaPlayer，播放音频时，我们还需要用到 AudioManager。AudioManager 用于管理设备上的音频源和音频输出。播放视频时，我们需要用到 SurfaceView。

## 权限申请

在介绍 MediaPlayer 的相关知识之前，我们需要先了解下播放音视频需要申请哪些权限：

- 播放时如果不希望屏幕熄灭，我们会设置保持屏幕常亮，此时需要申请以下权限：

```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

- 如果需要播放网络上的音视频内容，则需要申请网络权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

- 如果读取的是外部目录中的文件，则可能需要申请外部目录的文件读写权限：

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## MediaPlayer 基础

对于音视频文件和流的播放控制，MediaPlayer 使用状态机进行管理。下面的官方状态图展示了 MediaPlayer 中存在的播放状态，以及状态切换的时机。

![MediaPlayer状态图](/imgs/MediaPlayer状态图.png)

从图中我们可以看出 MediaPlayer 定义的播放状态，以及 MediaPlayer 的使用流程。

MediaPlayer 的实例可以通过两种途径创建：

- 使用构造函数 new 出 MediaPlayer 实例。使用构造函数创建出来的 MediaPlayer 对象处于 Idle 状态
- 使用 MediaPlayer.create() 方法获取 MediaPlayer 的实例。如果使用 create 的任一重载方法创建 MediaPlayer 对象成功，则 MediaPlayer 对象将处于 Prepared 状态，而不是 Idle 状态

   ```java
   // MediaPlayer.create() 的所有重载方法
   public static MediaPlayer create(
      Context context, 
      int resid
   )
   public static MediaPlayer create(
      Context context, 
      Uri uri
   )
   public static MediaPlayer create(
      Context context, 
      Uri uri, 
      SurfaceHolder holder
   )
   public static MediaPlayer create(
      Context context, 
      Uri uri, 
      SurfaceHolder holder,  
      AudioAttributes audioAttributes, 
      int audioSessionId
   )
   public static MediaPlayer create(
      Context context, 
      int resid,
      AudioAttributes audioAttributes, 
      int audioSessionId
   )
   ```

### MediaPlayer 的状态

MediaPlayer 定义了以下播放状态，在 Idle 状态和 End 状态之间就是 MediaPlayer 对象的生命周期：

![MediaPlayer的生命周期](/imgs/MediaPlayer的生命周期.png)

### Error(错误状态)

通常音视频的播放/控制操作可能会因为各种原因而失败，因此暴露错误给用户，以及从错误中恢复是十分重要的功能。例如碰到不支持的音视频格式、音频/视频内容存在同步问题、音视频分辨率太高、音视频流超时或者编程导致的错误(如在无效的状态中调用播放控制操作)等。

一旦发生错误，除了 new 出来的 MediaPlayer 对象调用了不合适方法这种场景，MediaPlayer 对象都会进入 Error 状态。

用户可以通过调用 setOnErrorListener(OnErrorListener) 方法监听 MediaPlayer 的错误信息。当 MediaPlayer 出现错误时，如果用户已经注册了 OnErrorListener 回调，则 MediaPlayer 对象的内部 player 引擎会调用用户提供的 OnErrorListener.onError() 方法，以告知用户错误信息。

为了方便 MediaPlayer 对象从 Error 状态恢复，并实现 MediaPlayer 对象的重用，我们可以调用 MediaPlayer.reset() 方法将 MediaPlayer 对象重置到 Idle 状态。

### Idle(空闲状态)

MediaPlayer 的 Idle 状态意为空闲状态，此状态下 MediaPlayer 并未与具体的音视频文件或流关联，针对具体文件和流的操作都不可用。如以下示例方法不能在 Idle 状态下调用(非全部)：

- prepare()：同步准备播放
- prepareAsync()：异步准备播放
- start()：开始播放
- pause()：暂停播放
- stop()：停止播放
- getCurrentPosition()：获取当前播放位置
- getDuration()：获取音视频内容的时长
- getVideoWidth()：获取视频宽度
- getVideoHeight()：获取视频高度
- setAudioAttributes(AudioAttributes)：设置音频属性
- setVolume(float, float)：设置左右声道音量
- setLooping(boolean)：设置循环播放
- seekTo(long, int)：播放跳转

通过以下两种方式，MediaPlayer 可以进入 Idle 状态：

1. 新建 MediaPlayer 对象，刚 new 出来的 MediaPlayer 处于 Idle 状态。如果用户设置了 OnErrorListener，并且创建后立即调用了上面列举的任一方法，MediaPlayer 对象的状态会保持不变，同时 MediaPlayer 对象不会调用用户设置的 OnErrorListener.onError() 回调方法。
2. 调用 reset() 方法成功后，MediaPlayer 对象处于 Idle 状态。如果用户设置了 OnErrorListener，并且在 reset() 方法之后立即调用了上面列举的任一方法，则内部 player 引擎将调用用户提供的 OnErrorListener.onError() 回调方法，并将 MediaPlayer 对象的状态转移到 Error 状态

### Initialized(初始状态)

当 MediaPlayer 已处于 Idle 状态时，可以调用下列 setDataSource 的重载方法之一，将 MediaPlayer 对象从 Idle 状态的转移到 Initialized 状态：

   ```java
   public void setDataSource(FileDescriptor fd)
   public void setDataSource(String path)
   public void setDataSource(MediaDataSource dataSource)
   public void setDataSource(
      String path, 
      Map<String, String> headers
   )
   public void setDataSource(
      @NonNull Context context, 
      @NonNull Uri uri
   )
   public void setDataSource(
      FileDescriptor fd, 
      long offset, 
      long length
   )
   public void setDataSource(
      @NonNull Context context, 
      @NonNull Uri uri,
      @Nullable Map<String, String> headers
   )
   public void setDataSource(
      @NonNull Context context, 
      @NonNull Uri uri,
      @Nullable Map<String, String> headers, 
      @Nullable List<HttpCookie> cookies
   )
   ```

注意在其他任何非 Idle 状态状态下调用 setDataSource() 方法，都会抛出 IllegalStateException。在调用 setDataSource 的任一重载方法时，我们应注意捕获处理方法内抛出的异常。

### Prepared(准备完成)

当 MediaPlayer 对象初始化完成，已处于 Initialized 状态后。必须先进入 Prepared 状态，然后才能开始播放。MediaPlayer 提供了同步与异步两种方式进行播放准备，准备完成后可以达到 Prepared 状态：

- 调用 prepare() 方法将以同步的方式进行准备
- 调用 prepareAsync() 方法将以异步的方式进行准备

prepare() 或 prepareAsync() 方法只能在 Initialized 状态下调用，其他状态下调用都会导致 MediaPlayer 抛出 IllegalStateException。

注意准备完成处于 Prepared 状态后，仍然可以调用相应的 set 方法来调整音频音量、screenOnWhilePlaying、looping 等属性。

#### 1. 同步准备

调用 MediaPlayer.prepare() 方法将使 MediaPlayer 以同步的方式进行准备工作。同步准备时，所在的线程会被阻塞。MediaPlayer 的准备工作是个耗时的任务，如果在主线程调用 prepare() 方法，可能会导致 ANR。因此 prepare() 方法只能在异步线程调用，准备完成后再切回主线程，如下面给出的示例代码一样：

```kotlin
scope.launch(Dispatchers.Main) {
    runCatching {
        withContext(Dispatchers.IO) {
            mediaPlayer.prepare()
        }
    }.onSuccess {
        playState = PlayState.PREPARED
        // next operation
    }.onFailure {
        // Uh-oh Error
        playState = PlayState.ERROR
    }
}
```

prepare() 方法执行完后，MediaPlayer 会调用用户提供的 OnPreparedListener.onPrepared() 回调方法通知用户准备完成。我们可以使用 MediaPlayer.setOnPreparedListener(OnPreparedListener) 方法注册 OnPreparedListener。

#### 2. 异步准备

调用 MediaPlayer.prepareAsync() 方法将使 MediaPlayer 以异步的方式进行准备工作。异步准备时，MediaPlayer 对象首先会将状态转移到 Preparing 状态，同时内部 player 引擎继续处理其余的准备工作，直到准备工作完成，再切换到 Prepared 状态。

Preparing 状态是一个短暂的状态，当 MediaPlayer 对象处于 Preparing 状态时，调用任何方法的效果都是未知的，或者说 MediaPlayer 未定义在 Preparing 状态下调用其他方法的效果。

异步准备方法 prepareAsync() 只能通过回调监听。完成准备时，MediaPlayer 会调用用户提供的 OnPreparedListener.onPrepared() 回调方法通知用户准备完成。我们可以使用 MediaPlayer.setOnPreparedListener(OnPreparedListener) 方法注册 OnPreparedListener。

### 播放状态

#### Started 状态

MediaPlayer 准备完成，状态变为 Prepared 状态后，就可以开始播放了。要开始播放，必须调用 MediaPlayer.start() 方法。start() 方法调用成功后，MediaPlayer 对象会转换成 Started 状态。处于 Started 状态时，MediaPlayer 的内部 player 引擎会调用用户提供的 OnBufferingUpdateListener.onBufferingUpdate() 回调方法，此回调允许 app 在音视频流中跟踪缓冲状态。我们可以调用 setOnBufferingUpdateListener(OnBufferingUpdateListener) 方法注册 OnBufferingUpdateListener。

注意如果 MediaPlayer 对象已经处于 Started 状态，此时再调用 start() 方法不会有任何效果。我们可以调用 MediaPlayer.isPlaying() 方法检测 MediaPlayer 对象是否处于 Started 状态。

#### Paused 状态

音视频内容开始播放，已处于 Started 状态后，可以暂停播放。调用 MediaPlayer.pause() 方法可以暂停播放。当 pause() 方法调用成功后，MediaPlayer 对象会进入 Paused 状态。如果 MediaPlayer 对象已经处于 Paused 状态，此时再调用 pause() 方法不会有任何效果。

Paused 状态状态下可以调用 start() 方法继续播放，继续播放开始的位置与暂停位置相同。从 Started 状态到 Paused 状态的转换(反之亦然)在播放器引擎中是异步发生的，因此调用 isPlaying() 方法获取到的状态可能有延时，需要过一段时间才能更新。对于流式内容，这个时间可能长达几秒。

#### PauStopped 状态

音视频内容开始播放，已处于 Started 状态后，可以停止播放。调用 MediaPlayer.stop() 方法可以停止播放，并使处于 Started、Paused、Prepared 或 PlaybackCompleted 状态的 MediaPlayer 进入 Stopped 状态。如果 MediaPlayer 对象已经处于 Stopped 状态，此时再调用 stop() 方法不会有任何效果。

一旦处于 Stopped 状态，MediaPlayer 就不能调用 start() 方法继续播放。如果想要开始播放，需要调用 prepare() 方法或 prepareAsync() 方法重新准备，待到 MediaPlayer 对象状态变为 Prepared，才能开始播放。

#### 调整播放位置

音视频内容开始播放，已处于 Started 状态后，可以调用 seekTo(long, int) 方法调整当前播放位置。seekTo(long, int) 方法是个异步方法，调用 seekTo() 方法不会阻塞当前线程，可以继续执行 seekTo 之后的代码，但实际的跳转操作可能需要过一段时间才能完成。这个延时在当前内容是音视频流时尤为明显。

当实际的跳转操作完成时，MediaPlayer 会调用用户提供的 OnSeekCompleteListener.onSeekComplete() 回调方法通知用户跳转完成。我们可以使用 setOnSeekCompleteListener(OnSeekCompleteListener) 方法注册 OnSeekCompleteListener。

seekTo(long, int) 方法也可以在其他非 Started 状态下调用，例如 Prepared、Paused 和 PlaybackCompleted 状态。如果音视频流中有视频，并且请求的位置有效，则在这些状态下调用 seekTo(long, int) 方法时，MediaPlayer 不会继续播放，而是显示目标位置的视频帧(即展示当前画面)。在 Started 状态下调用 seekTo(long, int) 方法，当跳转操作完成时，MediaPlayer 对象会从目标位置开始继续播放。

我们可以调用 getCurrentPosition() 来获取当前实际的播放位置。

### PlaybackCompleted(播放完成)

当播放到音视频内容的末尾时，播放完成。

如果已调用 setLooping(boolean) 方法将循环播放模式设置为 true，则 MediaPlayer 对象将保持 Started 状态，不会变为 PlaybackCompleted 状态。

如果循环模式为 false，当播放完成时，MediaPlayer 会调用用户提供的 OnCompletionListener.onCompletion() 回调方法通知用户播放完成。我们可以使用 setOnCompletionListener(OnCompletionListener) 方法注册 OnCompletionListener

在 PlaybackCompleted 状态下，我们可以调用 start() 方法重新从头开始播放音视频内容。

### End(结束状态)

MediaPlayer 的 End 状态意为结束状态。在 Idle 状态和 End 状态之间的状态就是 MediaPlayer 的生命周期状态。当 MediaPlayer 对象调用了 release() 方法后，MediaPlayer 就处于 End 状态。release() 方法在以下两种场景会被调用：

- MediaPlayer 对象被回收时。一旦 MediaPlayer 的实例被创建，我们就必须保持对该实例的引用，以防止它被 GC 回收。如果 MediaPlayer 实例被回收，则 MediaPlayer 的 release() 方法将被调用 ，以停止正在播放的音视频内容。
- 音视频内容播放完成。MediaPlayer 实例正常播放完音视频内容后，我们也应该调用 release() 方法释放获取到的资源(例如内存和编解码器等)。一旦调用了 release() 方法，我们就不能再与已释放的 MediaPlayer 实例进行交互。

## MediaPlayer 方法的调用时机

鉴于 MediaPlayer 中定义了多个不同的状态，所以我们需要考虑 MediaPlayer 中不同方法在哪些状态下可以调用，在哪些状态下不能调用。下表列举了各个方法在哪些状态调用是有效的和无效的。

|||||
|:---:|:---:|:---:|:---:|
|方法名称|有效状态|无效状态|说明|
|attachAuxEffect|{Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Idle, Error}|必须在 setDataSource 之后调用。调用它不会改变对象状态。|
|getAudioSessionId|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态。|
|getCurrentPosition|{Idle, Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Error}|
在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态。|
|getDuration|{Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Idle, Initialized, Error}|
在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态|
|getVideoHeight|{Idle, Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Error}|在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态|
|getVideoWidth|{Idle, Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Error}|在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对��转移到 Error 状态|
|isPlaying|{Idle, Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Error}|在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态|
|pause|{Started, Paused, PlaybackCompleted}|{Idle, Initialized, Prepared, Stopped, Error}|在有效状态下成功调用此方法会将对象转移到 Paused  状态。在无效状态下调用此方法会将对象转移到 Error 状态。|
|prepare|{Initialized, Stopped}|{Idle, Prepared, Started, Paused, PlaybackCompleted, Error}|在有效状态下成功调用此方法会将对象转移到 Prepared 状态。在无效状态下调用此方法会引发 IllegalStateException。|
|prepareAsync|{Initialized, Stopped}|
{Idle, Prepared, Started, Paused, PlaybackCompleted, Error}|在有效状态下成功调用此方法会将对象转移到 Preparing  状态。在无效状态下调用此方法会引发 IllegalStateException。|
|release|any|{}|在 release() 之后，不得与该对象进行交互。|
|reset|{Idle, Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted, Error}|{}|reset()之后，对象进入 Idle 状态|
|seekTo|{Prepared, Started, Paused, PlaybackCompleted}|{Idle, Initialized, Stopped, Error}|在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态|
|setAudioAttributes|{Idle, Initialized, Stopped, Prepared, Started, Paused, PlaybackCompleted}|{Error}|成功调用此方法不会更改状态。为了使目标音频属性类型生效，必须在 prepare() 或 prepareAsync() 之前调用此方法|
|setAudioSessionId|{Idle}|{Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted, Error}|此方法必须在 Idle 状态下调用，因为在调用 setDataSource 之前必须知道音频会话 ID。调用它不会改变对象状态。|
|setAudioStreamType (deprecated)|{Idle, Initialized, Stopped, Prepared, Started, Paused, PlaybackCompleted}|{Error}|成功调用此方法不会更改状态。为了使目标音频流类型生效，必须在 prepare() 或 prepareAsync() 之前调用此方法。|
|setAuxEffectSendLevel|any|{}|调用此方法不会更改对象状态。|
|setDataSource|{Idle}|{Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted, Error}|在有效状态下成功调用此方法会将对象转移到 Initialized 状态。在无效状态下调用此方法会引发 IllegalStateException。|
|setDisplay|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态。|
|setSurface|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|setVideoScalingMode|{Initialized, Prepared, Started, Paused, Stopped, PlaybackCompleted}|{Idle, Error}|成功调用此方法不会更改状态。|
|setLooping|{Idle, Initialized, Stopped, Prepared, Started, Paused, PlaybackCompleted}|{Error}|在有效状态下成功调用此方法不会更改状态。在无效状态下调用此方法会将对象转移到 Error 状态。|
|isLooping|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态。|
|setOnBufferingUpdateListener|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态。|
|setOnCompletionListener|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态。|
|setOnErrorListener|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|setOnPreparedListener|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|setOnSeekCompleteListener|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|setPlaybackParams|{Initialized, Prepared, Started, Pa0used, PlaybackCompleted, Error}|{Idle, Stopped}|在某些情况下，此方法会更改状态，具体取决于调用该方法的时机|
|setScreenOnWhilePlaying|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|setVolume|{Idle, Initialized, Stopped, Prepared, Started, Paused, PlaybackCompleted}|{Error}|成功调用此���法不会更改状态。|
|setWakeMode|any|{}|该方法可以在任何状态下调用，调用它不会改变对象状态|
|start|{Prepared, Started, Paused, PlaybackCompleted}|{Idle, Initialized, Stopped, Error}|在有效状态下成功调用此方法会将对象转移到 Started 状态。在无效状态下调用此方法会将对象转移到 Error 状态。|
|stop|{Prepared, Started, Stopped, Paused, PlaybackCompleted}|{Idle, Initialized, Error}|在有效状态下成功调用此方法会将对象转移到 Stopped 状态。在无效状态下调用此方法会将对象转移到 Error 状态|
|getTrackInfo|{Prepared, Started, Stopped, Paused, PlaybackCompleted}|{Idle, Initialized, Error}|成功调用此方法不会更改状态。|
|addTimedTextSource|{Prepared, Started, Stopped, Paused, PlaybackCompleted}|{Idle, Initialized, Error}|成功调用此方法不会更改状态|
|selectTrack|{Prepared, Started, Stopped, Paused, PlaybackCompleted}|{Idle, Initialized, Error}|成功调用此方法不会更改状态。|
|deselectTrack|{Prepared, Started, Stopped, Paused, PlaybackCompleted}|{Idle, Initialized, Error}|成功调用此方法不会更改状态。|

## MediaPlayer 的使用

MediaPlayer 的使用遵循着固定的步骤，很简单，可以参考官方的状态图以及上文的讲解。下面列举下使用 MediaPlayer 的示例代码。完整代码可看 Github 链接：[MediaPlayerVideoFragment.kt](https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/video/MediaPlayerVideoFragment.kt)

实例代码主要涉及几个方面：

1. 将创建好的 SurfaceHolder 设置给 MediaPlayer，以用于视频画面的展示(视频的展示用 SurfaceView)。SurfaceHolder 的创建是个异步过程，需要设置 SurfaceHolder.Callback 回调。
2. 注册视频尺寸监听，并设置 SurfaceView 的宽高
3. 配置 MediaPlayer，包括设置是否循环播放，设置播放时屏幕常亮
4. new 出 MediaPlayer 对象后，依次调用 setDataSource、prepare、start 方法
5. 亮屏时恢复播放(start)，熄屏时暂停播放(pause)，界面销毁时(onDestroy)停止播放(stop)，并调用 release 方法释放资源。

```kotlin
class MediaPlayerVideoFragment : BaseFragment<FragmentMediaPlayerVideoBinding>() {
    companion object {
        const val TAG = "MediaPlayerVideo"
    }

    private var scheduledJob: Job? = null

    val mediaPlayer = MediaPlayer()

    override fun initView(rootView: View) {
        // 设置回调，将创建好的 SurfaceHolder 设置给 MediaPlayer
        binding.svVideo.holder.addCallback(object : SurfaceHolder.Callback2 {
            override fun surfaceCreated(holder: SurfaceHolder) {
                mediaPlayer.setDisplay(holder)
            }
            // 其他代码省略
        })
        // 设置进度条
        binding.sbProgress.setOnSeekBarChangeListener(
            object : SeekBar.OnSeekBarChangeListener {
                override fun onStopTrackingTouch(seekBar: SeekBar) {
                    // 拖动结束，进行跳转
                    mediaPlayer.seekTo(seekBar.progress)
                }
                // 其他代码省略
            }
        )
        binding.btnPlay.setOnClickListener {
            startPlay()
        }
    }

    override fun initData(context: Context) {
        mediaPlayer.apply {
            // 重置到 Idle 状态
            mediaPlayer.reset()
            // 循环播放
            mediaPlayer.isLooping = true
            // 设置播放时屏幕常量
            setScreenOnWhilePlaying(true)
            setDataSource(context, Uri.parse(R.raw.tanaka_asuka.uriPath()))
            // 注册视频尺寸监听
            setOnVideoSizeChangedListener { mMediaPlayer, width, height ->
                changeViewSize(width, height)
            }

            prepareAndStart()
        }
    }

    private fun changeViewSize(videoWidth: Int, videoHeight: Int) {
        if (videoWidth <= 0 || videoHeight <= 0) {
            return
        }
        // 设置视频画面尺寸
        binding.svVideo.post {
            val viewWidth = binding.svVideo.measuredWidth
            val viewHeight = (videoHeight.toFloat() / videoWidth * viewWidth).toInt()
            val lp = binding.svVideo.layoutParams
            lp.width = viewWidth
            lp.height = viewHeight
            binding.svVideo.layoutParams = lp
        }
    }

    private fun MediaPlayer.prepareAndStart() {
        lifecycleScope.runResult(
            doOnIo = {
                prepare()
            },
            doOnSuccess = {
                playState = PlayState.PREPARED
                realStartPlay()
            },
            doOnFailure = {
                playState = PlayState.ERROR
            }
        )
    }

    override fun onResume() {
        super.onResume()

        startPlay()
    }

    override fun onPause() {
        super.onPause()

        stopPlay(true)
    }

    override fun onDestroy() {
        super.onDestroy()

        if (mediaPlayer.isPlaying) {
            mediaPlayer.stop()
        }

        mediaPlayer.release()
    }

    private fun MediaPlayer.notPlay(): Boolean {
        return playState.isPlayState(PlayState.PREPARED) || playState.isPlayState(PlayState.PAUSED)
    }

    private fun startPlay() {
        if (playState == PlayState.PLAYING) {
            return
        }

        if (playState.isPlayState(PlayState.UNINITIALIZED)) {
            mediaPlayer.prepareAndStart()
            return
        }
        if (playState.isPlayState(PlayState.STOPPED)) {
            mediaPlayer.seekTo(0)
        }
        if (mediaPlayer.notPlay()) {
            realStartPlay()
        }
    }

    private fun realStartPlay() {
        mediaPlayer.start()
        playState = PlayState.PLAYING
    }

    private fun stopPlay(isPaused: Boolean = false) {
        if (isPaused) {
            mediaPlayer.pause()
            playState = PlayState.PAUSED
        } else {
            mediaPlayer.stop()
            playState = PlayState.UNINITIALIZED
        }
    }
}
```

MediaPlayer 的相关知识暂时就讲这些，以后有机会好好研究下 Android 的音视频框架。再出篇更详细的讲解。