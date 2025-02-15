---
title: "Android 模版设计模式实战"
description: "本文讲解了在 Android 使用模版设计模式优化代码逻辑"
keywords: "Android,模版设计模式"

date: 2020-03-28T18:57:00+08:00

categories:
  - Android
tags:
  - 设计模式
  - Android

url: post/CC2737B5B6714B72A75CA176E16F5561.html
toc: true
---

**本文主要讲解如何在实际项目中使用模版设计模式优化代码结构**

<!--More-->

## 概念

在模板模式（Template Pattern）中，一个抽象类公开定义了执行它的方法的方式/模板。它的子类可以按需要重写方法实现，但调用将以抽象类中定义的方式进行。这种类型的设计模式属于行为型模式。

模版设计模式的本质便是固定算法框架。

上面的概念中有三个要点：

- 父类定义方法模版
- 子类实现方法的某一个部分
- 调用以父类的方式调用

## 优点

- 在开发时，只需要考虑方法的实现。不需要考虑方法在何种情况下被调用。实现代码复用。
- 一次性实现一个算法的不变部分，并将可变的行为留给子类来实现。
- 各子类中公共的行为应被提取出来并集中到一个公共父类中以避免代码重复。
- 需要通过子类来决定父类算法中某个步骤是否执行，实现子类对父类的反向控制。

## 核心思想

代码复用，避免重复

## 使用

下面，让我们来介绍一个例子。假设我们需要设计一个即时聊天工具，这个工具可以显示图片、语音、文本、表情等等类型的消息。并且可以显示消息发送的状态，显示消息的时间，显示成员头像，显示成员名称。显示有哪些人读了你的消息。相信使用过 QQ 或者微信的人对这些一定都不陌生。我们暂且将这些功能称为：消息内容、消息时间、消息回执、消息状态、成员头像、成员名称。以发送端的消息显示为例，其可以长这个样子。

![聊天消息布局](/imgs/模版模式设计实战样例图.png)

根据我们对 QQ 和微信的使用，可以很明显的看出，以下的部分是公有布局：

- 消息时间
- 消息回执
- 消息状态
- 成员头像
- 成员名称
- 公共操作，如点击事件、长按事件等等。

除开上面的公共部分，其实每种消息类型的不同之处便是消息内容部分，对应上图中的主布局区域。

理清了这些思路，我们可以很轻松的根据模版模式构建出一个消息的显示流程。

首先，我们应该确定在哪个类里面进行消息的绑定操作。对于 Android，现在已经开始流行使用 RecyclerView，使用 RecyclerView，我们应该在 ViewHolder 中，进行数据的绑定。通过定义一个基类 ViewHolder，实现公共的逻辑。然后定义子类，实现不同消息类型的消息内容的绑定，便可以定义出一套消息绑定的流程。

下面，我们来一一讲解。首先是流程。

1. 定义公共布局：将上面我们列举到的时间、头像、名字、已读回执、消息状态这些，定义为公共布局。
2. 在基类 ViewHolder 中，定义绑定这些公共方法的逻辑。
3. 在子类 ViewHolder 中，对私有数据进行绑定。

布局就不详讲了。主要是采用 include 标签，将公共的布局包含到对应的消息类型中。我们重点讲解第2、3步。

### 定义基类

基类的定义属于第二步，又可以具体细分为三步。其定义方式如下（注：以下所有的代码，只讲解流程，不会涉及具体的代码）：

```java
public abstract class BaseChatItemHolder extends RecyclerView.ViewHolder {
    // 2.1 定义外部类调用入口，绑定数据
    public void onBindViewHolder(Msg msg, int position) {
        // 绑定消息公共的数据部分
        bindCommonData(msg, position);
        // 绑定消息私有的数据部分
        bindPrivateData(msg, position);
    }

    // 2.2 定义公共的数据绑定流程，流程不可更改
    public void bindCommonData(Msg msg, int position) {
        // 设置消息时间
        setTime(msg);
        // 设置成员头像
        setHead(msg);
        // 设置成员名称
        setName(msg);
        // 设置消息状态
        setState(msg);
        // 设置消息回执
        setMsgReceipt(msg);
        // 设置公共操作
        setCommonOperation(msg);
    }

    // 2.3 定义公共方法，非抽象，需要父类提供实现
    // 设置消息时间
    public void setTime(Msg msg) {
        // 省略具体绑定过程
    }
    // 设置成员头像
    public void setHead(Msg msg) {
        // 省略具体绑定过程
    }
    // 设置成员名称
    public void setName(Msg msg) {
        // 省略具体绑定过程
    }
    // 设置消息状态
    public void setState(Msg msg) {
        // 省略具体绑定过程
    }
    // 设置消息回执
    public void setMsgReceipt(Msg msg) {
        // 省略具体绑定过程
    }
    // 设置公共操作
    public void setCommonOperation(Msg msg) {
        // 省略具体绑定过程
    }

    // 2.4 定义消息私有内容绑定的抽象方法
    public abstract void bindPrivateData(Msg msg, int position);
}
```

在上面的流程设计中，我们定义了公共方法，以表示公共消息布局的绑定过程，公共的方法不必声明为 abstract。子类特有的消息内容区域需要设置为抽象类型的，表示子类必须自己处理消息内容布局的绑定过程，并且消息内容的布局需要自己设计。但必须置于一个公共的父布局下。比如所有消息类型的内容布局，其根布局必须是 ConstraintLayout。

Msg 表示消息，是所有消息类型的父类。如图片消息 PhotoMsg、语音 VoiceMsg 等等这些消息类型都由其衍生出来。其包含了所有消息类型共有的一些属性，比如消息的 id，发送者的 id，接受者的 id，聊天框的 id 等等。当然，具体的内容视业务而定，这里只是举个例子。

