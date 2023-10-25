---
title: "Android 组件化"
description: "本文讲解了如何在 Android 项目中实现组件化"
keywords: "Android,组件化"

date: 2021-05-17 16:57:00 +08:00
lastmod: 2021-05-17 16:57:00 +08:00

categories:
  - Android
  - 组件化
tags:
  - Android
  - Android 组件化

url: post/071DE5F05689474694D8A705245B423E.html
toc: true
---

本文讲解了如何在 Android 项目中实现组件化。

<!--More-->

## 为什么要组件化

- 代码隔离
- 功能复用
- 单独编译
- 应用安全

## 组件化前提

- 避免循环依赖
- 组件之间完全平等
- 组件层次清晰

## 组件化分层结构

1. **App 壳工程**：负责管理各个业务组件和打包 APK，没有具体的业务功能
2. **业务组件层**：根据不同的业务构成独立的业务组件，其中每个业务组件包含一个对外暴露的接口，以及对应的接口实现
3. **功能组件层**：对上层提供基础功能服务，如日志服务，网络服务等
4. **组件基础设施**：页面路由服务、消息总线、组件功能加载器等

## 组件化分类

1. 单工程方案：App 壳工程和组件在相同的工程中。本文重点讲这个，懂个这个，就能覆盖大多数场景了
2. 多工程方案：App 壳工程和组件在不同的工程中，此方案本文不讲，懂了"单工程方案"就懂了这个了

## 组件化实现过程

### 1. 壳工程与业务组件

组件化，也可以叫做模块化。每个新建的 Android 工程默认有一个 app module，然后还可以通过 File -> New -> New Module 选项新建一个 module。我们可以把 app module 称为壳工程，把新建的 module 称为业务组件。

在 Android Studio 中，使用 Gradle 构建时，Android Gradle 中提供了三种插件，在开发中可以通过配置不同的插件来配置不同的module类型。我们使用 Application 和 Library 两种插件。

- Application 插件：id: com.android.application。作用是配置一个 Android App 工程，项目构建后输出一个 APK 安装包
- Library 插件：id: com.android.library。作用是配置一个 Android Library 工程，构建后输出 ARR 包

![Library插件1](/imgs/Library插件1.png)

![Library插件2](/imgs/Library插件2.png)

显然，App 壳工程就是配置 Application 插件，业务组件就是配置 Library 插件。

注意点：

1. 值得一提的是，新建 module 时，Android Studio 会根据选择的不同，自动分配不同的插件：

   ![新建项目时的不同插件](/imgs/新建项目时的不同插件.png)

   - 如果选择的是 1，则 Android Studio 会自动使用 Application 插件，并生成对应的包结构
   - 如果选择的是 2，则 Android Studio 会自动使用 Library 插件，并生成对应的包结构
2. Android Studio 新建 Module 时，会自动向 settings.gradle 文件中添加 Module。如果我们不使用 Android Studio 提供的 New Module 选项，而是手动创建 Module，那么我们需要向 settings.gradle 中手动添加创建好的 module，以便 gradle 能正确识别生效的 module。

   ![include模块](/imgs/include模块.png)

壳工程与业务组件创建好后，工程包结构如下：

![壳工程结构](/imgs/壳工程结构.png)

3. 如果有多个业务模块，那么可以收敛到一个业务包 lib 下，创建时可以使用下图的 module 名：

   ![一包多module的命名](/imgs/一包多module的命名.png)

创建好后，项目结构长这样：

   ![一包多module的结构](/imgs/一包多module的结构.png)

settings.gradle 里的结构是这样，包名为 ":lib:module_chat"/":lib:module_mine"：

   ![settings文件示例](/imgs/settings文件示例.png)

### 2. 单独编译与变量定义

想要实现业务组件的单独编译，就需要把配置改为 Application 插件；而调试完成后，又需要变回 Library 插件以进行集成调试。如何让组件在这两种调试模式之间自动转换呢？当然可以手动修改组件的 gralde 文件，但是如果项目有几十个组件，那一个个的改可就太让人难受了。所以我们需要寻找另外一种方法。下面直接说结论。

Gradle 支持三种 Properties, 这三种 Properties 的作用域和初始化阶段都不一样：

1. System Properties(Root Project Properties): 
   1. 可通过 gradle.properties 文件，环境变量 或 命令行 -D 参数 设置
   2. 可在 setting.gradle 或 build.gradle 中动态修改，在 setting.gradle 中的修改对 buildscript 配置块可见
   3. 所有工程可见，不建议在 build.gradle 中修改
   4. 多子工程项目中，子工程的 gradle.properties 会被忽略掉，只有 root 工程的 gradle.properties 有效
2. Project Properties: 
   1. 可通过 gradle.properties 文件，环境变量 或 命令行 -P 参数 设置
   2. 可在 build.gradle 中动态修改，但引用不存在的 project properties 会立即抛错
   3. 动态修改过的 project properties 对 buildscript 配置块中不可见
3. Project ext properties:
   1. 可在项目的 build.gradle 中声明和使用，本工程和子工程可见
   2. 不能在 setting.gradle 中访问
4. Other properties:
   1. 自定义 properties 文件
   2. 访问方式比较特别(下面讲解)

注意：buildscript 优先于 build.gradle 中的其他内容执行，注意变量的使用范围。

1. System Properties 方式定义变量

根据上面的描述，我们可以在 System Properties 中定义调试切换开关，即在项目根目录下的 gradle.properties 文件中定义变量，在所有业务组件子项目中引用。

```java
// 文件名：gradle.properties
// 组件独立调试开关, 每次更改值后要同步工程
isAPK = false
```

2. Other properties 方式定义变量

我们可以自定义一个 properties 文件，然后手动读取里面的属性并赋值。以 local.properties 文件为例。每个 Android 项目中都会有一个 local.properties 文件，但是该文件并不会纳入到 git 管理中，因为这是 Android Studio(IDEA) 动态生成的文件。如果我们不做改动，那么里面默认定义了 sdk.dir 属性，该属性表示 Android SDK 的目录。我们可以在这个目录中额外定义属性，然后手动读取它。如果我们希望部分项目中定义的变量不放入到 git 仓库中(比如 release 包签名，比如私有 maven 仓库账号密码)，那么就可以放入到  local.properties 文件中定义(gradle.properties 文件会跟随 git 管理)。

首先定义 isAPK 属性，不定义则为 false

![定义isAPK属性](/imgs/定义isAPK属性.png)

