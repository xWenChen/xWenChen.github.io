---
title: "Flutter自定义绘制详解"
description: "本文讲述了在Flutter中进行自定义绘制的相关知识"
keywords: "Flutter,自定义绘制"

date: 2025-02-22T17:20:00+08:00

categories:
  - Flutter
tags:
  - Flutter
  - 自定义绘制

url: post/CA2DB277B8234BC39A3A461B26C250A3.html
toc: true
---

本文讲述了在Flutter中进行自定义绘制的相关知识。

<!--More-->

在Flutter中，某些时候系统提供的控件可能无法实现我们想要的效果，这时候就需要我们进行自定义绘制。

Flutter底层使用的skia引擎进行绘制，skia引擎定义Canvas+Painter进行绘制，这一点和Android/html是类似的，Android的软解也是使用的skia，chrome中也有Canvas API。

我们可以使用CustomPaint+Canvas+Paint实现自定义绘制效果，此处Canvas为画布，Paint为画笔。

Flutter中自定义绘制的控件可以使用CustomPaint控件，并传入自定义的painter即可。

```dart
// 使用CustomPaint，传入我们自定义的myPainter，类型是_ImagePainter。
CustomPaint(
  painter: myPainter,
  size: widget.size,
)
```

而这个自定义的Painter也是继承自CustomPaint控件。我们只需要实现其paint和shouldRepaint即可。

```dart
class _ImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
```

CustomPainter的核心函数是paint函数，我们需要自定义Painter，并设置对应属性，在canvas上进行绘制。

```dart
@override
void paint(Canvas canvas, Size size) {
  final paint = Paint()..isAntiAlias = true;
  canvas..drawImageRect(image, src, dst, paint); // src
}
```

shouldRepaint 函数用于指定widget是否需要重绘，如果我们给CustomPainter传入了参数，那么我们可以使用参数比对数据是否相同，不同则可以直接重绘。

```dart
@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => data != oldDelegate.data;
```

## 基础知识

Flutter中和绘制相关的对象有三个，分别是Canvas、Layer 和 Scene：

- Canvas：封装了Flutter Skia各种绘制指令，比如画线、画圆、画矩形等指令。

- Layer：分为容器类和绘制类两种；暂时可以理解为是绘制产物的载体，比如调用 Canvas 的绘制 API 后，绘制产物被保存在 PictureLayer.picture 对象中。

- Scene：屏幕上将要要显示的元素。在上屏前，我们需要将Layer中保存的绘制产物关联到 Scene 上。

Layer上的内容需要借助SceneBuilder生成Scene，之后才能被渲染在屏幕上。这一过程被称之为addToScene。addToScene主要的功能就是将Layer树中每一个layer传给Skia（最终会调用native API），这是上屏前的最后一个准备动作，最后就是调用 window.render 将绘制数据发给GPU。

Scene的知识点就讲这么多，下面看看其他的知识点。

## Flutter绘制

### Flutter Layer

在Flutter中，Flutter Layer作为绘制产物的持有者，其作用是：

- 可以在不同的frame之间复用绘制产物（如果没有发生变化）。

- 划分绘制边界，缩小重绘范围。

Flutter在build、layout、render过程中会生成 3 棵树：

- Element Tree

- RenderObject Tree

- Layer Tree

可以说 Layer Tree是Flutter Framework最终的输出产物，之后的流程就进入到 Flutter Engine 了。

![Element_RenderObject_LayerTree](/imgs/Element_RenderObject_LayerTree.webp)

- 在build阶段，由 Element Tree 生成 RenderObject Tree。

- 在paint阶段，由 RenderObject Tree 生成 Layer Tree。

- 有当RenderObject的isRepaintBoundary为true时才会生成独立的 Layer 节点。

此处我们需要了解下LayerTree的生成机制，才能更好的进行自定义绘制，处理自定义绘制遇到的问题。

我们先看下Layer的类图。

![Layer类图](/imgs/Layer类图.webp)

如上图，Layer是抽象基类，其内部实现了基本的 Layer Tree 的管理逻辑以及对渲染结果复用的控制逻辑。具体的 Layer 大致可以分为2类。

- 容器类 Layer

- 绘制类 Layer

#### 容器类 Layer

ContainerLayer 虽然并非抽象类，开发者可以直接创建 ContainerLayer 类的示例，但实际上很少会这么做，相反，在需要使用使用 ContainerLayer 时直接使用其子类即可。在当前的 Flutter 源码中，没有直接使用 ContainerLayer 类的地方。

容器类 Layer 的作用是：

- 容器类 Layer 可以添加任意多个子Layer(当然也包括绘制类 Layer)，将组件树的绘制结构组成一棵树。即Layer树。

