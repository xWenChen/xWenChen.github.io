---
title: "Android 图片处理部分知识点说明"
description: "本文讲解了在 Android 开发中遇到的一些加载图片的注意点"
keywords: "Android,图片加载"

date: 2023-03-15 17:51:00 +08:00
lastmod: 2023-03-15 17:51:00 +08:00

categories:
  - Android
tags:
  - Android
  - 图片加载

url: post/88596A1EE80641BF9DCA51AB98B21AB3.html
toc: true
---

本文讲解了在 Android 开发中遇到的一些加载图片的注意点。

<!--More-->

本文讲解在 Android 的日常开发中，针对图片的几个小 tips。

## 图片的 mimeType

在 Android 系统中，图片的 mimeType 系统默认是根据后缀名判断。比如 pic.jpg 的 mimeType 就是 "image/jpeg"。

这种逻辑在图片的后缀名正常时还 OK，但是如果图片的后缀名和图片的实际类型匹配不上，那大概率会导致业务异常。比如 zip 压缩文件的后缀名改为 "data.jpg"，那么我们在筛选出手机上的图片时，这张 "data.jpg" 也会被识别出来，然后就会出现 ImageView 展示白屏、图片压缩失败、上传图片失败(压缩包过大，超出图片限制)等问题。

此时通过如 androidx 的 LoaderManager 那一套读取出来的系统的 mimeType 信息就不可靠了，我们需要自己确定文件实际的 mimeType，一般我们可以使用系统提供的 BitmapFactory，也可以读取文件头信息，拿到数据的 mimeType。前者适用范围更广，后者可定制性更强。实现时可按需选择。代码如下：

```kotlin
// 方法1：使用 BitmapFactory 确定 mimeType
val String.imageMimeType: String
    get() {
        return try {
            val decodeOptions = BitmapFactory.Options()
            decodeOptions.inJustDecodeBounds = true
            BitmapFactory.decodeFile(data, decodeOptions)

            decodeOptions.outMimeType
        } catch (ignored: Throwable) {
            Log.e("String.imageMimeType", ignored)
            
            "image/*"
        }
    }
```

```kotlin
// 方法2：读取文件头确定 mimeType
val File.imageMimeType: String
    get() {
        return try {
            FileInputStream(this).use { input ->
                when (input.read()) {
                    0xFF -> "image/jpeg"
                    0x89 -> "image/png"
                    0x47 -> "image/gif"
                    else -> readOtherType()
                }
            }
        } catch (ignored: Throwable) {
            Log.e("File.imageMimeType", ignored)
            "image/*"
        }
    }
// 读取 heic 图片(HEIF 图片)的文件头
private fun File.readOtherType(): String {
    return reader().use {
        // heic 格式，头4个字节不用管
        it.skip(4)
        // heic 格式：5 - 12 共 8 个字节是 ftypheic 8 个字符
        val array = CharArray(8)
        if (it.read(array) != -1 && String(array) == "ftypheic") {
            "image/heic"
        } else {
            "image/*"
        }
    }
}
```

## 图片的尺寸信息

通常，我们可以使用 BitmapFactory 图片的尺寸：

```kotlin
val decodeOptions = BitmapFactory.Options()
decodeOptions.inJustDecodeBounds = true
BitmapFactory.decodeFile(path, decodeOptions)
val width = decodeOptions.outWidth
val height = decodeOptions.outHeight
```

但是上面的代码存在一个问题，即 width 和 height 可能取反了。即 width 是 height 的值，height 是 width 的值。出现问题的原因可能是图片带有 EXIF 信息，这个信息是关于图片拍摄时的信息，相机会把诸如图片的旋转角度、拍摄地点、曝光等参数写入到其中。而 Android 系统兼容了这个信息的读取。

当图片具有 EXIF 信息，并且旋转角度是 90 度或者 270 度时，系统会把图片的宽高信息取反，即宽变成高，高变成宽。如果我们忽略了 EXIF 的信息，那么可能导致业务出异常，比如图片的缩放比例出现问题。此时我们需要手动兼容存在 EXIF 信息的场景，即当存在 EXIF 信息并且旋转了时，得把宽高值再取反一次。负负得正，保证图片的宽高信息是正常的。

