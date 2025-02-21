---
title: "使用 Windows 编译 ffmpeg Android so"
description: "本文讲述了如何使用 Windows 编译 ffmpeg Android so"
keywords: "Android,ffmpeg,音视频开发"

date: 2021-02-27T16:21:00+08:00

categories:
  - Android
  - 音视频开发
tags:
  - Android
  - 音视频开发
  - ffmpeg

url: post/C2D99ED8A4BF4BD9ACB1B04C82336FA7.html
toc: true
---

本文讲述了如何使用 Windows 编译 ffmpeg Android so。

<!--More-->

## 聊聊

这边文章主要是个记录，用于记录本人在 Windows 中编译 ffmpeg 的 Android so 的过程中踩到的坑以及详细过程，方便后续回味。能搜到这里来的同学，想必都知道 ffmpeg 是啥了。我就不多介绍了。不懂的可以百度。

开干。

## 为啥不用 Windows 直接编译 so

**Windows 直接编译 so 是个大坑，尽量别用 Windows 直接编译 ffmpeg。请记住这句话。**下面来讲几点原因：

1. Windows 原生编译 so 的文章相比于 Linux 编译来说，着实不算多。本人也在百度上查阅了各种资料。都没能找到一篇让人满意的参考文章(可能是个人能力有限吧)。
2. ffmpeg 是在 Linux 上用纯 C 编写的，证据之一就是 ffmpeg 源码中的 configure 文件，这是 Linux 小开发们常用的编译配置方式。这就导致了在 Windows 上编译 ffmpeg，注定会碰一鼻子灰。尤其是 4.X 以上。比如我遇到的无法解决的一个问题：ffmpeg 4.X.X 以上的软链接问题，其会导致的一个错误如下：
```
ln: failed to create symbolic link 'libavutil.so': No such file or directory
make: *** [ffbuild/library.mak:102: libavutil/libavutil.so] Error 1


clang: error: no such file or directory: 'liba'
make: *** [ffbuild/library.mak:103: libavformat/libavformat.so.58] Error 1

LD      libavformat/libavformat.so.58
clang: error: no such file or directory: 'liba'
make: *** [ffbuild/library.mak:103: libavformat/libavformat.so.58] Error 1
```

如果想要用 Windows 原生编译 so，可以看看下面两个东西：

1. 一个大佬：https://blog.csdn.net/luo0xue/article/details/90369426。
2. Windows 中的编译安装过程：
   1. 安装 Linux 的开发环境：cygwin。请不要使用 MinGW，更不要使用 Git Bash，二者缺少了一些 ffmpeg 编译所需要的文件。
   2. 在 Linux 开发环境中安装 NDK
   3. 下载 ffmpeg 源码
   4. 配置编译脚本，进行编译

## Windows10 WSL 编译 Android so

从上面我踩过的坑中，我发现了在 Windows10 中，使用 Windows10 提供的 WSL 来编译是最方便的。因为无论是第一个大佬讲的东西，还是我第二个总结的东西，都绕不开一个问题：**在 Windows 环境下编译 ffmpeg 的 Android so，必须搭建 Linux 的开发环境。**就是基于这一点，我确定了，**在 Windows10 下编译 ffmpeg 的 Android so，使用 Windows10 WSL 是最方便的。**下面来详细讲下在 Windows10 WSL 中，如何编译 Android so

### 开启 WSL

按照以下步骤打开 Windows10 的 WSL。

打开控制面板操作如下：

鼠标右键 ---> 个性化 ---> 主题 ---> 桌面图标设置 ---> 勾中控制面板

![开启WSL步骤1](/imgs/开启WSL步骤1.webp)

![开启WSL步骤2](/imgs/开启WSL步骤2.webp)

![开启WSL步骤3](/imgs/开启WSL步骤3.webp)

![开启WSL步骤4](/imgs/开启WSL步骤4.webp)

至此，控制面板图标便出现在了桌面上：

![控制面板出现在桌面](/imgs/控制面板出现在桌面.webp)

接着就可以打开 WSL 功能了：控制面板 ---> 点击程序和功能 ---> 启用或关闭 Windows 功能 ---> 适用于 Linux 的 Windows 子系统：

![打开WSL功能步骤1](/imgs/打开WSL功能步骤1.webp)

![打开WSL功能步骤2](/imgs/打开WSL功能步骤2.webp)

![打开WSL功能步骤3](/imgs/打开WSL功能步骤3.webp)

