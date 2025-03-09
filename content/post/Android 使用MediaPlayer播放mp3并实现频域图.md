---
title: "Android 使用MediaPlayer播放mp3并实现频域图.md"
description: "本文讲解了在Android中如何使用MediaPlayer播放mp3，并实现频域图。"
keywords: "Android,音视频开发,camera2,MediaCodec,录像"

date: 2025-03-09T10:01:00+08:00
lastmod: 2025-03-09T10:01:00+08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - MediaPlayer
  - 音频播放

url: post/C0C9F2BB39F44B0484C560763D04F94E.html
toc: true
draft: true
---

示例代码链接：[MediaPlayer播放mp3代码](https://github.com/xWenChen/WellMedia/blob/master/app/src/main/java/com/mustly/wellmedia/audio/AudioPlayFragment.kt)

本文讲解了在Android中如何使用MediaPlayer播放mp3，并实现频域图。

<!--More-->

## 前言

在Android中，要实现音频的播放，通常有两种方式：

- 使用MediaPlayer。MediaPlayer是系统提供的音视频播放控制器，其基于AudioTrack封装。MediaPlayer是比AudioTrack更上层的API。
- 使用AudioTrack。AudioTrack是Android系统提供的基础音频播放接口，我们可以使用AudioTrack自定义或者控制音频的播放。

本文讲解下如何使用MediaPlayer播放mp3音频。不使用AudioTrack的原因是AudioTrack只能播放PCM数据。这就意味着我们需要把mp3转换为PCM数据，传给AudioTrack。而在Android中，进行音视频解码的接口我们通常是使用MediaCodec。但是不凑巧的是，MediaCodec不支持mp3音频的编解码。主要是有以下方面的原因：

- mp3以前有版本问题存在(现在版权已过期，人人都能用)。
- MediaCodec 主要用于硬件加速，而mp3解码通常不需要硬件加速，使用软解即可。
- mp3格式较老。

综上，所以Android系统层面并没有进行这种格式的支持，而是支持了无版权问题，并且性能、指标更加优异的 AAC 格式。

因为要想使用AudioTrack播放mp3音频，我们需要使用自定义的逻辑或者三方库解码mp3数据。而三方库通常使用的是lame或者ffmpeg，这两个都是c库，要想将他们引入到Android中，需要使用jni和交叉编译相关的知识。而这块知识已经超出了本文想要讲解的范畴。所以本文使用的是MediaPlayer播放mp3，MediaPlayer内部使用的是软件解码器来处理mp3，并传给AudioTrack播放。

要达到使用MediaPlayer播放mp3音频的效果，我们需要考虑以下几个问题：

- mp3文件存放在哪里。
- mp3播放时，需要展示哪些动效。
- 如何实现上诉的动效。
- 播放mp3如何实现。

针对上面的问题，我们一一解答。

## mp3文件的存放

我们知道，Android的资源文件在构建过程中会被编译和优化。例如布局文件、菜单文件等XML文件会被编译成二进制格式，以提升加载速度和减少体积。资源编译后会生成R.java文件，为每个资源分配唯一ID，便于在代码中引用。在高版本Android Studio中，我们可以通过R.txt文件查看这些编译结果和资源id。

像mp3这类音视频文件或者自定义的动画文件，是不能被编译的。此时我们就可以使用两种不被编译为二进制的方式进行存放和解析：

1. 放入res/raw目录下，raw目录下面的内容被称为raw资源，可以通过`R.raw.xxx`的方式访问。
2. 放到assests目录中，assests目录下的内容被称为assests资源，可以通过AssestsManager访问。

本文使用的是第一种方式，并通过`android.resource://com.my.test/abc`的形式得到资源的 uri。

```kotlin
val uri = Uri.parse(R.raw.never_be_alone.uriPath())

// 获取资源 id 的 uri 路径表示
fun Int.uriPath(): String = "android.resource://${getAppContext().packageName}/$this"
```

## 待实现的动效

