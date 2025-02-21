---
title: "重磅 - Gradle 功能介绍"
description: "本文介绍了 Android Gradle 的进阶知识"
keywords: "Android,Gradle"

date: 2023-01-28T22:51:00+08:00

categories:
  - Android
  - Gradle
tags:
  - Android
  - Gradle

url: post/1C0A0A86D7BE46A293A2791409052978.html
toc: true
---

本文介绍了 Android Gradle 的进阶知识。

<!--More-->

笔者耗时 8 个月学习、写作，五万字长文总结，带你了解 Gradle 提供的功能。

## 阅前提示

阅读本文前需知晓的几个点：

- 本文档不是面向小白的文档，而是适用于有过一定 Gradle 使用经验的开发者阅读。关于 Gradle 的基础知识点的讲解文档，可以自行上网搜索。

- 本文并不会讲解 Gradle 的所有知识点，会跳过很多知识点。

- 文本并不是 Gradle API 说明文档，只是一篇功能说明文档。主要目的是阐述 Gradle 具有哪些功能，方便我们编写代码时，可以快速判断适不适合用 Gradle；或者看到一些 Gradle 方法、术语时，不用再十分茫然，发出这是啥的疑问。至于具体的功能怎么实现的，具体的代码该怎么写，本文可能不会详细阐述。

- 本文基本不会涉及 AGP(Android Gradle Plugin) 的内容，基本只会讲 Gradle 的知识点

- 本文的示例代码，存在 Groovy 和 kts 混用的情况，主要是为了凸显出差异。推荐优先使用 kts 开发，方便代码更易于阅读、理解以及调试

- 不同版本的 Gradle，差异很大。基本可以看作是破坏式更新。本文主要以 Gradle 7.3.3 版本为基础，对 Gradle 的知识点进行讲解，低版本的功能可能和当前版本存在较大差异。请大家谨慎阅读

## 概述

Android 项目使用 Gradle 构建、管理项目。Gradle 是一个基于 JVM 的构建工具。对于使用者而言，其主要有以下两个方面的特点：

1. 可以看作是一个工具。因为我们主要执行是使用 Gradle 进行编译。

2. 可以看作是基于 java、groovy、kotlin 等语言的一个三方库或者一个框架。因为在日常使用中，我们主要是编写 gradle 脚本，gradle 脚本又主要是定义任务(Task)、实现插件(Plugin)、编写 build 配置(Configuration)。

Gradle 的两个特点其实并不冲突。相反，是有紧密联系的。首先 Gradle 可以看作工具，是因为 Gradle 提供了对应的能力；而 Gradle 具有的能力，是我们通过任务、插件实现的。所以学习 Gradle，本质上是要学习 Gradle 提供的能力，以及如何自定义能力。

本文便从将 Gradle 视为三方库的角度，对 Gradle 的相关知识进行介绍。文章主要涉及到 Project、Gradle、Settings、Task、Configuratin、Plugin 等几个类的讲解。其中 Project 类贯穿全文。

## Gradle 项目结构

Gradle 的常见的项目结构如下：

![Gradle项目结构](/imgs/Gradle项目结构.webp)

针对图片中的内容，做以下几点说明：

- 在 gradle 中，一个具有 build.gradle 文件的目录，可以看作是一个项目目录，gradle 会为其生成一个 project 对象。**即一个 project 对象对应一个 build.gradle 文件**

- 一个项目可以有上级项目与子项目，如上图，module A 文件夹具有上级目录"项目目录"，"项目目录"也有子目录"module A 文件夹"，而"项目目录"本身代表的是根项目。反应到 Gradle 中的定义就是，"项目目录"代表 root project，也代表 module A 的 parent project，而 module A 则是 "项目目录" 的 child project

- 每个 Gradle 项目都有一个 gradle 文件夹，里面是 wrapper 目录，wrapper 目录里有 gradle-wrapper.jar 文件和 gradle-wrapper.properties 文件。我们需要重点关注 gradle-wrapper.properties 文件，gradle-wrapper.jar 文件我们可以不用太关注。针对 gradle-wrapper.properties 文件，作两点说明：

   1. 文件中可以设置一个 distributionUrl 属性。该属性决定了当前项目导入的 Gradle 的版本。以 distributionUrl=https\://services.gradle.org/distributions/gradle-7.3.3-all.zip 为例。通常我们只需要关注标黄的部分即可

      - 7.3.3 代表了当前项目我们使用的 Gradle 的版本。注意此版本应该和 Android Gradle Plugin 的版本匹配。具体可见官方说明：Android Gradle 插件版本说明

      - all 代表了我们引入的是有源码的版本的。此处通常可选两个值：bin/all。bin代表引入的是编译后的 Gradle 版本，此版本仅有 Gradle 被编译成二进制代码后的 class 文件，反编译后，是看不到类的注释的，也无法执行类的跳转。而 all 版本除了导入 class 文件外，还导入了 Gradle 工具的 java 源码，我们可以查看对应的类的注释，以及执行类之间的跳转

      - 有时设置 all 版本之后，也看不到源码。此时可能是因为选择的项目管理工具是 IDEA，而不是 Gradle。此问题在新建项目时需确定好

   2. 文件中可以设置的属性中，有一个 GRADLE_USER_HOME 的变量，代表 gradle 所在的目录。该目录可以在 iead 中设置：

      ![Gradle_Home_设置位置](/imgs/Gradle_Home_设置位置.webp)
    
- 每一个 Gradle 项目，都会有一个 settings.gradle 文件，该文件全局唯一，对应一个 Settings 对象，用于指定相关信息，包括根项目、参与编译的项目(include build)等。该文件里的内容是 Gradle 项目编译时，最先执行的内容

   ![Settings文件内容](/imgs/Settings文件内容.webp)

- 在 Gradle 的根项目下，有 gradlew 和 gradlew.bat 两个文件，这是系统脚本文本，用于启动 Gradle 编译，分别对应 Linux 和 Windows 系统的脚本

- Gradle 中可以使用 buildSrc 做一些编译时的操作，该目录会被视作一个 include build，但是却并不需要在 settings.gradle 文件中导入(有该目录，gradle 就默认导入)

- Gradle 中，一个接口的实现类，默认以 Default 开头，比如 Gradle 的实现类 DefaultGradle，Settings 的实现类 DefaultSettings

## Project 类功能

我们在使用 gradle 的过程中，最核心的一个类就是 Project，它提供了 Gradle 各个能力的入口，每个 build.gradle 文件都会生成一个 project 对象。project 类提供的能力如下。后面我们会逐个分析这些能力：

![Project提供的能力](/imgs/Project提供的能力.webp)

## Gradle 文件操作