Android 系统读取 EXIF 信息主要是用到了 ExifInterface 这个类。这个类支持图片 EXIF 信息的读取和修改。

```kotlin
// 先定义 bean 类
class ImageInfo {
    val width: Int
        get() {
            // 图片存在 Exif 信息，并且旋转了 90 度或者 270 度，则交换宽高值
            return if (careOrientation && isRotated) {
                options.outHeight
            } else {
                options.outWidth
            }
        }
    val height: Int
        get() {
            // 图片存在 Exif 信息，并且旋转了 90 度或者 270 度，则交换宽高值
            return if (careOrientation && isRotated) {
                options.outWidth
            } else {
                options.outHeight
            }
        }
    // 宽高不用从这里获取，可用于获取其他信息，比如 mimeType 等
    var options: BitmapFactory.Options = BitmapFactory.Options()
    // 是否关注图片旋转信息的标志位
    var careOrientation: Boolean = true
    // 图片的旋转角度
    var orientation = ExifInterface.ORIENTATION_UNDEFINED
    // 图片是否旋转了的标志
    val isRotated: Boolean
        get() {
            return orientation in arrayOf(
                ExifInterface.ORIENTATION_ROTATE_90,
                ExifInterface.ORIENTATION_ROTATE_270,
            )
        }
}

// 获取图片的旋转信息
private fun getRotateInfo(info: ImageInfo, path: String) {
    try {
        val exif = ExifInterface(path)
                
        info.orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_UNDEFINED
        )
    } catch (e: Exception) {
        Log.e(TAG, e)
    }
}

// 修改 Exif 的信息并保存
private fun setExifInfo(info: ImageInfo, path: String) {
    try {
        val exif = ExifInterface(path)
        // 调用多个 set 方法
        exif.setAttribute(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL.toString()
        )
        exif.resetOrientation()
        // 最后调用 save 方法保存
        exif.saveAttributes()
    } catch (e: Exception) {
        Log.e(TAG, e)
    }
}
```

ExifInterface 还有大量其他的方法方便我们使用，具体的可见类的 API 文件。

## 图片的旋转

在了解了图片的旋转角度后，我们自然会想到如何根据旋转角度获取图片的正确数据。其实我们只需要根据旋转角度再旋转下图片，就可以获取正确的图像数据了。

图片的旋转需要用到矩阵 Matrix，矩阵 Matrix 的详细讲解可以看这篇文章：https://blog.csdn.net/cquwentao/article/details/51445269

关于图片的翻转可以看这片文章：https://www.loongwind.com/archives/72.html

对于图像的处理，涉及到三种逻辑：

- 旋转：用 rotate 表示，旋转后的图片有旋转角度(orientation)，旋转操作有顺时针(clockwise：CW)和逆时针(counterclockwise：CCW)的区别
- 翻转：用 flip 表示，有沿 x 轴和 y 轴翻转两种形式，沿 x 轴翻转是垂直翻转，沿 y 轴翻转是水平翻转。即沿 x 轴也沿 y 轴翻转相当于对图片进行了 180 度旋转。
- 转置：用 transpose 和 transverse 表示，transpose 相当于沿左上 - 右下对角线翻转。也可以表示为先水平翻转再顺时针旋转270度(等于逆时针旋转 90 度)；transverse 表示图像沿右上 - 左下对角线翻转，也可以表示为先水平翻转再顺时针旋转90度(等于逆时针旋转 270 度)。

旋转方法如下：

