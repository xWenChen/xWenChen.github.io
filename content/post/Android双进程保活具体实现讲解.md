---
title: "Android双进程保活具体实现讲解"
description: "本文讲解了如何在 Android 中实现双进程保活"
keywords: "Android,进程保活,双进程保活"

date: 2023-11-04 16:04:00 +08:00
lastmod: 2023-11-04 16:04:00 +08:00
draft: true

categories:
  - Android
  - 进程保活
tags:
  - Android
  - 进程保活
  - 双进程保活

url: post/995D3969833D4431BF041D8C71553BCA.html
toc: true
---

本文讲解了如何在 Android 中实现双进程保活。

<!--More-->

原文链接：https://weishu.me/2020/01/16/a-keep-alive-method-on-android/

随着 Android 系统变得越来越完善，单单通过自己拉活自己逐渐变得不可能了；因此后面的所谓「保活」基本上是两条路：

1. 提升自己进程的优先级，让系统不要轻易弄死自己；
2. App 之间互相结盟，一个兄弟死了其他兄弟把它拉起来。

当然，还有一种终极方法，那就是跟各大系统厂商建立 PY 关系，把自己加入系统内存清理的白名单；比如说国民应用微信。当然这条路一般人是没有资格走的。

大神 gityuan 在其博客上公布了 TIM 使用的一种可以称之为「终极永生术」的保活方法；这种方法在当前 Android 内核的实现上可以大大提升进程的存活率。Github 参考实现 [Leoric](https://github.com/tiann/Leoric)。接下来就给大家分享一下这个终极保活黑科技的实现原理。

## 保活的底层技术原理

知己知彼，百战不殆。既然我们想要保活，那么首先得知道我们是怎么死的。一般来说，系统杀进程有两种方法，这两个方法都通过 ActivityManagerService 提供：

- killBackgroundProcesses
- forceStopPackage

在原生系统上，很多时候杀进程是通过第一种方式，除非用户主动在 App 的设置界面点击「强制停止」。国内各厂商以及一加三星等 ROM 现在一般使用第二种方法。第一种方法太过温柔，根本治不住想要搞事情的应用。第二种方法就比较强力了，一般来说被 force-stop 之后，App 就只能乖乖等死了。

因此，要实现保活，我们就得知道 force-stop 到底是如何运作的。既然如此，我们就跟踪一下系统的 forceStopPackage 这个方法的执行流程：

1. 首先是 ActivityManagerService里面的 forceStopPackage 这方法：

    ```java
    public void forceStopPackage(final String packageName, int userId) {

        // .. 权限检查，省略

        long callingId = Binder.clearCallingIdentity();
        try {
            IPackageManager pm = AppGlobals.getPackageManager();
            synchronized(this) {
                int[] users = userId == UserHandle.USER_ALL
                        ? mUserController.getUsers() : new int[] { userId };
                for (int user : users) {

                    // 状态判断，省略..

                    int pkgUid = -1;
                    try {
                        pkgUid = pm.getPackageUid(packageName, MATCH_DEBUG_TRIAGED_MISSING,
                                user);
                    } catch (RemoteException e) {
                    }
                    if (pkgUid == -1) {
                        Slog.w(TAG, "Invalid packageName: " + packageName);
                        continue;
                    }
                    try {
                        pm.setPackageStoppedState(packageName, true, user);
                    } catch (RemoteException e) {
                    } catch (IllegalArgumentException e) {
                        Slog.w(TAG, "Failed trying to unstop package "
                                + packageName + ": " + e);
                    }
                    if (mUserController.isUserRunning(user, 0)) {
                        // 根据 UID 和包名杀进程
                        forceStopPackageLocked(packageName, pkgUid, "from pid " + callingPid);
                        finishForceStopPackageLocked(packageName, pkgUid);
                    }
                }
            }
        } finally {
            Binder.restoreCallingIdentity(callingId);
        }
    }
    ```

    在这里我们可以知道，系统是通过 uid 为单位 force-stop 进程的，因此不论你是 native 进程还是 Java 进程，force-stop 都会将你统统杀死。

2. 继续跟踪forceStopPackageLocked 这个方法：

    ```java
    final boolean forceStopPackageLocked(String packageName, int appId,
            boolean callerWillRestart, boolean purgeCache, boolean doit,
            boolean evenPersistent, boolean uninstalling, int userId, String reason) {
        int i;

        // .. 状态判断，省略

        boolean didSomething = mProcessList.killPackageProcessesLocked(packageName, appId, userId,
                ProcessList.INVALID_ADJ, callerWillRestart, true /* allowRestart */, doit,
                evenPersistent, true /* setRemoved */,
                packageName == null ? ("stop user " + userId) : ("stop " + packageName));

        didSomething |=
                mAtmInternal.onForceStopPackage(packageName, doit, evenPersistent, userId);

        // 清理 service
        // 清理 broadcastreceiver
        // 清理 providers
        // 清理其他

        return didSomething;
    }
    ```

    这个方法实现很清晰：先杀死这个 App 内部的所有进程，然后清理残留在 system_server 内的四大组件信息

我们关心进程是如何被杀死的，因此继续跟踪 killPackageProcessesLocked，这个方法最终会调用到 ProcessList 内部的 removeProcessLocked 方法;removeProcessLocked 会调用 ProcessRecord 的 kill 方法。

3. 我们看看这个kill：

```java

```