**注：官方讲解地址：[Working With Files](https://docs.gradle.org/current/userguide/working_with_files.html)**

每个 gradle 构建(build)都或多或少会与文件操作打交道。Gradle 提供了一个全面的 API，帮助我们轻松执行所需的文件操作。这些 API 主要分为以下两大部分：

- 指定要处理的文件和目录(Working With Files (gradle.org)深入讲解了此内容)

- 指定需要使用这些文件和目录做什么事(Working With Files (gradle.org)深入讲解此内容)

本文要讲解的 Gradle 的文件操作的知识点如下：

![Gradle文件操作](/imgs/Gradle文件操作.webp)

### 复制文件

Gradle 内置了复制文件的能力，为其配置文件的来源以及目的地，以复制文件。

- 参数的类型可以参考 Project.file 或者 Project.files 支持的参数形式

- Copy.from(java.lang.Object...​) 指定需要复制哪个文件

   1. from 支持声明多个文件参数(即支持多文件复制)，见 copyReportsForArchiving 任务

   2. from 方法可以调用多次，用于指定多个文件。Copy 类有个列表，存储待执行的复制操作，每调用一次 from，就会向List 增加一次数据

- Copy.into(java.lang.Object) 指定复制到哪里

- include 用于指定需要被包含的文件，见 copyPdfReportsForArchiving/copyReportsDirForArchiving2 任务

   - 在 from，into 闭包内使用时，仅对当前闭包生效

   - 参数支持模版指定，具体的可以参阅 PatternFilterable 类

- exclude 用于指定需要被排除的文件

   - 在 from，into 闭包内使用时，仅对当前闭包生效

   - 参数支持模版指定，具体的可以参阅 PatternFilterable 类

- filters 指定过滤文件

- rename 重命名文件

- Gradle 内置的 copy 任务默认会一起复制文件的目录结构

要使用这种能力，一般有两种方式：

- 可以自定义任务，实现 Copy 类。

- 使用 Project.copy(Action) 方法。此方法默认不是增量的(增量编译相关，后面讲解)

```groovy
tasks.register('copyReport', Copy) {
    from layout.buildDirectory.file("reports/my-report.pdf")
    into layout.buildDirectory.dir("toArchive")
}

tasks.register('copyReport2', Copy) {
    from "$buildDir/reports/my-report.pdf"
    into "$buildDir/toArchive"
}

tasks.register('copyReportsForArchiving', Copy) {
    from layout.buildDirectory.file("rAndroid Plugin DSL Reference
y) {
    from layout.buildDirectory.dir("reports")
    // 此 include 对 task 生效
    include "*.pdf"
    into layout.buildDirectory.dir("toArchive")
}

tasks.register('copyReportsDirForArchiving2', Copy) {
    from(layout.buildDirectory) {
        // 此 include 仅对 from 生效
        include "reports/**"
    }
    into layout.buildDirectory.dir("toArchive")
}
```

#### 使用 CopySpec 类

CopySpec 可以翻译为复制规范。该规范决定将什么复制到何处，以及在复制过程中文件会发生什么。上面有许多复制和归档任务配置形式的示例。但是 CopySpec 有两个属性值得更详细地介绍。

- CopySpec 可独立于 task。这允许我们在构建中共享 CopySpec

- CopySpec 是有层次的。这允许我们提供更细粒度的控制

##### 共享 CopySpec

假设一个场景：需要将一个包含多个资源的静态网站添加到压缩包中。此时有多个任务用于完成这件事。一项任务可能会将资源复制到本地 HTTP 服务器的文件夹中，而另一项任务可能会将它们打包到发布包中。

我们可以在需要时每次手动指定文件位置和文件包含的内容，但人为设置可能存在潜在风险，从而导致任务之间的不一致。Gradle 提供了一种这个问题的解决方案：Project.copySpec(org.gradle.api.Action) 方法。该方法允许我们在任务配置块之外创建 CopySpec，然后使用 CopySpec.with(org.gradle.api.file.CopySpec...​) 方法将其附加到适当的任务。

以下示例演示了上面的说明：

```groovy
// 定义在多个 task 中使用的共享 CopySpec
CopySpec webAssetsSpec = copySpec {
    from 'src/main/webapp'
    include '**/*.html', '**/*.png', '**/*.jpg'
    rename '(.+)-staging(.+)', '$1$2'
}

tasks.register('copyAssets', Copy) {
    into layout.buildDirectory.dir("inPlaceApp")
    with webAssetsSpec
}

tasks.register('distApp', Zip) {
    archiveFileName = 'my-app-dist.zip'
    destinationDirectory = layout.buildDirectory.dir('dists')

    from appClasses
    with webAssetsSpec
}
```

```groovy
// 定义共享闭包
def webAssetPatterns = {
    include '**/*.html', '**/*.png', '**/*.jpg'
}

tasks.register('copyAppAssets', Copy) {
    into layout.buildDirectory.dir("inPlaceApp")
    from 'src/main/webapp', webAssetPatterns
}

tasks.register('archiveDistAssets', Zip) {
    archiveFileName = 'distribution-assets.zip'
    destinationDirectory = layout.buildDirectory.dir('dists')

    from 'distResources', webAssetPatterns
}
```

#### 使用子规范

子规范(可以视作补充约束)是在 from() 块或者 into() 块中指定的内容。有几个注意事项：

- root into() 中的内容应指定好，以代表所有复制内容默认的取值。

- 子 CopySpec 会从父级继承目标路径、包含模式、排除模式、复制操作、名称映射和过滤器。配置时需谨慎

```groovy
tasks.register('nestedSpecs', Copy) {
    into layout.buildDirectory.dir("explodedWar")
    exclude '**/*staging*'
    from('src/dist') {
        include '**/*.html', '**/*.png', '**/*.jpg'
    }
    from(sourceSets.main.output) {
        // WEB-INF/classes 是相对于 explodedWar 的目录
        into 'WEB-INF/classes'
    }
    into('WEB-INF/lib') {
        from configurations.runtimeClasspath
    }
}
```

#### 在任务中复制文件

在上面的讲解中，复制文件的操作，我们都是定义任务单独进行的。但是存在将复制文件作为任务动作一部分的场景。例如编译任务的众多中间文件。此时我们可以使用 Project.copy(org.gradle.api.Action) 方法进行复制。但是该方法默认不能用于增量编译。

下面的代码描述如何让 Project 的 copy 方法具有增量编译的能力。copyMethodIO 是增量的，其输入来自于 copyTask，输出为 some-dir。虽然方法 copyMethodIO 任务并没有直接改动这些任务，但是 copy 方法使输出发生了改变(copyMethodIO 定义输入输出，copy 使用了输入输出。inputs 和 outputs 可以改变，一改变就能检测到)。此时增量编译检查也能生效。

```groovy
tasks.register('copyMethodIO') {
    // inputs 的 up-to-date check 增加 copyTask
    // 返回的是 TaskInputFilePropertyBuilder，
    // 属性名为：inputs(第二行代码)
    inputs.files(copyTask)
        .withPropertyName("inputs")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    // outputs 的 up-to-date check 增加 some-dir
    // 返回的是 TaskOutputFilePropertyBuilder
    // 属性名为：outputDir(第二行代码)
    outputs.dir('some-dir')
        .withPropertyName("outputDir")
    doLast{
        copy {
            // 复制 copyTask 的 ouput 到 some-dir
            from copyTask
            into 'some-dir'
        }
    }
}
```

#### 同步操作

Sync 任务扩展了 Copy 任务。它将源文件复制到目标目录中，然后从目标目录中删除它没有复制的所有文件。换句话说，它将目标目录的内容与其源同步。这对于安装 app、创建解压包或维护项目依赖等操作很有帮助。此外还可以使用 Project.sync(org.gradle.api.Action) 方法在自己的任务中执行相同的功能。

```groovy
tasks.register('libs', Sync) {
    from configurations.runtime
    into layout.buildDirectory.dir('libs')
}
```

#### 不记录任务状态

##### 1. 将文件部署到服务器

我们可以使用 Copy 任务部署应用程序归档包(例如 WAR 文件)到服务器。

Copy 单个文件时需要指定 Copy 动作的目标目录，但该目录有时包含不可读的文件，例如命名管道(pipe line)等。当目录包含不可读的文件时，Gradle 在进行 up-to-date 检查(增量编译检查)时可能会遇到问题。为了解决这个问题。我们可以使用 Task.doNotTrackState() 方法不记录任务的状态。换句话说，使用 Task.doNotTrackState() 就抛弃了增量编译的能力，每次任务都会执行。

```groovy
plugins { id 'war' }

tasks.register("deployToTomcat", Copy) {
    from war
    into layout.projectDirectory.dir('tomcat/webapps')
    doNotTrackState("Deployment directory contains unreadable files")
}
```

##### 2. 安装可执行文件

构建了一个独立的可执行文件后，我们可以在系统上安装这个文件。安装后它最终会出现在系统对应的路径中(如 Linux系统的 /usr/local/bin 目录)。我们可以使用 Copy 任务将可执行文件复制到对应目录中。但是安装目录中可能包含其他可执行文件，其中一些 Gradle 可能无法读取。为了避免因文件不可读导致的耗时检查(增量编译检查)，我们可以使用 Task.doNotTrackState() 方法。

```groovy
tasks.register("installExecutable", Copy) {
    from "build/my-binary"
    into "/usr/local/bin"
    doNotTrackState("Installation directory contains unrelated files")
}
```

### 删除文件

可以使用 Delete 任务或 Project.delete(org.gradle.api.Action) 方法轻松的删除文件和目录。在这两种情况下，参数与 Project.files(java.lang.Object...​) 方法支持的参数形式相同。

更精细化的删除控制，不是由与 Copy 类似的 include 和 exclude 控制，而是需要使用 FileCollection 和 FileTree 内置的过滤机制。

```groovy
tasks.register('myClean', Delete) {
    delete buildDir
}
// 删除 src 目录下的 temp 文件
tasks.register('cleanTempFiles', Delete) {
    delete fileTree("src").matching {
        include "**/*.tmp"
    }
}
```

### 移动文件

移动目录和文件不是一个常见的要求，应该谨慎使用，因为会丢失信息并且很容易破坏构建。通常最好是复制目录和文件。

Gradle 没有用于移动文件和目录的 API，可以先复制，后删除，达到相同效果。

### 使用文件

Project.file(java.lang.Object) 方法解析文件。相对路径是相对于项目目录解析的，而绝对路径保持不变。并且无论项目路径如何，该方法都不会返回空文件。注意永远不要使用 new File(relative path) 获取文件，因为这会创建一个相对于当前工作目录 (current working directory，CWD) 的路径。 Gradle 不能保证 CWD 的位置。这意味着依赖于 CWD 的构建(build)随时都有可能中断。方法参数取值如下：

- 一个 CharSequence，包括 String 或 groovy.lang.GString。被视作相对于项目目录的相对路径。以 file: 开头的字符串被视为文件 URL

- 一份文件。如果文件是绝对路径文件，则原样返回。否则被视作相对于项目目录的相对路径

- 一个 java.nio.file.Path 对象，该路径必须与默认 provider 相关联，并以与 File 实例相同的方式处理

- URI 或 java.net.URL。 URL 的路径被解释为文件路径。仅支持 file: 开头的 URL

- org.gradle.api.file.Directory 或 org.gradle.api.file.RegularFile

- 此处任何受支持类型的 Provider。Provider 的值被递归解析

- 一个 org.gradle.api.resources.TextResource 对象

- 返回此处任何支持的类型的 Callable。 call() 方法的返回值被递归解析

- 返回此处任何支持的类型的 Groovy 闭包(Closure)或 Kotlin 函数(Function)。闭包的返回值被递归解析

```groovy
// 相对路径：字符串和 File 对象
File configFile = file('src/config.xml')
configFile = file(new File('src/config.xml'))
// 使用 java.nio.file.Path 和相对路径
configFile = file(Paths.get('src', 'config.xml'))
// 绝对路径
configFile = file(configFile.absolutePath)
// 使用 java.nio.file.Path 和绝对路径
configFile = file(
    Paths.get(System.getProperty('user.home')
).resolve('global-config.xml')

// 多项目工程中，使用 rootDir 获取绝对路径
configFile = file("$rootDir/shared/config.xml")
```

### 创建目录

使用 Project.mkdir(java.lang.Object) 方法创建目录。如果目录已存在，mkdir 不会做任何操作。

```groovy
tasks.register('ensureDirectory') {
    doLast {
        mkdir "images"
    }
}
```

### 重命名文件

Gradle 允许使用 rename() 方法在 Copy 文件时进行重命名。可以使用正则或者闭包匹配。如果想要改名，则返回一个新的文件名，如果不想改变名字，则返回 null。注意在重命名的闭包中，避免耗时操作，因为每个文件复制时都会执行该闭包。以下示例代码为从它的文件名中删除“_OEM_BLUE_”标记：

```groovy
// 如 'style_OEM_BLUE_.css' 文件将被重命名为 'style.css'
tasks.register('copyFromStaging', Copy) {
    from "src/main/webapp"
    into layout.buildDirectory.dir('explodedWar')
    // 使用正则表达式匹配名称
    rename '(.*)_OEM_BLUE_(.*)', '$1$2'
}

tasks.register('copyWithTruncate', Copy) {
    from layout.buildDirectory.dir("reports")
    // 使用闭包匹配名称
    rename { String filename ->
        if (filename.size() > 10) {
            return filename[0..7] + "~" + filename.size()
        }
        else return filename
    }
    into layout.buildDirectory.dir("toArchive")
}
```

### 文件集合

文件和目录的包装，主要是指文件集合(FileCollection)和文件树(FileTree)。它们的实现主要分为两种：可修改类和不可修改类。可修改类是可读可写的，而不可修改类是只读的。如下表：ConfigurableFileCollection 和 ConfigurableFileTree 等以 Configurable 开头命名的类是可读写的，类似于 kotlin 中的 MutableList。

|     |     |
| :-: | :-: |
| FileCollection：只读 | ConfigurableFileCollection：可读写 |
| FileTree：只读 | ConfigurableFileTree：可读写 |

#### 文件集合

文件集合是由 FileCollection 接口表示的一组文件路径。FileCollection 中的文件不必位于同一目录中，甚至不必具有共享的父目录，可以彼此不相关。

获取文件集合推荐使用 ProjectLayout.files(java.lang.Object...) 方法，该方法返回一个 FileCollection 实例。此方法非常灵活，允许您传递不同参数。如果任务已定义输出(outputs，这部分内容涉及增量编译，后面讲解)，您甚至可以将任务作为参数传递。所有参数类型同 Project.files(Object) 方法。如下：

- 一个 CharSequence，包括 String 或 groovy.lang.GString。被视作相对于项目目录的相对路径。以 file: 开头的字符串被视为文件 URL

- 一份文件。file(Object) 得到的文件被视作相对于项目目录的相对路径。

- 一个 java.nio.file.Path 对象

- URI 或 java.net.URL。 URL 的路径被解释为文件路径。仅支持 file: 开头的 URL

- org.gradle.api.file.Directory 或 org.gradle.api.file.RegularFile。

- Collection、Iterable 或包含此处任何受支持类型的对象的数组。集合的元素被递归解析

- 一个 org.gradle.api.file.FileCollection，参数的所有元素加入到返回的对象中

- FileTree 或 org.gradle.api.file.DirectoryTree，参数的所有元素加入到返回的对象中

- 此处任何受支持类型的 Provider。Provider 的值被递归解析。如果 Provider 的值表示某个任务的输出，则在文件集合作为另一个任务的输入时执行该任务。

- 返回任何支持的类型的 Callable。 call() 方法的返回值被递归解析。 null 返回值被视为空集合。

- 返回此处列出的任何类型的 Groovy 闭包(Closure)或 Kotlin 函数(Function)。闭包的返回值被递归解析。 null 返回值被视为空集合。

- 一个任务(task)。将任务的输出文件转成 FileCollection。此 FileCollection 用作另一个任务的输入时，执行该任务。

- 一个 org.gradle.api.tasks.TaskOutputs。解释同 task

- 除了上述类型，其他任何内容都被视为错误。

文件集合在 Gradle 中有一些重要的特征：

- 可延迟创建(懒加载)：延迟创建的关键是将闭包(在 Groovy 中)或 Provider(在 Kotlin 中)传递给 files() 方法。您的闭包/Provider只需要返回 files() 接受的类型的值即可，例如 List<File>、String、FileCollection 等

   ```groovy
   tasks.register('list') {
       doLast {
           File srcDir

          // 使用 closure 包创建 FileCollection 
           collection = layout.files { srcDir.listFiles() }

           srcDir = file('src')
           println "Contents of $srcDir.name"
           // collect 相当于 kotlin 中的 map 操作
           // 对每个元素进行转换
           collection.collect { relativePath(it) }
               .sort().each { println it }

           srcDir = file('src2')
           println "Contents of $srcDir.name"
           collection.collect { relativePath(it) }
               .sort().each { println it }
       }
   }

   // gradle -q list 的执行结果：
   // > gradle -q list
   // Contents of src
   // src/dir1
   // src/file1.txt
   // Contents of src2
   // src2/dir1
   // src2/dir2
   ```

- 可遍历。FileCollection 继承了 Iterable<File>，可在 Groovy 中使用 each() 方法，或者在 Kotlin 中使用 forEach 方法，或者单纯的使用 for 循环

- 可结合：可以使用 +、- 对集合进行操作

   ```groovy
   collection.each { File file ->
       println file.name
   }
   // 转为其他集合类型
   Set set = collection.files
   Set set2 = collection as Set
   List list = collection as List
   String path = collection.asPath
   File file = collection.singleFile
   // 集合操作
   def union = collection + layout.files('src/file2.txt')
   def difference = collection - layout.files('src/file2.txt')
   ```

- 可过滤：使用 FileCollection.filter(Spec) 方法确定需要保留的元素，返回一个新的集合

   ```groovy
   FileCollection textFiles = collection.filter { File f ->
       f.name.endsWith(".txt")
   }
   ```

#### 文件树

文件树(file tree)是一个文件集合，具有 FileTree 类型。它保留了它所包含的文件的目录结构，这意味着文件树中的所有路径都必须有一个共享的父目录。要将文件树转换为平面集合，可以使用 FileTree.getFiles() 方法。下图说明了在复制文件的常见情况下文件树和文件集合之间的区别:

![FileTree和FileCollection](/imgs/FileTree和FileCollection.webp)

创建文件树最简单的方法是将文件或目录传递给 Project.fileTree(java.lang.Object) 方法。这将创建该目录中所有文件和目录的树(但不是基本目录本身)。以下示例演示了如何使用，此外，还演示了如何使用 Ant 样式模式过滤文件和目录：

```groovy
// 基本使用
ConfigurableFileTree tree = fileTree(dir: 'src/main')

// 使用模版语法
tree.include '**/*.java'
tree.exclude '**/Abstract*'

// 使用闭包
tree = fileTree('src') {
    include '**/*.java'
}

// 使用 Map，Map 的定义语法非标准 groovy 语法，由 gradle 扩展实现
tree = fileTree(dir: 'src', include: '**/*.java')
tree = fileTree(dir: 'src', includes: ['**/*.java', '**/*.xml'])
tree = fileTree(dir: 'src', include: '**/*.java', exclude: '**/*test*/**')
```

在 settings.gradle 中，可以设置默认的排除选项，一般不需要我们设置。

```groovy
// 在 settings.gradle 文件中
import org.apache.tools.ant.DirectoryScanner

DirectoryScanner.removeDefaultExclude('**/.git')
DirectoryScanner.removeDefaultExclude('**/.git/**')
```

FileTree 继承自 FileCollection，具备和 FileCollection 类似的操作：

```groovy
// 遍历文件
tree.each {File file ->
    println file
}
// 过滤
FileTree filtered = tree.matching {
    include 'org/gradle/api/**'
}
// 集合操作
FileTree sum = tree + fileTree(dir: 'src/test')
// 深度优先访问元素。element 类型是 FileVisitDetails
tree.visit {element ->
    println "$element.relativePath => $element.file"
}
```

#### 压缩包的文件树

使用 Project.zipTree(java.lang.Object) 和 Project.tarTree(java.lang.Object) 方法解析相应类型的压缩文件文件为文件树结构(请注意，JAR、WAR 和 EAR 文件都是 ZIP 类型的)。这两个方法返回的都是 FileTree。

#### 文件集合的隐式转换

文件集合的隐式转换是特定 task 的功能。Gradle 中的许多对象都具有接受一组输入文件的属性。隐式转换不会发生在任何具有 FileCollection 或 FileTree 属性的任务上(此时显式指定了类型)。如果我们想知道在特定情况下是否发生隐式转换，那么我们需要阅读相关文档(如相应任务的 API 文档)。或者，我们可以通过在构建中明确使用 ProjectLayout.files(java.lang.Object...) 来消除所有歧义。例如，JavaCompile 任务具有 source 属性，该属性定义要编译的源文件。我们可以使用 files() 方法支持的任何类型设置 source 属性的值。

像 source 这样的属性在核心 Gradle 任务中具有相应的方法。这些方法遵循设置值时是新增到集合中，而不是替换集合中的值(是 += 的关系，不是 = 的关系)。这个原则在自定义插件/任务中十分重要。这样可以避免将其他插件/任务的配置覆盖掉。比如 A 插件设置了 javaCompileOptions 的内容，我们的自定义插件 B 也设置了 javaCompileOptions。+= 的模式可以避免我们把 A 插件的配置覆盖掉，导致编译出错。

```groovy
tasks.register('compile', JavaCompile) {
    // 属性的使用方式
    // 会转换成 += 的调用
    // 使用 File 对象指定源码目录
    source = file('src/main/java')
    // 使用字符串指定
    source = 'src/main/java'
    // 使用数组
    source = ['src/main/java', '../shared/java']
    // 使用 FileCollection
    source = fileTree(dir: 'src/main/java').matching { 
       include 'org/gradle/api/**' 
    }
    // 使用闭包
    source = {
        // 使用 src 目录中每个 zip 文件的内容
        file('src').listFiles().findAll {
           it.name.endsWith('.zip')
        }.collect { zipTree(it) }
    }
}

compile {
    // 方法的使用方式
    // 列表
    source 'src/main/java', 'src/main/groovy'
    // 文件对象
    source file('../shared/java')
    // 文件数组
    source { file('src/test/').listFiles() }
}
```

### Gradle 文件类

Gradle 定义了更强类型的类来表示文件系统的元素：Directory 和 RegularFile。这些类型不应与标准 Java 文件类型(File)混淆，因为它们用于告诉 Gradle 和其他人，我们期望更具体的值，例如目录或非目录的文件(如设备)。

- Directory 和 RegularFile 不建议继承实现。Gradle 提供了两个专门的 Property 子类型来处理：RegularFileProperty 和 DirectoryProperty。 ObjectFactory 具有创建这些属性的方法：ObjectFactory.fileProperty() 和 ObjectFactory.directoryProperty()。

- Directory 和 RegularFile 实例还可以使用 ProjectLayout 提供的方法获取。比如 getProjectDirectory()。而 RegularFile 实例还可以通过 Directory.file 获取

```groovy
abstract class GenerateSource extends DefaultTask {
    // inputs 是个 file
    @InputFile
    abstract RegularFileProperty getConfigFile()

    // outputs 是个 dir
    @OutputDirectory
    abstract DirectoryProperty getOutputDir()

    @TaskAction
    def compile() {
        // 类型 RegularFile
        def inFile = configFile.get().asFile
        logger.quiet("configuration file = $inFile")
        // 类型 Directory
        def dir = outputDir.get().asFile
        logger.quiet("output dir = $dir")
        def className = inFile.text.trim()
        def srcFile = new File(dir, "${className}.java")
        srcFile.text = "public class ${className} { ... }"
    }
}

// 注册任务
tasks.register('generate', GenerateSource) {
    configFile = layout.projectDirectory.file('src/config.txt')
    outputDir = layout.buildDirectory.dir('generated-source')
}

layout.buildDirectory = layout.projectDirectory.dir('output')
```

### 压缩包操作

压缩包文件可以看作一个特殊的文件系统(区别于操作系统的文件系统)。

#### 压缩文件

从 Gradle 的角度来看，将文件压缩实际上更像是一个复制操作，只是目标目录是压缩文件(zip，tar等)而不是系统中的目录(dir)。所以 Gradle 中压缩框架的设计，能够看见 Copy 操作的影子。下图为压缩相关任务的一个继承图：

![Copy任务继承图](/imgs/Copy任务继承图.webp)

使用压缩任务时，我们需要指定存档的目标目录(destinationDirectory)和名称(archiveFileName)，注意不是使用 into() 方法指定了，这两个都是必需的(示例见 packageDistribution 任务)。但是通常在自定义任务中，我们不会看到它们的显式设置，这是因为大多数项目都应用了 Base Plugin(The Base Plugin (gradle.org))。该 Plugin 为这些属性提供了一些默认值。下面一个示例演示了这一点。

下面示例假设了一个常见的场景：将文件复制到压缩包的指定子目录中。例如，假设我们要将所有的 PDF 打包到压缩包根目录中的 docs 目录中，但压缩包中不存在此 docs 目录，因此我们必须将其创建成为压缩包的一部分。要达成此效果，我们需要为 PDF 添加一个 into() 声明：

```groovy
plugins { id 'base' }

version = "1.0.0"

tasks.register('packageDistribution', Zip) {
    // archiveFileName = "my-distribution.zip"
    // destinationDirectory = layout.buildDirectory.dir('dist')
    from(layout.buildDirectory.dir("toArchive")) {
        exclude "**/*.pdf"
    }

    from(layout.buildDirectory.dir("toArchive")) {
        include "**/*.pdf"
        // copy 到压缩包的 docs 子目录，目录不存在时，会创建目录
        into "docs"
    }
}
```

#### 解压文件

解压压缩包是将文件从压缩包中复制到系统目录中，或者复制到另一个压缩包中。 Gradle 通过提供一些包装函数来实现这一点，这些函数使压缩包可以被视作文件树：

- Project.zipTree(java.lang.Object)

- Project.tarTree(java.lang.Object)

与普通 Copy 任务一样，可以通过 filters 控制哪些文件被解压缩，可以在文件解压缩时重命名文件，可以通过 eachFile() 遍历压缩包中的每个文件。
   
   - 注意：解压时，可以忽略掉空目录；不忽略空目录时，即使可以包含空目录，空目录的目标路径也不能改变(历史遗留问题，见 [Issue 2940](https://github.com/gradle/gradle/issues/2940))

```groovy
tasks.register('unpackLibsDirectory', Copy) {
    // zipTree() 同样适用于 jar、war 等文件
    from(zipTree("src/resources/thirdPartyResources.zip")) {
        include "libs/**"  // 仅解压压缩包中 libs 目录下的文件
        eachFile { fcd ->
            fcd.relativePath = new RelativePath(
                true, 
                fcd.relativePath.segments.drop(1)
            )  // 文件路径中删除 libs 段，将文件路径重新映射到目标目录
        }
        includeEmptyDirs = false  // 解压时，忽略掉空目录
    }
    into layout.buildDirectory.dir("resources")
}
```

#### 压缩包名称

Gradle 支持创建 ZIP 和 TAR 文件，并且进一步扩展实现了 Java 的 JAR、WAR 和 EAR 格式——Java 的产物格式其实都是 ZIP。每一种格式都有相应的任务类型来创建它们：Zip、Tar、Jar、War 和 Ear。这些格式都以相同的方式工作并且都基于 CopySpec，就像复制任务一样。

了解了基于规范的存档名称，可以使我们免于一直配置目标目录(destinationDirectory)和存档名称(archiveFileName)。

AbstractArchiveTask.getArchiveFileName() 提供了默认存档名称模式：[archiveBaseName]-[archiveAppendix]-[archiveVersion]-[archiveClassifier].[archiveExtension]。可以在任务中分别设置这些属性中的每一个。我们可以在 AbstractArchiveTask 的 API 文档中找到所有任务属性。

Base Plugin 提供了部分默认值：

- 为 archiveBaseName 设置了项目名称

- 为 archiveVersion 设置了项目版本

- 为 archiveExtension 设置压缩包类型

- 其他属性的值没有提供

```groovy
// 任务输出结果：customName-1.0.zip
tasks.register('myCustomZip', Zip) {
    // 覆盖了 archiveBaseName 的值
    archiveBaseName = 'customName'
    from 'somedir'

    doLast {
        println archiveFileName.get()
    }
}
```

```groovy
plugins {
    id 'base'
}

version = 1.0
// tag::base-plugin-config[]
base {
    // 为所有任务指定 archivesName
    archivesName = "gradle"
    distsDirectory = layout.buildDirectory.dir('custom-dist')
    libsDirectory = layout.buildDirectory.dir('custom-libs')
}
// end::base-plugin-config[]

tasks.register('myZip', Zip) {
    from 'somedir'
}

tasks.register('myOtherZip', Zip) {
    archiveAppendix = 'wrapper'
    archiveClassifier = 'src'
    from 'somedir'
}

tasks.register('echoNames') {
    doLast {
        println "Project name: ${project.name}"
        println myZip.archiveFileName.get()
        println myOtherZip.archiveFileName.get()
    }
}
// 任务输出结果：
// Project name: archives-changed-base-name
// gradle-1.0.zip
// gradle-wrapper-1.0-src.zip
```

#### 可重复的构建

我们有时需要在不同的机器上逐字节地重新创建完全相同的压缩包。我们希望源代码相同时，构建结果无论何时何地都会产生相同的结果。

要达到这种效果，有一定的挑战性，因为压缩包中文件的顺序受底层文件系统的影响。每次从源代码构建 ZIP、TAR、JAR、WAR 或 EAR 时，压缩包中文件的顺序可能都会发生变化。具有不同时间戳的文件也可能会导致归档在构建之间存在差异。

但是好在 Gradle 内置的所有 AbstractArchiveTask（例如 Jar、Zip）任务都支持生成可重现的压缩。例如，要使 Zip 任务可重现，您需要将 Zip.isReproducibleFileOrder() 设置为 true，并将 Zip.isPreserveFileTimestamps() 设置为 false。为了使构建中的所有存档任务可重现，需要将以下配置添加到构建文件(build.gradle)中：

```groovy
tasks.withType(AbstractArchiveTask).configureEach {
    preserveFileTimestamps = false // 不保存时间戳
    reproducibleFileOrder = true
}
```

## Gradle properties 说明

### 属性分类

注：官方文档地址：[Build Environment (gradle.org)](https://docs.gradle.org/current/userguide/build_environment.html)

gradle 中，property(属性)主要是用于定义传递值(比如统一管理版本号)。

Gradle 支持 4 种 Properties, 这三种 Properties 的作用域和初始化阶段都不一样：

#### System Properties

1. System Properties 也叫 Root Project Properties，可以看作根项目属性。可通过 根项目/gradle.properties 文件、环境变量 或 命令行 -D 参数 设置

2. 可在 setting.gradle 或 build.gradle 中动态修改，在 setting.gradle 中的修改对 buildscript 配置块可见

3. System Properties 对所有工程可见，不建议在 build.gradle 中修改

4. 多子工程项目中，子工程的 gradle.properties 会被忽略掉，只有 root 工程的 gradle.properties 有效

示例代码：

```groovy
# 注释省略，想看注释，请新建项目查看
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
--warning-mode=all
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
org.gradle.daemon=true
```

#### Project Properties

1. Project Properties 也可理解成 Child Project Properties，子工程属性。可通过 根项目/模块工程/gradle.properties 文件，环境变量 或 命令行 -P 参数 设置

2. 可在 build.gradle 中动态修改，但引用不存在的 project properties 会立即抛错

3. 动态修改过的 project properties 对 buildscript 配置块中不可见

示例代码：

```groovy
# 定义编译后的 aar 的 maven pom 信息
GROUP=com.well.android.test
ARTIFACT=test-ui
VERSION=1.0.0
```

#### Project ext properties

1. 项目扩展属性，可在项目的 build.gradle 中声明和使用，本工程和子工程可见。

2. 不能在 setting.gradle 中访问

3. ext 的 DSL 由接口类 ExtraPropertiesExtension 定义。

4. 通常，我们是定义根项目的 ext 属性。在根项目的 build.gradle 文件的 buildscript 中定义。

```groovy
// 根项目的 build.gradle 文件
buildscript {
    // 方式 1：
    ext {
        COMPILE_SDK_VERSION = 30
        BUILD_TOOL_VERSION = '30.0.2'
        MIN_SDK_VERSION = 21
        TARGET_SDK_VERSION = 30
        println("MIN_SDK_VERSION:${MIN_SDK_VERSION}")
    }
}
// 方式 2：
// properties 的使用在下面说明
ext.enableLocalDev = properties.get("localDev") == "true"
```

#### Custom properties

Custom properties，即自定义 properties。我们可以自定义一个 properties 文件，然后手动读取里面的属性并赋值。

以 local.properties 文件为例。每个 Android 项目中都会有一个 local.properties 文件，但是该文件并不会纳入到 git 管理中，因为这是 Android Studio(IDEA) 动态生成的文件。如果我们不做改动，那么里面默认定义了 sdk.dir 属性，该属性表示 Android SDK 的目录。

我们可以在 local.properties 中额外定义属性，然后手动读取它。如果我们希望部分项目中定义的变量不放入到 git 仓库中(比如 release 包签名路径，比如私有 maven 仓库账号密码)，那么就可以放入到 local.properties 文件中定义(gradle.properties 文件会跟随 git 管理)。

比如我们在 local.properties 文件中定义个 isAPK 变量：

![local_property_文件定义属性变量](/imgs/local_property_文件定义属性变量.webp)

定义了属性后，我们就可以在项目根目录的 build.gradle 文件中读取值：

```groovy
// 文件：Root Project 的 build.gradle 文件
buildscript {
    Properties properties = new Properties()
    // 加载 local.properties 文件
    properties.load(project.rootProject.file('local.properties').newDataInputStream())
    // 读取 isAPK 属性，ext 为 Root Project 的 ext
    ext.isAPK = properties.get("isAPK") == "true"
}
```

对面代码，需要解释以下几个点：

1. buildscript 优先于 build.gradle 中的其他内容执行，注意变量的使用范围

2. properties 文件，properties 文件可以是任意名称，并且不关心是否受 git 管理。可以跟 git，也可以被 git 忽略

3. properties 文件中定义的键值对的值，默认是 String 类型的，无需再单独加引号

Custom properties 可以读取后，再赋值给 Project ext properties。这样可以避免每次使用时都去读取 properties 文件。

### 懒加载

Gradle 提供了惰性属性(Lazy properties)(属性的懒加载)，该属性会先声明而不运算值，直到真正使用属性时才去运算确定值。这样做为 build script 和 plugin developer 提供了三个主要好处：

- 开发者可以将 Gradle Model 类写在一起，而不需要管属性的值什么时候确定。例如，我们想要根据一个扩展属性(extension property)的源目录属性设置任务的输入源文件，但在构建脚本或其他插件配置它之前，此扩展属性值是未知的。此时使用惰性属性，就可以在需要的时候拿到值而不出现问题

- 开发者可以将任务的输出属性(outputs)连接为其他任务的输入属性(inputs)，Gradle 会根据此连接自动确定任务的依赖关系。属性实例会携带有哪个任务(如果有)赋予它们值的信息。开发者不需要处理同步任务依赖和配置更改之间的同步

- 构建作者可以避免在配置阶段(configuration 阶段)进行资源密集型工作，这会对构建性能产生很大影响。例如，当 value 需要通过解析文件来获取，但仅在运行阶段使用时，使用惰性属性可以仅在运行阶段才解析文件，而不是在配置阶段。这意味着配置阶段执行效率的提高，时间的缩短。

Gradle 的懒加载相关类如下：

![Property相关类](/imgs/Property相关类.webp)

#### 基础说明

Gradle 使用以下两种接口来表示属性的懒加载：

- Provider 代表一个只读的值

- Provider.get() 获取当前的值

- 可以使用 Provider.map(Transformer) 从另一个 Provider 创建新 Provider

- Provider 有很多实现类、扩展类，可以在任何需要使用 Provider 的地方使用

Property 代表了可读写的值

- Property 继承了 Provider 接口

- Property.set(T) 为属性设置值

- Property.set(Provider) 指定属性的值来自于另一个 Provider。这可以将 Provider 和 Property 两个实例连接在一起

- ObjectFactory.property(Class) 可以创建一个 Property

- Gradle 会为任务实现中的每个 Property 类型的属性生成 setter 方法。这些 setter 方法允许使用赋值 (=) 运算符来配置属性，以方便使用

```groovy
// extension 的说明会在自定义 Plugin 中讲解
interface MessageExtension {
    Property<String> getGreeting()
}

abstract class Greeting extends DefaultTask {
    @Input
    abstract Property<String> getGreeting()
    // greeting 的值会传递给 message
    @Internal
    final Provider<String> message = greeting.map { 
        it + ' from Gradle' 
    }
    @TaskAction
    void printMessage() {
        logger.quiet(message.get())
    }
}

// 创建 extension
project.extensions.create('messages', MessageExtension)

// 创建任务
tasks.register("greeting", Greeting) {
    // 关联 extension 和 task 中的 property
    // extension 值的更改，会传递给 task
    greeting = messages.greeting
}

messages {
    // 配置 extension
    greeting = 'Hi'
}
```

注：请不要自定义实现 Provider 及其所有子类，应使用 Gradle 框架提供的工厂类获取 Provider 及其子类。具体的 api 可以看这里：[Lazy Configuration (gradle.org)](https://docs.gradle.org/current/userguide/lazy_configuration.html#lazy_configuration_reference)

- Project.getObjects() >>> ObjectFactory.property(Class)

- ~~ProviderFactory.provider(Callable)~~(不推荐，建议使用 map 方法)

- Provider.map(Transformer)

```groovy
abstract class GenerateSource extends DefaultTask {
    // inputs 是个 file
    @InputFile
    abstract RegularFileProperty getConfigFile()

    // outputs 是个 dir
    @OutputDirectory
    abstract DirectoryProperty getOutputDir()

    @TaskAction
    def compile() {
        def inFile = configFile.get().asFile
        logger.quiet("configuration file = $inFile")
        def dir = outputDir.get().asFile
        logger.quiet("output dir = $dir")
        def className = inFile.text.trim()
        def srcFile = new File(dir, "${className}.java")
        srcFile.text = "public class ${className} { ... }"
    }
}

// 注册任务
tasks.register('generate', GenerateSource) {
    configFile = layout.projectDirectory.file('src/config.txt')
    outputDir = layout.buildDirectory.dir('generated-source')
}

layout.buildDirectory = layout.projectDirectory.dir('output')
```

说明：

- 此示例通过 Project.getLayout()、 ProjectLayout.getBuildDirectory()、 ProjectLayout.getProjectDirectory() 创建表示项目位置和构建目录的 provider

- 使用 DirectoryProperty.getAsFileTree() 或 Directory.getAsFileTree() 可以将 DirectoryProperty 或 Directory 转换为 FileTree，

- 可以使用 DirectoryProperty.files(Object...) 或 Directory.files(Object...) 创建包含目录中的一组文件的 FileCollection 实例

#### 集合懒加载

Gradle 提供了两种惰性属性(lazy property)类型来帮助配置 Collection 属性。它们的工作方式与任何其他 Provider 完全一样，并且就像文件提供程序一样，它们有额外的 model 类：

- 对于 List，该接口称为 ListProperty。可以使用 ObjectFactory.listProperty(Class) 创建新的 ListProperty 并指定元素类型

- 对于 Set，该接口称为 SetProperty。可以使用 ObjectFactory.setProperty(Class) 创建新的 SetProperty 并指定元素类型

Collection 类型的属性允许覆盖整个集合值：

- HasMultipleValues.set(Iterable)

- HasMultipleValues.set(Provider)

或者通过各种 add 方法添加新元素：

- HasMultipleValues.add(T)

- HasMultipleValues.add(Provider)

- HasMultipleValues.addAll(Provider)：添加 Provider 的所有值到集合中

#### 映射懒加载

Gradle 提供了一个惰性 MapProperty 类型来允许配置 Map 值。可以使用 ObjectFactory.mapProperty(Class, Class) 创建 MapProperty 实例

与其他属性类型类似，MapProperty 有一个 set() 方法，可以使用该方法指定属性的值，这些值可以是惰性值

```groovy
abstract class Generator extends DefaultTask {
    @Input
    abstract MapProperty<String, Integer> getProperties()

    @TaskAction
    void generate() {
        properties.get().each { key, value ->
            logger.quiet("${key} = ${value}")
        }
    }
}

def b = 0
def c = 0

tasks.register('generate', Generator) {
    properties.put("a", 1)
    properties.put("b", providers.provider { b })
    properties.putAll(providers.provider { [c: c, d: c + 1] })
}

// 输出的最终结果为2、3
// b = 2
// c = 3
```

#### 属性默认值

当没有为属性设置值时，我们可能希望对要使用的属性指定一些规范(convention)或默认值。此时可以使用 convention() 方法达到这个目的。此方法接受一个值或 Provider，这个值将默认被使用，直到配置了其他值

```groovy
def property = objects.property(String)

// Set a convention
property.convention("convention 1")
println("value = " + property.get())

// Can replace the convention
property.convention("convention 2")
println("value = " + property.get())

property.set("value")
// 一旦设置了值，convention 就被忽略了
property.convention("ignored convention")
println("value = " + property.get())
```

#### final 属性

任务(task)或项目(project)的大多数属性(properties)由插件或构建脚本配置，然后将结果值用于完成一些事情。例如，由插件指定的编译任务的输出目录，可在构建脚本中修改，然后在任务运行时使用这个值。此时我们希望一旦任务开始运行，值就不可以再被修改。增加这种限制，我们可以避免不同使用者使用不同的属性值，进而导致错误。这些使用者可以是如任务操作、Gradle 的最新检查(up-to-date)、构建缓存操作或其他任务。

惰性属性(Lazy properties)提供了几种方法，可以使我们在使用这些方法配置属性值后，禁止属性值再被更改

- finalizeValue() 方法计算属性的 final 值并防止对属性进行进一步更改。当属性的值来自 Provider 时，会向此 Provider 查询其当前值，结果将成为该属性的最终值，并且属性不再跟踪该 Provider 的值。调用此方法还会使属性实例不可修改，当任务开始执行时，Gradle 会自动使任务的属性成为 final，任何进一步更改属性值的尝试都将失败

- finalizeValueOnRead() 方法作用类似，只是在查询属性值之前不计算属性的 final 值。换句话说，该方法根据需要延迟计算最终值，而 finalizeValue() 则立即计算最终值。当该值的计算成本可能很高或可能尚未配置时，我们希望确保该属性的所有使用者在查询该值时得到相同的值，可以使用此方法

#### File 属性

FileCollection、FileTree、RegularFileProperty、DirectoryProperty、ConfigurableFileCollection、ConfigurableFileTree、SourceDirectorySet 等文件相关类，都是懒加载属性。

Gradle 提供了两个专门的 Property 子类型来处理这些类型的值：RegularFileProperty 和 DirectoryProperty。 ObjectFactory 定义了创建这些属性的方法：ObjectFactory.fileProperty() 和 ObjectFactory.directoryProperty()。

DirectoryProperty 还可用于分别通过 DirectoryProperty.dir(String) 和 DirectoryProperty.file(String) 为 Directory 和 RegularFile 创建一个惰性的 Provider。这些方法创建 Provider，其值是相对于创建它们的 DirectoryProperty 的位置计算的。DirectoryProperty 的值发生更改，这些被创建的 Provider 的值会同步更改。

示例可见上文 GenerateSource 任务类的使用

## Gradle 类功能

每个 Gradle 项目都有一个全局唯一的 gradle 对象，该 gradle 对象是 org.gradle.api.invocation.Gradle 的一个实例。我们可以通过 Gradle 接口类的定义，了解 Gradle 的一些知识点。

如图是 Gradle 提供的能力，主要是 gradle 描述相关、项目相关、构建流程相关三块。我们最主要关心的就是和构建流程相关的知识

![Gradle提供的能力](/imgs/Gradle提供的能力.webp)

## Gradle 构建流程

根据官方说明，Gradle 的构建流程主要分为三个阶段：

- Initialization：初始化阶段。此阶段主要是解析执行 settings.gradle 文件，生成 project 对象。具体内容下面讲解

- Configuration：配置阶段。配置阶段主要是与 build.gradle 和 task 有关。此阶段主要是将上个阶段确定的各个 project 对象对应的 build.gradle 文件从上往下执行、解析，确定各个 project 的任务子集、配置 task、以及生成任务图 task graph(或者可以叫做有向无环图(Directed Acyclic Graph (DAG)))。

- Execution：执行阶段。此阶段主要 根据 DAG 执行所有任务的 actions。此时是编译的真正运行时刻，如生成 .class 文件，上传编译结果到 maven 等等。

具体的执行流程如下图：

![Gradle执行流程](/imgs/Gradle执行流程.webp)

我们可以通过 Gradle 提供的构建流程相关方法，hook gradle 构建流程的关键节点。其中 addListener 方法中可以添加的 Listener 类型为：

- BuildListener

- org.gradle.api.execution.TaskExecutionGraphListener

- ProjectEvaluationListener

- org.gradle.api.execution.TaskExecutionListener

- org.gradle.api.execution.TaskActionListener

- org.gradle.api.logging.StandardOutputListener

- org.gradle.api.tasks.testing.TestListener

- org.gradle.api.tasks.testing.TestOutputListener

- org.gradle.api.artifacts.DependencyResolutionListener

需要注意的一点是，我们可以通过打印 gradle 构建流程的详细日志，辅助梳理整个流程：gradle -i :app:assemble。

Gradle 任务执行方式为：

![Gradle任务执行方式](/imgs/Gradle任务执行方式.webp)

## Settings 类功能

因为 Gradle 的初始化阶段和 settings.gradle 文件息息相关，而 settings.gradle 文件又和 Settings 对象一一对应。所以在介绍 Gradle 的初始化流程前，我们需要看下 Settings 类，Settings 接口类的定义如下：

![Settings_API_说明](/imgs/Settings_API_说明.webp)

注：在 project、settings、gradle 中查询某个项目实例时，应注意带上冒号( : )。在 gradle 中，冒号即文件路径分隔符，对应 Linux 下的 /。

### 依赖说明

在一个典型的 Gradle 项目中，依赖管理是重要关注的存在。

- 项目导入第三方依赖通常分为两步：

   - 指定依赖所在仓库，仓库是存放大量依赖的地方

   - 导入目标版本的依赖，依赖可以具有多个不同的版本，我们应选择合适的版本

- 导入的依赖使用涉及两个方面：

   - Gradle 自身所用依赖

   - 目标产物所用的依赖

指定依赖所在仓库，使用的是 repositories 方法；导入目标版本的依赖，使用的是 dependencies 方法。

Gradle 自身使用的依赖，通常是在 .gradle 文件中写 java/groovy/kotlin 代码时用到。依赖信息在 buildScript 中配置，调用 ScriptHandler.repositories() 方法配置仓库信息，调用 ScriptHandler.dependencies() 方法导入相关依赖

在 Android 中，目标产物通常是指 app 或者 aar。因为项目可以模块化，所以目标产物所用的依赖，依赖一般是在模块级别的 build.gradle 中引入的，单仓库信息可以在根项目的 build.gradle 中声明。调用 Project.repositories() 方法配置仓库信息，调用 Project.dependencies() 方法导入模块使用的相关依赖

上述说明可用下面的图片阐述：

![依赖说明](/imgs/依赖说明.webp)

一段依赖配置的典型代码如下：

```groovy
// rootProject 的 build.gradle 文件
buildscript {
    repositories {
        google() // google 中央仓库
        jcenter() // 已废弃，不再使用
        mavenCentral()
        // 阿里云的中央仓库，国外的仓库访问不上时，可使用国内的
        maven{ url 'https://maven.aliyun.com/repository/central'}
        maven{ url'https://maven.aliyun.com/repository/public'}
        maven{ url "https://maven.aliyun.com/repository/google"}
    }

    dependencies {
        // 导入 gradle 需要使用的 android 和 kotlin 插件
        classpath "com.android.tools.build:gradle:7.2.0"
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.6.10'
    }
}

allprojects {
    // 配置 app 所使用的仓库
    repositories {
        google()
        jcenter()
        mavenCentral()
        maven{ url 'https://maven.aliyun.com/repository/central'}
        maven{ url'https://maven.aliyun.com/repository/public'}
        maven{ url "https://maven.aliyun.com/repository/google"}
    }
}
```

```groovy
// app 的 build.gradle 文件
plugins {
    // 应用 android 插件和 kotlin 插件
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
}
dependencies {
    // Kotlin 的相关依赖
    implementation "androidx.core:core-ktx:1.7.0"
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.5.30"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.5.2"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.5.2"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.5.2"

    // Android 的相关依赖
    implementation "androidx.appcompat:appcompat:1.4.1"
    implementation "com.google.android.material:material:1.6.0"
    implementation "androidx.constraintlayout:constraintlayout:2.1.4"
    implementation "androidx.activity:activity:1.4.0"
    implementation "androidx.fragment:fragment:1.4.1"
    implementation "androidx.fragment:fragment-ktx:1.4.1"
    implementation "androidx.legacy:legacy-support-v4:1.0.0"
}
```

### getBuildscript

settings.gradle 文件解析是在初始化阶段就执行的，而项目的 build.gradle 文件在配置阶段执行的。所以根项目中配置的 buildscript 内容，是无法在 settings.gradle 生效的。但是当我们在 settings.gradle 中写 java/groovy/kotlin 代码时，如果想要使用第三方库该怎么办？此时就可以在 settings.gradle 文件中使用 buildscript{} 块，配置仓库和导入对应依赖

### pluginManagement

gradle 最初是没有一个统一的插件存放仓库的，大多数人可能会把插件放到 github 上。而后来官方弄了一个插件仓库，用户可以从该仓库下载插件、或者上传插件到仓库。可以使用 pluginManagement 在 settings.gradle 中配置插件管理，该 block 配合 plugins block 使用。请注意，有 pluginManagement block 时，该 block 必须是 settings.gradle 中的第一个 block。一个常见的使用方式如下：

```groovy
// settings.gradle 文件中
pluginManagement {
    // 此处不指定 plugins，后续引入时需要指定版本号，可选
    plugins {
        // 引入插件
        id 'com.android.application'
        id 'org.jetbrains.kotlin.android' version '1.6.10'
        id 'com.android.library' version '7.2.0' apply false
    }
    // 指定插件解析策略, 可选
    resolutionStrategy {
        eachPlugin {
            if (requested.id.namespace == "com.example") {
                useModule("com.example:sample-plugins:1.0.0")
            }
        }
    }
    repositories {
        maven {url "custom-plugin-repo-url"} // 自定义插件仓库
        gradlePluginPortal() // gradle 官方插件仓库
    }
}
```

应用 plugins block 使用插件：

```groovy
// 使用插件，app 的 build.gradle 文件首行
plugins {
    id 'com.android.application' version '7.2.0'
    id 'org.jetbrains.kotlin.android'
}
```

针对 pluginManagement 和 plugins DSL(Domain Specific Language)的一些说明：

- pluginManagement 的 DSL 由接口类 PluginManagementSpec 定义，plugins 的 DSL 由接口类 PluginDependenciesSpec 定义

- pluginManagement >>> plugins block 为可选项

- 在 pluginManagement >>> plugins block 中，id 是必须声明的，version 和 apply 是可选项。如果在引入插件时没有指定 version，以及设置了插件不生效(apply 值为 false)。则在使用插件时必须设置 version 和 apply

- 在 pluginManagement >>> plugins block 中声明插件后，查看会被默认应用上(apply 值为 true)

### 依赖导入说明

注：关于如何处理大型项目的依赖，可以参考这个指引：[依赖处理](https://docs.gradle.org/current/userguide/structuring_software_products.html#assigning_types_to_components)

在 gradle 中，我们可以使用以下方式导入远程或者本地依赖。其具体方式如图：

![Gradle依赖导入说明](/imgs/Gradle依赖导入说明.webp)

#### allprojects & dependencyResolutionManagement

在 gradle 项目中，当我们导入依赖时，需要先声明依赖所在仓库。在低版本 gradle 项目中，我们通常在 rootProject 的 build.gradle 文件中，使用 allprojects.repositories 块设置仓库：

```groovy
allprojects {
    repositories {
        google()
        mavenLocal()
        maven { url 'https://jitpack.io' }
    }
}
```

但是 gradle 官方建议将仓库的声明统一管理，这样方便本地仓库和远程仓库切换(这在多工程，大型项目中通常很有用)。于是在 6.8 中加入了 dependencyResolutionManagement 语句块，用于在 settings.gradle 中声明依赖仓库。在新版 Android Studio 中，新建项目，默认都是采用这种方式声明仓库。

```groovy
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
```

声明了依赖仓库后，我们就可以使用 dependencies 导入编译好的二进制依赖了。注意：使用 dependencyResolutionManagement 声明了仓库后，就可以不用写 allprojects.repositories 块了。

#### sourceControl

sourceControl 示例见：[sourceControl 的使用](https://stackoverflow.com/questions/63910307/gradle-how-to-define-sourcecontrol-with-sub-path-as-dependency)

- 在 Gradle 中，我们除了可以导入远程的二进制依赖，还可以导入远程 module 源码，在本地编译应用时，编译出一个远程 module。同导入二进制依赖类似，sourceControl 可以声明仓库和指定依赖。sourceControl 块中，使用 gitRepository 方法指定 git 仓库，该 git 仓库可以视作依赖仓库。gitRepository 方法返回的是 VersionControlRepository 接口类。使用该类定义的 producesModule 方法可以指定导入的 module 依赖(字符串形式："group:moduleName")。使用 setRootDir 方法可以指定 module 在 git 仓库中的相对位置。故 sourceControl 的一个常见用法为：

   ```groovy
   // rootProject/settings.gradle 文件
   sourceControl {
      gitRepository("https://github.com/google-ar/arcore-android-sdk.git") {
          producesModule("com.google.ar.core.examples:app")
          rootDir = "samples/hello_ar_java"
      }
   }
   ```

   其中 https://github.com/google-ar/arcore-android-sdk.git 是一个远程 git 仓库，我们需要导入该仓库下的 app 模块，该模块在 rootDir/samples/hello_ar_java 目录下。

- sourceControl 可等价于导入远程依赖，如下，dependencies 导入远程二进制依赖，可与 sourceControl 导入远程源码依赖等价：

```groovy
// 代码 1
sourceControl {
   gitRepository("https://github.com/gradle/native-samples-cpp-library.git") {
       producesModule("org.gradle.cpp-samples:utilities")
   }
}

// 上面 1 的代码，等价于下面的代码
dependencies {
   implementation 'org.gradle.cpp-samples:utilities:1.0'
}
```

#### include & includeBuild

gradle 支持多 module(或者叫 child project) 工程构建，include 和 includeBuild 方法都是在多 module 工程构建中使用。其说明如下：

- include 在单工程中使用，该工程可以包含多个 module，每个需要加入构建的 module 都需要在 settings.gradle 中使用 include 声明，表明该 module 需要加入到构建中：

```groovy
// rootProject 的 settings.gradle 文件中
// app 模块和 libTest 模块加入到构建中
rootProject.name = "TestApp"
include ':app'
include ':libTest'
```

- includeBuild 在跨工程(官方的名称翻译为"复合构建")中使用。例如本地 app 工程 依赖本地 lib 工程下的 log、net 模块。这两个 module 会被编成 maven 依赖包，app 以远程依赖的形式导入。但是如果 log、net 模块出了 bug，此刻想要修复，每次都得编包、同步、编译，相当麻烦(如果遇到 app 工程存在缓存冲突，则每次还得清缓存，会花费相当多的时间)。此刻我们可以考虑使用 includeBuild，将 lib 工程导入 app 工程中，再使用具体的依赖替换规则，将 log、net 的远程依赖替换为 lib 工程下的 module(即使用本地 module，不使用远程依赖)，这样我们可以保证编译速度，提高效率，大大节省了时间

   includeBuild 方法使用时，可以传入一个 ConfigurableIncludedBuild 的闭包，该闭包包含一个 dependencySubstitution 的方法，该方法又可以传入一个 DependencySubstitutions 的闭包，用于编写依赖替换规则

   具体使用说明如下：

   1. 定义数据结构。此处以在 local.properties 文件中定义为例(可以是其他任意文件，只要保证能正常读取即可)。
      1. INCLUDE_BUILD 是个 json 数组，代表着需要被导入的其他工程的信息，每个被导入的工程都是个 json 对象

      2. enabled 表示对于该工程，includeBuild 是否生效

      3. rootPath 表示被导入的工程的根目录

      4. modules 表示需要被替换的 module 的信息，name 表示 lib 工程中对应的 module 名，maven 表示 app 模块中需要被替换掉的远程依赖

      ```groovy
      # file name: local.properties
      INCLUDE_BUILDS=[\
        {\
           "enabled":true,\
           "modules": [\
               {\
                   "name": "log",\
                   "maven":"com.test.android:log"\
               },\
               {\
                   "name": "net",\
                   "maven":"com.test.android:net"\
               }\
           ],\
           "rootPath":"../lib"\
        }\
      ]
      ```

   2. 在定义了数据结构后，我们可以在 settings.gradle 中进行实现。

   ```groovy
   // settings.gradle 文件中
   dealIncludeBuild()

   import groovy.json.JsonSlurper
   void dealIncludeBuild() {
       // 1. 加载 local.properties 文件
       File propertyFile = new File(rootDir.getAbsolutePath() + "/local.properties")
       properties.load(propertyFile.newDataInputStream())
       // 2. 加载我们定义的数据
       def includeBuilds = properties.getProperty('INCLUDE_BUILDS')
       if (includeBuilds == null || includeBuilds == "") {
           return
       }
       def jsonSlurper = new JsonSlurper()
       def localProjects = jsonSlurper.parseText(includeBuilds)
       // 遍历需要被 includeBuild 的项目
       for (localProject in localProjects) {
           if (localProject.enabled != true) {
               continue
           }
           includeBuild(localProject.rootPath) {
               // 替换对应的依赖
               dependencySubstitution {
                   localProject.modules.each { itt ->
                       substitute module(itt.maven) with project(":${itt.name}")
                   }
               }
           }
       }
   }
   ```

   3. 在定义了上述逻辑之后，我们就可以自由控制 includeBuild 是否生效了。如果 local.properties 文件中没有定义 INCLUDE_BUILDS 结构，或者 enable 为 false，那么 app 会使用 log、net 的远程 maven 依赖，否则使用 lib 工程下的本地 module

- 对于 include 和 includeBuild，还有几点说明如下：

   - 虽然 include 导入的是本工程的 child project，includeBuild 导入的是跨工程的 project，但这并不是绝对的。对于一个 project 导入时应使用 include 还是 includeBuild，最本质的特点是看该 project 是否具有 settings.gradle 文件。如果工程具有 settings.gradle 文件，则其他工程在导入它时，就应该使用 includeBuild，否则应使用 include。

   - includeBuild 并不会导入 module 的配置信息。比如 lib 工程下 net 模块如果以远程依赖的方式依赖了 okhttp，那么在 includeBuild 到 app 工程时，okhttp 的依赖信息并不会传入 app 工程，需要 app 工程在 dependencies 中再导入一次。

#### 总结

1. include、includeBuild、sourceControl 和 dependencies 有极大的相似性

   - nclude 是以本地单工程源码的形式导入 module

   - includeBuild 是以本地跨工程源码的形式导入 module

   - sourceControl 是以远程仓库源码的形式导入 module

   - dependencies 是以远程二进制依赖的形式导入 module

2. includeBuild、sourceControl 导入的内容，都应视作仓库，而非某个具体的依赖，具体生效的依赖需要根据相应的依赖替换规则确定。而 dependencies 中导入的内容，可以看作是某个具体的依赖。

## Task 类功能

Gradle Task 功能众多，本文将按照以下要点进行讲解。

![Task类讲解](/imgs/Task类讲解.webp)

### task 含义

Task 可以翻译为任务，是我们使用 gradle 的过程中的一个核心类。Task 代表构建的单个原子工作(原子性意味着不可再分割)，如编译 classes 或生成 javadoc。

每个 task 都属于一个 project。可以使用 org.gradle.api.tasks.TaskContainer 类的各种方法来创建和查找 task 实例(可以是 Gradle 内置类的实例，也可以是我们自定义 task 类的实例)。例如，使用 org.gradle.api.tasks.TaskContainer.create(String) 方法创建一个具有给定名称的空 task。当然，也可以在 build.gradle 文件中使用 task 关键字创建任务。如下面的代码：

```groovy
// 创建的 task 的名称为 myTask
task myTask
// 创建 myTask，创建时，configuration 阶段使用闭包中的代码配置 task
task myTask { configure closure }
// 创建的 myTask，实例类型为 someType(如 DefaultTask)
// 不推荐这种语法
task myTask(type: SomeType)
task myTask(type: SomeType) { configure closure }
```

每个 task 都有一个 name，在其所属的 project 中唯一，并且每个 task 都有一个完全限定的路径(绝对路径)，该路径在所有 project 中的所有 task 中唯一。路径是所属 project 的路径和 task 名称的拼接。路径元素使用“:”字符分隔。


#### 语法解释

gradle 生成的代码中，clean 代码的语法简直是四不像，理解起来很困难。[Gradle 创建 Task 的写法不是 Groovy 的标准语法吧？](https://cloud.tencent.com/developer/article/1818133) 这篇文章已对这个语法做了解释，故不推荐下面示例的这种写法

```groovy
task clean(type: Delete) {
    delete rootProject.buildDir
}
```

### API 说明

#### Task API 说明

![Task_API](/imgs/Task_API.webp)

#### TaskContainer API 说明

![TaskContainer_API](/imgs/TaskContainer_API.webp)

### task 的描述

描述一个 task，可以用 name，group，description，path，type。

- name 为任务的名称，可以唯一标识一个任务，如 help 任务

- description 为任务的描述，此信息对 gradle 没什么用，主要是方便人的理解

- group 用于将任务聚合起来。比如下图的 build 和 help 就是不同的 group

   ![Task_Group_实例](/imgs/Task_Group_实例.webp)

- path 为任务的位置。此值可以不用设置，创建任务后，使用 [:projectName:]taskName 即可找到任务，当在 project 内查找任务时可以省略 project 名

- type 表示任务的实际类型，通常是 Class，比如 Copy.class，Zip.class

```groovy
// task name 是 publish
task publish(type: Copy) {
    from "sources"
    into "output"
}

configure(publish) {   
    group = 'Publishing'
    description = 'Publish source code to output directory'
}
```

### task 的例子

我们可以自定义实现 task，也可以使用 Gradle 内置的 task。它们都有不同的使用目的。此处简单举几个例子聊聊。

#### finalizer task

当目标任务准备运行时，它的 Finalizer 任务会自动添加到相关任务图中。无论目标任务执行失败或着目标任务被认为是最新(up-to-date)的，Finalizer 任务都会执行。Finalizer 任务的此种特性在某些场景下十分有用。比如构建无论失败还是成功，资源都必须清理，此时可以使用 Finalizer 任务。

使用 Task.finalizedBy 方法添加目标任务执行结束后立即执行的对应任务，被添加的任务的执行顺序是无序的

#### lifecycle task

Lifecycle 任务是本身不工作的任务。它们通常没有任何任务 actions。他们仅代表构建执行的几个阶段。Gradle Base Plugin 定义了几个标准的生命周期任务，例如 check、assemble、build。所有的核心编程语言插件，如 Java 插件、Kotlin 插件，都继承了 Base Plugin，因此它们具有相同的基本生命周期任务集。

除非 Lifecycle 任务有 actions，否则它的结果是由它依赖的任务决定的。如果 Gradle 执行了这些依赖任务中的任何一个，则该 Lifecycle 任务都将被视为 EXECUTED。如果所有任务依赖项都是UP-TO-DATE，SKIPPED 或者 FROM-CACHE，则生命周期任务将被视为 UP-TO-DATE。如下图，assembleDebug/assembleRelease 任务的任意一个执行完成，assemble 任务就算执行完成。

- check：使用 check.dependsOn(task) 方法将验证任务与 Lifecycle 任务关联，比如在编译 app 前检查签名

- assemble：使用 assemble.dependsOn(task) 方法，将生成目标产物的任务与此 Lifecycle 任务关联。比如 jar 任务生成 Java libraries

- build：依赖于 check、assemble 任务。该任务旨在构建一切，包括运行所有测试任务、生成目标产物和生成文档。应尽量少将任务直接与 build 任务关联，因为 check 和 assemble 任务通常更合适

![lifecycle_task](/imgs/lifecycle_task.webp)

#### other task

Gradle 还内置了其它很多用途的 task，想要了解具体的用途和如何使用，可以查阅 Gradle 的 api 文档说明。比如 File 任务、Download 任务、Exec 相关的任务、Test 任务、Sign 任务等等。

### task 的定位

每个 task 都属于一个 project，一个 project 可以包含多个 task，这些 task 都存放在 project 的 task container 中。TaskContainer 是 Collection 的一个实现类，TaskContainer 具有的能力，是其本身及其父类定义的。TaskContainer 简要的继承关系如下：

![TaskContainer继承图](/imgs/TaskContainer继承图.webp)

想要从 TaskContainer 中找到我们需要的 task 示例(或 task provider)，我们主要使用以下几种方式：

![task定位方式](/imgs/task定位方式.webp)

使用方式如下：

```groovy
tasks.withType(Copy.class).forEach {
    // ....
}
tasks.matching { it.class == Copy.class }.forEach {
    // ....
}
def task = tasks.findByName("assembleDebug")
// tasks.getAt("assembleDebug") 等价于 tasks["assembleDebug"]
def task = tasks["assembleDebug"]
def task = tasks.findByPath(":app:assembleDebug")
```

### task 的创建

#### 创建方式

Gradle 中，任务创建主要有两种方式：实时创建和延后创建(懒加载)。

- 使用 create 创建的 task，会在代码执行到时(此时任务还没运行)立即创建 task 的实例。即使用 create 相关方法实时创建任务实例。

- 而使用 register 创建的 task，不会在代码执行到时立即创建 task 的实例。该方式只是提供一个 provider，只有等到 task 真正运行时，才会创建任务的实例。即使用 register 相关方法延迟创建任务实例(懒加载)。register 相关 api 属于 Gradle 定义的 Task Configuration Avoidance APIs。

```groovy
// 返回的是 Provider<Task> 的实例
def hello = tasks.register('hello') {
    doLast {
        println 'hello'
    }
}
// 返回的是 Provider<Copy> 的实例
def copy = tasks.register('copy', Copy) {
    from(file('srcDir'))
    into(buildDir)
}
// 返回的是 task 的实例
task myTask { configure closure }
```

#### 任务类型

任务的分类方式有很多种，但都可以归纳为两类：Gradle 内置任务或者自定义任务。前者如 Copy/Delete 等任务，后者则是我们继承了 Task 类实现的自定义类。自定义任务有很多指的深入的点，比如属性配置、增量构建、构造函数传参等等。此处仅简单的说明下构建函数传参。

##### 构造函数传参

与在创建后配置 Task 的可变属性相反，我们可以通过 Task 类的构造函数传递参数不可变值(形如 Kotlin 中的 val)。使用步骤如下：

1. 使用 @javax.inject.Inject 注解相关的构造函数

2. 创建任务时，在参数列表的末尾传递构造函数参数

注意：在任何情况下，向构造函数传递的值都必须是非空的。如果尝试传递空值，Gradle 将抛出 NullPointerException，以指明哪个值为空

```groovy
abstract class CustomTask extends DefaultTask {
    final String message
    final int number

    @Inject
    CustomTask(String message, int number) {
        this.message = message
        this.number = number
    }
}
tasks.register('myTask', CustomTask, 'hello', 42)
```

#### 任务配置

我们编写 task 的创建代码时，应注意 Configuration 和 Execution 两个阶段。定义任务时，我们使用的闭包为配置闭包(代码在 Configuration 阶段执行)，不是运行闭包(代码在Execution 阶段执行)。如果想要代码在运行阶段执行，则需要使用 doLast 和 doFirst 等方法。方法传入的闭包，会加入到 task 的 actions 列表中，actions 列表会在 Execution 阶段执行。

Task Actions 可以翻译为任务动作。一个 task 由一连串的 action 组成。执行 task 时，调用 Action.execute 方法，依次执行每个action。

- 可以通过调用 doFirst(Action) 或 doLast(Action) 向 task 添加 action。

- Groovy 闭包也可视作 action。可以通过调用 doFirst(Closure) 或 doLast(Closure) 将 action 闭包添加到 task。

- 执行 action 时，可以抛出 2 个特殊异常以中止执行当前 action，并继续接下来的流程，而不会导致构建失败。

   - action 可以通过抛出 org.gradle.api.tasks.StopActionException 中止 action 的执行并继续执行 task 的下一个 action。

   - action 可以通过抛出 org.gradle.api.tasks.StopExecutionException 中止 task 的执行并继续执行下一个 task。

使用这些异常可以让我们拥有特定条件下，跳过任务执行或跳过部分任务执行的能力

```groovy
tasks.register("test") {
    println "代码运行在 configuration 阶段"
    doLast {
        println "代码运行在 execution 阶段"
    }
}
```

注：Groovy 的闭包有个解析顺序(this, owner, delegate)，可以调用闭包的 setResolveStrategy 方法更改闭包的默认的解析顺序。可以给闭包设置 delegate(形如代码：closure.delegate = project)。

##### 任务依赖

一个 task 可能依赖于其他 task，也可能被安排为始终在另一个 task 之后运行。Gradle 会确保在执行 task 时，所有 task 的依赖项和排序规则都生效，以确保所有 task 的正确执行。

- 定义任务依赖，通常需要用到任务名，如果某个任务依赖的是其他项目的任务，则需要跟进一步，使用 projectName + taskName 的形式：

   ```groovy
   // 示例 1：定义两个任务之间的依赖
   project('project-a') {
       tasks.register('taskX')  {
           // 如果是其他项目的任务，可以在任务名前指定项目名
           dependsOn ':project-b:taskY'
           doLast {
               println 'taskX'
           }
       }
   }

   project('project-b') {
       tasks.register('taskY') {
           doLast {
               println 'taskY'
           }
       }
   }
   ```

- 除了使用 task 实例定义任务之间的依赖以外，还可以使用 TaskProvider 定义任务之间的依赖

   ```groovy
   // 示例 2：使用 TaskProvider 定义两个任务之间的依赖
   def taskX = tasks.register('taskX') {
       doLast {
           println 'taskX'
       }
   }

   def taskY = tasks.register('taskY') {
       doLast {
           println 'taskY'
       }
   }

   taskX.configure {
       dependsOn taskY
   }
   ```

- 可以使用 lazy block 定义任务依赖，通常我们使用 Gradle Provider 代表 lazy block。解析时 lazy block 会被传递给正在确定自己依赖的任务。lazy block 应返回单个任务(single task)或任务对象的集合(tasks' collection)，这些返回值会被视为任务的依赖

   ```groovy
   // // 示例 3：使用 lazy block 定义两个任务之间的依赖
   def taskX = tasks.register('taskX') {
       doLast {
           println 'taskX'
       }
   }

   // Gradle Provider 代表  lazy block
   taskX.configure {
       dependsOn(provider {
           tasks.findAll { task -> task.name.startsWith('lib') }
       })
   }

   tasks.register('lib1') {
       doLast {
           println('lib1')
       }
   }

   tasks.register('lib2') {
       doLast {
           println('lib2')
       }
   }

   tasks.register('notALib') {
       doLast {
           println('notALib')
       }
   }
   ```

可以使用以下方法定义依赖项和排序规则：

- 使用 dependsOn(Object...) 方法或 setDependsOn(Iterable) 方法添加对另一个 task 的依赖。简单的讲，就是指定在 taskA 之前应执行的任务

- 使用 finalizedBy 方法添加某个任务执行结束后立即执行的任务，被添加的任务的执行顺序是无序的。简单的讲，就是指定在 taskA 之后应执行的任务

上述方法的参数 Object 可以使用以下任何类型：

- 一个用于表示 task 路径或名称的 String、CharSequence 或 groovy.lang.GString。相对路径表示相对于当前项目的 task。也可以指定其他 project 中的 task。

- 一个 task 对象

- 一个 TaskDependency 对象

- 一个 org.gradle.api.tasks.TaskReference 对象

- 一个 Buildable 对象

- 一个 org.gradle.api.file.RegularFileProperty 或 org.gradle.api.file.DirectoryProperty 对象

- 一个 Provider 对象。对象的 value 可以是此处列出的任何类型

- 一个 Iterable、Collection、Map 或数组对象。对象的值可以是此处列出的任何类型。iterable、collection、map、array 的元素可以递归包含

- 一个 Callable 对象。call() 方法返回的值可以是此处列出的任何类型。它的返回值可以递归包含。返回 null 会被视为空 Collection。

- 一个 Groovy Closure 或者 Kotlin function，闭包可以将 Task 作为参数。返回的值可能是此处列出的任何类型。它的返回值可以递归包含。返回 null 会被视为空 Collection。

- **除上述类型外的其他任何类型都会被视为错误**

##### 任务排序

指定 2 个任务的执行顺序，而不在 2 个任务之间引入显式依赖关系，在下列场景中很有用。

- 固定任务执行顺序：例如 'build' 任务永远不会在 'clean' 任务之前运行

- 在构建(build)之前运行构建验证：例如在构建 release 包之前验证是否拥有正确的签名

- 在运行“耗时任务”之前运行“快速任务”，以更快地获得反馈。例如单元测试任务应在集成测试任务前运行

- 收集特定类型任务执行结果的任务：例如"测试报告任务"包含了所有执行了的"测试任务"的结果输出

任务排序和任务依赖之间的主要区别在于，排序规则不会影响将执行哪些任务，只会影响它们的执行顺序。即不管有没有排序规则，我们都可以在没有 taskB 的情况下执行 taskA，反之亦然。

- taskA 和 taskB 可以独立。排序规则仅在两个 task 都执行时才有效

- 运行时如果指定了 --continue，taskB 在 taskA 执行失败的情况下仍然可能会执行

有两种指定任务顺序的方式："must run after" 和 "should run after"。使用 mustRunAfter(Object...)、setMustRunAfter(Iterable)、shouldRunAfter(Object...)和 setShouldRunAfter(Iterable) 指定 task 之间的排序。

- 当使用 "must run after" 排序规则时，我们指定了只要 taskA 和 taskB 都运行，则 taskB 必须始终在 taskA 之后运行。代码表达为：taskB.mustRunAfter(taskA)。

- "should run after" 排序规则与 "must run after" 类似，但不那么严格。我们应该在”指定排序顺序有益但不是必须项“的情况下使用 "should run after" 排序规则，它会在两种情况下被忽略。

   - 使用该规则时，如果引入了排序循环(你在我之后，我在你之后)，则该规则被忽略。

   - 任务的并行执行启用时，一个任务如果除了 "should run after" 依赖之外，其余所有依赖关系都已经确定。那么无论这个任务的 "should run after" 依赖任务是否已经运行，它都会运行。

   ```groovy
   // 出现了依赖循环，则 should run after 规则被忽略
   def taskX = tasks.register('taskX') {
       doLast {
           println 'taskX'
       }
   }
   def taskY = tasks.register('taskY') {
       doLast {
           println 'taskY'
       }
   }
   def taskZ = tasks.register('taskZ') {
       doLast {
           println 'taskZ'
       }
   }

   taskX.configure { dependsOn(taskY) }
   taskY.configure { dependsOn(taskZ) }
   taskZ.configure { shouldRunAfter(taskX) }

   /**
    * 执行 gradle -q taskX 命令，打印结果如下
    * taskZ
    * taskY
    * taskX
    */

   // taskZ 之前并没有打印 taskX，说明 should run after 没有生效
   ```

### task 的忽略

Gradle 提供了几种忽略任务(跳过任务执行)的途径：

![task忽略](/imgs/task忽略.webp)

#### 使用 onlyIf 方法

我们可以使用 onlyIf() 方法将允许任务执行的条件附加到任务中，执行条件在任务即将执行之前解析。可以使用闭包提供执行条件。只有当执行条件解析为 true 时，才会执行任务。闭包作为参数传递给任务，如果任务需要执行，则返回 true，如果需要跳过任务，则返回 false。

```groovy
// 执行 gradle hello -PskipHello 命令时，任务会被跳过
def hello = tasks.register('hello') {
    doLast {
        println 'hello world'
    }
}

hello.configure {
    onlyIf { !project.hasProperty('skipHello') }
}
```

#### 使用 StopExecutionException

跳过任务的逻辑除了用闭包来表达，还可以使用 StopExecutionException，Gradle 默认导入了该类。如果某个 action 抛出此异常，则跳过该 action 以及该任务的任何后续 action 的进一步执行。但 build 还是会继续执行下一个任务。

```groovy
def compile = tasks.register('compile') {
    doLast {
        println 'We are doing the compile.'
    }
}
compile.configure {
    doFirst {
        if (true) {
            throw new StopExecutionException()
        }
    }
}
tasks.register('myTask') {
    dependsOn('compile')
    doLast {
        println 'I am not affected'
    }
}
```

此功能会很有用，如果 Gradle 提供的内置任务预置了相关逻辑，那么它允许我们对这些内置任务的内置 actions 添加控制这些 action 执行的条件。

#### 设置 enabled flag

每个任务都有一个默认为 true 的 enabled flag(enable and disable tasks)。将其设置为 false 会阻止任务所有 action 的执行。disabled 的 task 将被标记为 SKIPPED

```groovy
def disableMe = tasks.register('disableMe') {
    doLast {
        println 'This should not be printed if the task is disabled.'
    }
}

disableMe.configure {
    enabled = false
}
```

#### 设置任务 timeout

每个任务都有一个超时属性(timeout property)，用于限制任务的执行时间。当一个任务达到超时时间时，它的任务执行线程被中断(be interrupted)。该任务将被标记为失败(failed)。它的 Finalizer tasks(通过 finalizedBy 方法添加的任务)仍将运行。如果 gradle 使用了 --continue flag，其他任务可以在该任务之后继续运行。

注意不能中断的任务就不能设置超时。Gradle 的所有内置任务都能中断，并及时响应超时。

```groovy
tasks.register("hangingTask") {
    doLast {
        Thread.sleep(100000)
    }
    timeout = Duration.ofMillis(500)
}
```

### 增量构建

在讲 task 的运行之前，我们需要先讲解下 task 的增量构建。因为要了解 task 运行相关的知识，很多部分都需要先明白 task 增量构建相关的知识。

#### 知识背景

任何构建工具的一个重要功能，就是能够避免重复执行已经完成的工作。例如编译过程中，如果源文件没有更改，则下次编译时就不需要重新执行编译任务。因为编译可能会花费大量时间，因此在不需要时跳过编译步骤可以节省大量时间。这种功能叫做执行结果检查，或者又叫增量构建。

Gradle 默认支持这种功能。在 Gradle 中，这个功能被称为"增量构建"(incremental build)，也可以叫做"最新检查"(Up-to-date checks)。我们可以在项目中看到他们的身影：在运行构建时，我们可以看到 UP-TO-DATE 文本出现在任务名称后。此结果就是增量构建生效的体现。

为了支持增量构建，Gradle 定义了两套 API：IncrementalTask​​Inputs API(Gradle 5.4之前) 和 InputChanges API。Gradle 5.4 之前定义了 IncrementalTask​​Inputs API，但该 API 有两个缺点：

- 使用 IncrementalTask​​Inputs 时，只能查询任务输入的所有文件更改。无法查询单个输入文件属性的更改。

- IncrementalTask​​Inputs API 不区分增量和非增量的任务输入，因此任务实现本身需要确定更改的来源。

IncrementalTask​​Inputs API 已被弃用，最终将被删除。新的 InputChanges API 取代了它并解决了它的缺点。如果需要使用旧 API，则需要查看 Gradle 5.3.1 用户手册文档。

#### 概念定义

通常，Gradle task 会接受一些输入(inputs)，并生成一些输出(outputs)。如编译任务会将 java 源文件编译成 class。此时 java 源文件是输入，生成的 class 文件是输出。Gradle 使用输入输出来确定任务是否是最新的(up-to-date)，并且使用此信息来确定是否需要执行任何工作。如果输入或输出都没有改变，Gradle 就能跳过该任务。我们将 Gradle 的这些内容称为 Gradle 的增量构建支持(incremental build support)。

为了支持增量构建，Gradle 将 task 抽象为 3 大部分：inputs、TaskAction、outputs。

- inputs 代表任务的输入

- TaskAction 代表任务要执行的操作

- ouputs 代表任务使用输入执行对应操作后，生成的输出

![Gradle增量构建模型图](/imgs/Gradle增量构建模型图.webp)

要利用增量构建支持，我们需要向 Gradle 提供与任务有关的输入和输出(tasks' inputs and outputs)信息，当然任务也可以被配置为仅具有输出(only have outputs)。在执行任务之前，Gradle 会检查输出，如果输出没有更改，将跳过任务的执行。在实际构建中，任务通常也有输入——包括源文件、资源和属性。 Gradle 在执行任务之前检查输入和输出都没有改变。

注意：当 Gradle 版本更改时，Gradle 会检测并删除使用旧版本 Gradle 执行的任务的输出，以确保最新版本的任务从已知的 clean 状态开始。

#### 工作逻辑

在第一次执行任务之前，Gradle 会获取输入(inputs)的指纹，该指纹包含输入文件的路径和每个文件内容的哈希值。之后 Gradle 再执行任务。如果任务成功完成执行，Gradle 会获取输出(outputs)的指纹。该指纹包含输出文件集合和每个文件内容的哈希值。 Gradle 会为下次执行任务保留两个指纹。

之后在每次执行任务之前，文件的状态信息(即 lastModified 和 size)更改，Gradle 都会获取输入和输出的新指纹。如果新指纹与之前的指纹相同，Gradle 会假定输出结果是最新的(up-to-date)并跳过该任务。如果指纹不相同，Gradle 将执行任务并保留生成的新指纹。

- 如果文件的状态信息(即 lastModified 和 size)没有改变，Gradle 将复用上次执行的文件指纹。这意味着当文件的统计信息没有更改时，Gradle 不会检测更改。

- Gradle 还将任务的代码(任务的实现逻辑)视为任务输入的一部分。当任务、任务的操作(task action)或其依赖任务在两次执行之间发生变化时，Gradle 会认为该任务已过期。为了跟踪任务、任务操作和嵌套输入的实现，Gradle 使用类名和包含类实现的类路径的 id。在某些情况下，Gradle 无法准确跟踪实现：

   - 未知的 classloader。当 Gradle 没有创建用于加载实现的 classloader 时，无法确定类路径。

   - java lambda 表达式。Java lambda 类是在运行时使用不确定的类名创建的。因此，类名并不能标识 lambda 的具体实现以及不同 Gradle 运行之间的更改

   当无法精确跟踪任务、任务的操作或嵌套输入的实现时，Gradle 会禁用该任务的任何缓存。这意味着该任务将永远不会是最新的(up-to-date)，并且任务不会从构建缓存中加载

- 如果一个文件属性(如持有 Java 类路径的属性)对顺序敏感。在比较此类属性的指纹时，即使文件顺序发生变化也会导致任务过时(out-of-date)

- 如果任务指定了输出目录，则自上次执行以来添加到该目录的任何文件都将被忽略，并且不会导致任务过期，这是因为不相关的任务可以共享一个输出目录而不会相互干扰。如果出于某些考虑这不是我们想要的行为，则可以考虑使用 TaskOutputs.upToDateWhen(Closure)

- 更改无效文件的有效性(如将损坏的文件链接的目标修改为有效文件，反之亦然)将被最新检查(up-to-date check)检测到，并被其处理。

简而言之，增量构建中，Gradle 会通过检测输入输出的校验和，对比本次和上次构建的任务的输入输出是否有任何变化。如果没有，Gradle 认定任务是最新的(up to date)，会跳过执行该任务的操作(action)。

#### 非增量场景补充

在很多情况下，Gradle 无法确定需要处理哪些输入文件，此时需要以非增量方式执行。它们包括以下场景：

- 以前的执行没有可用的历史记录

- 使用不同版本的 Gradle 进行构建。目前 Gradle 只支持使用当前版本的任务历史记录

- 添加到任务的 TaskOutputs.upToDateWhen 条件返回了 false(表示任务不是 up-to-date，而是 out-of-date)

- 输入属性已更改

- 非增量输入文件属性(non-incremental input file property)已更改

- 一个或多个输出文件已更改

在这些情况下，Gradle 会将所有输入文件视为 ADDED，并且 getFileChanges() 方法将返回包含输入属性的所有文件的详细信息。

#### 执行结果

Gradle 执行 task 时，会在控制台中或通过 Tooling API (在代码中使用)为 task 标记不同的执行结果。打上哪些状态标签取决于 task 有是否要执行的操作(action)、task 是否应该执行这些操作、task 是否确实执行了这些操作以及 task 的这些操作是否有结果更改。task 的标签类型有：

- (no label) 或者 EXECUTED：无标签或者标签为 EXECUTED，则代表 task 执行了 actions。以下几种场景会打上此标签：

   - task 有 actions 作为构建的一部分被执行

   - task 无 actions 执行，但是有依赖的 task，并且所有依赖的 task 都是 EXECUTED 状态

- UP-TO-DATE：task 的 outputs 没有任何改变。以下几种场景会打上此标签：

   - 任务有 inputs 和 outputs，但它们都没有任何变化

   - task 有 actions 执行，但是该 task 告诉 gradle 执行 actions 的 outputs 没有变化

   - task 无 actions 执行，但是有依赖的 task，并且所有依赖的 task 都是 UP-TO-DATE 状态，或 SKIPPED 状态，或者 FROM-CACHE 状态

   - task 无 actions 执行，并且无依赖的 task

- FROM-CACHE：task 的 outputs 可以从上一次的运行结果中找到

   - 任务从构建缓存拿了 ouputs 时会打上此标签。具体可以看：[Build Cache (gradle.org)](https://docs.gradle.org/current/userguide/build_cache.html#build_cache)

- SKIPPED：task 并没有执行 actions

   - 构建运行前，task 在命令行中被显式的移除，不用运行时会打上此标签。详情见：[Command-Line Interface (gradle.org)](https://docs.gradle.org/current/userguide/command_line_interface.html#sec:excluding_tasks_from_the_command_line)

   - 任务有 onlyIf 块限制，并且 onlyIf 结果返回了 false

- NO-SOURCE：任务不需要执行 actions

   - 任务有 inputs 和 outputs，但没有源码时会打上此标签。例如 JavaCompile 任务需要的 .java 源文件不存在时

#### 代码定义

##### 输入确定方式

处理增量构建时，一个很重要的议题是：如何确定哪个内容应作为任务的输入？

其实输入的一个重要特征就是它会影响一个或多个输出。**如果某个内容会影响输出，则该内容应成为任务的输入；反之如果某个内容不影响输出，则该内容不必成为任务的输入。**

从上面的 task 概念拆分图中可以看出，如果源文件不同或 java 版本不同，则会生成不同的字节码。这决定了它们应成为任务的 inputs。但是编译时是否有 500MB 或 600MB 的最大可用内存，由 memoryMaximumSize 属性确定，对生成的字节码 outpus 没有影响，则该属性无需作为 inputs。在 Gradle 术语中，memoryMaximumSize 只是一个内部任务属性。

另外一个值得注意的点是，**增量构建要求任务至少有一个任务输出，即使任务至少定义了输入，否则增量构建将不起作用。**

综上，要使用 Gradle 提供的增量构建能力，对开发者而言，操作十分简单：我们只需要告诉 Gradle 哪些 task properties 是输入，哪些是输出，并定义任务的操作即可。

- 如果 task properties 会影响输出，则需要将其注册为输入。注意：如果不注册，该任务将被认为是最新(up-to-date)的，即使任务实际上不是最新的

- 如果 task properties 不影响输出，则不要将其注册为输入，否则任务可能会在不需要时执行。

- 如果任务在完全相同的输入的前提下，生成了不同输出。则此任务不应配置为增量构建，因为此时最新检查(up-to-date check)将不起作用

##### 实现方式

Gradle 中，主要有两种方式让任务获得增量构建的能力：注解和运行时 API。

- 注解：注解在自定义 Task 中使用，是官方推荐的实现增量构建的方式

- 运行时 API：在 task 的配置代码中使用(不仅限于自定义的 Task)。运行时 API 的一个重要的特点是可以让非增量的任务变得可增量构建。但是官方不推荐优先使用运行时 API，运行时 API 更适用于无法使用注解的情况。如我们看不到第三方插件定义的 task 的源码，则我们无法使用注解，但又想让该任务获得增量构建的能力，此时我们就可以使用运行时 API

##### 使用注解

下列讲解中：IO 代表 inputs and outputs，即输入输出。而 ACTION 代表 task action。

###### IO：注解示例

当我们自定义任务类时，只需两步即可使增量构建生效。

1. 为任务的输入和输出创建指定类型的 Property

2. 为每个属性添加适当的注解。

注意注解必须放在 getter 或 Groovy 属性(properties)上。注解如果放在属性的 setter 上，或者如果属性上没有相应的注解，则属性将不被视为 inputs。

Gradle 支持四种主要的输入和输出类别：

- 简单的值，使用 @Input 注解

   - 数字、字符串等主要类型

   - 实现了 Serializable 的类型

- 文件相关类型，如 @InputFiles 注解

   - RegularFile 类

   - Directory 类

   - 标准 File 类

   - FileCollection 类

   - Project.file 和 Project.files 方法支持的 file/dir 属性

- 依赖解析结果，如

   - 该类型仅支持包装在 Provider 类中，不支持单独使用

   - artifact metadata 的 ResolvedArtifactResult 类

   - dependency graphs 的 ResolvedComponentResult 类

- 嵌套的值，使用 @Nested 注解

   - 自定义的类作为输入，可以使用 @Nested 注解，gradle 能够从中读取 inputs 和 outputs

举个列子，假设一个模版处理框架任务具有三个输入和一个输出：

- 输入：模版源代码

- 输入：java bean 数据(Model data)

- 输入：模版引擎

- 输出：outputs 的保存位置作为输出

```groovy
// buildSrc/src/main/java/org/example/ProcessTemplates.java
package org.example;

import java.util.HashMap;
import org.gradle.api.DefaultTask;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.*;

public abstract class ProcessTemplates extends DefaultTask {
    // 简单的值，输入
    @Input
    public abstract Property<TemplateEngineType> getTemplateEngine();
    @InputFiles
    public abstract ConfigurableFileCollection getSourceFiles();
    // 自定义 Model Data，嵌套类型
    @Nested
    public abstract TemplateData getTemplateData();
    // 输出
    @OutputDirectory
    public abstract DirectoryProperty getOutputDir();
    // 任务动作
    @TaskAction
    public void processTemplates() {
        // ...
    }
}

// buildSrc/src/main/java/org/example/TemplateData.java
import org.gradle.api.provider.MapProperty;

public abstract class TemplateData {
    @Input
    public abstract Property<String> getName();
    @Input
    public abstract MapProperty<String, String> getVariables();
}
```

上述代码中有很多需要讨论的内容，此处挨个讲解：

- templateEngine

   表示在处理源模板时使用哪个引擎。引擎类型其实可以定义为字符串。但在本例中，我们选择了自定义枚举，因为它提供了更大的类型信息和安全性。并且枚举自动实现了 Serializable，我们可以将其视为一个简单的取值并使用 @Input 注解，就像我们使用 String 一样

- sourceFiles

   表示任务将处理的模板源文件。单个文件和文件集合需要使用不同的注解。本例中，我们需要处理输入文件的集合，因此我们使用了 @InputFiles 注解。下面会列举更多关于文件的注解

- templateData

   本例中，我们使用了自定义类来表示 model data(java bean)。但是，它没有实现 Serializable，所以我们不能使用 @Input 注解。但这并不是什么大问题，因为 TemplateData 中的属性(字符串和 hashmap 继承自 Serializable))是可序列化的，可以使用 @Input 进行注解，然后我们可以在 templateData 上使用 @Nested 注解，让 Gradle 知道这是一个具有嵌套输入的属性

- outputDir

   生成的文件所在的目录。与输入文件一样，输出文件和目录也有几个注解。表示单个目录的属性需要使用 @OutputDirectory 注解

本例适用于多个源文件。那如果只有一个源文件发生更改会怎样呢？任务是再次处理所有源文件还是只处理那个修改后的文件？实际上这取决于任务的具体实现。如果是后者，那么任务本身就是增量的，这与我们在此处讨论的功能不同。此处我们讨论的是 Gradle 通过其内置的 incremental build support 功能帮助 task 实现增量构建的能力

###### IO：注解列表

输入输出可用的注解如下表所示：

||||
|:-:|:-:|:-:|
|**注解名**|**可修饰的属性类型**|**含义**|
|@Input|Serializable 类型或者依赖解析结果类型|一个简单的输入值或者依赖解析结果|
|@InputFile|File|单个 file，不是 dir|
|@InputDirectory|File|单个 dir，不是 file|
|@InputFiles|Iterable<File>|列表，内容可以是 file 和 dir|
|@Classpath|Iterable<File>|代表 Java classpath 的 file 和 dir 的列表|
|@CompileClasspath|Iterable<File>|代表 Java compile classpath 的 file 和 dir 的列表|
|@OutputFile|File|单个 file，非 dir|
|@OutputDirectory|File|单个 dir，非 file|
|@OutputFiles|Map<String, File> 或者 Iterable<File>|output files的列表或者映射|
|@OutputDirectories|Map<String, File> 或者 Iterable<File>|output dirs的列表或者映射|
|@Destroys|File 或者 Iterable<File>|指定需要被此任务删除的一个或多个文件。注意：任务可以定义 inputs/outputs 或 destroyable 文件两者之一，但不能同时定义两者|
|@LocalState|File 或者 Iterable<File>|指定一个或多个代表任务本地状态的文件。从缓存加载任务时这些状态文件将被删除|
|@Nested|任何自定义类型|自定义类型可以未实现 Serializable，但类里的字段或属性至少要有一个标记有当前注解列表中的注解之一，这个注解甚至可以是 @Nested|
|@Console|任何类型|表示该属性既不是输入也不是输出。它只是影响任务的控制台输出，例如增加或减少任务的详细程度|
|@Internal|任何类型|表示该属性在任务内部使用，既不是输入也不是输出|
|@ReplacedBy|任何类型|表示该属性已被另一个属性替换，当作为输入或输出时，应被忽略|
|@SkipWhenEmpty|File 或者 Iterable<File>|与 @InputFiles 或 @InputDirectory 注解一起使用，告诉 Gradle 如果注解修饰的文件或目录，以及使用此注解声明的所有其他输入文件为空，则跳过该任务。使用此注解的任务，如果被跳过执行，那么必然是 "NO-SOURCE" 结果(inputs 为空，肯定没有源文件)|
|@Incremental|Provider<FileSystemLocation> 或者 FileCollection|与 @InputFiles 或 @InputDirectory 一起使用以指示 Gradle 跟踪带此注解的文件属性的更改，方便通过@InputChanges.getFileChanges() 查询输入的更改。**增量任务必需注解**|
|@Optional|任何类型|与 Optional API 文档中列出的任何 property 类型的注解一起使用，表示注解对应的属性的值可以不用设置。此注解禁用对相应属性的验证检查。|
|@PathSensitive|File 或者 Iterable<File>|与任何输入文件属性一起使用，以告诉 Gradle 仅将文件路径的给定部分视为重要的部分。例如，如果使用了 @PathSensitive(PathSensitivity.NAME_ONLY) 注解，则在不更改其内容的情况下移动文件不会使任务过期|
|@IgnoreEmptyDirectories|File 或者 Iterable<File>|与 @InputFiles 或 @InputDirectory 一起使用，以指示 Gradle 仅跟踪目录内容的更改，而不是目录本身的差异。例如，在目录结构中添加、删除或重命名空目录不会使任务过期|
|@NormalizeLineEndings|File 或者 Iterable<File>|与 @InputFiles、@InputDirectory 或 @Classpath 一起使用，以指示 Gradle 在执行 up-to-date检查或构建缓存 key 时优化文件换行符。例如，文件在 Unix 换行符和 Windows 换行符之间切换不会使任务过期|

- 表格中的 File 类型可以是 Project.file(Object) 方法接受的任何类型

- Iterable<File> 类型可以是 Project.files(Object...​) 方法接受的任何类型。甚至是 Callable、closures。FileCollection 和 FileTree 也是 Iterable<File> 类型的

- Map 类型本身可以封装在 Callables、closures 中

###### IO：注解优先级

子类会继承修饰父类(包括接口)的注解，对于修饰某个属性的注解，子类的注解会覆盖掉父类的注解，父类的注解会覆盖接口中的注解。即 child > parent > interface。

上述表中的 Console 和 Internal 注解是特殊情况，因为它们既不是任务输入也不是任务输出。那么问题来了，为什么要使用它们呢？因为这样就可以利用 Java Gradle Plugin Development plugin (即帮助开发 plugin 的 plugin)来帮助我们开发和发布自己的插件。此插件会检查我们的自定义 task 类的 properties 是否缺少增量构建注解。这可以防止我们在开发过程中忘记添加适当的注解

###### IO：使用依赖解析结果

依赖解析结果即 dependency resolution results。依赖关系解析结果可以通过两种方式作为任务输入使用：

- 使用 ResolvedComponentResult 处理已解析了的元数据的图(the graph of the resolved metadata)。解析图可以通过 Configuration 的 incoming resolution result 中懒加载获取，并连接到 @Input 属性

   ```groovy
   // inputs 定义输入
   @Input
   public abstract Property<ResolvedComponentResult> getRootComponent();
   ```

   ```groovy
   // 获取配置
   Configuration runtimeClasspath = configurations.getByName("runtimeClasspath");

   // input 绑定输入结果
   task.getRootComponent().set(
       runtimeClasspath.getIncoming().getResolutionResult().getRootComponent()
   );
   ```

- 使用 ResolvedArtifactResult 处理已解析了的产物的集合(the flat set of the resolved artifacts)。已解析的工件集可以从 Configuration 的 incoming artifacts 中懒加载获取。下面的例子中，鉴于 ResolvedArtifactResult 类型包含元数据和文件信息，实例只需要在连接到 @Input 属性之前转换为元数据即可：

   ```groovy
   // 定义输入
   @Input
   public abstract ListProperty<ComponentArtifactIdentifier> getArtifactIds();
   ```

   ```groovy
   Configuration runtimeClasspath = configurations.getByName("runtimeClasspath");
   Provider<Set<ResolvedArtifactResult>> artifacts = runtimeClasspath.getIncoming().getArtifacts().getResolvedArtifacts();
   // 将元数据转换为 id，并绑定到 inputs
   task.getArtifactIds().set(artifacts.map(new IdExtractor()));

   static class IdExtractor
       implements Transformer<List<ComponentArtifactIdentifier>, Collection<ResolvedArtifactResult>> {
       @Override
       public List<ComponentArtifactIdentifier> transform(Collection<ResolvedArtifactResult> artifacts) {
           return artifacts.stream().map(ResolvedArtifactResult::getId).collect(Collectors.toList());
       }
   }
   ```

   graph 和 set 都可以和解析的文件信息相结合和扩充，更具体的讲解见：[Implementing tasks with dependency resolution result inputs Sample (gradle.org)](https://docs.gradle.org/current/samples/sample_tasks_with_dependency_resolution_result_inputs.html)

###### IO：使用 classpath 注解(可跳过)

除了 @InputFiles 注解以外，对于 JVM 相关的任务，Gradle 还需处理类路径输入(classpath inputs)(涉及 JVM，Android 开发一般用不上)。

当 Gradle 查找任务变更时，运行时和编译类路径(runtime and compile classpaths)的处理方式会有所不同。

与使用 @InputFiles 注解的输入属性相反，对于类路径属性(classpath properties)，文件集合中定义的顺序很重要。另一方面，计算输入是否改变时，类路径本身上的目录和 jar 文件的名称和路径、jar 包中的时间戳、类文件和资源的顺序，都会被忽略。因此重新创建具有不同文件日期的 jar 包不会使任务过期(换句话讲，选取 class 所在的 jar 时，顺序很重要。而 jar 中的文件和资源的顺序、时间戳这些不重要)

运行时类路径用 @Classpath 标记，它们通过类路径规范提供更深入的定制。

使用 @CompileClasspath 注解的输入属性被视为 Java 编译时类路径。除了前面提到的类路径规则之外，编译类路径还会进一步忽略除对 class 以外的所有内容的更改。 Gradle 使用 Java 编译说明([The Java Plugin (gradle.org)](https://docs.gradle.org/current/userguide/java_plugin.html#sec:java_compile_avoidance))中描述的相同逻辑来进一步过滤不改变类的 ABI 的更改。这意味着仅涉及类实现的更改不会使任务过时。

###### IO：嵌套输入

在解析输入和输出属性需要使用那些数据时，如果检测到 @Nested 任务属性，Gradle 会使用 @Nested 任务属性的子属性。它可以发现运行时配置的所有子属性

- Provider 被 @Nested 修饰时，Provider 的值被视为嵌套输入(nested input)

- iterable 被 @Nested 修饰时，iterable 中的每个元素都被视为单独的嵌套输入。iterable 中的每个嵌套输入都被分配了一个名称，默认情况下，该名称是 $ 符号后跟对象在 iterable 中的索引，例如 $2。如果 iterable 中的元素实现了 Named 接口，则该名称用作对应属性的名称(每个 setter 都可以当作属性使用，如编译任务的 setSource 方法)。如果不是所有元素都实现了 Named 接口，那么 iterable 中元素的顺序对于可靠的 up-to-date 检查和缓存至关重要。不允许有多个具有相同名称的元素。

- map 被 @Nested 修饰，每个 value 会被视为一个嵌套输入，使用 key 作为名称。

嵌套输入的类型和类路径也被跟踪。这确保了对嵌套输入实现的更改会导致构建过时。示例可见：[Authoring Tasks (gradle.org)](https://docs.gradle.org/current/userguide/more_about_tasks.html#sec:task_input_nested_inputs)

###### IO：数据验证

- Gradle 会对带注解的属性执行一些基本验证。此类验证提高了构建的稳健性，使我们能够快速识别与输入和输出相关的问题。Gradle 在任务执行之前会对下列带注解的属性执行以下操作:

   - @InputFile：验证该属性是否设置了 value，并验证 value 路径表示的文件(不是目录)是否存在

   - @InputDirectory：同 @InputFile，区别是验证的目录(不是文件)是否存在

   - @OutputDirectory：验证路径是否与文件匹配；并验证目录存在，不存在则创建该目录

- 如果一个任务(生产者)的输出作为另一个任务(消费者)的输入，则 Gradle 会检查这两个任务的依赖性。当生产者和消费者任务同时执行时，构建将失败，以避免产生不正确的状

- 如果我们想要禁用某些验证，特别是当输入文件实际上可能真的不存在时。可以使用 @Optional 注解来告诉 Gradle 特定输入是可选的(仅适用于 Optional API 相关的注解)，如果相应的文件或目录不存在，构建不应输出失败的结果。

###### ACTION：增量任务操作

对于增量处理输入的任务，该任务必须包含增量任务操作(incremental task action)。增量任务操作是一个具有单个 InputChanges 入参的任务操作方法(task action method)，该参数告诉 Gradle 该操作只想处理更改的输入。此外，该任务需要使用 @Incremental 注解或 @SkipWhenEmpty 注解声明至少一个增量文件输入属性。

注意要查询输入文件属性(input file property)的增量更改，该属性(property)始终需要返回相同的实例。完成此操作的最简单方法是对此类文件属性使用以下类型之一：RegularFileProperty、DirectoryProperty 或 ConfigurableFileCollection。

- 对于给定的基于文件类型输入属性(file-based input property)，无论是 RegularFileProperty、DirectoryProperty 还是 ConfigurableFileCollection 类型，增量任务操作可以使用 InputChanges.getFileChanges() 方法来找出哪些文件发生了更改。该方法返回一个可以查询以下内容的 FileChange 类型的 Iterable：

   - 通过 getFile() 方法获取受影响的文件

   - 通过 getChangeType() 方法获取文件变化的类型：ADDED, REMOVED 或者 MODIFIED(文件的添加、删除或者修改)

   - 通过 getNormalizedPath() 方法获取获取变化文件的路径。路径的返回值受 PathSensitivity、Classpath、CompileClasspath 等设置的影响

   - 通过 getFileType() 查询文件的类型：DIRECTORY、FILE 或者 MISSING

- 可以使用 InputChanges.isIncremental() 方法检查任务是否是增量执行的

- 可以使用 Task.doNotTrackState() 方法抛弃了增量编译的能力

以下示例演示了具有目录输入的增量任务。它假设该目录包含一组文本文件，操作将它们复制到输出目录，并反转每个文件中的文本。需要注意的关键点是 inputDir 属性的类型、其注解以及操作(execute() 方法)如何使用 getFileChanges() 处理部分更改的文件。如果相应的输入文件已被删除，同时还可以看到该操作如何删除目标文件：

```groovy
// 注意 abstract 关键字
abstract class IncrementalReverseTask extends DefaultTask {
    @Incremental
    @PathSensitive(PathSensitivity.NAME_ONLY)
    @InputDirectory
    abstract DirectoryProperty getInputDir()

    @OutputDirectory
    abstract DirectoryProperty getOutputDir()

    @Input
    abstract Property<String> getInputProperty()
    /**
     * 任务操作只需要为任何过时的输入生成输出文件，
     * 并删除已被删除的输入对应的输出文件
     */
    @TaskAction
    void execute(InputChanges inputChanges) {
        println(inputChanges.incremental
            ? 'Executing incrementally'
            : 'Executing non-incrementally'
        )

        inputChanges.getFileChanges(inputDir).each { change ->
            if (change.fileType == FileType.DIRECTORY) return

            println "${change.changeType}: ${change.normalizedPath}"
            def targetFile = outputDir.file(change.normalizedPath).get().asFile
            if (change.changeType == ChangeType.REMOVED) {
                targetFile.delete()
            } else {
                targetFile.text = change.file.text.reverse()
            }
        }
    }
}
```

如果由于某种原因任务以非增量的方式执行，则所有文件都被视为 ADDED，与之前执行的状态无关。在这种情况下，Gradle 会自动移除之前的输出，因此增量任务只需要处理给定的文件即可(不用考虑之前的处理结果)。

##### 使用运行时 API

自定义 task 类是一种将我们自定义的构建逻辑引入增量构建领域的简单方法，但我们并不是总能使用这种方式。例如使用第三方 plugin 提供的 task，我们无法更改其源码。如果我们无法访问自定义任务类的源代码，那我们就无法添加上面介绍的任何注解。如果这时候我们想要启用增量构建该怎么做？Gradle 为这样的场景提供了运行时 API(runtime API)。它可以用于任何任务实例。

###### 代码示例

运行时 API 是通过几个见名知义的属性提供的，这些属性可用于每个 Gradle 任务：

- Task.getInputs() 方法，代表输入，方法返回 TaskInputs 实例

- Task.getOutputs() 方法，代表输出，方法返回 TaskOutputs 实例

- Task.getDestroyables() 方法，代表被任务删除的 files 或 dirs，方法返回 TaskDestroyables 实例

这些对象中定义的方法允许我们指定构成任务输入和输出的文件、目录和值(files, directories and values)。实际上，运行时 API 基本上具有与使用注解相同的功能，它所缺少的只是 @Nested 的等价物。

```groovy
tasks.register('processTemplatesAdHoc') {
    // engine input property 的值是 TemplateEngineType.FREEMARKER
    inputs.property('engine', TemplateEngineType.FREEMARKER)
    // sourceFiles input files 的值是 src/templates
    inputs.files(fileTree('src/templates'))
        .withPropertyName('sourceFiles')
        .withPathSensitivity(PathSensitivity.RELATIVE)
    inputs.property('templateData.name', 'docs')
    inputs.property('templateData.variables', [year: '2013'])
    outputs.dir(layout.buildDirectory.dir('genOutput2'))
        .withPropertyName('outputDir')

    doLast {
        // Process the templates here
    }
}
```

该示例有很多可以讨论的点。

- 实际上，我们应该编写一个自定义任务类实现上述逻辑，因为它其实可以是一个具有多个配置选项的较复杂的实现。此例并有设计其他任务属性来存储根源代码文件夹(root source folder)、输出目录的位置或任何其他设置，此处仅是为了强调运行时 API 不需要任务具有任何其他条件就可以达到与自定义任务注解相同的功能，所以简单点写。在增量构建方面，上述任务实例的行为与自定义任务类相同。

- 运行时 API 和注解之间的一个显着区别是运行时 API 缺少直接对应 @Nested 的方法。这就是为什么该示例使用了两个 property() 声明，每个 TemplateData 属性一个。在实现带有嵌套值的运行时 API 时，我们应该使用相同的方式。任何给定的任务都可以声明 destroyables 或 inputs/outputs，但不能同时声明两者

- 所有输入和输出的定义都是通过 inputs 和 outputs 的相关方法完成的，例如 property()、files() 和 dir()。 Gradle 对参数值执行 up-to-date 检查以确定任务是否需要再次运行。每个方法都对应一个增量构建注解，例如，inputs.property() 对应 @Input 注解，outputs.dir() 对应 @OutputDirectory 注解

- 任务可删除的文件可以通过 Task.getDestroyables.register() 指定
   
   ```groovy
   tasks.register('removeTempDir') {
       destroyables.register(layout.projectDirectory.dir('tmpDir'))
       doLast {
           delete(layout.projectDirectory.dir('tmpDir'))
       }
   }
   ```

注意如果任务类型已经在使用增量构建注解，则使用相同名称的运行时 API 注册输入或输出将导致错误。

###### 使任务可增量构建

上面我们讲过，运行时 API 可以让非增量构建的任务具备增量构建的能力。要实现这种功能，主要有两种方式：

- 如果可以拿到 task 实例，则可以直接对 task 实例增加配置项。此种方式在上面的例子中已经讲解过了。

- 如果无法拿到 task 实例，则可以新定义一个包装任务，原任务要做的任务放入此包装任务中，包装任务负责检测原任务的输入输出。借用讲解文件时的例子，我们来说明这种功能如何实现。

因为 Project.copy(org.gradle.api.Action) 方法进行复制时默认不是增量构建的，并且无法拿到 Task 实例。所以我们需要对该方法进行包装。

我们定义一个 copyIncremental 方法包装 copy 操作。copyIncremental 任务是增量的，其输入来自于 copyTask，输出为 some-dir。虽然 copyIncremental 任务并没有直接改动这些文件，但是 copy 方法使输出发生了改变，此时增量编译检查也能生效(copyIncremental 定义输入输出，copy 使用了输入输出。inputs 和 outputs 可以改变，一改变就能检测到)。

```groovy
tasks.register('copyIncremental') {
    // inputs 的 up-to-date check 增加 copyTask
    // 返回的是 TaskInputFilePropertyBuilder，
    // 属性名为：inputs(第二行代码)
    inputs.files(copyTask)
        .withPropertyName("inputs")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    // outputs 的 up-to-date check 增加 some-dir
    // 返回的是 TaskOutputFilePropertyBuilder
    // 属性名为：outputDir(第二行代码)
    outputs.dir('some-dir')
        .withPropertyName("outputDir")
    doLast{
        copy {
            // 复制 copyTask 的 ouput 到 some-dir
            from copyTask
            into 'some-dir'
        }
    }
}
```

###### 更多配置

- 运行时 API 方法虽然只允许我们声明输入和输出。但是针对文件类型，运行时 API 会返回一个 TaskInputFilePropertyBuilder 类型的构建器(builder)，该 builder 允许我们提供有关这些输入和输出的更多额外信息。我们可以在其 API 文档中了解构建器提供的所有选项，此处仅展示一个简单的示例，方便我们了解它可以做什么。

   假设我们不想在没有源文件的情况下运行 processTemplates 任务(无论它是否 clean build)，毕竟如果没有源文件，任务就没有什么可做的了。此时我们可以这样配置：

   ```groovy
   tasks.register('processTemplatesAdHocSkipWhenEmpty') {
       // ...
       inputs.files(fileTree('src/templates') {
               include '**/*.fm'
           })
           .skipWhenEmpty()
           .withPropertyName('sourceFiles')
           .withPathSensitivity(PathSensitivity.RELATIVE)
           .ignoreEmptyDirectories()
       // ...
   }
   ```

   上述实例中，TaskInputs.files() 方法返回一个TaskInputFilePropertyBuilder。调用 skipWhenEmpty 方法等价于使用 @SkipWhenEmpty 对属性进行注释。

- 假设有一个将 processTemplates 任务的输出打包的归档任务。我们肯定能知道归档任务运行前需要先运行 processTemplates 任务，因此我们会添加显式的 dependsOn。但是，如果我们使用下面的代码定义归档任务，Gradle 会自动使 packageFiles 任务依赖于 processTemplates。Gradle 之所以这样做，是因为 Gradle 知道 packageFiles 的输入之一是 processTemplates 任务的输出。这种功能在 Gradle 被称为推断的任务依赖(an inferred task dependency)：

   ```groovy
   tasks.register('packageFiles', Zip) {
       from processTemplates.map {it.outputs }
   }
   ```

   因为 from() 方法可以接受任务实例作为参数，例子也可以简化为如下形式。在具体的实现中，from() 方法会使用 project.files() 方法包装入参，这会将任务的输出转为文件集合。换句话说， from(taskObject) 是一个特例，下述代码也是一个特例，非普遍情况。

   ```groovy
   tasks.register('packageFiles2', Zip) {
       from processTemplates
   }
   ```

- Copy 任务的 from() 方法没有用 @InputFiles 注解，但任何传递给它的文件都被视为任务的正式输入。它是如何工作的呢？代码实现其实非常简单，我们可以对自己的自定义任务使用相同的技术来改进，以便将文件直接添加到适当的注解属性。例如，以下示例介绍了如何将 sources() 方法添加到我们之前介绍的自定义 ProcessTemplates 类：

   ```groovy
   public abstract class ProcessTemplates extends DefaultTask {
       // ...
       @SkipWhenEmpty
       @InputFiles
       @PathSensitive(PathSensitivity.NONE)
       public abstract ConfigurableFileCollection getSourceFiles();

       public void sources(FileCollection sourceFiles) {
           getSourceFiles().from(sourceFiles);
       }

       // ...
   }

   tasks.register('processTemplates', ProcessTemplates) {
       // ...
       outputDir = file(layout.buildDirectory.dir('genOutput'))
       sources fileTree('src/templates')
   }
   ```

- 如果我们想将任务作为参数并将它们的输出视为输入，我们可以使用 project.layout.files() 方法解析任务。使用这个方法的一个好处是，我们的自定义方法可以通过 Gradle 自动推断任务的依赖关系。如下所示：

   ```groovy
   // ProcessTemplates 类
   public void sources(TaskProvider<?> inputTask) {
       getSourceFiles().from(getProject().getLayout().files(inputTask));
   }

   def copyTemplates = tasks.register('copyTemplates', Copy) {
       into file(layout.buildDirectory.dir('tmp'))
       from 'src/templates'
   }

   tasks.register('processTemplates2', ProcessTemplates) {
       // ...
       sources copyTemplates
   }
   ```

   注意如果我们正在开发一个将源文件集合作为输入的任务，例如这个示例，那么请考虑使用 Gradle 内置的 SourceTask 任务。它将使我们免于定义一些如需要放到 ProcessTemplates 任务中的属性和方法。此处仅是为了举例，才自定义了 source。

- 将 @OutputDirectory 链接到 @InputFiles。

   想将一个任务的输出链接为另一个任务的输入时，输入输出的类型通常需要匹配(例如文件输出属性(File output property)可以分配给文件输入(File input))，并且需要一个简单的属性表示该链接。

   不幸的是，当我们希望任务的 @OutputDirectory 中的文件成为另一个任务的 @InputFiles 属性的源时，这种方法就失效了。因为两者具有不同的类型，因此属性分配将不起作用。

   例如，假设我们想使用 Java 编译任务的输出作为自定义任务(任务名为 Instrument)的输入。该自定义任务检测包含 Java 字节码的文件，并且有一个用 @InputFiles 注解的 classFiles 属性。

   最初我们可能会尝试像这样配置任务：

   ```groovy
   plugins {
       id 'java-library'
   }

   tasks.register('badInstrumentClasses', Instrument) {
       classFiles.from fileTree(tasks.named('compileJava').map { it.destinationDir })
       destinationDir = file(layout.buildDirectory.dir('instrumented'))
   }
   ```

   这段代码没有明显的问题，但是我们可以从控制台输出中看到缺少编译任务 compileJava 的执行(即用 fileTree() 意味着 Gradle 无法自动推断任务依赖)。此问题有几个解决方案。

   1. 我们需要通过 dependsOn 方法在 instrumentClasses 和 compileJava 之间添加显式任务依赖项。

   2. 使用 TaskOutputs.files 方法，如以下示例所示：

      ```groovy
      tasks.register('instrumentClasses', Instrument) {
          classFiles.from tasks.named('compileJava').map { it.outputs.files }
          destinationDir = file(layout.buildDirectory.dir('instrumented'))
      }
      ```

   3. 使用 project.files()、project.layout.files() 或 project.objects.fileCollection() 方法之一代替 project.fileTree() 方法，以便让 Gradle 能自动访问适当的属性。因为 project.files()、project.layout.files() 和 project.objects.fileCollection() 可以将任务作为参数，而 fileTree() 不能 

      ```groovy
      tasks.register('instrumentClasses2', Instrument) {
          classFiles.from layout.files(tasks.named('compileJava'))
          destinationDir = file(layout.buildDirectory.dir('instrumented'))
      }
      ```

   上述方法的缺点是源任务的所有文件输出都会成为目标(此处是 instrumentClasses2)任务的输入文件。当源任务只有一个文件输出(file-based output)是 OK 的(比如 JavaCompile 任务)；但是当源任务有多个输出，而我们只想指定其中一个作为目标任务的输入时，上述方法就不行了。此时需要使用下面的方法。

   - 使用 builtBy 方法(等价于 task 的 dependsOn 方法)明确告诉 Gradle 哪个任务生成输入文件：

   ```groovy
   tasks.register('instrumentClassesBuiltBy', Instrument) {
       classFiles.from fileTree(tasks.named('compileJava').map { it.destinationDir }) {
           // 声明产生此 ConfigurableFileCollection 的任务
           // Gradle 会自动推导出任务之间的依赖关系
           builtBy tasks.named('compileJava')
       }
       destinationDir = file(layout.buildDirectory.dir('instrumented'))
   }
   ```

##### 增量状态缓存
   
使用 Gradle 的 InputChanges API 并不是创建增量构建任务的唯一方法。Kotlin 编译器等工具内置了增量功能。这些功能实现的方式通常是编译器将一些有关上次执行状态的分析数据存储在某个文件中。如果这样的状态文件是可重定位的，那么它们可以被视为任务的输出。这样当任务的运行结果被从缓存中加载时，下次执行也可以使用从缓存中加载的分析数据

但是，如果状态文件是不可重定位的，那么它们就不能通过构建缓存共享。实际上，当从缓存加载任务时，必须清理任何此类状态文件，以防止旧状态在下次执行时搞乱编译工具。

**通过 task.localState.register() 方法声明这些陈旧文件或使用 @LocalState 注释标记属性，Gradle 可以确保删除这些旧的状态文件**

##### 禁用最新检查

Gradle 会自动处理对输出文件和目录的最新检查。但当任务输出不是普通的产物，如对 Web 服务或数据库表的更新；或者有时我们需要有一个始终应该运行的任务。该怎么做呢？

此时可以**使用 Task.doNotTrackState() 方法，完全禁用任务的最新(up-to-date)检查；如果是自定义任务，还可以使用 @UntrackedTask 注解代替**，而不是调用 Task.doNotTrackState() 方法。

例如 Gradle 可以集成如 Git 的外部工具，它们都做自己的最新(up-to-date)检查。此时 Gradle 再进行最新检查就没有多大意义了。我们可以通过在包装工具的任务上使用 @UntrackedTask 注解或者使用运行时 API 方法 Task.doNotTrackState() 来禁用 Gradle 的最新检查。

```groovy
// 类：buildSrc/src/main/java/org/example/GitClone.java
@UntrackedTask(because = "Git tracks the state")                                           
public abstract class GitClone extends DefaultTask {
    @Input
    public abstract Property<String> getRemoteUri();
    @Input
    public abstract Property<String> getCommitId();
    @OutputDirectory
    public abstract DirectoryProperty getDestinationDir();

    @TaskAction
    public void gitClone() throws IOException {
        File destinationDir = getDestinationDir().get()
            .getAsFile()
            .getAbsoluteFile(); 
        String remoteUri = getRemoteUri().get();
        // ...
    }
}

tasks.register("cloneGradleProfiler", GitClone) {
    destinationDir = layout.buildDirectory.dir("gradle-profiler")                      
    remoteUri = "https://github.com/gradle/gradle-profiler.git"
    commitId = "d6c18a21ca6c45fd8a9db321de4478948bdf801b"
}
```

##### 自定义 up-to-date 检查

Gradle 会自动处理对输出文件和目录的最新检查，但如果任务输出不标准，如对 Web 服务或数据库表的更新。Gradle 在检查时就无法判断任务是否是最新的了。此时我们可以使用 TaskOutputs 上的 upToDateWhen() 方法，增加自定义的检查逻辑。该方法需要一个闭包参数，用于确定任务是否是最新的。例如，我们可以从数据库中读取数据库模式的版本号。或者您可以检查数据库表中的特定记录是否存在或已更改。

请注意，使用自定义最新检查(up-to-date check)的原则是自定义最新检查应可以节省我们的时间。我们不应添加比标准方式执行任务，花费更多资源或更多时间的检查代码。事实上，如果一个任务最终要频繁运行，因为它很少是最新(up-to-date)的，那么它可能根本不值得最新检查。

一个常见的错误混淆使用 upToDateWhen() 而不是使用 Task.onlyIf()。如果我们想用与任务输入和输出无关的某些条件跳过任务，那么我们应该使用 onlyIf()。例如，在设置或未设置特定属性时跳过任务。

##### 规范补充

对于最新(up-to-date)检查和构建缓存，Gradle 需要确定两个任务输入属性是否具有相同的值(value)。为此，Gradle 首先对两个输入进行规范化处理，然后比较结果。例如，对于类路径(compile classpath)，Gradle 从类路径中的类中提取 ABI 签名，然后比较上次运行结果和当前运行结果的签名，如 [The Java Plugin (gradle.org)](https://docs.gradle.org/current/userguide/java_plugin.html#sec:java_compile_avoidance) 中所述。

###### 排除整个文件

规范化适用于类路径上的所有 zip 文件（例如 jars、wars、aars、apks 等）。这允许 Gradle 识别两个 zip 文件何时在功能上相同，即使 zip 文件本身可能由于元数据（例如时间戳或文件顺序）而略有不同。规范化不仅适用于在类路径上的直接 zip 文件，还适用于 嵌套在目录内或者 zip 文件内的 zip 文件。

我们可以自定义 Gradle 内置的运行时类路径规范化策略。所有带有 @Classpath 注释的输入都被认为是运行时类路径。

假设我们想将文件 build-info.properties 添加到所有生成的 jar 中，该 jar 包含相关构建信息(如构建开始时的时间戳或用于标识发布工件的 CI 作业的某个 ID)。该 jar 是测试任务(test task)的运行时类路径的一部分。但是该 jar 在每次构建调用时都会发生变化(build-info.properties 文件会变化)，因此 test 任务永远不会是最新的，test 任务永远不会从构建缓存中提取。这种情况下，为了让增量构建生效，我们可以使用 Project.normalization(org.gradle.api.Action) 告诉 Gradle 在项目(project)级别的运行时类路径上忽略此文件的变化。

```groovy
normalization {
    runtimeClasspath {
        ignore 'build-info.properties'
    }
}
```

如果将此类文件添加到 jar 文件中是我们为构建中的所有项目执行的操作，并且我们希望为所有消费者都过滤此文件，则我们应考虑在[Sharing Build Logic between Subprojects (gradle.org)](https://docs.gradle.org/current/userguide/sharing_build_logic_between_subprojects.html#sec:convention_plugins)中配置此类规范以在子项目之间共享它(就像 CopySpec 一样的共享逻辑)。

此配置的效果是在进行最新检查和构建缓存计算 key 时，build-info.properties 的更改将被忽略。请注意，这不会改变 test 任务的运行时行为——即任何 test 仍然能够加载 build-info.properties 并且运行时类路径仍然与之前相同。

###### 排除部分属性

默认情况下，属性文件(即以 .properties 扩展名结尾的文件)将被规范化以忽略注释、空格和属性顺序的差异。 但是有时某些属性会对运行时产生影响，而另一些则不会。此时排除整个文件会影响运行时的属性选项。而我们又想将不影响运行的属性从最新检查和构建缓存键计算中排除。

此时可以使用 properties 将忽略属性的规则应用于一组特定的文件。如果文件与规则匹配且无法作为属性文件加载，则它将视为普通文件，参与到 up-to-date 检查或者构建缓存计算。换句话说，如果文件不能作为属性文件加载，我们对空格、属性顺序或注释的任何更改都可能导致任务过期或导致缓存缺失。

```groovy
normalization {
    runtimeClasspath {
        properties('**/build-info.properties') {
            ignoreProperty 'timestamp'
        }
    }
}

// 例子 2
normalization {
    runtimeClasspath {
        // 针对所有 properties files
        properties {
            ignoreProperty 'timestamp'
        }
    }
}
```

###### Java META-INF 设置

对于 jar 包中 META-INF 目录中的文件，由于它们存在运行时影响，并不总是可以忽略整个文件。

META-INF 中的清单文件可以被规范化，以忽略注释、空格和顺序差异。清单中的属性名称也会以不区分大小写的方式进行比较。

```groovy
normalization {
    runtimeClasspath {
        // 忽略 attributes
        metaInf {
            ignoreAttribute("Implementation-Version")
        }
    }
}

normalization {
    runtimeClasspath {
        // 忽略 property keys
        metaInf {
            ignoreProperty("app.version")
        }
    }
}
// 忽略 META-INF/MANIFEST.MF
normalization {
    runtimeClasspath {
        metaInf {
            ignoreManifest()
        }
    }
}
// 忽略 META-INF 中的所有文件和目录
normalization {
    runtimeClasspath {
        metaInf {
            ignoreCompletely()
        }
    }
}
```

### task 的运行

在讲解了增量构建的相关知识之后，我们可以来讲讲 task 运行的一些知识点了。

#### 构建缓存

Gradle 的构建缓存与 task 的增量构建功能密切相关，构建缓存会使用与最新检查(up-to-date check)类似的逻辑，以节省构建时间。

默认情况下，构建缓存并未启用。我们可以通过多种方式启用构建缓存

- 在命令行上使用 --build-cache 语句启用。当对当前一次构建生效

- 将 org.gradle.caching=true 配置项放入 gradle.properties 文件。Gradle 将尝试为所有构建重用之前构建的输出，除非使用 --no-build-cache 语句明确禁用。

如果任务的输出缓存可用，则任务的输入还用于计算构建缓存的键值，该构建缓存用于加载任务输出。具体讲解可见：[Build Cache (gradle.org)](https://docs.gradle.org/current/userguide/build_cache.html#sec:task_output_caching)

#### 并行运行

默认情况下，task 之间不会并行执行，除非一个 task 正在等待另一个异步动作，并且另一个不依赖于它的 task 已准备好去执行。

启动构建时，可以通过设置 --parallel flag 启用 task 的并行执行。在并行模式下，不同 project(即在多项目 multi-project 构建中) 的 task 能够并行执行

当使用"--parallel"选项时，Gradle 可以使用此信息来决定如何运行任务。比如以下一些场景：

- Gradle 将在选择下一个要运行的任务时检查任务的输出，并避免并发执行写入同一输出目录的任务。

- Gradle 将使用有关任务销毁哪些文件(由 Destroys 注解指定)的信息，并避免运行在另一个任务正在使用或创建文件时删除这些相同文件(反之亦然)的任务

- Gradle 还可以确保创建文件的任务(生产者任务)运行时，使用这些文件的任务(消费者)不运行，避免在生产者和消费者之间运行删除这些文件的任务。

通过提供任务输入和输出信息，Gradle 可以推断任务之间(针对输入输出)的创建/消费/销毁关系，并可以确保任务执行时不会违反这些关系

#### 任务验证

在执行构建时，Gradle 会检查是否使用正确的注解声明了任务类型。验证时 Gradle 会试图定位问题，例如注解被用在不兼容的类型或 setter 上。任何未使用输入/输出相关注解进行注解的 getter 也会被标记。这些检测出的问题会导致构建失败或在执行任务时标注为废弃。

可以做验证警告的任务会在没有任何优化的情况下执行。具体来说，它们有以下特点：

- 不执行 up-to-date 检查

- 不从构建缓存加载或存储在构建缓存中

- 即使在启用了并行执行的情况下，也不与其他任务并行执行

- 不进行增量执行

- 在执行无效性验证任务之前，文件系统状态(也称为虚拟文件系统)在内存中的表示也是无效的

#### 持续构建

定义任务输入和输出的另一个好处是持续构建。由于 Gradle 知道任务依赖于哪些文件，因此如果其任何输入发生更改，它可以自动再次运行任务。通过在运行 Gradle 时激活持续构建(通过 --continuous 或 -t 选项)，您将让 Gradle 进入一种状态，在这种状态下，它会不断检查更改并在遇到此类更改时执行需要执行的任务(任务的输入与这些更改关联)

我们可以在[Command-Line Interface (gradle.org)](https://docs.gradle.org/current/userguide/command_line_interface.html#sec:continuous_build)中找到有关此功能的更多信息

#### 添加规则

上面我们介绍了，在 TaskContainer 中，我们可以使用 task 的 name 获取 task 实例。但是当 TaskContainer 中不存在对应名称的任务时，我们有没有办法拿到任务实例呢？答案是可以的。有两种方式实现这种效果。

- 一种是当 task 不存在时，我们主动像 TaskContainer 中 add 一个任务实例。

- 另一种方法是可以使用 TaskContainer.addRule(String description, Action<String> ruleAction) 方法为任务添加任务规则。当我们使用了不在列表中的名称获取任务实例时，会调用到规则闭包里的代码。

实际上，addRule 方法没有定义在 TaskContainer 中，而是定义在其父类 NamedDomainObjectCollection 中(可以用 name 定位元素的集合)。所以 addRule 实际上不是针对 Task 添加规则的方法，而是针对集合中某一元素添加规则的方法。

addRule 的第二个入参 Action<String> 可以等价替换为 Groovy 的闭包。闭包中的变量代表当前元素的名称(name)，我们可以使用该名称定位元素。

```groovy
tasks.addRule("Pattern: ping<ID>") { String taskName ->
    if (taskName.startsWith("ping")) {
        // 使用 Project.task 方法创建任务
        task(taskName) {
            doLast {
                println "Pinging: " + (taskName - 'ping')
            }
        }
    }
}

tasks.register('groupPing') {
    dependsOn 'pingServer1', 'pingServer2'
}
```

Gradle Task 的内容就先讲这么多。下面让我们看看 Gradle 的产物。

## Gradle 产物

在讲解 Gradle 产物的相关知识前，我们需要先明确 Gradle 中的几个概念。

在 Gradle 和其他管理工具中，有 component 和 artifact 的概念。前者可以翻译为组件，实际上就是指编译后的产物；后者可以翻译为工件，实际上就是指编译过程中或临时的、或最终的一个文件。另外还有 dependency 的概念，dependency 可以翻译为依赖，实际上就是指产物里用到的，非本项目的能力，能力由代码定义。

Gradle 和其他管理工具的一个明显差别是 Gradle 还有一个 Variant 的概念，Variant 可以翻译为变体，是 component 的不同使用方式，如 doc 文档或者 jar。如果把 Component 视为抽象类，那么 Variant 就是其具体实现。

### 组件模型

#### Maven 组件模型

![Maven组件模型](/imgs/Maven组件模型.webp)

#### Gradle 组件模型

在 Gradle 中，artifact 被附加到一个变体，并且每个变体可以有一组不同的依赖关系(dependencies)。当有多个变体时，Gradle 如何知道选择哪个变体呢？实际上，Gradle 使用属性([Variant Attributes](https://docs.gradle.org/current/userguide/variant_attributes.html#variant_attributes))来匹配变体。

Gradle 中有区分两种组件：本地组件和外部组件。前者是如 Project 一样使用项目源代码构建的，后者是发布到远程仓库的。对于本地组件，变体与配置(Configuration)映射；对于外部组件，变体根据已发布的 Gradle Module Metadata 定义或从 Ivy/Maven Metadata 解析得到([Understanding variant selection (gradle.org)](https://docs.gradle.org/current/userguide/variant_model.html#sec:mapping-maven-ivy-to-variants))。

注意本文到此处，我们已提及了两种"属性"：Provider/Property 和 Attribute，虽然中文都翻译为属性，但是他们有着不同的使用场景。

组件定义变体的数量没有限制。虽然通常一个组件至少有一个变体。虽然组件的功能通常被变体代替，但是组件也能对外公开文档或源代码等内容。对于相同用途的不同使用者(消费者)，组件也可以定义不同的变体。例如在编译时，针对 Linux、Windows 和 macOS 系统，组件能有不同的 headers。

![Gradle组件模型](/imgs/Gradle组件模型.webp)

### 变体

由于历史原因，在部分文档、DSL 或 API 中，变体(Variants)和配置(configurations)可以互换使用。所有组件都提供变体，并且这些变体由一个配置支持。但是并非所有配置都是变体，因为配置还可能被用于声明或解析依赖项(dependencies)。

简单的讲，就是 variant 都会对应一个 configuration。但是 configuration 可能并不一定对应 variant，因为 configuration 可能对应 dependencies。

#### 变体属性

属性(attribute)是类型安全的键值对(key-value)，在变体或者配置中定义产生(生产者)，在配置解析时使用(配置是消费者)。

可解析的配置(消费者)可以定义任意数量的属性。每个属性都有助于缩小可选择变体的范围。属性值可以不精准匹配。

变体(生产者)也可以定义任意数量的属性，这些属性应该描述如何 Gradle 使用变体。例如，Gradle 使用 org.gradle.usage 属性来描述如何使用组件(编译、运行时执行等场景)。变体具有的属性通常比选中它时所需的属性更多。

属性包含 Gradle 官方文档中介绍了几种 Gradle 定义的标准属性和开发者自定以的属性：

![变体属性介绍](/imgs/变体属性介绍.webp)

##### 自定义属性

属性是类型确定的 key，在 build script 或者 plugin 中，我们可以创建属性。下面是实现步骤：

1. 使用 Attribute<T> 的相关方法创建一个属性。属性的类型支持绝大多数 Java 主要类，例如 String 和 Integer，或者任何继承实现了 org.gradle.api.Named 的类。

2. 必须在 dependencies handler 的 attribute schema 中声明属性

3. configurations 为 attribute 设值。对于扩展了 Named 的属性，其值必须通过 object factory 创建：

```groovy
// `String` 类型的 attribute
def myAttribute = Attribute.of("my.attribute.name", String)
// `Usage` 类型的 attribute
def myUsage = Attribute.of("my.usage.attribute", Usage)

dependencies.attributesSchema {
    // 注册 attribute 到 attributes schema
    attribute(myAttribute)
    attribute(myUsage)
}

configurations {
    // 找到名为 myConfiguration 的 Configuration
    myConfiguration {
        attributes {
            // attributes 中添加 myAttribute 属性
            attribute(myAttribute, 'my-value')
            // object factory 创建 Named Attribute 的值
            attribute(myUsage, project.objects.named(Usage, 'my-value'))
        }
    }
}
```

##### 属性兼容性规则

在某些情况下，生产者可能没有完全满足消费者的要求，但此时可能会有一个可以使用的变体。例如，如果消费者需要一个 library 的 API 变体而生产者没有完全匹配的变体，则可以认为 runtime 变体是兼容的。这是一个需要发布到外部仓库的 library 经常遇到的典型场景。在这种情况下，我们知道即使我们没有完全匹配(API)，我们仍然可以针对 runtime 变体进行编译(它包含的内容比我们需要的要多，使用起来是 ok 的)。

- Gradle 可以为每个属性定义了属性兼容性规则(attribute compatibility rules)。兼容性规则的作用是根据消费者的要求解释哪些属性值是兼容的。

- 属性兼容性规则必须通过属性匹配策略(AttributeMatchingStrategy<T>)注册，我们可以从属性模式(AttributesSchema)中获取该策略

##### 属性消歧规则

由于一个属性可以设置多个值，并且多个值之间可以兼容(如目标需要 Java 11，而变体提供了 Java 8 和 Java 7)。所以 Gradle 需要在所有兼容的候选值中选择"最佳"候选值。这个逻辑被称为“消歧”

- 消歧功能是通过实现属性消歧规则(AttributeDisambiguationRule<T>)来完成的。

- 属性消歧规则必须通过属性匹配策略(AttributeMatchingStrategy<T>)注册，我们可以从属性模式(AttributesSchema)中获取该策略。

#### 匹配变体属性

变体名称主要用于调试目的和获取错误消息，不参与变体匹配——只有变体的属性参与匹配。

变体的匹配过程可以将 Gradle 视作一个选择器。消费者定义变体应具备哪些属性，以及属性具备哪些值；生产者(即变体)也定义自己哪些属性和值。两者将信息交给 Gradle，由 Gradle 的依赖管理引擎(Gradle's dependency management engine)选择最为匹配的变体。

![Gradle的依赖管理引擎](/imgs/Gradle的依赖管理引擎.webp)

Gradle 通过将消费者请求的属性与生产者定义的属性进行匹配，来选择变体(variant aware selection)。注意有两个例外绕过算法定义的规则：

- 当生产者没有变体(Variant)时，将选择默认工件。

- 当消费者通过名称明确选择配置(Configuration)时，将选择与配置对应的工件。

##### 例子

在实际的构建中，消费者和生产者通常具有不止一种属性。例如 Gradle 中的一个 Java Library 项目涉及到了几个不同的属性。

- org.gradle.usage：描述如何使用变体

- org.gradle.dependency.bundling：描述变体如何处理依赖项(shadow jar(有修改包名的 jar) vs fat jar(包含所有依赖的 jar) vs regular jar(一般的 jar))

- org.gradle.libraryelements，描述变体如何打包(classes 或 jar)

- org.gradle.jvm.version 描述了变体最小的目标 Java 版本

- org.gradle.jvm.environment 描述了变体的目标 JVM 类型

假设一个消费者想要使用 Java 8 的库运行测试逻辑，生产者支持两个不同的 Java 版本(Java 8 和 Java 11)的场景。下面是对应操作。

1. 消费者定义它需要哪个版本的 Java：消费者想要解析一个具备下面两个条件的变体：

   - 具有 org.gradle.usage=JAVA_RUNTIME，表示变体可以在运行时使用

   - 具备 org.gradle.jvm.version=8，表示最低运行版本是 Java 8

2. 生产者需要公开组件的不同变体：组件同时存在 API(编译)和运行时变体。组件的 Java 8 和 Java 11 版本中都存在这些变体。

||||
|:-:|:-:|:-:|
|**变体名**|**变体具备的属性**|**变体作用**|
|apiJava8Elements|org.gradle.usage=JAVA_APIorg.gradle.jvm.version=8|用于 Java 8 消费者的 API|
|用于 Java 8 消费者的 API|org.gradle.usage=JAVA_RUNTIME</br>org.gradle.jvm.version=8|用于 Java 8 消费者的运行时|
|apiJava11Elements|org.gradle.usage=JAVA_API</br>org.gradle.jvm.version=11|用于 Java 11 消费者的 API|
|runtime11Elements|org.gradle.usage=JAVA_RUNTIME</br>org.gradle.jvm.version=11|用于 Java 11 消费者的运行时|

3. 最后，Gradle 通过查看所有属性来选择最合适的变体：

   - 消费者想要一个具有与 org.gradle.usage=JAVA_RUNTIME 和 org.gradle.jvm.version=8 兼容属性的变体

   - 生产者与消费者的属性匹配结果。runtime11Elements 和 apiJava11Elements 不能在 Java 8 上运行，而 apiJava8Elements 不具备 org.gradle.usage=JAVA_RUNTIME 属性

   |||||
   |:-|:-|:-|:-:|
   ||**org.gradle.usage=JAVA_RUNTIME**|**org.gradle.jvm.version=8**|**结果**|
   |apiJava8Elements|org.gradle.usage=JAVA_API ×|org.gradle.jvm.version=8 ✔|×|
   |runtime8Elements|org.gradle.usage=JAVA_RUNTIME ✔|org.gradle.jvm.version=8 ✔|✔|
   |apiJava11Elements|org.gradle.usage=JAVA_API ×|org.gradle.jvm.version=11 ×|×|
   |runtime11Elements|org.gradle.usage=JAVA_RUNTIME ✔|org.gradle.jvm.version=11 ×|×|

4. 最终 Gradle 选择的是 runtime8Elements 变体，向消费者提供来自 runtime8Elements 变体的工件和依赖项

###### 变体的兼容性

- 如果消费者将 org.gradle.jvm.version 设置为了 7，则 Gradle 的依赖解析操作将会失败，并显示一条用于说明没有合适的变体的错误消息。Gradle 认为消费者需要兼容 Java 7 的 library，而生产者可用的最低 Java 版本是 8。

- 如果消费者将 org.gradle.jvm.version 设置为了 15，则 Gradle 认为 Java 8 或 Java 11 变体都可以工作，最终 Gradle 将选择 Java 版本最高的(11)兼容的变体。

##### 处理匹配错误

当选择最合适的组件变体时，解析可能会失败，产生以下错误：

- 歧义错误：生产者有不止一个变体匹配消费者的属性

- 不兼容错误：生产者没有变体匹配消费者的属性

###### 处理歧义错误

歧义的变体选择的报错信息如下所示，project :ui 是消费者，project :lib 是生产者。

- 下面的报错信息中，所有兼容的候选变体都与其属性一起显示

   - 首先显示不匹配的属性，因为它们可能是选择正确变体时缺失的部分

   - 兼容属性排在第二位，因为它们表明消费者想要什么以及变体(生产者)如何匹配消费者的请求

   - 此处不会列举有任何不兼容的属性，因为这些变体不会被视为候选者

- 错误修复的关键不在于属性匹配(attribute matching)，而在于能力匹配(capability matching)，这显示在变体名称旁边。因为这两个变体都有效地提供了相同的属性和功能，所以它们无法消除歧义。因此，在这种情况下，修复错误的最好方式是在生产者端(project :lib)提供不同的能力，并在消费者端(project :ui)指定要选择的能力。

```groovy
> Could not resolve all files for configuration ':compileClasspath'.
   > Could not resolve project :lib.
     Required by:
         project :ui
      > Cannot choose between the following variants of project :lib:
          - feature1ApiElements
          - feature2ApiElements
        All of them match the consumer attributes:
          - Variant 'feature1ApiElements' capability org.test:test-capability:1.0:
              - Unmatched attribute:
                  - Found org.gradle.category 'library' but wasn't required.
              - Compatible attributes:
                  - Provides org.gradle.dependency.bundling 'external'
                  - Provides org.gradle.jvm.version '11'
                  - Required org.gradle.libraryelements 'classes' and found value 'jar'.
                  - Provides org.gradle.usage 'java-api'
          - Variant 'feature2ApiElements' capability org.test:test-capability:1.0:
              - Unmatched attribute:
                  - Found org.gradle.category 'library' but wasn't required.
              - Compatible attributes:
                  - Provides org.gradle.dependency.bundling 'external'
                  - Provides org.gradle.jvm.version '11'
                  - Required org.gradle.libraryelements 'classes' and found value 'jar'.
                  - Provides org.gradle.usage 'java-api'
```

###### 处理无匹配变体错误

没有匹配的变体的错误信息如下所示。

- 所有兼容的候选变体都与其属性一起显示。

   - 首先展示不兼容的属性，因为通常它们是帮助我们理解不选择变体的原因的关键。

   - 然后显示其他属性，包括消费者必需和可兼容的属性，以及生产者声明了而消费者没定义的所有属性。

- 与变体的歧义错误类似，我们的目标应该是了解选择哪个变体。在某些情况下，生产者可能没有任何兼容的变体(例如尝试在Java 8 上运行为 Java 11 构建的库)

```groovy
> No variants of project :lib match the consumer attributes:
  - Configuration ':lib:compile':
      - Incompatible attribute:
          - Required artifactType 'dll' and found incompatible value 'jar'.
      - Other compatible attribute:
          - Provides usage 'api'
  - Configuration ':lib:compile' variant debug:
      - Incompatible attribute:
          - Required artifactType 'dll' and found incompatible value 'jar'.
      - Other compatible attributes:
          - Found buildType 'debug' but wasn't required.
          - Provides usage 'api'
  - Configuration ':lib:compile' variant release:
      - Incompatible attribute:
          - Required artifactType 'dll' and found incompatible value 'jar'.
      - Other compatible attributes:
          - Found buildType 'release' but wasn't required.
          - Provides usage 'api'
```

##### 变体属性匹配算法

当组件有许多不同的变体和属性时，找到最合适的变体会变得很复杂。

插件和构建环境可以通过实施兼容性规则、消歧规则或者告诉 Gradle 属性的优先级来影响选择算法。具有更高优先级的属性按顺序兼容匹配。例如在 Java 构建环境中，org.gradle.usage 属性的优先级高于 org.gradle.libraryelements。这意味着如果两个候选对象都具有 org.gradle.usage 和 org.gradle.libraryelements 的兼容值，Gradle 将选择通过 org.gradle.usage 消歧规则检测的候选对象。

Gradle 的依赖解析引擎在寻找最佳结果(可能失败)时会执行以下算法：

1. 每个变体属性值都与消费者需要的属性值进行比较。如果候选变体属性的值与消费者需要的属性值完全匹配，则 Gradle 认为该候选变体是合适的。

2. 如果只有一名候选变体，则该候选变体被选择。

3. 如果多个候选变体都，但其中一个候选变体具有其他候选变体匹配的所有属性，则 Gradle 会选择该候选变体。这是"最长"匹配规则的体现(the "longest" match)。

4. 如果有多个候选变体兼容，并且每个变体都有相同数量的匹配属性，则 Gradle 需要消除候选变体的歧义

   - 对于每个消费者请求的属性，如果候选变体没有匹配消歧规则的值，则 Gradle 将舍弃该候选变体，考虑其他变体

   - 如果属性具有已知的优先级，Gradle 将按照属性优先级进行比较，并在剩下一个候选变体时立即停止，此时可能并未比较完所有属性

   - 如果属性没有已知的优先级，泽 Gradle 必须考虑比较所有属性

5. 如果仍有几个候选变体，Gradle 将开始考虑使用额外的属性，以消除多个候选变体之间的歧义。额外属性是消费者未请求，但至少出现在一个候选人身上的属性。这些额外的属性按优先顺序进行比较。

   - 如果额外属性具有已知的优先级，Gradle 将按照属性优先级进行比较，并在剩下一个候选变体时立即停止

   - 在比较了所有具有优先级的额外属性之后，生于候选变体如果与所有无序的消歧规则兼容，则可以选择它们。

6. 如果还有几个候选变体，Gradle 将再次考虑额外的属性。如果候选变体具有最少数量的额外属性，则可以选择它。

7. 如果最终仍没有候选变体，则匹配解析失败。此时 Gradle 会输出一个步骤 1 中所有兼容候选变体的列表，以帮助开发者调试解决变体匹配失败的错误。

##### 打印变体信息

###### outgoingVariants 任务打印

类似于 dependencyInsight 打印任务([Viewing and debugging dependencies (gradle.org)](https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html#sec:identifying_reason_dependency_selection))，outgoingVariants 打印任务会显示可供项目消费者(the consumers of the project)选择的变体列表。它显示每个变体的功能、属性和工件(the capabilities, attributes and artifacts)。

默认情况下，outgoingVariants 任务会打印有关所有变体的信息。

- 任务接受可选参数 --variant <variantName> ，该参数用于选择要显示的单个变体

- 任务接受 --all 标志，该标志用于打印包含一流的、弃用的配置的信息。

下面的日志信息是在 java-library 项目上，outgoingVariants 任务的输出记录：

```groovy
> Task :outgoingVariants
--------------------------------------------------
Variant apiElements
--------------------------------------------------
Description = API elements for main.

Capabilities
    - new-java-library:lib:unspecified (default capability)
Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-api
Artifacts
    - build/libs/lib.jar (artifactType = jar)

Secondary Variants (*)

    --------------------------------------------------
    Secondary Variant classes
    --------------------------------------------------
        Description = Directories containing compiled class files for main.

        Attributes
            - org.gradle.category            = library
            - org.gradle.dependency.bundling = external
            - org.gradle.jvm.version         = 11
            - org.gradle.libraryelements     = classes
            - org.gradle.usage               = java-api
        Artifacts
            - build/classes/java/main (artifactType = java-classes-directory)

--------------------------------------------------
Variant mainSourceElements (i)
--------------------------------------------------
Description = List of source directories contained in the Main SourceSet.

Capabilities
    - new-java-library:lib:unspecified (default capability)
Attributes
    - org.gradle.category            = verification
    - org.gradle.dependency.bundling = external
    - org.gradle.verificationtype    = main-sources
Artifacts
    - src/main/java (artifactType = directory)
    - src/main/resources (artifactType = directory)

--------------------------------------------------
Variant runtimeElements
--------------------------------------------------
Description = Elements of runtime for main.

Capabilities
    - new-java-library:lib:unspecified (default capability)
Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-runtime
Artifacts
    - build/libs/lib.jar (artifactType = jar)

Secondary Variants (*)

    --------------------------------------------------
    Secondary Variant classes
    --------------------------------------------------
        Description = Directories containing compiled class files for main.

        Attributes
            - org.gradle.category            = library
            - org.gradle.dependency.bundling = external
            - org.gradle.jvm.version         = 11
            - org.gradle.libraryelements     = classes
            - org.gradle.usage               = java-runtime
        Artifacts
            - build/classes/java/main (artifactType = java-classes-directory)

    --------------------------------------------------
    Secondary Variant resources
    --------------------------------------------------
        Description = Directories containing the project's assembled resource files for use at runtime.

        Attributes
            - org.gradle.category            = library
            - org.gradle.dependency.bundling = external
            - org.gradle.jvm.version         = 11
            - org.gradle.libraryelements     = resources
            - org.gradle.usage               = java-runtime
        Artifacts
            - build/resources/main (artifactType = java-resources-directory)

--------------------------------------------------
Variant testResultsElementsForTest (i)
--------------------------------------------------
Description = Directory containing binary results of running tests for the test Test Suite's test target.

Capabilities
    - new-java-library:lib:unspecified (default capability)
Attributes
    - org.gradle.category              = verification
    - org.gradle.testsuite.name        = test
    - org.gradle.testsuite.target.name = test
    - org.gradle.testsuite.type        = unit-test
    - org.gradle.verificationtype      = test-results
Artifacts
    - build/test-results/test/binary (artifactType = directory)

(i) Configuration uses incubating attributes such as Category.VERIFICATION.
(*) Secondary variants are variants created via the Configuration#getOutgoing(): ConfigurationPublications API which also participate in selection, in addition to the configuration itself.
```

从上我们可以看到 java library 定义的两个主要变体，即 apiElements 和 runtimeElements。二者主要区别在于 org.gradle.usage 属性，其值分别为 java-api 和 java-runtime。正如它们所声明的那样，这就是消费者的编译类路径(compile classpath)与运行时类路径(runtime classpath)需要的内容之间的区别。

它还显示了二级变体(secondary variants)，这些变体是 Gradle 项目独有的且未发布。例如，apiElements 中二级变体的类允许 Gradle 在编译 java-library 项目时跳过 JAR 创建。

###### 打印可解析配置

Gradle 提供了一个名为 resolvableConfigurations 的免费打印任务，它显示一个项目的可解析配置(the resolvable configurations of a project)，这些配置可以用于添加和解析依赖项。该报告将列出配置的属性和配置扩展的任何配置。它还会列出在解析过程中，受兼容性规则或消歧规则影响的任何属性的摘要信息。

默认情况下，resolvableConfigurations 打印有关所有纯可解析配置(purely resolvable configurations)的信息。这些是标记为可解析但未标记为可消费的配置。尽管一些可解析的配置也被标记为可使用的，但这些是遗留的旧的配置，不应在构建脚本中使用它们添加依赖项。

- 任务接受可选参数 --configuration <configurationName>， 该参数用于选择要显示的单个配置。

- 任务接受 --all 标志，以包打印含有关遗留的、弃用的配置的信息。

- 任务接受 --recursive 标志，以打印被扩展配置的信息，这些配置是可传递而不是直接被扩展复写

下面的日志信息是在 java-library 项目上，resolvableConfigurations 任务的输出记录：

```groovy
> Task :resolvableConfigurations
--------------------------------------------------
Configuration annotationProcessor
--------------------------------------------------
Description = Annotation processors and their dependencies for source set 'main'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-runtime

--------------------------------------------------
Configuration compileClasspath
--------------------------------------------------
Description = Compile classpath for source set 'main'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = classes
    - org.gradle.usage               = java-api
Extended Configurations
    - compileOnly
    - implementation

--------------------------------------------------
Configuration runtimeClasspath
--------------------------------------------------
Description = Runtime classpath of source set 'main'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-runtime
Extended Configurations
    - implementation
    - runtimeOnly

--------------------------------------------------
Configuration testAnnotationProcessor
--------------------------------------------------
Description = Annotation processors and their dependencies for source set 'test'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-runtime

--------------------------------------------------
Configuration testCompileClasspath
--------------------------------------------------
Description = Compile classpath for source set 'test'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = classes
    - org.gradle.usage               = java-api
Extended Configurations
    - testCompileOnly
    - testImplementation

--------------------------------------------------
Configuration testRuntimeClasspath
--------------------------------------------------
Description = Runtime classpath of source set 'test'.

Attributes
    - org.gradle.category            = library
    - org.gradle.dependency.bundling = external
    - org.gradle.jvm.environment     = standard-jvm
    - org.gradle.jvm.version         = 11
    - org.gradle.libraryelements     = jar
    - org.gradle.usage               = java-runtime
Extended Configurations
    - testImplementation
    - testRuntimeOnly

--------------------------------------------------
Compatibility Rules
--------------------------------------------------
Description = The following Attributes have compatibility rules defined.

    - org.gradle.dependency.bundling
    - org.gradle.jvm.environment
    - org.gradle.jvm.version
    - org.gradle.libraryelements
    - org.gradle.plugin.api-version
    - org.gradle.usage

--------------------------------------------------
Disambiguation Rules
--------------------------------------------------
Description = The following Attributes have disambiguation rules defined.

    - org.gradle.category
    - org.gradle.dependency.bundling
    - org.gradle.jvm.environment
    - org.gradle.jvm.version
    - org.gradle.libraryelements
    - org.gradle.plugin.api-version
    - org.gradle.usage
```

从上面我们可以看到用于解析依赖的两个主要配置，compileClasspath 和 runtimeClasspath，以及它们对应的测试配置(corresponding test configurations)。

#### 将 Maven/Ivy 映射为 Gradle 变体

因为 Android 中没用到 Maven 管理项目，此处就不细讲了

Maven 和 Ivy 中都没有变体的概念，只有 Gradle Module Metadata 原生支持变体。通过使用不同的变体派生策略，Gradle 仍然可以与 Maven 和 Ivy 一起工作。

映射的主要工作是将 Gradle Module Metadata 与 pom.xml 或 ivy.xml 这样的元数据文件相互转换。Gradle Module Metadata 是在存储仓库中发布的模块的元数据格式，它包含有关变体的详细信息。存储仓库可以是 Maven、Ivy 或其他类型的存储仓库。Gradle Module Metadata 详情见：[gradle-module-metadata](https://github.com/gradle/gradle/blob/master/subprojects/docs/src/docs/design/gradle-module-metadata-latest-specification.md)

具体映射规则见：[Understanding variant selection (gradle.org)](https://docs.gradle.org/current/userguide/variant_model.html#sec:mapping-maven-ivy-to-variants)

### 相关类图

我们可以在 project 中使用 components 和 configurations 打印 component 相关实现类的信息。

```groovy
// 实验代码
task printConfig {
    doLast {
        // configuration 类型是 DefaultConfiguration
        project.configurations.forEach {
            // Artifact 类型是 DecoratingPublishArtifact
            it.getAllArtifacts().forEach { art ->
                println("ZWCTest, config type: " + it.class + ", artifact type: " + art.class)
            }
        }
        // component 类型是 DefaultAdhocSoftwareComponent
        project.components.forEach {
            println("ZWCTest, components type: " + it.class)
        }
    }
}
```

使用 project.getComponents() 方法可以获取到当前项目的组件产物，我们在任务中打印出 Component 的实际类型，得到的结果是 DefaultAdhocSoftwareComponent。以 javaPlugin 为例，DefaultAdhocSoftwareComponent 的相关类如下：

![Component相关类](/imgs/Component相关类.webp)

我们实际上已经在上图中把 Component - Variant - Configuration - Artifact 这条线连起来了。针对该图，有以下说明：

- 就 Component 而言。DefaultAdhocSoftwareComponent 是由工厂类 DefaultSoftwareComponentFactory 生成的，而工厂类是由 Gradle Plugin 指定的

   ```groovy
   // JavaPlugin 部分代码
   public class JavaPlugin implements Plugin<Project> {
       public void apply(final Project project) {
           configureArchivesAndComponent(project, javaExtension);
       }
    
       private void configureArchivesAndComponent(Project project, final JavaPluginExtension pluginExtension) {
           registerSoftwareComponents(project);
       }
    
       private void registerSoftwareComponents(Project project) {
           AdhocComponentWithVariants java = softwareComponentFactory.adhoc("java");
           project.getComponents().add(java);
       }
   }
   ```

- 就 Variant 而言，我们在配置 Gradle 时，可以将其视为 Configuration，因为二者都对应这 dependencies 和 artifacts。Configuration 是 Gradle 暴露给开发者的接口，本文会重点讲解 Configuration 的相关知识。

- 就 Artifact 而言，我们可以将其视作文件(txt/jar/zip/apk 等等)或者文件夹，我们可以配置文件的名称、类型、后缀名、修饰符等等，在上面讲解任务增量编译的知识时，我们讲解过相关知识，此处就不细讲了。

## Configuration 类功能

Configuration 可以翻译为配置，是 Gradle 中一个比较重要的功能。一个 Project 可以有多个 Configuration，他们都放在 ConfigurationContainer 中(配置集合)，可用通过 Project.configurations 方法拿到配置集合。Configuration 包含 Dependency 和 Artifact 两大块。配置将声明的依赖项用于特定目的。

Gradle 项目声明的每个依赖项都有特定的适用范围。例如，一些依赖项用于编译源代码，而其他依赖项只需要在运行时使用。 Gradle 在配置的帮助下表示依赖项的范围。每个配置都可以用一个唯一的名称来标识。

许多 Gradle 插件都会向我们的项目添加预定义好的配置。例如，Java 插件添加配置以表示进行源代码编译、执行测试等时所需的各种类路径(详情见[The Java Plugin (gradle.org)](https://docs.gradle.org/current/userguide/java_plugin.html#sec:java_plugin_and_dependency_management))。

![Configuration示例图](/imgs/Configuration示例图.webp)

按照惯例，我们还是先把配置和配置集合的类图放上，方便按点讲解功能点：

![Configuration_API](/imgs/Configuration_API.webp)

可以看出，Configuration 的大量功能都于依赖相关。实际上，Configuration 和 DependencyHandler 提供的许多功能都相同，只是二者的作用范围不同：前者针对的是 Configuration 中的所有依赖，后者针对的是单个依赖。

### 配置的继承和组合

一个配置可以扩展其他配置以形成继承的层次结构。子配置继承了为父配置声明的全部依赖项集合。配置的继承被 Gradle 的核心插件大量使用(如 Java 插件)。例如，testImplementation 配置扩展了 implementation 配置。使用配置的继承有一个实际目的：测试用例需要在测试类自身依赖项的基础上，测试目标代码的依赖项。例如一个 Java 项目如果在代码中导入了 Guava。则在使用 JUnit 编写和执行测试代码时，也需要导入 Guava。

![Configuration继承](/imgs/Configuration继承.webp)

在 JavaPlugin 的具体实现中，testImplementation 和 implementation 配置通过调用方法 Configuration.extendsFrom(Configuration...) 形成了继承的层次结构。配置可以扩展任何其他配置，而不管它在 build script 或 plugin 中的定义如何。

![Configuration继承代码实例](/imgs/Configuration继承代码实例.webp)

假设我们想要编写一套冒烟测试，每个冒烟测试用例都会进行 HTTP 调用以验证 Web 服务功能。同时该项目已经使用了 JUnit 作为底层测试框架。那么我们可以定义一个名为 smokeTest 的新配置，它从 testImplementation 配置扩展以复用现有的测试框架依赖。代码如下

```groovy
// Configuration 已实现了 Namer，可通过名称定位。
configurations {
    // Gradle 已兼容语法，等价于 configurations["smokeTest"]
    smokeTest.extendsFrom testImplementation
}

dependencies {
    testImplementation 'junit:junit:4.13'
    smokeTest 'org.apache.httpcomponents:httpclient:4.5.5'
}
```

### 可解析和可消费的配置

配置是 Gradle 依赖解析的基本部分。在依赖解析的上下文中，区分消费者和生产者是很有用的。根据配置的使用目的，配置至少具有 3 个不同的角色：

1. 单纯作为存放依赖的容器，声明依赖关系

2. 被消费者使用，解析一组文件的依赖(可解析的消费者)

3. 被生产者使用，将可消费的配置(生产者生产的东西可消费。通常是生产者向消费者提供了变体)公开以供其他项目使用，配置中通常包括 artifacts 及 artifacts 的依赖项(可消费的生产者)

此处我们用一个示例作为说明：假设有 app 和 lib 两个 project。

#### 可解析的配置

让我们先站在 app 一方思考些问题。app 使用其他项目项目提供的依赖，是一个消费者。如果我们需要根据配置的用途，来配置 app 的 Configuration，此时怎么区分呢？答案是我们可以使用 canBeResolved 区分出单纯的 Configuration 和有明确用途的 Configuration。

可解析的配置(Resolvable configurations)是我们可以为其计算依赖图的配置，它包含进行依赖解析所需的所有信息。我们要为该配置计算生成一个依赖图，并解析图中的组件(components)，最终得到工件(Artifacts)。

可解析的配置继承至少一个不可解析的配置(单纯的依赖容器)。

将 canBeResolved 设置为 false 意味着配置不可解析，这样的配置只是为了声明依赖关系。尝试解析 canBeResolved=false 的配置会出错。某种程度讲，canBeResolved=false 的配置类似于抽象类，抽象类不能被实例化；而 canBeResolved=true 则类似于具体类，具体类继承自抽象类，可以被实例化。根据实际使用(如 compile classpath, runtime classpath 等不同的使用场景)，它可以解析为不同的图。

下面的代码是 app project 的一段脚本配置。有 3 种具有不同配置，根据配置的用途，理解如下：

- someConfiguration 的 canBeResolved 设置为 false，对应定位 1。它只是一个单纯的用于容纳依赖的容器

- compileClasspath 和 runtimeClasspath 的 canBeResolved 设置为 true，对应定位 2。它们是要解析的配置，它们分别包含项目的编译时类路径和运行时类路径

```groovy
// 例子
configurations {
    // 声明一个名为 someConfiguration 的 configuration
    // 语法解释见下方
    someConfiguration
    someConfiguration.canBeResolved=false
}
dependencies {
    // 添加一个 project 依赖
    someConfiguration project(":lib")
}
```

```groovy
configurations {
    // compileClasspath 和 runtimeClasspath 有明确的用途
    compileClasspath.extendsFrom(someConfiguration)
    runtimeClasspath.extendsFrom(someConfiguration)
}
```

#### 可消费的配置

下面让我们再站在 lib project 的一方(生产者方)思考些问题。

在 lib project 中，我们也会使用 Configuration 来表示什么可以被消费。例如，library 可能公开 API 或 runtime 配置，并将工件添加到其中。

假设我们编译 lib，但只需要 lib 的 API，但并不需要它的 runtime 依赖项(对外公开 API)。则可以使用 Configuration 的 canBeConsumed 标志。lib project 可以暴露一个 apiElements 配置，以帮助消费者寻找 lib 的 API。此时我们的配置是消费品(consumable)，不需要解析(resolved)。

```groovy
configurations {
    // 创建 exposedApi 配置
    create("exposedApi") {
        // 对外暴露，不需要解析
        isCanBeResolved = false
        // 消费者可以消费配置
        isCanBeConsumed = true
    }
}
```

简而言之，配置的定位由 canBeResolved 和 canBeConsumed 标志组合决定：

||||
|:-:|:-:|:-:|
|**配置定位**|**可解析(被消费者使用)**|**可消费(被生产者使用)**|
|单纯的依赖容器|false|false|
|解析依赖(消费者，app 方)|true|false|
|暴露产物，产物可消费(生产者，lib 方)|false|true|
|~~保留，不要使用~~|~~true~~|~~true~~|

为了向后兼容，这两个标志都有默认值 true，但对于插件开发者而言，应该始终为这些标志确定正确的值，否则可能会引起解析错误。

#### 语法解释

Gradle 官方的示例中，创建 Configuration 的方式很奇怪，不是标准的 Groovy 语法，着实让人有点摸不着头脑。这段代码需要解释一番。

```groovy
// 代码 1
configurations { someConfiguration }
```

首先我们要明白这段代码实际上是在找一个名为 someConfiguration 的配置。因为 Configuration 实现了 Namer，所以在 ConfigurationContainer 中，可以直接通过 name 查找 configuration。

首先，在 ConfigurationContainer 查找 someConfiguration 时，会走到 ConfigureDelegate 的 getProperty 方法。

![Configuration创建语法解释](/imgs/Configuration创建语法解释.webp)


然后，上面的代码，重点在于拿不到进行创建时调用 _configure 方法。该方法被 NamedDomainObjectContainerConfigureDelegate._configure 方法重载。最终会调用到 ConfigurationContainer 的 create 方法。

![Configuration创建语法解释2](/imgs/Configuration创建语法解释2.webp)

所以代码 1 具备创建配置的作用。但是不建议过多的使用这种语法糖，虽然看着简洁，但是会造成阅读和理解困难。在 Gradle 的 kts 代码中，Gradle 就少了很多在 groovy 中类似的语法糖。恰好开发 Android 的主语言也是 kotlin，所以推荐使用 kts。

### 配置仓库

注：本来依赖仓库的知识不应在 configuration 一节讲解，但是因为它与依赖息息相关。所以在此处讲解下。

开发软件时，我们可以利用依赖仓库来下载和使用别人已开发好的开源依赖。流行的仓库包括 Maven Central 和 Google Android 仓库等。 Gradle 为这些仓库提供了内置的速记符号。

![仓库示例图](/imgs/仓库示例图.webp)

RepositoryHandler API 记录了仓库可用的便捷符号。要了解所以预定义的仓库，可以看 RepositoryHandler API 的类文档。

#### 通过 URL 声明自定义仓库

仓库声明的顺序决定了 Gradle 在运行时如何检查依赖。如果 Gradle 在特定仓库中找到了对应模块的描述信息，它将尝试从同一仓库下载该模块的所有工件。Maven POM 文件中可以声明引用其他仓库，但这些仓库将被 Gradle 忽略，Gradle 只会使用在当前项目中声明的存储库。

```groovy
repositories {
    mavenCentral()
    maven {
        url "https://repo.spring.io/release"
    }
    maven {
        url "https://repository.jboss.org/maven2"
    }
}
```

##### 设置工件位置

有时仓库会将 POM 发布到一个位置，而将 JAR 或其他工件发布到另一个位置。此时可以使用 artifactUrls 声明工件位置。

```groovy
repositories {
    maven {
        // 此 url 用于寻找 POMs 和 artifacts
        url "http://repo2.mycompany.com/maven2"
        // 如果 url 中不存在工件，则从 artifactUrls 中下载
        artifactUrls "http://repo.mycompany.com/jars"
        artifactUrls "http://repo.mycompany.com/jars2"
    }
}
```

#### 受支持的仓库类型

##### 远程仓库

远程仓库的声明上面已经讲过了。

```groovy
repositories {
    mavenCentral()
    maven {
        url "https://repo.spring.io/release"
    }
}
```

##### Flat 目录仓库

一些仓库或者项目可能会将依赖作为项目源代码的一部分(如文件依赖)，而不是生成远程二进制依赖。此时我们需要添加一个或多个目录作为依赖仓库。注意这种仓库中的依赖不需要包含 Metadata 文件。

```groovy
repositories {
    flatDir {
        dirs 'lib'
    }
    flatDir {
        dirs 'lib1', 'lib2'
    }
}
```

##### Local 仓库

Gradle 可以使用本地 Maven 仓库中的依赖。Gradle 使用与 Maven 相同的逻辑来定位本地 Maven 缓存的位置。如果在 settings.xml 中定义了本地仓库位置，则 Gradle 将使用该位置。如果没有可用的 settings.xml，Gradle 将使用默认位置 USER_HOME/.m2/repository。

```groovy
repositories {
    mavenLocal()
}
```

使用 Local 仓库有以下注意事项：

- 实际上 Maven 是将 Local 用作缓存，而不是仓库，这意味着它可以包含部分模块。例如如果 Maven 从未下载给定模块的源文件或 javadoc 文件，则 Gradle 也无法找到它们

- Gradle 不会对该仓库做任何缓存。首先添加 mavenLocal() 会导致构建速度变慢

- Local 仓库是本地所有 Gradle 工程公用的，这意味着使用 Local 仓库可以做到本地跨工程分享依赖。

#### 仓库内容过滤

Gradle 提供了一个 API 以声明仓库可能包含或不包含的内容。它有不同的用途：

- 当我们知道永远不会在特定仓库中找到特定依赖时，可以使用该 API 来优化构建性能

- 可以避免私有项目中使用的依赖被泄漏以提高安全性

- 当某些仓库包含损坏的元数据或工件时，可以使用该 API 提高构建的可靠性

默认情况下，仓库包含所有内容并且不排除任何内容：

- 如果声明了一个 include，则仓库会仅包含 include 内容，排除其他所有内容

- 如果您声明了一个 exclude，则仓库包括除排除之外的所有内容

- 如果同时声明了 include 和 exclude，则仓库只包含明确 include 而不被排除的内容

可以通过显式指定 group、module、version、依赖完整路径或正则表达式等形式进行过滤。使用依赖完整路径时，可以指定版本区间([Declaring Versions and Ranges (gradle.org)](https://docs.gradle.org/current/userguide/single_versions.html#single-version-declarations))。此外，还可以按 configuration 名称或者 configuration 属性过滤，详情见 RepositoryContentDescriptor 类声明。

```groovy
repositories {
    maven {
        url "https://repo.mycompany.com/maven2"
        // ArtifactRepository.content() 方法
        content {
            // 该仓库仅包含 my.company 团队的依赖
            includeGroup "my.company"
        }
    }
    mavenCentral {
        content {
            // 该仓库包含除 my.company 仓库外的其他仓库
            excludeGroupByRegex "my\\.company.*"
        }
    }
}
```

### 依赖说明

#### 依赖分类

##### 模块依赖

模块依赖(Module dependencies)是 Gradle 中最常见的依赖。他们关联的是远程仓库中的模块。如果我们声明模块依赖，Gradle 会在远程仓库中查找模块的元数据文件(metadata file：即 .module、.pom 或 ivy.xml)。如果存在这样的模块元数据文件，Gradle 会对模块进行解析并下载模块包含的工件(如 some.jar)及其依赖项。如果不存在这样的模块元数据文件，从 Gradle 6.0 开始，就需要配置元数据(Declaring repositories (gradle.org))。

注意在 Maven 中，一个模块只能有一个工件。在 Gradle 和 Ivy 中，一个模块可以有多个工件。每个工件都可以有一组不同的依赖关系。

Gradle 为模块依赖提供字符串表示和映射表示两种表达方式。模块依赖的关联类是 ExternalModuleDependency，其具有更多可配置的 API，可阅读类文档了解完整信息。

```groovy
dependencies {
    runtimeOnly group: 'org.springframework', name: 'spring-core', version: '2.5'
    runtimeOnly 'org.springframework:spring-core:2.5',
            'org.springframework:spring-aop:2.5'
    runtimeOnly(
        [group: 'org.springframework', name: 'spring-core', version: '2.5'],
        [group: 'org.springframework', name: 'spring-aop', version: '2.5']
    )
    runtimeOnly('org.hibernate:hibernate:3.0.5') {
        transitive = true
    }
    runtimeOnly group: 'org.hibernate', name: 'hibernate', version: '3.0.5', transitive: true
    runtimeOnly(group: 'org.hibernate', name: 'hibernate', version: '3.0.5') {
        transitive = true
    }
}
```

##### 文件依赖

project 有时会不依赖远程二进制仓库依赖，而是依赖与项目源代码一起放入版本控制的文件，这些依赖项被称为文件依赖(file dependencies)，常见的如项目中的 aar、jar。它们是没有附加任何元数据(metadata)的文件(元数据是被用于记录如传递依赖、代码来源或其作者的信息的文件)。

文件依赖不对外暴露，仅在同一构建中的传递项目依赖。这意味着文件依赖不能在当前构建之外使用，仅可以在同一个构建中使用。

创建文件依赖最常见的方法有：Project.files(Object… )、ProjectLayout.files(Object… ) 和 Project.fileTree(Object)。

```groovy
dependencies {
    // libs 与 src 目录同级 TestProject/app/libs
    implementation fileTree(include: ['*.jar'], dir: 'libs')
    // 不声明仓库，直接添加文件依赖
    implementation files('libs/a.jar', 'libs/b.jar')
}

```

我们也可以指定任务作为文件依赖的来源。

```groovy
dependencies {
    // 依赖由 compile 任务生成
    implementation files(layout.buildDirectory.dir('classes')) {
        builtBy 'compile'
    }
}

tasks.register('compile') {
    doLast {
        println 'compiling classes'
    }
}

tasks.register('list') {
    // 配置解析完了，再执行任务
    dependsOn configurations.compileClasspath
    doLast {
        println "classpath = ${configurations.compileClasspath.collect { File file -> file.name }}"
    }
}

// 输出结果：
// $ gradle -q list
// compiling classes
// classpath = [classes]
```

###### 版本控制

Gradle 的版本冲突解决方案不会考虑文件依赖，所以我们在使用文件依赖时应自己明确用途和版本。此时文件名带版本号(如 common-utils-1.3.jar)是十分重要的。为文件依赖添加版本号使得项目的依赖更易于维护和组织，通过版本号我们更容易发现潜在的 API 不兼容问题，例如我们可以通过 release notes 跟踪库的更改。

##### 项目依赖

在大型项目中，我们通常将工程分解成不同的模块(组件化)，以提高可维护性并防止强耦合。Gradle 允许模块间定义彼此的依赖关系，以在同一工程中复用代码。Gradle 会对模块之间的依赖关系进行建模，确保各个模块按照正确的顺序进行编译。这些依赖项称为项目依赖(project dependencies)，由 ProjectDependency 类代表。这个名称代表着每个依赖模块都由一个 Gradle project 表示。

![Gradle多项目构建](/imgs/Gradle多项目构建.webp)

项目依赖的使用方式如下：

```groovy
dependencies {
    implementation project(':base-media')
}
```

###### 类型安全的项目依赖

使用项目依赖 project(":some:path") 语法有个明显的问题，那就是我们必须要记住每个被依赖项目的路径，更改被依赖项目路径的同时需要更改所有依赖该项目的地方，这样很容易出现更改遗漏的问题。为了解决这个问题，Gradle 从 Gradle 7 开始为项目依赖提供了一个实验性的类型安全 API(type-safe API)。

类型安全的 project 访问器是一项必须手动启用的实验性孵化功能，其实现可能随时会改变。在 settings.gradle 文件中添加以下配置，并在 build.gradle 中使用。

类型安全的 API 具有 IDE 补全代码的优势，所以我们可以无需弄清楚 project 的实际 name。

项目访问器(the project accessors)是从项目路径(project path)映射而来的(即键值对 map)。举个例子，如果项目路径是 :common:base:lib，那么项目访问器就是 projects.common.base.lib。这是 projects.getCommon().getBase().getLib() 的简写形式。

形如 base-lib 或 base_lib 的项目名称将在访问器中转换为驼峰大小写：projects.baseLib。

```groovy
// settings.gradle
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")
```

```groovy
// build.gradle
dependencies {
    implementation projects.utils
    implementation projects.api
}
```

##### Gradle 内嵌依赖

形如仓库的速记符号，Gradle 提供了部分依赖的速记符号。此处仅列举部分，完整的列表可以查看 DependencyHandler 类的类文档。

###### Gradle API 依赖

我们可以使用 DependencyHandler.gradleApi() 方法声明对当前使用版本 Gradle 的 API 的依赖。这在我们自定义 Gradle task 或自定义 gradle plugin 时很有用。

```groovy
dependencies {
    implementation gradleApi()
}
```

###### Gradle TestKit 依赖

我们可以使用 DependencyHandler.gradleTestKit() 方法声明对当前使用版本 Gradle 的 TestKit API 的依赖。这在我们为自定义的 Gradle 插件和 build script 实现测试代码时很有用。

```groovy
dependencies {
    testImplementation gradleTestKit()
}
```

###### Local Groovy 依赖

我们可以使用 DependencyHandler.localGroovy() 方法声明对当前使用 Gradle 依赖的 Groovy 的依赖项。这在我们使用 Groovy 开发自定义 Gradle task 或自定义 gradle plugin 时很有用。

```groovy
dependencies {
    implementation localGroovy()
}
```

#### 标记依赖关系

当我们声明依赖或依赖约束(dependency constraint)时，可以同时带上一个原因说明。这有助于我们弄懂构建脚本(build script)中的依赖声明逻辑，同时保证有关依赖打印任务更易于理解。

```groovy
dependencies {
    implementation('org.ow2.asm:asm:7.1') {
        because 'we require a JDK 9 compatible bytecode generator'
    }
}
```

如果我们使用 gradle -q dependencyInsight --dependency asm 语句打印 asm 依赖的相关信息，会看到我们声明的语句。

- 表明使用的是 org.ow2.asm:asm:7.1 依赖

- 表明依赖对应的变体

- Selection reasons 打印的是我们传入的原因

- 表明依赖对应的 configuration

```groovy
> gradle -q dependencyInsight --dependency asm
org.ow2.asm:asm:7.1
  Variant compile:
    | Attribute Name                 | Provided | Requested    |
    |--------------------------------|----------|--------------|
    | org.gradle.status              | release  |              |
    | org.gradle.category            | library  | library      |
    | org.gradle.libraryelements     | jar      | classes      |
    | org.gradle.usage               | java-api | java-api     |
    | org.gradle.dependency.bundling |          | external     |
    | org.gradle.jvm.environment     |          | standard-jvm |
    | org.gradle.jvm.version         |          | 11           |
   Selection reasons:
      - Was requested: we require a JDK 9 compatible bytecode generator

org.ow2.asm:asm:7.1
\--- compileClasspath

A web-based, searchable dependency report is available by adding the --scan option.
```

#### 支持的 Metadata 格式

外部的远程 module 依赖需要 module 元数据(Gradle 可以用来找出模块的传递依赖关系)。Gradle 支持不同的元数据格式。

- Gradle Module Metadata 文件：Gradle 模块元数据专门设计用于支持 Gradle 依赖管理模型的所有功能。详细讲解见这里 [Declaring repositories (gradle.org)](https://docs.gradle.org/current/userguide/declaring_repositories.html#sec:supported_metadata_sources)

- Maven POM 文件：Gradle 默认支持 Maven POM 文件([Maven – POM Reference (apache.org)](https://maven.apache.org/pom.html))。默认情况下 Gradle 会首先查找 POM 文件，但如果此文件包含特殊标记，Gradle 将转而使用 Gradle Module Metadata

- Ivy files：Gradle 支持 Apache Ivy 元数据文件。同样，Gradle 将首先查找 ivy.xml 文件，但如果此文件包含特殊标记，Gradle 将改用 Gradle Module Metadata

#### 依赖传递

##### 直接依赖与依赖约束

一个组件(component)可能有两种不同类型的依赖：

- 直接依赖(direct dependencies)是组件直接需要并声明的。直接依赖也称为一级依赖(first level dependency)。比如项目源码需要Guava，我们就应该声明Guava为直接依赖

- 传递依赖(transitive dependencies)是组件不直接需要的依赖，是被组件依赖的另一个依赖需要的依赖。

与传递依赖有关的问题是很常见的。我们经常通过添加直接依赖的方式来错误地修复传递依赖的问题。为了避免这种情况，Gradle 提供了依赖约束(dependency constraints)的概念。

##### 添加对传递依赖的约束

依赖约束(Dependency constraints)允许我们定义构建脚本(build script)中声明的依赖和传递依赖的版本或版本区间。依赖约束是添加约束到配置的所有依赖(all dependencies of a configuration)上的首选方式。

依赖约束本身也可以传递添加，注意依赖约束仅在使用 Gradle 模块元数据(Gradle Module Metadata)时才会发布出去，即当使用 Maven 或 Ivy 进行依赖管理时它们会"丢失"。

当 Gradle 尝试解析模块依赖的版本时，所有带版本的依赖声明、所有的传递依赖和该模块的所有依赖约束都会被考虑在内。Gradle 会选择符合所有条件的最高版本。如果找不到这样的版本，Gradle 将失败并显示依赖声明冲突(conflicting declarations)的错误。

如果发生这种情况，我们可以调整依赖或依赖约束的声明，或者根据需要对传递依赖进行其他调整。与声明依赖类似，依赖约束由配置(configuration)限定范围，可以为构建的部分逻辑选择性地定义依赖约束。

如果依赖约束影响了解析结果，那么之后仍然可以应用任何类型的依赖解析规则(dependency resolve rules)。

下面的例子在声明依赖时省略了版本，转而在约束块中定义版本。因为 commons-codec 依赖并未直接声明，所以 commons-codec:1.11 的版本约束仅在将 commons-codec 作为传递依赖引入时才会考虑，如果没有作为传递依赖引入，则改约束无效。

依赖约束支持丰富的版本定义形式，并支持严格(strictly version)版本以强制执行一个版本(即使它与传递依赖定义的版本相矛盾)。

```groovy
dependencies {
    implementation 'org.apache.httpcomponents:httpclient'
    constraints {
        implementation('org.apache.httpcomponents:httpclient:4.5.3') {
            because 'previous versions have a bug impacting this application'
        }
        implementation('commons-codec:commons-codec:1.11') {
            because 'version 1.9 pulled from httpclient has bugs affecting this application'
        }
    }
}
```

##### 排除传递依赖

可以在声明依赖一级排除传递依赖。排除语法是使用 group 属性和 module 属性的键值对，如下例所示。有关详细信息，请参阅 ModuleDependency.exclude(java.util.Map)。

```groovy
dependencies {
    implementation('commons-beanutils:commons-beanutils:1.9.4') {
        exclude group: 'commons-collections', module: 'commons-collections'
    }
}
```

注意与 Maven 相比，Gradle 排除依赖时会考虑整个依赖图。如果一个库有多个依赖，则只有在所有依赖都同意排除时才会排除依赖。例如，如果我们再添加了 opencsv 依赖(依赖于 commons-beanutils)，那么 commons-collection 将不会被排除，因为 opencsv 本身并不排除它。

```groovy
dependencies {
    // 此时 commons-collections 依赖不会被排查
    implementation('commons-beanutils:commons-beanutils:1.9.4') {
        exclude group: 'commons-collections', module: 'commons-collections'
    }
    implementation 'com.opencsv:opencsv:4.6' // 依赖于 'commons-beanutils' 
}

dependencies {
    // 两个都排除，才能真正排除依赖
    implementation('commons-beanutils:commons-beanutils:1.9.4') {
        exclude group: 'commons-collections', module: 'commons-collections'
    }
    implementation('com.opencsv:opencsv:4.6') {
        exclude group: 'commons-collections', module: 'commons-collections'
    }
}
```

下面的代码是使用 Configuration.exclude(java.util.Map) 方法在 configuration 级别排除传递依赖。

```kotlin
// kts 的语法
configurations {
    "implementation" {
        exclude(group = "commons-collections", module = "commons-collections")
    }
}

dependencies {
    implementation("commons-beanutils:commons-beanutils:1.9.4")
    implementation("com.opencsv:opencsv:4.6")
}
```

#### version catalog API

Gradle 从 7.0 开始提供了 version catalog API，用于统一管理项目里的依赖。

version catalog (版本目录)就是一个依赖列表，记录着依赖的信息。用户在构建脚本(build script)中声明的依赖可以从 version catalog 中选择。

应注意 version catalog 中的版本可能不是 Gradle 最终选择的版本，还需要经过版本冲突处理等操作才能决定最终的版本。

```groovy
dependencies {
    // libs 是一个目录，groovy 表示此目录中可用的依赖项
    implementation(libs.groovy.core)
}
```

与直接在构建脚本中声明依赖相比，version catalog 有许多优势：

- 对于每个 catalog，Gradle 都会生成类型安全的访问器，以便我们可以在 IDE 中轻松添加具有代码补全功能的依赖

- 每个目录对参与构建的所有项目都是可见的。它是声明依赖的中心位置，确保每个对依赖版本的更改都会适用于每个子项目

- catalogs 可以以依赖包的形式同时声明一个包中的多个依赖

version catalogs 可以在 settings.gradle(.kts) 文件中声明。为了保证 libs 的 groovy 可用，我们需要将别名与 GAV (group, artifact, version) 坐标相关联，别名必须由ascii 字符、数字、破折号（-，推荐）、下划线 (_) 或点 (.) 标识符分隔组成，使用了 -、_ 和 . 分隔符后，生成的目录将全部规范化为点号。例如，别名 foo-bar 会自动转换为 foo.bar：

```kotlin
// settings.gradle 文件中
dependencyResolutionManagement {
    versionCatalogs {
        libs {
            library('groovy-core', 'org.codehaus.groovy:groovy:3.0.5')
            library('groovy-json', 'org.codehaus.groovy:groovy-json:3.0.5')
            library('groovy-nio', 'org.codehaus.groovy:groovy-nio:3.0.5')
            library('commons-lang3', 'org.apache.commons', 'commons-lang3').version {
                strictly '[3.8, 4.0['
                prefer '3.9'
            }
        }
    }
}
```

注意有些保留关键字不能用于别名，如 extensions、class、convention；有些关键字不能作为别名的首个单词，如 bundles、versions、plugins。例如别名 versions-dependency 是无效的，但 versionsDependency 或 dependency-versions 有效。因为 -(破折号) 会被识别为点号，而大驼峰命名法不会。

##### 版本号

我们可以使用 version 方法声明公共的版本号，例如 gradle kts 的代码所示：

```kotlin
// settings.gradle.kts 文件中
dependencyResolutionManagement {
    versionCatalogs {
        create("libs") {
            version("groovy", "3.0.5")
            version("checkstyle", "8.37")
            library("groovy-core", "org.codehaus.groovy", "groovy").versionRef("groovy")
            library("groovy-json", "org.codehaus.groovy", "groovy-json").versionRef("groovy")
            library("groovy-nio", "org.codehaus.groovy", "groovy-nio").versionRef("groovy")
            library("commons-lang3", "org.apache.commons", "commons-lang3").version {
                strictly("[3.8, 4.0[")
                prefer("3.9")
            }
        }
    }
}
```

版本号也像依赖一样可以从 version catalogs 中获取：

```kotlin
checkstyle {
    toolVersion = libs.versions.checkstyle.get()
}
```

##### 依赖包

因为在不同的项目中经常系统地一起使用一系列依赖，所以版本目录提供了依赖包(dependency bundle)的概念。一个 bundle 基本上是几个依赖的别名。

```kotlin
// settings.gradle.kts 文件中声明
dependencyResolutionManagement {
    versionCatalogs {
        create("libs") {
            version("groovy", "3.0.5")
            version("checkstyle", "8.37")
            library("groovy-core", "org.codehaus.groovy", "groovy").versionRef("groovy")
            library("groovy-json", "org.codehaus.groovy", "groovy-json").versionRef("groovy")
            library("groovy-nio", "org.codehaus.groovy", "groovy-nio").versionRef("groovy")
            library("commons-lang3", "org.apache.commons", "commons-lang3").version {
                strictly("[3.8, 4.0[")
                prefer("3.9")
            }
            bundle("groovy", listOf("groovy-core", "groovy-json", "groovy-nio"))
        }
    }
}
```

```kotlin
// build.gradle.kts 文件中使用
dependencies {
    implementation(libs.bundles.groovy)
}
```

##### 插件版本

除了依赖，版本目录还支持声明插件(Plugin)版本。因为依赖由 group、artifact、version 三者组成仓库坐标表示，而插件仅由插件 ID 和插件版本标识，所以二者的表示不能共用一套，需要单独声明：

```kotlin
// settings.gradle.kts 文件中声明
dependencyResolutionManagement {
    versionCatalogs {
        create("libs") {
            plugin("jmh", "me.champeau.jmh").version("0.6.5")
        }
    }
}
```

```kotlin
// build.gradle.kts 文件中使用
plugins {
    'java-library'
    alias(libs.plugins.jmh)
}
```

##### libs.versions.toml 文件

除了在 setting 文件中声明 catalog，Gradle 还可以从 libs.versions.toml 文件获取 catalog 信息。详情见 [Sharing dependency versions between projects](https://docs.gradle.org/current/userguide/platforms.html#sub:conventional-dependencies-toml)。

#### 依赖验证

依赖验证由两个不同且互补的操作组成：

- 完整性验证(checksum verification)，允许断言依赖的完整性。通过校验和验证依赖的完整性。

- 签名验证(signature verification)，允许断言依赖的来源。APK 可以有签名，依赖就也可以有签名

更具体的讲解，详见[Verifying dependencies (gradle.org)](https://docs.gradle.org/current/userguide/dependency_verification.html)

### 依赖的版本

#### 版本声明形式

Gradle 中一个依赖的版本就是一个字符串，Gradle 支持不同的版本声明方式(Gradle 术语：rich version)。

- 一个明确的版本：例如1.3、1.3.0-beta2、1.0-20150201.131010-1 等

- Maven 风格的版本区间：例如[1.0,]，[1.1, 2.0]，(1.2, 1.5]

   - [ 和 ] 符号表示闭区间； ( 和 ) 表示开区间

   - 当版本区间缺少上限或下限时，则版本区间没有上限或下限

   - 用于表示开区间下限时，符号 ] 等价于 (，用于表示开区间上限时，符号 [ 等价于 )。例如 ]1.0, 2.0[ 等价于 (1.0, 2.0)

   - 开区间上限通过判断前缀生效。即 [1.0, 2.0[ 还将排除所有以 2.0 开头的版本。例如 2.0-dev1 或 2.0-SNAPSHOT 等版本。

- 前缀版本区间：例如1.+，1.3.+。仅包括与 + 之前的字符串完全匹配的版本。

- 一个 latest-status 版本，比如 latest.integration, latest.release。在多个相同状态的依赖中，将选择版本最高的依赖


#### 版本排序

既然版本的声明有丰富的形式，那么在进行版本比较时就必须具有一个规则。Gradle 依赖的版本具有隐式顺序。顺序的主要作用有：

- 确定特定版本是否包含在某个区间内。

- 在执行冲突解决时确定哪个版本是"最新的"。

依赖的版本根据以下规则排序：

1. 每个版本都有它的组成"部分"：

   - 标点符号 [、.、-、_、+、] 用于分隔版本的不同“部分”。

   - 任何包含数字和字母的部分都被分成单独的部分：1a1 == 1.a.1

   - 当比较版本时，实际的分隔符并不重要，因为 1.a.1 == 1-a+1 == 1.a-1 == 1a1(不过在解决冲突的上下文中有例外)。

2. 两个版本的等效部分会使用以下规则比较：

   - 如果都是数字，则采用数字的比较：1.1 < 1.2

   - 如果不都是数字，则认为数字大于非数字：1.a < 1.1

   - 如果都不是数字，则按字母顺序比较部分，区分大小写：1.A < 1.B < 1.a < 1.b

   - 具有额外数 字(即使额外数字为 0)的版本号仍大于没有的版本：1.1 < 1.1.0

   - 具有额外非数字部分的版本号小于没有的版本：1.1.a < 1.1

3. 某些非数字部分在排序时具有特殊含义：

   - dev 被认为小于任何其他非数字部分：1.0-dev < 1.0-ALPHA < 1.0-alpha < 1.0-rc

   - 字符串 rc、snapshot、final、ga、release 和 sp 被认为大于任何其他字符串部分：1.0-zeta < 1.0-rc < 1.0-snapshot < 1.0-final < 1.0-ga < 1.0-release < 1.0-sp < 1.0

   - 上述特殊字符串不区分大小写，并且不依赖于它们周围使用的分隔符：1.0-RC-1 == 1.0.rc.1

版本声明的部分示例如下，因为 strict 版本无法升级，并且会覆盖该依赖项提供的任何传递依赖项。所以建议对 strict 版本使用区间：

```kotlin
dependencies {
    // 使用了 !!
    implementation('org.slf4j:slf4j-api:1.7.15!!')
    // 等价于
    implementation("org.slf4j:slf4j-api") {
        version {
           strictly '1.7.15'
        }
    }

    implementation('org.slf4j:slf4j-api:[1.7, 1.8[!!1.7.25')
    // 等价于
    implementation('org.slf4j:slf4j-api') {
        version {
           strictly '[1.7, 1.8['
           prefer '1.7.25'
        }
    }
}
```

对于较大的项目，可以声明没有版本的依赖，并使用依赖约束进行版本声明。这么做的优势是依赖约束允许我们在一个地方管理所有依赖(包括传递依赖)的版本。

```kotlin
dependencies {
    implementation 'org.springframework:spring-web'
}

dependencies {
    constraints {
        implementation 'org.springframework:spring-web:5.0.2.RELEASE'
    }
}
```

#### 版本约束

Gradle 允许组合不同级别的版本信息，此时可以使用版本约束限制依赖的版本。版本约束按照约束力从最强到最弱的解释如下：

- strictly：与此版本符号不匹配的任何版本都将被排除在外。这是最强的版本声明。在声明依赖时，strictly 可以降级版本。在传递依赖时，如果无法选择本约束可接受的版本，则将导致依赖解析失败。

   - 定义 strictly 后，将覆盖任何先前的 require 声明并清除先前的 reject 声明。

   - 对于library，strictly 不能轻易使用，应该在深思熟虑后再使用。因为这会对下游依赖产生影响。

- require：意味着所选版本不能低于 require 接受的版本，但可以通过冲突解决(conflict resolution)选择更高的版本。这就是直接依赖的含义。require 支持动态版本。定义 require 后，将覆盖任何先前的 strictly 声明并清除先前的 reject 声明。

- prefer：这是一个非常软的版本声明。仅当依赖的版本没有更强的非动态选项时才生效。这意味着 prefer 不支持动态版本。定义可以补充 strictly 或 require 声明。定义 prefer 后，将覆盖任何先前的 prefer 声明并清除先前的 reject 声明。

- reject：声明依赖不接受特定版本。如果唯一可选择的版本被拒绝，则依赖解析将失败。reject 支持动态版本。

下表举了些例子来讲解。

||||||
|:-:|:-:|:-:|:-:|:-:|
|**strictly**|**require**|**prefer**|**rejects**|**结果**|
||1.5|||相当于 org:foo:1.5。接受从 1.5 开始的任何版本，例如接受升级到 2.4|
||[1.0, 2.0[|1.5||1.0 和 2.0 之间的任何版本，如果没有其他特定依赖声明，则优先选择 1.5。接受升级到 2.4|
|[1.0, 2.0[||1.5||1.0 和 2.0 之间的任何版本，如果没有其他特定依赖声明，则优先选择 1.5。会覆盖传递依赖的版本|
|[1.0, 2.0[||1.5|1.4|1.0 和 2.0 之间除了 1.4 的任何版本，如果没有其他特定依赖声明，则优先选择 1.5。会覆盖传递依赖的版本|

#### 强制依赖 vs 严格版本

版本设置中，有强制依赖 vs 严格版本(Forced dependencies vs strict dependencies)的问题。ExternalDependency.setForce(boolean) 方法已被弃用(设置强制依赖)。官方解释三点原因：

- 使用强制依赖会遇到一个难以排查的排序问题

- 强制依赖不能与其他丰富的版本约束声明方式很好地一起工作

- 如果我们正在编写和发布一个库(library)，那么我们还需要知道设置了 force 的依赖不会被发布。

官方推荐我们应该优先使用严格版本。但是如果出于某种原因，我们不能使用严格版本，则使用强制依赖可以这样做：

```kotlin
dependencies {
    implementation('commons-codec:commons-codec:1.9') {
        force = true
    }
}
```

如果项目在 configuration 的层级需要特定版本的依赖，则可以通过调用 ResolutionStrategy.force(java.lang.Object[]) 方法来实现。

```kotlin
configurations {
    compileClasspath {
        resolutionStrategy.force 'commons-codec:commons-codec:1.9'
    }
}
```

### 依赖解析

依赖解析是由两个阶段组成，这些阶段会重复，直到依赖图完成：

- 当一个新的依赖被添加到依赖图中时，Gradle 会执行冲突解决(conflict resolution)以确定应该将哪个版本添加到依赖图中

- 当具体版本的特定依赖被识别为依赖图的一部分时，Gradle 会解析其元数据，以便递归添加其依赖项

Configuration 允许我们通过解析策略(ResolutionStrategy)在解析时为依赖及其版本自定义解析逻辑。

#### 使用组件选择规则

当有多个版本与版本选择器匹配时，组件选择规则(component selection rules)可以影响组件实例的选择。规则适用于每个可用版本，并允许该版本可以被规则明确拒绝(reject)。这样做可以保证 Gradle 忽略任何不满足规则的组件实例。

规则是通过 ComponentSelectionRules 实例配置的。ComponentSelection 作为配置规则的参数，包含有关候选版本的信息。调用 ComponentSelection.reject 方法会导致给定的候选版本被显式拒绝，在这种情况下，选择器不会考虑该候选版本。

```groovy
configurations {
    // 声明 rejectConfig 配置
    rejectConfig {
        resolutionStrategy {
            componentSelection {
                // 选择非 1.5 的最高版本
                all { ComponentSelection selection ->
                    if (selection.candidate.group == 'org.sample' && selection.candidate.module == 'api' && selection.candidate.version == '1.5') {
                        selection.reject("version 1.5 is broken for 'org.sample:api'")
                    }
                }
            }
        }
    }
}

dependencies {
    // 明确拒绝动态版本中的 1.5 版本，但可以选择其他的版本
    rejectConfig "org.sample:api:1.+"
}
```

规则也可以针对特定模块。模块必须以 group:module 的形式指定：

```groovy
configurations {
    targetConfig {
        resolutionStrategy {
            componentSelection {
                withModule("org.sample:api") { ComponentSelection selection ->
                    if (selection.candidate.version == "1.5") {
                        selection.reject("version 1.5 is broken for 'org.sample:api'")
                    }
                }
            }
        }
    }
}
```

规则同样可以针对特定元数据，元数据可能是 ComponentMetadata 和 IvyModuleDescriptor。

注意元数据可能为空，注意判空。

```kotlin
configurations {
    metadataRulesConfig {
        resolutionStrategy {
            componentSelection {
                // 拒绝 experimental 依赖
                all { ComponentSelection selection ->
                    if (selection.candidate.group == 'org.sample' && selection.metadata?.status == 'experimental') {
                        selection.reject("don't use experimental candidates from 'org.sample'")
                    }
                }
                // 判断分支状态及其他条件
                withModule('org.sample:api') { ComponentSelection selection ->
                    if (selection.getDescriptor(IvyModuleDescriptor)?.branch != "release" && selection.metadata?.status != 'milestone') {
                        selection.reject("'org.sample:api' must be a release branch or have milestone status")
                    }
                }
            }
        }
    }
}
```

#### 锁定依赖版本

声明动态版本(例如 1.+ 或 [1.0,2.0) 等前缀/区间/latest 版本)会使构建变得不确定，这会导致构建可能在没有任何明显更改的情况下中断；更糟糕的是，这可能是由开发者无法控制的传递依赖引起的。

当为了实现可重现的构建，我们有必要锁定依赖和传递依赖的版本。这样具有相同输入的构建将始终解析得到相同的依赖版本，这被称为依赖锁定。

因为是针对解析依赖的操作，所以只有可以解析的配置才会附加锁定状态。对不可解析的配置应用锁定只是一个空操作。

可以使用 ResolutionStrategy.activateDependencyLocking() 启用依赖锁定。一旦在配置上打开，解析结果可以被保存，然后重新用于后续构建。

```kotlin
configurations {
    // 锁定 compileClasspath 的依赖(单个配置)
    compileClasspath {
        resolutionStrategy.activateDependencyLocking()
    }
}
```

```kotlin
// 锁定所有的 Configuration(除了 buildscript)的依赖
dependencyLocking {
    lockAllConfigurations()
}
```

```kotlin
// 锁定 buildscript 的依赖
buildscript {
    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}
```

我们可以在 dependencyLocking 配置中忽略依赖项。注意值 *:* 不被接受，因为它等同于禁用锁定：

```kotlin
dependencyLocking {
    ignoredDependencies.add('com.example:*')
}
```

#### 处理变化版本

我们可以通过使用动态版本轻松依赖不断变化的依赖项。但是在 Gradle 中，即使是同一模块(依赖)的同一版本，请求的模块也可以随时间变化，也就是所谓的变化版本(changing version)。如 Maven 的 SNAPSHOT 模块就是一个始终指向最新发布工件的依赖。换句话说，一个标准的 Maven 快照是一个不断进化的依赖，它是一个 "变化的模块"(changing module)。

默认情况下，Gradle 会缓存动态版本 24 小时。这句话的意思是从网上下载后，24 小时内不再重复下载，除非手动触发。要更改 Gradle 的缓存时间，可以使用 ResolutionStrategy.cacheDynamicVersionsFor() 方法：

```kotlin
configurations.all {
    // 缓存 10 分钟
    resolutionStrategy.cacheDynamicVersionsFor 10, 'minutes'
}
```

默认情况下，Gradle 缓存变化的模块 24 小时。要更改 Gradle 的缓存时间，请使用 cacheChangingModulesFor() 方法：

```kotlin
configurations.all {
    // 缓存 4 小时
    resolutionStrategy.cacheChangingModulesFor 4, 'hours'
}
```

当然我们使用动态版本和动态模块时会导致无法重现的构建。随着特定依赖新版本的发布，其 API 可能与我们的源代码不兼容。我们应谨慎使用此功能。

#### 解析前替换依赖

有时我们可能希望在解析之前修改配置的依赖项。withDependencies 方法允许我们用编程方式添加、删除或修改依赖项

```kotlin
configurations {
    create("implementation") {
        withDependencies {
            val dep = this.find { it.name == "to-modify" } as ExternalModuleDependency
            dep.version {
                strictly("1.2")
            }
        }
    }
}
```

#### 解析时替换依赖

可以在解析时使用 useVersion 方法替换依赖版本，注意 useVersion 方法不是强制解析版本，比如其他模块的该依赖使用了 newest 声明时，则更高的最新版本(如 1.3)仍会被选择使用。

```kotlin
configurations.all {
    resolutionStrategy.eachDependency {
        // eachDependency 的 item 可以理解成是类 DependencyResolveDetails 的 apply
        if (requested.group == "org.software" && requested.name == "some-library" && requested.version == "1.2") {
            useVersion("1.2.1")
            because("fixes critical bug in 1.2")
        }
    }
}
```

可以使用 replacedBy 方法将旧依赖替换成新依赖。例如在旧依赖被改成新名称等场景时很有用。

```kotlin
dependencies {
    modules {
        module("com.google.collections:google-collections") {
            replacedBy("com.google.guava:guava", "google-collections is now part of Guava")
        }
    }
}
```

#### 依赖替换规则

依赖替换规则和依赖解析规则类似。可以用于替换依赖。比如替换外部依赖为本地项目。更详细的 api 说明见 DependencySubstitutions 类文档：

```kotlin
// 1 使用本地项目替换远程依赖
configurations.all {
    resolutionStrategy.dependencySubstitution {
        substitute(module("org.utils:api"))
            .using(project(":api")).because("we work with the unreleased development version")
        substitute(module("org.utils:util:2.5")).using(project(":util"))
    }
}
// 2 使用远程依赖替换本地项目
configurations.all {
    resolutionStrategy.dependencySubstitution {
        substitute(project(":api"))
            .using(module("org.utils:api:1.3")).because("we use a stable version of org.utils:api")
    }
}
// 3 有条件的替换依赖
configurations.all {
    resolutionStrategy.dependencySubstitution.all {
        requested.let {
            if (it is ModuleComponentSelector && it.group == "org.example") {
                val targetProject = findProject(":${it.module}")
                if (targetProject != null) {
                    useTarget(targetProject)
                }
            }
        }
    }
}
```

##### 替换具有 classifier 的依赖

假设 app 工程有以下配置：

```kotlin
dependencies {
    implementation("com.google.guava:guava:28.2-jre")
    implementation("co.paralleluniverse:quasar-core:0.8.0")
    implementation(project(":lib"))
}
```

lib 工程的配置如下，依赖末尾指定了 classifier。classifier 的作用见 [Maven的classifier作用](https://www.cnblogs.com/lnlvinso/p/10111328.html)：

```kotlin
dependencies {
    implementation("co.paralleluniverse:quasar-core:0.7.12_r3:jdk8")
}
```

此时执行解析会报错，因为虽然 Gradle 会默认采用较高版本(0.8.0)，但是因为此版本没有 classifier，版本对不上(解析采用的 0.8.0 带了 classifier)，所以会报找不到依赖的错误。

可以尝试使用以下配置解决该问题：

```kotlin
configurations.all {
    resolutionStrategy.dependencySubstitution {
        // 解析后的依赖无 classifier
        substitute(module("co.paralleluniverse:quasar-core"))
            .using(module("co.paralleluniverse:quasar-core:0.8.0"))
            .withoutClassifier()
    }
}
```

#### 禁用传递依赖的解析

可以将 ModuleDependency.setTransitive(boolean) 设置为false(比如传递依赖的 metadata 有损坏时)，以告知 Gradle 禁止解析依赖的传递依赖，只解析该依赖的工件即可。

```kotlin
// 单个依赖禁止解析传递依赖
dependencies {
    implementation("com.google.guava:guava:23.0") {
        isTransitive = false
    }
}
// 整个 configuration 禁止解析传递依赖
configurations.all {
    isTransitive = false
}
```

#### 依赖冲突处理策略

在进行依赖解析时，Gradle 会处理两种类型的冲突：

- 版本冲突(Version conflicts)：当两个以上的依赖需要另一个特定版本的依赖，但该依赖具有不同的版本时，会产生此冲突

- 实现冲突(Implementation conflicts)：当依赖图中包含多个提供相同实现或功能的模块时，会产生此冲突，实现通过 variants 和 capabilities 识别(不经常碰到，此处忽略)

当声明的相同依赖具有不同版本时，默认情况下，Gradle 会选择最高的版本。但是这样的处理可能会导致一些问题，所以我们可以更改 Gradle 默认的依赖冲突处理策略。

- ResolutionStrategy.failOnVersionConflict：依赖冲突时解析失败

- ResolutionStrategy.failOnDynamicVersions：解析到动态版本(包含区间版本、版本前缀等)依赖时失败

- ResolutionStrategy.failOnChangingVersions：解析到变化版本时失败

- ResolutionStrategy.failOnNonReproducibleResolution：解析到不可重复构建时失败。等价于同时调用 failOnDynamicVersions 和 failOnChangingVersions

```kotlin
// 依赖冲突时解析失败
configurations.all {
    resolutionStrategy {
        failOnVersionConflict()
    }
}
// 解析到动态版本依赖时失败
configurations.all {
    resolutionStrategy {
        failOnDynamicVersions()
    }
}
// 解析到变化版本时失败
configurations.all {
    resolutionStrategy {
        failOnChangingVersions()
    }
}
// 版本不可重复构建时失败
configurations.all {
    resolutionStrategy {
        failOnNonReproducibleResolution()
    }
}
```

#### 依赖解析的一致性

一个 Gradle 正在开发的孵化特性，详见 [Preventing accidental dependency upgrades](https://docs.gradle.org/current/userguide/resolution_strategy_tuning.html#resolution_consistency)

## Plugin 类功能

Gradle 中，自定义插件是一个很核心的功能。插件的入口类就是 Plugin，但是 Plugin 只有一个 apply 方法，该方法带有一个泛型参数。不过通常这个泛型参数都是 Project 类。

![Plugin类定义](/imgs/Plugin类定义.webp)

在自定义插件时，我们通常都是针对项目做配置(Configuration)、实现自定义任务(Task)等。鉴于这部分内容上面都讲过，此处就不再重复赘述了。只讲一些涉及到插件的小知识点。

- Android Gradle Plugin(Gradle) 是 Android 官方提供的 Gradle 编译插件，用于 Android apk/library 等的编译。Android gradle plugin 的版本和 gradle 的版本并不完全一致。具体版本要求可以查看官方说明：Android Gradle 插件版本说明。

- Gradle 是一个编译工具，与 IDE 和具体的语言解耦。Gradle DSL 和 Android DSL 可以看作两门新的语言来学习。

   - Gradle DSL 文档链接：Gradle DSL Version 7.6

   - Android Gradle Plugin DSL 旧版链接，旧版说明更详细(截止到 AGP 3.4)：旧版 APG DSL API Guide

   - Android Gradle Plugin DSL 新版链接(APG 版本 >= 4.1)：新版 APG DSL API Guide

- 领域特定语言(英语：domain-specific language、DSL)指的是专注于某个应用程序领域的计算机语言。又译作领域专用语言。简单点讲，DSL 就是定义的新的语言的语法。

   - Gradle 中，自定义插件时，要自定义 DSL，需要搭配 Extension 使用。Extension 可以看作是 Plugin 的 bean 或者 POJO。Extension 中做定义，Plugin 中做实现。具体讲解见：Developing Custom Gradle Plugins

   ```kotlin
   // Extension
   interface GreetingPluginExtension {
       val message: Property<String>
       val greeter: Property<String>
   }

   class GreetingPlugin : Plugin<Project> {
       override fun apply(project: Project) {
           val extension = project.extensions.create<GreetingPluginExtension>("greeting")
           project.task("hello") {
               doLast {
                   println("${extension.message.get()} from ${extension.greeter.get()}")
               }
           }
       }
   }

   // 引入 GreetingPlugin
   apply<GreetingPlugin>()

   // 使用 DSL block 进行配置
   configure<GreetingPluginExtension> {
       message.set("Hi")
       greeter.set("Gradle")
   }

   // 打印效果
   // > gradle -q hello
   // Hi from Gradle
   ```

- 要想查看 APG 的源码。可以在根项目的 buildScript 和 dependencies(重点) 中配置 Android 插件依赖：

   ```groovy
   // 配置项目用到的依赖
   allprojects {
       repositories {
           google()
           mavenLocal()
           maven { url "https://maven.aliyun.com/repository/public" }
       }
       dependencies {
           classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
           classpath "com.android.tools.build:gradle:$agpVersion"
       }
   }

   // 配置 gradle 脚本自身用到的依赖
   buildscript {
       repositories {
           google()
           mavenLocal()
           maven { url "https://maven.aliyun.com/repository/public" }
       }

       dependencies {
           classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
           classpath "com.android.tools.build:gradle:$agpVersion"
       }
   }
   ```

- gradle 插件可由两部分标识：id 和 version。这两者可用于唯一确定一个插件。

- gradle 插件分为两类，插件具体的引入方式见：Using Gradle Plugins。

   1. 脚本插件(script plugins)：脚本插件可以看作源码插件，脚本文件通过 "apply from: "xxxx""(Groovy 语法) 的形式引入。我们在项目中定义的 xxx.gradle 就是这种脚本文件，其默认会引入当前的 project 对象。app 工程 apply 了脚本插件，脚本关联的就是 app project 对象；root 引入了脚本插件，脚本里关联的就是 rootProject 对象。注意 apply from 引入的脚本插件，可以是 http 链接。

      ```kotlin
      apply(from = "other.gradle.kts")
      ```

   2. 二进制插件(binary plugins)：二进制插件是会编译成 class 文件的插件，通过 "apply plugin: "xxxx""(Groovy 语法) 的形式引入。

      ```kotlin
      apply<GreetingPlugin>()
      ```

- Gradle 默认有个 buildSrc 目录(名称必须准确，每个字符都必须对上)。buildSrc 目录会被视为 included build。Gradle 发现该目录后，会自动编译该目录的代码，并将其放入构建脚本的类路径中。对于多项目构建，只能有一个 buildSrc 目录，它必须位于项目根目录中。在自定义插件等场景中，buildSrc 应该优先于脚本插件，因为它更容易维护、重构和测试代码。

   - 如果想要在本工程中以单独模块的形式引入 gradle 插件，则可以使用 buildSrc 目录的形式，使用时将插件 apply 到对应项目。buildSrc 的 build.gradle 脚本先于 rootProject 的 build.gradle 脚本执行。buildSrc 的 repositories 需要单独配置

   - 如果需要暴露给其他项目，则需要使用单独 module 的形式，并配置 maven publish。单独 module 的形式(非 buildSrc)编写插件，需用远程仓库的形式(如 api "com.xxx.xxx:xxx:xx" 的形式)引入，否则会出现插件找不到的问题。

插件的知识点就暂时先讲这些吧。

## 结语

Gradle 作为 Android 项目的管理工具，其灵活度相当之高，功能和知识点相当之多，但是版本迭代也相当之快。本文某种程度上可以作为我的一个学习记录，虽然写了这么多内容，但仍有较大的遗憾、缺陷以及不懂的地方。一方面仍遗留了很多知识点没介绍，比如缓存、工件发布(publication)等等；另一方面很多知识点也没详细介绍，比如 Gradle 的产物、Configuration 功能、Java 插件、上传插件等等。没有补充到的点都是没有学到的点(-_-|||)。所以还是得继续学习，常用常新。

最后感谢大家以极大的耐心阅读本文，文中的错误、不足也请指出，方便改正和补充。