在 Root Project 的 build.gradle >>> buildscript 闭包中，我们可以读取属性，必将其赋值给 Root Project 的 ext。

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

在业务组件的 build.gradle 中声明插件

```java
// 文件名：业务组件的 build.gradle
// 注意 gradle.properties 中的数据类型都是 String 类型，使用其他数据类型需要自行转换
if (isAPK.toBoolean()){
    apply plugin: 'com.android.application'
} else {
    apply plugin: 'com.android.library'
}
// 如果变量定义在 local.properties 中，则需要使用 rootProject.isAPK 进行判断
// if (rootProject.isAPK){
//     apply plugin: 'com.android.application'
// } else {
//     apply plugin: 'com.android.library'
// }
```

每个 App 都是需要一个 ApplicationId 的 ，而组件在单独编译时也是一个 App，所以也需要一个 ApplicationId。另外每个 APP 也有一个启动页，启动页声明在 AndroidManifest 文件中。所以这两个也需要单独配置。

```java
// 文件名：业务组件的 build.gradle
android {
    defaultConfig {
        // 使用 applicationId 
        if (isAPK.toBoolean()) {
            // 单独编译时添加 applicationId
            applicationId "com.example.xxx"
        }
    }

    sourceSets {
        main {
            // 单独编译时使用不同的清单文件
            if (isAPK.toBoolean()) {
                manifest.srcFile 'src/main/apk/AndroidManifest.xml'
            } else {
                manifest.srcFile 'src/main/module/AndroidManifest.xml'
            }
        }
    }
}
```

两个清单文件的内容如下，一个指定了 application 和启动页(可单独编译)，一个没有指定(不能单独编译)。

```java
// apk/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.xxx" >
    <application android:name=".XXXApplication"
        android:allowBackup="true"
        android:label="XXX"
        android:theme="@style/Theme.AppCompat">
        <activity android:name=".XXXMainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

```java
// module/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.xxx">
    <application>
        <activity android:name=".XXXActivity"></activity>
    </application>
</manifest>
```

这样配置以后，我们就可以在 Android Studio 中选择需要运行的 APK 了。

![选择需要运行的APK](/imgs/选择需要运行的APK.png)

注意：Android Gradle 中，可以为每个 module 设置不同的 applicationIdSuffix(在 ProductFlavor 中设置)。该字段表示：在不改变默认的包名的情况下，为其添加后缀。比如应用包名是com.example.demo，但你想为 chat 模块设置不同的包名，这个时候将applicationIdSuffix设置为.chat，那么你的应用程序对应的包名就变成了com.example.demo.chat。设置 applicationIdSuffix 可以实现不为各模块手动设置 applicationId，但各 demo 工程包名不同的效果。applicationIdSuffix 具体说明见：https://developer.android.com/studio/build/application-id?hl=zh-cn

### 3. 组件下沉

上面讲过，组件化里的方案里，其实有一个多工程的方案选项。这个方案我们其实可以和单工程方案结合起来使用。比如一些很基础的组件，就可以下沉到一个单独的项目中，作为二方库使用，通常而言，二方库是对三方库的再一次封装，当然也有完全自己实现功能的。比如日志库、图片库、网络库等十分基础的常用的组件和功能，就可以下沉为二方库。就公司层面而言，组件下沉有几方面的好处：

- 代码隔离：降低因代码改动带来的风险，单工程组件化可能存在解耦不彻底的风险，从而导致一些问题
- 权限管理：下沉为一个单独的项目，可以管理不同成员的权限了，比如项目部署在 gitlab 上，而有些核心项目，是不想让部分成员看见的，就可屏蔽掉(比如 IM 库，不想让外包人员了解，就可以不给其分配权限)
- 功能复用：想日志、网络等基础功能，封装好组件库后，一个公司内的所有 APK 都可以导入使用，避免了重复造轮子带来的浪费

组件下沉后该如何使用呢？首先，我们知道，Android 项目使用 Gradle 构建，Gradle 可以依赖本地包或者远程包，这些包可以是 aar 包或者 jar 包，对于 APP 壳工程，可以使用这种方法依赖二方库。aar 包和 jar 的区别，可以看看这篇文章：[jar 包与 aar 包的区别](https://blog.csdn.net/ljx1400052550/article/details/80111051)。简单的讲，aar 包可以包含资源，jar 包不行。

然后，对于组件，就公司层面而言，一般我们会把下沉的组件放到服务器上，方便公司的其他项目也一起使用。这就涉及到了组件项目的编译和上传过程。Google 提供的 library 插件可以把项目打包成一个 aar 包，那么编译这一块我们就不必费神了。我们只需要关注如何将编译好的 aar 包上传到服务器即可。

#### 第 1 种属性定义方式

首先我们在项目根目录下新建一个 maven_info.properties 文件，这个文件用于记录 maven 仓库的所需信息

```java
# 文件名：maven_info.properties
# 用户名
user=android
# 密码
password=android123
# release 仓库地址
url.release=url:port/nexus/content/repositories/android-release/
# dev 仓库地址
url.dev=url:port/nexus/content/repositories/android-dev/
# POM 的名称，给用户提供的更为友好的项目名
# POM 全称是Project Object Model，即项目对象模型，它是 Maven 中工作的基本组成单位
pom.name=android
# 项目描述，在 maven 文档中保存
pom.description=example chat lib
# 项目组的编号，这在组织或项目中通常是独一无二的。
# 例如，一家银行集团 com.company.bank 拥有所有银行相关项目。
pom.groupId=com.example.test
# 项目的 ID。这通常是项目的名称
pom.artifactId=lib-chat
# 项目打包方式
pom.packaging=aar

# RELEASE 版本号
pom.version.release=1.0.0
# DEV 版本号
pom.version.dev=1.0.0-Dev
# 是否上传 dev 版本
isDev=false
```

然后新建一个 maven_upload.gradle 文件，定义上传任务。

```java
// 文件名：maven_upload.gradle
// 使用 maven 插件
apply plugin: 'maven'

// 读取配置文件 maven_info.properties
Properties properties = new Properties()
properties.load(project.rootProject.file('maven_info.properties').newDataInputStream())
def userName = properties.getProperty("user")
def userPassword = properties.getProperty("password")
def releaseUrl = properties.getProperty("url.release")
def devUrl = properties.getProperty("url.dev")
def isDev = properties.getProperty("isDev").toBoolean()
def pomName = properties.getProperty("pom.name")
def pomDescription = properties.getProperty("pom.description")
def pomGroupId = properties.getProperty("pom.groupId")
def pomArtifactId = properties.getProperty("pom.artifactId")
def pomPackaging = properties.getProperty("pom.packaging")
def pomVersionRelease = properties.getProperty("pom.version.release")
def pomVersionDev = properties.getProperty("pom.version.dev")

