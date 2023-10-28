---
title: "Android MediaCodec 解码 mp4"
description: "本文讲解了使用 Android MediaCodec 解码 mp4"
keywords: "Android,音视频开发,MediaCodec,mp4"

date: 2023-04-15 18:57:00 +08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - MediaCodec

url: post/3A527688B2B346FD8911716A88CD4B9F.html
toc: true
---

本文讲解了使用 Android MediaCodec 解码 mp4。

<!--More-->

上篇博文：[Android MediaCodec 功能讲解](D08E5E865578467FB0D8D4F753FE89EE.html)

本文示例源代码：[MediaCodec 解码播放 mp4 文件](https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/video/MediaCodecVideoFragment.kt)

上篇博文中，我们讲解了 MediaCodec 的基础知识，本篇文章我们通过使用 MediaCodec 解码并播放 mp4 文件，来讲下 MediaCodec 的使用。

解码并播放 mp4 文件主要涉及到了以下 5 大方面的功能：

1. 解码视频：主要使用到了 MediaCodec
2. 解码音频：主要使用到了 MediaCodec
3. 播放视频：主要使用到了 SurfaceView
4. 播放音频：主要使用到了 AudioTrack
5. 播放控制：主要涉及到了音视频的播放控制

鉴于本文着重讲解 MediaCodec 的使用，故 SurfaceView 和 AudioTrack 就不详细讲解了，感兴趣的可以自行阅读以下文章了解：

- SurfaceView 讲解：https://juejin.cn/post/6844903968217235469 和 https://www.cnblogs.com/roger-yu/p/15641545.html
- AudioTrack 讲解：https://blog.csdn.net/yangwen123/article/details/39989751 和 https://www.cnblogs.com/wulizhi/p/8183658.html

## mp4 基础知识

MP4 或称 MPEG-4，是一种标准的数字多媒体容器格式，官方标准定义的唯一扩展名是 .mp4。虽然官方标准是 mp4，但第三方公司或机构通常会使用各种扩展名来指示文件的内容：

1. 同时拥有音频视频内容的 MPEG-4 文件通常使用标准扩展名 .mp4

2. 仅有音频的MPEG-4文件会使用 .m4a 扩展名，对于不受保护的内容更是如此

   1. 通过 iTunes Store 销售的拥有数字版权的 MPEG-4 音频文件会使用 .m4p 作为扩展名

   2. 包含 章节标记/图像/超链接 的有声读物、播客文件或是元数据会使用 .m4b 作为扩展名，但有时候也会使用 .m4a 作为扩展名。使用 .m4a 扩展名的文件不能使用书签来记录播放位置，而使用 .m4b 扩展名的就可以做到这一点

   3. 苹果公司的 iPhone 手机使用 MPEG-4 音频作为其电话铃声，但扩展名为 .m4r

3. 仅有视频流的 MPEG-4 视频文件可以使用 .m4v 扩展名
4. 移动电话使用 3GP 视频格式，它类似于 MP4 格式但使用 .3gp 或是 .3g2 扩展名

MP4 是种容器格式，不是最终的音视频信息，编码后的音视频流可以嵌入到 MP4 文件中，因此 MP4 文件中包含了单独用于存储流信息的轨道：

- 视频轨道：存储视频信息的轨道，视频通常以 H265/H264 等格式编码
- 音频轨道：存储音频信息的轨道，音频通常以 AAC/OPUS 等格式编码
- 字幕格式：存储视频字幕的信息

## 定义 mp4 解码器

MediaCodec 主要是使用了手机上的硬件设备解码 mp4，该硬件设备通常是指 DSP 芯片。DSP 芯片是能够实现数字信号处理技术的芯片。DSP 即 Digital Signal Processing，译为数字信号处理。数字信号处理单元通常是硬件，并且通常是芯片的一个组成部分，芯片中还可以包括其他的单元，如射频单元等等。MediaCodec 编解码时，底层调用的就是 DSP 提供的能力。

