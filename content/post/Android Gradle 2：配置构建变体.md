---
title: "Android Gradle 2：配置构建变体"
description: "本文主要讲解 Android Gradle 的进阶内容"
keywords: "Android,Gradle"

date: 2020-02-03 18:38:00 +08:00
lastmod: 2020-02-03 18:38:00 +08:00

categories:
  - Android
tags:
  - Gradle
  - Android

url: post/CCDB475698774A8BBA674460B4715E9C.html
toc: true
---

本文主要讲解 Android Gradle 的进阶内容

<!--More-->

本博文以**<u>[Android Gradle 1：基本介绍](https://www.cnblogs.com/wellcherish/p/12241807.html)</u>**为基础，介绍如何配置构建变体。包括：版本类型(Build Type)、产品变种(Product Flavors)、版本变体(版本变体)、依赖项等内容。

## 配置版本类型(Build Type)

可以在模块级 build.gradle 文件的 android 块内的创建和配置版本类型(Build Type)。配置代码包含在 buildTypes 代码块内。当创建新模块时，Android Studio 会自动创建 "debug" 和 "release" 两种版本类型。虽然 "debug" 类型没有显示在构建配置文件中，但 Android Studio 会使用 `debuggable true` 配置它。

如果要添加或更改某些设置，可以将 "debug" 类型添加到配置中。以下示例为调试 Build 类型指定了 applicationIdSuffix，并配置了一个 "test" 版本类型。

```groovy
android {
    // 默认配置
    defaultConfig {
        manifestPlaceholders = [hostName:"www.example.com"]
        ...
    }
    buildTypes {
        // 发布版本的配置
        release {
            // 开启混淆和压缩
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
	// 调试版本的配置
        debug {
            applicationIdSuffix ".debug"
            debuggable true
        }
        // 测试版本的配置
        test {
            // 赋值 debug 版本的属性进行初始化操作
            initWith debug
            manifestPlaceholders = [hostName:"internal.example.com"]
            applicationIdSuffix ".debugTest"
        }
    }
}
```

要详细了解 Build Type 配置的所有属性，请参阅**<u>[版本类型(BuildType) DSL 参考文档](http://wellcherish.gitee.io/androidgradledsl/current/com.android.build.gradle.internal.dsl.BuildType.html)</u>**。

## 配置产品变种(Product Flavors)

### 基本应用

创建产品变种(Product Flavors)与创建版本类型(Build Type)类似：配置位置在 android 代码块的 productFlavors 子代码块中。产品变种支持与 defaultConfig 相同的属性，这是因为 defaultConfig 实际上属于 ProductFlavor 类。这意味着，可以在 defaultConfig 代码块中，提供所有类型的基本配置。并且每种产品变种均可更改任何这些默认值。

所有产品变种都必须属于一个指定的维度，即一个产品变种组。必须将所有产品变种分配给某个维度；否则，将被提示构建错误。错误如下：

```
Error:All flavors must now belong to a named flavor dimension.
The flavor 'flavor_name' is not assigned to a flavor dimension.
```

以下代码示例创建了一个名为 "version" 的维度，并添加了 "demo" 和 "full" 产品变种。这些变种自行提供其 applicationIdSuffix 和 versionNameSuffix：

```groovy
android {
    ...
    defaultConfig {...}
    // 配置版本类型
    buildTypes {
        debug{...}
        release{...}
    }

    // 配置产品变种
    // 指定维度，即产品变种组
    flavorDimensions "version"

    productFlavors {
        demo {
            // 如果所有维度只有一个，这个设置可要可不要，构建系统会自动指定维度为 "version"，建议写上
            dimension "version"
            applicationIdSuffix ".demo"
            versionNameSuffix "-demo"
        }
        full {
            dimension "version"
            applicationIdSuffix ".full"
            versionNameSuffix "-full"
        }
    }
}
```

同样的，要详细了解通过产品变种(Product Flavors)配置的所有属性，请参阅**<u>[产品变种(Product Flavors) DSL 参考文档](http://wellcherish.gitee.io/androidgradledsl/current/com.android.build.gradle.internal.dsl.ProductFlavor.html)</u>**。

### 根据维度划分(配置版本变体(Build Variant))

先看个问题：对于同一个 APK，已经构建了 "demo" 和 "full" 两个变种 APK，但是来了个新需求。需要进一步根据 API 级别划分 APK。这怎么办？

此时就需要用上维度了。

可以使用 Gradle 创建多组维度。在构建应用时，Gradle 会结合使用您定义的每个维度的产品变种配置以及版本类型配置，以创建最终的变种 APK。Gradle 不会将属于同一维度的产品变种组合在一起。

以下代码示例使用 flavorDimensions 属性来创建 "mode" 类型维度和 "api" 类型维度，前者用于对 "full" 和 "demo" 产品类型进行分组，后者用于根据 API 级别对产品类型配置进行分组。

```groovy
android {
    ...
    buildTypes {
        debug {...}
        release {...}
    }
    
    // 指定两个维度，维度的优先级取决于被列举出来的顺序，从高到低，在配置产品变种时，需要确保每一个变种都被指定了一个维度
    flavorDimensions "api", "mode"
    productFlavors {
        demo {
            dimension "mode"
            ...
        }

        full {
            dimension "mode"
            ...
        }
        
        // api 维度中的配置会覆盖 demo 中的同名配置，高优先级覆盖低优先级
        minApi24 {
            dimension "api"
            minSdkVersion 24
            versionCode 30000 + android.defaultConfig.versionCode
            versionNameSuffix "-minApi24"
            ...
        }
        
        minApi23 {
            dimension "api"
            minSdkVersion 23
            versionCode 20000  + android.defaultConfig.versionCode
            versionNameSuffix "-minApi23"
            ...
        }

        minApi21 {
            dimension "api"
            minSdkVersion 21
            versionCode 10000  + android.defaultConfig.versionCode
            versionNameSuffix "-minApi21"
            ...
        }
    }
}
```

Gradle 创建的 APK 数量(版本变体数) = 每个产品变种数 * 版本类型数。如上面的代码中，最终生成的 APK 数量为：12，形式如 app-[minApi24, minApi23, minApi21]-[demo, full]-[debug, release].apk

某一个 APK 的名字为：app-minApi24-demo-debug.apk。对应的版本变体名为：minApi24DemoDebug。

### 过滤变体

默认的，在构建时，Gradle 会穷举所有的 BuildType 和 ProductFlavor 组合，但是实际上，有一些组合出来的 APK 结果并不是我们所需要的，此时就需要进行过滤。

可以通过在各个模块的 build.gradle 文件中创建变体过滤器来移除某些构建变体配置。

继续上面的例子，假设我们只想让 "demo" 版应用仅支持 API 级别 23 和更高版本。那么此时可以使用 variantFilter 代码块过滤掉所有将 "minApi21" 和 "demo" 结合在一起的配置，此代码块仍然在 android 块内：

```groovy
android {
    ...
    buildTypes {...}

    flavorDimensions "api", "mode"
    productFlavors {
        demo {...}
        full {...}
        minApi24 {...}
        minApi23 {...}
        minApi21 {...}
    }
    
    // 过滤变种组合，对于每一中组合，都会经过这个过滤器筛选。
    variantFilter {
        // groovy 语法，根据已有列表创建新列表的简洁语法， * 相当于遍历 flavors 中的所有元素，并取出每个元素的 name 构成一个新的列表
        // 转换成 Java 语法的形式为(非正确代码)
        // 
        // def names;
        // for(Flavor flavor : variant.flavors)
        //     names.add(flavor.name);
        // 
        // 此处的 flavors 实际大小为 1，因为是针对每一个 variant 而言的，则 names 实际是个字符串类型

        variant ->
        def names = variant.flavors*.name
        if (names.contains("minApi21") && names.contains("demo")) {
            // 符合条件则忽略
            setIgnore(true)
        }
    }
}
```

## 配置源集(Source Set)

源集，也叫做源代码文件集。默认情况下，Android Studio 会为我们创建 "main/" 源代码文件集和目录。但是，如果我们希望构建新的版本类型和产品变种及其交叉产物。那么我们就可以构建新的源集，在 "main/" 源代码文件集中定义基本功能，各个变种 APK 的不同特性定义在不同的源集中。

Gradle 要求以某种类似于 "main/" 源代码文件集的方式，组织源代码文件集文件和目录。例如，Gradle 要求将 "debug" Build Type特有的 Java 类文件放在 "src/debug/java/" 目录中。

### 使用任务查看源集

Gradle 的 Android 插件提供了一个有用的 Gradle 任务(task)，该任务可以用来展示如何整理每个构建类型(Build Type，中文翻译不一样，意思一样)、产品类型(Product Flavor)和构建变体(Build Variant)的文件。例如，以下任务输出的示例描述了 Gradle 希望 "debug" 构建类型的部分文件所在的位置：

```
------------------------------------------------------------
Project :app
------------------------------------------------------------

...

debug
----
Compile configuration: compile
build.gradle name: android.sourceSets.debug
Java sources: [app/src/debug/java]
Manifest file: app/src/debug/AndroidManifest.xml
Android resources: [app/src/debug/res]
Assets: [app/src/debug/assets]
AIDL sources: [app/src/debug/aidl]
RenderScript sources: [app/src/debug/rs]
JNI sources: [app/src/debug/jni]
JNI libraries: [app/src/debug/jniLibs]
Java-style resources: [app/src/debug/resources]
```

想要使用此任务查看输出，可以使用一下操作步骤：

1. 点击 IDE 右侧的 Gradle 图标。
2. 依次转到 MyApplication > Tasks > android，然后双击 sourceSets。Gradle 执行该任务后，系统应该会打开 Run 窗口以显示输出，Run 窗口默认在 IDE 底部。位置如下，

![Gradle 查看源集的任务](/imgs/AndroidGradleSourceSetTask.png)

注意：输出的结果中还包含了测试（Android测试，Java测试）源代码文件集。

### 创建源集

当创建新的构建变体时，Android Studio 不会创建源代码文件集目录，而是提供一些有用的选项，手动触发创建选项。例如，为 "debug" 构建类型创建 "java/" 目录，应执行以下操作：

1. 打开 Project 窗格，然后从窗格顶部的下拉菜单中选择 Project 视图。
2. 转到 MyProject/app/src/。
![创建源集第一二步](/imgs/创建源集第一二步.png)
3. 右键点击 src 目录，然后依次选择 New > Folder > Java Folder。
![创建源集第三步](/imgs/创建源集第三步.png)
4. 从 Target Source Set 旁边的下拉菜单中，选择 debug。
5. 点击 Finish。
![创建源集第四五步](/imgs/创建源集第四五步.png)

当 "debug" 构建类型被指定为目标源代码文件集后，Android Studio 在创建 XML 文件时会自动创建必要的目录。如图：

![指定debug为目标源集后的xml目录](/imgs/指定debug为目标源集后的xml目录.png)

按照相同的过程，可以创建产品变种的源代码文件集目录（如 src/demo/）和构建变体的源代码文件集目录（如 src/demoDebug/）。此外，还可以创建特定构建变体的，特定的测试源代码文件集（例如 src/androidTestDemoDebug/）。要了解详情，请查看**<u>[测试源代码文件集](https://developer.android.google.cn/studio/test/index.html#sourcesets)</u>**。

### 更改默认源代码文件集配置

如果开发中未按照官方建议的源集文件结构，整理源文件（如上文创建源集的相关内容所述），则可以使用 sourceSets 代码块，更改为源集的每个组件收集文件的位置。改代码块也是在 android 代码块下。无需改变文件的位置，只需设置相对于模块级 build.gradle 文件的路径即可。Gradle 会在该路径下找到每个源集组件的文件。要了解可以配置哪些组件，以及是否可以将它们映射到多个文件或目录，请参阅**<u>[AndroidSourceSet DSL 参考文档](http://wellcherish.gitee.io/androidgradledsl/current/com.android.build.gradle.api.AndroidSourceSet.html)</u>**。

下面的代码展示了将 "app/other/" 目录中的源文件映射到 "main/" 源代码文件集的某些组件，并更改 "androidTest/" 源代码文件集的根目录。

```groovy
android {
    ...
    sourceSets {
        // 指定 Java 源代码目录为，默认的目录是'src/main/java'
        java.srcDirs = ['other/java']
        // 指定资源文件夹目录，默认的目录是'src/main/res'
        // 如果此处同时列举了多个目录，gradle 在编译时会从所有目录中收集源文件。因为所有目录的优先级都是一样的。
        // 但是如果不同的目录中有相同的源文件，则会报错。即可以指定多个目录，但目录之间之间不同有相同的文件。
        // 另外，在自动目录时，应避免目录之间存在父子关系(父目录，子目录)。即目录之间应该是并列关系，而不是包含关系
        res.srcDirs = ['other/res1', 'other/res2']
        // 对于每一个源集，可以指定一个清单文件。Android Studio 会默认为 "main/" 源集创建一个清单文件
        manifest.srcFile 'other/AndroidManifest.xml'
        ...
    }
    // 额外的块配置其他源集
    androidTest {
        // 如果一个源集的所有文件都在一个目录下，则可以使用 'setRoot ' 属性指根目录。
        // 设置了以下属性后，Gradle 会在 'src/tests/java/' 目录下寻找 Java 源文件
        setRoot 'src/tests'
        ...
    }
    ...
}
```

### 使用源集进行构建

可以在源代码文件集目录中，添加针对某些配置打包在一起时的代码和资源。例如，如果要构建 "demoDebug" 这个构建变体（"demo"产品变种和"debug"构建类型的混合产物），则 Gradle 会查看这些目录，并为它们指定以下优先级：

1. src/demoDebug/（构建变体源代码文件集）
2. src/debug/（构建类型源代码文件集）
3. src/demo/（产品类型源代码文件集）
3. src/main/（主源代码文件集）

注意，优先级也受维度的影响。参见上文对构建变体(Build Variant)的介绍。

上面列出的顺序决定了 Gradle 组合代码和资源时,哪个源代码文件集的优先级更高。如果 'demoDebug/' 包含了 'debug/' 中也定义了的文件，则 Gradle 会使用 'demoDebug/' 源代码文件集中的文件。在应用以下构建规则时，Gradle 会考虑这种优先级顺序：

- java/ 目录中的所有源代码将一起编译以生成单个输出。注意：对于给定的构建变体，如果 Gradle 遇到两个或更多个源代码文件集目录定义了同一个 Java 类的情况，则会抛出构建错误。例如，在构建 debug APK 时，您不能同时定义 src/debug/Utility.java 和 src/main/Utility.java 两个相同的类。这是因为 Gradle 在构建过程中会查看这两个目录并抛出“重复类”错误。
- 所有清单都将合并为一个清单。优先级将按照上面列出的顺序分配。也就是说，构建类型(debug)的清单设置会替换产品变种(demo)的清单设置，依此类推。要了解详情，请参阅**<u>[清单合并](https://developer.android.google.cn/studio/build/manifest-merge.html)</u>**。
- 同样，values/ 目录中的文件也会合并在一起。如果两个文件同名，例如存在两个 strings.xml 文件，将按照上述列表中的相同顺序指定优先级，高优先级覆盖低优先级。
- res/ 和 asset/ 目录中的资源会打包到一起。如果在两个或更多个源代码文件集中定义了同名的资源，将按照上面列表中的顺序指定优先级。同 'values' 目录的处理方式。
- 最后，在构建 APK 时，Gradle 会为库模块依赖项随附的资源和清单指定最低优先级(依赖库中的内容为最低优先级)。

总结一下，Java 类比较特殊，重复了会报重复类的错误，说明 Java 类之间不会相互覆盖。而其他的资源、清单文件会根据优先级来相互覆盖。

从上面的类重复错误和资源覆盖可以看出。源集的构建应该遵循"**主源集包含公共的内容，其他构建变体的源集包含差异化的内容**"的原则。

到这里为止，Android Gradle 当做工具的进阶使用讲解算是告一段落。

最后，附上**<u>[Android Plugin for Gradle DSL 参考](http://wellcherish.gitee.io/androidgradledsl/current/index.html)</u>**。