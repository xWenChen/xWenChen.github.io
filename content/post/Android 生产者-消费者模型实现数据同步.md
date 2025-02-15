---
title: "Android 生产者-消费者模型实现数据同步"
description: "本文讲解了如何在 Android 中实现生产者-消费者之间的数据同步"
keywords: "Android,多线程编程,多线程同步,ByteBuffer,生产者-消费者模型"

date: 2021-05-18T17:58:00+08:00

categories:
  - Android
  - 多线程编程
tags:
  - Android
  - 多线程编程
  - 多线程同步
  - ByteBuffer
  - 生产者-消费者

url: post/832410DAFBFF4F1AA688B1BB5B4BB6A3.html
toc: true
---

本文讲解了如何在 Android 中实现生产者-消费者之间的数据同步。

<!--More-->

## 前提

目前做需求，遇到了这样一个场景：

- 数据需求方一次需要用到 320 个字节的数据，而数据提供方一次只能提供 240 个字节的数据
- 数据提供方、数据需求方处于两个不同的线程

## 流程定义

上面的场景，使用 生产者-消费者 模型可以很容易就解决，我们可以把数据提供方称为生产者，而数据需求方可以称为消费者：

1. 首先定义一个 640 个字节的缓冲区(320 * 2)
2. 消费者等待
3. 生产者唤醒
4. 生产者生产数据
5. 生产者生产了 >= 320 个字节的数据后
6. 生产者等待
7. 消费者唤醒
8. 消费者消费数据，直到数据 < 320 个字节
9. 重复 2-8 步，直到因其他条件的介入而导致的循环结束

## 代码实现

代码的具体实现如下：

定义一个管理器，管理器持有 生产者线程/消费者线程/公共缓冲区 的实例，公共缓冲区用小端序的 ByteBuffer 实现。虽然用阻塞队列实现起来更简单，但是在阻塞队列中存储的都是封装过的对象，当数据量较多时，数据的频繁读取，会造成小对象的频繁创建与回收，进而可以导致内存抖动。所以使用 ByteBuffer 实现，避免了小对象的频繁创建与回收。管理器的功能主要有，控制 生产者-消费者 循环的开始与结束，管理缓存，提供，写缓存和读缓存的接口。

```java
public class Manager {
    private static final String TAG = "Manager";
    // 消费者一次处理需要的数据大小
    public static final int CONSUME_DATA_SIZE = 320;
    // 生产者一次生产的数据大小
    public static final int PRODUCE_DATA_SIZE = 240;

    // 生产者-消费者 循环能否运行的标志
    private boolean canRun;
    // 公共缓冲区
    private ByteBuffer dataCache;
    // 生产者、消费者的实例对象
    private ProducerThread mProducerThread;
    private ConsumerThread mConsumerThread;
    // 单例模式
    private Manager() {
        mProducerThread = new ProducerThread(this, mConsumerThread);
        mConsumerThread = new ConsumerThread(this, mProducerThread);
    }
    private static class SingleInstance {
        private static final Manager INSTANCE = new Manager();
    }
    public static Manager getInstance() {
        return SingleInstance.INSTANCE;
    }
    // 开始 生产者-消费者 循环
    // 开始后，想要结束循环，可以调用 setCanRun，设置为 false 即可
    public void start() {
        resetDataCache();
        try {
            Log.d(TAG, "start");
            mProducerThread.start();
            mConsumerThread.start();
        } catch (Exception e) {
            Log.e(TAG, "", e);
        }
    }

    // 生产者开始运行前，需要刷新数据区
    public Manager resetDataCache() {
        this.dataCache = ByteBuffer.allocate(CONSUME_DATA_SIZE * 2);
        this.dataCache.order(ByteOrder.LITTLE_ENDIAN);
        return this;
    }
    //  生产者-消费者 循环是否可运行的标志与设置接口
    public boolean canRun() {
        return canRun;
    }
    public Manager setCanRun(boolean canRun) {
        this.canRun = canRun;
        return this;
    }

    public ByteBuffer getDataCache() {
        return dataCache;
    }

    // 写缓存
    public Manager putIntoDataCache(byte[] data) {
        if(dataCache == null) {
            return this;
        }
        // 防止数据越界
        int length = Math.min(dataCache.remaining(), data.length);

        Log.d(TAG, "数据写入缓存，data.length: " + data.length
              + ", dataCache.position: " + dataCache.position()
              + ", length: " + length);
        dataCache.put(data, 0, length);

        return this;
    }
    // 读缓存
    public void getFromDataCache(byte[] byteData, int consumeSize) {
        if(dataCache.position() < consumeSize) {
            Log.e(TAG, "无可用缓存数据");
            return;
        }
        dataCache.flip();
        dataCache.get(byteData, 0, byteData.length);
        dataCache.compact();
        Log.d(TAG, "从缓存读数据");
    }
}
```