由于 MediaCodec 解码 mp4 音频和视频的过程十分类似，所以我们可以将解码逻辑放到一起。我们定义一个 HardwareDecoder，用于实现解码逻辑。解码逻辑如下：

1. 获取 MediaExtractor。MediaExtractor 用于分离 mp4 文件的音视频轨道，以读取格式数据和音视频流数据。MediaExtractor 的使用步骤如下：

   1. new MediaExtractor() 获取 MediaExtractor
   2. 调用 MediaExtractor.setDataSource 方法配置 MediaExtractor。
   3. 使用 MediaExtractor.readSampleData 读取数据
   4. MediaExtractor 使用完后，调用 MediaExtractor.release 方法释放，并将 MediaExtractor 置为 null

2. 使用 MediaExtractor 解析 mp4，找到格式信息。

3. 创建解码器，对于音频的解码，我们还需要配置 AudioTrack

4. 调用 MediaCodec.configure 和 MediaCodec.start 方法配置并开始解码 mp4，音频的 surface 为空。

5. 使用 MediaExtractor 循环读取编码数据，并传入 MediaCodec 解码

   1. 编码数据传入 MediaCodec

      1. MediaCodec.dequeueInputBuffer 获取可用输入缓冲区的 index，-1表示暂时没有可用的
      2. MediaCodec.getInputBuffer 获取可用输入缓冲区
      3. MediaExtractor.readSampleData(inputBuffer, 0) 读取待解码数据
      4. MediaExtractor.queueInputBuffer 将输入缓冲区入队，进行解码，如果无可用数据，则传入 MediaCodec.BUFFER_FLAG_END_OF_STREAM 标记
      5. MediaExtractor.advance() 跳到下一个 sample， 方便再次读取数据

   2. 从 MediaCodec 获取已解码数据

      1. MediaCodec.dequeueOutputBuffer 获取可用输出缓冲区的 index，-1表示暂时没有可用的
      2. MediaCodec.getOutputBuffer 获取可用输出缓冲区
      3. 如果是音频，需要从输出缓冲区的 ByteBuffer 中读取数据到 ByteArray，并将 ByteArray 中的数据传入到 AudioTrack 中，以保证音频的正常播放。
      4. 根据 MediaCodec.BufferInfo.presentationTimeUs 数据进行音视频同步，该字段表示 PTS。
      5. 检查 MediaCodec.BUFFER_FLAG_END_OF_STREAM 标记，判断是否解码完成。

上面的流程定义显得很复杂，我们一个一个的说明：

## HardwareDecoder 的状态

为了方便我们定义流程，我们需要定义出 HardwareDecoder 解码流程中的状态，结合 MediaCodec 的知识，我们可以定义出以下状态。

```kotlin
private enum class MediaCodecState {
    UNINITIALIZED, // 调用 reset 或者 stop 时进入
    RUNNING, // 首次 dequeue Input(Output) Buffer 成功时进入
    END_OF_STREAM,  // Output Buffer 结束时进入
    ERROR, // 遇见错误时进入
    RELEASED, // 调用 release 时进入
    PAUSED, // 自定义状态，非 MediaCodec 标准状态，用于暂停场景
    RESET, //  自定义状态，非 MediaCodec 标准状态，用于重置场景
    FLUSHED, // 自定义状态，非 MediaCodec 标准状态，用于清除缓存
}
```

MediaCodec 的各状态定义:

在MediaCodec的生命周期内存在三种状态：Stopped、Executing、Released

- Stopped状态包含三种子状态：Uninitialized, Configured, Error
- Executing状态包含三种子状态：Flushed, Running, End-of-Stream

创建 Codec 实例后(调用以下3个方法之一)，Codec将会处于 Uninitialized 状态

- createByCodecName
- createDecoderByType
- createEncoderByType

调用 MediaCodec.configure 方法后，Codec 将进入 Configured 状态

