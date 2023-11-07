---
title: "protobuf 通过 Android Bundle 传输"
description: "本文讲解了如何在 Android 中使用 Bundle 传输 protobuf 数据"
keywords: "Android,protobuf,Bundle"

date: 2023-11-07 16:23:00 +08:00
lastmod: 2023-11-07 16:23:00 +08:00

categories:
  - Android
  - protobuf
tags:
  - Android
  - protobuf

url: post/55E27F254C6449609D48DA7A1F348BCE.html
toc: true
---

本文讲解了如何在 Android 中使用 Bundle 传输 protobuf 数据。

<!--More-->

Protocol Buffers（protobuf）是一种轻便高效的结构化数据存储格式，可以用于序列化结构化数据。它可以在 Android Bundle 中传输，但需要先将 protobuf 对象序列化为字节数组(ByteArray)，然后将字节数组放入 Bundle。在接收端，需要从 Bundle 中获取字节数组并反序列化为 protobuf 对象。

以下是一个简单的示例，说明如何在 Android Bundle 中传输 protobuf 对象：

1. 首先，定义一个 protobuf 消息：

```protobuf
syntax = "proto3";
package com.example;

message Person {
  string name = 1;
  int32 age = 2;
}
```

2. 使用 protobuf 编译器生成 Java 类：

```sh
protoc --java_out=./src/main/java/ person.proto
```

3. 在 Activity 中创建一个 Person 对象，并将其序列化为字节数组：

```java
import com.example.Person;

// ...

Person person = Person.newBuilder()
    .setName("John Doe")
    .setAge(30)
    .build();

byte[] personBytes = person.toByteArray();

Bundle bundle = new Bundle();
bundle.putByteArray("person", personBytes);

// 将 Bundle 传递给另一个 Activity 或 Fragment
```

4. 在接收端，从 Bundle 中获取字节数组并反序列化为 Person 对象：

```java
// 在另一个 Activity 或 Fragment 中

Bundle bundle = getIntent().getExtras();
byte[] personBytes = bundle.getByteArray("person");

Person person = Person.parseFrom(personBytes);

// 使用 person 对象
```

这样，就可以在 Android Bundle 中传输 protobuf 对象了。请注意，这个示例仅用于说明目的，实际应用中可能需要处理异常和其他细节。