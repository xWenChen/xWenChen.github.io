---
title: "Glide 加载本地图片出错问题处理"
description: "本文讲解了在 Android 开发中处理的一个 Glide 加载本地图片出错的问题"
keywords: "Android,Glide,源码分析,bug 处理,图片加载"

date: 2023-03-14T14:26:00+08:00

categories:
  - Android
  - Glide
tags:
  - Android
  - Glide
  - 源码分析
  - bug 处理
  - 图片加载

url: post/809BA98B21714461B8D10E54B7310653.html
toc: true
---

本文讲解了在 Android 开发中处理的一个 Glide 加载本地图片出错的问题。

<!--More-->

## 问题描述

我开发的一个需求中，需要读取图片，然后解析出图片的宽高，并根据宽高做些特殊处理。图片有可能是网络图片或者本地图片。

网络图片需要先下载，再解析宽高。这就涉及到网络图片的缓存管理，刚好项目里有引入 4.11 版本的 Glide，所以自然而然的想到用 Glide 管理缓存：url 先扔给 Glide，Glide 转成 File 扔给我们，我们再使用 File 解析图片的尺寸数据。

根据这个思路，我写了如下的代码：

```kotlin
class MainActivity : AppCompatActivity() {
    companion object {
        const val TAG = "MainActivity"
    }

    // 图片的链接，有可能是网络链接或者本地图片文件地址
    val url = "https://img-blog.csdnimg.cn/75826d2cd45849da84d8bd" +
        "c89c0793f9.png?x-oss-process=image/watermark,type_d3F5LX" +
        "plbmhlaQ,shadow_50,text_Q1NETiBAanhxMTk5NA==,size_20,col" +
        "or_FFFFFF,t_70,g_se,x_16#pic_center"
    // 本地图片链接，具体地址省略
    val filePath = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        Glide.with(applicationContext)
            .asFile()
            .load(url)
            .into(object : CustomTarget<File>() {
                override fun onResourceReady(
                    file: File,
                    transition: Transition<in File>?
                ) {
                    Log.d(TAG, "success, file path is ${file.absolutePath}")
                    // 具体处理逻辑省略
                }

                override fun onLoadCleared(placeholder: Drawable?) {
                    Log.d(TAG, "gg, onLoadCleared")
                }

                override fun onLoadFailed(errorDrawable: Drawable?) {
                    Log.d(TAG, "gg, onLoadFailed")
                }
            })
    }
}
```

很简单的代码，正常情况下，我们只需要在 onResourceReady 方法中拿到 file 并进行处理就行了。但是很不幸，这段代码只对网络图片生效。对于本地图片，这段代码会报错，并走 onLoadFailed 方法。

## Glide 源码流程

既然代码报错了，我们就得改正。修改方式有很多，同时我们仍然可以使用 Glide 管理。但是上面的代码为啥会出错呢？这就得结合源码好好排查下了。按照惯例先上一张 Glide 的加载流程图，方便后面我们叙述：

![Glide的加载流程图](/imgs/Glide的加载流程图.webp)

Glide 的加载流程，会一路经过 Glide ---> RequestManager ---> RequestBuilder -> SingleRequest，然后执行 SingleRequest.begin ---> CustomTarget.getSize -> SingleRequest.onSizeReady，最终在 onSizeReady 方法中调用到 Engine.load 方法。

Engine 中会经过 Engine.load ---> Engine.waitForExistingOrStartNewJob ---> EngineJob.start，最终在 EngineJob.start 方法使用 GlideExecutor 执行 DecodeJob。

### DecodeJob 类讲解

DecodeJob 类的作用是从缓存或原始源解码图片资源，并对图片资源应用转换和转码(transformations and transcodes)。这个类就是文本讲解的核心类。

DecodeJob 能够在线程池 Executor 中运行，是因为它继承自 Runnable。所以 DecodeJob 的核心入口方法是 run 方法。而 run 方法最终又会进入 runWrapped 方法，其源码如下：

```java
private void runWrapped() {
    switch (runReason) {
        case INITIALIZE:
            stage = getNextStage(Stage.INITIALIZE);
            currentGenerator = getNextGenerator();
            runGenerators();
            break;
        case SWITCH_TO_SOURCE_SERVICE:
            runGenerators();
            break;
        case DECODE_DATA:
            decodeFromRetrievedData();
            break;
        default:
            throw new IllegalStateException(
                "Unrecognized run reason: " + runReason
            );
    }
}
```

