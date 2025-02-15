---
title: "Java和Kotlin的文件处理知识点"
description: "本文讲解了 Java 和 Kotlin 文件处理的相关知识点"
keywords: "Android,Java,Kotlin,文件处理"

date: 2024-01-18T18:45:00+08:00

categories:
  - Java
  - 文件处理
tags:
  - Android
  - Java
  - Kotlin
  - 文件处理

url: post/CD171957CB14482C86652AE204503C03.html
toc: true
---

本文讲解了 Java 和 Kotlin 文件处理的相关知识点。

<!--More-->

## 路径处理

在 java 的文件处理中，路径的处理有个必须要说明的点。就是相对路径和绝对路径的区别。在 Mac 和 Linux 中，这两者的区别可能不明显。但是在 Windows 电脑上，不注意这个问题，可能会触发比较验证的 Bug。

在 Windows 电脑上，使用绝对路径创建文件没啥好讲的。此处要讲的是 在 Windows 电脑上相对路径的使用。

比如下面这段代码：

```Kotlin
package test

import java.io.File

fun main() {
    val prefix = "..\\flutter"
    val path = "${prefix}/.android/include_flutter.groovy"

    val file = File(path)

    println("file exist = ${file.exists()}")
    println("file is an absolute path = ${file.isAbsolute}")
    println("file  path = ${file.absolutePath}")
}
```

打印结果为：

```
file exist = true
file is an absolute path = false
file  path = D:\Code\KotlinTest\..\flutter\.android\include_flutter.groovy
```

很明显`D:\Code\KotlinTest\..\flutter\.android\include_flutter.groovy`这个路径是有问题的，其中 D:\Code\KotlinTest 是我的 Kotlin 测试项目。

要修正这个问题，我们做如下处理：创建 File 时，做绝对路径转换和路径平整化的处理。

### 绝对路径转换

要将相对路径转为绝对路径，可以使用`File.getAbsoluteFile()`方法。

未做绝对路径转换前：

```Kotlin
fun main() {
    val prefix = "..\\flutter"
    val path = "${prefix}/.android/include_flutter.groovy"

    val file = File(path)

    println("file exist = ${file.exists()}")
    println("file is an absolute path = ${file.isAbsolute}")
    println("file  path = ${file.path}")
}
```

打印结果为：

```
file exist = true
file is an absolute path = false
file  path = ..\flutter\.android\include_flutter.groovy
```

做了绝对路径转换后：

```Kotlin
package test

import java.io.File

fun main() {
    val prefix = "..\\flutter_module"
    val path = "${prefix}/.android/include_flutter.groovy"

    val file = File(path).absoluteFile

    println("file exist = ${file.exists()}")
    println("file is an absolute path = ${file.isAbsolute}")
    println("file  path = ${file.path}")
}
```

打印结果为：

```
file exist = true
file is an absolute path = true
file  path = D:\Code\KotlinTest\..\flutter\.android\include_flutter.groovy
```

### 路径平整化

从上面的代码可以看出，即使将相对路径转为绝对路径，打印出来的路径仍然是有问题的。此时我们还需要平整路径，我们可以使用Kotlin下的`File.normalize()`扩展方法实现该功能。

要打印最终正常的路径，我们可以使用绝对路径转和路径平整化打印：

```Kotlin
package test

import java.io.File

fun main() {
    val prefix = "..\\flutter"
    val path = "${prefix}/.android/include_flutter.groovy"

    val file = File(path).absoluteFile.normalize()

    println("file exist = ${file.exists()}")
    println("file is an absolute path = ${file.isAbsolute}")
    println("file  path = ${file.path}")
}
```

打印结果为：

```
file exist = true
file is an absolute path = true
file  path = D:\Code\flutter\.android\include_flutter.groovy
```

最终我们就得到了`D:\Code\flutter\.android\include_flutter.groovy`这个正确的路径。

### 使用 Path 类处理相对路径

除了使用 File 处理相对路径和绝对路径的转换，我们还可以使用 Path 的相关类来处理，代码如下：

```Kotlin
package test

import java.nio.file.Files
import java.nio.file.Paths

fun main() {
    val prefix = "..\\flutter"
    val mPath = "${prefix}/.android/include_flutter.groovy"

    val path = Paths.get(mPath).toAbsolutePath().normalize()

    println("file exist = ${Files.exists(path)}") // 使用 Files.exists(Path) 方法判断 path 是否存在
    println("file is an absolute path = ${path.isAbsolute}")
    println("file  path = $path")
}
```

打印结果如下：

```
file exist = true
file is an absolute path = true
file  path = D:\Code\flutter\.android\include_flutter.groovy
```

### 获取项目的当前目录

我们可以使用以下代码获取工程代码所在的目录：

```java
String curDir = System.getProperty("user.dir")
```