---
title: "Android Gradle 基本介绍"
description: "本文主要讲解 Android Gradle 的基本内容"
keywords: "Android,Gradle"

date: 2020-01-31 14:56:00 +08:00
lastmod: 2020-01-31 14:56:00 +08:00

categories:
  - Android
  - Gradle
tags:
  - Android
  - Gradle

url: post/1BA263F2B2A249959A37588643145C13.html
toc: true
---

本文主要讲解 Android Gradle 的基本内容

<!--More-->

## 简介

注：这片文章是对官方教程的一篇整合，官方的网站太难访问了（原因众所周知）。

现在的 Android 应用都是采用 Android Studio 来开发的，AS 默认是采用 Gradle 作为构建工具的。通常开发者可以不需要理解任何 Gradle 的脚本配置，就可以开发出一个 APP。但是，当你想做一些更智能的操作时，比如修改打包后的输出目录、提高打包速度等等，就必须对 Gradle 有比较深入的了解。Gradle 脚本是基于 Groovy 语言来编译执行的。详见**[groovy 官网](http://www.groovy-lang.org/)**。进行配置前，应该首先了解 gradle 中用到的相关 groovy 语言的语法。

Gradle 是一个工具，同时它也是一个编程框架。详见**[Gradle 官网](https://docs.gradle.org/)**

下面我们会将 Gradle 当作一个编译工具，从 Android 项目编译流程、Android Gradle 项目结构、自定义配置过程等方面介绍 Gradle。

## Android 项目编译流程

构建流程涉及许多将项目转换成 Android 应用软件包 (APK) 的工具和流程。下面借用一张官方的图片：

![Android 项目编译流程](/imgs/Android编译流程官方介绍图.png)

中间的虚线部分便是由 Gradle管理的。

如上图所示，典型 Android 应用模块的构建流程通常按照以下步骤执行：

1. 编译器将您的源代码转换成 DEX 文件（Dalvik 可执行文件，其中包括在 Android 设备上运行的字节码），并将其他所有内容转换成编译后的资源。
2. APK 打包器将 DEX 文件和编译后的资源合并到一个 APK 中。
3. APK 打包器使用调试(Debug)或发布(Release)密钥库为 APK 签名。调试版应用（即专用于测试和分析的应用）会使用调试密钥库为应用签名。**Android Studio 会自动使用调试密钥库配置新项目。**这是默认的情况，如果我们不需要发布版应用，则不必再次配置密钥库，直接使用即可。要使用发布版应用，则要创建发布密钥库，请参阅**[在 Android Studio 中为应用签名](https://developer.android.google.cn/studio/publish/app-signing.html#studio)。**
4. 打包器使用 zipalign 工具对应用进行优化，以减少其在设备上运行时所占用的内存。 
5. 生成最终的可以使用的 APK。

## 自定义编译配置

Gradle 和 Android 插件可以完成以下方面的版本配置：

### 版本类型

版本类型的英文名是：Build Type。版本类型定义 Gradle 在构建和打包应用时使用的某些属性，通常针对开发流程的不同阶段进行配置。要构建应用，必须至少定义一个版本类型。**Android Studio 默认会创建调试和发布两个版本类型（Debug版和Release版）**。更多的内容详见**[配置版本类型](https://developer.android.google.cn/studio/build/build-variants.html#build-types)**。

### 产品变种

产品变种的英文名为：Product Flavors。亦可翻译为产品风味，产品味道。含义嘛，个人的理解就是同一种产品，有着不同的"味道"、特性。产品变种代表您会向用户发布的应用的不同版本，如应用的免费版和付费版。您可以自定义产品变种来使用不同的代码和资源，同时共享和重复利用各版应用的共用部分。产品变种是可选的，您必须手动创建，Gradle 不会自动生成产品变种。更多的内容详见**[配置产品变种](https://developer.android.google.cn/studio/build/build-variants.html#product-flavors)**。

### 版本变体

版本变体的英文名是：Build Variant。版本变体是版本类型与产品变种的交叉产物(即 Build Variant = Build Type * Product Flavors)。利用版本变体，您可以在开发期间构建产品变种的调试版本，或者构建产品变种的已签名发布版本以供分发。更多的内容详见**[配置版本变体](https://developer.android.google.cn/studio/build/build-variants.html)**

### 清单条目

您可以在版本变体配置(Gradle 配置)中为清单文件的某些属性(AndroidManifest 清单文件中设置的属性)指定值。这些版本值会替换清单文件中的现有值。如果您要为模块生成多个 APK，让每一个 APK 文件都具有不同的应用名称、最低 SDK 版本或目标 SDK 版本，便可运用这一技巧。更多的内容详见**[合并清单设置](https://developer.android.google.cn/studio/build/manifest-merge.html)**

### 依赖项

Gradle 项目构建系统会管理来自本地文件系统以及来自远程代码库的项目依赖项。这样一来，您就不必手动搜索、下载依赖项的二进制文件包以及将它们复制到项目目录中。更多的内容详见**[添加构建依赖项](https://developer.android.google.cn/studio/build/dependencies.html)**

### 签名

Gradle 构建系统允许您在版本配置过程中指定签名设置，并且可以在构建过程中自动为 APK 签名。更多的内容详见**[在 Android Studio 中为应用签名](https://developer.android.google.cn/studio/publish/app-signing.html#studio)**。 

### 代码和资源缩减

Gradle 构建系统允许您为每个版本变体指定不同的 ProGuard 规则文件。在构建应用时，构建系统会应用一组适当的规则来使用其内置的缩减工具（如 R8）。几个典型的例子便是如混淆和差异化打包。更多的内容详见**[缩减您的代码和资源](https://developer.android.google.cn/studio/build/shrink-code.html)**

### 多 APK 支持

Gradle 构建系统支持您自动构建不同的 APK，并使每个 APK 只包含特定屏幕密度或应用二进制接口 (ABI) 所需的代码和资源。如需了解详情，请参阅**[构建多个 APK](https://developer.android.google.cn/studio/build/configure-apk-splits.html)**。

### 源集(SourceSet)

Android Studio 按逻辑关系将每个模块的源代码和资源分组为源集(可以理解成包含源代码和资源的文件夹，下面项目机构图中的蓝色部分)。模块的 main/ 源集包含其所有版本变体共用的代码和资源，是项目生成时会默认创建的源集。其他源集目录是可选的，不会默认生成，需要手动添加。

在您配置新的版本变体时，Android Studio 不会自动创建这些目录。不过，创建类似于 main/ 的源集，有助于更好地组织管理，不同版本变体(Build Variant)使用的文件和资源。

- "src/main/" 源集：默认会创建的源集，此源集包含所有版本变体共用的代码和资源。
- "src/buildType/" 源集：需要手动创建的源集，创建此源集以纳入特定版本类型(BuildType，例如 Debug 版和 Release 版两种类型)专用的代码和资源。
- "src/productFlavor/" 源集：需要手动创建的源集，创建此源集以纳入特定产品变种(ProductFlavors，例如同一个 APP 的收费版和免费版两种风格)专用的代码和资源。
- "src/productFlavorBuildType/" 源集：需要手动创建的源集，创建此源集以纳入特定版本变体(Build Variant = Build Type * Product Flavors)专用的代码和资源。

如果不同源集包含同一文件的不同版本。Gradle 将按以下优先顺序决定使用哪一个文件（左侧源集替换右侧源集的文件和设置）：

`版本变体 > 版本类型 > 产品变种 > 主源集 > 库依赖项 `

如果不同的源集中包含不同的清单文件(AndroidManifest.xml 文件)，也会使用同样的顺序进行选择。

更多的内容详见**[创建版本变体的源集](https://developer.android.google.cn/studio/build/build-variants.html#sourcesets)**

## Android Gradle 项目结构

默认情况下，Android 项目的文件目录结构是像下面这样的，借用官方的一张图：

![官方表述的结构图](/imgs/Android项目结构官方介绍图.png)

上图中，灰黑色代表着整个项目部分，绿色是项目中的不同模块，蓝色便是一个模块中的不同源集。

从图中可以看出，存在着多个 build.gradle 文件。事实上，Gradle 项目可以进行模块化编译。所以包含多个 build.gradle 文件，其中最顶层的被称为项目 gradle 文件，各个模块的 build.gradle 文件被称为模块 Gradle 文件。每个模块都有一个 build.gradle 文件，但项目 build.gradle 文件只会有一个。

另外，图中有几个其他作用的目录名，其中包括存放编译结果的 build 目录(编译出来的 APP 会存放到这里)，和指定模块所需依赖包(APP 也是一个模块)的 libs 目录。

settings.gradle 文件位于项目的根目录下，用于指示 Gradle 在构建应用时应将哪些模块包含在内。对大多数项目而言，该文件很简单。当然，它可以做一些很复杂的事，但这需要对 gradle 文件和 Android 项目编译过程有很深的了解。一般不建议做其他事。大多数的 Android 项目的 settings.gradle 文件形式如下：

```java
// APP 模块会被编译进项目中
include ':app'
```

而项目的 build.gradle 文件通常长这个样子：

```groovy
/**
 * 此文件的这个编译脚本的代码块配置 gradle 本身所需要的依赖包，不应该在这里配置每个模块所需要的依赖包。
 */
buildscript {

    /**
     * 此处配置用于 Android Gradle 项目构建的依赖库的搜索和下载位置，
     * 默认配置了包括 JCenter, Maven Central, Ivy 的远程仓库。
     * 当然也可以配置本地依赖库，或者是其他的远程仓库。
     * 下面的代码指定了 jcenter 远程仓库。
     */
    repositories {
        google()
        jcenter()
    }

    /**
     * 该代码块指定Android 项目需要用到的依赖包。
     * 下面的代码是导入 Android Gradle 的插件，用于 Android 项目构建。
     * 项目中各个模块都需要用到的插件和依赖包可以在这里指定
     */
    dependencies {
        classpath 'com.android.tools.build:gradle:3.5.2'
    }
}

/**
 * 此处可以指定用于项目中所有模块的依赖仓库。包括第三方插件和依赖包等。
 * 但是应该注意，模块级别的依赖包应该在模块内部的 build.gradle 文件中定义。
 * 项目默认包含以下两种。并不会导入依赖包（除非明确指定了需要导入的包，不推荐这么做）
 */
allprojects {
    repositories {
        google()
        jcenter()
    }
}
```

### 定义全局公用的额外属性

**定义**

对于包含多个模块的 Android 项目，可能有必要在项目层级定义某些属性并在所有模块之间共享这些属性。为此，可以将额外的属性添加到项目 build.gradle 文件内的 ext 代码块中。

```groovy
// 项目的 build.gradle 文件
buildscript {...}

allprojects {...}

// ext代码块包含自定义的额外属性，这些属性能够被项目中的其他所有模块所使用
ext {
    // 下面是两个例子
    compileSdkVersion = 28
    supportLibVersion = "28.0.0"
    ...
}
```

**使用**

在模块的 build.gradle 文件内，使用语法`rootProject.ext.属性名`访问在 ext 代码块中定义的自定义属性。

```groovy
// 模块的 build.gradle 文件
android {
    // 使用的语法
    compileSdkVersion rootProject.ext.compileSdkVersion
    ...
}
...
dependencies {
    // 此处使用双引号
    implementation "com.android.support:appcompat-v7:${rootProject.ext.supportLibVersion}"
    ...
}
```

## 模块的 build.gradle 文件

模块级 build.gradle 文件位于每个 project/module/ 目录下，用于为其所在的特定模块配置版本设置。可以通过配置这些版本设置来提供自定义打包选项（如额外的版本类型和产品变种），以及替换 main/ 应用清单或顶层 build.gradle 文件中的设置。下面是对该文件的一些基础介绍：

```groovy
// 模块的 build.gradle 内
// 第一行应用这个，此插件是官方开发的生成 APK 的插件。gradle构建项目是以插件的形式具体化的。gradle 是一个框架，不做具体的事。具体的事需要开发者自己实现，这个实现的过程就是开发插件。
// 应用此插件，以便明确构建的最终目的是生成一个 Android 的 APK。此外，插件可以不是 Android 的，可以是C++，Java等的。不过这不在本次的讲述范围内
apply plugin: 'com.android.application'

// android 代码块。导入 Android 插件后，可以配置 Android 项目的属性
android {
    // 编译 APK 时，用到的最大的 SDK 版本
    compileSdkVersion 28
    // 编译工具的版本
    buildToolsVersion "29.0.0"
    // defaultConfig 代码块，定义默认的配置，部分配置可以在 main/AndroidManifest.xml 文件中进行修改，或者是在定义产品变种(product flavors)时修改配置项的实际值
    defaultConfig {
        // 标识应用唯一性的 APP ID，注意和应用的包名是两个概念，虽然它们默认是一致的
        applicationId 'com.example.myapp'
        // APP运行时需要的最小的 SDK 版本
        minSdkVersion 15
        // APP运行时的目标 SDK 版本，也是最大的 SDK 版本
        targetSdkVersion 28
        // APP 的版本号
        versionCode 1
        // APP 的版本名称
        versionName "1.0"
    }
    // buildTypes 代码块配置版本类型，默认情况下，有 Debug 和 Release 两种。Debug 版的相关配置无需明确写出来，可以缺省
    buildTypes {
        // 配置 release 版本
        release {
            // 开启代码混淆，可以进行资源等的压缩
            minifyEnabled true
            // 代码混淆时使用的规则文件，第一个 proguard-android.txt 是 Android 默认的混淆文件，我们自定义的混淆规则添加在后面的这个文件(proguard-rules.pro)中
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    // 构建产品变种(product flavors)时需要指定产品风味维度(flavorDimensions，可以理解成一个组。相同组下面的配置生效)，维度名字随便取
    flavorDimensions "tier"
    productFlavors {
        // 举例：产品有两个版本，付费版本和免费版本，二者报名不一致
        free {
          dimension "tier"
          applicationId 'com.example.myapp.free'
        }

        paid {
          dimension "tier"
          applicationId 'com.example.myapp.paid'
        }
    }
    // 定义分包，根据不同的 ABI 架构或者屏幕密度。
    splits {
        // 根据不同的屏幕密度编包，各个包之间不兼容
        density {

          // 不启用 ABI 拆分机制
          enable false

          // 编包时排除掉以下密度文件夹中的资源，减小体积
          exclude "ldpi", "tvdpi", "xxxhdpi", "400dpi", "560dpi"
        }
    }
    // 该模块依赖的库，下面的代码演示了如何添加本地的和远程的依赖
    dependencies {
        // 添加一个本地依赖，依赖库的名称必须包含在 settings.gradle 文件中
        implementation project(":lib")
        // 添加远程依赖
        implementation 'com.android.support:appcompat-v7:28.0.0'
        // 添加本地二进制依赖，下面的语句添加了 "模块名/libs/" 目录中所有的 JAR 文件
        implementation fileTree(dir: 'libs', include: ['*.jar'])
    }
}
```

## Gradle 属性文件

除了上面讲的 build.gradle 和 settings.gradle 文件，Gradle 还包含两个属性文件，它们位于项目的根目录下，可用于指定 Gradle 构建工具包本身的设置。

**gradle.properties**

您可以在其中配置项目全局 Gradle 设置，如 Gradle 守护进程的最大堆大小。

**local.properties**

配置构建系统的本地环境属性，其中包括：

- ~~ndk.dir：NDK 的路径。此属性已被弃用。NDK 的所有下载版本都将安装在 Android SDK 目录下的 ndk 目录中。~~
- sdk.dir：SDK 的路径。
- cmake.dir：CMake 的路径。
- ndk.symlinkdir：在 Android Studio 3.5 及更高版本中，创建指向 NDK 的**[符号链接](https://baike.baidu.com/item/%E7%AC%A6%E5%8F%B7%E9%93%BE%E6%8E%A5/7177630?fr=aladdin)**，该链接可比 NDK 安装路径短。

至此，Android Gradle 的基本介绍到这里就结束了。更多更高级的内容会在后续的博文中讲解。