定义生产者线程，该线程持有消费者线程的实例对象和管理器的弱引用

```java
public class ProducerThread extends Thread {
    private static final String TAG = "ProducerThread";

    private WeakReference<Manager> mReference;
    private WeakReference<ConsumerThread> mConsumer;

    private int consumeSize;

    public ProducerThread(Manager manager, ConsumerThread mConsumer) {
        mReference = new WeakReference<>(manager);
        this.mConsumer = new WeakReference<>(mConsumer);
        consumeSize = Manager.CONSUME_DATA_SIZE;
    }

    @Override
    public void run() {
        super.run();

        int i = 0;
        byte[] byteData;
        while (mReference.get().canRun()) {
            synchronized (mReference.get().getDataCache()) {
                if(mReference.get().getDataCache().position() >= consumeSize) {
                    try {
                        Log.d(TAG, "生产者线程等待");
                        mReference.get().getDataCache().wait();
                    } catch (Exception e) {
                        Log.e(TAG, "", e);
                    }
                }
                while(mReference.get().getDataCache().position() < consumeSize) {
                    if(mReference.get().canRun()) {
                        byteData = produceData(i);
                        i++;
                        mReference.get().putIntoDataCache(byteData);
                    } else {
                        Log.d(TAG, "生产数据期间，停止运行");
                        break;
                    }
                }
                // 防止停止运行后，消费者线程一直等待
                try {
                    Log.d(TAG, "唤醒消费者线程");
                    mReference.get().getDataCache().notify();
                } catch (Exception e) {
                    Log.e(TAG, "", e);
                }
            }
        }
    }

    // 生产数据
    private byte[] produceData(int i) {
        byte[] bytes = new byte[Manager.PRODUCE_DATA_SIZE];
        Arrays.fill(bytes, (byte) i);
        Log.d(TAG, "生产数据");
        return bytes;
    }
}
```

定义消费者线程，该线程持有生产者线程的实例对象和管理器的弱引用

```java
public class ConsumerThread extends Thread {
    private static final String TAG = "ConsumerThread";

    private WeakReference<Manager> mReference;
    private WeakReference<ProducerThread> mProducer;

    private int consumeSize;

    public ConsumerThread(Manager manager, ProducerThread mProducer) {
        mReference = new WeakReference<>(manager);
        this.mProducer = new WeakReference<>(mProducer);
        consumeSize = Manager.CONSUME_DATA_SIZE;
    }

    @Override
    public void run() {
        byte[] byteData = new byte[consumeSize];
        while (mReference.get().canRun()) {
            synchronized (mReference.get().getDataCache()) {
                if(mReference.get().getDataCache().position() < consumeSize) {
                    try {
                        Log.d(TAG, "消费者线程等待，等待生产数据 size = " + consumeSize);
                        mReference.get().getDataCache().wait();
                    } catch (Exception e) {
                        Log.e(TAG, "", e);
                    }
                }
                mReference.get().getFromDataCache(byteData, consumeSize);
                if(mReference.get().canRun()) {
                    dealCacheData(byteData);
                }
                try {
                    // 防止停止运行后，生产者线程一直等待
                    Log.d(TAG, "唤醒生产者线程");
                    mReference.get().getDataCache().notify();
                } catch (Exception e) {
                    Log.e(TAG, "", e);
                }
            }
        }
    }

    // 处理缓存数据
    public void dealCacheData(byte[] bytePcm) {
        Log.d(TAG, "消费数据, data.size = " + bytePcm.length);
    }
}
```

## 代码解释

对于上面代码的解释如下：

1. 生产者-消费者 模型采用 synchronized-notify-wait 方式实现
2. 使用 notify-wait 时，对象/类 必须在 synchronized 块中，即下面的模版代码：

   ```java
   A a = new A();
   synchronized (a) {
       a.notify();
       a.wait();
   }
   ```