然后，就可以去 Microsoft Store 搜索 Ubuntu 了。可以下载 Ubuntu 20.04 LTS 版本：

![下载Ubuntu](/imgs/下载Ubuntu.webp)

安装之后，在开始菜单中点击打开，初始化 OK 之后，就可以做下面的操作了。

### WSL 安装 NDK

创建目录：

```
mkdir -p /home/wenchen/android/ndk
```

进入目录：

```
cd /home/wenchen/android/ndk
```

使用 wget 命令下载 NDK：

```
wget https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
```

下载完成后解压到 ndk-r21e 目录：

```
unzip android-ndk-r21e-linux-x86_64.zip -d ndk-r21e
```

解压好之后配置环境变量：

```
sudo vim /etc/profile
```

按 i 键编辑，在配置文件末尾增加以下内容：

```
#android NDK
export ANDROID_NDK="/home/wenchen/android/ndk/ndk-r21e/android-ndk-r21e"
export PATH="$ANDROID_NDK:$PATH"
```

按 esc 键退出编辑模式，输入 :wq 保存退出。接着更新环境变量：

```
source /etc/profile
```

NDK 就配置好了，接着我们可以看下是否 OK。输入 ndk-build 命令，如果出现以下提示，就 OK 了：

```
wenchen@DESKTOP-RKNC9R1:~$ ndk-build
Android NDK: Could not find application project directory !
Android NDK: Please define the NDK_PROJECT_PATH variable to point to it.
/home/wenchen/android/ndk/ndk-r21e/android-ndk-r21e/build/core/build-local.mk:151: *** Android NDK: Aborting    .  Stop.
```

### 搭建 Git 开发环境

下载的 Ubuntu 已经为我们装好了 Git，我们只需要配置一下就可以了。

输入下面的命令，配置名称：

```
git config --global user.name "xxx"
```

输入下面的命令，配置邮件：

```
git config --global user.email "xxx@yyy.com"
```

#### 生成 ssh key pair 密钥对：

启用 ssh-agent：

```
eval `ssh-agent`
```

输入以下命令，生成 rsa 密钥。一路回车，不要输入任何东西，直到生成 OK：

```
ssh-keygen -t rsa -C "注释内容(可以是邮箱地址)"
```

把私钥添加到 ssh-agent 的高速缓存中：

```
ssh-add ~/.ssh/id_rsa
```

打印 rsa 的公钥信息：

```
cat ~/.ssh/id_rsa.pub
```

公钥信息如下：

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT+zQtc3Hh/zGKtC7Onx1f256g6JMhdXRBTC4uF7MEzd0zzmic71knFxSKln0xWBmwECUzoQ0FI6dvNGOo8qZfnILjm6WpQDU23wSjGHcEw6CANi3TqRKrFpHU/cY7RzwjVtxMeT5RYaBJ3FsifIYY94s47iYBnEMIu5pdDV9sM0J9sg0TUiZhvwi9y51CL+Vu38kQAQQLlbu27MqJJjHSj6nRis71+b8q0HScp8jlXCuQT/34NMoyXC2pNKHvXOsPGgeU+yoT1K+n2zMvhcSn8F22kDMLpe9kdsBCbwZ0rSylh9wZrTZyGJmCwFm4OP5e0fasofM14EMqK2DtKWTXqyjCSHRilUmuiGFG7SHULeU72Rhu1MutozBfuCDYVI1YlanWrX/ifHtkaI1tlhMXXOISgpbSVP3n5AnGhZ6W1tfp+kNeVGbtYRC/DtmVanUS+T3rr2kWVyGEhEetFZNX1n2ZPRA1+YfICbh2rU9EeumhV1P3BPEF+JWGd8IJszBSvBN/eosys/7KCVyAbOGkeTsWdizJoQN7ArKlnyWSGlIVHaLmyupe/otrfVsFbUd7lF4aPYmLJi4YztSGTBlW1scydnaevi3j5mqgFImALJg6X5KAVnSFVHnYVfIpSdgc5KgcG1wLcTz0lg83ieyhSwFBYykAklRCSjicBOwNrQ== xxx@yyy.com
```

#### 将公钥信息添加到 Gitee

打开 Gitee 后，选择设置项：

![将公钥信息添加到Gitee1](/imgs/将公钥信息添加到Gitee1.webp)

选择 SSH公钥 设置项，粘贴刚才打印的公钥信息，并点击确定，公钥就保存成功了。

![将公钥信息添加到Gitee2](/imgs/将公钥信息添加到Gitee2.webp)

### 下载 ffmpeg 源码

进入目录：

```
cd /home/wenchen/android
```

创建源码目录：

```
mkdir src
```


创建 so 目录：

```
mkdir so
```

进入源码目录：

```
cd src
```

下载 ffmpeg 源码：

```
git clone https://gitee.com/mirrors/ffmpeg.git
```

下载 OK 后，进入 ffmpeg 源码目录：

```
cd ffmpeg
```

修改 configure 文件权限：

```
chmod 777 configure
```

在 configure 文件中修改编译脚本设置，新增编译工具拼接选项(ndk 中交叉编译工具名称不同，默认规则拼接后，会出现找不到的情况，解释如图)：

![修改编译脚本设置_新增编译工具拼接选项](/imgs/修改编译脚本设置_新增编译工具拼接选项.webp)

打开 Vim：

```
sudo vim configure
```

输入 /CMDLINE_SET，按下回车键来匹配设置项。找到 cross_prefix，按 i 键编辑，新增一行内容：

```
CMDLINE_SET="
    $PATHS_LIST
    ar
    arch
    as
    assert_level
    build_suffix
    cc
    objcc
    cpu
    cross_prefix
    # 下面一行内容为新增命令行参数，原文件中没有
    cross_prefix_clang
    custom_allocator
    cxx
    dep_cc
    # 省略其他.....