```kotlin
/**
 * 当角度为 [ExifInterface.ORIENTATION_UNDEFINED] 或者 
 * [ExifInterface.ORIENTATION_NORMAL] 时，表示不用旋转
 */
fun Bitmap.rotateBitmap(orientation: Int): Bitmap {
    val matrix = Matrix()
    when (orientation) {
        // 图片已水平翻转
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> {
            matrix.setScale(-1f, 1f)
        }
        // 图片已旋转 180 度
        ExifInterface.ORIENTATION_ROTATE_180 -> {
            // 顺时针旋转 180 度
            matrix.setRotate(180f)
        }
        // 图片已垂直翻转
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
            // 下面两个语句等价于 matrix.postScale(1f, -1f)
            matrix.setRotate(180f)
            matrix.postScale(-1f, 1f)
        }
        // 沿左上 - 右下对角线翻转
        ExifInterface.ORIENTATION_TRANSPOSE -> {
            // 先顺时针旋转 90 度，再水平翻转
            matrix.setRotate(90f)
            matrix.postScale(-1f, 1f)
        }
        // 图片已逆时针旋转 90 度
        ExifInterface.ORIENTATION_ROTATE_90 -> {
            // 顺时针旋转 90 度
            matrix.setRotate(90f)
        }
        // 沿右上 - 左下对角线翻转
        ExifInterface.ORIENTATION_TRANSVERSE -> {
            // 先逆时针旋转 90 度，再水平翻转
            matrix.setRotate(-90f)
            matrix.postScale(-1f, 1f)
        }
        // 图片已逆时针旋转 270 度
        ExifInterface.ORIENTATION_ROTATE_270 -> {
            // 逆时针旋转 90 度
            matrix.setRotate(-90f)
        }
        // 其他场景不做转换
        else -> return this
    }
    try {
        // 创建新的 bitmap
        val bmRotated = Bitmap.createBitmap(
            this,
            0,
            0,
            width,
            height,
            matrix,
            true
        )
        if (bmRotated != this)
            recycle()
        return bmRotated
    } catch (e: Exception) {
        e.printStackTrace()
        return this
    }
}
```

## 图片的颜色取值判断

