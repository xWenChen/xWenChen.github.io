---
title: "Android自定义SeekBar并使用Glide处理图片"
description: "本文讲解了在 Android 中如何使用 Glide 处理图片，并将结果作为 SeekBar 的样式"
keywords: "Android,图片加载,SeekBar,Glide"

date: 2024-01-20 14:25:00 +08:00
lastmod: 2024-01-20 14:25:00 +08:00

categories:
  - Android
tags:
  - Android
  - Glide
  - SeekBar
  - 图片加载

url: post/39B395A091FA4775BCD036020C91B5AD.html
toc: true
---

本文讲解了在 Android 中如何使用 Glide 处理图片，并将结果作为 SeekBar 的样式。

<!--More-->

在最近的一个处理音频播放的需求中，视觉同事要求实现如下一个效果：

![音频播放视觉示例](/imgs/音频播放视觉示例.png)

- 左边一个进度条，中间一个时间长度，右边一个播放按钮。当点击播放按钮时，会播放音频，并不停刷新播放进度

- 如果将最长的竖线+左右4个对称竖向称为 1 个音视频视觉段，两个音频段之间以 1 个竖线分割，则音视频视觉段数量不确定，可能有 1、2、3、4 个

- 鉴于音视频视觉段的数量不固定，但是视觉不想重复切图，只想给一个最长的切图。所以剩下较短的段数开发自己计算比例，裁剪图片得到。

![音频播放视觉切割说明](/imgs/音频播放视觉切割说明.png)

根据视觉提供的布局说明，则可以得到 1、2、3、4 个音视频视觉段的比例为：0.196f、0.468f、0.736f、1.0f。

本文不讲播放逻辑，只讲视觉实现逻辑。

上述音频进度条功能可以使用 SeekBar 实现，但是不能简单的组合 LayerDrawable 和 ClipDrawable 作为 SeekBar 的 progressDrawable，这种方案在裁剪特定音频段数时，会出现展示不全的问题。鉴于项目中使用 Glide 加载图片，所以在经过尝试后，决定使用 Glide 加载图片，经过变换处理后，再作为 progressDrawable 传递给 SeekBar。

要实现以上功能，我们需要实现以下几个功能点：

- 使用 Glide 为图片添加内边距(该功能与音频视觉无关，是另一个功能点的内容，此处一起讲了)。
- 使用 Glide 按照某个比例裁剪图片。
- 将我们自定义的图片 Drawable 包装后作为 progressDrawable 传递给 SeekBar。

## 使用 Glide 为图片添加内边框

Android 系统并未提供为图片或者 View 添加内边框(也叫描边)的方法。系统提供的添加边框的 xml 语法，是添加的外边框。如果想要为 为图片或者 View 添加内边框，我们需要自定义实现。要使用 Glide 为图片添加内边框，我们可以使用 Glide 提供的图片变换(Transformation)功能。假设我们自定义的 Transformation 的名称为 InnerStrokeTransformation，其接受三个参数：边框宽度，边框颜色，边框圆角半径。则其使用方式如下：

```kotlin
var options = RequestOptions()
// 添加 Transformation
val transformation = mutableListOf<Transformation<Bitmap>>()
// 其他 Transformation 省略
transformation.add(
    InnerStrokeTransformation(
        R.dimen.dp_0_5.dimenRes.toFloat(), // 边框宽度为 0.5dp
        R.color.color_DFE2EA.colorRes, // 边框颜色为 #DFE2EA
        R.dimen.dp_6.dimenRes.toFloat() // 边框圆角半径为：6dp
    )
)
// 应用 Transformation
if (transformation.isNotEmpty()) {
    options = options.transform(MultiTransformation(transformation))
}
// 加载图片
Glide.with(imageView)
    .load(url)
    .apply(options) // 应用 RequestOptions
    .into(imageView)
```

InnerStrokeTransformation 的具体实现步骤如下：

1 - 创建 InnerStrokeTransformation 类，继承自 BitmapTransformation。并新增 3 个变量：width: Float, color: Int, radius: Float。分别代表 描边宽度，描边颜色，描边的圆角半径