def repoUrl
def pomVersion

// uploadArchives 是一个 task
uploadArchives {
    if(isDev) {
        repoUrl = devUrl
        pomVersion = pomVersionDev
    } else {
        repoUrl = releaseUrl
        pomVersion = pomVersionRelease
    }
    // maven 部署器
    repositories.mavenDeployer {
        // 指定用户名，密码
        repository(url: repoUrl) {
            authentication(userName: userName, password: userPassword)
        }
        // 调用 gradle 的 uploadArchives 的 task 就可以上传了
        // 对这部分感兴趣的可以搜索下 pom.xml
        pom.project {
            name pomName
            description pomDescription
            url repoUrl
            groupId pomGroupId
            artifactId pomArtifactId
            version pomVersion
            packaging pomPackaging
        }
    }
}
```

定义好 maven 任务后，在 library 的 build.gradle 项目中引入：

```java
// library 的 build.gradle 文件
if (isAPK.toBoolean()) {
    apply plugin: 'com.android.application'
} else {
    apply plugin: 'com.android.library'
}
// 引用本地的 gradle 文件
apply from: "${rootDir}/maven_upload.gradle"
```

点击 gradle 任务中的 task 即可上传到指定的 maven 仓库。

![上传到指定的maven仓库](/imgs/上传到指定的maven仓库.png)

#### 第 2 种属性定义方式

注意：maven_info.properties 这个文件中的内容，其实也可以定义在 gradle 中。比如在根目录下定义一个 config.gradle 文件。

```java
// 文件名：config.gradle
ext{
    // 用户名
    user="android"
    // 密码
    password="android123"
    // release 仓库地址
    url.release="url:port/nexus/content/repositories/android-release/"
    // dev 仓库地址
    url.dev="url:port/nexus/content/repositories/android-dev/"
    // POM 的名称，给用户提供的更为友好的项目名
    // POM 全称是Project Object Model，即项目对象模型，它是 Maven 中工作的基本组成单位
    pom.name="android"
    // 项目描述，在 maven 文档中保存
    pom.description="example chat lib"
    // 项目组的编号，这在组织或项目中通常是独一无二的。
    // 例如，一家银行集团 com.company.bank 拥有所有银行相关项目。
    pom.groupId="com.example.test"
    // 项目的 ID。这通常是项目的名称
    pom.artifactId="lib-chat"
    // 项目打包方式
    pom.packaging="aar"
    
    // RELEASE 版本号
    pom.version.release="1.0.0"
    // DEV 版本号
    pom.version.dev="1.0.0-Dev"
    // 是否上传 dev 版本
    isDev=false
}
```

然后 maven_upload.gradle 文件改成这样即可。

```java
// 文件名：maven_upload.gradle
// 使用 maven 插件
apply plugin: 'maven'
apply from: "${rootDir}/config.gradle"

def repoUrl
def pomVersion

// uploadArchives 是一个 task
uploadArchives {
    if(isDev) {
        repoUrl = url_dev
        pomVersion = pom_version_dev
    } else {
        repoUrl = url_release
        pomVersion = pom_version_release
    }
    // maven 部署器
    repositories.mavenDeployer {
        // 指定用户名，密码
        if(isDev) {
            // Dev 作为快照版本
            snapshotRepository(url: repoUrl) {
                authentication(userName: user, password: password)
            }
        } else {
            // 非 Dev 作为正式版本
            repository(url: repoUrl) {
                authentication(userName: user, password: password)
            }
        }
        // 调用 gradle 的 uploadArchives 的 task 就可以上传了
        // 对这部分感兴趣的可以搜索下 pom.xml
        pom.project {
            name pom_name
            description pom_description
            url repoUrl
            groupId pom_groupId
            artifactId pom_artifactId
            version pomVersion
            packaging pom_packaging
        }
    }
}
```

然后正常引入任务即可：

```java
// library 的 build.gradle 文件
if (isAPK.toBoolean()) {
    apply plugin: 'com.android.application'
} else {
    apply plugin: 'com.android.library'
}
// 引用本地的 gradle 文件
apply from: "${rootDir}/maven_upload.gradle"
```

#### 为 aar 包添加源码和注释

如果想要上传的包中带有源码和注释，则需要定义额外的任务，用来将源码和注释打包。在生成 aar 的同时,在 build 目录会有一个 libs 目录,里面放着源码和文档的 jar 包,如果上传到 maven 私服,会自动同时提交。如果使用本地aar,需要单独引入。在 maven_upload.gradle 文件中新增如下任务：

```java
// 文件名：maven_upload.gradle
// 代码是固定模版

// 打包注释，生成 javadoc.jar
// 使用 .sourceFiles 时，gradle 筛选了 .java 类型的文件进行打包
// 而使用 .getSrcDirs() 把整个目录作为参数时，gradle 不再排查文件后缀，把所有目录下所有文件都打包进来了。
task androidJavadocsJar(type: Jar, dependsOn: Javadoc) {
    // classifier = 'javadoc'
    // from android.sourceSets.main.java.sourceFiles
    // 指定文档名称
    archiveClassifier.set('javadoc')
    from android.sourceSets.main.java.getSrcDirs()
}
// 打包源码，生成 sources.jar
task androidSourcesJar(type: Jar) {
    // classifier = 'sources'
    // from android.sourceSets.main.java.sourceFiles
    archiveClassifier.set('sources')
    from android.sourceSets.main.java.getSrcDirs()
}
// 处理 Maven 需要上传的包
artifacts {
    if (isDev) {
        archives androidSourcesJar
        archives androidJavadocsJar
    }
}
```

#### 上传成功后清除缓存

在得到源码 aar 包后，再加上上传成功后删除本地缓存的逻辑。

```java
// 文件名：maven_upload.gradle
task cleanDir(type:Delete) {
    delete buildDir
}

