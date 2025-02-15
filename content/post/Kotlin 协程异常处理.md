---
title: "Kotlin 协程异常处理"
description: "本文讲解了 Kotlin 中协程的异常处理的知识点"
keywords: "Kotlin,协程,异常处理"

date: 2023-12-07T09:42:00+08:00

categories:
  - Kotlin
  - 协程
tags:
  - Kotlin
  - 协程

url: post/21A3E9E3431548FBAA6864E9DB0F1B79.html
toc: true
---

本文讲解了 Kotlin 中协程的异常处理的知识点。

<!--More-->

## try-catch 失效的问题

kotlin 的协程中不要用try-catch直接包裹launch、async。原因有两个：

1. 异常处理位置不合适：launch 和 async 是用于启动协程的函数，它们会立即返回一个 Job 或 Deferred 对象。当在这两个函数外部使用 try-catch 时，实际上只能捕获到启动协程时的异常，而无法捕获到协程内部执行过程中产生的异常。

2. 协程框架内部已经处理了异常：Kotlin 协程库已经在内部处理了异常。对于 launch 启动的协程，如果发生异常，会将异常传递给协程的异常处理器(CoroutineExceptionHandler)。对于 async 启动的协程，异常会被封装在 Deferred 对象中，当调用 await() 函数时，如果有异常，会抛出异常，这时我们可以在调用 await() 的地方使用 try-catch 来捕获异常。

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val job = launch {
        try {
            // 协程内部的代码
        } catch (e: Exception) {
            // 处理异常
        }
    }

    val deferred = async {
        // 协程内部的代码
    }

    try {
        val result = deferred.await()
    } catch (e: Exception) {
        // 处理异常
    }
}
```

## 协程的异常处理机制

当一个协程执行过程中遇到未捕获的异常时，首先会尝试将异常传递给自己的父协程，最终传递给最顶级的父协程。如果父协程不处理(父协程为SupervisorJob或为async启动的协程)，则由自身上下文中的异常处理器(CoroutineExceptionHandler)处理，如果自身上下文没有异常处理器，则会同时交给JVM全局的异常处理器和当前线程的 uncaughtExceptionHandler 处理(调用Thread.setDefaultUncaughtExceptionHandler方法设置)。

对于通过launch方法启动的协程，在执行过程中遇到未捕获异常时会直接抛出。而对于async方法启动的协程，在执行过程中遇到未捕获异常时不会抛出，而是直接进入完成状态。但当调用await方法获取结果时会将异常抛出。

![协程异常处理流程](/imgs/协程异常处理流程.webp)

在 Android 中，JVM 全局的异常处理器只会做记录系统日志、显示错误对话框(以提示应用已停止运行)等工作，不会做特殊处理，该崩还是得崩。而 kotlin 协程并不会为线程设置 uncaughtExceptionHandler，我们需要通过协程提供的 CoroutineExceptionHandler 机制处理异常。我们可以创建一个自定义的 CoroutineExceptionHandler，并在启动协程时将其添加到协程的上下文中。以下是一段示例代码：

```kotlin
import kotlinx.coroutines.*

fun main() = runBlocking {
    val exceptionHandler = CoroutineExceptionHandler { _, exception ->
        println("Caught $exception")
    }

    val job = GlobalScope.launch(exceptionHandler) {
        throw RuntimeException("An error occurred in the coroutine")
    }

    job.join()
}
```

