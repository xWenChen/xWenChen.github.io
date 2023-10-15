---
title: "Android 注解"
description: "本文讲解了 Android 中的注解知识"
keywords: "Android,注解"

date: 2020-01-27 21:18:00 +08:00
lastmod: 2020-01-27 21:18:00 +08:00

categories:
  - Android
tags:
  - 注解
  - Android

url: post/9C086EDE432D4777926B1838ED642D1F.html
toc: true
---

**本文主要讲解 Android 开发常用的注解**

<!--More-->

## 介绍

注解可以理解成一个标签，是给类、方法、变量、属性等加标签。注解（Annotation） 为我们在代码中添加信息提供了一种形式化的方法，是我们可以在稍后 某个时刻方便地使用这些数据（通过 解析注解 来使用这些数据），常见的作用有以下几种：

1. 提供信息给编译器： 编译器可以利用注解来探测错误和警告信息
2. 编译阶段时的处理： 软件工具可以用来利用注解信息来生成代码、Html文档或者做其它相应处理
3. 运行时的处理： 某些注解可以在程序运行的时候接受代码的提取

## 元注解

『元注解』是用于修饰注解的注解，通常用在注解的定义上，例如：

JAVA 中有以下几个『元注解』：

- @Target：注解的作用目标
- @Retention：注解的生命周期
- @Documented：注解是否应当被包含在 JavaDoc 文档中
- @Inherited：是否允许子类继承该注解

### @Target

@Target 注解指明了注解的使用范围。其包含一个 ElementType 数组类型的属性字段，属性名是 value。

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Target {
    ElementType[] value();
}
```

ElementType 是一个枚举类型，其包含以下一些值：

```java
public enum ElementType {
    // 被修饰的注解可以作用在类、接口(包括注解类型)、或者枚举上
    TYPE,
    // 被修饰的注解可以作用在属性上
    FIELD,
    // 被修饰的注解可以作用在方法上
    METHOD,
    // 被修饰的注解可以作用在参数上
    PARAMETER,
    // 被修饰的注解可以作用在构造器上
    CONSTRUCTOR,
    // 被修饰的注解可以作用在本地局部变量上
    LOCAL_VARIABLE,
    // 被修饰的注解可以作用在注解上
    ANNOTATION_TYPE,
    // 被修饰的注解可以作用在包上
    PACKAGE,
    // 1.8新增类型，被修饰的注解可以作用在泛型上
    TYPE_PARAMETER,
    // 1.8新增类型，被修饰的注解可以作用在任何类型上    
    TYPE_USE
}
```

### @Retention

Retention 的英文意为保留期的意思。当 @Retention 应用到一个注解上的时候，它解释说明了这个注解的的存活时间。

Retention 包含一个 RetentionPolicy 数组类型的属性字段，属性名是 value。

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Retention {
    RetentionPolicy value();
}
```

RetentionPolicy 意为保留策略，是一个枚举类型。

```java
public enum RetentionPolicy {
    // 注解只在源码阶段保留，在编译器进行编译时它将被丢弃忽视。
    SOURCE,
    // 注解只被保留到编译进行的时候，它并不会被加载到 JVM 中
    CLASS,
    // 注解可以保留到程序运行的时候，它会被加载进入到 JVM 中，所以在程序运行时可以获取到它们
    RUNTIME
}
```

### @Documented

顾名思义，@Documented 是和文档有关。被它标记的元素会被 Javadoc 工具处理，作用是能够将注解中的元素包含到 Javadoc 中去。

### @Inherited

Inherited 是继承的意思，其表明了注解的继承关系，子类可以继承父类的注解声明。

如果一个类 1 被 @Inherited 注解过，那么用注解 A 去标记类 1，类 2 继承自类 1。不管类 2 有没有注解 A，类 2 都有 A 的注解，其继承自类 1。

### @Repeatable

Repeatable 是可重复的意思。@Repeatable 是 Java 1.8 才加进来的，所以算是一个新的特性。

```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Repeatable {
    // 包含一组相同类型的值
    Class<? extends Annotation> value();
}
```

从上面的代码可以看出，@Repeatable 注解使用了泛型，其值是注解的 Class 类型，属性名是 value。