- 可以对多个 layer 整体应用一些变换效果。比如：

    - 剪裁效果（ClipRectLayer、ClipRRectLayer、ClipPathLayer）

    - 过滤效果（ColorFilterLayer、ImageFilterLayer）

    - 矩阵变换（TransformLayer）

    - 透明变换（OpacityLayer）

    - 其他效果。

值得说明的是，虽然 ContainerLayer 可以对其子 layer 整体进行一些变换，但是在大多数UI系统的 Canvas API 中，也都有一些变换相关的 API ，这也就意味着针对一些变换效果，我们

- 既可以通过 ContainerLayer 来实现，

- 也可以通过 Canvas 来实现。

比如，要实现平移变换，我们既可以使用 OffsetLayer ，也可以直接使用 Canva.translate API。那么，此时就有一个问题了，我们应该怎么选择实现方式呢？原则是什么？

答案是**优先使用 Canvas 来实现，只有当 Canvas 实现起来非常困难或实现不了时，才会用 ContainerLayer 来实现。**

一个典型的场景是，我们需要对组件树中的某个子树整体做变换，且子树中有多个 PictureLayer 时，可以使用Layer的变换功能。此时有几点需要说明：

- Canvas对象中也有名为 ...layer 相关的 API，如 Canvas.saveLayer，它和此处介绍的Layer含义不同，是两个概念。Canvas对象中的 layer 主要是提供一种在绘制过程中缓存中间绘制结果的手段，其是为了在绘制复杂对象时，方便多个绘制元素之间分离绘制而设计的。

- 我们可以简单认为不管 Canvas 创建多少个 layer，这些 layer 都是在同一个 PictureLayer 上（当然具体Canvas API底层实现方式还是Flutter团队说了算，但作为应用开发者，理解到这里就够了）。

了解了基础后，我们了解一下容器类 Layer 实现变换效果的原理。容器类 Layer 的变换在底层是通过 Skia 引擎来实现的，不需要 Canvas 来处理。具体的原理是，有变换功能的容器类 Layer 会对应一个 Skia 引擎中的 Layer，为了和Flutter framework中 Layer 区分开，flutter 中将 Skia 的Layer 称为 engine layer。而有变换功能的容器类 Layer 在添加到 Scene 之前就会构建一个 engine layer。

```dart
@override
void addToScene(ui.SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {
  // 构建 engine layer
  engineLayer = builder.pushOffset(
    layerOffset.dx + offset.dx,
    layerOffset.dy + offset.dy,
    oldLayer: _engineLayer as ui.OffsetEngineLayer?,
  );
  addChildrenToScene(builder);
  builder.pop();
}
```

比如 OffsetLayer 对其子节点整体做偏移变换的功能是 Skia 中实现支持的。Skia 可以支持多层渲染，但并不是层越多越好，engineLayer 是会占用一定的资源，Flutter 自带组件库中涉及到变换效果的都是优先使用 Canvas 来实现，如果 Canvas 实现起来非常困难或实现不了时才会用 ContainerLayer 来实现。

一个典型的场景是，我们需要对组件树中的某个子树整体做变换，且子树中有多个 PictureLayer 时，可以使用Layer的变换功能。这是因为一个 Canvas 往往对应一个 PictureLayer，不同 Canvas 之间相互隔离的，只有子树中所有组件都通过同一个 Canvas 绘制时才能通过该 Canvas 对所有子节点进行整体变换，否则就只能通过 ContainerLayer 。子节点何时复用同一个 PictureLayer，何时创建新的 PictureLayer的知识点在下面讲解。

#### 绘制类 Layer

绘制类 Layer 是真正用于承载渲染结果的 layer，在 Layer Tree 中属于叶结点。比如绘制类 Layer 的几个实现：

- PictureLayer承载的是图片的渲染结果。

- TextureLayer承载的是纹理的渲染结果。

Flutter最终显示在屏幕上的是位图信息，而位图信息正是由 Canvas API 绘制的。实际上，Canvas 的绘制产物由 Picture 对象表示，而当前版本的 Flutter 中只有 PictureLayer 才拥有 picture 对象，也就是说，Flutter 中通过Canvas 绘制自身及其子节点的组件的绘制结果最终会落在 PictureLayer 中。

综上，Flutter两种Layer的区别为：

- 如果是容器Layer，要绘制孩子和自身。当然，容器Layer自身也可以没有绘制逻辑，只绘制孩子即可，比如Center组件。

- 如果不是容器类Layer，是绘制类 Layer，则绘制自身即可，比如Image组件。

### 组件树绘制流程

绘制相关实现在渲染对象 RenderObject 中，RenderObject 中和绘制相关的主要属性有：

- layer：

- isRepaintBoundary：Flutter 自带了一个 RepaintBoundary 组件，它的功能其实就是向组件树中插入一个绘制边界节点。

- needsCompositing：图层合成。

