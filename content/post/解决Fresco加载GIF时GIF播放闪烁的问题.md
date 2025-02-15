---
title: "解决Fresco加载GIF时GIF播放闪烁的问题"
description: "本文讲述了Fresco加载GIF时GIF播放闪烁的问题的处理流程"
keywords: "Android,Fresco,GIF"

date: 2021-03-22T19:40:00+08:00

categories:
  - Android
  - 图片加载框架
tags:
  - Android
  - 图片加载框架
  - Fresco
  - GIF

url: post/7525EFC5527044EAB456BAAE212D7BEC.html
toc: true
---

本文讲述了 Fresco 加载 GIF 时 GIF 播放闪烁的问题的处理流程。

<!--More-->

最近在做需求，需求中有一个功能是显示 GIF，我们项目中目前在用的是 Fresco，版本是：2.3.0

测试过程中发现了一个 BUG：加载某些特定的表情时，表情会不停的闪烁。

我感到很纳闷儿。查不出为什么。让视觉改了好几次切图，也无法修复。视觉最后也不知道为什么，也没辙了。遂决定先抛弃 Fresco，改用 Android 系统提供的 GIF 解析方案试试。不试不知道，一试吓一跳：使用 Android 自带的方案显示会闪烁的 GIF。GIF 就不闪了。这意味着 Fresco 的解析 GIF 的逻辑有问题。Android 系统的实现方案如下，

- 高版本用 ImageDecoder + AnimatedImageDrawable 
- 低版本用 Movie + 自定义 View

下面是使用 Android 自带方法实现的部分关键代码。

```java
public class Test {
    public void test {
        // SDK >= 28
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            testByDrawable();
        } else {
            // 低版本使用 Movie + 自定义 View
            startParseGif();
        }
    }
    // 高版本测试方法类
    public void testByDrawable() {
        AnimatedImageDrawable decodedAnimation = ImageDecoder
            .decodeDrawable(ImageDecoder.createSource(new File(gifPath)));
        // 给 ImageView 设置图像
        iv.setImageDrawable(decodedAnimation);

        btn_start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (decodedAnimation instanceof AnimatedImageDrawable) {
                    /**
                     * 设置重复次数
                     */
                    decodedAnimation.repeatCount = 0;
                    // 开始动画前，首帧会优先展示
                    ((AnimatedImageDrawable)decodedAnimation).start();
                }
            }
        });
        btn_stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (decodedAnimation instanceof AnimatedImageDrawable) {
                    /**
                     * 设置重复次数
                     */
                    decodedAnimation.repeatCount = 0;
                    // 停止动画后，首帧会优先展示
                    ((AnimatedImageDrawable)decodedAnimation).stop();
                }
            }
        });
    }

    /**
     * 关键方法，方法节选自自定义 View。设置gif图资源
     */
    public void startParseGif() {
        byte[] bytes = getGiftBytes();
        mMovie = Movie.decodeByteArray(bytes, 0, bytes.length);
        requestLayout();
    }

    /**
     * 将gif图片转换成byte[]
     * @return byte[]
     */
    private byte[] getGiftBytes() {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        InputStream is = new FileInputStream(gifPath);
        byte[] b = new byte[1024];
        int len;
        try {
            while ((len = is.read(b, 0, 1024)) != -1) {
                baos.write(b, 0, len);
            }
            baos.flush();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return baos.toByteArray();
    }
    /**
     * 关键方法，方法节选自自定义 View。设置gif图资源
     */
    @Override
    protected void onDraw(Canvas canvas) {
        if (mMovie != null) {
            if (!mPaused) {
                updateAnimationTime();
                drawMovieFrame(canvas);
                invalidateView();
            } else {
                drawMovieFrame(canvas);
            }
        }
    }

    /**
     * 更新当前显示进度
     */
    private void updateAnimationTime() {
        long now = android.os.SystemClock.uptimeMillis();
        // 如果第一帧，记录起始时间
        if (mMovieStart == 0) {
            mMovieStart = now;
        }
        // 取出动画的时长
        int dur = mMovie.duration();
        if (dur == 0) {
            dur = DEFAULT_MOVIE_DURATION;
        }
        // 算出需要显示第几帧
        mCurrentAnimationTime = (int) ((now - mMovieStart) % dur);
    }
    /**
     * 绘制图片
     *
     * @param canvas 画布
     */
    private void drawMovieFrame(Canvas canvas) {
        // 设置要显示的帧，绘制即可
        mMovie.setTime(mCurrentAnimationTime);
        canvas.save();
        canvas.scale(mScale, mScale);
        mMovie.draw(canvas, mLeft / mScale, mTop / mScale);
        canvas.restore();
    }

    /**
     * 重绘
     */
    private void invalidateView() {
        if (mVisible) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                postInvalidateOnAnimation();
            } else {
                invalidate();
            }
        }
    }
}
```

