---
title: "Kotlin协程知识点说明"
description: "本文主要讲解与 Android 中 Kotlin 协程的知识点"
keywords: "Kotlin,协程,Android"

date: 2023-12-10 12:32:00 +08:00
lastmod: 2023-12-10 12:32:00 +08:00

categories:
  - Kotlin
  - 协程
tags:
  - Kotlin
  - 协程
  - Android

url: post/DA20ADE8EAA44D75AA24538015EF8B6F.html
toc: true
---

本文主要讲解与 Android 中 Kotlin 协程的知识点。

<!--More-->

## 挂起点和续体

在理解 Kotlin 协程的相关知识点前，我们需要先明确一些概念：在 Android 中，Kotlin 的协程框架其实是基于 java 线程和线程池的二次封装。传统的 java 异步写法是基于回调的，随着业务代码的膨胀，回调会越来越多，层级会越来越深，最终导致 "回调地狱"。为了解决这个问题，Kotlin 协程对 java 线程和线程池做了二次封装，结合上 Kotlin 编译器的处理，最终实现了不用回调就能写出正确的异步代码，这种机制就是协程的挂起与恢复。

协程的挂起与恢复依赖于 挂起点 和 续体，挂起点用 suspend 关键字标识，告诉编译器这段代码会异步执行，而续体则是协程恢复之后要执行的剩余代码，用 Continuation 类标识。Continuation 类的定义如下：

```kotlin
public interface Continuation<in T> {
    public val context: CoroutineContext
    public fun resumeWith(result: Result<T>)
}
```

Continuation 类的定义非常简单，仅包含 context 变量和 resumeWith 方法。通俗的讲，Continuation 就是一个异步执行后的回调。resumeWith 就是其回调时调用的方法。

传统的 java 异步代码，我们会在完成异步操作后，将结果通过回调返回：

```java
Callback callback = new Callback() {
    @Override
    public void onSuccess(data: Data) {
        // 异步执行结束后，打印结果
        System.out.println("sucess: data is " + data);
    }
};

public void doAsync(callback: Callback) {
    new Thread() {
        // 执行异步代码
        callback.onSuccess(data);
    }.run();
}
```

采用协程的写法如下，doAsync 这个 suspend 方法被调用时，就是挂起点被挂起了，后续的打印操作，就是续体：

```kotlin
GlobalScope.launch {
    val data = doAsync()
    println("sucess: data is $data")
}

suspend fun doAsync(): Data {
    // 执行异步代码
    val data = doSomething()
    return data
}
```

类比到协程里的 Continuation 类，我们就可以做这样的转换：

```java
Continuation continuation = new Continuation() {
    @Override
    public void resumeWith(data: Data) {
        // 异步执行结束后，打印结果
        System.out.println("sucess: data is " + data);
    }
};

public void doAsync(callback: Callback) {
    new Thread() {
        // 执行异步代码
        continuation.resumeWith(data);
    }.run();
}
```

从上可以看出，我们可以简单的将 Continuation 视作一个异步回调。

## 协程作业

Job 表示协程作业，其代表着协程，是协程的句柄。使用 launch 或者 async 方法创建的每个协程都会返回一个 Job 对象，该 Job 实例是协程的唯一标识并管理其运行状态。

## 协程作用域

CoroutineScope 是协程生效的范围，可以理解成协程的作用域和生命周期，其描述了协程可用的时机。开启 Kotlin 协程需要在 CoroutineScope 上调用 launch 或者 async 方法。