// 上传后，执行清除任务
uploadArchives.mustRunAfter 'cleanDir'
```

对于 APP 壳工程而言，使用下面的代码，可以引用二方库上传到 Maven 的 aar 包或者 jar 包。

第 1 步，添加 Maven 仓库地址到依赖中。

```java
allprojects {
    repositories {
        google()
        jcenter()
        //私有 maven 仓库地址
        maven {
            url 'http://xxx'
        }
    }
}
```

第 2 步，在 APP 壳工程中添加依赖库。

```java
dependencies {
    implementation 'com.example.test:xxx:xxx'
    // ......
}
```

上面的代码就将组件下沉以及依赖引入的主体流程讲完了。下面讲下其他关键点。

### 4. 界面跳转

组件化的核心之一就是代码解耦，所以组件间是不能有直接依赖的，那么如何实现组件间的页面跳转呢？这里就有两种方法了：一种是显式指定页面，一种是隐式启动页面。显式指定页面就是比如说直接指定具体的某个页面(包名+类名)；而隐式启动页面就是按类型启动，比如启动音乐界面、登录界面等，我们不关心是哪个界面，我们只需要知道你有这个功能就够了。这和 Android 系统的 Intent 跳转有点类似。当然，这两个启动都有一定的缺陷。首先是显式指定页面的方式，这种方式会导致比较强的耦合，与组件化的初衷有所背离。而隐式启动页面界面，又会导致管理较集中，不便于多方协作。

综上，页面跳转方式的设计肯定是有取舍折中的。但是组件化的初衷就是解耦，所以实际实现中，我们通常还是会采取隐式启动页面的方式。而其具体的实现，又有两种途径，一种是使用第三方开源库，一种则是自定义。下面将分别讲解，其中第三方开源库的实现方式会采用阿里的 ARouter。

#### 1. common 组件

组件化中，通常都会存在一个公共的核心组件，我们可以称之为 common 组件。其他所有的组件，都依赖了这个 common 组件，包括 APP 壳工程。有了这么一个公共组件，我们就可以做很多事了，比如管理页面跳转。

#### 2. 第三方开源库 ARouter 实现页面跳转

ARouter 是阿里 Android 技术团队开源的一款路由框架。这款路由框架可以为我们的应用开发提供更好更丰富的跳转方案。比如支持解析标准 URL 进行跳转，并自动注入参数到目标页面中；支持添加多个拦截器，自定义拦截顺序（满足拦截器设置的条件才允许跳转，所以这一特性对于某些问题又提供了新的解决思路）。使用 ARouter 具有以下优势：

1. 通过 URL 索引跳转就可以解决类依赖的问题
2. 通过分布式管理页面配置可以解决隐式 intent 中集中式管理 Path 的问题
3. 自己实现的整个路由过程可以拥有良好的扩展性
4. 可以通过 AOP 的方式解决跳转过程无法控制的问题，与此同时也能够提供非常灵活的降级方式

下面开始介绍使用 ARouter 实现页面跳转

##### 1. 引入 ARouter

ARouter 可以在所有组件中使用，则需要在 Common 组件中添加 Arouter 的依赖。另外，其它组件共同依赖的库也要都放到 Common 中统一依赖(避免重复依赖，以及可能由此带来的依赖包版本不一致问题)。使用下面的配置引入 ARouter：

```java
// common 组件的 build.gradle 文件
android {
    defaultConfig {
        javaCompileOptions.annotationProcessorOptions {
            arguments = [AROUTER_MODULE_NAME: getProject().getName()]
        }
    }
}

dependencies {
    // 替换成最新版本, 需要注意的是api
    // 要与compiler匹配使用，均使用最新版可以保证兼容
    implementation 'com.alibaba:arouter-api:1.5.1'
    annotationProcessor 'com.alibaba:arouter-compiler:1.5.1'
}
```

##### 2. 初始化 ARouter

阿里官方建议我们在 Application 里面进行 ARouter 初始化：

```java
public class TestApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        // 这两行必须写在 init 之前，否则这些配置在 init 过程中将无效
        if (BuildConfig.DEBUG) {
            // 打印日志
            ARouter.openLog();
            // 开启调试模式。如果在 InstantRun 模式下运行，必须开启调试模式！
            // 而线上版本需要关闭,否则有安全风险
            ARouter.openDebug();
        }
        // 尽可能早，推荐在 Application 中初始化
        ARouter.init(this);
    }
}
```

##### 3. ARouter 添加路由地址

```java
// 1. 在 Activity/Fragment 类上面定义路由
@Route(path = "/app/activity_main")
public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        // 2. 在 Activity/Fragment 类里面进入 Arouter 注入
        ARouter.getInstance().inject(this);
        findViewById(R.id.tv).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // 3. 构建路由，进行跳转
                ARouter.getInstance().build("/app/activity_second").navigation();
            }
        });
    }
}
```

ARouter 的基本使用有三点：

1. 在 Activity/Fragment 类上面定义路由，路由至少需要有两级，形如：/xx/xx
2. 在 Activity/Fragment 类里面进入注入，也就是：ARouter.getInstance().inject(this)。因为能跳转的页面都需要注入。所以建议此处将注入逻辑放入基础 Activity/Fragment 中，如在 BaseActivity/BaseFragment 的 onCreate 中注入
3. 使用目标页面的路由进行跳转。建议将页面的路由放到一个统一的地方，集中进行管理

##### 4. ARouter 携带参数跳转

上面的代码，页面跳转时没有携带参数，ARouter 也支持携带参数的跳转，使用方式如下：

```java
ARouter.getInstance()
    .build("/app/activity_second")
    .withString("name", "zhang") //携带参数 1
    .withInt("age", 3) //携带参数 2
    .navigation();
```

而在目标界面 SecondActivity 中，我们需要使用 Autowired 注解以获取对应的参数值(自动获取，不需要再手动赋值)：

```java
@Route(path = "/app/activity_second")
public class SecondActivity extends AppCompatActivity {
    @Autowired
    private String name;
    @Autowired(name = "age")
    private int age;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_second);
        ARouter.getInstance().inject(this);
    }
}
```

##### 5. ARouter 路由回调

在使用 ARouter 进行界面跳转时，可以设置回调，以监听路由状态.回调接口 NavigationCallback 有一个抽象类的实现：NavCallback。图方便的话，可以使用 NavCallback：

```java
ARouter.getInstance().build(path)
    .navigation(context, new NavigationCallback() {
        @Override
        public void onFound(Postcard postcard) {
            // 找到了要打开的 activity
        }

        @Override
        public void onLost(Postcard postcard) {
            // 找不到要打开的 activity
        }

        @Override
        public void onArrival(Postcard postcard) {
            // 已经打开了目标activity
        }

        @Override
        public void onInterrupt(Postcard postcard) {
            // 跳转请求被拦截了
        }
    });