视觉解决不了这个问题，而 Android 原生的解析又没有问题，那就只有是 Fresco 的解析有问题了。然后怎么办呢？只能去啃 Fresco 源码，看看能不能解决了。

## 寻找解码位置

在 Fresco 源码中找了一番，最终找到了 ImageDecoder 这个接口，解码图片时，Fresco 会调用这个接口的实现类。其定义如下：

```java
public interface ImageDecoder {
    CloseableImage decode( @Nonnull EncodedImage encodedImage,
        int length, @Nonnull QualityInfo qualityInfo,
        @Nonnull ImageDecodeOptions options);
}
```

Fresco 提供了 DefaultImageDecoder 这个类，其实现了 ImageDecoder。未指定解码器时，Fresco 默认使用这个类解析图片。其核心代码如下：

```java
public class DefaultImageDecoder implements ImageDecoder {

    private final ImageDecoder mAnimatedGifDecoder;
    private final ImageDecoder mAnimatedWebPDecoder;
    private final PlatformDecoder mPlatformDecoder;
    // 未指定解码器时，默认的解码器
    private final ImageDecoder mDefaultDecoder = new ImageDecoder() {
        @Override
        public CloseableImage decode(EncodedImage encodedImage,
            int length, QualityInfo qualityInfo,
            ImageDecodeOptions options) {
            // 获取图片结构
            ImageFormat imageFormat = encodedImage.getImageFormat();
            if (imageFormat == DefaultImageFormats.JPEG) {
                // JPG
                return decodeJpeg(encodedImage, length, qualityInfo, options);
            } else if (imageFormat == DefaultImageFormats.GIF) {
                // GIF
                return decodeGif(encodedImage, length, qualityInfo, options);
            } else if (imageFormat == DefaultImageFormats.WEBP_ANIMATED) {
                // WebP
                return decodeAnimatedWebp(encodedImage, length, qualityInfo, options);
            } else if (imageFormat == ImageFormat.UNKNOWN) {
                throw new DecodeException("unknown image format", encodedImage);
            }
            // 默认解码成静态图片
            return decodeStaticImage(encodedImage, options);
        }
    };

    /**
     * 在 ImagePipelineFactory 的 ImageDecoderConfig 中指定的不同图片的解码器
     * 项目中目前并未使用这个属性。
     */
    @Nullable private final Map<ImageFormat, ImageDecoder> mCustomDecoders;

    @Override
    public CloseableImage decode(final EncodedImage encodedImage,
        final int length, final QualityInfo qualityInfo,
        final ImageDecodeOptions options) {
        // 最高优先级的解码器
        // 我们在 ImageDecodeOptions 中指定的解码器
        if (options.customImageDecoder != null) {
            return options.customImageDecoder.decode(encodedImage, length, qualityInfo, options);
        }
        // 中优先级的解码器，在 ImagePipelineFactory 中的 ImageDecoderConfig 中指定的，对应图片类型的解码器
        ImageFormat imageFormat = encodedImage.getImageFormat();
        if (imageFormat == null || imageFormat == ImageFormat.UNKNOWN) {
            imageFormat = ImageFormatChecker.getImageFormat_WrapIOException(encodedImage.getInputStream());
            encodedImage.setImageFormat(imageFormat);
        }
        if (mCustomDecoders != null) {
            ImageDecoder decoder = mCustomDecoders.get(imageFormat);
            if (decoder != null) {
                return decoder.decode(encodedImage, length, qualityInfo, options);
            }
        }
        // 默认解码器，最低优先级
        return mDefaultDecoder.decode(encodedImage, length, qualityInfo, options);
    }
}
```