调用 MediaCodec.start 方法后，Codec 会转入 Executing 状态

- start 后 Codec 立即进入 Flushed 子状态，此时的 Codec 拥有所有的 input and output buffers，Client 无法操作这些 buffers
- 调用 MediaCodec.dequeueInputBuffer 请求得到了一个有效的input buffer index 后, Codec 立即进入到了 Running 子状态
- 当得到带有 end-of-stream 标记的 input buffer 时(queueInputBuffer(EOS))，Codec将转入 End-of-Stream 子状态。在此状态下，Codec 不再接受新的 input buffer 数据，但仍会处理之前入队列而未处理完的 input buffer 并产生 output buffer，直到 end-of-stream 标记到达输出端，数据处理的过程也随即终止
- 在 Executing 状态下可以调用 MediaCodec.flush方法进入 Flushed 子状态
- 在 Executing 状态下可以调用 MediaCodec.stop 方法进入 Uninitialized 子状态,可以对 Codec 进行重新配置

极少数情况下 Codec 会遇到错误进入 Error 状态，可以调用 MediaCodec.reset 方法使其再次可用

当 MediaCodec 数据处理任务完成时或不再需要 MediaCodec 时，可使用  MediaCodec.release 方法释放其资源

## HardwareDecoder 核心方法

HardwareDecoder 的解码过程具有唯一性，要么只解码音频、要么只解码视频，不会同时解码二者。我们可以定义一个 decode 方法，作为 HardwareDecoder 的核心方法。

```kotlin
/**
 * Video 需要用到 Surface
 * Audio 需要输出到 AudioTrack
 * */
fun decode(context: Context, surface: Surface? = null) {
    try {
        // 1. 配置 HardwareDecoder
        if (!configMedia(context)) {
            return
        }
        // 2. 配置音频和视频的差异项
        if (isVideo) {
            this.surface = surface
        } else {
            if (audioTrack == null) {
                this.audioTrack = createAndConfigAudioPlayer()
            }
        }
        // 3. 创建 MediaCodec，并开始解码
        createAndDecode()
        // 解码完成，释放资源
        release()
    } catch (e: Exception) {
        LogUtil.e(TAG, e)
        state = MediaCodecState.ERROR
    }
}
```

## 1. 配置 HardwareDecoder

首先我们定义一个 configMedia 方法，用于进行 HardwareDecoder 的配置。

1. 通过构造方法获取 MediaExtractor 的实例。MediaExtractor 用于分离 mp4 文件的音视频轨道，以读取格式数据和音视频流数据。
2. 调用 MediaExtractor.setDataSource 方法配置 MediaExtractor。
3. 调用 MediaExtractor.trackCount 和 MediaExtractor.getTrackFormat 方法获取到目标轨道对应的格式
4. 调用 MediaExtractor.selectTrack 选中目标轨道

```kotlin
// 先定义格式信息
data class HardwareMediaInfo(
    val mimeType: String,
    val trackIndex: Int,
    val mediaFormat: MediaFormat?,
)
```

```kotlin
private fun configMedia(context: Context): Boolean {
    // 1. 获取 MediaExtractor 实例
    var mExtractor: MediaExtractor = MediaExtractor()
    // 2. 配置 MediaExtractor，传入 mp4 文件的 fileUri
    mExtractor.setDataSource(context, fileUri, null)
    // 3. 找到音视频相关信息
    mediaInfo = findMediaFormat()

    if (mediaInfo!!.trackIndex < 0 || mediaInfo!!.mediaFormat == null) {
        return false
    }
    // 4. 选中对应的轨道
    mExtractor.selectTrack(mediaInfo!!.trackIndex)

    return true
}

fun findMediaFormat(): HardwareMediaInfo {
    // 定义 mimeType 前缀
    val prefix = if (isVideo) {
        "video/"
    } else {
        "audio/"
    }
    // 读取 mp4 所有的音视频轨道，并拿到目标数据
    (0 until mExtractor.trackCount).forEach {
        val format = mExtractor.getTrackFormat(it)
        val mimeType = format.getString(MediaFormat.KEY_MIME) ?: ""
        if (mimeType.startsWith(prefix)) {
            // 找到目标格式的数据信息，返回 mimeType、trackIndex 和 MediaFormat
            return HardwareMediaInfo(mimeType, it, format)
        }
    }

    return HardwareMediaInfo("", -1, null)
}
```