```

##### 6. ARouter 界面跳转动画

调用 withTransition，里面传入两个动画的资源 id(如 R.anim.xxx)，即可实现 Activity 的转场动画。当然，更复杂的，还是建议自己实现(如共享元素动画)：

```java
ARouter.getInstance().build("app/activity_second")
    .withTransition(enterAnimId, exitAnimId)
    .navigation();
```

ARouter 的用法，就先讲这么多吧。更多用法可以参考阿里的官方文档：[ARouter 的使用](https://gitee.com/mirrors/ARouter)

#### 3. 自定义实现页面跳转

第三方开源库的跳转方式讲了，那么如何自定义实现页面跳转呢？首先，我们不能显式的指定类名来启动界面，那么就只能隐式的打开界面了。一般而言，我们通过接口来打开页面。比如我们定义了一个 Login 组件，那么我们可以定义下面的 api 跳转登录页，然后在其他地方使用`LoginApi.startLoginPage(activity)`即可：

```java
// 文件名：LoginApi.java
// 启动登录页
public static void startLoginPage(Activity activity) {
  // 具体实现省略
}
```

那么问题来了，api 类应该定义在哪里呢？首先，API 的含义就是组件向外暴露的接口，当然可以被其他模块使用。我们知道，common 组件是被所有组件单向依赖的，那么定义在 common 中，就可以被所有组件使用了。然后 API 方法的具体实现肯定是放在各个组件中(否则会出现找不到类的错误)。这样就形成了 "声明在 common 组件，实现在业务组件" 的布局。这种场景还可以优化，即把 "声明和实现都放在业务组件，编译时将声明拷到 common 组件"。当然，这样做会导致类重复定义的问题(包名相同，类名相同)。所以还需要做点优化，即做到 "业务组件中类的声明不可被编译器识别" 就 OK 了。事实上，Android Studio 提供了这样的一个能力，可以把非 Java 文件当做 Java 文件处理，但是 Java 编译器只会识别 .java 文件。这么一来我们就能通过以下方法暴露出业务组件的接口声明到 common 组件中，同时不暴露接口的具体实现，做到代码隔离，并且不会编译出错了。

- 在业务组件中定义接口和类声明
- 拷贝接口和类声明到 common 组件中
- 在业务组件中实现接口和类
- 在其他组件中使用 Api 等暴露出来的接口

##### 1. 定义接口声明

Android Studio 中，提供了将非 Java 文件当做 Java 文件处理的能力。这里以文件名后缀名为 .api 的文件为例，使用如下的设置后，Android Studio 可以将 api 文件当做 java 文件处理。

在 Android Studio 中选择 File ---> Settings ---> Editor ---> File Types ---> Java，然后在 Registered Patterns 中添加 *.api，Android Studio 就会将后缀名为 .api 的文件当做 java 文件处理了。

![配置识别api后缀文件](/imgs/配置识别api后缀文件.png)

然后我们定义一个接口文件：

```java
// 文件名：LoginApi.api
public class LoginApi {
    public static void startLoginPage(Context context) {
        // 实现省略
    }
}
```

##### 2. 拷贝声明到 common 组件中

在我们声明了接口文件之后，怎么将文件拷贝到 common 组件中呢？自然不可能手动拷，我们可以写个脚本，在 Android Studio 开始编译前，将 api 文件从源目录拷到目标目录，然后拷贝的过程中，给 common 中的声明改个名，将 .api 的后缀改为 .java 的后缀。当然，为了减少扫描目录的时间开销，我们需要把源文件和目标文件都限定在一个特定目录中。

拷贝脚本可以定义为一个 gradle task，然后源文件(.api)和目标文件(.java)的 root 目录，可以限定为 com.xxx.xxx.api.module_name 包名，各个组件拷贝后，可以放到 api 包下，比如登录组件的接口，包名就叫 com.xxx.xxx.api.login，而聊天组件的接口，包名就叫 com.xxx.xxx.api.chat。

```java
// 同步任务(Sync)继承自复制任务(Copy)，当它执行时，它会复制源文件到目标目录中，然后从目标目录中的删除所有非复制的文件
task copyApiToJava(type: Sync) {
    // 第 1 步，获取所有子模块
    Set<Project> projects = project.subprojects
    if(projects == null || projects.size() <= 0) {
        return
    }
    // 第 2 步，获取 common 模块
    // 注：project 的 path 是在 name 前加上 :，表示相对路径
    Project comProject = project.rootProject.findProject(":common")
    // 拷贝所有组件的接口到 common 组件中
    projects.each {
        from "${rootDir}/${it.name}/src/main/java/com/xxx/xxx/api"
        into "${rootDir}/${comProject.name}/src/main/java/com/xxx/xxx/api/${it.name}"
        //排除所有的.java文件
        exclude '**/*.java'
        //包括所有的.api文件
        include '**/*.api'
        rename { String fileName ->
            fileName.replace(".api", ".java")
        }
    }
}

