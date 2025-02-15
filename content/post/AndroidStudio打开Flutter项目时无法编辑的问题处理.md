---
title: "AndroidStudio打开Flutter项目时无法编辑的问题处理"
description: "本文处理了用 Android Studio 打开 Flutter 项目时, Flutter 的源码无法编辑的问题"
keywords: "Android,Android Studio,Flutter"

date: 2024-01-08T11:02:00+08:00

categories:
  - Flutter
tags:
  - Flutter
  - Android Studio

url: post/FEEBD720C29248C98A8B880D24C54D9B.html
toc: true
---

本文处理了用 Android Studio 打开 Flutter 项目时, Flutter 的源码无法编辑的问题。

<!--More-->

问题的根本在于android studio无法识别当前项目位置。这个时候，需要我们手动去表示项目的位置。操作步骤如下：

1 - 删除.idea,.gradle,.dart_tool三个文件夹

![删除问题文件夹](/imgs/删除问题文件夹.webp)

2 - 重启 android studio(Restart and invalidate cache)，并打开对应项目；右键选择项目根目录，手动识别目录。

![手动识别Flutter项目目录](/imgs/手动识别Flutter项目目录.webp)