## 2. 对于音频播放，配置 AudioTrack

在 Android 中播放音频，我们需要用到 AudioTrack 类。

1. 调用 AudioTrack.getMinBufferSize 方法获取缓冲区的最小尺寸
2. 根据 AudioAttributes、AudioFormat、minBufferSize 等信息生成 AudioTrack 的实例
3. 调用 AudioTrack.play() 准备播放(此时不会播放，因为没有数据传入)

```kotlin
private fun createAndConfigAudioPlayer(): AudioTrack {
    // 创建音频播放器
    // 1. 获取 minBufferSize
    val minBufferSize = AudioTrack.getMinBufferSize(
        mediaInfo!!.sampleRate,
        mediaInfo!!.voiceTrack,
        mediaInfo!!.sampleDepth
    )
    // 说明 https://stackoverflow.com/questions/50866991/android-audiotrack-playback-fast
    // 2. 生成 AudioTrack 实例
    val audioTrack = AudioTrack(
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build(),
        AudioFormat.Builder()
            .setSampleRate(mediaInfo!!.sampleRate)
            .setChannelMask(mediaInfo!!.voiceTrack)
            .setEncoding(mediaInfo!!.sampleDepth)
            .build(),
        minBufferSize,
        AudioTrack.MODE_STREAM,
        AudioManager.AUDIO_SESSION_ID_GENERATE
    )
    // 3. 准备播放，此时不会播放，因为没有数据传入
    audioTrack.play()
    //updatePlayState(audioTrack) TODO 此行代码暂未用上，保留着用以说明 AudioTrack 的状态转换逻辑

    return audioTrack
}
```

## 3. 创建并开始解码

配置成功后，我们就可以创建 MediaCodec 的实例，并开始解码播放了。

```kotlin
private fun createAndDecode() = try {
    // 创建解码器
    create()
    // 开始解码
    startDecode()
} catch (e: Exception) {
    LogUtil.e(TAG, e)
    state = MediaCodecState.ERROR
}

fun create() {
    if (decoder == null) {
        // 根据 mimeType 创建 MediaCodec 实例
        decoder = MediaCodec.createDecoderByType(
            mediaInfo?.mimeType ?: ""
        )
    }
    state = MediaCodecState.UNINITIALIZED
}
```

开始解码前，我们需要新使用如下方法配置 MediaCodec。

```kotlin
fun prepare() {
    if (state != MediaCodecState.UNINITIALIZED) {
        LogUtil.e(TAG, "can not prepare decoder which not in uninitialized state")
        return
    }
    // 解码音频不需要 surface，surface 为 null
    decoder?.configure(mediaInfo?.mediaFormat, surface, null, 0)
    decoder?.start()
}
```

MediaCodec 开始解码后，我们就需要进行数据处理了。

## 4. 解码循环

MediaCodec 开始解码后，我们需要循环处理数据。首先是是读取待解码数据并传入 MediaCodec 的操作。

### 读取数据并入队

我们采用以下方法读取编码数据，并放入 MediaCodec 中。

