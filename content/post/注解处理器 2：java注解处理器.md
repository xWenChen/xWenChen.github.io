---
title: "注解处理器 2：java 注解处理器"
description: "本文讲解了 java 注解处理器的知识"
keywords: "Java,注解处理器"

date: 2023-03-12 15:35:00 +08:00
lastmod: 2023-03-12 15:35:00 +08:00

categories:
  - Java
  - 注解处理器
tags:
  - Java
  - 注解处理器

url: post/04B5C92A04564560A1143F299EA9A57A.html
toc: true
---

本文讲解了 java 注解处理器的知识。

<!--More-->

上篇文档：[注解处理器 1：javax.lang.model 包讲解](A90F3472990141F8B69A6EC73420C0D2.html)

下篇文档：[注解处理器 3：实战 Android Router 插件实现](A85ED138561142DBBFA335CE35A4289B.html)

## 概览

注解处理器(Annotation Processor Tool)是 javac 的一个工具，它用来在编译时扫描和处理注解(Annotation)。其生效的时间节点是 java 代码被编译为 class 之前，所以我们可以使用 APT 扫描源码，声明新文件，新文件可以是根据 java doc 生成的 html 文件、根据 java 源代码生成的 java 文件等等。

![注解处理器生效时间点](/imgs/注解处理器生效时间点.png)

我们可以自定义注解，并注册相应的注解处理器。注解处理器在 Java 5 开始就有了，但是从 Java 6(2006年12月发布) 开始才有可用的 API。

注解的处理过程是一轮一轮的循环过程。在每一轮中，处理器都需要处理在前一轮生成的源文件和 class 文件中找到的注解。第一轮处理的输入是注解处理工具运行的初始输入(initial inputs)；这些初始输入可以被视为虚拟的第零轮处理的输出。注解处理器可以处理给定的轮次，此时它将同时处理包括最后一轮在内后续的轮次，即使没有要处理的注解。注解处理器还可以处理由 APT 隐式生成的文件。