//在preBuild之前，必须先运行 copyApiToJava
preBuild.dependsOn copyApiToJava
```

拷贝后，我们就能在 common 组件的 api 目录下看见 java 文件了。这种拷贝还有一个好处，那就是 common 组件中的接口可以动态生成，sync 拷贝时，会清空 common 组件中的接口，再把新的接口添加上。各个组件可以自己维护需要暴露给其他组件的接口。从 git 的角度讲，那就是可以把业务组件中的接口和实现文件使用 git 管理，而 common 组件中的接口就不用使用 git 管理，编译前动态拷贝一份即可。

##### 3. 业务组件中实现接口

当把声明拷贝到 common 组件中之后，我们就可以在业务组件中实现 common 组件中的接口了。比如 Login 模块有个 Login 的功能。那么我们可以在 login 模块中定义两个 api 文件：

1. LoginApi.api 文件

   ```java
   // 文件名：LoginApi.api
   public class LoginApi {
       public static void startLoginPage(Context context) {
           ILoginService service = new LoginServiceImpl();
           service.startLoginPage(context);
       }
   }
   ```

2. ILoginService.api 文件

   ```java
   // 文件名：ILoginService.api
   public interface ILoginService {
       void startLoginPage(Context context);
   }
   ```

然后执行 copyApiToJava task，将在 login 模块中的 api 文件，拷贝到 common 组件中。再在 login 组件中实现 ILoginService。

3. LoginServiceImpl.java 文件

   ```java
   // 文件名：LoginServiceImpl.java
   public class LoginServiceImpl implements ILoginService {
       @Override
       public void startLoginPage(Context context) {
           // 具体实现省略
       }
   }
   ```

这下就实现了 代码隔离 + 接口暴露。在其他模块中，调用`LoginApi.startLoginPage`方法就可以启动登录页了

##### 自定义路由步骤总结

从上面的讲解中，我们可以看出，自定义路由需要经过以下步骤：

1. 定义 api 文件
2. 拷贝 api 文件到 common 组件中
3. 实现接口声明
4. 在其他组件中使用定义好的 api 接口

上面的几个步骤，其实第 2 步和第 3 步可以互换。即使先实现再拷贝也是可行的。因为 Android Studio 此时已经把 api 文件当做了 java 文件，使用 api 文件编辑器不会报错。而实现后再拷贝，是保证编译器不会报错。所以，上面定义的顺序，是逻辑顺序，和实际使用时的顺序，可以有所不同。这点需要清楚。否则后面项目其他成员来实现组件化，按照实际使用流程理解的话，可能会陷入死胡同。

### 5. 组件通信

上面讲了，组件化的一个核心就是代码解耦。在组件化开发的时候，组件之间是相互独立的没有依赖关系，A 不能显式调用 B 组件的方法，也就不能直接通知 B 组件了。那么 A 组件要如何通知 B 组件，并且携带上参数呢？

首先讲下通信架构，一般的通信架构如下。通知方和被通知方都只和通信管理器打交道，而通信管理器和通信总线打交道，而通知总线和通知方、被通知方打交道。即通知方、被通知方依赖于通信管理器，通信管理器依赖于通信总线，而通信总线依赖于通知方、被通知方。

- 通知方通过通信管理器发起通知，而通信管理器通过通信总线将通知发送被通知方
- 被通知方通过通信管理器发起通知响应，而通信管理器通过通信总线将通知响应发送通知方

![通信总线架构](/imgs/通信总线架构.png)

上面的架构图，一定程度上借鉴了电脑架构里的总线设计。总线代表了具体的实现(如第三方 SDK 实现和自定义实现)，而图中的通知方和被通知方，都是逻辑结构。这样一来，就可以实现代码的解耦。后续也可以方便的切换总线。

而组件间通信的具体实现思路其实和页面跳转差不多，主要用两种方式实现，如下。以 Login 组件通知 Chat 组件为例，登录成功后，可以聊天了。

- 第三方 SDK 实现组件间通信，以 ARouter 为例，可以在 Bundle 中加入参数，但是 Bundle 中的参数大小是有限制的。所以还是需要另外定义通信逻辑
- 自定义实现组件间通信

综上，下面讲解下如何自定义组件通信。

#### 1. 定义逻辑结构

按照上面的思路，我们先定义一下逻辑结构。定义会尽量简单，否则就会扯到通知，通知成功，响应，响应成功等一系列复杂概念，就和 TCP 的 三次握手/四次挥手 类似了。

**通信请求和通信响应**

通信请求和通信响应的类定义如下。

```java
// 通知
public class NotifyRequest {
    // 代码省略
}
```
```java
// 通知响应
public class NotifyResponse {
    // 代码省略
}
```

**通知方和被通知方**

通知方和被通知方的类定义如下。

```java
// 通知方
public interface NotifyParty {
    // 收到被通知方的通知响应
    void onReceivedResponse(NotifyResponse response);
}
```

```java
// 被通知方
public interface NotifiedParty {
    // 收到通知
    void onReceivedNotify(NotifyRequest notify);
}
```

**通知管理器和通信总线**

```java
// 通知管理器
public class NotifyManager {
    // 发送通知
    public boolean sendNotify(NotifyRequest notify) {
        boolean isSendSuccess = false;
        // 通过通信总线发送通知
        return isSendSuccess;
    }
    // 发送通知响应
    public boolean sendResponse(NotifyResponse response) {
        boolean isSendSuccess = false;
        // 通过通信总线发送通知响应
        return isSendSuccess;
    }
}
```

```java
// 通信总线
public class NotifyBus {
    // 下发通知
    public boolean dispatchNotify(NotifyRequest notify) {
        boolean isSendSuccess = false;
        // 通过通信总线发送通知
        return isSendSuccess;
    }
    // 下发通知响应
    public boolean dispatchResponse(NotifyResponse response) {
        boolean isSendSuccess = false;
        // 通过通信总线发送通知响应
        return isSendSuccess;
    }
}
```

讲下上面定义的方法的使用逻辑。

1. 通知方(NotifyParty) 调用 通知管理器(NotifyManager) 发送通知(调用 sendNotify 方法)
2. 通知管理器(NotifyManager) 调用 通知总线(NotifyBus) 发送通知(调用 dispatchNotify 方法)
3. 通知总线(NotifyBus) 发送通知到 被通知方(NotifiedParty)，被通知方(NotifiedParty) 收到通知(调用 onReceivedNotify 方法)
4. 被通知方(NotifiedParty) 处理通知
5. 被通知方(NotifiedParty) 在处理了通知后，调用 通知管理器(NotifyManager) 发送通知响应(调用 sendResponse 方法)
6. 通知管理器(NotifyManager) 调用 通知总线(NotifyBus) 发送通知响应(调用 dispatchResponse 方法)
7. 通知总线(NotifyBus) 发送通知响应到 通知方(NotifyParty)，通知方(NotifyParty) 收到通知响应(调用 onReceivedResponse 方法)
8. 通知方(NotifyParty) 处理通知响应

![通信总线使用流程](/imgs/通信总线使用流程.png)

#### 2. 具体实现

按照上面的定义，我们实现一下通信过程，此处省略了抽象层，简化了逻辑，实际开发中，应该把抽象层加入，并且后期切换类库太过于麻烦(举个切身例子：深刻教训，前期为封装图片框架，直接使用 Fresco，导致后来项目无法切换 glide)。

具体的逻辑就不讲了，很简单。要点如下：

- 通知和通知响应，可以携带三个字段：群组，类型，数据块。定义群组是因为不同模块里的类别，可能有重复，在实际开发中，群组即模块。数据块字段可以使用泛型定义。
- 通知方和接收方在发送和接收通知前，应该将自己支持接收的通知类型注册到通知管理器中，不用时就解注册(通常是在 Activity 的 onCreate 和 onDestroy 中)。通知管理器不具体维护通知类型的映射表，这个工作交给通信总线。通信总线负责维护映射表，并执行具体的通知工作。

### 6. 组件初始化

快速过完了 组件通信 的要点，下面讲解一下组件的初始化。组件初始化需要着重考虑几个方面：线程的同步问题、组件的依赖问题。组件依赖问题又可以涉及到一个概念：组件的生命周期。

组件的依赖是非常重要的一个环节，部分组件之间可能存在逻辑上的依赖关系。举个例子，Login 模块和 Chat 模块虽然彼此间代码解耦，但是仍然需要登录成功了，才能开始聊天，这就产生了一个逻辑上的依赖关系。所以，不是所有组件都必须同时初始化，组件之间的初始化顺序可能存在先后关系。

APP 在启动时，通常会做一些比较耗时的操作，比如网络请求、文件 IO、数据库读写。这些操作不能放在主线程中，只能放在异步线程里操作。此时就涉及到一个线程同步的问题了。主线程的操作如何保证在异步线程之后呢？这里有几种办法：

- 延迟初始化：顾名思义，不重要的任务延后加载，这么做不仅可以保证时序，也可以缩短开机时间、减少开机时的工作量
- 显示开屏页：打开 APK 时，如果想要主线程执行在异步线程之后，那么可以在异步任务开始时，播放动画，或者广告。但是这么做，可能会导致 APK 打开时间增加
- 线程优先级：当自定义线程池时，可以给线程设置优先级，这也能一定程度上解决线程的时序问题

组件是多种多样的，而组件间依赖关系也不可能是线性的。举个例子：假如组件 A 依赖于组件 B，组件 B 依赖于组件 C，在可表示成 A ---> B ---> C，假设组件 E 依赖于组件 B，则可表示成 E ---> B。

解决组件的依赖关系，有两种办法：一是使用 Gradle，二是使用 Java 代码。Gradle 是编译期解决，Java 代码是运行期解决。
如果使用 Gradle，可以使用下面的步骤：

- 各模块在 Gradle 文件中声明依赖的模块
- 在 settings.gradle 文件中读取各模块声明的依赖(settings.gradle 先于 build.gradle 执行)，生成一个根据模块区分的依赖映射表
- 各模块在 build.gradle 中读取 settings.gradle 存储的模块的依赖
- 各模块将读取的依赖信息通过 buildConfigField 写入 BuildConfig 文件中
- APK 在启动时，读取存储在 BuildConfig 文件中的依赖信息

如果使用的 Java，则可以使用下面的方式：

定义依赖解析器，加入 A ---> B ---> C，E ---> B，那么我们可以以 B 作为 key，然后以 A、E 作为 value，B 执行了，就去读取 A 执行，A 执行完后，又去读取依赖于 A 的组件继续执行，直到最终没有组件(一个深度遍历的过程)，才返回 B 的那一层，调用 E 执行，重复深度遍历的过程，直到所有的组件都初始化 OK。

- 定义组件接口，代表组件
- 定义根组件，所有组件默认都依赖于它
- 定义组件父类，所有组件都必须继承自它，并且调用方法添加上 根组件 的依赖
- 定义组件管理器，注册所有组件(否则我们并不清楚项目中有哪些组件)
- 编译组件，解析依赖。依赖管理器解析出来的依赖项，以被依赖的组件(A)作为 key，以依赖于 A 的组件为 value
- 使用依赖管理器解析出来的依赖项进行初始化，一个深度遍历的过程
- 深度遍历初始化过程中，可以考虑线程同步的问题
- 深度遍历的过程中，可能存在组件重复初始化的问题。那么可以加入组件的生命周期进行管理。比如设置 注册、解注册、配置、执行、初始化完毕 等步骤。未执行的步骤才执行，执行过的就不执行了

下面的内容讲解了组件初始化的思想以及生命周期的概念，线程同步没讲。主要是线程的同步问题会占很大篇幅，建议找专门的文章了解。

**定义组件能力**

```java
// 该接口表示组件的执行流程
public interface IModuleTask {
    // 第 1 步：建立组件依赖
    void dependency();
    // 第 2 步：配置组件
    void configure();
    // 第 3 步：组件执行
    void execute();
}
```

**定义根组件**

```java
// 所有组件默认依赖于根组件
public class RootModule extends Module {
    @Override
    public void dependency() { }
    @Override
    public void configure() { }
    @Override
    public void execute() { }
}
```

**定义组件父类**

```java
// 所有组件的父类
public abstract class Module implements IModuleTask {
    // 当前的生命周期状态
    private ModuleLifecycle lifecycle;