Flutter第一次绘制时，会从上到下开始递归的绘制子节点，针对每个子节点，进行以下判断和处理：

- 如果子节点是一个边界节点，则判断该边界节点的 layer 属性是否为空（类型为ContainerLayer）

    - 为空就创建一个新的容器类Layer OffsetLayer 并赋值给它。

    - 如果不为空，则直接使用它。然后将该边界节点的 layer 传递给子节点。

- 如果子节点是非边界节点，且需要绘制。

    - 则会在第一次绘制时：

        - 创建一个Canvas 对象和一个绘制类Layer PictureLayer，然后将它们绑定，后续调用Canvas 绘制都会落到和其绑定的PictureLayer 上。

        - 接着将这个 PictureLayer 加入到边界节点的 layer 中。

    - 非第一次绘制，则复用已有的 PictureLayer 和 Canvas 对象 。

针对上述流程，需要补充两点：

- 如果遇到边界节点且其不需要重绘（_needsPaint 为 false) 时，会直接复用该边界节点的 layer，而无需重绘！这就是边界节点能跨 frame 复用的原理。

- 父节点在绘制子节点时，如果子节点是绘制边界节点，则在绘制完子节点后会生成一个新的 PictureLayer，后续其他子节点会在新的 PictureLayer 上绘制。

    - 因为只要一个组件需要往 Layer 树中添加新的 Layer，那么就必须也要结束掉当前 PictureLayer 的绘制。

![Layer树生成示例](/imgs/Layer树生成示例.webp)

当子树的递归完成后，就要将子节点的layer 添加到父级 Layer中。整个流程执行完后就生成了一棵Layer树。下面是 widget 树生成的Layer树的过程。 

1. RenderView 是 Flutter 应用的根节点，绘制会从它开始，所以他是一个绘制边界节点。
    - 在第一次绘制时，会为他创建一个 OffsetLayer(容器类Layer)，我们记为 OffsetLayer1，接下来 OffsetLayer1会传递给Row。
2. 由于 Row 是一个容器类组件且不需要绘制自身，那么接下来他会绘制自己的孩子，它有两个孩子：
    1. 先绘制第一个孩子Column1，将 OffsetLayer1 传给 Column1，而 Column1 也不需要绘制自身。
        1. 它又会将 OffsetLayer1 传递给第一个子节点Text1。Text1 需要绘制文本，他会使用 OffsetLayer1进行绘制。
            1. 由于 OffsetLayer1 是第一次绘制，所以会新建一个PictureLayer1(绘制类Layer)和一个 Canvas1 ，然后将 Canvas1 和PictureLayer1 绑定，接下来文本内容通过 Canvas1 对象绘制
            2. Text1 绘制完成后，Column1 又会将 OffsetLayer1 传给 Text2 。
        2. Text2 也需要使用 OffsetLayer1 绘制文本，但是此时 OffsetLayer1 已经不是第一次绘制。
            - 所以会复用之前的 Canvas1 和 PictureLayer1，调用 Canvas1来绘制文本。
        3. Column1 的子节点绘制完成后，PictureLayer1 上承载的是Text1 和 Text2 的绘制产物。
    2. Row 完成了 Column1 的绘制后，开始绘制第二个子节点 RepaintBoundary。
        1. Row 会将 OffsetLayer1 传递给 RepaintBoundary，由于它是一个绘制边界节点，且是第一次绘制
            1. 则会为它创建一个 OffsetLayer2，并结束PictureLayer1的绘制。接下来 RepaintBoundary 会将 OffsetLayer2 传递给Column2。
            2. Column2 会使用 OffsetLayer2 去绘制 Text3 和 Text4，绘制过程同Column1，在此不再赘述。
        2. 当 RepaintBoundary 的子节点绘制完时，要将 RepaintBoundary 的 layer（ OffsetLayer2 ）添加到父级Layer（OffsetLayer1）中。
    3. Row 完成了 RepaintBoundary 的绘制后，开始绘制第三个子节点 Text5。
        1. offsetLayer2完成绘制后，需要添加到父Layer offsetLayer1中，此时offsetLayer2的绘制结束。
        2. 绘制Text5时，会新建一个Canvas和PictureLayer，在其上绘制，并传递给父Layer。

至此，整棵组件树绘制完成，生成了一棵右图所示的 Layer 树。PictureLayer1 和 OffsetLayer2、PictureLayer3是兄弟关系，它们都是 OffsetLayer1 的孩子。

通过上面的流程，我们发现：同一个 Layer 是可以多个组件共享的，比如 Text1 和 Text2 共享 PictureLayer1。此时导致两个问题，

- Text1 文本发生变化需要重绘时，也会连带着 Text2 重绘。

- Text2 重绘时可能影响到Text1已绘制好的内容，即Text2覆盖了Text1的内容。