2 - 实现 updateDiskCacheKey 方法、equals 方法和 hashCode 方法，方便 Glide 管理缓存。其实现可以参考 Glide 内置的 Transformation。

3 - 实现 transform 方法，添加描边。

接下来我们一个个讲。

### 实现 updateDiskCacheKey、equals 和 hashCode 方法

这一步非常简单，模仿 Glide 内的实现即可，没啥好讲的。ID 弄个可以唯一标识本类的字符串即可。

```kotlin
import com.bumptech.glide.load.resource.bitmap.BitmapTransformation
import java.security.MessageDigest

class InnerStrokeTransformation(
    var width: Float, // 描边宽度
    var color: Int, // 描边颜色
    var radius: Float // 描边的圆角半径
) : BitmapTransformation() {

    override fun updateDiskCacheKey(messageDigest: MessageDigest) {
        messageDigest.update(ID.toByteArray(CHARSET))
    }

    override fun equals(other: Any?): Boolean {
        return other is InnerStrokeTransformation
    }

    override fun hashCode(): Int {
        return ID.hashCode()
    }

    companion object {
        private const val TAG = "InnerStrokeTransformation"
        private const val VERSION = 1
        private const val ID = "com.test.android.glide.transformation.$TAG.$VERSION"
    }
}
```

### 添加描边

添加描边的步骤如下图所示：

![Glide为图片添加内边框的步骤](/imgs/Glide为图片添加内边框的步骤.png)

可以看出，添加描边主要是两个步骤：绘制原图像、绘制描边。