    @Override
    public void dependency() {
        dependOn(RootModule.class);
    }

    public void dependOn(Class<? extends Module> clsParent) {
        ModuleManager.dependOn(clsParent, getClass());
    }

    public ModuleLifecycle getLifecycle() {
        return lifecycle;
    }
    public Module setLifecycle(ModuleLifecycle lifecycle) {
        this.lifecycle = lifecycle;
        return this;
    }
}
```

**定义生命周期枚举**

```java
// 组件的生命周期
public enum ModuleLifecycle {
    // 组件已注册
    REGISTERED,
    // 组件已配置
    CONFIGURED,
    // 组件已执行
    EXECUTED
}
```

**定义组件**

组件依赖：A ---> B ---> C，D ---> B

```java
// A 组件依赖于 B 组件和 Root 组件
public class AModule extends Module {
    @Override
    public void dependency() {
        super.dependency();
        dependOn(BModule.class);
    }
    @Override
    public void configure() { }
    @Override
    public void execute() { }
}
```

```java
// B 组件依赖于 C 组件和 Root 组件
public class BModule extends Module {
    @Override
    public void dependency() {
        super.dependency();
        dependOn(CModule.class);
    }
    @Override
    public void configure() { }
    @Override
    public void execute() { }
}
```

```java
// C 组件依赖于 Root 组件
public class CModule extends Module {
    @Override
    public void dependency() {
        super.dependency();
    }
    @Override
    public void configure() { }
    @Override
    public void execute() { }
}
```

```java
// D 组件依赖于 B 组件和 Root 组件
public class DModule extends Module {
    @Override
    public void dependency() {
        super.dependency();
        dependOn(BModule.class);
    }
    @Override
    public void configure() { }
    @Override
    public void execute() { }
}
```

**定义组件管理器**

定义组件管理器，并负责初始化。核心方法是 init 方法，init 方法中定义组件初始化的所有流程

```java
// 组件管理器
public class ModuleManager {
    // key 是被依赖的组件(A)，value 是依赖于 A 的组件
    private static LinkedHashMap<Class<? extends Module>, Dependency> dependencies = new LinkedHashMap<>();
    // 当前已注册的组件的实例缓存
    private static LinkedHashMap<Class<? extends Module>, Module> modules = new LinkedHashMap<>();
    // 组件初始化
    public static void init() {
        // 1. 注册组件
        registerModules();
        // 2. 构建 Root 组件节点
        Dependency rootDependency = new Dependency();
        rootDependency.father = RootModule.class;
        rootDependency.children = new LinkedHashSet<>();
        dependencies.put(rootDependency.father, rootDependency);
        // 3. 遍历组件，生成依赖关系
        for(Module module: modules.values()) {
            module.dependency();
        }
        // 4. 深度遍历，配置组件
        deepTraverse(rootDependency, new Task() {
            @Override
            public void doTask(Module module) {
                // 已配置过了
                if(module.getLifecycle() == ModuleLifecycle.CONFIGURED) {
                    return;
                }
                // 配置组件，并更新组件的生命周期状态
                module.configure();
                module.setLifecycle(ModuleLifecycle.CONFIGURED);
            }
        });
        // 4. 深度遍历，组件执行
        deepTraverse(rootDependency, new Task() {
            @Override
            public void doTask(Module module) {
                // 已执行过了
                if(module.getLifecycle() == ModuleLifecycle.EXECUTED) {
                    return;
                }
                // 组件执行，并更新组件的生命周期状态
                module.execute();
                module.setLifecycle(ModuleLifecycle.EXECUTED);
            }
        });
    }
    // 注册组件
    private static void registerModules() {
        registerModule(AModule.class);
        registerModule(BModule.class);
        registerModule(CModule.class);
        registerModule(DModule.class);
        registerModule(RootModule.class);
    }
    // 注册单个组件
    private static void registerModule(Class<? extends Module> cls) {
        Module component = modules.get(cls);
        if (component != null) {
            return;
        }
        try {
            Module module = cls.newInstance();
            module.setLifecycle(ModuleLifecycle.REGISTERED);
            modules.put(cls, module);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    // 添加依赖关系
    static void dependOn(Class<? extends Module> clsFather, Class<? extends Module> clsChild) {
        Dependency existDependency = findDependency(clsFather);
        if (existDependency != null) {
            existDependency.children.add(clsChild);
            return;
        }

        existDependency = new Dependency();
        existDependency.father = clsFather;
        existDependency.children = new LinkedHashSet<>();
        existDependency.children.add(clsChild);
        dependencies.put(existDependency.father, existDependency);
    }

    private static Dependency findDependency(Class<?> clsFather) {
        if (clsFather == null) {
            return null;
        }
        return dependencies.get(clsFather);
    }

    private static void deepTraverse(Dependency root, Task task) {
        if (root == null) {
            return;
        }
        // 执行被依赖项 A
        Module module = modules.get(root.father);
        task.doTask(module);
        // 执行依赖于 A 的组件
        for (Class<? extends Module> child : root.children) {
            Dependency dependency = findDependency(child);
            // 无依赖项，说明深度遍历到底了
            if (dependency == null) {
                // 调用 子组件的方法
                module = modules.get(child);
                task.doTask(module);
            } else {
                // 有依赖项，继续递归的去深度遍历
                deepTraverse(dependency, task);
            }
        }
    }

    // 依赖关系封装类
    private static class Dependency {
        // 被依赖的组件
        Class<? extends Module> father;
        // 依赖于 father 组件的组件列表
        LinkedHashSet<Class<? extends Module>> children;
    }
    // 初始化过程中需要执行的任务
    private interface Task {
        void doTask(Module module);
    }
}
```

该初始化流程肯定有改进空间，比如组件依赖虑重。当然，这属于优化项，不属于必须项，所以这里就删去了

### 7. 组件混淆

混淆是组件化过程中必须注意的问题。一般的混淆模版代码如下：

```java
defaultConfig {
    consumerProguardFiles 'consumer-rules.pro'
}

buildTypes {
    release {
        minifyEnabled false
        // 存在多个混淆文件
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

consumerProguardFiles 和 proguardFiles 命令的区别：

- consumerProguardFiles 配置的 proguard 会被打进 aar 包中，而 proguardFiles 配置的 proguard 不会被打进 aar 中
- proguardFiles 配置的 proguard 文件只作用于库文件代码，只在编译发布 aar 的时候有效，将库文件作为一个模块添加到 App 模块中后，库文件中 consumerProguardFiles 配置的 proguard 文件会追加到 app 模块的 Proguard 配置文件中，作用于整个 app 代码。即 proguardFiles 的作用范围为组件内，而 consumerProguardFiles 的作用范围为整个 App

明白了上面的区别后，我们就可以对混淆文件进行解耦了。我们**可以通过 consumerProguardFiles 命令在各个组件模块中配置各个模块自己的混淆规则，因为这种方式配置的混淆规则最终都会追加到 app 模块的混淆规则中，并最终统一混淆**。比如存在 A、B、APP 三个组件，那么配置过程如下：

A 组件的混淆配置较简单，直接在 defaultConfig 使用 consumerProguardFiles 配置项配置了一个混淆文件，defaultConfig 中的设置项默认会应用到所有的构建变体中

```java
// A 组件的混淆配置
android {
    defaultConfig {
        // A 组件的混淆配置是 proguard-rules.pro
        consumerProguardFiles 'proguard-rules.pro'
    }
}
```

B 组件额外加入了一个二方库混淆文件

```java
// B 组件的混淆配置
android {
    defaultConfig {
        consumerProguardFiles 'proguard-rules.pro', proguard-second.pro
    }
}
```

app 组件的默认混淆文件是 proguard-android-optimize.txt，该文件路径是 {$ANDROID_SDK_PATH}/tools/proguard/proguard-android-optimize.txt。getDefaultProguardFile 表示用于获取 SDK 目录下的混淆配置文件。值得一提的是，Android Gradle Plugin 2.2及其之后的版本(2.2+)，都不推荐使用 proguard-android.txt/proguard-android-optimize.txt，因为这两个文件不再维护了。

另外 app 组件也会配置工程中系统组件、二方库、三方库的混淆配置。

```java
// app 组件的混淆配置
android {
    defaultConfig {
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-system.pro', 'proguard-second.pro', 'proguard-third.pro'
    }
}
```

proguard-system.pro 这个文件需要单独说明下，因为 proguard-android.txt/proguard-android-optimize.txt 这两个文件不再维护了，所以部分系统组件的混淆配置，需要我们单独加下。具体可见：[通用混淆配置](https://gitee.com/wellcherish/LearningMaterials/blob/master/code/proguard-rules.pro)。混淆配置选项说明，可以看这篇文章：[混淆配置参数](https://www.cnblogs.com/albert1017/p/8383923.html)

Android 组件化的相关知识点和注意事项，就先讲这么多吧