### runWrapped 方法解析

runReason 是 RunReason 枚举的实例，表示执行解码的原因。其中 INITIALIZE 是初始化状态，首次对图片执行解码，都会执行 INITIALIZE 下的代码。DECODE_DATA 表示有新的图片数据，需要执行解码。

- INITIALIZE 下会依次执行 getNextStage、getNextGenerator、runGenerators 方法。
- DECODE_DATA 下会执行 decodeFromRetrievedData 方法。

stage 是 Stage 枚举的实例，表示图片解码到了哪个阶段了。主要有 INITIALIZE、RESOURCE_CACHE、DATA_CACHE、SOURCE、ENCODE、FINISHED 等阶段。

Stage 类与磁盘缓存策略 DiskCacheStrategy 息息相关。DiskCacheStrategy 有 ALL、NONE、DATA、RESOURCE、AUTOMATIC 五种策略。其含义如下：

- DATA：图片解码前的数据写入磁盘缓存
- RESOURCE：图片解码后的数据写入磁盘缓存
- ALL：解码前后的数据都写入磁盘缓存
- NONE：解码前后的数据都不写入磁盘缓存
- AUTOMATIC：默认策略，根据 DataFetcher 和 ResourceEncoder.EncodeStrategy 自动选择磁盘缓存和解码策略。默认情况下，AUTOMATIC 只会缓存远程图片的解码前数据以及 Glide 执行转换后的图片。缓存的内容则是都会解码。

   ```java
   public static final DiskCacheStrategy AUTOMATIC =
       new DiskCacheStrategy() {
           @Override
           public boolean isDataCacheable(DataSource dataSource) {
               // 默认缓存远程图片
               // DataSource 有 LOCAL(本地数据)、REMOTE、DATA_DISK_CACHE、
               // RESOURCE_DISK_CACHE、MEMORY_CACHE 五种取值
               return dataSource == DataSource.REMOTE;
           }

           @Override
           public boolean isResourceCacheable(
               boolean isFromAlternateCacheKey, 
               DataSource dataSource, 
               EncodeStrategy encodeStrategy
           ) {
               return (
                   (isFromAlternateCacheKey && 
                       dataSource == DataSource.DATA_DISK_CACHE
                   ) || dataSource == DataSource.LOCAL
               ) && encodeStrategy == EncodeStrategy.TRANSFORMED;
           }
           // 解码被缓存的解码后的数据
           @Override
           public boolean decodeCachedResource() {
             return true;
           }
           // 解码被缓存的解码前的数据
           @Override
           public boolean decodeCachedData() {
             return true;
           }
   };
   ```

DataSource 是个枚举类，表示图片数据的来源，有五种枚举取值，其取值含义如下：
- LOCAL：表示数据从本地文件或者 content provider
- REMOTE：表示数据从远程图片得到
- DATA_DISK_CACHE：表示数据从图片未解码的磁盘缓存得到
- RESOURCE_DISK_CACHE：表示数据从图片解码后的磁盘缓存得到
- MEMORY_CACHE：表示数据从图片的内存缓存得到

解释了几个状态量的作用后，我们来解释下三个关键函数的作用。

getNextStage 的源码如下，可以看出，如果 DiskCacheStrategy.decodeCachedResource() 和 DiskCacheStrategy.decodeCachedData() 都成立，则默认情况下，代码的执行流程应该是：INITIALIZE ---> RESOURCE_CACHE ---> DATA_CACHE ---> SOURCE/FINISHED。即图片解码后的数据优先级高于解码前的数据。

```java
private Stage getNextStage(Stage current) {
    switch (current) {
      case INITIALIZE:
        return diskCacheStrategy.decodeCachedResource()
            ? Stage.RESOURCE_CACHE
            : getNextStage(Stage.RESOURCE_CACHE);
      case RESOURCE_CACHE:
        return diskCacheStrategy.decodeCachedData()
            ? Stage.DATA_CACHE
            : getNextStage(Stage.DATA_CACHE);
      case DATA_CACHE:
        // Skip loading from source if the user opted to only retrieve the resource from cache.
        return onlyRetrieveFromCache ? Stage.FINISHED : Stage.SOURCE;
      case SOURCE:
      case FINISHED:
        return Stage.FINISHED;
      default:
        throw new IllegalArgumentException("Unrecognized stage: " + current);
    }
}
```