3. 使用 synchronized-notify-wait 方式实现 生产者-消费者 模型时，谁是被竞争的资源，谁就应该被放在 synchronized 块内。必须获得 synchronized 指定的锁对象，才能访问 synchronized 块里的内容。在上面的代码中，两个线程共用 1 个公共缓冲区，则公共缓冲区就是被竞争的资源，公共缓冲区的实例对象就是锁对象，就应放在 synchronized 块内
4. 上面代码的运行流程，可以做这么理解：
   1. 调用`Manager.start()`方法后，两个异步线程就开始运行了，两个线程同时去申请公共缓冲区锁对象的使用权。
   2. 假设是生产者先拿到了公共缓冲区锁对象的使用权，那么消费者会因为无法访问 synchronized 块里的内容而陷入等待
   3. 生产者进入 synchronized 块内运行，会判断是否生产了足够多的数据：
      - 如果生产的数据不够，则会生产足够的数据，然后调用用公共缓冲区锁对象的 notify 方法，通知正在等待的消费者继续运行
      - 如果生产的数据够了，则会调用公共缓冲区锁对象的 wait 方法，进入等待状态。调用锁对象的 wait 方法，陷入等待的线程是当前持有公共缓冲区锁对象的线程，生产者调用则是生产者进入等待。
   4. 生产者陷入等待后，会把公共缓冲区锁对象给释放掉。而正在等待锁的消费者线程，在生产者释放了后，就能拿到锁对象了，也就能访问 synchronized 块里的内容了。
   5. 消费者判断缓冲区里的数据够不够，如果够，就会去消费数据。如果数据不够，就会陷入等待，并释放锁。释放锁，生产者就开始执行了，就开始了 2-5 步的重复
5. 经过上面的解释，应该比较清楚流程了，说明下 wait、notify 的作用：**wait 是将当前线程从从运行状态变为阻塞状态，并释放锁，而 notify 则是将等待线程从阻塞状态变为就绪状态。notify 并不会释放锁，必须等待 synchronized 代码块执行完毕，或者调用 wait 方法，notify 通知的线程才能真正开始执行**。
6. **wait 是针对当前线程的，而 notify 是针对其他线程的。当前线程运行完了，notify 通知的线程才能运行。所以 notify 方法的调用位置，很多时候会放在 synchronized 代码块的最后一行(当然不是绝对的)**。

综上，只要真正理解了 synchronized/notify/wait/锁 的含义与作用，就很容易实现 生产者-消费者模型了。

## 额外说明

这里再说明一下 ByteBuffer 的用法，ByteBuffer 底部映射一块内存区域，既然是内存，肯定就有大端存储和小端存储的区别。所以在使用 ByteBuffer 时，最好特别指定下字节序。

ByteBuffer 中有几个位置概念：

- position：当前的下标位置，表示进行下一个读写操作时的起始位置
- limit：结束标记下标，表示进行下一个读写操作时的(最大)结束位置
- capacity：该 ByteBuffer 容量
- mark: 自定义的标记位置

无论如何，这 4 个属性总会满足如下关系：mark <= position <= limit <= capacity

下面对上面代码中用到的几个方法做下说明：

- position()：原本该方法是用来获取 ByteBuffer 的 position 属性的。但是在上面代码的使用中，数据始终是从 0 开始存储的，所以 position() 也用来获取当前缓冲区中已存入的数据大小
- order()：指定 ByteBuffer 中存储数据的字节序
- remaining()：该方法返回的是 ByteBuffer 当前的剩余可用长度(即剩余空间大小)
- put()：通过 put(byte b)/put(byte[] b)/putChar(char val)/putShort(short val)/putInt(int val)/putFloat(float val)/putLong(long val)/putDouble(double val) 方法向 ByteBuffer 添加数据。添加后，position 会向后移动对应的长度，方便下一次添加
- get()：通过 get()/getChar()/getShort()/getInt()/getFloat()/getLong()/getDouble() 方法从 ByteBuffer 读取数据。读取后，position 会向后移动对应的长度，方便下一次读取
- flip()：该方法将 position 复位为 0，同时也将 limit 的位置放置在了 position 之前所在的位置上，这样 position 和 limit 之间即为新读取到的有效数据
- compact()：该方法就是将 position 到 limit 之间还未读取的数据拷贝到 ByteBuffer 中数组的最前面，然后再将 position 移动至这些数据之后的一位，将 limit 移动至 capacity。这样 position 和 limit 之间就是已经读取过的老的数据或初始化的数据，就可以放心大胆地继续写入覆盖了

从代码中可以看出，**ByteBuffer 的基本使用流程为：初始化(allocate) ---> 写入数据(read/put) ---> 转换为读取模式(flip) ---> 读取数据(get) ---> 转换为写入模式(compact) ---> 写入数据(read/put)**

ByteBuffer 的详细用法可以参考: **java.nio.ByteBuffer 用法小结: https://blog.csdn.net/mrliuzhao/article/details/89453082**