```kotlin
/**
 * 原始数据写入解码器，返回值表示编码数据是否全部读取完成
 * */
private fun MediaCodec.inputData(mExtractor: MediaExtractor?): Boolean? {
    // 1. dequeue: 出列，拿到一个输入缓冲区的index，-1表示暂时没有可用的
    val inputBufferIndex = dequeueInputBuffer(TIMEOUT)
    if (inputBufferIndex < 0) {
        LogUtil.d(TAG, "isVideo = $isVideo, inputBufferIndex = $inputBufferIndex")
        return null
    }

    if (state != MediaCodecState.RUNNING) {
        state = MediaCodecState.RUNNING
    }

    // 2. 使用返回的 inputBuffer 的 index 得到一个 ByteBuffer，可以放数据了
    val inputBuffer = getInputBuffer(inputBufferIndex) ?: return null

    // 3. 往 InputBuffer 里面写入数据。返回的是写入的实际数据量，-1 表示已全部写入
    val sampleSize = mExtractor?.readSampleData(inputBuffer, 0) ?: -1
    // 4. 数据入队
    return if (sampleSize >= 0) {
        // 数据已填充入 InputBuffer，分别设置 size 和 sampleTime
        // 这里 sampleTime 不一定是顺序来的，所以需要缓冲区来调节顺序
        queueInputBuffer(
            inputBufferIndex, 
            0, 
            sampleSize, 
            mExtractor?.sampleTime ?: 0, 
            0
        )
        // 在 MediaExtractor 执行完一次 readSampleData 方法后，
        // 需要调用 advance() 去跳到下一个 sample，
        // 然后再次读取数据(读取下次采样视频帧)
        mExtractor?.advance()
        false
    } else {
        // 数据读完，入队结束
        queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
        true
    }
}
```

### 读取数据并出队

读取解码后的数据主要是为了音频播放以及音频视频的播放同步。

我们采用以下方法读取解码后数据，并放入 AudioTrack 中。我们可以从输出缓冲区的 ByteBuffer 中读取数据到 ByteArray，并将 ByteArray 中的数据传入到 AudioTrack 中。

```kotlin
/**
 * 从解码器获取解码后的音频数据
 * */
private fun MediaCodec.outputData(startTime: Long): Boolean? {
    val bufferInfo = MediaCodec.BufferInfo()
    // 等待 50 豪秒
    val outputBufferIndex = dequeueOutputBuffer(bufferInfo, TIMEOUT)
    if (outputBufferIndex >= 0) {
        if (!isVideo) {
            // 解码音频，数据需要放入 AudioTrack 中
            val byteBuffer = getOutputBuffer(outputBufferIndex) ?: return null
            val pcmData = ByteArray(bufferInfo.size)

            // 读取缓存到数组
            byteBuffer.position(0)
            byteBuffer.get(pcmData, 0, bufferInfo.size)
            byteBuffer.clear()
            // audioTrack.write(pcmData, 0, audioBufferInfo.size);//用这个写法会导致少帧？
            // 数据写入播放器
            audioTrack?.write(pcmData, bufferInfo.offset, bufferInfo.offset + bufferInfo.size)
        }
        currentSampleTime = bufferInfo.presentationTimeUs / 1000
        // 直接渲染到 Surface 时使用不到 outputBuffer
        // ByteBuffer outputBuffer = videoCodec.getOutputBuffer(outputBufferIndex);
        // 如果缓冲区里的展示时间(PTS) > 当前音频播放的进度，就休眠一下(音频解析过快，需要缓缓)
        sleep(bufferInfo, startTime)
        // 将该ByteBuffer释放掉，以供缓冲区的循环使用
        releaseOutputBuffer(outputBufferIndex, true)
    }

    // outputBufferIndex < 0 时需要检查是否解码完成
    return if (bufferInfo.flags.and(MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
        state = MediaCodecState.END_OF_STREAM
        true
    } else {
        false
    }
}
```

音频视频的同步后面单独讲解。

### 数据处理循环

讲解了如何向 MediaCodec 读写数据后，我们就可以定义数据处理循环了。