getNextGenerator 方法的源码如下，其主要作用是根据磁盘缓存策略获取对应的 DataFetcherGenerator，DataFetcherGenerator 用于获取 DataFetcher。DataFetcherGenerator 有三个子类：

- ResourceCacheGenerator：解码后数据的 DataFetcher
- DataCacheGenerator：解码前数据的 DataFetcher
- SourceGenerator：使用 Glide 注册的 ModelLoader 和 load 方法传入的 model(图片源，Glide 抽象成了 model) 从原始源数据生成 DataFetcher。根据磁盘缓存策略，源数据可能首先写入磁盘，然后从缓存文件中加载，而不是直接返回

```java
private DataFetcherGenerator getNextGenerator() {
    switch (stage) {
      case RESOURCE_CACHE:
        return new ResourceCacheGenerator(decodeHelper, this);
      case DATA_CACHE:
        return new DataCacheGenerator(decodeHelper, this);
      case SOURCE:
        return new SourceGenerator(decodeHelper, this);
      case FINISHED:
        return null;
      default:
        throw new IllegalStateException("Unrecognized stage: " + stage);
    }
}
```

runGenerators 方法的源码如下，其主要作用是运行 Generators，核心逻辑在 while 循环中，`currentGenerator.startNext()` 方法会去拿取对应的图片数据。

```java
private void runGenerators() {
    currentThread = Thread.currentThread();
    startFetchTime = LogTime.getLogTime();
    boolean isStarted = false;
    // while 循环和 currentGenerator.startNext() 是核心逻辑
    while (!isCancelled
        && currentGenerator != null
        && !(isStarted = currentGenerator.startNext())) {
      stage = getNextStage(stage);
      currentGenerator = getNextGenerator();

      if (stage == Stage.SOURCE) {
        reschedule();
        return;
      }
    }
    // 流程跑完了还没取到数据，则失败了
    if ((stage == Stage.FINISHED || isCancelled) && !isStarted) {
      notifyFailed();
    }
}
```

decodeFromRetrievedData 方法会一路调用 decodeFromData ---> decodeFromFetcher ---> runLoadPath，最终在 runLoadPath 方法中拿到对应的资源文件。

### DataFetcherGenerator 类解析

ResourceCacheGenerator 类用于获取解码后的图片数据，比如被降采样、转换过的图片。ResourceCacheGenerator 的核心方法是 startNext 方法。

startNext 方法首先会读取 DiskLruCacheWrapper 中缓存的数据文件 cacheFile，并根据 cacheFile 拿到对应的加载器 ModelLoader，最后根据加载器 ModelLoader 拿到 DataFetcher 加载数据，并将返回结果表示解码已经开始(DataFetcher 是异步的过程)。

```java
// ResourceCacheGenerator.java
// startNext 方法的返回值表示 loadData 的操作是否开始
// DataFetcher.loadData 是异步的过程
@Override
public boolean startNext() {
    // 只保留关键代码，其他代码省略
    List<Class<?>> resourceClasses = helper.getRegisteredResourceClasses();
    if (resourceClasses.isEmpty()) {
      // TranscodeClass 就是我们设置的 asFile asBitmap 等方法对应的类型
      if (File.class.equals(helper.getTranscodeClass())) {
        return false;
      }
    }
    while (modelLoaders == null || !hasNextModelLoader()) {
      // 从磁盘缓存获取 cacheFile
      cacheFile = helper.getDiskCache().get(currentKey);
      if (cacheFile != null) {
        // 根据 cacheFile 获取 modelLoader
        modelLoaders = helper.getModelLoaders(cacheFile);
        modelLoaderIndex = 0;
      }
    }

    loadData = null;
    boolean started = false;
    while (!started && hasNextModelLoader()) {
      ModelLoader<File, ?> modelLoader = modelLoaders.get();
      // 根据 modelLoader 获取 loadData
      loadData = modelLoader.buildLoadData(); // 参数省略
      if (loadData != null && helper.hasLoadPath()) {　// 方法参数省略
        started = true;
        // DataFetcher.loadData 获取数据
        loadData.fetcher.loadData(helper.getPriority(), this);
      }
    }
    
    return started;
}
```

DataCacheGenerator、SourceGenerator 类的 startNext 方法的流程和 ResourceCacheGenerator 的流程大致相同。此处就不细讲了。

DataFetcher.loadData 方法加载完数据后，内部会调用 DataCallback.onDataReady ---> DataFetcherGenerator.onDataReady ---> FetcherReadyCallback.onDataFetcherReady，最终走到 DecodeJob.onDataFetcherReady 方法。