APT 工具使用发现进程(discovery process)搜索注解处理器，并决定这些注解处理器是否应该运行。通过配置 APT 工具，可以控制潜在的注解处理器。例如对于 [JavaCompiler](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/tools/JavaCompiler.html)，要运行的候选注解处理器列表可以直接由用于查找 service-style ([service-style lookup](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/ServiceLoader.html))的搜索路径([search path](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/tools/StandardLocation.html#ANNOTATION_PROCESSOR_PATH))设置或控制。其他 APT 工具的实现可能有不同的配置机制，例如命令行选项；要了解这些配置的详细信息，请参阅特定工具的文档。

APT 工具根据[根元素](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/annotation/processing/RoundEnvironment.html#getRootElements())上存在的[注解](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/lang/model/AnnotatedConstruct.html)、注解处理器[支持的注解](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/annotation/processing/Processor.html#getSupportedAnnotationTypes())、处理器[是否声明待处理的注解](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/annotation/processing/Processor.html#process(java.util.Set,javax.annotation.processing.RoundEnvironment))，决定运行哪些注解处理器。

注解处理器可以处理它支持的所有注解的一个子集，甚至是一个空集合。在给定的轮次中，APT 工具会计算根元素中的所有元素的注解集合。

- 如果注解集合不为空，那么当处理器声明了集合中的注解时，这些注解将从不匹配的注解集合中移除。当不匹配的注解集合为空，或者没有更多可用的处理器，该轮次运行完毕。
- 如果注解集合为空，注解处理仍会进行，但只有支持处理所有注解类型"*"的通用处理器(universal processors)才能声明内容为空的注解类型集合。

在每一轮处理中，如果该轮根元素中的元素上存在至少一个某个类型的注解，则认为该注解存在。这么做的目的是

- 泛型元素([generic element](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/lang/model/element/TypeParameterElement.html#getGenericElement()))包含类型参数(type parameter)
- 包元素(package element)不包含该包中的顶级类型(top-level types)，因为代表包的根元素是在处理包信息文件(process package-info file)时创建的
- 模块元素(module element)不包含该模块中的包，因为代表模块的根元素是在处理模块信息文件(process module-info file)时创建的
- 在计算是否存在注解类型时，忽略类型使用([type uses](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/annotation/ElementType.html#TYPE_USE))的注解，而不是元素(elements)上的注释

注意在调用注解处理器的 process 方法时，如果注解处理器返回了 true，则表示该注解处理器处理了注解，其他注解处理器不会再运行。如要要其他处理器能够继续运行，此方法应返回 false。

如果处理器抛出了未捕获的异常，APT 工具可能会停止其他运行的注解处理器。如果注解处理器触发了错误，则当前轮次运行完成，后续轮次将出现错误，不在运行。因此处理器应该仅在错误无法恢复或错误报告不可行的情况下抛出未捕获的异常。

APT 工具的环境不需要支持以多线程方式每轮([RoundEnvironment](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/annotation/processing/RoundEnvironment.html))或跨轮([ProcessingEnvironment](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/annotation/processing/ProcessingEnvironment.html))访问环境资源的注释处理器。

如果用于获取注解处理器配置信息的方法返回 null、其他无效结果或抛出异常，则 APT 工具框架将此视为错误场景。

为了保证不同的 APT 工具的实现的运行更健壮，注解处理器应该具有以下属性：

1. 函数实现应保证处理给定输入的结果不是其他输入存在与否的证据(正交性 orthogonality)
2. 处理相同的输入会产生相同的输出(一致性 consistency)
3. 先处理输入 A 再处理输入 B 等同于先处理 B 再处理 A(交换性 commutativity)
4. 处理输入不依赖于其他注解处理器输出(独立性 independence)

Filer 接口定义了注解处理器如何操作文件，后续再讲解。

## 注解处理器 API

Processor interface 是所有注解处理器的基类，AbstractProcessor 类是其直接实现类，每一个注解处理器都是继承于 AbstractProcessor。每一个注解处理器类都必须有一个空的构造函数。

Processor 的每个实现类都必须提供一个公共的无参数构造函数，以供工具实例化注解处理器。APT 框架与 Processor 实现类的交互步骤如下所示：

1. 如果有 Processor 的实例对象未被使用，则调用无参数构造函数创建处理器实例
2. 紧接着，APT 框架调用 init 方法，并传入适当的 ProcessingEnvironment 参数
3. 之后，APT 框架调用 getSupportedAnnotationTypes、getSupportedOptions 和 getSupportedSourceVersion 方法。这些方法每次运行只调用一次，而不是每一轮都调用
4. 最后，等到合适的时候，APT 框架调用 Processor 实例的 process 方法；并不是每一轮创建一个新的 Processor 实例

如果在没有遵循上述协议的情况下创建和使用 Processor 实例，则该 Processor 实例的行为不受 Processor 接口规范的控制。

Processor API 如下图所示：

![注解处理器API](/imgs/注解处理器API.png)

Processor 接口定义如下：

```java
public interface Processor {
    // 用于获取当前注解处理器支持的额外参数
    Set<String> getSupportedOptions();
    // 指定注解处理器是注册给哪个注解的，必须指定
    Set<String> getSupportedAnnotationTypes();
    // 指定 Java 版本，通常返回 SourceVersion.latestSupported()
    SourceVersion getSupportedSourceVersion();
    // 初始化操作，方法会被注解处理工具调用
    void init(ProcessingEnvironment var1);
    // 相当于每个处理器的主函数 main()
    // 我们在这里实现扫描、解析和处理注解的逻辑，以及生成 Java 文件
    boolean process(
        Set<? extends TypeElement> var1, 
        RoundEnvironment var2
    );
    // 主要供 IDE 使用，用于在使用注解时向用户提供关于注解的建议
    Iterable<? extends Completion> getCompletions(
        Element var1, 
        AnnotationMirror var2, 
        ExecutableElement var3, 
        String var4
    );
}
```

他们的作用如下：

- **`init(ProcessingEnvironment env)`:** init 方法会被注解处理工具调用，并传入 ProcessingEnviroment 参数。ProcessingEnviroment 类提供了很多有用的工具类：Elements, Types 和 Filer。后面我们将介绍详细的内容。

- **`process(Set<? extends TypeElement> annotations, RoundEnvironment env)`:** process 方法相当于每个处理器的主函数 main()。我们在这里实现扫描、解析和处理注解的逻辑，以及生成 Java 文件。方法会传入参数 RoundEnviroment，可以让你查询出包含特定注解的被注解元素。后面我们将介绍详细的内容。如果结果返回了 true，则表示该注解处理器处理了注解，其他注解处理器不会再运行。如要要其他处理器能够继续运行，此方法应返回 false。

- **`getSupportedOptions()`:** 用于获取当前注解处理器支持的额外参数。

- **`getSupportedAnnotationTypes()`:** 用于指定这个注解处理器是注册给哪个注解的，我们必须指定。注意，方法的返回值是一个字符串集合，包含处理器想要处理的注解类型的合法全称。换句话说，我们在这里定义注解处理器注册到哪些注解上。

- **`getSupportedSourceVersion()`:** 用于指定我们使用的 Java 版本，通常这里返回SourceVersion.latestSupported()。但是如果我们有足够的理由只支持 Java 6 的话，也可以返回 SourceVersion.RELEASE_6。但是推荐使用前者。

- **`getCompletions()`:** 主要供 IDE 使用，用于在使用注解时向用户提供关于注解的建议。本文就不细讲了。

在 Java 7 及更高版本，我们也可以使用注解来代替 getSupportedOptions() 方法、getSupportedAnnotationTypes() 方法、getSupportedSourceVersion() 方法。但是**因为兼容的原因，特别是针对 Android 平台，建议使用重载 getSupportedAnnotationTypes() 方法、getSupportedOptions() 方法、getSupportedSourceVersion() 方法代替 @SupportedAnnotationTypes 注解、@SupportedOptions注解、 @SupportedSourceVersion 注解。**

```java
@SupportedSourceVersion(SourceVersion.latestSupported())
@SupportedOptions({
   // 注解参数的集合
})
@SupportedAnnotationTypes({ 
   // 注解合法全名的集合 
})
public class MyProcessor extends AbstractProcessor {

    @Override
    public synchronized void init(ProcessingEnvironment env){ }

    @Override
    public boolean process(
      Set<? extends TypeElement> annoations, 
      RoundEnvironment env
}
```

## 注册注解处理器

想要我们自定义的注解处理逻辑生效，出了新增 Processor 外，我们还需要注册对应的注解处理器，注册方式是使用 java 的 SPI 机制(Service Provider Interface)。以下是相关知识点：

1. 如果是将注解处理器放入到 jar 包中，则在 jar 中，我们需要打包一个特定的形如 com.my.example.Processor 的文件到 META-INF/services 路径下，其中填入我们自定义的需要生效的注解处理器。javac 会自动检索和读取该文件的内容，并且注册对应的注解处理器。

2. 如果是以源码的形式参与编译，则在 moduleName/src/main/resources/META-INF 目录(services 目录可带可不带)下，可以新建一个形如 com.my.example.Processor 的文件(没有后缀名)，在其中输入注解处理器的全名称：

   ```
   com.my.example.MyProcessor
   com.my.example.YouProcessor
   com.my.example.OtherProcessor
   ```

3. 如果觉得上面新建文件的注册方式很麻烦，则可以使用以下语句引入 google 的 auto-service 库，该库封装了 SPI 的注册，将会在 META-INF/services 目录下自动生成对应的文件。
   
   ```groovy
   // 方便注解处理器生成对应的文件
   kapt "com.google.auto.service:auto-service:1.0.1"
   // 方便我们在项目源码中使用 auto-service 对应的注解
   implementation "com.google.auto.service:auto-service-annotations:1.0.1"
   ```

   引入之后使用 @AutoService 注解，我们就可以很方便的注册注解处理器了。

   ```groovy
   @AutoService(Processor::class) // 使用注解注册
   class MyProcessor : AbstractProcessor() {
      // 其他代码省略
   }
   ```

## ProcessingEnvironment 接口

Processor 的 init 方法调用时，APT 框架会提供一个 ProcessingEnvironment 接口类型的数据，以便注解处理器可以使用框架提供的能力(方便注解处理器与 APT 框架交互)。我们可以使用 ProcessingEnvironment 获取许多工具和能力，如编写新文件(write new files)、报告错误消息(report error messages)、或通过 ProcessingEnvironment 接口提供的方法寻找 APT 框架提供的其他工具类(find other utilities) 等。ProcessingEnvironment 是一个接口类，它的定义及作用如下：

```java
public interface ProcessingEnvironment {
    // 获取 Options
    Map<String, String> getOptions();
    // 获取 Messager
    Messager getMessager();
    // 获取 Filer
    Filer getFiler();
    // 获取 Elements
    Elements getElementUtils();
    // 获取 Types
    Types getTypeUtils();
    // 获取 SourceVersion
    SourceVersion getSourceVersion();
    // 获取 Locale
    Locale getLocale();
}
```

### Options

ProcessingEnvironment.getOptions() 方法通常和 Processor.getSupportedOptions() 搭配使用，前者可以用于获取传递给注解处理器的额外信息(即额外参数)，后者用于定义受支持的参数类型。我们可以在项目配置中传入自定义信息，并在自己的注解处理器中获取相关信息。总体而言，其使用分为如下 3 步：

**1. 传入参数**

在脚本配置中，我们可以使用 ProductFlavor.javaCompileOptions.annotationProcessorOptions 语句向注解处理器传入自定义的参数。注意使用 += 的方式为注解添加选项。防止其他设置项被覆盖掉。

```kotlin
// 当前文件：build.gradle

// 在 gradle 配置中传入参数
val options = mutableMapOf("moduleName" to project.name)

// 以 += 的方式为注解添加选项(arguments 方法内部调用了 Map 的 putAll 方法)
android.defaultConfig.javaCompileOptions
   .annotationProcessorOptions
   .arguments(options)
android.productFlavors.forEach {
   it.javaCompileOptions
      .annotationProcessorOptions
      .arguments(options)
}
```

**2. 过滤参数**

在自定义的 Processor 中，我们可以使用 Processor.getSupportedOptions() 方法过滤出当前处理器需要的参数类型。

```kotlin
override fun getSupportedOptions() = mutableSetOf("moduleName")
```

**3. 获取参数**

在自定义 Processor 的 init 方法中，我们可以使用 ProcessingEnvironment.getOptions() 方法过滤出当前处理器需要的参数类型。


```kotlin
class MyProcessor : AbstractProcessor() {

    private var moduleName = ""

    override fun init(env: ProcessingEnvironment?) {
        super.init(env)

        moduleName = env?.options?.get("moduleName") ?: ""
    }

    // 其他代码省略
}
```

在讲解 ProcessingEnvironment 的其他方法之前，我们需要了解一些基础的类的概念和 API，比如 Element、Type 等，这些类的讲解可见：[Java 语言模型 - javax.lang.model 包讲解](https://www.cnblogs.com/wellcherish/p/17147811.html)。

### Messager

Messager 使注解处理器能够向我们传递错误、警告和其他提示信息。Elements、annotations 和 annotation values 等元素可以被传递，用于为相关提示信息提供来源定位(比如用于在 IDE 中定位以显示错误提示)。但是请注意这样的定位可能是不准确的，或者是不可用的。

Messager 类的定义如下：

```java
public interface Messager {
    // 打印指定种类的信息
    void printMessage(
        Diagnostic.Kind kind, 
        CharSequence msg
    );
    // 在元素 e 的位置打印指定种类的信息
    void printMessage(
        Diagnostic.Kind kind, 
        CharSequence msg, 
        Element e
    );
    // 在注解元素 e 的注解 a 的位置打印指定种类的信息
    void printMessage(
        Diagnostic.Kind kind, 
        CharSequence msg, 
        Element e, 
        AnnotationMirror a
    );
    // 在注解元素 e 的注解 a 的注解值 v 的位置打印指定种类的信息
    void printMessage(
        Diagnostic.Kind kind, 
        CharSequence msg, 
        Element e, 
        AnnotationMirror a, 
        AnnotationValue v
    );
}
```

Diagnostic.Kind 是个用于表示信息种类的枚举类，类似于我们经常使用的日志级别(error、 warning、info、debug等)：

![Diagnostic_Kind枚举类](/imgs/Diagnostic_Kind枚举类.png)

### FileObject

在讲解 Filer 之前，需要讲解下 FileObject。

FileObject 类是 APT 工具的文件抽象。在 FileObject 的关联语境中，文件可以表示常规文件的抽象或者其他数据源的抽象。文件对象可用于表示常规文件(regular files)、内存缓存或数据库中的数据。对于此类，需要注意以下两点事项：

- 如果发生安全异常，此接口中的所有方法都可能抛出 SecurityException
- 除非明确规定，否则当给定 null 参数时，此接口中定义的所有方法都可能抛出 NullPointerException。

FileObject 的相关类如图：

![FileObject的相关类](/imgs/FileObject的相关类.png)

上图中的 URI 类是 java.net.URI 类，NestingKind 是 javax.lang.model.element.NestingKind 类，Modifier 是 javax.lang.model.element.Modifier 类，此处就不细讲了；io 相关的类也不再介绍了。感兴趣的读者可以自行搜索。此处只讲下 FileObject 及其子类。

#### FileObject 类

FileObject 类的定义如下：

```java
public interface FileObject {
    // 返回一个代表当前文件对象(file object)的 URI 实例
    URI toUri();
    // 返回此文件对象的用户易懂的名称(user-friendly name)
    // 虽然该接口未指定返回的确切值，但该接口的实现类应注意保留用户给定的名称
    // 例如用户在命令行中写入了文件名 "Test.java"，则此方法应返回 "Test.java"，
    // 而 toUri 方法会返回 file:///C:/Document/UncleBob/Test.java。
    String getName();
    // 返回此文件对象关联的 InputStream
    InputStream openInputStream() throws IOException;

    // 返回此文件对象关联的 OutputStream
    OutputStream openOutputStream() throws IOException;
    // 返回此文件对象关联的 Reader。返回的 Reader 将用默认的翻译字符替换无法解码的字节
    // 如果 ignoreEncodingErrors 不为 true，则 Reader 可以报告错误
    Reader openReader(boolean ignoreEncodingErrors) throws IOException;
    // 返回此文件对象的字符串内容(如果可用)。任何无法解码的字节都将被默认的翻译字符替换
    // 如果 ignoreEncodingErrors 不为 true，则 Reader 可以报告错误
    CharSequence getCharContent(boolean ignoreEncodingErrors) throws IOException;
    // 返回此文件对象关联的 Writer
    Writer openWriter() throws IOException;
    // 返回上次修改此文件对象的时间
    // 时间是 unix 时间戳的毫秒数，即自起点(1970-01-01 00:00:00)至今的毫秒数
    long getLastModified();
    // 删除此文件对象。成功则返回 true，如果失败或者出现错误，则返回 false
    boolean delete();
}
```

#### ForwardingFileObject 类

ForwardingFileObject 是 FileObject 的直接子类，可以将其理解为一个代理类。其直接持有一个 fileObject，对于 ForwardingFileObject 文件对象的操作，最终都会传递到其内部的 fileObject 对象上。

ForwardingFileObject 类的定义如下：

```java
// 泛型 F 代表持有的 fileObject 的实际类型
public class ForwardingFileObject<F extends FileObject> implements FileObject {
    // 持有的实际 fileObject
    protected final F fileObject;
    // 创建一个新的 ForwardingFileObject 实例
    protected ForwardingFileObject(F fileObject) {
        this.fileObject = Objects.requireNonNull(fileObject);
    }

    public URI toUri() {
        return fileObject.toUri();
    }

    public String getName() {
        return fileObject.getName();
    }

    public InputStream openInputStream() throws IOException {
        return fileObject.openInputStream();
    }

    public OutputStream openOutputStream() throws IOException {
        return fileObject.openOutputStream();
    }

    public Reader openReader(
        boolean ignoreEncodingErrors
    ) throws IOException {
        return fileObject.openReader(
            ignoreEncodingErrors
        );
    }

    public CharSequence getCharContent(
        boolean ignoreEncodingErrors
    ) throws IOException {
        return fileObject.getCharContent(
            ignoreEncodingErrors
        );
    }

    public Writer openWriter() throws IOException {
        return fileObject.openWriter();
    }

    public long getLastModified() {
        return fileObject.getLastModified();
    }

    public boolean delete() {
        return fileObject.delete();
    }
}
```

#### JavaFileObject 类

JavaFileObject 是 FileObject 的直接子类，表示 APT 工具运行时，Java 语言中源码文件和 class 文件的文件抽象，文件的后缀名可以通过`JavaFileObject.getKind().extension`语句获得。

SimpleJavaFileObject 类是 JavaFileObject 的直接实现类，并未新增方法，此处就不再单独讲解了。另外 ForwardingJavaFileObject 是 JavaFileObject 和 ForwardingFileObject 的实现类，并未新增方法，此处也不再单独讲解了。

JavaFileObject 类定义如下：

```java
public interface JavaFileObject extends FileObject {
    // JavaFileObjects 的文件类型，可用于获取文件后缀名
    enum Kind {
        // 源码文件，比如以 .java 结尾的文件
        SOURCE(".java"),
        // JVM 关联的 class 文件，以 .class 结尾
        CLASS(".class"),
        // 以 .html 结尾的 html 文件
        HTML(".html"),
        // 其他文件
        OTHER("");
        // 文件扩展名
        public final String extension;
        private Kind(String extension) {
            this.extension = Objects.requireNonNull(extension);
        }
    }
    // 获取当前文件对象(file object)的种类
    Kind getKind();
    // 判断当前文件对象是否与指定的 simpleName(如类的 simpleName，非全限定名)和 kind 兼容
    // 实现时是判断当前文件对象的文件名和 simpleName + kind.extension 是否相等
    boolean isNameCompatible(String simpleName, Kind kind);
    // 获取此文件对象表示的类的嵌套级别。此方法可能
    // 会返回 NestingKind.MEMBER，以表示 NestingKind.LOCAL 或 NestingKind.ANONYMOUS
    // 如果嵌套级别未知或此文件对象不代表类，则此方法返回 null。
    NestingKind getNestingKind();
    // 获取此文件对象表示的类的访问级别(与类的修饰符有关)
    // 如果访问级别未知或者此文件对象不代表类，则此方法返回 null。
    Modifier getAccessLevel();

}
```

### JavaFileManager

在讲解 Filer 之前，需要讲解下 JavaFileManager。

JavaFileManager 类表示 APT 工具在 Java 语言中针对源码文件和 class 文件的文件管理器。此处的文件表示常规文件和其他数据源的抽象(如缓存和数据库中的数据)。

当构造新的 JavaFileObjects 时，文件管理器必须确定在哪里创建它们。例如当文件管理器管理文件系统上的文件时，它可以有一个当前目录(或者叫工作目录)，作为创建和查找文件的默认位置。可以向文件管理器提供许多关于提示，以指示在何处创建文件。当然，任何文件管理器都可能选择忽略这些提示。

- 此接口中的某些方法使用了类名作为参数，类名和接口名必须以全限定名的形式给出。为了方便 '.'和'/'可以互换。这意味着"java/lang.package-info"、"java/lang/package-info"、"java.lang.package-info" 是有效且等价的。

   类名是对大小写敏感的，所有名称都要区分大小写。例如，如果某些文件系统区分文件名的大小写，代表此类文件的文件对象应注意使用 File.getCanonicalFile() 或类似方法来保留大小写；如果系统不区分大小写，则文件对象必须使用其他方式来保留大小写。

- 此接口中的某些方法使用相对名称，则相对名称是由 "/" 分隔的非 null/非空串的字符串。'.'或 '..'是无效的路径。有效的相对名称必须符合 RFC 3986 第 3.3 节的 "path-rootless" 规则。如下面的语句应该返回 true：
   
   ```java
   URI.create(relativeName)
       .normalize()
       .getPath()
       .equals(relativeName)
   ```

此接口中的所有方法都可能抛出 SecurityException；除非明确指出，否则给定 null 参数时，此接口中的所有方法都可能抛出 NullPointerException。

JavaFileManager 涉及到的相关类如图：

![JavaFileManager相关类](/imgs/JavaFileManager相关类.png)

#### JavaFileManager

JavaFileManager 类的定义如下：

```java
public interface JavaFileManager extends Closeable, Flushable, OptionChecker {
    // 文件对象(file object)的位置。文件管理器使用它来确定文件对象的位置
    interface Location {
        // 返回此 Location 的名称
        String getName();
        // 判断是否是用于输出结果的位置
        boolean isOutputLocation();
        // 判断是否是 module-oriented 的 location
        default boolean isModuleOrientedLocation() {
            return getName().matches("\\bMODULE\\b");
        }
    }
    // 返回一个类加载器，用于从给定的 package-oriented location 加载插件
    // 例如，编译器会用 StandardLocation.ANNOTATION_PROCESSOR_PATH 
    // 的 Location 请求一个类加载器，以用于加载 annotation processors
    ClassLoader getClassLoader(Location location);
    // 在给定的 package-oriented location 列出指定包的指定类型的所有文件对象
    // 如果 recurse 为 true，则列出"子包"中的文件对象
    // 注意即使文件管理器不知道给定的 location，它也可能不会返回 null 或抛出异常
    Iterable<JavaFileObject> list(
        Location location,
        String packageName,
        Set<Kind> kinds,
        boolean recurse
    ) throws IOException;
    // 基础 package-oriented location 推断文件对象的二进制名称(即 simpleName)
    String inferBinaryName(Location location, JavaFileObject file);
    // 如果两个文件对象代表的底层对象相同，则返回 true。
    boolean isSameFile(FileObject a, FileObject b);
    // 处理一个选项。如果 current 是文件管理器的一个选项，
    // 它将使用 remaining 中对应该选项的任何参数并返回 true，否则返回 false。
    boolean handleOption(String current, Iterator<String> remaining);
    // 判断文件管理器是否有 location
    boolean hasLocation(Location location);
    // 为 input 返回一个文件对象
    // 文件对象代表给定 package-oriented location 中特定 kind 的类
    JavaFileObject getJavaFileForInput(
        Location location,
        String className,
        Kind kind
    ) throws IOException;
    // 为 output 返回一个文件对象
    // 文件对象代表给定 package-oriented location 中特定 kind 的类
    // sibling 用于确定输出的位置，文件对象通常和 sibling 平级
    JavaFileObject getJavaFileForOutput(
        Location location,
        String className,
        Kind kind,
        FileObject sibling
    ) throws IOException;
    // 为 input 返回一个文件对象
    // 文件对象代表给定 package-oriented location 中相对名称为 relativeName 的类 
    FileObject getFileForInput(
        Location location,
        String packageName,
        String relativeName
    ) throws IOException;
    // 为 input 返回一个文件对象
    // 含义同 getFileForInput 方法相同
    FileObject getFileForOutput(
        Location location,
        String packageName,
        String relativeName,
        FileObject sibling
    ) throws IOException;
    // flush 此文件管理器为输出直接或间接打开的任何资源
    // flush 已关闭的文件管理器没有任何效果
    @Override
    void flush() throws IOException;
    // 释放此文件管理器直接或间接打开的任何资源
    // 调用此方法会使该文件管理器及其打开的对象变得无用
    // 注意关闭一个已经关闭的文件管理器没有任何效果。
    @Override
    void close() throws IOException;
    // java 1.9 新增方法
    // 获取 location 中 moduleName 模块的位置，
    // 该位置可以是 module-oriented location 或 output location
    // 如果入参 location 是输出位置，则结果将是 output location
    // 如果入参 location 不是输出位置，则结果将是 package-oriented location
    default Location getLocationForModule(
        Location location, 
        String moduleName
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
    // java 1.9 新增方法
    // 获取 location 中包含特定文件的模块的位置
    // 返回结果解释见上一个同名方法
    default Location getLocationForModule(
        Location location, 
        JavaFileObject fo
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
    // java 1.9 新增方法
    // 从给定 location 获取特定 service 的 ServiceLoader
    // 如果位置是 module-oriented 的位置，ServiceLoader 将使用在该位置找到的模块中的声明
    // 否则，将使用 package-oriented 的位置创建 ServiceLoader，
    // package-oriented 的位置 即 META-INF/services 中的 provider-configuration
    default <S> ServiceLoader<S> getServiceLoader(
        Location location, 
        Class<S> service
    ) throws  IOException {
        throw new UnsupportedOperationException();
    }
    // java 1.9 新增方法
    // 根据 getLocationForModule 或 listModuleLocations 
    // 返回的位置推断模块的名称
    default String inferModuleName(
        Location location
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
    // java 1.9 新增方法
    // 列出 module-oriented location 或 output location 中所有模块的位置
    // 如果入参 location 是 output，则返回的位置将是 output location，
    // 否则将是 package-oriented location
    default Iterable<Set<Location>> listLocationsForModules(
        Location location
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
    // java 1.9 新增方法
    // 确定 location 中是否包含文件对象 fo
    // 通过 getFileForInput、getFileForOutput、getLocationForModule 
    // 方法获取到的文件对象包含在对应的 location 中
    default boolean contains(
        Location location,
        FileObject fo
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
}
```

- Location 类代表文件对象(file object)的位置。文件管理器使用它来确定文件对象的位置。通常工具可以有文件读取的位置；可以有文件写入的位置。

   - 用于标识读取文件的位置 Location：

      - 如果这些文件可以组织在一个简单的 package/class 层次结构中，那么这样的 Location 就是 package-oriented 的。在 package-oriented 的 location 中，可以使用`JavaFileManager.getJavaFileForInput(javax.tools.JavaFileManager.Location, java.lang.String, javax.tools.JavaFileObject.Kind)`或`JavaFileManager.list(javax.tools.JavaFileManager.Location、java.lang.String、java.util.Set<javax.tools.JavaFileObject.Kind>、boolean)`等方法访问其中的类。
      - 如果文件可以组织在 module/package/class 层次结构中，那么这样的 Location 就是 module-oriented 的。在 module-oriented 的 location 中，直接列出类是不可能的。相反，可以使用` JavaFileManager.getLocationForModule(javax.tools.JavaFileManager.Location, java.lang.String)`或`JavaFileManager.listLocationsForModules(javax.tools.JavaFileManager.Location)`等方法获取 package-oriented 的 location，再根据此 location 获取具体的类。
   
   - 用于标识工具写入文件的 Location 由写入文件的工具指定如何组织这些文件。

- `FileObject getFileForInput​(JavaFileManager.Location location, String packageName, String relativeName) throws IOException` 方法为 input 返回一个文件对象，文件对象代表给定 package-oriented location 中相对名称为 relativeName 的类。注意如果返回的对象表示源码或 class 文件，则它必须是 JavaFileObject 的实例。
   通常此方法返回的文件对象的位置是 位置/包名称/相对名称 的串联。例如，要在 SOURCE_PATH 位置的包 "com.sun.tools.javac" 中找到属性文件 "resources/compiler.properties"，可以这样调用此方法：
   
   ```java
   getFileForInput(
       SOURCE_PATH, 
       "com.sun.tools.javac", 
       "resources/compiler.properties"
   );
   ```

   如果方法的调用是在 Windows 上执行的，并且 SOURCE_PATH 设置成了 "C:\Documents and Settings\UncleBob\src\share\classes"，则方法结果将是表示文件"C:\Documents and Settings\UncleBob\src\share\classes\com\sun\tools\javac\resources\compiler.properties"的文件对象。

ForwardingJavaFileManager 类似于 ForwardingFileObject，其内部持有了 JavaFileManager 的实例，相当于 JavaFileManager 的代理类，并未新增什么方法，文本就不细讲了。

#### StandardJavaFileManager

StandardJavaFileManager 是 JavaFileManager 的子类，其是基于 java.io.File 和 java.nio.file.Path 的文件管理器。获取 StandardJavaFileManager 实例的常用方法是使用 getStandardFileManager：

```java
JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
DiagnosticCollector<JavaFileObject> diagnostics =
    new DiagnosticCollector<JavaFileObject>();
StandardJavaFileManager fm = compiler
    .getStandardFileManager(diagnostics, null, null);
```

StandardJavaFileManager 创建代表常规文件、zip 文件或其他文件类型的文件对象。StandardJavaFileManager 文件管理器返回的任何文件对象遵循以下规范：

- 文件名是完全限定路径(无 ../. 等路径表示)
- 当文件对象代表常规文件时
   
   - FileObject.delete() 方法等价于 File.delete()
   - FileObject.getLastModified() 方法等价于 File.lastModified()
   - 当`new FileInputStream(new File(fileObject.toUri()))
`语句执行成功时，方法`FileObject.getCharContent(boolean)`、`FileObject.openInputStream()`和`FileObject.openReader(boolean)`成功
   - 当`new FileOutputStream(new File(fileObject.toUri()))`语句执行成功时，如果忽略编码问题，则`FileObject.openOutputStream()`和`FileObject.openWriter()`方法成功

- 从 FileObject.toUri() 返回的 URI 对象

   - 有一个 schema(URI.isAbsolute() 方法)
   - 文件名必须是绝对路径(不依赖于当前的工作目录)
   - 如 file:///C:/Documents%20and%20Settings/UncleBob/BobsApp/Test.java、jar:///C:/Documents%20and%20Settings/UncleBob/lib/vendorA.jar!/com/vendora/LibraryClass.class 这样的路径是允许的
   - 如file:BobsApp/Test.java(文件名是相对的，取决于当前目录)、
jar:lib/vendorA.jar!/com/vendora/LibraryClass.class(! 之前的前半部分路径取决于当前目录，而!之后的部分是合法的)、
Test.java(依赖于当前目录，并且没有 schema)、jar:///C:/Documents%20and%20Settings/UncleBob/BobsApp/../lib/vendorA.jar!com/vendora/LibraryClass.class(未转换成绝对路径，存在 ..)这样的路径是不允许的

StandardJavaFileManager 类的定义如下：

```java
public interface StandardJavaFileManager extends JavaFileManager {
    // 继承自父类的方法
    @Override
    boolean isSameFile(FileObject a, FileObject b);
    // 返回代表指定 file 列表的 file object 列表
    Iterable<? extends JavaFileObject> getJavaFileObjectsFromFiles(
        Iterable<? extends File> files
    );
    // 返回代表指定 path 列表的 file object 列表
    default Iterable<? extends JavaFileObject> getJavaFileObjectsFromPaths(
        Iterable<? extends Path> paths
    ) {
        return getJavaFileObjectsFromFiles(asFiles(paths));
    }
    // 返回代表指定 file 列表的 file object 列表
    // 等同于 getJavaFileObjectsFromFiles(Arrays.asList(files))
    Iterable<? extends JavaFileObject> getJavaFileObjects(
        File... files
    );
    // 返回代表指定 path 列表的 file object 列表
    // 等价于 getJavaFileObjectsFromPaths(Arrays.asList(paths))
    default Iterable<? extends JavaFileObject> getJavaFileObjects(
        Path... paths
    ) {
        return getJavaFileObjectsFromPaths(Arrays.asList(paths));
    }
    // 返回代表指定 file name 列表的 file object 列表
    Iterable<? extends JavaFileObject> getJavaFileObjectsFromStrings(
        Iterable<String> names
    );
    // 返回代表指定 file name 列表的 file object 列表
    // 等价于 getJavaFileObjectsFromStrings(Arrays.asList(names))
    Iterable<? extends JavaFileObject> getJavaFileObjects(
        String... names
    );
    // 将给定的 files 代表的搜索路径与给定的 location 相关联，
    // 任何以前的值都将被丢弃
    // 如果 location 是 module-oriented 或者 output location，
    // 则由 setLocationForModule 方法指定的模块的关联将被取消
    void setLocation(
        Location location, 
        Iterable<? extends File> files
    ) throws IOException;
    // java 9 新增方法
    // 作用同 setLocation
    default void setLocationFromPaths(
        Location location, 
        Collection<? extends Path> paths
    ) throws IOException {
        setLocation(location, asFiles(paths));
    }
    // java 9 新增方法
    // 将给定的 files 代表的搜索路径与给定的模块和 location 相关联
    // location 必须是 module-oriented 或者 output location
    // 任何以前的值都将被丢弃
    // setLocation、setLocationFromPaths 与本方法会相互覆盖
    default void setLocationForModule(
        Location location, 
        String moduleName,
        Collection<? extends Path> paths
    ) throws IOException {
        throw new UnsupportedOperationException();
    }
    // 返回与给定 location 关联的搜索路径
    Iterable<? extends File> getLocation(Location location);
    // java 9 新增方法
    // 作用同 getLocation，不过返回类型变成了 Path
    default Iterable<? extends Path> getLocationAsPaths(
        Location location
    ) {
        return asPaths(getLocation(location));
    }
    // java 9 新增方法
    // 返回与 file object 关联的 Path 对象(如果存在)
    default Path asPath(FileObject file) {
        throw new UnsupportedOperationException();
    }
    // java 9 新增接口
    // 从 String 创建 Path 对象的工厂
    interface PathFactory {
        // 根据路径字符串获取 Path 对象
        Path getPath(String first, String... more);
    }
    // java 9 新增方法
    // 指定 PathFactory，如果不调用此方法，
    // java.nio.file.Paths.get(first, more) 方法将调用
    default void setPathFactory(PathFactory f) { }
}
```

可以看出 StandardJavaFileManager 相比于 JavaFileManager，主要是新增了关于 File 和 Path 相关操作的方法。

### Filer

Filer 接口及其实现类支持注解处理器创建新文件。通过 Filer 创建的文件将被实现 Filer 接口的注解处理器工具(APT)所感知，从而使得注解处理器工具能够更好地管理它们。

在用于写入文件内容的 Writer 或 OutputStream 调用了 close 方法后，通过 Filer 创建的文件将由 APT 在下一轮处理中进行处理。APT 主动识别三种文件：源文件(.java/.kt/.groovy 等后缀)、类文件(.class 后缀)和资源文件(resources file)。

有两个受支持的用于放置新创建的文件的位置：一个用于放置新的源码文件，一个用于放置新的 class 文件。位置可以使用命令行指定。新创建的源文件和 class 文件的实际位置可能相同也可能不同。

资源文件可以在任一位置创建。资源的读写方法使用相对名称作为入参。相对名称是不为空的由"/"分隔路径字符串；'.'和 '..' 是无效的路径。有效的相对名称必须符合 RFC 3986 第 3.3 节的 "path-rootless" 规则。

文件创建方法采用可变数量的参数，允许将原始元素(the originating elements)作为提示提供给 APT 框架，以更好地管理依赖性。原始元素是促使 APT 尝试创建新文件的 types、packages(代表 package-info 文件)、modules(代表 module-info 文件)。例如，如果注解处理器尝试创建源文件 GeneratedFromUserSource，以处理下面的代码：

```java
@Generate
public class UserSource {}
```

UserSource 对应的类型元素(type element)应该作为创建文件的方法的调用的一部分，如下所示：

```java
filer.createSourceFile(
    "GeneratedFromUserSource",
    eltUtils.getTypeElement("UserSource")
);
```

如果没有原始元素，则不需要传递任何数据。原始元素的信息可用于增量构建环境中，以确定是否需要重新运行处理器或删除已生成的文件。非增量环境可能会忽略这些信息。

在注解处理工具的每次运行期间，特定路径的文件只被创建一次。如果该文件在首次尝试创建前已经存在，则文件中的旧内容会被删除。在运行期间，任何创建相同文件的后续尝试都会抛出 FilerException，尝试创建具有相同 type 名称或 package 名称的 class 文件和源码文件也是如此。APT 工具认定初始输入(initial inputs)由第零轮创建，因此尝试创建与这些输入对应的源码文件或 class 文件将抛出 FilerException。

使用时应注意，注解处理器不能故意尝试覆盖由其他处理器生成的现有文件。Filer 的实例会拒绝尝试打开对应于现有类型的文件，如 java.lang.Object。同样，注解处理器工具的调用者不得故意配置工具，以此避免搜索发现的处理器尝试覆盖非自己生成的现有文件。

当环境配置为可访问 javax.annotation.Generated 时，注解处理器可以通过包含 javax.annotation.Generated 注解来表示生成源码文件或 class 文件。

另外也应该注意，覆盖文件的相同效果可以通过使用装饰器模式来实现：不是直接修改一个类，而是设计一个类架构，以便通过注解处理器生成其父类或子类。如果生成了子类，则父类可以设计为使用工厂模式获取，而不是提供公共构造函数，以确保只有子类实例可以被使用。

Filer 类的定义如下：

```java
public interface Filer {
    // 创建一个新的源码文件，并返回一个 JavaFileObject 对象
    JavaFileObject createSourceFile(
        CharSequence name,
        Element... originatingElements
    ) throws IOException;
    // 创建一个新的 class 文件，并返回一个 JavaFileObject 对象
    JavaFileObject createClassFile(
        CharSequence name,
        Element... originatingElements
    ) throws IOException;
    // 创建一个新的资源文件，并返回一个 FileObject 对象
    FileObject createResource(
        JavaFileManager.Location location,
        CharSequence moduleAndPkg,
        CharSequence relativeName,
        Element... originatingElements
    ) throws IOException;
    // 获取资源文件，参数限制同 createResource 方法
    FileObject getResource(
        JavaFileManager.Location location,
        CharSequence moduleAndPkg,
        CharSequence relativeName
    ) throws IOException;
}
```

Filer 中定义的方法比较少，各个方法的作用如下：

- `JavaFileObject createSourceFile(CharSequence name, Element... originatingElements) throws IOException;`：该方法使用全限定名创建一个新的源码文件，并返回一个 JavaFileObject 对象，以方便开发者对文件进行读写操作。originatingElements 代表与此文件的创建有因果关系的类型(type)、包或模块元素，可以被省略或为空

   - 可以创建 type 或者 package 的源文件，文件的名称和路径(相对于源文件的根输出位置)基于在该文件中声明的名称、包名以及指定的模块(如果存在)。如果在单个文件(即单个编译单元)中声明了多个类型(即多个类)，则文件的名称应与主要顶级类型的名称相对应(即一个 java 文件中必须要一个顶级类)

   - 可以创建源文件来保存有关包的信息，包括包的注解
      - 要为有命名的包创建源文件，文件名称为包的名称后跟".package-info"
      - 要为未命名的包创建源文件，文件名称为 "package-info"

   可选模块的名称以类型名称或包名称为前缀，并使用 "/" 字符分隔。例如，要在模块 foo 中创建类型 a.B 的源文件，则文件名称未 "foo/a.B"。

   如果没有明确的模块前缀并且环境支持模块，则工具会推断合适的模块。如果无法推断出合适的模块，则会抛出 FilerException 异常。Filer 的实现可以使用 APT 工具的配置信息，作为推断的一部分。

   注意不支持在未命名包中创建源文件，不支持在已命名的模块中为未命名的包创建源文件。

   注意如果要使用特定的字符集对文件内容进行编码，则可以使用根据文件对象的 OutputStream 创建具有指定字符集的 OutputStreamWriter。字符集不指定时通常是平台的默认编码

   不支持在未命名包中创建源码文件，也不支持为命名模块中的未命名包创建文件。

- `JavaFileObject createClassFile​(CharSequence name, Element... originatingElements) throws IOException`：该方法的作用和限制与 createSourceFile 方法类似，只是从创建源文件变成了创建了 class 文件

- `FileObject createResource​(JavaFileManager.Location location, CharSequence moduleAndPkg, CharSequence relativeName, Element... originatingElements) throws IOException`：创建一个新的辅助资源文件，并返回一个 FileObject 对象。该文件可能与新创建的源码、二进制文件放在一起，也可能放在其他受支持的位置，但是必须支持源码文件的位置(StandardLocation.SOURCE_OUTPUT)、二进制文件的位置(StandardLocation.CLASS_OUTPUT)。资源可能如源文件和 class 文件一样，会根据模块和包通过相对路径名命名。从广义上讲，新文件的完整路径名将是 location、moduleAndPkg 和 relativeName 的串联。

   - 如果 moduleAndPkg 包含"/"字符，则"/"字符前的前缀是模块名，"/"字符后的后缀是包名。包后缀可以为空。
   - 如果 moduleAndPkg 不包含"/"字符，则整个参数将被解释为包名称
   
   注意使用此方法创建的文件默认不会被注解处理器处理

### Elements & Types & SourceVersion

这几个类涉及到 java 语言的建模，本文就不重复讲解了，感兴趣的可以看上一篇文章：[javax.lang.model 包介绍](https://www.cnblogs.com/wellcherish/p/17147811.html)

# RoundEnvironment 接口

Processor 的 process 方法被调用时，APT 框架会提供一个 RoundEnvironment 类型的数据。以便注解处理器可以查询有关一轮中注解处理有关的信息。

RoundEnvironment 类的定义如下：

```java
public interface RoundEnvironment {
    // 如果本轮生成的数据类型(types)将后续轮此不再处理
    // 则返回 true；否则返回 false
    boolean processingOver();
    // 前一轮处理中出现错误则返回 true；否则返回 false。
    boolean errorRaised();
    // 返回上一轮注解处理生成的根元素。
    Set<? extends Element> getRootElements();
    // 返回使用给定注解类型注解的元素
    // 注解可能是直接使用的，也可能被继承的
    // 详细解释见下文
    Set<? extends Element> getElementsAnnotatedWith(TypeElement a);
    // 返回使用 annotations 中一种或多种注解类型注解的元素
    default Set<? extends Element> getElementsAnnotatedWithAny(
        TypeElement... annotations
    ){
        // 代码实现未省略
        Set<Element> result = new LinkedHashSet<>();
        for (TypeElement annotation : annotations) {
            result.addAll(getElementsAnnotatedWith(annotation));
        }
        return Collections.unmodifiableSet(result);
    }
    // 方法含义和限制同另一个同名函数，只不过入参不一样
    Set<? extends Element> getElementsAnnotatedWith(
        Class<? extends Annotation> a
    );
    // 方法含义和限制同另一个同名函数，只不过入参不一样
    default Set<? extends Element> getElementsAnnotatedWithAny(
        Set<Class<? extends Annotation>> annotations
    ){
        // 代码实现未省略
        Set<Element> result = new LinkedHashSet<>();
        for (Class<? extends Annotation> annotation : annotations) {
            result.addAll(getElementsAnnotatedWith(annotation));
        }
        return Collections.unmodifiableSet(result);
    }
}
```

- `Set<? extends Element> getElementsAnnotatedWith(TypeElement a)` 方法返回使用给定注释类型注释的元素。注解可能直接出现，也可能被继承。

   - 仅返回本轮注解处理中包含的包元素、模块元素和类型(type)元素，或其中使用注解的成员、构造函数、参数或泛型参数的元素
   - 类型元素包含的是顶级类型和嵌套在其中的任何成员类型(top-level class 和 member class)
   - 包内的元素不包含在内，因为为 package 创建了 package-info 文件
   - 模块内的元素不包含在内，因为为 module 创建了 module-info 文件

RoundEnvironment 类的定义比较简单，此处就不再多讲了。

## 总结

支持，注解处理器涉及到的相关类的知识点，我们就讲完了。后续该进入实战了。