## GIF 为何会闪烁

通过跟踪 decodeGif 这个方法，我最终找到了如下代码：

```java
public class AnimatedFactoryV2Impl implements AnimatedFactory {
    public ImageDecoder getGifDecoder(final Config bitmapConfig) {
        return new ImageDecoder() {
            public CloseableImage decode(EncodedImage encodedImage, int length, 
                QualityInfo qualityInfo, ImageDecodeOptions options) {
                // 默认的 GIF 的解码位置
                return AnimatedFactoryV2Impl.this.getAnimatedImageFactory()
                    .decodeGif(encodedImage, options, bitmapConfig);
            }
        };
    }

    public ImageDecoder getWebPDecoder(final Config bitmapConfig) {
        return new ImageDecoder() {
            public CloseableImage decode(EncodedImage encodedImage, int length, 
                QualityInfo qualityInfo, ImageDecodeOptions options) {
                // 默认的 Webp 的解码位置
                return AnimatedFactoryV2Impl.this.getAnimatedImageFactory()
                    .decodeWebP(encodedImage, options, bitmapConfig);
            }
        };
    }
}
```

点击进入，找到实现的位置。如下：

```java
public class AnimatedImageFactoryImpl implements AnimatedImageFactory {   
    public CloseableImage decodeGif(final EncodedImage encodedImage,
        final ImageDecodeOptions options, final Bitmap.Config bitmapConfig) {
        if (sGifAnimatedImageDecoder == null) {
            throw new UnsupportedOperationException("To encode animated gif please add the dependency " 
                + "to the animated-gif module");
        }
        // 未解码的数据
        final CloseableReference<PooledByteBuffer> bytesRef = encodedImage.getByteBufferRef();
        Preconditions.checkNotNull(bytesRef);
        try {
            final PooledByteBuffer input = bytesRef.get();
            AnimatedImage gifImage;
            // 这两个解码方法，最终都走到了 Native 层。没法继续追踪了。
            if (input.getByteBuffer() != null) {
                gifImage = sGifAnimatedImageDecoder
                    .decodeFromByteBuffer(input.getByteBuffer(), options);
            } else {
                gifImage = sGifAnimatedImageDecoder.decodeFromNativeMemory(
                    input.getNativePtr(), input.size(), options);
            }
            return getCloseableImage(options, gifImage, bitmapConfig);
        } finally {
            CloseableReference.closeSafely(bytesRef);
        }
    }
}
```

走到最后，发现 Fresco 默认使用的是 Native 层的方法解码。没法继续追踪了。不过还好，范围已经够窄了。去百度了一下。最终明白了**Fresco 默认是借助 giflib 库在 Native 层进行解码。这说明 Fresco 自带的 giflib 库在解码 GIF 时不可靠，可能会出现解码出来的 GIF 数据有异常的情况。**

## 解决 GIF 闪烁

需要更换方式。更换啥呢，有点没思路了。最后经大佬指点，发现项目中还有一个 Fresco 库没引入(lite库)。死马当活马医，引入试试。好家伙，引入了之后，看了下里面包括的类，瞬间燃起了希望。里面**有个关键类 GifDecoder。看了下类说明，发现这个类是基于 Android 自带的 Movie 类解码的。**Movie 类不正好是上面验证的没问题的方案吗？

