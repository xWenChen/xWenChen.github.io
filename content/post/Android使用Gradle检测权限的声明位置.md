---
title: "Android使用Gradle检测权限的声明位置"
description: "本文主要讲解在 Android 中如何使用 Gradle 检测出某个权限是在哪个清单文件中声明的"
keywords: "Android,Gradle,应用合规"

date: 2023-12-28 15:51:00 +08:00
lastmod: 2023-12-28 15:51:00 +08:00

categories:
  - Android
  - Gradle
tags:
  - Android
  - Gradle
  - 应用合规

url: post/1CE9AE367EB44C418F5DF677E9521551.html
toc: true
---

本文主要讲解在 Android 中如何使用 Gradle 检测出某个权限是在哪个清单文件中声明的。

<!--More-->

在 Android 的合规整改过程中，权限的规范处理是个很重要的点。如果有某个其他 SDK 声明了某个动态权限，但是没有使用。此时其仍然会在系统的应用信息中被列举出来。如果被官方看到了，也会收到通报。

要想检测出权限声明的位置，我们需要知道以下知识点：

1. 每个动态权限在申请前，都必须在 AndroidManifest.xml 声明出来
2. 第三方 SDK 的 aar 中可以包含单独的 AndroidManifest.xml 清单文件
3. 在编译生成 APK 的过程，本项目的 AndroidManifest.xml 和 第三方 SDK 的 AndroidManifest.xml 会合并生成最终的 AndroidManifest.xml 清单文件。其位置在 appProjectDir/build/intermediates/merged_manifest/app_variant/AndroidManifest.xml

要确定项目 AndroidManifest.xml 中是否声明了对应权限，我们可以使用以下方式：

1. 打开已合并的最终 AndroidManifest.xml 文件，搜索其中是否包含了对应权限的声明(比如读取短信的权限 "android.permission.READ_SMS")
2. 如果发现确实存在对应权限的声明，则此时我们可以使用以下 Gradle 代码检测出是哪个 SDK 声明了这个权限。此处以短信的读写权限为例：

```groovy
task scanTest {
    // gradle 下载文件后的缓存位置，针对所有项目
    def directoryToSearch = "C:\\Users\\abcdefg\\.gradle\\caches\\modules-2\\files-2.1"
    // 要检查的字符串 "android.permission.READ_SMS"
    def searchString = "android.permission.SEND_SMS"

    // 创建一个文件树，包含指定目录中所有具有 .aar 后缀名的文件
    def aarFiles = fileTree(dir: directoryToSearch, include: '**/*.aar')

    // 遍历并打印找到的 AAR 文件
    aarFiles.each { aarFile ->
        // 解压 AAR 文件并读取 AndroidManifest.xml
        def manifestContent = zipTree(aarFile.absolutePath).matching { include 'AndroidManifest.xml' }.singleFile.text

        // 检查 AndroidManifest.xml 中是否包含特定字符串
        if (manifestContent.contains(searchString)) {
            println "hahatest >>> Found string '${searchString}' in AndroidManifest.xml of AAR: ${aarFile.name}"
        } else {
            println "hahatest >>> String '${searchString}' not found in AndroidManifest.xml of AAR: ${aarFile.name}"
        }
    }
}
```