我们使用诸如 [color-thief-java](https://github.com/SvenWoltmann/color-thief-java) 这样的开源库来读取颜色的主色列表，但是这样取出来的颜色，可能并不会让视觉同学满意，最常见的问题就是颜色值不对，影响了图片上相关问题的显示。例如当文字为白色时，背景色过浅，则会影响文字的展示效果，所以我们还需要对颜色的深浅做一些判断处理。

如何颜色的深浅呢？首先我们需要了解一些颜色格式，常见的颜色格式有 RGB/ARGB/HSV/HSB/YUV 等。其中 YUV 格式大量应用于视频画面中。

YUV 格式是亮度参量和色度参量分开表示的像素格式，其中 "Y" 表示明亮度(Luminance 或 Luma)，也就是灰度值；而 "U" 和 "V" 表示的则是色度(Chrominance 或 Chroma)，作用是描述影像色彩及饱和度，用于指定像素的颜色。

YCbCr 则是 YUV 经过缩放和偏移的翻版，是在世界数字组织视频标准研制过程中作为 ITU - R BT.601 建议的一部分。一般人们所讲的 YUV 格式大多是指 YCbCr 格式。YCbCr 中 Y 是指亮度分量，Cb 指蓝色色度分量，而 Cr 指红色色度分量。在 YUV 家族中，YCbCr 是在计算机系统中应用最多的成员，其应用领域很广泛，JPEG、MPEG 等均采用此格式。

要判断一个是否过浅，通过判断颜色的 Y 值。Y 值大于基准值时，我们就可以认为颜色过亮(过浅)了，会影响白色文字的显示。而基准值我们可以让视觉同学指定一个基准颜色，然后得出该颜色的 Y 值。

通常视觉同学给出的颜色都是 RGB 或者 ARGB 格式，此时我们就需要将颜色转为 YUV 格式，RGB 和 YUV 颜色的互转可以使用如下方法：

```kotlin
/**
 * 获取颜色(ARGB 的整型)的 yuv Data 数据
 * */
fun Int.rgb2yuv(): IntArray {
    val colorRed = Color.red(this)
    val colorGreen = Color.green(this)
    val colorBlue = Color.blue(this)
	// roundToInt 方法为四舍五入浮点数到整数
    val yuvY = ( 0.299 * colorRed + 0.587 * colorGreen + 0.114 * colorBlue      ).roundToInt()
    val yuvU = (-0.148 * colorRed - 0.291 * colorGreen + 0.439 * colorBlue + 128).roundToInt()
    val yuvV = ( 0.439 * colorRed - 0.368 * colorGreen - 0.071 * colorBlue + 128).roundToInt()

    return intArrayOf(yuvY, yuvU, yuvV)
}

/**
 * 根据颜色 yuv Data 获取 RGB 颜色，数组尺寸只能为 3、4。
 * - 尺寸为3时，表示颜色为 yuv  格式，透明度为不透明
 * - 尺寸为4时，表示颜色为 yuva 格式，透明度为 a 的值
 * */
fun IntArray.yuv2rgb(): Int {
    if (this.size == 3) {
        val rgbArray = trans2rgbArray()

        return Color.argb(255, rgbArray[0], rgbArray[1], rgbArray[2])
    }

    if (this.size == 4) {
        val rgbArray = trans2rgbArray()

        return Color.argb(this[3], rgbArray[0], rgbArray[1], rgbArray[2])
    }

    return 0
}

private fun IntArray.trans2rgbArray(): IntArray {
    this[0] -= 16
    this[1] -= 128
    this[2] -= 128

    val red = (1.164 * this[0] + 1.596 * this[2]).roundToInt()
    val green = (1.164 * this[0] - 0.392 * this[1] - 0.813 * this[2]).roundToInt()
    val blue = (1.164 * this[0] + 2.017 * this[1]).roundToInt()

    return intArrayOf(red, green, blue)
}
```

对于颜色过浅的问题，我们做如下判断和处理，假定基准颜色的 Y 值为 140：

```kotlin
fun generateFinalColor(colorInt: Int): Int {
	val colorYUV = colorInt.rgb2yuv()
	val baseY = 140
	if (colorYUV[0] < baseY) {
		return colorInt
	}
	// Y 值大于 140，颜色过亮，需要暗点
	colorYUV[0] = baseY
	
	return colorYUV.yuv2rgb()
}
```

## 图片取色算法

图片取色算法主要用于从图像中提取主要颜色。有许多不同的算法可以实现这个目标，以下是一些常见的图片取色算法及其实现细节：

### 直方图法

直方图法是一种基于图像中像素颜色分布的算法。首先，计算图像中每种颜色的出现次数，然后找到出现次数最多的颜色。实现细节如下：

1. 遍历图像中的每个像素

2. 对于每个像素，获取其颜色值（例如，RGB值）

3. 使用哈希表或数组记录每种颜色的出现次数

4. 遍历哈希表或数组，找到出现次数最多的颜色

### K-means聚类

K-means 聚类是一种将图像中的颜色分为K个簇的算法。然后，可以选择每个簇的中心颜色作为主要颜色。实现细节如下：

1. 选择K个初始颜色作为簇中心。

2. 遍历图像中的每个像素。

3. 对于每个像素，计算其与每个簇中心的距离（例如，欧几里得距离）。

4. 将像素分配给距离最近的簇中心。

5. 更新每个簇的中心，使其成为簇中所有像素颜色的平均值。

6. 重复上述过程，直到簇中心不再发生变化或达到最大迭代次数。

7. 选择每个簇的中心颜色作为主要颜色，返回列表。

### 主成分分析（PCA）

主成分分析是一种降维技术，可以用于提取图像中的主要颜色。实现细节如下：

1. 将图像中的每个像素颜色表示为一个向量（例如，RGB向量）。

2. 计算颜色向量的协方差矩阵。

3. 计算协方差矩阵的特征值和特征向量。

4. 选择最大特征值对应的特征向量作为主成分。

5. 将颜色向量投影到主成分上，得到新的颜色值。

6. 使用直方图法或其他方法从投影后的颜色中提取主要颜色。

### 颜色量化

颜色量化是一种减少图像中颜色数量的方法，可以用于提取主要颜色。实现细节如下：

1. 使用颜色空间划分（例如，八叉树或均匀划分）将图像中的颜色减少到一定数量。

2. 计算每个颜色区域的平均颜色。

3. 使用直方图法或其他方法从减少颜色后的图像中提取主要颜色。

### 中位切分法（Median cut）


中位切分法（Median Cut）是一种颜色量化算法，用于从图像中提取主要颜色。它通过将颜色空间划分为若干个区域，并计算每个区域的平均颜色来实现。

以下是中位切分法提取颜色的过程：

1. 准备工作：

    - 从图像中获取所有像素的颜色值（例如，RGB值）。

    - 将颜色值存储在一个列表中。

2. 切分颜色空间：

    - 找到颜色列表中颜色值的最大范围（红、绿、蓝中的一个）。

    - 按照最大范围的颜色分量对颜色列表进行排序。

    - 在中位数处将颜色列表切分为两个子列表。这样，我们就得到了两个颜色区域。

    - 重复上述过程，直到达到所需的颜色区域数量。每次迭代时，都会将一个颜色区域切分为两个子区域。

3. 计算每个颜色区域的代表颜色：

    - 对于每个颜色区域，计算区域内所有颜色值的平均颜色。这可以通过计算每个颜色分量（红、绿、蓝）的平均值来实现。
    
    - 将计算得到的平均颜色作为该颜色区域的代表颜色。

4. 提取主要颜色：

    - 最终，我们得到了与颜色区域数量相等的代表颜色。这些代表颜色就是通过中位切分法提取的主要颜色。

中位切分法的优点是它可以很好地保留图像中的颜色分布，同时减少颜色数量。然而，它的计算复杂度较高，可能不适用于实时处理大量图像的场景。

### 八叉树算法（Octree）

八叉树是一种颜色量化算法，用于将图像中的颜色减少到一定数量。它通过将颜色空间划分为若干个立方体，并计算每个立方体的平均颜色来实现。

以下是八叉树算法提取颜色的过程：

1. 准备工作：

    - 从图像中获取所有像素的颜色值（例如，RGB值）。

    - 初始化一个空的八叉树。

2. 构建八叉树：

    - 遍历图像中的每个像素颜色。

    - 将每个颜色插入到八叉树中。如果当前节点已经有8个子节点，则将颜色插入到相应的子节点中。否则，将颜色存储在当前节点，并更新节点的颜色计数和总颜色值。

    - 如果八叉树的节点数量超过了预设的最大值，可以通过合并颜色最接近的子节点来减少节点数量。

3. 提取主要颜色：

    - 遍历八叉树中的每个叶子节点。

    - 计算每个叶子节点的平均颜色（将节点的总颜色值除以颜色计数）。

    - 将计算得到的平均颜色作为主要颜色。

### 神经网络（Neural-Net）

神经网络颜色量化算法使用自组织映射（Self-Organizing Map，SOM）神经网络从图像中提取主要颜色。

以下是神经网络提取颜色的过程：

1. 准备工作：

    - 从图像中获取所有像素的颜色值（例如，RGB值）。

    - 初始化一个SOM神经网络。神经网络通常具有一维或二维的拓扑结构，每个神经元都有一个与颜色值相对应的权重向量。

2. 训练神经网络：

    - 随机选择一个像素颜色作为输入。

    - 计算输入颜色与神经元权重向量之间的距离（例如，欧几里得距离）。

    - 找到距离最小的神经元（称为最佳匹配单元，BMU）。

    - 更新BMU及其邻近神经元的权重向量，使其更接近输入颜色。更新幅度随着迭代次数和距离BMU的远近而逐渐减小。

    - 重复上述过程，直到达到预设的迭代次数。

3. 提取主要颜色：

    - 遍历神经网络中的每个神经元。

    - 将神经元的权重向量作为主要颜色。

神经网络颜色量化算法的优点是可以自动调整颜色空间的划分，以适应图像中的颜色分布。然而，它的计算复杂度较高，可能不适用于实时处理大量图像的场景。

### 总结

这些算法中的每一个都有其优缺点，具体取决于应用场景和需求。在实际应用中，可以根据需要选择合适的算法。

## 图片的缩放与圆角问题、格式转换与阴影问题

ImageView 的 scaleType 可能导致图像圆角消失，包括 centerCrop，fitXY 等。如果给 ImageView 设置了 centerCrop，当 ImageView 和 Bitmap 的宽高比不匹配时，会出现圆角消失的问题。即使我们提交的 Bitmap 有裁剪过圆角的。解决方法有两种：

- 一种是自定义 View，在 onDraw 时绘制圆角。
- 一种是将 Bitmap 的剪裁宽高比与 ImageView 的尺寸保持一致，ImageView 的尺寸可以先跑一次功能进行获取。再将 Glide 加载图片的尺寸缩放设置为对应的尺寸比例。

图片 png 转 webp 后，也得看看效果是否正常，尤其是带阴影的 ui 效果(视觉那边叫投影)。我就碰到了 png 转了 75% 的 webp 后，阴影效果丢失的问题。修复办法可尝试转 100% 的 webp，或者保留 png 原图。