DecodeJob 中会调用 onDataFetcherReady ---> decodeFromRetrievedData ---> decodeFromData ---> notifyEncodeAndRelease ---> notifyComplete ---> DecodeJob.Callback.onResourceReady ---> EngineJob.notifyCallbacksOfResult，最终回到 EngineJob。

EngineJob 中会走 onResourceReady ---> notifyCallbacksOfResult ---> CallResourceReady.run，最终进入 CallResourceReady。

CallResourceReady 中会走 run ---> callCallbackOnResourceReady ---> ResourceCallback.onResourceReady ---> SingleRequest.onResourceReady 的流程，最终回到 SingleRequest。

SingleRequest 中会最终调用到 Target.onResourceReady 方法，最终回到 CustomTarget。

## 出错原因

在了解了 Glide 的整条加载回调链路之后，我们就可以来分析下代码出错的原因了。

在解析本地文件链接时。

首先，在 DecodeJob.runGenerators 方法中，我们会首先去拿对应 Stage.RESOURCE_CACHE 的 ResourceCacheGenerator，尝试获取对应 DataFetcher，在 startNext 方法中，我们最终会走到 if (resourceClasses.isEmpty()) 语句中，直接结束 ResourceCacheGenerator 的执行。

```java
class ResourceCacheGenerator implements 
    DataFetcherGenerator, 
    DataFetcher.DataCallback<Object> 
{
  // 其余代码省略
  @SuppressWarnings("PMD.CollapsibleIfStatements")
  @Override
  public boolean startNext() {
    List<Key> sourceIds = helper.getCacheKeys();
    if (sourceIds.isEmpty()) {
      return false;
    }
    // 此处尝试根据 model 和 transcodeClass 获取 resourceClasses
    // model 就是我们上面传入的文件地址，是 String 类型
    // transcodeClass 就是我们最终想要拿到的数据，是 File 类型
    // 此处最终获取的 resourceClasses 是空列表，拿不到
    List<Class<?>> resourceClasses = helper.getRegisteredResourceClasses();
    if (resourceClasses.isEmpty()) {
      // TranscodeClass 是 File，目标代码进入这里，不再解析
      if (File.class.equals(helper.getTranscodeClass())) {
        return false;
      }
    }
  }
}
```

ResourceCacheGenerator 执行结束后，会紧跟着执行 Stage.DATA_CACHE 对应的 DataCacheGenerator。DataCacheGenerator 的 startNext 方法会首先尝试从磁盘读取 cacheFile，然后根据 cacheFile 获取 ModelLoaders，最终根据 ModelLoaders 拿到 DataFetcher 加载图片数据。

<font color="#FFB74D">**因为磁盘缓存策略默认是 AUTOMATIC 的，而 AUTOMATIC 模式默认只会缓存远程图片的未解码数据，本地文件本身默认是没有缓存的。所以此时拿本地文件的 cacheFile 就是 null。最终导致无对应的 ModelLoaders，以及后续用于加载图片数据的 while 循环不执行。**</font>

```java
class DataCacheGenerator implements 
    DataFetcherGenerator, 
    DataFetcher.DataCallback<Object> 
{
  // 其余代码省略
  @Override
  public boolean startNext() {
    while (modelLoaders == null || !hasNextModelLoader()) {
      // 根据 originalKey 从磁盘缓存取 cacheFile
      Key originalKey = new DataCacheKey(sourceId, helper.getSignature());
      cacheFile = helper.getDiskCache().get(originalKey);
      // cacheFile 此处为空，不会执行获取 ModelLoaders 的逻辑
      if (cacheFile != null) {
        modelLoaders = helper.getModelLoaders(cacheFile);
      }
    }

    boolean started = false;
    // hasNextModelLoader 为 false，while 循环内的加载逻辑不会执行
    while (!started && hasNextModelLoader()) {
        // 数据加载逻辑
    }
    return started;
  }
}
```

<font color="#FFB74D">DataCacheGenerator 执行结束后，会紧跟着执行 Stage.SOURCE 对应的 SourceGenerator， SourceGenerator 的 startNext 方法会执行 helper.getDiskCacheStrategy().isDataCacheable 方法判断未解码的缓存是否可用，因为磁盘缓存策略默认是 AUTOMATIC 的，而 AUTOMATIC 模式默认只会缓存远程图片的未解码数据，本地文件本身默认是没有缓存的。所以下面代码中的 1 处的 if 永远不会执行，最终的结果是 SourceGenerator 相当于没执行。</font>