- 当然，这样设计的原因是为了节省资源，Layer 太多时 Skia 会比较耗资源，所以这其实是一个取舍的过程。

为了避免子节点不必要的重绘并提高性能，通常情况下都会将子节点包裹在RepaintBoundary组件中，这样会在绘制时就会创建一个新的绘制层(Layer)。

- RepaintBoundary的子组件将在新的Layer上绘制

- RepaintBoundary的父组件将在原来Layer上绘制

也就是说 RepaintBoundary 能隔离其子组件和父组件的绘制。

#### 重绘操作

因为绘制过程存在Layer共享，所以重绘时，需要重绘所有共享同一个Layer的组件。比如上面的例子中，Text1发生了变化，那么我们除了 Text1 也要重绘 Text2。

当一个节点需要重绘时，我们得找到离它最近的第一个父级绘制边界节点，然后让它重绘即可。RenderObject 通过调用 markNeedsRepaint 函数完成了这个过程。markNeedsRepaint用于发起重绘请求。当一个节点调用了它时，具体的步骤如下：

1. 从当前节点一直往父级查找，直到找到一个绘制边界节点时终止查找，然后会将该绘制边界节点添加到其PiplineOwner的 _nodesNeedingPaint 列表中(即保存需要重绘的绘制边界节点）。
2. 在查找的过程中，将自己到绘制边界节点路径上所有节点的_needsPaint属性置为true，表示需要重新绘制。
3. 请求新的 frame，执行重绘重绘流程。

## Paint类

了解了绘制流程后，在了解画布 Canvas 之前，我们先了解下画笔 Paint。Paint的常用方法如下：

![FlutterPaintAPI](/imgs/FlutterPaintAPI.webp)

### style

Paint的style为PaintingStyle.fill时，画笔的绘制会填充满图形内部。为 stroke 时，会进行描边操作。

![Style说明](/imgs/Style说明.webp)

### strokeCap

线条末端的样式如下，同样绘制的线条，round 和 square 比 butt 多出一些，多出的长度为 strokeWidth 的一半。默认为StrokeCap.butt。

![strokeCap说明](/imgs/strokeCap说明.webp)

### strokeJoin

拐角的形状即线段连接处的样式，主要有以下效果。默认为 miter，即尖角。

![strokeJoin说明](/imgs/strokeJoin说明.webp)

### strokeMiterLimit

strokeMiterLimit可以理解为需要绘制尖角时，可以反向延长的长度。如果绘制尖角时反向补充的长度超过了该限制。则将拐角样式会从斜接（miter）转换为圆角（bevel）或圆形（round）。这样做可以控制路径交点的外观，使其看起来更平滑或更尖锐。也可以避免更尖锐的角的出现。

![strokeMiterLimit说明](/imgs/strokeMiterLimit说明.webp)

### Shader

shader意为着色器，可以变更Paint的绘制样式。在Flutter中，Shader的优先级高于 color。我们可以使用以下代码设置渐变着色器：

```dart
final paint = Paint()
  ..style = PaintingStyle.fill
  // 线性渐变
  ..shader = ui.Gradient.linear(Offset.zero, Offset(100, 0), [Colors.red, Colors.blue], [0, 1]);
```

![Flutter线形渐变说明](/imgs/Flutter线形渐变说明.webp)

#### TileMode

着色器的构造函数如下：

```dart
// 渐变着色器
Gradient.linear(
  Offset from,
  Offset to,
  List<Color> colors, [
  List<double>? colorStops,
  TileMode tileMode = TileMode.clamp, // 颜色重复模式
  Float64List? matrix4,
])
// 图片构造器
ImageShader(
  Image image, 
  TileMode tmx, // 水平方向的重复模式
  TileMode tmy, // 竖直方向的重复模式
  Float64List matrix4, // 对图像应用matrix变换，比如平移、旋转等变换操作。
  {
    FilterQuality? filterQuality, // 采样的质量，有高（high）、中 (medium)、低（low）三类
  }
)
```

可以看到，两种着色器的构造函数中都有个TileMode参数。实际上，TileMode代表的是当无法填充满待绘制区域时，图片的重复模式。如图：

decal：对应方向不做任何处理，使用透明填充，比如tmx和tmy都为 decal 时的效果为：

![flutter_canvas_decal_decal](/imgs/flutter_canvas_decal_decal.webp)

clamp：图像边缘的延伸 / repeated：方向上重复图像。比如这是 tmx 为 clamp，tmy 为 repeated 时的效果图：

![flutter_shader_clamp_repeated](/imgs/flutter_shader_clamp_repeated.webp)

mirror：图像镜像填充，下面是 tmx 为 mirror，tmy 为 clamp 的效果图。

![flutter_shader_mirror_clamp](/imgs/flutter_shader_mirror_clamp.webp)

上面效果的代码为：

```dart
import 'dart:ui' as ui;

class CanvasDemo extends StatefulWidget {

  @override
  State<CanvasDemo> createState() => _CanvasDemoState();
}

class _CanvasDemoState extends State<CanvasDemo> {
  ui.Image? image;

  @override
  void initState() {
    if (mounted) {
      _loadImage();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (image == null) {
        return const Text(
          '加载中......',
          style: TextStyle(fontSize: 24,),
        );
      }
      return CustomPaint(
        painter: MyPainter(image!), // 使用自定义绘图
        size: const Size(500, 500),
      );
    });
  }
  // 加载assets图片
  Future<void> _loadImage() async {
    // 加载图片
    final data = await rootBundle.load('pic1.png'); // 不同平台的 assets 图片写法有区别。
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    image = frameInfo.image;
    setState(() {});
  }
}

// 自定义 Painter
class MyPainter extends CustomPainter {
  MyPainter(this.image,);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = ui.Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, ui.Paint()..color = Colors.red);

    final paint = Paint()
      ..isAntiAlias = true
      ..shader = ImageShader(
        image,
        ui.TileMode.mirror, // 重复模式
        ui.TileMode.clamp, // 重复模式
        Matrix4.identity().storage,
      );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### BlendMode

BlendMode代表了画笔的混合模式。我们可以使用该参数**混合Paint绘制的两个图层的内容**。如果是一个图层，可能效果有时候不会达到预期。

![BlendModeSrc](/imgs/BlendModeSrc.webp)

```dart
paint
  ..drawCircle(..) // 省略代码，先绘制的是dst，即目标图像
  ..drawRect(..) // 省略代码，后绘制的为src，即原图像
```

两个内容的混合，有两种模式：

- Alpha 合成 (Alpha Compositing)

- 混合 (Blending)

#### Alpha 合成

第一类，Alpha 合成，其实就是 「PorterDuff」这个词所指代的算法。「PorterDuff」并不是一个具有实际意义的词组，而是两个人的名字（准确讲是姓）。这两个人当年(1984年)共同发表了一篇论文，描述了 12 种将两个图像共同绘制的操作（即算法）。而这篇论文所论述的操作，都是关于 Alpha 通道（也就是我们通俗理解的「透明度」）的计算的，后来人们就把这类计算称为Alpha 合成 ( Alpha Compositing ) 。如下图，其中 in 代表的src和dst图像的相交区域，out代表的是不相交区域。

- 比如 srcIn 表示绘制src的图像，但是只绘制src和dst的相交区域。

- 比如 dstOut 表示绘制 dst 的图像，但是只绘制src和dst的不相交区域。

![Alpha合成](/imgs/Alpha合成.webp)

#### Blending混合

第二类，混合，也就是 Photoshop 等制图软件里都有的那些混合模式（multiply darken lighten 之类的）。这一类操作的是颜色本身而不是 Alpha 通道，并不属于 Alpha 合成，所以和 Porter 与 Duff 这两个人也没什么关系，不过为了使用的方便，它们同样也被Google加进了BlendMode里。

![Blending混合](/imgs/Blending混合.webp)

#### colorFilter

colorFilter 用于处理和融合图片颜色，类似 ColorFiltered 组件的效果。colorFilter会作为src图层(一个纯色图层)，盖在原图上面，此时原图是 dst 图像。想要自定义混合后最终的取值，可以更改画笔的BlendMode，以实现想要的效果。如下代码的效果为：

```dart
import 'dart:ui' as ui;

class MyPainter extends CustomPainter {
  MyPainter(this.image,);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = ui.Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..isAntiAlias = true
      ..shader = ImageShader(
        image,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        Matrix4.identity().storage,
      ) // ImageShader 先绘制，为 dst。
      ..colorFilter = const ui.ColorFilter.mode(Colors.green, ui.BlendMode.srcOut); // colorFilter 后绘制，为 src。

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

![flutter_paint_color_filter](/imgs/flutter_paint_color_filter.png)

#### imageFilter

imageFilter是图片绘制时的过滤器。其各个效果如下：

- ImageFilter.blur：高斯模糊效果，可以用于对图像进行模糊处理，通常用于创建背景模糊效果或柔和的视觉效果。可以指定水平和垂直方向上的模糊强度。

![flutter_paint_blur](/imgs/flutter_paint_blur.webp)

- ImageFilter.dilate/erode：膨胀/腐蚀操作，将一个像素膨胀/缩小为特定范围的像素，通常用于图像处理中的形态学操作，前者可以使图像中的亮区域变得更大，后者可以缩小该区域，通常用于增强图像中的特定特征。参数可以入传入 x/y 方向上的半径。

    - 注意：部分平台并为实现该操作，比如 web 平台，所以 dilate/erode API 存在兼容性问题。

    ![flutter_paint_dilate](/imgs/flutter_paint_dilate.webp)

#### MaskFilter

Paint 对象可以设置 maskFilter 属性，可以通过 MaskFilter.blur 让画笔进行高斯模糊，BlurStyle.solid 模式会让画笔绘制时，四周产生模糊的阴影。而BlurStyle.inner/outer 则是内外产生模糊，第二参决定模糊程度，比如 2、4、6。

![flutter_paint_mask_filter](/imgs/flutter_paint_mask_filter.webp)

## Canvas类

Flutter的绘制流程：

1. 构建一个 Canvas 用于绘制；同时创建一个绘制指令记录器，因为绘制指令最终是要传递给 Skia 的，而 Canvas 可能会连续发起多条绘制指令，指令记录器用于收集 Canvas 在一段时间内所有的绘制指令，因此Canvas 构造函数第一个参数必须传递一个 PictureRecorder 实例。

2. Canvas 绘制完成后，通过 PictureRecorder 获取绘制产物，然后将其保存在 Layer 中。

3. 构建 Scene 对象，将 layer 的绘制产物和 Scene 关联起来。

4. 上屏；调用window.render API 将Scene上的绘制产物发送给GPU。

几乎所有的UI系统都会提供一个自绘UI的接口，这个接口通常会提供一块2D画布Canvas，Canvas内部封装了一些基本绘制的API，开发者可以通过Canvas绘制各种自定义图形。Flutter提供了一个CustomPaint组件，Canvas可以结合CustomPainter在其中实现自定义图形绘制。

Canvas的常用方法有：

![FlutterCanvasAPI](/imgs/FlutterCanvasAPI.webp)

针对图中的方法，我们一个个说明。

### Canvas变换

在 Flutter 中，Canvas可以进行变换，常见的有以下几种，注意，这些变换是对canvas本身进行的变换，不是对其上内容进行的变换，但是最终会影响到内容的绘制：

- translate：对canvas进行平移操作。

- rotate：旋转canvas。旋转中心在 canvas 的左上角。

- scale：缩放canvas。小于1为缩小，大于1，为放大。

- skew：错切canvas。错切的大小是弧度制。比如错切90度，就是二分之派。

- transform：对canvas使用指定的矩阵变换，可以用来组合上面的四种效果。

```dart
@override
void paint(Canvas canvas, Size size) {
  final rect = ui.Rect.fromLTWH(0, 0, size.width, size.height);
  // 绘制一个矩形
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.green);
  // 保存当前状态
  canvas.save();
  // 两次translate的作用是位移到旋转中心
  canvas.scale(0.5, 0.5);
  canvas.translate(200, 200);
  canvas.rotate(pi * 0.25); // 弧度值，旋转 45 度
  canvas.translate(-100, -100); // 位移到 100，100 的位置。
  // 绘制一个矩形
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.blue);
  // 恢复到之前的状态
  canvas.restore();
}
```

![flutterCanvas变换说明](/imgs/flutterCanvas变换说明.webp)

图像的错切(skew)实际上是平面景物在投影平面上的非垂直投影，错切使图像中的图形产生扭变,相当于使图像发生了倾斜。其一般有两种情况：水平方向错切、垂直方向错切。

- 错切的原点是左上角。x向右是正方向，y向下是正方向。

- 错切的方向是正值表示向正方向倾斜。水平方向参数为 0.2 会使图形在 x 轴方向上向右倾斜。垂直方向参数为 0.2 会使图形在 y 轴方向上向下倾斜。

```dart
@override
void paint(Canvas canvas, Size size) {
  // 保存当前状态
  canvas.save();
  canvas.save();
  canvas.save();
  canvas.translate(200, 200);
  // 绿色菱形
  canvas.skew(0.25 * pi, 0.25 * pi);
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.green);
  canvas.restore();
  // 红色平行四边形
  canvas.translate(200, 0);
  canvas.skew(0.25 * pi, 0);
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.red);
  // 蓝色平行四边形
  canvas.restore();
  canvas.translate(0, 200);
  canvas.skew(0, 0.25 * pi);
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.blue);
  // 青色矩形
  canvas.restore();
  canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.cyan);
}
```
最终效果为：

![flutterCanvasSkew说明](/imgs/flutterCanvasSkew说明.webp)

skew传入的参数是弧度制，范围为：0到2π。

![flutterSkew操作](/imgs/flutterSkew操作.webp)

所以canvas.skew(-0.25 * pi, -0.25 * pi)这段代码实际计算方式为：

- X1=X+Y。
- Y1=X+Y。
- 假设正方形的边长为2X2，则变换的结果为：

   - (0,0)=>(0,0)
   - (0,1)=>(1,1) (1,0)=>(1,1)  2个点的计算结果重复了，消失了1个点。
   - (0,2)=>(2,2) (2,0)=>(2,2) (1,1)=>(2,2) 3个点的计算结果重复了，消失了2个点。
   - (2,2) => (4,4)  边长从2变成了4，边长增加了。

从上面的例子可以看出。

- 如果在x和y方向上都设置了错切，则图形最终会被压扁拉伸。而不是倾斜成平行四边形。
- 传入的角度越逼近(90+n*180度，比如-90，90，270度)，则压缩拉伸效果越严重。因为正切函数的图像为：

![正切函数图像](/imgs/正切函数图像.webp)

### Canvas状态

在 Flutter 中，绘图状态，如变换、剪裁、绘图属性等，都是以堆栈的形式存储的。

![Canvas堆栈结构](/imgs/Canvas堆栈结构.webp)

在Flutter中，Canvas的状态有以下结论：

- save操作用于保存状态到堆栈，restore操作用于从堆栈中恢复状态。save和restore操作必须一一对应。
- 绘制的内容不以堆栈存储，执行restore操作时，绘制的内容不会随着canvas的堆栈状态改变而改变。
- canvas的状态堆栈层数有一个count计数。
   - 入栈(save)操作时，count+1；退栈(restore)操作时，count-1。
   - count计数从1开始，因为canvas至少有一个状态。
   - 可以使用restoreToCount(int targetCount)跳转到指定到指定堆栈。如果targetCount<1，则canvas会退回最初的状态；如果targetCount>count，则什么都不会发生。
- canvas的状态堆栈和canvas中的图层不是一一对应的关系。因为
   - save操作并不会新建一个图层，此时不会应用Paint的colorFilter和blendMode等属性。只有 saveLayer 操作才会新建一个图层。此时colorFilter和blendMode等属性才能正确生效。

以下的例子说明了绘制的内容不会随着canvas的堆栈状态改变而改变：

```dart
@override
void paint(Canvas canvas, Size size) {
    // 保存当前状态
    canvas.save();
    // 进行一些变换
    canvas.translate(50, 50); // 位移
    canvas.rotate(0.5); // 旋转 0.5 弧度
    // 绘制一个矩形
    canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.blue);
    // 恢复到之前的状态
    canvas.restore();
    // 在恢复后的状态下绘制另一个矩形
    canvas.drawRect(Rect.fromLTWH(0, 0, 200, 200), Paint()..color = Colors.red);
}
```

效果图如下，可以看到canvas经过变换后绘制的蓝色区域，并未随着restore操作恢复到红色区域的位置。

![canvasRestore效果说明](/imgs/canvasRestore效果说明.webp)

以下例子用于说明 save 和 saveLayer 操作的区别。

原图为：
```dart
void paint(Canvas canvas, Size size) {
    const rect = ui.Rect.fromLTWH(0, 0, 200, 200);
    canvas.drawRect(rect, Paint()..color = Colors.red);
    canvas.translate(100, 100);
    canvas.rotate(-0.25 * pi);
    canvas.translate(-100, -100);
    canvas.drawRect(rect, Paint()..color = Colors.green);
}
```

![canvasSave原图](/imgs/canvasSave原图.webp)

下面的代码使用了 save()，但是效果和上图一致。

```dart
void paint(Canvas canvas, Size size) {
    const rect = ui.Rect.fromLTWH(0, 0, 200, 200);
    canvas.save();
    canvas.drawRect(rect, Paint()..color = Colors.red);
    canvas.restore();
    canvas.save();
    canvas.translate(100, 100);
    canvas.rotate(-0.25 * pi);
    canvas.translate(-100, -100);
    canvas.drawRect(rect, Paint()..color = Colors.green..blendMode=BlendMode.srcIn);
    canvas.restore();
}
```

只有正确使用了saveLayer()，才能正确展示效果。saveLayer要求我们传入一个Paint，该Paint用于指定blendMode。

- saveLayer传入的paint最好专门用来搞混合，和用于绘制的paint区分开。比如下面的 blendPaint 和 drawPaint。
- 要正确产生混合效果，在绘制 dst 和 src 图像时，最好都新建一个图层，并传入相同的blendMode。
- 先绘制的图像为 dst 图像，后绘制的图像为 src 图像。
- 如果混合效果与预期有出入，可以从几个方面判断：
   - 可以简单理解为canvas自带了一个默认图层，是透明的。restore时会进行图像混合。
   - 使用了硬件加速进行绘制，硬件加速的绘制可能和纯cpu的绘制有一些差异。
   - 使用 restore 的顺序会影响图像混合的先后顺序。

```dart
void paint(Canvas canvas, Size size) {
    const rect = ui.Rect.fromLTWH(0, 0, 200, 200);
    
    final drawPaint = Paint()..color = Colors.red;
    final blendPaint = Paint()..blendMode=BlendMode.srcIn; // 混合效果的画笔单独使用一个。
    
    // 该图层和默认图层混合
    canvas..saveLayer(rect, blendPaint)
    ..drawRect(rect, drawPaint) // 先绘制的为 dst。
    ..restore();
    
    // 新图层和上面混合过后的图层混合。
    drawPaint.color = Colors.green;
    canvas..saveLayer(rect, blendPaint)
    ..translate(100, 100)
    ..rotate(-0.25 * pi)
    ..translate(-100, -100)
    ..drawRect(rect, drawPaint) // 后绘制的为 src。
    ..restore();
}
```

效果能正确展示：

![blendMode效果](/imgs/blendMode效果.webp)

### Canvas裁剪

Canvas具有clipXXX系列的方法，以用来裁剪Canvas的可绘制区域。比如ClipRRect，可以用来裁剪圆角矩形：

```dart
const rect = Rect.fromLTWH(0, 0, 200, 200);

canvas
    ..clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8))) // 裁剪对后面的代码生效。
    ..drawRect(rect, Paint()..color = Colors.red);
```

clipXXX系列的方法有几点值得注意。

- clipXXX是对后续调用的绘制指令生效，比如上面例子中的drawRect。

- 由于clipXXX和saveLayer混用时，可能产生预期之外的效果。所以建议谨慎混用clipXXX和saveLayer，由clipXXX进行代替，复杂的效果可以使用clipPath实现。

### Canvas绘制

canvas的绘制方法通常是 drawXXX 的命名格式，如何 drawRect、drawCircle。有几个需要说明的方法为：

- canvas用于绘制图片的方法主要有两个：
    - drawImage：加载一张图片
    - drawImageRect，加载图片的指定区域到布局的制定范围内，可用于图片的局部加载和绘制。
- canvas用于绘制曲线的方法有三个：
    - drawArc：绘制一段圆弧
    - drawOval：绘制一个椭圆
    - drawPath：给Path添加相关的曲线路径
- drawPoints可以用于绘制指定图形，比如三角形。

对于椭圆的绘制，我们需要制定一个矩形区域，以进行椭圆的绘制，如下图，椭圆是包在矩形内的图形：

![drawOval说明](/imgs/drawOval说明.webp)

对于弧线的绘制，其实就是绘制椭圆的局部，所以需要加上起始角度和扫过角度。

- Canvas绘制时涉及到的角度的单位都是弧度制。
- 起始角度向右为0度。
- 扫过角度顺时针为正，逆时针为负。
- useCenter用于指定是否闭合矩形中心点和弧线的两端，闭合就是绘制扇形，不闭合就是绘制弧线。

![drawArc说明](/imgs/drawArc说明.webp)

```dart
@override
void paint(Canvas canvas, Size size) {
  const rect = ui.Rect.fromLTWH(0, 0, 200, 200);
  final drawPaint = Paint()..color = Colors.red;
  canvas.drawArc(rect, 0, 0.5 * pi, true, drawPaint);
}
```

![drawArc结果](/imgs/drawArc结果.webp)

path可以组合多种图形和效果，绘制可以实现非常复杂的效果。

- drawShader可以在图形的下方绘制阴影。
- drawPoints可以实现画直线和曲线的效果
    - 绘制直线时需要给到[起点坐标、终点坐标、起点坐标、终点坐标……]的坐标列表
    - 绘制曲线是根据指定的控制点绘制的贝塞尔曲线。

```dart
void paint(Canvas canvas, Size size) {
  // 创建一个路径，结果是等腰三角形
  Path path = Path();
  path.moveTo(150, 100);
  path.lineTo(0, 200);
  path.lineTo(300, 200);
  path.close(); // 闭合首尾两个点，连接一条直线。
    
  // 绘制阴影
  canvas.drawShadow(path, Colors.red, 10.0, true); // 10.0为偏移量。

  // 使用Path绘制三角形
  Paint paint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke;

  canvas.drawPath(path, paint);

  // 根据点绘制三角形
  paint.color = Colors.green;
  canvas.drawRawPoints(
    ui.PointMode.lines, // 可以是单独的点、线、或者贝塞尔曲线。
    // 结果是绿色的三角形
    Float32List.fromList([
      150.0, 150.0, // 起点
      0.0, 250.0, // 终点
      150.0, 150.0, // 起点
      300.0, 250.0, // 终点
      0.0, 250.0, // 起点
      300.0, 250.0, // 终点
    ]),
    paint,
  );
}
```

![drawPath结果](/imgs/drawPath结果.webp)

## 总结

本文讲解了部分Flutter自定义绘制的知识点，还有很多内容没涉及到，但是能够满足日常开发了。Flutter自定义绘制的主要内容都在Paint和Canvas这两个类里定义了。其主要难点是Flutter Layer、Canvas Layer、BlendMode等内容的理解。但是多使用就能熟练掌握。