该注解的用法可以参考[这篇博文](https://blog.csdn.net/ljcgit/article/details/81708679)，此处就不介绍了，还是很简单的.
```

# 注解的属性

从上面的代码中，我们知道注解的定义是使用 @interface。其实所有的注解都隐式继承自 Annotation 这个接口。所以我们见到的所有注解的属性，严格意义上讲并不是属性，而是方法。想想接口的方法是怎么定义的？

```java
public interface A {
    // 接口的方法定义，加括号
    String say();
}

public @interface B {
    // 注解的属性定义，加括号
    String say();
}
```

两者的定义方式是不是出奇的一致！！！所以，注解的属性，念做属性，实为方法。因此，**注解中的属性定义时，一定要加上括号。**

## Java 内置注解

Java 的内置注解，相信我们大家都不陌生。包括 @Deprecated，@Override，@SuppressWarnings，@SafeVarargs，@FunctionalInterface。

### @Deprecated

这个元素是用来标记过时的元素，编译器在编译阶段遇到这个注解时会发出提醒警告，告诉开发者正在调用一个过时的元素比如过时的方法、过时的类、过时的成员变量。比较鲜明的特征是，被这个注解标记的元素会被打上删除线。

### @Override

这个元素提示子类要复写父类中被 @Override 修饰的方法。表明子类中被这个注解标记的方法均来自父类。该注解只可作用于方法。

### @SuppressWarnings

这个注解用来抑制编译器的警告。之前说过调用被 @Deprecated 注解的方法后，编译器会警告提醒。而有时候开发者会忽略这种警告，他们可以在调用的地方通过 @SuppressWarnings 达到目的。

该注解的使用原理：Java 1.5 为 Java 增加了注解。使用时可以为 "javac" 指令增加 -Xlint 参数来控制是否报告这些警告（如@Deprecated）。默认情况下，Sun 编译器**以简单的两行的形式输出警告。通过添加 -Xlint:keyword 标记（例如 -Xlint:finally），您可以获得关键字类型错误的完整说明。通过在关键字前面添加一个破折号，写为 -Xlint:-keyword，您可以取消警告。（-Xlint 支持的关键字的完整列表可以在 javac 文档页面上找到。）**

下面是使用到的关键字的详细说明：
- deprecation：使用了不赞成使用的类或方法时的警告
- unchecked：执行了未检查的转换时的警告，例如使用集合时没有指定泛型类型
- fallthrough：当 Switch 程序块直接通往下一种情况而**没有 Break **时的警告
- path：在类路径、源文件路径等中有不存在的路径时的警告
- serial：当在可序列化的类上缺少 serialVersionUID 定义时的警告
- finally：任何 finally 子句不能正常完成时的警告
- all：关于以上所有情况的警告

基于上面的描述，下面是一个使用例子：

```java
public class D1 {
    @Deprecated
    public static void foo() {
    }
}
 
public class D2 {
    // 忽略废弃元素的警告，value中的可指定值在上面列举出来了
    @SuppressWarnings(value={"deprecation"})
    public static void main(String[] args) {
       D1.foo();
    }
}
```

### @SafeVarargs

参数安全类型注解。它的目的是提醒开发者不要用参数做一些不安全的操作。它的存在会阻止编译器产生 unchecked 这样的警告。它是在 Java 1.7 的版本中加入的。

具体的例子此处我就不讲了，可以看看[这片博文](https://blog.csdn.net/lastsweetop/article/details/82863417)

### @FunctionalInterface

函数式接口注解，这个是 Java 1.8 版本引入的新特性。函数式编程很火，所以 Java 8 也及时添加了这个特性。函数式接口可以很容易转换为 Lambda 表达式。

## Android 注解

Android 平台提供了部分注解供我们使用，在使用之前，需要导入相关的包，语句如下：

```
compile 'com.android.support:support-annotations:VERSION_NUM'
```

此包提供的注解如下：

### IntDef 和 StringDef

IntDef 和 StringDef 是 Android 提供的两个魔法变量注解，用于取代 enum 和 魔法数字(字符串)等，其有一个数组类型的 value 属性。

假设我们需要定义消息类型，包括语音、文本、表情、图片、视频等，这些消息类型用整数定义。

```java
public class Msg {
    int msgType;
}
```

我们并不希望出现其他数字的消息类型，即需要限定类型的范围。此时就有几种方法：
- 在使用处加上注释，这并不是什么好方法，不建议采用
- 使用枚举类型代替整型，这种方法是可行的，但是在低端机上可以会存在内存占用大的情况。其使用方法如下：

```java
public class Msg {
    MsgType msgType;
}

public enum MsgType {
    TEXT, VOICE, PHOTO, VIDEO
}
```

- 第三种方法便是使用注解，可以使用 IntDef 注解。其使用方法如下：

```java
// 1、定义消息类型
public class MsgType {
    public static final int TEXT = 1;
    public static final int VOICE = 2;
    public static final int PHOTO = 3;
    public static final int VIDEO = 4;
}
// 2、自定义注解，指定取值范围，后续增加的消息类型都需要在这里加入
// IntDef 有一个属性 value 是一个 int 类型的数组
@IntDef(value = {MsgType.TEXT, MsgType.VOICE, MsgType.PHOTO, MsgType.VIDEO})
@Retention(RetentionPolicy.SOURCE)
public @interface AMsgType {

}
// 3、使用注解
// 这样就指定了取值范围
public class Test {
    @AMsgType
    public int msgType;
}
```

就这么简单，StringDef 的用法也差不多。不过需要注意的是，IntDef 注解还有个 boolean 类型的 flag 的属性，默认情况下，IntDef 的所有取值会被当作 enum （枚举类型）处理，而如果设置了 flag = true，那么 IntDef 中设置的取值范围就会被当作 flag （标志位）处理，标志位可以进行位运算。

另外，有一个 IntRange 注解和 IntDef 注解类似，前者可以指定取值范围，包括 from 和 to 两个属性，取值区间是连续的。而后者的取值范围更自由，可以不是连续的取值范围。

### Threading 注解

**Thread注解是帮助我们设置方法的执行线程**，如果和指定的线程不一致，抛出异常。Threading 注解类型：

- @UiThread：UI线程
- @MainThread：主线程
- @WorkerThread：工作线程（子线程）
- @BinderThread：绑定线程

### 取值限制范围注解

Android 提供了集中取值的范围限制注解供我们使用，其中就包括上面我们提到的 @IntRange 和 @FloatRange 注解，另外还包括一个 @Size 注解。常用的就这三个：

- @Size
- @IntRange
- @FloatRange

@Size 使用 min、max，而后两者使用 from、to。@Size 用于定义尺寸，其源码如下：

```java
@Retention(SOURCE)
@Target({PARAMETER,LOCAL_VARIABLE,METHOD,FIELD})
public @interface Size {
    // 尺寸的默认值
    long value() default -1;
    // 尺寸 n 的取值范围：min <= n <= max
    // 可取的最小值
    long min() default Long.MIN_VALUE;
    //　可取的最大值
    long max() default Long.MAX_VALUE;
    // 尺寸的缩放倍数
    long multiple() default 1;
}
```

### @CallSuper 注解

@CallSuper 注解主要是用来提示子类在覆盖父类的方法时，需要调用对应的super.***方法。下面的代码是个例子：

```java
// 父类
public class F {
    // 提示子类在重写父类的 init 方法时，需要加上 super.init 语句
    @CallSuper
    protected  void init(){

    }
}
// 子类
class T extends F{
    @Override
    protected void init() {
        // 此处不加入这句，编译器会报错
        super.init();
    }
}
```

### @CheckResult 注解

此注解主要是提示我们使用到方法定义的返回值。该注解有一个 suggest 的字符串类型的属性，允许我们加上一些提醒，来告诉方法调用者为什么要使用此方法的返回值。

```java
@CheckResult(suggest = "这是注解的说明，请使用返回值!!!")
public int getInt() {
    return 1;
}

public static void main(String[] args) {
    // 这种调用方式会报错
    getInt();
    // 这种调用方法是正确的
    int result = getInt();
}
```

另外，注解也可以通过反射获取到。