```java
class SourceGenerator implements 
    DataFetcherGenerator, 
    DataFetcherGenerator.FetcherReadyCallback 
{
  // 其余代码省略
  @Override
  public boolean startNext() {
    while (!started && hasNextModelLoader()) {
      loadData = helper.getLoadData().get(loadDataListIndex++);
      // 1
      if (loadData != null && 
      (helper.getDiskCacheStrategy().isDataCacheable(
        loadData.fetcher.getDataSource()) || helper.hasLoadPath(
            loadData.fetcher.getDataClass())
      )) {
        started = true;
        // 真正的加载逻辑
        startNextLoad(loadData);
      }
    }
    return started;
  }
}
```

SourceGenerator 执行结束后，状态就是 Stage.FINISHED 了。整个 Decode 获取图片数据的工作就完成，此时还没有拿到图片数据，则证明 gg fail 了。

## 修复方式

### 方式 1

了解到了出错的原因之后，我们就能修复问题了，修复的方式很简单。既然是缓存逻辑出错，导致 DiskCacheStrategy.isDataCacheable() 用不了，进而导致解析失败。那么我们使 DataCache 可解析就行了。很巧，Glide 的 DiskCacheStrategy 中，不同的策略会使 isDataCacheable() 的返回值不同。

```java
public static final DiskCacheStrategy ALL = new DiskCacheStrategy() {
    @Override
    public boolean isDataCacheable(DataSource dataSource) {
        // 未解码数据只缓存远程文件的
        return dataSource == DataSource.REMOTE;
    }

    @Override
    public boolean isResourceCacheable(
        boolean isFromAlternateCacheKey, 
        DataSource dataSource, 
        EncodeStrategy encodeStrategy
    ) {
        // 已缓存过的解码后的数据不再缓存，内存缓存也不再缓存
        return dataSource != DataSource.RESOURCE_DISK_CACHE
              && dataSource != DataSource.MEMORY_CACHE;
    }

    @Override
    public boolean decodeCachedResource() {
        // 支持解码 CachedResource
        return true;
    }

    @Override
    public boolean decodeCachedData() {
        // 支持解码 CachedData
        return true;
    }
};

/** Saves no data to cache. */
public static final DiskCacheStrategy NONE = new DiskCacheStrategy() {
    @Override
    public boolean isDataCacheable(DataSource dataSource) {
        // 不缓存未解码的数据
        return false;
    }

    @Override
    public boolean isResourceCacheable(
        boolean isFromAlternateCacheKey, 
        DataSource dataSource, 
        EncodeStrategy encodeStrategy
    ) {
        // 不缓存解码后的数据
        return false;
    }

    @Override
    public boolean decodeCachedResource() {
        // 不支持解码 CachedResource
        return false;
    }

    @Override
    public boolean decodeCachedData() {
        // 不支持解码 CachedData
        return false;
    }
};

/** Writes retrieved data directly to the disk cache before it's decoded. */
public static final DiskCacheStrategy DATA = new DiskCacheStrategy() {
    @Override
    public boolean isDataCacheable(DataSource dataSource) {
        // 已缓存过的未解码数据不再缓存，内存缓存也不再缓存
        return dataSource != DataSource.DATA_DISK_CACHE 
            && dataSource != DataSource.MEMORY_CACHE;
    }

    @Override
    public boolean isResourceCacheable(
        boolean isFromAlternateCacheKey, 
        DataSource dataSource, 
        EncodeStrategy encodeStrategy
    ) {
        // 不缓存解码后的数据 
        return false;
    }

    @Override
    public boolean decodeCachedResource() {
        // 不支持解码 CachedResource
        return false;
    }

    @Override
    public boolean decodeCachedData() {
        // 支持解码 CachedData
        return true;
    }
};

  /** Writes resources to disk after they've been decoded. */
public static final DiskCacheStrategy RESOURCE = new DiskCacheStrategy() {
    @Override
    public boolean isDataCacheable(DataSource dataSource) {
        // 不缓存未解码的数据
        return false;
    }

    @Override
    public boolean isResourceCacheable(
        boolean isFromAlternateCacheKey, 
        DataSource dataSource, 
        EncodeStrategy encodeStrategy
    ) {
        // 已缓存过的解码后数据不再缓存，内存缓存也不再缓存
        return dataSource != DataSource.RESOURCE_DISK_CACHE
            && dataSource != DataSource.MEMORY_CACHE;
    }

    @Override
    public boolean decodeCachedResource() {
        // 支持解码 CachedResource
        return true;
    }

    @Override
    public boolean decodeCachedData() {
        // 不支持解码 CachedData
        return false;
    }
};

  /**
   * 根据 DataFetcher 和 ResourceEncoder 的 EncodeStrategy 自动选择缓存策略
   */
public static final DiskCacheStrategy AUTOMATIC = new DiskCacheStrategy() {
    @Override
    public boolean isDataCacheable(DataSource dataSource) {
        // 只缓存远程文件
        return dataSource == DataSource.REMOTE;
    }

    @Override
    public boolean isResourceCacheable(
        boolean isFromAlternateCacheKey, 
        DataSource dataSource, 
        EncodeStrategy encodeStrategy
    ) {
        // 未解码的磁盘缓存解码后如果可被替换，则可以被缓存
        // 本地文件解码后的数据可以缓存
        // transform 后的图片可以被缓存
        return (
            (isFromAlternateCacheKey 
                && dataSource == DataSource.DATA_DISK_CACHE
            ) || dataSource == DataSource.LOCAL
        ) && encodeStrategy == EncodeStrategy.TRANSFORMED;
    }

    @Override
    public boolean decodeCachedResource() {
        // 支持解码 CachedResource
        return true;
    }

    @Override
    public boolean decodeCachedData() {
        // 支持解码 CachedData
        return true;
    }
};
```

