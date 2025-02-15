---
title: "Android获取系统支持的字体"
description: "本文记录了在 Android 中如何获取系统支持的字体"
keywords: "Android,字体获取"

date: 2023-11-15T17:40:00+08:00

categories:
  - Android
tags:
  - Android

url: post/CC33812BBE634DE3935869FDAD312B94.html
toc: true
---

本文记录了在 Android 中如何获取系统支持的字体。

<!--More-->

问：在 Android 如何获取系统支持哪些字体?

答：在Android中，可以通过AssetManager类来获取系统支持的字体。

系统字体文件通常位于/system/fonts目录下。以下是一个示例，演示了如何获取系统支持的字体：

```java
import android.content.res.AssetManager;
import android.os.Environment;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class FontUtils {

    public static List<String> getSystemFonts() {
        List<String> fontList = new ArrayList<>();
        File fontDir = new File("/system/fonts");
        if (fontDir.exists() && fontDir.isDirectory()) {
            File[] fontFiles = fontDir.listFiles();
            if (fontFiles != null) {
                for (File fontFile : fontFiles) {
                    if (fontFile.isFile() && fontFile.getName().endsWith(".ttf")) {
                        fontList.add(fontFile.getName());
                    }
                }
            }
        }
        return fontList;
    }
}
```

上述示例创建了一个 FontUtils 类，其中包含一个名为 getSystemFonts 的静态方法。这个方法首先检查 /system/fonts 目录是否存在，然后遍历该目录下的所有文件。如果找到一个以 .ttf 结尾的文件，就将其添加到 fontList 列表中。最后，返回包含所有系统字体文件名的列表。

请注意，这个方法只能在Android设备上运行，因为它依赖于设备的文件系统。在模拟器上运行可能会导致问题。另外，这个方法可能需要读取外部存储的权限，所以请确保在AndroidManifest.xml中添加了相应的权限：

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```