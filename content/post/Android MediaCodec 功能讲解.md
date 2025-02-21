---
title: "Android MediaCodec 功能讲解"
description: "本文讲解了 Android MediaCodec 的功能"
keywords: "Android,音视频开发,MediaCodec"

date: 2023-04-15T13:43:00+08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - MediaCodec

url: post/D08E5E865578467FB0D8D4F753FE89EE.html
toc: true
---

本文讲解了 Android MediaCodec 的功能。

<!--More-->

上篇博文：[Android MediaPlayer 功能讲解](BD5946122B3348138BB493005FA20EBD.html)

MediaCodec 是 Android 系统提供的用于对音视频进行编解码的类，它通过访问底层的 codec 来实现编解码的功能。Codec 意为编解码器。MediaCodec 是 Android media 基础框架的一部分，是比 MediaPlayer 更底层的实现。MediaCodec 通常同 MediaExtractor、MediaSync、MediaMuxer、MediaCrypto、MediaDrm、Image、Surface 和 AudioTrack 等一起使用。

## 权限申请

在介绍 MediaCodec 的相关知识之前，我们需要先了解下播放音视频需要申请哪些权限：

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

## 数据类型

MediaCodec 可以操作三种类型的数据：

- 压缩数据(compressed data)
- 原始音频数据(raw audio data)
- 原始视频数据(raw video data)。

虽然这三种数据都可以使用 ByteBuffers 承载处理，但对于原始视频数据(raw video data)，更倾向于使用 Surface，以提高编解码器性能。Surface 使用了 native 视频缓冲区(native video buffers)，原始视频数据无需映射或复制到 ByteBuffers 中，因此它更有效率。

使用 Surface 时，我们需要注意虽然通常无法访问原始视频数据，但是我们可以使用 ImageReader 类来访问不安全的已解码视频帧，通常这种方式仍然比使用 ByteBuffers 更有效，因为此时部分 native 缓冲数据可能会映射到 Direct ByteBuffers，Direct ByteBuffer 的字节数据直接存放在堆外内存中，而不是堆内存中。

如果不使用 Surface，而是使用 ByteBuffer 模式，则我们可以使用 MediaCodec.getInputImage(int index) 方法和 MediaCodec.getOutputImage(int index) 方法来获取 Image 类，通过 Image 类来访问已解码视频帧数据。

### Compressed Buffers

Compressed Buffers 中的数据是压缩数据。所谓压缩数据，就是指编码过的数据。所以压缩缓冲区承载的实际上就是编码过的音视频数据。

- 对于解码器而言，压缩缓冲区就是输入缓冲区(Input buffers)
- 对于编码器而言，压缩缓冲区就是输出缓冲区(output buffers)

当包含视频数据时，压缩缓冲区中通常是单个编码过的视频帧

当包含音频数据时，压缩缓冲区中通常包含 n(n >= 1) 个编码过的音频帧。无论压缩缓冲区中包含几个编码过的音频帧，缓冲区的数据都是在帧的边界开始或结束；如果想要在任意字节开始或结束，需要给 MediaCodec 设置 BUFFER_FLAG_PARTIAL_FRAME 标记。

注意音频数据是流式的，本身没有明确的一帧帧的概念，在实际的应用中，为了方便音频算法的处理和传输，一般约定一个可单独访问处理的音频段为一个音频帧。一个音频帧可能包含几到几十毫秒的音频数据，音频帧的时长和格式由对应的音频格式决定。

### Raw Audio Buffers

Raw Audio Buffers 中的数据是完整的 PCM 音频帧，PCM 音频数据是按照音频通道顺序为每个音频通道进行采样后得到的数据。每个 PCM 音频样本都是一个有符号整数或一个浮点数，整数或者浮点数的长度为 8 bit(一个 byte)或者 16 bit(两个 byte)。

- 音频采样通常都是 2 个字节采样，1 个字节的音频采样比较少见(比如 amr 音频编码)，除非是特别低端的设备才会用到一个字节。
- 每个 PCM 样本数据的排序都采用 native 字节顺序，即大端序或者小端序，这是个比较容易踩坑的知识点
- PCM 中的数据通常都是整型，浮点型的情况只出现在使用 MediaCodec.configure 方法，将 MediaFormat#KEY_PCM_ENCODING 属性的值设置成了 AudioFormat#ENCODING_PCM_FLOAT，并由 codec 证实确实是这样。解码器通过 MediaCodec.getOutputFormat() 判断，编码器通过 MediaCodec.getInputFormat() 判断。这两个方法返回的都是 MediaFormat，我们需要在 MediaFormat 中通过以下代码来检查 PCM 数据是否是 float 的：

```java
static boolean isPcmFloat(MediaFormat format) {
    return format.getInteger(
        MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT
    ) == AudioFormat.ENCODING_PCM_FLOAT;
}
```