### 定义子类

接下来，我讲讲子类如何利用父类定义的流程。这里举两个例子。以图片消息(PhotoMsg)、语音消息(VoiceMsg)为例。图片消息无需什么特殊的操作，而语音消息需要特殊的长按操作。

注：前面提到过，消息内容的布局应该包裹在 ConstraintLayout 中，如下：

```xml
<!-- 消息内容的布局区域，可以统一命名，方便设置公共操作 -->
<androidx.constraintlayout.widget.ConstraintLayout
        android:id="@+id/chat_msg_item_content"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content">

    	<!-- 消息内容的布局 --> 

</androidx.constraintlayout.widget.ConstraintLayout>
```

**图片消息**

根据上面提到的原则，图片消息的布局如下：

```xml
<!-- 消息内容的布局区域，可以统一命名，方便设置公共操作 -->
<androidx.constraintlayout.widget.ConstraintLayout
        android:id="@+id/chat_msg_item_content"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content">
    	<!-- 显示图片的 ImageView，布局参数省略 -->
        <ImageView
            android:id="@+id/iv_photo"
            android:layout_width="40dp"
            android:layout_height="40dp" />
</androidx.constraintlayout.widget.ConstraintLayout>
```

```java
public class PhotoChatItemHolder extends BaseChatItemHolder {

    public PhotoChatItemHolder(ViewGroup parent, @LayoutRes int resId) {
        super(parent, resId);
    }

    @Override
    public void bindPrivateData(Msg msg, int position) {
        // 父类消息转成图片消息，进行私有消息内容数据部分的绑定
        PhotoMsg photoMsg = (PhotoMsg) msg;
        // 省略具体绑定过程
        ...
    }
}
```

图片消息除了私有部分，其他无须特殊处理，便可以复用父类的绑定流程。无需重写父类中的非 abstract 类型的方法，使用父类提供的默认实现即可。

**语音消息**

语音消息的布局如下：

```xml
<!-- 消息内容的布局区域，可以统一命名，方便设置公共操作 -->
<androidx.constraintlayout.widget.ConstraintLayout
        android:id="@+id/chat_msg_item_content"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content">
    	<!-- 显示图片的 ImageView，布局参数省略 -->
        <VoiceView
            android:id="@+id/vv_voice"
            android:layout_width="40dp"
            android:layout_height="40dp" />
</androidx.constraintlayout.widget.ConstraintLayout>
```

上面我们假设了语音需要特殊的长按操作。则可以构建如下代码：

```java
public class VoiceChatItemHolder extends BaseChatItemHolder {

    public VoiceChatItemHolder(ViewGroup parent, @LayoutRes int resId) {
        super(parent, resId);
    }

    @Override
    public void setCommonOperation(Msg msg) {
        // 1. 子类重写绑定过程，代执行到此处，会采用子类的实现，不会调用父类的方法
        ...
        // 2. 如果任性一点，不要长按事件，这里的实现甚至可以返回空。做到差异化。
    }

    @Override
    public void bindPrivateData(Msg msg, int position) {
        // 父类消息转成语音消息，进行私有数据部分的绑定
        VoiceMsg voiceMsg = (VoiceMsg) msg;
        ...
        // 3. 甚至你可以在这里调用公共操作方法，自定义部分加载流程，覆盖上面的长按事件调用。
        setCommonOperation(msg);
        ...
    }
}
```

上面的例子，我们重写了父类中的非抽象公共方法。但是却没有改变绑定流程，便达到了我们想要的效果。并且我们应该将私有部分消息内容的数据绑定放到最后，这样可以给予最大的自由度。另外给了三点说明，写在了注释中。

### 使用

学习 Java 的时候，我们都知道 Java 类有声明类型和实际类型。此处我们要想正确的调用，达到正确效果，便需要返回正确的实际类型。创建 ViewHolder 时，可以这么写。以图片和语音消息为例。

```java
public class ViewHolderManager {
    public BaseChatItemHolder createViewHolder(ViewGroup parent, int msgType) {
        int resId = MsgLayoutManager.getInstance().getLayoutResId(msgType);
        switch(msgType) {
            case MsgType.PHOTO:
                return new PhotoChatItemHolder(parent, resId);
                break;
            case MsgType.VOICE:
                return new VoiceChatItemHolder(parent, resId);
                break;
        }
    }
}
```

上面的实现很简单。但却能达到我们想要的效果。

讲完了构建，下面就讲下调用，很简单，在真正需要绑定布局的地方，比如消息适配器 MsgAdapter 的绑定方法中，调用 ViewHolder 的绑定方法即可。

```java
public class MsgAdapter extends RecyclerView.Adapter<BaseChatItemHolder>{
    List<Msg> msgList;

    @Override
    public BaseChatItemViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        return ViewHolderManager.getInstance().createViewHolder(parent, viewType);
    }

    @Override
    public void onBindViewHolder(BaseChatItemViewHolder holder, int position) {
        Msg msg = getItem(position);
        
        holder.onBindViewHolder(msg, position);
    }

    public Msg getItem(int position) {
        return msgList.get(i);
    }
}
```

上面的调用过程，创建和绑定数据的流程都很简单。

下面来总结一下。

## 总结

1. 模版模式使用的 Java 语言特性，核心有两个。1 是抽象类可以拥有抽象方法和非抽象方法。抽象方法要求子类必须实现，可以用来制定差异化。非抽象方法则可以用来定义流程。2 是 Java 的方法调用实际上，会最终调用到类的实际类型中的方法实现，而不是声明类型中的方法实现。
2. 模版模式是以代码复用为目的。避免一个类出现海量代码。规范了流程，提高了可读性。并且给予了子类极大的自由度。