---
title: "Android使用camera2+MediaCodec录像"
description: "本文讲解了在 Android 中如何使用 camera2 和 MediaCodec 录像，并保存为 mp4 文件。"
keywords: "Android,音视频开发,camera2,MediaCodec,录像"

date: 2024-12-28 13:17:00 +08:00
lastmod: 2024-12-28 13:17:00 +08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - camera2
  - MediaCodec
  - 录像

url: post/C029709AFDCE4F1486B7BE2E3C0C2F5E.html
toc: true
---

本文讲解了在 Android 中如何使用 camera2 和 MediaCodec 录像，并保存为 mp4 文件。

<!--More-->

**注：关于 Camera2 的基本使用流程，可以参考文章: [Android 使用 camera2 拍照](87B1186D69954900869DE7F54B269091.html)。本文只讲解关于视频录像和保存的部分。**

## 录像基础

在 Android 中实现录像并保存为 mp4 文件，需要客户端几个方面的问题。