可以看出 AUTOMATIC 不会缓存本地文件的未解码数据，ALL 不管解没解码都支持缓存，NONE 不管解没解码都不支持缓存，而 RESOURCE 只支持缓存解码后的数据，DATA 只支持缓存未解码的数据。

所以，想要修复 bug，我们可以选择 ALL 或者 DATA 这两种策略

```kotlin
Glide.with(applicationContext)
    .asFile()
    .load(filePath)
    .diskCacheStrategy(DiskCacheStrategy.DATA) // 设置缓存策略
    .into(object : CustomTarget<File>() {
        override fun onResourceReady(
            file: File,
            transition: Transition<in File>?
        ) {
            Log.d(TAG, "success, file path is ${file.absolutePath}")
                // 具体处理逻辑省略
            }

            override fun onLoadCleared(placeholder: Drawable?) {
                Log.d(TAG, "gg, onLoadCleared")
            }

            override fun onLoadFailed(errorDrawable: Drawable?) {
                Log.d(TAG, "gg, onLoadFailed")
            }
        }
    )
```

bingo，经过验证，本地文件可以被解析了，问题解决。因为不管 ResourceCacheGenerator 和 DataCacheGenerator 执没执行，SourceGenerator 最终都会执行，并根据对应的 DataFetcher 获取数据。

### 方式 2

除了上面的代码可以解决问题，其实还可以不管 Glide 的加载逻辑，只把 Glide 当成一个下载管理器，而 Glide 也确实提供了这样的方法，就是 download 和 downloadOnly 方法，download 内部会使用 asFile，返回 File 对象。

使用 download 和 submit 方法之后，我们会得到一个 FutureTarget，FutureTarget 既是 Future 又是 Target，我们可以使用 Future.get() 获取到我们想要的文件。不过注意 Future.get() 是线程阻塞方法，会阻塞当前线程，所以推荐和协程一起使用。

```java
/**
 * 根据路径解析文件，如果 url 是网络链接，则 Glide 会先下载文件
 * */
suspend fun invokeImageFile(
    url: String
): File = suspendCancellableCoroutine { coroutine ->
    try {
        if (url.startWith("http") != true) {
            coroutine.resume(File(url))
        } else {
            coroutine.resume(
                // Future.get() 方法是线程阻塞方法，默认等待 5 秒)
                Glide.with(MainApplication.application)
                    .download(url)
                    .submit()
                    .get(5, TimeUnit.SECONDS)
            )
        }
    } catch (e: Exception) {
        Log.e(TAG, e)
        coroutine.resumeWithException(e)
    }
    coroutine.invokeOnCancellation {
        Log.e(TAG, it)
    }
}
```

这种方法经过验证，也是可行的。最终采用的就是这种方法。

至此，问题解决。可以看出 Glide 的磁盘缓存策略的确会影响图片数据的加载。