要绘制特定形状的原图像(比如带圆角的图像)，我们可以为 paint 添加 BitmapShader。Paint 着色器的讲解，可以参考这片文章：[HenCoder Android 开发进阶: 自定义 View 1-2 Paint 详解](https://rengwuxian.com/ui-1-2/)

```kotlin
val paint = Paint().apply {
    this.isAntiAlias = true
    this.setShader(
        BitmapShader(bmp, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply {
            setLocalMatrix(
                Matrix().apply {
                    setScale(outWidth * 1f / bmpWidth, outHeight * 1f / bmpHeight)
                }
            )
        }
    )
}
```

为 paint 添加了 BitmapShader 后，我们可以使用`Canvas.drawRoundRect(float left, float top, float right, float bottom, float rx, float ry,@NonNull Paint paint)`绘制原图像。

```kotlin
drawRoundRect(0f, 0f, outWidth.toFloat(), outHeight.toFloat(), mRadius, mRadius, paint)
```

绘制描边和绘制原图像调用的方法一样，只是 paint 不一致，并且绘制的位置不一样。假设原图像的绘制区域为 (0, 0) 到 (width, height)，考虑到描边宽度，则描边的绘制范围为 (strokeWidth, strokeWidth) 到 (width - strokeWidth, height - strokeWidth)。即从 0 开始绘制，描边就是外描边；从 strokeWidth 开始绘制，描边就是内描边了。

结合上面的讲解，最终的源代码如下：

```kotlin
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Shader
import androidx.core.graphics.applyCanvas
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool
import com.bumptech.glide.load.resource.bitmap.BitmapTransformation
import java.security.MessageDigest

/**
 * 为图片添加内描边
 * */
class InnerStrokeTransformation(
    var width: Float, // 描边宽度
    var color: Int, // 描边颜色
    var radius: Float // 描边的圆角半径
) : BitmapTransformation() {

    companion object {
        private const val TAG = "InnerStrokeTransformation"
        private const val VERSION = 1
        private const val ID = "com.test.android.glide.transformation.$TAG.$VERSION"
    }

    override fun updateDiskCacheKey(messageDigest: MessageDigest) {
        messageDigest.update(ID.toByteArray(CHARSET))
    }

    override fun equals(other: Any?): Boolean {
        return other is InnerStrokeTransformation
    }

    override fun hashCode(): Int {
        return ID.hashCode()
    }

    override fun transform(
        pool: BitmapPool,
        toTransform: Bitmap,
        outWidth: Int,
        outHeight: Int
    ): Bitmap {
        val mWidth = this.width
        // 浮点型的误差值设为 0.05，小于 0.05 则视作 0
        if (mWidth < 0.05f || color == 0) {
            // 未设置，不做转换
            return toTransform
        }

        val sWidth = toTransform.width
        val sHeight = toTransform.height
        val mRadius = radius

        return pool.get(sWidth, sHeight, Bitmap.Config.ARGB_8888).apply {
            setHasAlpha(true)

            applyCanvas {
                // 绘制 bmp
                val paint = generatePaint(toTransform, sWidth, sHeight, outWidth, outHeight)
                drawRoundRect(
                    0f, 
                    0f, 
                    outWidth.toFloat(), 
                    outHeight.toFloat(), 
                    mRadius, 
                    mRadius, 
                    paint
                )

                // 绘制内描边
                val borderPaint = obtainBorderPaint(mWidth)
                drawRoundRect(
                    mWidth, 
                    mWidth, 
                    outWidth - mWidth, 
                    outHeight - mWidth, 
                    mRadius, 
                    mRadius, 
                    borderPaint
                )

                this.setBitmap(null)
            }
        }
    }

    private fun obtainBorderPaint(mStrokeWidth: Float) = Paint().apply {
        this.style = Paint.Style.STROKE
        this.strokeWidth = mStrokeWidth
        this.color = this@InnerStrokeTransformation.color
        this.isAntiAlias = true
    }

    private fun generatePaint(
        bmp: Bitmap, 
        bmpWidth: Int,
        bmpHeight: Int, 
        outWidth: Int, 
        outHeight: Int
    ) = Paint().apply {
        this.isAntiAlias = true
        this.setShader(
            BitmapShader(bmp, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP).apply {
                setLocalMatrix(
                    Matrix().apply {
                        setScale(outWidth * 1f / bmpWidth, outHeight * 1f / bmpHeight)
                    }
                )
            }
        )
    }
}
```

## 使用 Glide 按比例裁剪图片

要使用 Glide 按比例裁剪图片，我们仍然需要使用 Glide 提供的图片变换(Transformation)功能。其实现步骤与上文的 InnerStrokeTransformation 类似，代码的主要不同在于 transform 方法。
其代码如下：

```kotlin
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import androidx.core.graphics.applyCanvas
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool
import com.bumptech.glide.load.resource.bitmap.BitmapTransformation
import java.security.MessageDigest
import kotlin.math.min
import kotlin.math.roundToInt

class CutTransformation(
    private val ratio: Float = -1f, // 裁剪比例
) : BitmapTransformation() {
    override fun transform(
        pool: BitmapPool, 
        toTransform: Bitmap, 
        outWidth: Int, 
        outHeight: Int
    ): Bitmap {
        // 使用比例裁剪
        return cutWithRatio(pool, toTransform, outWidth, outHeight)
    }

    private fun cutWithRatio(pool: BitmapPool, toTransform: Bitmap, outWidth: Int, outHeight: Int): Bitmap {
        if (ratio < 0.05f) {
            // 浮点型不准确，使用 0.05f 表示 0f，比例为负，表示不用比例裁剪
            return toTransform
        }

        val srcWidth = toTransform.width
        val srcHeight = toTransform.height

        // 水平裁剪，按比例计算新的宽度，高度不变
        val targetWidth = min((srcWidth * ratio).roundToInt(), srcWidth)
        val targetHeight = srcHeight
        // 获取 bitmap
        return pool.get(targetWidth, targetHeight, Bitmap.Config.ARGB_8888).applyCanvas {
            
            val paint = Paint(PAINT_FLAGS)
            // 将 toTransform 的内容从左上角开始绘制到新 Bitmap 上，新 Bitmap 的尺寸为 (targetWidth, targetHeight)
            drawBitmap(toTransform, 0f, 0f, paint)

            setBitmap(null)
        }
    }

    override fun updateDiskCacheKey(messageDigest: MessageDigest) {
        messageDigest.update(ID.toByteArray(CHARSET))
    }

    override fun equals(other: Any?): Boolean {
        return other is CutTransformation
    }

    override fun hashCode(): Int {
        return ID.hashCode()
    }

    companion object {
        private const val TAG = "CutTransformation"
        private const val VERSION = 1
        private const val ID = "com.test.android.glide.transformation.$TAG.$VERSION"
        private const val PAINT_FLAGS = Paint.DITHER_FLAG or Paint.FILTER_BITMAP_FLAG
    }
}
```

## 为 SeekBar 设置 progressDrawable

要得到裁剪的图片，我们可以使用 Glide 加载，加载的代码如下：

```kotlin
// 加载图片并裁剪，将 Glide 的异步加载转为协程
private suspend fun loadDrawable(
    activity: Activity,
    resId: Int,
    // 音频视觉段的裁剪比例：0.196f、0.468f、0.736f、1.0f
    ratioLevel: Float,
) = withContext(Dispatchers.IO) {
    suspendCoroutine<Drawable?> { continuation ->
        try {
            Glide.with(activity)
                .asDrawable()
                .load(resId)
                .apply(
                    RequestOptions().run {
                        this.transform(CutTransformation(ratio = ratioLevel))
                    }
                )
                .into(object : CustomTarget<Drawable>() {
                    override fun onResourceReady(resource: Drawable, transition: Transition<in Drawable>?) {
                        continuation.resume(resource)
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        continuation.resume(null)
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        continuation.resume(null)
                    }
                })
        } catch (e: Exception) {
            CLog.e(TAG, e)
            continuation.resume(null)
        }
    }
}
```

要为 SeekBar 设置 progressDrawable。我们需要得到一个 LayerDrawable，这个 LayerDrawable 包含两个图层的 ClipDrawable，分为代表 SeekBar 的全部进度(backgroundDrawable)和已播放进度(mProgressDrawable)。并将全部进度的 id 设置为 android.R.id.background，将已播放进度的 id 设置为 android.R.id.progress。

![progressDrawable的层级](/imgs/progressDrawable的层级.png)

至于为什么 LayerDrawable 包含的必须是 ClipDrawable。这是因为 SeekBar 在改变进度时，会为其对应的 mProgressDrawable 设置 level。这个 level 是在 Drawable 中定义的。虽然 Drawable 的子类都可以使用，但是在官方提供的实现中，只有 ClipDrawable 会根据 level 取计算一个比例，并按照该比例裁剪 Drawable。比例的计算方式为：(level / 10000)，即 ClipDrawable 的最大 level 为 10000(一万)。只有按比例裁剪 Drawable，SeekBar 才能呈现出进度不断变化的样式。

```kotlin
val height = R.dimen.dp_18.dimenRes
activity.lifecycleScope.launch(Dispatchers.Main) {
    val backgroundDeferred = async { loadDrawable(activity, backgroundRes, ratioLevel) }
    val progressDeferred = async { loadDrawable(activity, progressRes, ratioLevel) }
    // 异步加载两个 Drawable
    val backgroundDrawable = backgroundDeferred.await() ?: return@launch
    val mProgressDrawable = progressDeferred.await() ?: return@launch

    val drawableList = arrayOf(
        ClipDrawable(backgroundDrawable, Gravity.START, ClipDrawable.HORIZONTAL).apply {
            // 背景进度条不用裁剪
            level = 10000
        },
        ClipDrawable(mProgressDrawable, Gravity.START, ClipDrawable.HORIZONTAL)
    )
    
    LayerDrawable(drawableList).apply {
        setId(0, android.R.id.background)
        setId(1, android.R.id.progress)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            setLayerHeight(0, height)
            setLayerHeight(1, height)
        }
        // 将最终得到的 LayerDrawable 赋值给 LiveData
        progressDrawable.value = this
    }
}
```

得到结果后，我们就可以为 SeekBar 设置 progressDrawable 了。下面的代码使用到了 DataBinding。我们将 ViewModel 中定义的 progressDrawable LiveData 传递给 xml。如果为 Binding 设置了 LifecyclerOwner，则当 LiveData 的值改变时，Binding 会自动刷新。下面的代码中 progressWidth、progressDrawable、position 都是 LiveData，一个代表 SeekBar 的宽度，一个代表  SeekBar 的 progressDrawable，一个代表 SeekBar 的当前进度。播放时，我们只要间隔一定时间(比如 20 ms)改变 position，SeekBar 的进度就会不断刷新。

```xml
<SeekBar
    android:id="@+id/seek_bar"
    android:layout_width="@{vm.progressWidth, default=wrap_content}"
    android:layout_height="@dimen/dp_18"
    android:minWidth="@{vm.progressWidth}"
    android:paddingStart="@dimen/dp_1"
    android:paddingEnd="@dimen/dp_1"
    android:layout_marginStart="@dimen/dp_8"
    android:progressDrawable="@{vm.progressDrawable}"
    android:thumbTint="@{vm.position == 0 ? @color/transparent : @color/color_0F2128}"
    android:thumb="@drawable/voice_seekbar_thumb"
    android:splitTrack="false"
    android:background="@null"
    android:max="100000"
    android:progress="@{vm.position}"
    tools:visibility="visible"
    />
```

- android:progressDrawable 用于设置进度条样式
- android:thumb 用于设置进度指针样式
- android:thumbTint 用于设置进度指针的颜色
- android:splitTrack="false" 用于处理自定义进度样式时可能出现的背景进度显示不全(被裁剪)的问题
- android:background="@null" 当自定义进度样式时，background 需要被清空

## 图片复用导致加载出错问题处理

上面生成 progressDrawable 的代码会有问题，最终的修复版还是得自己手绘，代码如下：

```
private fun generateFinalDrawable(backgroundRes: Int,mProgressRes: Int) {
    if (backgroundRes == 0 || mProgressRes == 0) {
        return
    }
    val height = R.dimen.dp_18.dp2px

    val ratioLevel = 0.273 // 裁剪原图的比例

    val bg = getClipDrawable(backgroundRes, ratioLevel)?.apply {
        level = 10000
    } ?: return
    val pg = getClipDrawable(mProgressRes, ratioLevel) ?: return

    LayerDrawable(arrayOf(bg, pg)).apply {
        setId(0, android.R.id.background)
        setId(1, android.R.id.progress)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            setLayerHeight(0, height)
            setLayerHeight(1, height)
        }

        progressDrawable = this
    }

    private fun getClipDrawable(srcDrawable: Int, ratioLevel: Float): ClipDrawable? {
        val res = GlobalApplicationAgent.getApplication().resources
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val srcBmp = BitmapFactory.decodeResource(res, srcDrawable) ?: return null

        val target = Bitmap.createBitmap(
            (srcBmp.width * ratioLevel).toInt(),
            srcBmp.height,
            Bitmap.Config.ARGB_8888
        )

        val canvas = Canvas(target)

        canvas.drawBitmap(srcBmp, 0f, 0f, paint)

        if (!srcBmp.isRecycled) {
            srcBmp.recycle()
        }

        return ClipDrawable(BitmapDrawable(res, target), Gravity.START, ClipDrawable.HORIZONTAL)
    }
}
```

## kotlin 代码实现多状态 Drawable

xml 中的多状态 Drawable 可以这么编写：

```xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@drawable/img_liked" android:state_selected="true" />
    <item android:drawable="@drawable/img_unlike" />
</selector>
```

其等价的 kotlin 代码实现为：

```kotlin
private fun realGenerateLikeIcon(unlikeIcon: Drawable, likedIcon: Drawable): Drawable {
    return StateListDrawable().apply {
        
        addState(intArrayOf(android.R.attr.state_selected), likedIcon)

        addState(intArrayOf(), unlikeIcon)
    }
}
```
