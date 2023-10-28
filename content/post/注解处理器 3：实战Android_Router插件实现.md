---
title: "注解处理器 3：实战 Android Router 插件实现"
description: "本文讲解了如何使用 java 注解处理器在 Android 中实现 Router 路由插件"
keywords: "Android,Java,注解处理器,Gradle Plugin,路由框架"

date: 2023-03-13 18:23:00 +08:00

categories:
  - Android
  - 注解处理器
tags:
  - Android
  - Java
  - 注解处理器
  - Gradle Plugin
  - 路由框架

url: post/A85ED138561142DBBFA335CE35A4289B.html
toc: true
---

本文讲解了如何使用 java 注解处理器在 Android 中实现 Router 路由插件。

<!--More-->

前篇文档：[注解处理器 1：javax.lang.model 包讲解](A90F3472990141F8B69A6EC73420C0D2.html)

前篇文档：[注解处理器 2：java 注解处理器](04B5C92A04564560A1143F299EA9A57A.html)

Gradle 关联文章：[Gradle 功能介绍](1C0A0A86D7BE46A293A2791409052978.html)

组件化介绍文章：[Android 组件化](071DE5F05689474694D8A705245B423E.html)

本文的 Demo 地址：[Github 指路](https://github.com/xWenChen/WellMedia)

## 概览

本文主要讲解如何使用注解处理器实现路由插件，涉及到 Gradle Plugin 开发、注解处理器(apt/kapt)、java 源代码的生成、组件化等知识。使用 kotlin 语言实现。

注解处理器的相关知识讲解，大家可以阅读我写的前两篇介绍文章。

## 知识背景

在 Android 的日常开发中，根据字符串跳转特定界面是很重要且常见的功能。此时这种字符串可以叫做路由，目标页面可以是本地页面、网页、Flutter 页面等。而根据路由跳转页面的框架，我们一般称为路由框架。

一般路由框架中的路由主要包含 3 大部分：协议、路径、参数。这 3 部分内容怎么定义，由应用内部自己决定，框架只需要定义好格式就行了。本文不介绍如何制定路由内容，而是会着重介绍路由框架如何实现。

本文以一款 比较流行的路由框架 [chenenyu/Router](https://github.com/chenenyu/Router) 为例，说明下一款路由框架是如何实现的。下面是简单用法。


```kotlin
// 定义
// 1. 定义路由
@Route("main_app")
class MainActivity : BaseActivity() {
    // 2. 参数注入
    @InjectParam(key = "main_param_name")
    var name: String? = null

    @InjectParam(key = "main_param_age")
    var age: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 2. 参数注入
        Router.injectParams(this)
    }
}

// 使用
fun start(activity: Activity) {
    // 1. build 构建路由
    // 2. with 填入参数
    // 3. go 跳转页面
    Router.build("main_app")
        .with("main_param_name", "Bob")
        .with("main_param_age", 18)
        .go(activity)
}
```

可以看出，路由框架的实现分为定义路由和使用路由两部分。这两部分主要都是涉及到 路由映射 和 参数注入 两步。他们的实现方式如下表：

<table>
   <tr>
      <td></td>
      <th style="text-align: center;">　　路由映射　　</th>
      <th style="text-align: center;">　　参数注入　　</th>
   </tr>
   <tr style="text-align: center;">
      <th>　　定义路由　　</th>
      <td>　　@Route 注解　　</td>
      <td>　　@InjectParam 注解　　</td>
   </tr>
   <tr style="text-align: center;">
      <th>　　使用路由　　</th>
      <td>　　Router.build　　</td>
      <td>　　Router.with　　</td>
   </tr>
   <tr style="text-align: center;">
      <th>　　页面跳转　　</th>
      <td colspan="2">　　Router.go　　</td>
   </tr>
</table>

上面表格中的主要技术点，本文会一一讲解。

## 路由注解

上面我们用到了 @Route 和 @InjectParam 两种注解，两者的实现原理一致。本文以 @Route 为例，说明下如何实现并解析一个自定义注解，@InjectParam 就不再重复讲解了，感兴趣的小伙伴可以阅读 [chenenyu/Router](https://github.com/chenenyu/Router) 路由框架的源码进行了解。

### 代码拆分

一个优秀的 Android 项目，应当是需要组件化的。对于本文介绍的路由插件的实现，也会使用组件化，本文会将注解的定义、注解的实现、注解的参数注入、注解的使用等步骤分到不同的组件，实现代码隔离。组件架构如图：

![组件架构](/imgs/组件架构.png)

- annotation 组件中存放的是我们自定义的路由组件和相关的工具类
- processor 组件中存放的是用于解析注解的路由注解处理器，依赖于 annotation 组件
- buildSrc 中存放的是我们自定义的路由插件，该插件会向注解处理器注入参数。buildSrc 不是 Gradle 中标准的 module，但是它会被 Gradle 识别并编译。在 Gradle 的介绍文章中，我们提过，如果 Gradle 插件是以本地源码形式导入本地项目，则应该使用 buildSrc 目录承载。
- app 是应用的主模块，负责使用路由注解

划分好了组件后，在实现注解处理器之前，我们需要先明确我们想要达到的最终效果。

一般的路由框架允许我们通过字符串跳转某个页面，是因为框架内部已经做了字符串到 Activity/Fragment 的转换。在框架内部，通常都维护着一个键值对映射表。即 Map 类。

我们的处理器最终目标也是要生成这样一个包含着"路由-页面"映射表的类，最好是单例类，这样数据在 app 运行期间都可以使用。

但是问题来了，如何向映射表里添加映射信息呢？开发时我们并不知道有多少路由信息需要添加。最好的时机就是运行期间添加内容到映射表里，因为此时不会再有新的路由信息生成。那么此时我们就需要在启动时向映射表里添加映射信息。启动时的最好时机就是在 application 中。所以此时我们需要额外的两个类：负责 application 中的初始化工作的类、已经负责向映射表塞数据的类。

按照以上思路，涉及到的类如下：

1. Route 注解：路由与页面的纽带
2. RouteHub：路由与页面的映射表存储类
3. RouteRegister：路由与页面的注册类，负责向 RouteHub 塞数据
4. RouteInitializer：启动时初始化
5. Router：负责根据路由跳转
6. RouteProcessor：负责解析路由信息
7. RoutePlugin:：负责编译时向 RouteProcessor 传递参数，用于生成 RouteRegister 具体的子类

最终，我们的实现逻辑如下：

1. 用户使用 Route 注解关联页面与路由
2. RoutePlugin 中向注解处理器传参，用于生成 RouteRegister 的子类
3. RouteProcessor 解析 RoutePlugin 的传参和所有 Route 注解，将信息写入 RouteRegister 的子类
4. 启动时在 RouteInitializer 中将 RouteRegister 的数据写入 RouteHub 中
5. Router 根据 RouteHub 中的信息，向用户提供简易的跳转方式

![Router流程](/imgs/Router流程.png)

最后我们来看看相关代码如何实现。

### 1. 定义注解

Route 注解的实现非常简单，在 annotation 组件中，我们定义路由注解。注解的相关知识可以参考这篇文章：[Android 注解](https://www.cnblogs.com/wellcherish/p/12228772.html)。

```kotlin
/**
 * 指定页面路由。
 * 
 * 单值注解在指定值时可以省略变量名
 *
 * @param url 页面的路由地址
 * */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class Route(val url: String = "")
```

### 2. 解析注解

要解析 Route 注解，我们需要用到注解处理器。注解处理器的使用分为使注解处理器生效、注册注解处理器和实现注解处理器几大部分。

#### 1. 注解处理器组件配置

在 kotlin 语言中，注解处理器工具叫做 kapt(kotlin annotation processor tool)。默认情况下，kapt 是不会生效的，我们需要在 processor 组件的 build.gradle 文件中做如下配置：

```java
plugins {
    id 'java-library'
    id 'org.jetbrains.kotlin.jvm'
    id 'kotlin-kapt' // 引入插件，使 kapt 生效
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

dependencies {
   // 依赖于 annotation 组件，方便我们使用 Route 注解
   implementation project(":annotation")
   // 导入依赖，方便开发
   implementation "org.jetbrains.kotlin:kotlin-reflect:1.5.30"
   implementation "org.jetbrains.kotlin:kotlin-stdlib:1.5.30"
   // 使 auto-service 依赖在注解处理器中生效
   kapt "com.google.auto.service:auto-service:1.0.1"
   implementation "com.google.auto.service:auto-service-annotations:1.0.1"
   implementation 'com.squareup:kotlinpoet:1.11.0'
}
```

我们引入了 `java-library`、`org.jetbrains.kotlin.jvm`、`kotlin-kapt` 三个插件，前两个都是为了方便我们写代码。真正核心的第 3 个 kotlin-kapt 插件，不引入该插件，`kapt "com.google.auto.service:auto-service:1.0.1"`语句就会编译报错。

- `kapt "com.google.auto.service:auto-service:1.0.1"`语句与注解处理器的注册有关。主要作用是保证谷歌的 auto-service 框架可以在注解处理器生效期间执行，方便生成注册注解处理器的文件与代码。
- `implementation "com.google.auto.service:auto-service-annotations:1.0.1"`语句与注解处理器的注册有关。方便我们在自定义的注解处理器中使用 auto-service 框架提供的注解。
- `implementation 'com.squareup:kotlinpoet:1.11.0'`语句主要是引入 kotlin poet 依赖，java poet 是 square 公司开源的 java 文件生成框架，kotlin poet 是 java poet 的 kotlin 版本，用于生成 kotlin 源码和 kotlin 文件。项目地址见：[kotlin poet](https://github.com/square/kotlinpoet)

#### 2. 注册注解处理器

在未引入 auto-service 框架之前，注解处理器的注册是比较麻烦的。我们需要使用 java 的 SPI 机制(Service Provider Interface) 进行注册，自己维护文件和文件内容。在引入 auto-service 之后，我们只需要使用注解即可，文件和文件内容的生成，都交由 auto-service 框架进行处理。

在 RouteProcessor 文件中，我们使用`@AutoService(Processor::class)`就可以把 RouteProcessor 注册好。

```kotlin
@AutoService(Processor::class)
class RouteProcessor : AbstractProcessor() {}
```

运行代码以后，框架会在 ProjectDir/processor/build/tmp/kapt3/classes/main/META-INF/services 目录下自动生成 javax.annotation.processing.Processor 文件，并填入 RouteProcessor，如图：

![注册注解处理器](/imgs/注册注解处理器.png)

#### 3. 实现注解处理器

按照上面对于路由注解处理器相关类的说明，路由解析的实现逻辑如下：

1. 我们支持解析 Route 注解
   
   ```kotlin
   @AutoService(Processor::class)
   class RouteProcessor : AbstractProcessor() {
       override fun getSupportedAnnotationTypes(

       ): MutableSet<String> {
           return mutableSetOf(Route::class.java.canonicalName)
       }
   }
   ```

2. 我们需要解析生成的 RouteRegister 的子类，此操作可通过解析对应的 moduleName 参数实现。比如 moduleName 是 app，则最终生成的类就是 AppRouteRegister。

   ```kotlin
   @AutoService(Processor::class)
   class RouteProcessor : AbstractProcessor() {
       object Constants {
           const val OPTION_MODULE_NAME = "moduleName"
           const val DEFAULT_MODULE_NAME = "Default"
       }

       // moduleName 代表我们生成的 RouteRegister 的子类的前缀
       private var moduleName = Constants.DEFAULT_MODULE_NAME

       // 支持解析的参数是 moduleName
       override fun getSupportedOptions(): MutableSet<String> {
           return mutableSetOf(Constants.OPTION_MODULE_NAME)
       }

       // 初始化时，读取 OPTION_MODULE_NAME 参数
       override fun init(
          processingEnv: ProcessingEnvironment?
       ) {
           super.init(processingEnv)

           moduleName = Utils.parseModuleName(
               processingEnv?.options?.get(
                  Constants.OPTION_MODULE_NAME
               )
           )
       }
   }
   ```

3. 拿到被 Route 注解的元素，通常是 Activity 或者 Fragment，我们需要检查一下

   ```kotlin
   object Constants {
       const val ACTIVITY_FULL_NAME = "android.app.Activity"
       const val FRAGMENT_FULL_NAME = "android.app.Fragment"
       const val FRAGMENT_X_FULL_NAME = "androidx.fragment.app.Fragment"
   }
   override fun process(
       annotations: MutableSet<out TypeElement>?, 
       roundEnv: RoundEnvironment?
   ): Boolean {
       val elements = roundEnv?.getElementsAnnotatedWith(
           Route::class.java
       )

       if (moduleName.isEmpty() || elements.isNullOrEmpty()) {
           // 我们自定义的注解处理器不再执行
           return true
       }

       // 合法的 TypeElement 集合
       val typeElements = elements.filter {
           it.kind.isClass && validateRoute(it)
       }.map {
           it as TypeElement
       }

       return true
   }
   
   // 检查 @Route 注解是否 OK
   private fun validateRoute(element: Element?): Boolean {
       // 不是 android 或者 androidx 中
       // 定义的 activity 和 fragment 的子类
       if (!isSubtype(element, Constants.ACTIVITY_FULL_NAME)
           && !isSubtype(element, Constants.FRAGMENT_FULL_NAME)
           && !isSubtype(element, Constants.FRAGMENT_X_FULL_NAME)
       ) {
           return false
       }
       // 如果是抽象类，也不 OK
       if (Modifier.ABSTRACT in (element?.modifiers ?: emptySet())) {
           return false
       }

       return true
   }
   
   // 检查 typeElement 是否是 type 的子类
   private fun isSubtype(
       typeElement: Element?, 
       type: String
   ): Boolean {
       return processingEnv?.run {
           // Types.isSubtype 方法
           typeUtils.isSubtype(
               typeElement?.asType(),
               elementUtils.getTypeElement(type).asType()
           )
       } ?: false
   }
   ```

4. 拿到被 Route 注解的元素后，我们就可以来生成代码了。生成代码，我们用到了 [kotlin poet](https://github.com/square/kotlinpoet)
   
   ```kotlin
   @AutoService(Processor::class)
   class RouteProcessor : AbstractProcessor() {
       override fun process(
           annotations: MutableSet<out TypeElement>?, 
           roundEnv: RoundEnvironment?
       ): Boolean {
           generateRouteTable(typeElements)

           return true
       }
   }
   ```

   generateRouteTable 方法流程如下：

   1. 生成`Map<String, String>`参数
      - 获取类型
      - 生成变量

      ```kotlin
      private fun generateRouteTable(
          typeElements: List<TypeElement>
      ) {
          // 生成方法的参数类型：Map<String, String>
          val mapTypeName = HashMap::class
              .asClassName()
              .parameterizedBy(
                  String::class.asClassName(),
                  String::class.asClassName()
                  /*KClass::class.asClassName().parameterizedBy(
                  WildcardTypeName.producerOf(Any::class)
                  )*/ // 生成方法的参数类型：Map<String, KClass<*>>
              )

          // 生成 map 参数
          val mapParamSpec = ParameterSpec
              .builder("map", mapTypeName)
              .build()
      }
      ```

   2. 生成`override public fun register(map: Map<String, KClass<*>>)`方法
      
      ```kotlin
      private fun generateRouteTable(
          typeElements: List<TypeElement>
      ) {
          // map 参数添加到 register 方法中
          // override public fun register(
          //     map: Map<String, 
          //     KClass<*>>
          // )
          val funcRegister = FunSpec
              .builder(Constants.METHOD_REGISTER)
              .addModifiers(KModifier.OVERRIDE)
              .addModifiers(KModifier.PUBLIC)
              .addParameter(mapParamSpec)
              .returns(UNIT)
      }
      ```

   3. 根据注解生成方法体
      - 根据元素的 Route 注解拿到路由 url
      - 根据 TypeElement 获取到页面的 canonicalName
      - 将路由和页面塞入 map 中，写到 register 方法体里

      ```kotlin
      private fun generateRouteTable(
          typeElements: List<TypeElement>
      ) {
          // 根据注解生成方法体
          // qualifiedName 全限定名
          typeElements.forEach {
              val route = it.getAnnotation(Route::class.java)
              val path = route.url
              funcRegister.addStatement(
                  "map[%S] = %S", 
                  path, 
                  it.asClassName().canonicalName
              )
              pathRecorder[path] = it.qualifiedName.toString()
          }
      }
      ```

   4. 方法体生成完毕后，生成类文件
      - RouteRegister 接口定义如下：

         ```kotlin
         interface RouteRegister {
             // 注册路由，代码自动生成
             fun register(map: HashMap<String, String>)
         }
         ```

      - 使用首先拿到 RouteRegister 接口类型：

         ```kotlin
         // Elements.getTypeElement 方法，传入类的全限定名
         processingEnv?.elementUtils?.getTypeElement(
             Constants.ROUTE_REGISTER_INTERFACE_NAME
         )?.let { superInterfaceType ->
             // 具体代码见下面
         }
         ```
      
      - 根据 RouteRegister 类型生成其子类：

         ```kotlin
         // 生成带类注释的 AppRouteRegister 子类，App 是模块名
         /**
          * Generated by Route annotation Processor. Do not edit it!
          */
         // public class AppRouteRegister : RouteRegister {
         TypeSpec
             .classBuilder(
                 // 根据模块生成子类名
                 // 当模块是 app 时，返回 AppRouteRegister
                 Utils.getRegisterClassName(moduleName)
             )
             // RouteRegister 是其父类
             .addSuperinterface(superInterfaceType.asClassName())
             // 添加 public 修饰符
             .addModifiers(KModifier.PUBLIC)
             // 加入 register 方法
             .addFunction(funcRegister.build())
             .addKdoc(Constants.CLASS_DOC)
             .build()
         ```

      - 最后，将生成好的类写入文件中：

         ```kotlin
         // 类写入文件
         // 文件路径是包名
         processingEnv?.filer?.apply {
             FileSpec.get(
                 Constants.GENERATED_ROUTE_REGISTER_PATH,
                 type
             ).writeTo(this)
         }
         ```

   最后，将上述代码整合，RouteProcessor 的实现如下：

   ```kotlin
   @AutoService(Processor::class)
   class RouteProcessor : AbstractProcessor() {

       private var moduleName = Constants.DEFAULT_MODULE_NAME

       override fun getSupportedAnnotationTypes(
           
       ): MutableSet<String> {
           return mutableSetOf(Route::class.java.canonicalName)
       }

       override fun getSupportedOptions(): MutableSet<String> {
           return mutableSetOf(Constants.OPTION_MODULE_NAME)
       }

       override fun getSupportedSourceVersion(): SourceVersion {
           return SourceVersion.latestSupported()
       }

       override fun init(processingEnv: ProcessingEnvironment?) {
           super.init(processingEnv)

           moduleName = Utils.parseModuleName(
               processingEnv?.options?.get(
                   Constants.OPTION_MODULE_NAME
               )
           )
       }

       override fun process(
           annotations: MutableSet<out TypeElement>?, 
           roundEnv: RoundEnvironment?
       ): Boolean {

           val elements = roundEnv?.getElementsAnnotatedWith(
               Route::class.java
           )

           if (moduleName.isEmpty() || elements.isNullOrEmpty()) {
               // 我们自定义的注解处理器不再执行
               return true
           }

           // 合法的TypeElement集合
           val typeElements = elements.filter {
               it.kind.isClass && validateRoute(it)
           }.map {
               it as TypeElement
           }

           generateRouteTable(typeElements)

           return true
       }

       private fun generateRouteTable(
           typeElements: List<TypeElement>
       ) {
           // 生成方法的参数类型：Map<String, KClass<*>>
           // 生成方法的参数类型：Map<String, String>
           val mapTypeName = HashMap::class
               .asClassName()
               .parameterizedBy(
                   String::class.asClassName(),
                   String::class.asClassName()
                   /*KClass::class.asClassName().parameterizedBy(
                       WildcardTypeName.producerOf(Any::class)
                   )*/
               )

           // 生成 map 参数
           val mapParamSpec = ParameterSpec
           .builder("map", mapTypeName)
           .build()

           // map 参数添加到 register 方法中
           // override public fun register(
           //     map: Map<String,
           //     KClass<*>>
           // )
           val funcRegister = FunSpec
               .builder(Constants.METHOD_REGISTER)
               .addModifiers(KModifier.OVERRIDE)
               .addModifiers(KModifier.PUBLIC)
               .addParameter(mapParamSpec)
               .returns(UNIT)

           // 根据注解生成方法体
           // qualifiedName 全限定名
           typeElements.forEach {
               val route = it.getAnnotation(Route::class.java)
               val path = route.url

               funcRegister.addStatement(
                   "map[%S] = %S", 
                   path, 
                   it.asClassName().canonicalName
               )
           }

           // 方法内容添加到类中
           processingEnv?.elementUtils?.getTypeElement(
               Constants.ROUTE_REGISTER_INTERFACE_NAME
           )?.let { superInterfaceType ->
               TypeSpec
                   .classBuilder(
                       Utils.getRegisterClassName(moduleName)
                   )
                   .addSuperinterface(
                       superInterfaceType.asClassName()
                   )
                   .addModifiers(KModifier.PUBLIC)
                   .addFunction(funcRegister.build())
                   .addKdoc(Constants.CLASS_DOC)
                   .build()
           }?.also { type ->
               try {
                   // 类写入文件
                   processingEnv?.filer?.apply {
                       FileSpec.get(
                           Constants.GENERATED_ROUTE_REGISTER_PATH,
                           type
                       ).writeTo(this)
                   }
               } catch (e: Exception) {
                   e.printStackTrace()
               }
           }
       }   

       // 检查 @Route 注解是否 OK
       private fun validateRoute(element: Element?): Boolean {
           if (!isSubtype(element, Constants.ACTIVITY_FULL_NAME)
               && !isSubtype(element, Constants.FRAGMENT_FULL_NAME)
               && !isSubtype(element, Constants.FRAGMENT_X_FULL_NAME)
           ) {
               return false
           }

           if (Modifier.ABSTRACT in (element?.modifiers ?: emptySet())) {
               return false
           }

           return true
       }

       private fun isSubtype(
           typeElement: Element?, 
           type: String
       ): Boolean {
           return processingEnv?.run {
               typeUtils.isSubtype(
                   typeElement?.asType(),
                   elementUtils.getTypeElement(type).asType()
               )
           } ?: false
       }
   }
   ```

假如我们根据 app 模块名在 com.mustly.wellmedia.lib.commonlib.route.generated 下生成了 AppRouteRegister 类，则其效果像这样：

![生成的AppRouteRegister类](/imgs/生成的AppRouteRegister类.png)

#### 4. 编译时参数注入

在 RouteProcessor 的解析过程中，我们解析了 moduleName 的参数，我们会根据这个参数生成 RouteRegister 的子类，比如当 moduleName 是 app 的时候，生成 RouteRegister 子类名就是 AppRouteRegister。然后在启动时，我们会构建 AppRouteRegister 的实例，调用 register 方法，向 RouteHub 中注入路由信息。

根据以上流程，我们可以知道对 moduleName 这个参数的需求，涉及编译时注解编译器和运行时初始化两个地方。对于这两个地方的参数注入，我们分开讲解。

##### 1. 用于编译时注解处理

编译时 RouteProcessor 注解编译器的参数注入，可以在编译前使用 javaCompileOptions.annotationProcessorOptions 作为注解处理器的编译选项传入，此代码可以写入到 RoutePlugin 中，注入后，moduleName 参数就可以被 RouteProcessor 解析到了。如下：

```kotlin
// build.gradle 中

class RoutePlugin : Plugin<Project> {
    // 其他代码省略
    val android: BaseExtension = project.extensions
        .getByName("android") as BaseExtension

    val options = mutableMapOf("moduleName" to project.name)

    // 为注解添加选项
    android.defaultConfig.javaCompileOptions
        .annotationProcessorOptions
        .arguments(options)
    android.productFlavors.forEach {
        it.javaCompileOptions
            .annotationProcessorOptions
            .arguments(options)
    }
}
```

##### 2. 用于运行时初始化

我们传的编译时的选项在 app 运行期间肯定是无法使用的。运行时我们需要使用其他方法获取对应的 moduleName。方法有很多种。比如读取特定的文件、BuildConfig 等等。本文采用的是读取 AndroidManifest.xml 文件中的配置。

###### AndroidManifest 清单文件

[AndroidManifest.xml](https://developer.android.com/guide/topics/manifest/manifest-intro?hl=zh-cn) 官方解释是应用清单，每个应用的根目录中都必须包含一个，并且文件名必须一模一样。这个文件中包含了 APP 的配置信息，系统需要根据里面的内容运行 APP 的代码，显示界面。

AndroidManifest.xml 是个典型的 xml 文件，首先看下 AndroidManifest.xml 文件的内容结构，Android 中一个常见的 AndroidManifest.xml 文件如下：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.aaa.bbb.ccc">

    <uses-permission android:name="android.permission.INTERNET" />

    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />
    <application
        android:name=".CustomApplication"
        android:icon="@drawable/ic_app_icon"
        android:label="@string/app_name"
        android:roundIcon="@drawable/ic_app_icon"
        android:supportsRtl="true"
        android:theme="@style/Theme.Custom">
        <activity
            android:name=".base.BaseActivity"
            android:exported="false" />
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Custom.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

可以看出，AndroidManifest.xml 包含 manifest ---> application ---> activity ---> intent-filter 等结构，并且具有清晰的层次结构，按照这种层次划分。我们可以按照解析 xml 文件的方式解析 AndroidManifest，并向其中插入数据。

我们自己插入的数据可以存放在 AndroidManifest 的 [meta-data](https://developer.android.com/guide/topics/manifest/meta-data-element?hl=zh-cn) 中。

###### Manifest中的\<meta-data>

\<meta-data> 是一个键值对，其语法如下：

```xml
<meta-data 
    android:name="string" 
    android:resource="resource specification"
    android:value="string" />
```

- android:name：该项的唯一名称。若要确保此名称具有唯一性，应使用 Java 样式的命名惯例，例如 "com.example.project.activity.fred"
- android:resource：对资源的引用。资源的 ID 是分配给该项的值。可以通过 Bundle.getInt() 方法从元数据 Bundle 中检索 ID
- android:value：分配给该项的值

\<meta-data> 可存在于\<activity>、\<activity-alias>、\<application>、\<provider>、\<receiver>、\<service> 等键值对内

\<meta-data> 可以向父组件提供的其他任意数据项的键值对。一个组件元素可以包含任意数量的 \<meta-data> 子元素。所有这些子元素的值最终会收集到一个 Bundle 对象，并且可作为 PackageItemInfo.metaData 字段提供给组件。

我们可以通过 value 属性指定值。不过，要将资源 ID 指定为值，要使用 resource 属性。例如，以下代码会将 @string/kangaroo 资源中存储的任何值分配给 zoo 名称：

```xml
<meta-data android:name="zoo" android:value="@string/kangaroo" />
```

而使用 resource 属性会为 zoo 分配资源的数字 ID，而不是资源中存储的值：

```xml
<meta-data android:name="zoo" android:resource="@string/kangaroo" />
```

现在，我们可以向 \<application> 元素中添加一个 \<meta-data>，形如下面的代码：

```xml
<application 
    android:name="com.mustly.wellmedia.MediaApplication" 
    android:icon="@drawable/ic_app_icon" 
    android:label="@string/app_name" 
    android:roundIcon="@drawable/ic_app_icon" >
    <!-- 其他代码省略 -->
    <meta-data 
        android:name="com.mustly.wellmedia.lib.commonlib.route.moduleName"             
        android:value="app"
    />
</application>
```

现在，我们需要考虑一个事情。meta-data 中的 name 字段是唯一的。在项目只有一个 module 时，上面的代码不会出现问题；但是当项目组件化后，有了多个 module，上面的代码可能就会出现问题了。因为 name 是唯一的。那么读取了 name 对应的值后，其他模块又传了相同的数据，数据肯定会被覆盖，不符合我们的预期。那应该怎么处理呢？其实我们可以把 name 和 value 的互换下，value 唯一，name 不一样，那么 name 就可以随便传了。我们只需要根据 value 判断即可。所以我们最终想要的效果如下：

```xml
<application 
    android:name="com.mustly.wellmedia.MediaApplication" 
    android:icon="@drawable/ic_app_icon" 
    android:label="@string/app_name" 
    android:roundIcon="@drawable/ic_app_icon" >
    <!-- 其他代码省略 -->
    <!-- name 和 value 的值互换 -->
    <meta-data 
        android:name="app"             
        android:value="com.mustly.wellmedia.lib.commonlib.route.moduleName"
    />
</application>
```

###### 数据写入 AndroidManifest

现在明白了我们想要的效果后，就可以写入数据了。我们需要解析 xml、塞入数据。解析 xml，我们使用的是 dom4j 框架，这个框架本文就不细讲了，感兴趣的可以看下[官网介绍](https://dom4j.github.io/)。塞入数据我们采用的是自定义 gradle task，并将其与 RoutePlugin 中关联起来。代码如下：

```groovy
// 导入依赖
// implementation APG 的依赖，方便编写插件时查看源码
implementation "com.android.tools.build:gradle:7.2.0"
implementation 'com.android.tools:common:30.2.1'
implementation "org.jetbrains.kotlin:kotlin-gradle-plugin:1.5.30"
implementation "org.jetbrains.kotlin:kotlin-stdlib:1.5.30"
implementation 'dom4j:dom4j:1.6.1'
implementation 'com.android.tools:repository:30.2.1'
```

```kotlin
// 定义 Manifest 编辑任务，然后将任务添加到路由插件中
abstract class ManifestTransformerTask : DefaultTask() {
    @get:InputFile abstract val srcManifest: RegularFileProperty
    @get:OutputFile abstract val updatedManifest: RegularFileProperty

    // 该 task 要做的事
    @TaskAction
    fun taskAction() {
        // 输入与输出
        val input = srcManifest.get().asFile
        val output = updatedManifest.get().asFile

        // 解析输入的 AndroidManifest.xml
        val document = SAXReader().read(input)

        // application 节点下添加 meta-data 元素，并向元素添加对应属性
        document.findFirstAppNode()?.addElement("meta-data")?.apply {
            addAttribute("android:name", project.name)
            addAttribute(
                "android:value", 
                "com.mustly.wellmedia.lib.commonlib.route.moduleName"
            )
        }

        // 修改后的 xml 内容，写入文件
        XMLWriter(
            FileOutputStream(output), 
            OutputFormat.createPrettyPrint().apply {
                encoding = "UTF-8"
                setIndentSize(4)
                isTrimText = false
            }
        ).apply {
            write(document)
            close()
        }
    }

    private fun Document.findFirstAppNode(): Element? {
        // 返回 application 节点
        return rootElement.element("application")
    }
}
```

添加节点的代码很简单，就不细讲了，关键的说明都有注释。现在来说明下如何把 Gradle task 和 plugin 关联起来。关联操作涉及到 APG 相关知识的运用，感兴趣的可以阅读官方文档：[扩展 Android Gradle Plugin](https://developer.android.com/studio/build/extend-agp?hl=zh-cn)

首先，我们需要获取 APG 定义的 components。

```kotlin
// com.android.build.api.extension.AndroidComponentsExtension
val androidComponents = project.extensions.getByName("androidComponents") 
    as AndroidComponentsExtension<*, *, *>
// 为 components 的每个 variant 注册任务
androidComponents.onVariants { variant -> // com.android.build.api.variant.Variant
    // 
    registerAndBindTask(project, variant)
}
```

注册任务的代码如下，代码是 android 官方示例代码实现的：

```kotlin
private fun registerAndBindTask(project: Project, variant: Variant) {
    // 首先创建任务
    val taskProvider = project.tasks.register(
        "process${variant.name.localCapitalize()}RouteManifest",
        ManifestTransformerTask::class.java
    )
    // 将任务和具体的产入产出挂钩，方便转换
    variant.artifacts
        // 指定任务
        .use(taskProvider)
        // 绑定输入输出与 artifacts 的产出挂钩
        .wiredWithFiles(
            ManifestTransformerTask::srcManifest,
            ManifestTransformerTask::updatedManifest
        )
        // 绑定 artifacts 的产出，处理 artifacts 中合并过后的 manifest 文件
        .toTransform(SingleArtifact.MERGED_MANIFEST)
}
```

因为我们需要处理 AndroidManifest，所以我们需要拿到 AndroidManifest，并且处理后输出。但是每个 module 都有一个 AndroidManifest 文件，我们应该拿谁呢？我们当然可以只对特定的 module 做处理。但是事实上，Android 在编译时会把所有的 AndroidManifest 文件的内容合并起来，组成一个 merged AndroidManifest。merged AndroidManifest 文件的位置在形如 /app/build/intermediates/merged_manifests/debug/AndroidManifest.xml。我们可以对这个文件做处理。

经过上述操作，我们就实现了在 AndroidManifest 中添加数据，以在运行时读取。

#### 5. 启动时参数注入

生成了 AppRouteRegister 类后，我们需要在启动时将 AppRouteRegister 的数据注入到 RouteHub 中。此操作在 application 中进行。此处我们使用了 Jetpack 中的 [AndroidX App Startup](https://blog.csdn.net/guolin_blog/article/details/108026357) 框架，以实现自动初始化。

1. 导入`implementation "androidx.startup:startup-runtime:1.1.1"`依赖
2. 在 create 方法中实现初始化操作，数据写入 RouteHub 单例类中
   
   ```kotlin
   class RouteInitializer : Initializer<Unit> {
       override fun create(context: Context) {
           init(context)
       }

       override fun dependencies() 
           = emptyList<Class<out Initializer<*>>>()

       private fun init(
           context: Context
       ) = context.packageManager.getApplicationInfo(
           context.packageName,
           PackageManager.GET_META_DATA
       ).metaData?.apply {
           // 读取在 RoutePlugin 注入的 moduleName 数据
           keySet().forEach {
               val moduleName = getString(it, null)
               if (Constants.META_VALUE == moduleName) {
                   injectRoute(it)
               }
           }
       }

       // 路由数据写入 RouteHub
       private fun injectRoute(moduleName: String) = try {
           // 等价于 Class.forName("AppRouteRegister")
           Class.forName(getTableClassName(moduleName))
               .takeIf {
                   // 判断是否是 RouteRegister 的子类
                   RouteRegister::class.java.isAssignableFrom(it)
               }?.run {
                   // 生成 RouteRegister 子类的实例
                   (this as Class<out RouteRegister>).newInstance()
               }?.also { routeRegister ->
                   // 路由数据写入 RouteHub.routeTable 中
                   routeRegister.register(RouteHub.routeTable)
               }
       } catch (e: Exception) {
           e.printStackTrace()
       }

       private fun getTableClassName(moduleName: String) =
           Constants.GENERATED_ROUTE_REGISTER_PATH + "." + Utils.getRegisterClassName(moduleName)
   }
   ```

3. AndroidManifest 文件中声明 RouteInitializer 启动项：

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <manifest
       xmlns:android="http://schemas.android.com/apk/res/android"
       xmlns:tools="http://schemas.android.com/tools"
       package="com.aaa.bbb.ccc">

       <application>
           <provider
               android:name="androidx.startup.InitializationProvider"
               android:authorities="${applicationId}.androidx-startup"
               android:exported="false"
               tools:node="merge">

               <meta-data
                   android:name="com.aaa.bbb.ccc.route.RouteInitializer"
                   android:value="androidx.startup" />
           </provider>
       </application>
   </manifest>
   ```

#### 6. 根据路由启动页面

数据注入 RouteHub 了后，我们就可以使用 Router 启动页面了。Router 源码如下：

```kotlin
object Router {
    fun go(context: Context, url: String) {
        val className = RouteHub.routeTable[url] ?: ""
        context.startActivity(
            getIntent(context, className).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }

    fun getIntent(context: Context, className: String): Intent {
        return Intent().setClassName(context, className)
    }
}
```

使用起来也很简单：

```kotlin
Router.go(activity, RouteConst.MAIN)
```

## 总结

经过上述步骤，我们就完成了 Route 注解的解析、路由注册类文件的生成、编译时参数注入、运行时参数注入、初始化是填充路由表、根据路由启动页面等操作。其中涉及到了自定义注解、自定义注解处理器、源码文件的生成、AndroidManifest.xml 文件的解析、自定义 Gradle Plugin、自定义 Gradle Task、APG 的自定义、编译时的参数注入、运行时的参数注入、jetpack 的 androidx.startup 框架的使用、反射生成类实例等知识点。

可以看出，自定义路由插件，涉及到的知识又多又杂又难，值得学习。最终我们也实现了想要的效果。

至此，本文的讲解就告一段落了，文中的知识，我们只是初步浅显的进行了讲解，更深入的知识，我们还是得继续学习。

感谢大家阅读本文，文中讲解的不足之处、错误的地方，欢迎大家指正。