```kotlin
private fun startDecode() {
    // 配置并开始解码，音频的 surface 为空
    prepare()
    start()

    var inputDone = false
    var outputDone = false

    while (!outputDone) {
        // 没有输出了，退出循环
        if (state == MediaCodecState.END_OF_STREAM) {
            break
        }
        // 暂停时不处理数据的输入输出
        if (state == MediaCodecState.PAUSED) {
            continue
        }
        if (state == MediaCodecState.RESET) {
            // 退到 0 帧处重新开始
            seekTo(0)
        }
        if (state == MediaCodecState.FLUSHED) {
            decoder?.flush()
            audioTrack?.flush()
        }
        // startMs time 随时可改，不能保证线程安全，此处赋值一次，保证一个输入输出内，startTime 值不变
        val nowStartTime = startMs
        // 将资源传递到解码器
        if (!inputDone) {
            inputDone = decoder?.inputData(mExtractor) ?: inputDone
        }
        // 从 codec 读取数据
        outputDone = decoder?.outputData(nowStartTime) ?: outputDone
    }
}

// 调到指定位置，单位 毫秒
fun seekTo(time: Long) {
    mExtractor.seekTo(time * 1000, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
    // 主要用于音视频同步
    startMs += (currentSampleTime - time)
    state = MediaCodecState.FLUSHED
}
```

## 音频视频同步

上面讲解了 HardwareDecoder 的主体逻辑，但是还有一块内容没有讲解，那就是音频内容的同步。为何要讲这个内容呢？因为 HardwareDecoder 只负责音频或者视频，所以解码一个包含音频和视频内容的 mp4 文件，需要两个 HardwareDecoder 实例，一个负责解码音频，一个负责解码视频。两者可能开始解码的时间不一致。此时如果不做处理，就会出现语音画面对不上的问题。所以播放音视频内容时，需要好好处理下同步问题。

音频视频同步问题中，有两个很重要的概念：DTS(Decoding Time Stamp) 和 PTS(Presentation Time Stamp)。简单的讲，DTS 就是解码数据的时间，比如视频的 fps 是 30，即每秒显示 30 帧。但我的处理器够优秀，一秒可以解码 60 帧。此时如果不加时间的限制，那么解码 60 帧一秒播放，就会出现视频加速的现象(一秒播完两秒的视频)，音频同理。为了解决这个问题，就需要用到 PTS 了，即显示的时间。

对于音视频的同步，我们肯定需要一个基准的起始时间，用于对齐。因为媒体文件的时间(如 PTS)是个相对的时间段，不是绝对的时间戳。

我们可以使用以下方法进行同步：

```kotlin
private fun sleep(mediaBufferInfo: MediaCodec.BufferInfo, decodeStartTime: Long) {
    // videoBufferInfo.presentationTimeUs / 1000  PTS 视频的展示时间戳(相对时间)
    val fastForwardTime = mediaBufferInfo.presentationTimeUs / 1000 + decodeStartTime - System.currentTimeMillis()
    if (fastForwardTime > 0) {
        // 音视频解析快了
        Thread.sleep(fastForwardTime)
    }
}
```

System.currentTimeMillis() - decodeStartTime 表示的是开始解码到现在过了多久。我们可以假设其值为 decodeTimeSpan。

mediaBufferInfo.presentationTimeUs - decodeTimeSpan 用于确定图片是否解析过快了。在第 1 秒时，解析到了第 2 秒的帧，此时第 2 秒的帧还不能播放，还需要等待 1 秒。

又因为音视频可能开始解码的时间不同(极端点，音频在 1 秒时开始解码，视频在 2 秒时开始解码)，所以我们需要使用统一的标杆，避免因采用不同的标杆导致的同步问题。

```kotlin
withContext(Dispatchers.IO) {
    // 同步时间，用于音频、视频 PTS 同步校准
    val startTime = System.currentTimeMillis()
    videoDecoder?.startMs = startTime
    audioDecoder?.startMs = startTime
    // 音频和视频的解析同步进行
    launch { videoDecoder?.decode(activity, surface) }
    launch { audioDecoder?.decode(activity) }
}
```