```java
/** 
 * A simple Gif decoder that uses Android's {@link Movie} class to decode Gif images.
 * 翻译：使用 Android 的 Movie 解码 Gif。
 */
public class GifDecoder implements ImageDecoder {
    // 代码省略
}
```

接着就试试是否可以解决 GIF 闪烁的问题。在 ImageRequest 中传入自定义解码器。使用代码如下：

```java
ImageRequest request = ImageRequestBuilder.newBuilderWithSource(Uri.parse(filePath))
    .setResizeOptions(new ResizeOptions(width, height))
    .setProgressiveRenderingEnabled(true)
    .setRotationOptions(RotationOptions.autoRotate())
    .setImageDecodeOptions(ImageDecodeOptions.newBuilder()
         // 设置自定义的解码器
         .setCustomImageDecoder(new GifDecoder())
         // 优先加载GIF的第一帧
         .setDecodePreviewFrame(true)
         .build())
    .build();
```

编译，运行，Bingo，GIF 不闪了。

可能 Fresco 维护者在使用时遇到了和我一样的问题，所以才特意提供的这个包吧。

## 解决静态图片解析失败的问题

上面的方法虽然解决了 GIF 闪烁的问题，但是又产生了新的问题。原本显示 OK 的 JPG，无法显示了。

从上面的代码中，我明白了以下几点：

- 默认情况下，Fresco 解码图片，最终会走到 DefaultImageDecoder 这个类。在这个类中进行解码操作。
- DefaultImageDecoder 这个类中实现了默认的解码方式，默认解码会根据图片类型不同而采取不同的解码方式。也就是说，当我们在代码中没有指定解码器时，解码器默认会判断图片的类型，然后解码数据进行展示。JPG 显示成 JPG，GIF 显示成 GIF。
- **Fresco 为我们准备了三种不同优先级的 ImageDecoder。我们在 ImageDecodeOptions 中指定了解码器，那么所有的图片都会被这个解码器处理。如果我们仅仅指定了 GIF 的解码器，那么传入 JPG 图片时，是解析不了的。这就是导致静态图片解析失败的原因。**
- **Fresco 中可以指定三种不同级别的图片解码器。其中以每次请求的解码器优先级最高(第一种方式)，其次是在初始化 Fresco 时，传入的每种图片格式的解码器(第二种方式)，此配置会对全局生效。默认解码器的优先级最低。**

**要解决图片解码失败的问题。可以用两种方式设置解码器。第二种相比于第一种，虽然设置起来方便，但是对全局生效，侵入性较强。第一种虽然比较麻烦，但是侵入性是完全可以接受的。此次解决问题，考虑了下现有项目的结构，决定采用第一种方案。**

在使用第一种方案的思路下，理了一下解码器传入的流程，发现如果传GIF解码器进入默认解码器的话，流程太长，需要传入的东西太多。于是决定使用反射拿到自定义的解码器的默认实现，并替换其中的 GIF 解码流程。代码如下：