"
```

按 esc 键退出编辑模式，输入 /ar_default="${cross_prefix}${ar_default}"，按下回车键来匹配设置项。按 i 键键入编辑：

```
# 原内容
ar_default="${cross_prefix}${ar_default}"
cc_default="${cross_prefix}${cc_default}"
cxx_default="${cross_prefix}${cxx_default}"
nm_default="${cross_prefix}${nm_default}"
pkg_config_default="${cross_prefix}${pkg_config_default}"
```

将中间两行修改为：

```
# 修改后的内容
ar_default="${cross_prefix}${ar_default}"
#------------------------------------------------
cc_default="${cross_prefix_clang}${cc_default}"
cxx_default="${cross_prefix_clang}${cxx_default}"
#------------------------------------------------
nm_default="${cross_prefix}${nm_default}"
pkg_config_default="${cross_prefix}${pkg_config_default}"
```

按 esc 键退出编辑，输入 :wq 保存退出。

注释：Vim 中，按 n(小写 n) 可以匹配下一个内容，按 shift+n 可以匹配上一个内容。输入 set nohlsearch(简写为：set-noh)来取消文本的高亮。

新增编译脚本文件：

```
touch build_android_clang.sh
```

修改脚本权限：

```
chmod 777 build_android_clang.sh
```

编辑脚本：

```
sudo vim build_android_clang.sh
```

按 i 键编辑，脚本文件内容如下：

```
#!/bin/bash
set -x # 执行指令后，先显示该指令及所下的参数。
# 目标Android版本
API=21
CPU=armv7-a
#so库输出目录
OUTPUT=/home/wenchen/android/so/$CPU
# NDK的路径，根据自己的NDK位置进行设置
NDK=/home/wenchen/android/ndk/ndk-r21e/android-ndk-r21e
# 编译工具链路径
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
# 编译环境
SYSROOT=$TOOLCHAIN/sysroot

function build
{
  ./configure \
  --prefix=$OUTPUT \
  --target-os=android \
  --arch=arm \
  --cpu=$CPU \
  --enable-asm \
  --enable-neon \
  --enable-cross-compile \
  --enable-shared \
  --disable-static \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-symver \
  --disable-ffmpeg \
  --sysroot=$SYSROOT \
  --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
  --cross-prefix-clang=$TOOLCHAIN/bin/armv7a-linux-androideabi$API- \
  --extra-cflags="-fPIC"

  make clean all
  # 这里是定义用几个CPU编译
  make -j8
  make install
}

build
```

按 esc 键退出编辑，输入 :wq 保存退出。

写好编译脚本后，安装 make 命令：

```
sudo apt-get install make
```

执行编译脚本：

```
./build_android_clang.sh
```

关于编译脚本中的一些说明，可以看看**[这篇文章](https://juejin.cn/post/6844904039524597773)**。脚本基本上都参考自它。

一路通畅，再也没有什么报错。在 so 目录下，可以找到 include、lib、share 三个目录，ffmpeg so 就在 lib 目录下，头文件在 include 目录下。

至于编译多种 CPU 架构的 so，其实搜下 shell 编程 for 循环就会了。