### 跳转(seek)和暂停播放后恢复的处理

seek 操作后，为了保证视频帧的正确展示，我们需要给 startMs 重设一个合适的时间，我们可以以现实时间戳为基准，确定新的 startMs 时间。此处举例解释一下为何这么处理。

- 比如我们在 10:00 点处开始解码一个时长为 10 分钟的视频，当我们不 seek，正常播放时，会在 10:10 的时间点播放完。startTime = 10:00

- 如果在播放了 8 分钟后，我们选择 seek 到了视频的 3 分钟处。假设解析速度不变，则视频播放完成应该在 10:15 分，多出来的 5 分钟是 3-8 分钟之前重复播放的内容。我们不考虑重复播放过的内容，仅考虑 9 分钟处的内容，原本在 10:09 分就能呈现的内容在 seek 后，得等到 10:14 分才能呈现，相当于向后延了 5 分钟。效果相当于从 10:05 分开始解析。startTime = 10:05，多出来的 5 分钟就是 8 - 3，即 startTime = startTime + currentPlayTime - seekTime。
   
   - 另一种解释是如果在播放了 8 分钟后，我们选择 seek 到了视频的 3 分钟处。假设解析速度不变，则相当于视频已经播放了 3 分钟，从 3 分钟前开始播放，即 startTime = System.currentTimeMillis() - seekTime。System.currentTimeMillis() = 10:08。seekTime=3分钟

- 同理，如果在播放了 3 分钟后，我们选择 seek 到了视频的 8 分钟处。假设解析速度不变，则视频播放完成应该在 10:05 分，少出来的 5 分钟是 3-8 分钟之前未播放的内容。我们不考虑未播放过的内容，仅考虑 9 分钟处的内容，原本在 10:09 分呈现的内容在 seek 后，提前到 10:04 分就呈现，相当于提前了 5 分钟。效果相当于从 09:55 分开始解析。startTime = 09:55，少的 5 分钟就是 3 - 8，即 startTime = startTime + currentPlayTime - seekTime。

   - 另一种解释是如果在播放了 3 分钟后，我们选择 seek 到了视频的 8 分钟处。假设解析速度不变，则相当于从 8 分钟前开始播放，即 startTime = System.currentTimeMillis() - seekTime。System.currentTimeMillis() = 10:03 seekTime = 8 分钟

```kotlin
// 调到指定位置，单位 毫秒
fun seekTo(time: Long) {
    mExtractor.seekTo(time * 1000, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
    // 调整开始时间，用于音视频同步
    startMs += (currentSampleTime - time) // 等价于 System.currentTimeMillis() - time
    state = MediaCodecState.FLUSHED
}
```

暂停播放后，恢复播放时，也存在一个现实时间流逝，但视频时间没变的问题，此时我们的参考时间为现实时间，还是以上面的例子为例。

- 比如我们在 10:00 点处开始解码一个时长为 10 分钟的视频，当我们不暂停，正常播放时，会在 10:10 的时间点播放完。startTime = 10:00

- 同理，如果在播放了 3 分钟后，我们选择了暂停视频的 5 分钟，恢复播放时是在 10:08 分。假设解析速度不变，则已经播放了 3 分钟，我们还会继续播放 7 分钟，相当于视频从 3 分钟前 10:05 开始播放。即 startTime = System.currentTimeMillis() - currentPlayTime。startTime = 10:05。

```kotlin
// 恢复解码
fun resume() {
    // 暂停后恢复了，音频解析慢了，startTime 加上差值对齐时间戳。否则视频视频播放会过快
    startMs = System.currentTimeMillis() - currentSampleTime
    state = MediaCodecState.RUNNING
}
```

seek 操作以及暂停后恢复的 startTime 改变，按照上面的解释，实际上可以统一。

至此，MediaCodec 解码 mp4 并播放的相关知识点，我们就讲解完了。完整源码请移步 Github。感谢大家的阅读。