```java
import android.text.TextUtils;

import com.facebook.animated.giflite.GifDecoder;
import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.imageformat.DefaultImageFormats;
import com.facebook.imageformat.ImageFormat;
import com.facebook.imageformat.ImageFormatChecker;
import com.facebook.imagepipeline.common.ImageDecodeOptions;
import com.facebook.imagepipeline.core.ImagePipelineFactory;
import com.facebook.imagepipeline.decoder.DefaultImageDecoder;
import com.facebook.imagepipeline.decoder.ImageDecoder;
import com.facebook.imagepipeline.image.CloseableImage;
import com.facebook.imagepipeline.image.EncodedImage;
import com.facebook.imagepipeline.image.QualityInfo;

import java.lang.reflect.Field;

public class CompatibleGifImageDecoder implements ImageDecoder {
    private static final String TAG = "CompatibleGifImageDecoder";
    /**
     * 非 GIF 类型图片的解码器
     * */
    private ImageDecoder defaultDecoder;
    /**
     * GIF 的解码器
     * */
    private GifDecoder mGifDecoder;

    @Override
    public CloseableImage decode(EncodedImage encodedImage, int length, 
        QualityInfo qualityInfo, ImageDecodeOptions options) {
        // 拿到图片的类型，参考自 DefaultImageDecoder 源码
        ImageFormat imageFormat = encodedImage.getImageFormat();
        if (imageFormat == null || imageFormat == ImageFormat.UNKNOWN) {
            imageFormat = ImageFormatChecker.getImageFormat_WrapIOException(encodedImage.getInputStream());
            encodedImage.setImageFormat(imageFormat);
        }
        if(TextUtils.equals(DefaultImageFormats.GIF.getName(), imageFormat.getName())) {
            // GIF
            if(mGifDecoder == null) {
                mGifDecoder = new GifDecoder();
            }
            return mGifDecoder.decode(encodedImage, length, qualityInfo, options);
        } else {
            // 其他图片格式的解码器
            if(defaultDecoder != null) {
                return defaultDecoder.decode(encodedImage, length, qualityInfo, options);
            }
            // long startTime = System.nanoTime();
            // 反射拿默认解码器
            ImagePipelineFactory factory = Fresco.getImagePipelineFactory();
            Class clz = ImagePipelineFactory.class;
            try {
                // 拿到 DefaultImageDecoder 实例
                Field field = clz.getDeclaredField("mImageDecoder");
                field.setAccessible(true);
                DefaultImageDecoder defaultImageDecoder = (DefaultImageDecoder)field.get(factory);
                // 通过 DefaultImageDecoder 实例拿到类中默认的实现
                clz = DefaultImageDecoder.class;
                field = clz.getDeclaredField("mDefaultDecoder");
                field.setAccessible(true);
                defaultDecoder = (ImageDecoder)field.get(defaultImageDecoder);
                // Log.d(TAG, "拿值耗时：" + (System.nanoTime() - startTime));
                if (defaultDecoder != null) {
                    return defaultDecoder.decode(encodedImage, length, qualityInfo, options);
                }
                return null;
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
        }
    }
}
```

然后在加载图片时传入，就解决了只能显示 GIF 的问题：

```java
ImageRequest request = ImageRequestBuilder.newBuilderWithSource(Uri.parse(gifPath))
    .setRotationOptions(RotationOptions.autoRotate())
    .setImageDecodeOptions(ImageDecodeOptions.newBuilder()
                           // 设置解码器
                           .setCustomImageDecoder(new CompatibleGifImageDecoder())
                           // 优先加载GIF的第一帧
                           .setDecodePreviewFrame(true)
                           .build())
    .build();
```

### 关于反射的耗时问题

大家都说反射挺耗时的，在使用反射时，我也额外关注了下反射的耗时问题。

```java
// 上述代码中的这两个方法，计算耗时，单位为纳秒
long startTime = System.nanoTime();
// 反射代码省略
Log.d(TAG, "拿值耗时：" + (System.nanoTime() - startTime));
```

经过测算。上面的代码拿值耗时为：

- 小米10青春版：首次拿值耗时最大在 60000 纳秒左右，后续拿值耗时在 20000 纳秒左右
- 5.0 系统的渣机，首次拿值耗时最大在 270000 纳秒左右，后续拿值耗时在 70000 纳秒左右

1 ms = 1,000,000 ns，结论：上述**反射代码的全机型耗时，应该在 1ms 以下。属于可接受的范围。**

## 解决 Release 版本图片失效的问题

上面的解决方案，在 Debug 版本上测试，是 OK 的，但是编了 Release 版本后，就失效。**大概率是混淆的问题。**看了错误日志，的确是报了找不到 DefaultImageDecoder 类的错误。于是在混淆配置文件加入以下内容。

```java
-keep class com.facebook.imagepipeline.decoder.**{*;}
```

再次编译，测试 OK。

以上便是 Fresco 显示部分 GIF 闪烁问题的详细解决过程。