另外我们可以使用以下代码，从原始音频缓冲区中，提取某个音频通道的 16 bit 带符号整型音频数据，到 short(长度 2 个字节)数组中，ByteBuffer 和 ShortBuffer 的使用方法可以自行上网搜索，此处就不讲了，感兴趣的可以看我的另一篇文章的结尾讲解：[Android 生产者-消费者模型实现数据同步](https://www.cnblogs.com/wellcherish/p/14782080.html)：

```java
short[] getSamplesForChannel(
    MediaCodec codec, 
    int bufferId, 
    int channelIndex
) {
    // 获取输出缓冲区
    ByteBuffer outputBuffer = codec.getOutputBuffer(bufferId);
    // 获取输出数据的格式
    MediaFormat format = codec.getOutputFormat(bufferId);
    // 指定缓冲区数据的数据，并将字节缓冲区转换成 Short 缓冲区
    ShortBuffer samples = outputBuffer.order(
        ByteOrder.nativeOrder()
    ).asShortBuffer();
    // 获取音频通道的数量
    int numChannels = format.getInteger(
        MediaFormat.KEY_CHANNEL_COUNT
    );
    // 数据有效性检查
    if (channelIndex < 0 || channelIndex >= numChannels) {
        return null;
    }
    // remaining()方法返回的是 current position 到 Limit 的长度
    // 此处表示 ShortBuffer 的长度
    short[] res = new short[samples.remaining() / numChannels];
    // 核心代码，取第 channelIndex 个通道的数据
    for (int i = 0; i < res.length; ++i) {
      res[i] = samples.get(i * numChannels + channelIndex);
    }
    return res;
}
```

### Raw Video Buffers

在 ByteBuffer 模式下，Raw Video Buffers 中的视频数据的放置方式是根据其颜色格式(color format)决定的。我们可以使用 getCodecInfo().getCapabilitiesForType().colorFormats 方法获取 MediaCodec 支持的颜色格式的数组。MediaCodec 支持三种颜色格式：

- native raw video format：该格式是 native 原始视频格式，对应的定义是 CodecCapabilities#COLOR_FormatSurface。native raw video format 格式可以与 input Surface 或者 output Surface 一起使用。

- YUV 相关颜色格式：YUV 格式有许多变种，例如 CodecCapabilities#COLOR_FormatYUV420Flexible，这些 YUV 格式可以与 input Surface 或者 output Surface 一起使用；也可以在 ByteBuffer 模式下，与 Image 类、MediaCodec.getInputImage(int index) 方法和 MediaCodec.getOutputImage(int index) 方法一起使用。

- 其他特定的颜色格式：其他颜色格式通常仅在 ByteBuffer 模式下受支持，并且一些颜色格式仅限于供应商支持。这些格式都是在 CodecCapabilities 中定义的。同 YUV 相关颜色格式一样，这些格式可以与 Image 类、MediaCodec.getInputImage(int index) 方法和 MediaCodec.getOutputImage(int index) 方法一起使用。

注意自 Android 5.1(API 等级 22，Build.VERSION_CODES.LOLLIPOP_MR1) 开始，所有视频编解码器都支持 YUV 4:2:0 格式的 buffers。另外在 Android 5.0(API 等级 21) 和 Image 类的支持出现之前，我们需要使用 MediaFormat#KEY_STRIDE 和 MediaFormat#KEY_SLICE_HEIGHT 属性了解 Raw Video ByteBuffers 中的数据放置方式。相关属性的解释可见 MediaFormat 的类文档以及 YUV 格式的讲解。

#### 视频帧的宽高

要获取/设置视频帧的宽高，我们需要使用到 MediaFormat#KEY_WIDTH 和 MediaFormat#KEY_HEIGHT 属性。然而，在大多数情况下，实际展示的视频(图片)只占视频帧的一部分，用"crop rectangle"表示。

要获取视频实际可用的尺寸，我们需要使用以下属性从 getOutputFormat 方法中获取到原始输出图像的"crop rectangle"范围。如果这些属性的值都不存在，则视频的范围是整个视频帧。

||||
|:-:|:-:|:-:|
|**属性**|**值类型**|**说明**|
|MediaFormat#KEY_CROP_LEFT|Integer|裁剪矩形的左坐标(x)|
|MediaFormat#KEY_CROP_TOP|Integer|裁剪矩形的顶坐标(y)|
|MediaFormat#KEY_CROP_RIGHT|Integer|裁剪矩形的右坐标(x-1)|
|MediaFormat#KEY_CROP_BOTTOM|Integer|裁剪矩形的底坐标(y-1)|

根据"crop rectangle"的范围，我们可以计算视频帧为旋转时的实际可用尺寸：

```java
// 获取输出格式
MediaFormat format = decoder.getOutputFormat(…);
int width = format.getInteger(MediaFormat.KEY_WIDTH);
// 存在"crop rectangle"时的宽度
if (format.containsKey(MediaFormat.KEY_CROP_LEFT)
    && format.containsKey(MediaFormat.KEY_CROP_RIGHT)
) {
    // 11 12 两列(共有 (12 - 11) + 1 列)
    width = format.getInteger(MediaFormat.KEY_CROP_RIGHT)
        - format.getInteger(MediaFormat.KEY_CROP_LEFT) + 1;
}
int height = format.getInteger(MediaFormat.KEY_HEIGHT);
// 存在"crop rectangle"时的高度
if (format.containsKey(MediaFormat.KEY_CROP_TOP)
    && format.containsKey(MediaFormat.KEY_CROP_BOTTOM)
) {
    height = format.getInteger(MediaFormat.KEY_CROP_BOTTOM)
        - format.getInteger(MediaFormat.KEY_CROP_TOP) + 1;
}
```

另外注意 BufferInfo.offset 在不同设备上的含义可能不同。在大多数设备上，它指向整个帧的左上角像素；而在某些设备上，它指向"crop rectangle"的左上角像素。

## MedidCodec 的状态

从概念上讲，MedidCodec 的声明周期共有三种状态，这三种状态各自又是几种更细分状态的集合：

1. Stopped 状态
   - Uninitialized 状态
   - Configured 状态
   - Error 状态
2. Executing 状态
   - Flushed
   - Running
   - End-of-Stream
3. Released

下图是 Android 官方给出的 MediaCodec 的生命周期状态图：

![MediaCodec的生命周期状态图](/imgs/MediaCodec的生命周期状态图.webp)

Stopped 状态具有三个子状态：Uninitialized、Configured 和 Error。

1. 有三种方式可以使 MediaCodec 进入 Uninitialized 子状态：

   - 使用工厂方法创建 MediaCodec 实例时，MediaCodec 处于 Uninitialized 状态

   - 处于 Executing 状态时，调用 MediaCodec.stop() 方法可以使 MediaCodec 返回到 Uninitialized 状态

   - 任何状态下调用 MediaCodec.reset() 方法，将 MediaCodec 移回 Uninitialized 状态

2. Uninitialized 状态下，我们需要调用 MediaCodec.configure() 方法配置 MediaCodec，配置成功后 MediaCodec 进入 Configured 状态

3. Configured 状态下，我们需要调用 MediaCodec.start() 方法使 MediaCodec 进入 Executing 状态。在 Executing 状态下，我们可以使用上面讲解到的 MediaCodec 使用步骤，在循环中处理目标数据

4. 在极少数情况下，MediaCodec 可能会遇到错误并进入 Error 状态。MediaCodec 的错误传递，可以通过队列操作返回无效值或者抛出异常。Error 状态下可以调用 MediaCodec.reset() 方法使 MediaCodec 变得可用；或者调用 MediaCodec.release() 方法移动 MediaCodec 到最后的 Released 状态

Executing 状态具有三个子状态：Flushed、Running 和 End-of-Stream：

1. 在调用了 MediaCodec.start() 之后，编解码器立即进入 Flushed 子状态，其中包含所有缓冲区。对于处于 Executing 状态的 decoder，我们可以随时调用 flush() 方法返回到 Flushed 子状态，注意此操作仅支持 decoder

2. 一旦第一个输入缓冲区出队，MediaCodec 就会进入 Running 子状态，MediaCodec 大部分的生命周期都处于 Running 自状态

3. 当待处理数据全部传递给 MediaCodec 后，我们可以在 input buffers 队列中为最后一个入队的 input buffer 添加 MediaCodec.BUFFER_FLAG_END_OF_STREAM 标记，遇到这个标记时，MediaCodec 会转换为 End-of-Stream 子状态。在此状态下，MediaCodec 不再接受新的输入，但是仍然会继续生成输出，直到输出到达 end-of-stream

使用完 MediaCodec 后，我们必须调用 MediaCodec.release() 方法进行释放。使 MediaCodec 进入 Released 状态。

### 创建 MediaCodec

对于 MediaCodec 实例的创建，通常需要使用以下几个步骤：

1. 解码音视频文件或流时，我们可以使用 MediaExtractor.getTrackFormat(int index) 方法获取特定轨道的格式

2. 使用 MediaFormat.setFeatureEnabled(String feature, boolean enabled) 方法启用/禁用特定功能。feature 的取值为 MediaCodecInfo.CodecCapabilities 类中以 FEATURE 开头的常量

3. 使用 MediaCodecList.findDecoderForFormat(MediaFormat format) 获取可以处理该媒体格式的编解码器的名称

4. 使用 MediaCodec.createByCodecName(String) 创建 MediaCodec 的实例

注意在 Android 5.0(API 等级 21) 上，传递给 MediaCodecList.findDecoder/EncoderForFormat 方法的 MediaFormat 不能包含帧率。我们需要使用 MediaFormat.setString(MediaFormat.KEY_FRAME_RATE, null) 语句清除 MediaFormat 中现有的帧率设置。

MediaCodec 实例的另一种创建方式是使用 MediaCodec.createDecoder/EncoderByType(String) 方法，此方法可以为特定的 MIME 类型创建编解码器。但是这种方法不能启用特定功能，并且创建的编解码器存在无法处理目标格式音视频数据的可能。

#### 创建安全的解码器

安全的解码器是指可以解密视频的解码器。

在 Android 4.4(API 等级 20) 及更早的系统版本中，即使安全的编解码器(secure decoders)在系统上可用，但这些 codec 仍然有可能不会列举到 MediaCodecList 中。此时 secure decoders 器只能通过名称来创建实例，方法是将".secure"后缀附加到常规 codec 名称的后面(所有安全的编解码器的名称必须以".secure"结尾)。

如果系统上不存在安全的编解码器，则 MediaCodec.createByCodecName(String) 方法会抛出 IOException 异常。

从 Android 5.0(API 等级 21) 开始，我们需要使用 MediaFormat.setFeatureEnabled 方法，将 CodecCapabilities#FEATURE_SecurePlayback 功能设置为 true，以创建安全的解码器。

### MediaCodec 的初始化

创建 Codec 后，我们可以使用如下步骤异步处理数据：

1. 使用 setCallback(MediaCodec.Callback cb, Handler handler) 方法设置 Callback 回调

2. 如果需要解码视频，则拿到用于视频展示的 Surface；编码视频以及音频处理不需要这个步骤

3. 调用 configure(MediaFormat, Surface, MediaCrypto, int flags) 方法：

   - 使用特定的 MediaFormat 配置编解码器

   - 如果是解码视频，还传入用于展示视频的 Surface；如果不是解码视频，则 Surface 传 null 即可

   - 如果需要解密视频，我们还需要为安全的编解码器设置解密参数(见 MediaCrypto 类)；如果不需要解密视频，则 MediaCrypto 传 null 即可

   - 最后，由于某些 Codec 可以在多种模式下运行，所以我们还可以指定 Codec 是按照解码器配置还是按照编码器配置。我们可以传入 MediaCodec.CONFIGURE_FLAG_ENCODE 标记，以将 MediaCodec 按照编码器配置。

4. 从 Android 5.0(API 等级 21) 开始，Configured 状态下可以查询输入输出格式，我们可以据此验证得到的配置是否符合预期(例如在调用 start 方法之前，检查颜色格式是否 OK)

5. 除了直接操作 input buffer 之外，我们还有另一种方式来告知 MediaCodec 需要编码的数据。我们可以在 configure 之后，start 之前，调用 createInputSurface() 为输入数据创建一个目标 Surface；或者调用 setInputSurface(Surface) 为 codec 设置先前创建的 Input Surface。我们在这个 Surface 中"作画"，MediaCodec 就能够自动的编码 Surface 中的"画作"，我们只需要从 output buffer 取出编码完成之后的数据即可。
   
   例如在使用 OpenGL 将录制内容显示到屏幕上时，我们同时可以将 OpenGL 的内容绘制到目标 Surface 中，此时 MecodeCodec 会对内容进行编码(H.264)，我们拿到编码内容就可以进行封装了(mp4)。

#### Codec-specific Data

解码音视频数据时，有些数据可能并不是视频的组成部分(即不是 YUV 数据)，而是些特殊数据，例如解码部分音视频格式如 AAC 音频格式、MPEG4、H.264 和 H.265 视频格式等时，需要指定一个特殊的前缀设置信息(setup data)或针对 codec 的设置信息(codec specific data)。这个设置信息通常包含在已编码的数据中，但是需要自己提取出来。想要提取这个设置信息(非实际的音视频数据)，必须在调用 queueInputBuffer 方式时传入 MediaCodec.BUFFER_FLAG_CODEC_CONFIG 标记。

针对 codec 的特定数据(codec specific data)可以通过以下步骤传递给 codec：

1. 在 MediaFormat 中调用 setByteBuffer(String name, ByteBuffer bytes) 方法塞入 name 为 name，value 为 bytes 的键值对。name 的取值为 "csd-0"、"csd-1"，以此类推。csd 意为 c odec specific data。
2. 调用 configure 将设置了 csd 的 MediaFormat 传递给 MediaCodec。

"csd-0"、"csd-1" 等键值对应的信息始终包含在使用 MediaExtractor 解析获得的 MediaFormat 的轨道(media track)中。csd 在 MediaCodec.start() 方法被调用时会自动提交给 codec；我们不能手动提交此数据。

如果目标格式不包含 csd，我们可以根据格式的要求，选择使用指定数量的缓冲区以正确的顺序提交 csd。例如对于 H.264 AVC 格式，我们可以使用单个 codec-config buffer 填充所有的 csd。

下表列举了 Android 定义的可以包含 csd buffers 的格式及对应的含义。为了实现正确的 MediaMuxer 轨道配置(MediaMuxer track configuration)，这些 buffers 的信息也需要在轨道格式(track format)中进行设置。标有(*)的每个参数结合，以及标有(*)的 csd 部分，必须以"\x00\x00\x00\x01"代码开头。

![Android定义的csd](/imgs/Android定义的csd.webp)

这张表的含义以后再做解释，涉及到的知识点比较多。此处就不讲了。

注意如果在 codec start 后不久，output buffer 或者 output format change 尚未返回之前就 flush 了 codec，则相关 csd 可能在 flush 期间丢失。我们必须在 flush 后重新使用标有 BUFFER_FLAG_CODEC_CONFIG 的 buffers，以确保 codec 的操作无异常。

注意在标有 codec-config flag 的任何有效 output buffer 之前，编码器将创建并返回 csd，可以理解为 csd 创建返回的时机在 setup data 之前。包含 csd 的 buffer 中的时间戳没有任何意义。

## MediaCodec 的数据处理

调用了 start 方法后，MediaCodec 就开始处理数据了。MediaCodec 的处理流程如下图所示：

![MediaCodec的处理流程](/imgs/MediaCodec的处理流程.webp)

MediaCodec 处理输入数据(input data)以生成输出数据(output data)，有同步和异步两种数据处理方式。每个 Codec 都维护了一组 input buffers 和 output buffers，这些 buffer 通过 buffer-ID 标识。简单的讲，我们通过以下步骤使用 MediaCodec：

1. 请求(或接收)一个空的输入缓冲区(empty input buffer)

   - 在同步模式下，调用 MediaCodec.dequeueInputBuffer() 方法从 codec 获取 input buffer

   - 在异步模式下，我们需要通过 MediaCodec.Callback.onInputBufferAvailable() 回调方法获取可用的 input buffer

2. 向 empty input buffer 中填入数据

3. 传递带输入数据的输入缓冲区给编解码器(Codec)进行处理

   调用 MediaCodec.queueInputBuffer 方法将其提交给Codec；如果需要解密视频，则需要使用 queueSecureInputBuffer。注意除非是 csd 数据，否则不同的 input buffer 不能具有相同的时间戳。

4. 编解码器处理数据

5. 处理完成后，Codec 将处理结果输出至一个空的输出缓冲区(empty output buffer)

6. 请求(或接收)一个已填充结果数据的 output buffer

   - 在同步模式下，调用 MediaCodec.dequeueOutputBuffer() 方法从 codec 获取 output buffer

   - 在异步模式下，我们需要通过 MediaCodec.Callback.onOutputBufferAvailable() 回调方法获取可用的 output buffer

7. 使用 output buffer

8. 使用完缓冲区后，调用 releaseOutputBuffer 方法将 buffer 返回给 codec

注意我们虽然不需要立即将 buffer 提交或释放给 codec(submit input buffer/release output buffer)，但保留 input/output buffer 过久可能会使 codec 停止运行(视实际设备而定)。此时 codec 可能会推迟生成 output buffer，直到所有 input/output buffer 的处置权都归还给 codec。因此，客户端应尽量少占用可用的 buffer。

根据 Android 版本的不同，我们可以让 MediaCodec 通过三种方式处理数据：

|**处理方式**|**API version <= 20**|**API version >= 21**|
|:-:|:-:|:-:|
|使用 buffer arrays 的同步 API|支持|Deprecated|
|使用 buffers 的同步 API|不可用|支持|
|使用 buffers 的异步 API|不可用|支持|

### 使用 buffers 的异步 API 的示例代码

自 Android 5.0(API 等级 21) 开始，官方优先推荐异步方式处理数据：在调用 configure 方法之前设置回调。异步模式稍微改变了状态转换，在调用 flush() 方法之后，我们必须手动调用 start() 方法，以将 codec 转换到 Running 子状态并开始接收 input buffer。类似地，在调用 start() 方法后，codec 将直接转换到 Running 子状态。

![异步模式状态转换](/imgs/异步模式状态转换.webp)

```java
// 1. 创建 MediaCodec 的实例
MediaCodec codec = MediaCodec.createByCodecName(name);
MediaFormat mOutputFormat;
// 2. 设置回调，使 MediaCodec 异步处理数据
codec.setCallback(new MediaCodec.Callback() {
    @Override
    void onInputBufferAvailable(MediaCodec mc, int inputBufferId) {
        // 拿到 inputBuffer
        ByteBuffer inputBuffer = codec.getInputBuffer(inputBufferId);
        // 省略填充数据到 inputBuffer
        codec.queueInputBuffer(inputBufferId, …);
    }
 
    @Override
    void onOutputBufferAvailable(MediaCodec mc, int outputBufferId, …) {
        // 拿到 outputBuffer
        ByteBuffer outputBuffer = codec.getOutputBuffer(outputBufferId);
        mOutputFormat = codec.getOutputFormat(outputBufferId);
        // 省略使用 outputBuffer
        codec.releaseOutputBuffer(outputBufferId, …);
    }
 
    @Override
    void onOutputFormatChanged(MediaCodec mc, MediaFormat format) {
        // 后续数据将使用新 format
        // 使用 getOutputFormat 方法获取了 MediaFormat 后，该回调可省略
        mOutputFormat = format;
    }
 
    @Override
    void onError(…) {
        // 错误处理省略
    }
    @Override
    void onCryptoError(…) {
        // 解密错误省略
    }
 });
// 3. 配置 MediaCodec
codec.configure(format, …);
// 获取 MediaFormat
mOutputFormat = codec.getOutputFormat();
// 4. 开始
codec.start();

...

// 5. 停止
codec.stop();
// 6. 释放
codec.release();
```

### 使用 buffers 的同步 API 的示例代码

自 Android 5.0(API 等级 21) 开始，在同步模式下使用 getInput/OutputBuffer(int) 和 getInput/OutputImage(int) 检测 input/output buffer，使用这些方法允许框架进行某些优化(例如在处理动态内容时)。如果调用的是 getInput/OutputBuffers() 方法，则此优化将被禁用。

```java
// 1. 创建 MediaCodec 的实例
MediaCodec codec = MediaCodec.createByCodecName(name);
// 2. 配置 MediaCodec
codec.configure(format, …);
// 获取 MediaFormat
MediaFormat outputFormat = codec.getOutputFormat();
// 3. 开始
codec.start();
// 循环处理数据
while(true) {
    // 拿到 inputBufferId
    int inputBufferId = codec.dequeueInputBuffer(timeoutUs);
    if (inputBufferId >= 0) {
        // 拿到 inputBuffer
        ByteBuffer inputBuffer = codec.getInputBuffer(…);
        // 省略填充数据到 inputBuffer
        codec.queueInputBuffer(inputBufferId, …);
    }
    // 拿到 outputBufferId
    int outputBufferId = codec.dequeueOutputBuffer(…);
    if (outputBufferId >= 0) {
        // 拿到 outputBuffer
        ByteBuffer outputBuffer = codec.getOutputBuffer(outputBufferId);
        // 后续数据将使用新 format
        MediaFormat bufferFormat = codec.getOutputFormat(outputBufferId); 
        // 省略使用 outputBuffer
        // 使用完 outputBuffer 后，释放给 codec
        codec.releaseOutputBuffer(outputBufferId, …);
    } else if (outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
        // 后续数据将使用新 format
        // 使用 getOutputFormat 方法获取了 MediaFormat 后，该 id 可省略
        outputFormat = codec.getOutputFormat();
    }
}
// 4. 停止
codec.stop();
// 5. 释放
codec.release();
```

#### 使用 buffer arrays 的同步 API 的示例代码

注意：该 API 已被废弃，仅作参考。

```java
// 代码已被废弃，仅作参考
MediaCodec codec = MediaCodec.createByCodecName(name);
codec.configure(format, …);
codec.start();
// 区别重点在 buffer 的获取
ByteBuffer[] inputBuffers = codec.getInputBuffers();
ByteBuffer[] outputBuffers = codec.getOutputBuffers();
while(true) {
    int inputBufferId = codec.dequeueInputBuffer(…);
    if (inputBufferId >= 0) {    
        // 填充数据到 inputBuffers[inputBufferId]
        codec.queueInputBuffer(inputBufferId, …);
    }
    int outputBufferId = codec.dequeueOutputBuffer(…);
    if (outputBufferId >= 0) {
        // 使用 outputBuffers[outputBufferId] 中的数据
        codec.releaseOutputBuffer(outputBufferId, …);
    } else if (outputBufferId == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
        outputBuffers = codec.getOutputBuffers();
    } else if (outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
        MediaFormat format = codec.getOutputFormat();
    }
}
codec.stop();
codec.release();
```

### 处理 End-of-stream

当输入到达末尾时，我们必须在调用 queueInputBuffer 时指定 MediaCodec.BUFFER_FLAG_END_OF_STREAM 标志。我们可以为最后一个有效的 input buffer 设置此标志；也可以提交一个额外的指定了 MediaCodec.BUFFER_FLAG_END_OF_STREAM 标志的空 input buffer。如果使用空 buffer，则时间戳将被忽略。

codec 会继续返回 output buffer，直到它最终在 BufferInfo 中指定了相同的 BUFFER_FLAG_END_OF_STREAM 标志，此 BufferInfo 是我们通过 dequeueOutputBuffer 方法传给 codec 的，codec 可以向其设置 flags。在异步模式下，onOutputBufferAvailable 回调方法会返回一个 BufferInfo。BUFFER_FLAG_END_OF_STREAM 标志可以设置在最后一个有效的 output buffer，或者设置在一个额外的空 output buffer 上。这种空 buffer 的时间戳应该被忽略。

除非编解码器已被 flushed(或 stopped 后 restarted)，否则不能在设置了 BUFFER_FLAG_END_OF_STREAM flag 后向 codec 提交额外的 input buffer。

### 使用 output Surface

使用 output Surface 时，数据的处理几乎与 ByteBuffer 模式相同，只是此时 output buffers 将不可访问，并为 null。例如。 getOutputBuffer/getOutputImage(int) 方法将返回 null，而 getOutputBuffers() 方法将返回一个仅包含 null 的数组。

使用 output Surface 时，我们可以选择是否在 Surface 上渲染每个 output buffer，有三个选择：

- 不渲染缓冲区：调用 releaseOutputBuffer(bufferId, false)。
- 使用默认时间戳渲染缓冲区：调用 releaseOutputBuffer(bufferId, true)。
- 使用特定时间戳渲染缓冲区：调用 releaseOutputBuffer(bufferId, timestamp)。

从 Android 6.0(API 等级 23) 开始，默认时间戳是 buffer 的 PTS( presentation timestamp)，时间会转换为纳秒。此外，从 Android 6.0(API 等级 23) 开始，我们可以使用 setOutputSurface 方法动态更改 output Surface。

将输出渲染到 Surface 时，Surface 可以被配置为丢弃过多的帧(即 Surface 会丢弃未及时消耗的帧)；也可以被配置为不丢弃过多的帧。不丢弃过多的帧时，如果 Surface 没有及时消耗输出帧，则 Surface 最终会阻塞 decoder。

在 Android 10(API 等级 29) 之前，View surfaces(SurfaceView 或 TextureView) 总是会丢弃过多的帧。从 Android 10(API 等级 29) 开始，默认模式是丢弃过多的帧，但 app 可以在 MediaFormat 中将 MediaFormat#KEY_ALLOW_FRAME_DROP 属性的值设置为 0，为 non-View surfaces(例如 ImageReader 或 SurfaceTexture)设置不丢弃过多的帧。该 MediaFormat 通过 MediaCodec.configure 方法传给 codec。

#### 渲染到 Surface 时的变换操作

渲染到 Surface 时的变换操作，有一些注意事项：

- 如果 codec 被配置为 Surface 模式，则任何的矩形裁剪、旋转和视频缩放模式变换都将自动应用。但是有一个例外：在 Android 6.0(API 等级 23) 之前，软件解码器在渲染到 Surface 上时可能不会应用旋转。此时没有标准简单的方法来识别软件解码器，同时也没有标准简单的方法判断软件解码器是否应用了旋转操作。

- 在 Surface 上显示输出时默认不需要考虑像素宽高比，输出会自适应 Surface 的尺寸。我们也可以手动调用 MediaCodec.setVideoScalingMode 方法为 codec 指定 VIDEO_SCALING_MODE_SCALE_TO_FIT 模式，或者当宽高比为 1:1 时，指定 VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING 模式。

- 从 Android 7.0(API 等级 24) 开始，对于旋转了 90 或 270 度的视频，VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING 模式可能无法正常工作。

- 设置了视频缩放模式时，需要每次输出缓冲区更改后都必须重新设置(因为此时缩放模式会被重置)。由于 INFO_OUTPUT_BUFFERS_CHANGED 事件已被弃用，我们需要在每次输出格式更改后执行此操作(INFO_OUTPUT_FORMAT_CHANGED 事件)。

### 使用 input Surface

使用 input Surface 时，input buffers 将不可访问，因为 buffers 会自动从  input Surface 传递到 codec。此时调用 dequeueInputBuffer 将抛出 IllegalStateException 异常；调用 getInputBuffers() 会返回一个只读的虚假 ByteBuffer[] 数组。

使用 input Surface 时，我们需要调用 signalEndOfInputStream() 以发出 end-of-stream 信号。在 signalEndOfInputStream 方法调用之后，input Surface 会立即停止向 codec 提交数据。

## 跳转和自适应播放

无论是否支持自适应播放，以及无论是否被配置成自适应播放，对于跳转(seek)和格式更改的处理，视频解码器的行为都存在不同。我们可以通过 CodecCapabilities.isFeatureSupported(String) 检测解码器是否支持自适应播放。注意仅当 decoder 在 Surface 上解码时，video decoder 的自适应播放才生效。

### 关键帧

调用 start() 方法或 flush() 方法之后的输入数据的第一帧必须是关键帧(key frame)。在 decoder 中，关键帧就是 I 帧。

- 对于 H.265 HEVC 格式，关键帧就是 IDR 或 CRA
- 对于 H.264 AVC 格式，关键帧就是 IDR
- 对于 H.263、VP8、VP9、MPEG-2、MPEG-4 等格式，关键帧并没有明确的命名

对于数据提交的一些注意事项如下：

1. 对于不支持自适应播放的解码器(包括不解码到 Surface 的情况)。如果想要解码与先前已提交的数据不相邻的数据(例如在 seek 操作后解码新的数据)，我们必须 flush 解码器。但是由于所有的 output buffers 在 flush 后都会立即被撤销，所以我们需要先发出 end-of-stream 信号，直到流结束，再调用 flush 方法。注意 flush 后，应该选择合适的关键帧，重新提交数据给解码器。

   注意 flush 后提交的数据的格式不能改变，flush() 不支持格式改变；当格式改变时，如果需要重新开始播放，则需要完整的调用 stop() - configure() - start() 方法链。

   另外还需要注意，如果在调用了 start() 方法后，我们过早的刷新了 codec，将我们需要将 csd 数据重新提交给 codec。例如调用了 start() 方法后，在收到第一个 output buffer 或者 output format change 信号之前，我们就调用了 flush() 方法，则此时我们需要重新提交 csd 数据给 codec。

2. 对于支持自适应播放的解码器。如果想要解码与先前已提交的数据不相邻的数据(例如在 seek 操作后解码新的数据)，我们不必 flush 解码器。但是，不相同的输入数据必须从合适的关键帧开始。

   对于某些视频格式，即 H.264、H.265、VP8 和 VP9，也可以在数据流中更改图片大小或配置。为了达到此效果，我们必须将整个新的 csd 配置数据和关键帧一起打包到单个 buffer中，并将其作为常规 input buffer 提交。
   
   在图片尺寸发生改变之后、任何新尺寸的帧被返回之前，我们将从 dequeueOutputBuffer 或 onOutputFormatChanged 回调中收到一个 INFO_OUTPUT_FORMAT_CHANGED 信号。注意就像 csd 一样，需要格外当心在更改图片尺寸后不久调用 flush() 方法。如果我们没有收到图片尺寸更改的确认信号，则我们需要重新申请新的图片尺寸。

## 错误处理

1. 工厂方法 createByCodecName 和 createDecoder/EncoderByType 在失败时会抛出 IOException，我们必须捕获或向上抛出(catch or throws)
2. 如果方法在不恰当的 codec 状态下调用，则MediaCodec 方法会抛出 IllegalStateException
3. 涉及安全缓冲区(secure buffers)的方法可能会抛出 CryptoException，此时可以通过 CryptoException#getErrorCode 方法获得的更多错误信息
4. codec 的内部错误会导致 CodecException，这可能是因为媒体内容损坏、硬件故障、资源耗尽等原因导致的。接收到 CodecException 时，我们可以确定更具体的错误，要确定该信息，可以调用 CodecException#isRecoverable 方法和 CodecException#isTransient 方法：

   1. 可恢复错误(recoverable errors)：如果 isRecoverable() 方法返回 true，则我们可以调用 stop()-configure()-start() 方法链来进行恢复操作。
   2. 瞬态错误(transient errors)：如果 isTransient() 返回 true，则资源(如硬件资源)暂时不可用，过段时间后可再次尝试访问资源(如硬件资源可用时，重新开始编解码)。
   3. 致命错误(fatal errors)：如果 isRecoverable() 和 isTransient() 都返回 false，则 CodecException 是致命错误，codec 必须 reset 或者 release。
   4. 注意 isRecoverable() 和 isTransient() 不会同时返回 true。

## 视频编码的最低质量标准

从 Android S(即 Android 12，API 等级 31)开始，Android 的视频编解码强制执行最低质量标准，以消除差质量的视频编码。最低质量标准仅对可变比特率(VBR)模式，以及尺寸在 (320x240, 1920x1080] 视频分辨率的视频生效。即：

- 当视频的尺寸为 320x240 及更低的分辨率时，最低质量标准不生效
- 当视频的尺寸高于 1920x1080 分辨率时，最低质量标准不生效
- 当视频编解码器处于恒定比特率(CBR)模式时，最低质量标准不生效

当最低质量标准生效时，Android 的编解码器和音视频框架会确保生成的视频至少具有"一般"或"良好"的质量。判定质量的指标是 VMAF (Video Multi-method Assessment Function)，指标的目标分数为 70。故最低质量标准不会影响用高比特率捕获到的内容，因为高比特率已经为编解码器提供了足够的容量来编码所有细节。

当最低质量标准生效时，生成的某些视频的比特率比我们配置的更高。出现这个情况主要是两种场景：

- 当我们配置的比特率特定比较低时，为了满足最低质量标准，编解码器将选择使用更能生成"一般"或"良好"质量视频的比特率
- 当视频包含非常复杂的内容(比如很多动作和细节)时，编解码器将根据需要使用额外的比特率，以避免丢失内容精细的细节

## 总结

MediaCodec 的基础知识暂时就讲到这里了，下片文章我们来讲讲 MediaCodec 的实际使用。
