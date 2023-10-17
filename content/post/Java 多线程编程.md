---
title: "Java 多线程编程"
description: "本文略讲了 Java 的多线程编程"
keywords: "Java,多线程编程"

date: 2020-04-01 21:17:00 +08:00
lastmod: 2020-04-01 21:17:00 +08:00

categories:
  - Java
tags:
  - Java
  - 多线程编程

url: post/F258040C892142DEB352426EF5044760.html
toc: true
---

本文略讲了 Java 的多线程编程

<!--More-->

本篇文章是 Java 多线程开发的部分总结，会讲解线程、线程的同步与互斥、线程池。代码较多，请细细品味。

## 线程

### 什么是线程？

- 进程：每个进程都有独立的代码和数据空间，是资源分配的最小单位，一个进程包含1个或多个线程。
- 线程：线程是cpu调度的最小单位，同一个进程中的线程共享代码和数据空间，每个线程有独立的运行栈和程序计数器(PC)。

### 如何使用？

在`Java`中，实现多线程有三种基本方法：

1. 继承 `java.lang.Thread`类，并重写 `run()`方法。
2. 实现`java.lang.Runnable`接口，并重写 `run()`方法。
3. `Callable` + `Future` + `FutureTask`(这三者在java.util.concurrent包下，该包是`java`中的一个并发包)。

### 使用举例

A、`Thread`类的使用：

```java
class MyThread extends Thread {
    
    private String name;

    public MyThread(String name) {
        this.name = name;
    }

    @Override
    public void run() {
        for (int i = 0; i < 5; i++) {
            System.out.println(name + "运行  :  " + i);
            try {
                sleep((int) Math.random() * 10);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}

public class Main {

    public static void main(String[] args) {
        MyThread mT1 = new MyThread("A");
        MyThread mT2 = new MyThread("B");
        mT1.start();
        mT2.start();
    }
}
```

结果如下：
![Thread类使用距离结果1](/imgs/Thread类使用距离结果1.png)

![Thread类使用距离结果2](/imgs/Thread类使用距离结果2.png)

`start()`方法调用后，线程变为就绪状态，但是什么时候运行是由操作系统决定的。注意，不能连续两次调用`start()`方法，会报错。

B、`Runnable`的使用：

```java
class MyRunnable implements Runnable {

    private String name;

    public MyRunnable(String name) {
        this.name = name;
    }

    @Override
    public void run() {
        for (int i = 0; i < 5; i++) {
            System.out.println(name + "运行  :  " + i);
        }
    }
}

public class Test {

    public static void main(String[] args) {
        Thread t1 = new Thread(new MyRunnable("A"));
        Thread t2 = new Thread(new MyRunnable("B"));
        t1.start();
        t2.start();
    }
}
```

结果如下：

![Runnable接口使用举例结果1](/imgs/Runnable接口使用举例结果1.png)

![Runnable接口使用举例结果2](/imgs/Runnable接口使用举例结果2.png)

通过对比使用`Thread`和`Runnable`的结果，我们发现两者的前后的两次结果不一致，两者线程的执行顺序是乱的。其实这是一种正常现象，这就是并发编程的基本形式。

**`Thread`和`Runnable`的知识点：**

- 不管是扩展`Thread`类还是实现`Runnable`接口来实现多线程，最终还是通过`Thread`的对象的`API`来控制线程的。
- `Thread`不可复用，`Runnable`可复用。其含义是`Runnable`可作为一种执行任务，放入到两个线程中，即两个`Thread`执行的任务是一模一样的。但是 `Thread`却不可以同时放入两个线程池中。
- `Runnable`可以避免`java`中的单继承（即一个类只能有一个父类）的限制。`java`可以通过实现多个接口达到和`C++`多继承类似的效果。
- 线程池只能放入实现`Runable`或`callable`接口的类作为任务，不能直接放入继承`Thread`的类。

C、`Callable + Future + FutureTask`的使用

`Runnable`执行是没有返回值的，如果需要返回值，可以用`Callable`代替。`Callable`的部分源代码如下：

```java
package java.util.concurrent;

public interface Callable<V> {
    /**
     * 得到一个结果，如果没法得到结果，则抛出一个异常。
     *
     * @return 算出的结果
     * @throws Exception 没法得到结果抛出的异常
     */
    V call() throws Exception;
}
```

`Callable`在`java.util.concurrent`包下（这是 Java 框架中一个很重要的包，如果你能读透这个包的源码，那么你就是并发大神了）。

`Callable`一般情况下是配合`ExecutorService`（属于线程池部分的内容，后面讲解）来使用的，`ExecutorService`接口中有两个方法经常使用：

```java
<T> Future<T> submit(Callable<T> task);
Future<?> submit(Runnable task);
```

一个参数是`Callable`，另一个是`Runnable`。至于`Future`，是对于**任务和结果的描述**与**操作的集合**，其部分方法如下：

```java
package java.util.concurrent;

public interface Future<V> {

    /**
     * 任务正常完成前，取消任务
     * @param mayInterruptIfRunning 为true表示取消任务
     * @return 取消成功返回true，否则返回false
     */
    boolean cancel(boolean mayInterruptIfRunning);

    /**
     * 判断任务是否被取消成功
     * @return 任务取消成功，返回 true，否则返回false
     */
    boolean isCancelled();

    /**
     * 判断任务是否已经完成
     * @return 任务完成返回true，否则返回false
     */
    boolean isDone();

    /**
     * 获取执行结果，会产生阻塞，一直等到任务执行完毕才返回
     * @return 返回的结果
     */
    V get() throws InterruptedException, ExecutionException;

    /**
     * 获取执行结果，如果指定时间内没获取到结果，则抛出超时异常
     * @param timeout 等待的时间长度
     * @param unit 时间的格式
     * @return 返回的结果
     */
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

对于`cancel`方法，如果任务还没有执行，则无论`mayInterruptIfRunning`为`true`还是`false`，都返回`true`；如果任务已经完成，则无论`mayInterruptIfRunning`为`true`还是`false`，此方法肯定返回`false`，如果任务正在执行，则取消的返回值就视情况而定了。正因为如此，`Future`接口才会提供一个判断任务是否取消完成的方法。

从源码中，我们可以看出，`Future`主要提供了三个方面的功能：

- 判断任务是否完成
- 取消任务，并判断任务是否被取消
- 获取任务执行结果

而`FutureTask`是什么样子的呢？其实它是`Future`接口的一个实现类，也在`concurrent`包下，其部分源代码如下：

```java
package java.util.concurrent;

public class FutureTask<V> implements RunnableFuture<V> {
    public FutureTask(Callable<V> callable) {
        if (callable == null)
            throw new NullPointerException();
        this.callable = callable;
        //......其余代码省略
    }
    //......其余代码省略
}
```

可以看出，`FutrueTask`的构造函数允许传入`Callable`作为参数，也就意味着他可以和`Callable`配合使用。那么`Future`呢？它不是`Callable + Future + FutureTask`三要素之一吗？别急，让我们继续看。

在上面的代码里，我们注意到一个事实，`FutureTask`是实现了`RunnableFuture`接口的，那`RunnableFuture`接口是什么呢？它是怎样的呢？让我们看看源码：

```java
package java.util.concurrent;

public interface RunnableFuture<V> extends Runnable, Future<V> {
    void run();
}
```

它继承了`Runnable`和`Future`接口，那么它既可以作为`Runnable`被线程执行，又可以作为`Future`接受`Callable`返回的结果。`FutureTask`是实现了`RunnableFuture`接口，自然就可以进行这些操作。

做个形容，`Future`可以理解为待做的事，即目的；`Callable`是可执行的方法，即操作，可理解为达到目的的操作；`FutureTask`，集合了两者，包含了操作和结果。

上面我们理清了`Callable + Future + FutureTask`的关系，下面就来看看它们怎么使用：

```java
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.Callable;

public class Test {
	public static void main(String[] args) {
		//线程池中包含5个线程
		ExecutorService service = Executors.newFixedThreadPool(5);
		Task task = new Task();
		Future<Integer> result = service.submit(task);
        //FutureTask<Integer> result = new FutureTask<>(task);
        //service.submit(result);
		System.out.println("-----主线程正在执行任务-----");
		try {
			System.out.println("task 运行结果为：" + result.get());
		} catch (ExecutionException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		System.out.println("-----主线程正在执行完成-----");
		//任务执行结束，释放资源
		service.shutdown();
		service = null;
	}
}

class Task implements Callable<Integer> {

    @Override public Integer call() throws Exception {
        System.out.println("-----子线程正在计算-----");
        int sum = 0;
        for(int i = 0; i < 10; i++) {
            sum += i;
        }
        System.out.println("-----子线程计算完成-----");
        return sum;
    }
}
```

结果如下，有两种。因为两个线程是并行的，不存在先后顺序：

![Callable_Future_ThreadPool的使用1](/imgs/Callable_Future_ThreadPool的使用1.png)

![Callable_Future_ThreadPool的使用2](/imgs/Callable_Future_ThreadPool的使用2.png)

那么`Callable + FutureTask`怎么使用呢？我们将上面的`main`方法稍微改造下。第12行代码改为下面的内容：

```java
FutureTask<Integer> result = new FutureTask<>(task);
service.submit(result);
```

其余代码不变，最后结果和未更改之前一致。

**说明：**

A、`Callable + Future + FutureTask`的使用步骤：

1. 定义任务，即实现`Callable`接口。
2. 初始化线程池。
3. 在线程池中执行任务，得到返回结果。

B、使用`Future`和`FutureTask`的区别：使用`Future`，传入线程池的任务是`Callable`，`Callable`有返回值，得定义`Future`变量存储（代码第12行）；而使用`FutureTask`，是作为`Runnable`传入的，是没有返回值的，结果包装在`FutureTask`中（代码第13, 14行）。

### `Thread`和`Runnable`的知识点

- 不管是扩展`Thread`类还是实现`Runnable`接口来实现多线程，最终还是通过`Thread`的对象的`API`来控制线程的。
- `Thread`不可复用，`Runnable`可复用。其含义是`Runnable`可作为一种执行任务，放入到两个线程中，即两个`Thread`执行的任务是一模一样的。但是 `Thread`却不可以同时放入两个线程池中。
- `Runnable`可以避免`java`中的单继承（即一个类只能有一个父类）的限制。`java`可以通过实现多个接口达到和`C++`多继承类似的效果。
- 线程池只能放入实现`Runable`或`callable`接口的类作为任务，不能直接放入继承`Thread`的类。

### 线程的生命周期

- 新建状态（New）：`new`操作新创建了一个线程对象后，线程就进入了新建状态。
- 就绪状态（Runnable）：线程的`start()`方法被调用后。线程就处于就绪状态，等待获取`CPU`的使用权。
- 运行状态（Running）：线程获取`CPU`的使用权，执行程序代码，就处于运行状态。
- 阻塞状态（Blocked）：阻塞状态是线程因为某种原因放弃CPU使用权，暂时停止运行。阻塞的情况分三种：
  - 等待阻塞：运行的线程执行`wait()`方法，进入等待状态，线程会释放持有的锁。其他线程可以使用该线程目前正在使用的资源。
  - 同步阻塞：运行的线程在获取对象的同步锁时，若该同步锁被别的线程占用，该线程就进入了同步阻塞状态。
  - 其他阻塞：运行的线程执行sleep()或join()方法，或者发出了I/O请求时，JVM会把该线程置为阻塞状态。当sleep()状态超时、join()等待线程终止或者超时、或者I/O处理完毕时，线程重新转入就绪状态。注意，线程调用`sleep()`不会释放持有的锁，其他线程不能使用该线程目前正在使用的资源。
- 死亡状态（Dead）：线程执行完了，或者因异常退出了`run()`方法，该线程就处于死亡状态，不再运行。

### 线程的优先级

`Java`线程有优先级，优先级高的线程会获得较多的运行机会。`Thread``类的setPriority()`和`getPriority()`方法分别用来设置和获取线程的优先级。

`Java`线程的优先级用整数表示，取值范围是1~10，`Thread`类有以下三个静态常量：

- MAX_PRIORITY：线程可以具有的最高优先级，取值为10。
- MIN_PRIORITY：线程可以具有的最低优先级，取值为1。
- NORM_PRIORITY：分配给线程的默认优先级，取值为5。

每个线程都有默认的优先级。主线程的默认优先级为Thread.NORM_PRIORITY。

线程的优先级有继承关系，比如A线程中创建了B线程，那么B将和A具有相同的优先级。

**注意：如果希望程序能跨平台，应该仅仅使用Thread类有以下三个静态常量作为优先级，这样能保证在各平台上是同样的调度方式。**

### 线程的调度

1. 线程睡眠：`Thread.sleep(long millis)`，使线程转到阻塞状态。millis参数设定睡眠的时间，以毫秒为单位。当睡眠结束后，就转为就绪（Runnable）状态。

2. 线程等待：`Object.wait()`方法，当前的线程等待，直到其他线程调用此对象的`notify()`方法或`notifyAll()`方法。这两个唤醒方法也在Object类中。

3. 线程让步：`Thread.yield()`方法，暂停当前正在执行的线程对象，把执行机会让给相同或者更高优先级的线程。

4. 线程加入：`Thread.join()`方法，等待其他线程终止。在当前线程中调用另一个线程的`join()`方法，则当前线程转入阻塞状态，直到另一个进程运行结束，当前线程再由阻塞转为就绪状态。

5. 线程唤醒：`Object.notify()`方法，唤醒等待的单个线程。如果所有线程都在此对象上等待，则会选择唤醒其中一个线程。选择是任意性的。`Object.notifyAll()`，唤醒等待的所有线程。

### 线程调度举例

- 线程睡眠：一句代码的事，此处不再举例。
- 线程等待和线程唤醒一般是一起执行的。推荐使用`notifyAll`，不推荐使用`notify`，后者唤醒的线程是随机的，是不可控的。一般情况下，我们应该在`synchronized`和`while`循环中使用`wait`和`notice`，如果不遵循这个规则，线程往往是不安全的，容易冲突或者导致死锁。

```java
import java.util.LinkedList;
import java.util.Queue;
import java.util.Random;

/**
 * @date 2018/12/20 8:31
 *
 * wait/notify举例：生产者-消费者模型
 */
public class Test {
    public static void main(String args[]) {
        System.out.println("Java 中 wait/notify 举例：生产者-消费者模型\n");
        Queue<Integer> queue = new LinkedList<>();
        int maxSize = 10;

        Producer producer = new Producer("PRODUCER", queue, maxSize);
        Consumer consumer = new Consumer("CONSUMER", queue, maxSize);

        producer.start();
        consumer.start();
    }
}

/**
 * 生产者线程
 * */
class Producer extends Thread {

    private static final String TAG = "[ProducerThread]";

    private Queue<Integer> queue;
    private int maxSize;

    public Producer(String name, Queue<Integer> queue, int maxSize) {
        super(name);
        this.queue = queue;
        this.maxSize = maxSize;
    }

    @Override
    public void run() {
        while(true) {
            synchronized (queue) {
                while(queue.size() == maxSize) {
                    try {
                        System.out.println(TAG + "The queue is full, producer is "
                            + "waiting for consumer to take something from the queue");
                        queue.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }

                Random random = new Random();
                int value = random.nextInt();
                System.out.println(TAG + "Producing value: " + value);
                queue.add(value);
		queue.notifyAll();
            }
        }
    }
}

/**
 * 消费者线程
 * */
class Consumer extends Thread {

    private static final String TAG = "ConsumerThread";

    private Queue<Integer> queue;
    private int maxSize;

    public Consumer(String name, Queue<Integer> queue, int maxSize) {
        super(name);
        this.queue = queue;
        this.maxSize = maxSize;
    }

    @Override public void run() {
        while(true) {
            synchronized (queue) {
                while(queue.isEmpty()) {
                    try {
                        System.out.println(TAG + "The queue is full, producer is "
                            + "waiting for consumer to take something from the queue");
                        queue.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }

                System.out.println(TAG + "Consuming value: " + queue.remove());
                queue.notifyAll();
            }
        }
    }
}
```

例子中有两个`while`循环，第一个是针对线程的，如果线程想要运行，最好在`while`循环中实现，第二个`while`是针对 `wait`和`notifyAll`，保证结果达到预期。

例子中的调用的是`Queue`的`wait`和`notifyAll`，其实此时是将`Queue`对象作为了缓冲区，或者叫共享对象（共享内存）。由缓冲区决定线程的等待或者唤醒，以保证线程能够一直运行下去，不出现死锁。

- 线程让步：将当前线程从执行状态变为就绪状态。cpu会从众多的就绪状态线程里（包括自己），选择相同或者更高优先级的线程执行。举个例子：一个人A去餐厅吃饭，本来他已经坐下了，但他看见外面有个人B，就离开了位置，出去对B说，我们比个赛吧，看谁先到那个位置，谁就餐。两人在同一起跑线上开跑，谁先到都有可能。A先到A就餐，B先到B就餐。

```java
public class YieldTest {
    public static void main(String args[]) {
        MyThread thread1 = new MyThread("张");
        MyThread thread2 = new MyThread("杨");

        thread1.start();
        thread2.start();
    }
}

class MyThread extends Thread {
	
    String name;

    public MyThread(String name) {
        super(name);
	this.name = name;
    }

    @Override
    public void run() {
	for (int i = 1; i <= 50; i++) {
	    // 当i为30时，该线程就会把CPU时间让掉，让其他或者自己的线程执行
	    //（也就是谁先抢到谁执行）
	    if (i == 30) {
		System.out.println(name + "-----" + "重新进入轮转");
		yield();
	    }
	    System.out.println(name + "-----" + i);
	}
    }
}
```

运行结果：

![yeild方法使用结果](/imgs/yeild方法使用结果.png)

在 1 处，名字为张的线程执行了`yield`函数，进入了可执行状态，`CPU`重新选择线程执行，此时`CPU`选择线程张，线程张继续执行；而在 2 处，线程杨执行了`yield`函数，进入了可执行状态，此时`CPU`选择了线程张，并没有选择线程杨。yield`的作用清晰可见。

- 线程加入：在很多情况下，主线程生成并起动了子线程，如果子线程里要进行大量的耗时的运算，主线程往往将于子线程之前结束，但是如果主线程处理完其他的事务后，需要用到子线程的处理结果，也就是主线程需要等待子线程执行完成之后再结束，这个时候就要用到join()方法了。

```java
public class Test {
    public static void main(String[] args) {
        String name = Thread.currentThread().getName();
        System.out.println("* * * * * 主线程等待线程 A 执行完毕再执行 * * * * *");
        try {
            System.out.println(name + " start.");

            ThreadB b = new ThreadB();
            ThreadA a = new ThreadA(b);

	    a.start();
	    b.start();
            //可以想象成将A的代码移动到此处执行
            a.join();
						
	    System.out.println(name + " start.");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            System.out.println("* * * * * 主线程执行完毕 * * * * *");
        }
    }
}

class ThreadA extends Thread {
    private ThreadB tb;

    public ThreadA(ThreadB tb) {
        super("Thread-A");
        this.tb = tb;
    }

    @Override public void run() {
        String name = Thread.currentThread().getName();
        System.out.println("* * * * * 线程 A 等待线程 B 执行完毕再执行 * * * * *");
        try {
            System.out.println(name + " start.");
			
            //可以想象成将线程B的代码移到此处执行
            tb.join();
			
            System.out.println(name + " end.");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            System.out.println("* * * * * 线程 A 执行完毕 * * * * *");
        }
    }
}

class ThreadB extends Thread {
    public ThreadB() {
        super("Thread-B");
    }

    @Override public void run() {
        String name = Thread.currentThread().getName();
        System.out.println("* * * * * 线程 B 首先执行 * * * * *");
        try {
            System.out.println(name + " start.");

            for (int i = 0; i < 5; i++) {
                System.out.println(name + " loop at " + i);
                sleep(1000);
            }

            System.out.println(name + " end.");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            System.out.println("* * * * * 线程 B 执行完毕 * * * * *");
        }
    }
}
```

运行结果：

![join方法使用结果1](/imgs/join方法使用结果1.png)

![join方法使用结果2](/imgs/join方法使用结果2.png)

上面两个结果中红色圈出的部分，对比发现是不同的。直觉告诉我们，第二个截图里的结果是我们想要的，但是却不能保证总是那个结果。这说明使用`join()`方法有时候会出现意想不到的情况，要保证线程按照固定的顺序执行，最好的方法还是对线程加锁，这一部分放到下面讲解。

## Java 中的同步与互斥

在`Java`中，进程同步与互斥 叫做 线程的同步与互斥。

### 概念

**线程同步**

异步环境下的一组并发进程因直接制约而互相发送消息、进行互相合作、互相等待，使得各线程按一定的速度执行的过程称为线程间的同步。简单的讲，多个线程常常需要共同修改某些共享变量，表格，文件数据库等，协作完成一些功能。这时候就需要用线程同步。一个十分经典的场景是，操作系统里的[生产者-消费者问题](https://zh.wikipedia.org/wiki/生产者消费者问题 "需要梯子")。

**线程互斥**

在多个程序中，有两个线程不可以同时进行。一个十分经典的场景是，多个线程对同一文件的[读写操作](https://zh.wikipedia.org/wiki/读写锁 "需要梯子")。

### `synchronized`关键字

java 默认实现了一个关键字---`synchronized`，以支持多线程中的同步操作。当它用来修饰一个方法或者一个代码块的时候，能够保证在同一时刻最多只有一个线程执行该段代码。

使用`synchronized`关键字的基本规则：

1. 同步锁分两种：对象锁和类锁。**对象锁对某个对象生效**，比如两个线程 A、B 要访问某个类的实例对象的代码，该对象实现了同步锁。如果 A 获取了此对象的同步锁，B 将不能访问此对象的同步锁内的代码。而对于该类的另外一个实例对象，B却是可以访问相同的同步锁内的代码；**类锁是指同步锁对于类的所有实例对象都生效**。比如上述的例子，如果将对象锁换位类锁，B 将不能访问，另一个对象同步锁内的代码。
2. 某个对象存在不止一个`synchronized`同步代码块，**如果一个线程 A 获得了其中一个`synchronized`代码块的锁，其他线程将不能访问该对象的所有`synchronized`代码块，但是可以访问非`synchronized`的代码块**。也就是说，锁对所有`synchronized`同步代码块都生效。

下面让我们用几个例子来验证一下。

#### 规则 1 验证

首先自定义一个`Runnable`类，对其使用`synchronized`同步锁：

```java
class MyRunnable implements Runnable {
    @Override public void run() {
        synchronized (this) {
            for (int i = 0; i < 5; i++) {
                System.out.println(Thread.currentThread().getName()
                    + " synchronized loop " + i);
            }
        }
    }
}
```

然后在`main`方法中使用（**验证代码1**）：

```java
public class SynchronizedTest {
    public static void main(String args[]) {
        MyRunnable runnable = new MyRunnable();
        Thread t1 = new Thread(runnable, "A");
        Thread t2 = new Thread(runnable, "B");
	t1.start();
	t2.start();
    }
}
```

按照预期，结果应该是 A 执行完毕 B 再执行，是不是这样呢？让我们来看看结果（**结果1**）：

![synchronized使用结果1](/imgs/synchronized使用结果1.png)

无论运行几次，得到的结果都是一样的。图中红点以上为线程 A 的执行结果，红点以下为 B 的执行结果。结果是符合预期的。

这里有个就问题了，对于`synchronized`，我们上面那种用法，构造的是对象锁还是类锁？我们可以根据规则 1 来验证一下，改写`main`方法（**验证代码2**）：

```java
public class SynchronizedTest {
    public static void main(String args[]) {
        MyRunnable runnableA = new MyRunnable();
	MyRunnable runnableB = new MyRunnable();
        Thread t1 = new Thread(runnableA, "A");
        Thread t2 = new Thread(runnableB, "B");
	t1.start();
	t2.start();
    }
}
```

将`MyRunnable`的实例对象从一个变成两个，线程 A 和 B 使用不同的实例，如果是类锁，结果会和上面一致。如果不是，结果可能就和上面不一致。现在运行代码，得到如下结果（**结果2**）：

![synchronized对象锁的验证结果](/imgs/synchronized对象锁的验证结果.png)

结果不一样，说明我们之前的用法是对象锁。

那么如何得到类锁呢？让我们将`MyRunnable`类改造以下，在`synchronized`块中传入`MyRunnable`的类名：

```java
class MyRunnable implements Runnable {
    @Override public void run() {
        synchronized (MyRunnable.class) {
            for (int i = 0; i < 5; i++) {
                System.out.println(Thread.currentThread().getName()
                    + " synchronized loop " + i);
            }
        }
    }
}
```

再用**验证代码2**进行验证，发现无论运行几次，结果都是**结果1**那样了。

通过上面这个例子，我们也明白**对象锁**和**类锁**是如何得到的了。

#### 规则 2 验证

验证了规则1，我们用一个例子继续验证规则2。在`MyRunnable`中增加了一个没有用 `synchronized`修饰的方法。

```java
class MyRunnable implements Runnable {
    @Override public void run() {
        synchronized (this) {
            for (int i = 0; i < 5; i++) {
                System.out.println(Thread.currentThread().getName()
                    + "synchronized loop " + i);
            }
        }
    }

    public void syncSayHello() {
        synchronized (this) {
            System.out.println("synchronized say Hello method.");
        }
    }
    
    public void sayHello() {
        System.out.println("Hello, this is not synchronized method.");
    }
}
```

在`main`方法中加入验证代码：

```java
public class SynchronizedTest {
    public static void main(String args[]) {
        MyRunnable runnable = new MyRunnable();	
        Thread t1 = new Thread(runnable, "A");
        Thread t2 = new Thread(new Runnable() {
            @Override public void run() {
                runnable.sayHello();
            }
        }, "B");

        t1.start();
        t2.start();
    }
}
```

线程 t2 实现了 Runnable 接口，接口里面调用了`MyRunnable`的非同步方法，如果 B 可以顺利访问访问A中的非同步代码块，那么 B 的代码有可能在 A 线程执行结束前执行。多运行几次，得到了如下结果：

![synchronized非同步代码调用结果1](/imgs/synchronized非同步代码调用结果1.png)

红点处是 B 线程的运行结果，在 A 线程结束之前。说明 B 虽然没有得到对象锁，但是仍然能够访问`MyRunnable`中的非同步代码，结果符合我们的预期。

规则2中还有一个说明，如果一个线程 A 获得了其中一个`synchronized`代码块的锁，其他线程将不能访问该对象的所有`synchronized`代码块。让我们来验证一下。

`Runnable`对象不变，改写一下`main`方法：

```java
public class SynchronizedTest {
    public static void main(String args[]) {

        MyRunnable runnable = new MyRunnable();
		
        Thread t1 = new Thread(runnable, "A");
        Thread t2 = new Thread(new Runnable() {
            @Override public void run() {
                // 此处改为访问同步方法
                runnable.syncSayHello();
            }
        }, "B");

        t1.start();
        t2.start();
    }
}
```

无论运行几次，结果都是一样，B 会在 A 线程执行完毕以后执行。符合我们的说明。

![synchronized同步代码调用结果1](/imgs/synchronized同步代码调用结果1.png)

截止到这里，`synchronized`的两个规则就说明的差不多了。

等等，以为这样就完了？不，其实还有一个知识点：`synchronized`同步方法和`synchronized`同步代码块。

让我们看看什么是`synchronized`同步方法：

```java
@Override 
public synchronized void run() {
    //这里写测试代码
}
```

是不是很简单！让我们看看`synchronized`同步代码块的用法。

在上面举的例子中，我们的用法是这样的：

```java
@Override 
public void run() {
    synchronized (this) {
        //这里写测试代码
    }
}
```

这其实就是`synchronized`同步代码块的用法。

虽然上面有提到，线程 B 得等到 A 执行完毕再执行，但是这里的意思**并不是 B 无法访问`run`方法。其实 B 可以访问`run`方法，B 真正无法访问的是`synchronized`代码块中的内容**。

举个例子验证一下。首先改写`MyRunnable`类：

```java
class MyRunnable implements Runnable {
    @Override public void run() {
        System.out.println("Hello, this is run start at thread "
            + Thread.currentThread().getName());
        synchronized (this) {
            for (int i = 0; i < 5; i++) {
                System.out.println(Thread.currentThread().getName()
                    + "synchronized loop " + i);
            }
        }
        System.out.println("Hello, this is run end at thread "
            + Thread.currentThread().getName());
    }
}
```

在同步代码两端加点非同步的代码，采用**验证代码1**的代码进行验证：

![synchronized同步块代码调用结果1](/imgs/synchronized同步块代码调用结果1.png)

可以看到，同步代码块之前的内容，B 是可以访问的，不必等到线程 A 执行完毕，但是同步代码块之后的代码，无论运行几次，发现都得等到 A 执行完毕，B 才能执行。

至此我们可以得出结论，对于`synchronized`同步代码块，在以下代码结构中：

```java
public void methodName() {
    //非同步代码块1
    synchronized (this) {
        //同步代码块
    }
    //非同步代码块2
}
```

如果存在 A、B 两个线程，A 取得了同步锁，那么 A 可以访问 非同步代码块1、同步代码块、非同步代码块2 三处代码，而 B 只能访问 非同步代码块1 一处代码，等到 A 执行完毕了，B 才能访问剩下两处代码。这里就有个疑问了，为什么 B 不能在 A 结束之前访问 非同步代码块2？其实在 非同步代码块2 之前，A已经取得了该对象的锁，此时 B 就不能访问对象中的任何内容了。只有等到 A 释放了锁，B 才能继续访问。

等等，我们是不是还有个点没有提，`synchronized`同步方法得到的锁是对象锁还是类锁？

我们改写一下`MyRunnable`类：

```java
class MyRunnable implements Runnable {
    @Override public synchronized void run() {
        for (int i = 0; i < 5; i++) {
            System.out.println(Thread.currentThread().getName()
                + "synchronized loop " + i);
        }
    }
}
```

采用**验证代码2**进行验证：

![synchronized同步方法代码调用结果1](/imgs/synchronized同步方法代码调用结果1.png)

上面的结果中，B 并未等到 A 结束再执行，而是在 A 结束之前就已经开始执行，这也就证明了`synchronized`同步方法获得的锁是对象锁，不是类锁。

### `Lock`的使用

在讲`Lock`前，我们得先 明白几件事。

- **什么是`Lock`？**出于对多线程的支持，JDK1.5引入了一个重要的包：`concurrent`（中文意思为并发）。该包主要包括三个部分：

   - `java.util.concurrent`：提供大部分关于并发的接口和类：如`callable`、`ExecutorService`等等。
   - `java.util.concurrent.atomic`：提供所有原子操作的类，如`AtomicInteger`，`AtomicLong`等等。
   - `java.util.concurrent.locks`：这就是我们这次要讲的内容了。这个包提供锁类, 如`Lock`，`ReentrantLock`等等。

- **为什么用`Lock`？**前面我们细讲了如何`synchronized`的用法，可见`synchronized`关键字还是很好用的。但是，`synchronized`关键字却几个缺点不容忽视：

   - `synchronized`关键字并没有对线程占用锁的时间作出限制。即除非出现持有锁的线程运行结束，或者抛出异常等情况，否则线程是不会释放锁的。比如以下场景：线程占有了锁，但是在等待 I/O 操作，如果 I/O 操作不完成，线程就会一直等待，并且不会释放锁。这会大大影响程序的效率。
   - 我们知道，当两个线程对一个文件进行操作时，两个线程的读操作可以同时进行，不会相互影响。但是如果采用`synchronized`关键字实现同步的话，就会出现一个问题，当多个线程进行读操作时，只有一个线程可以进行读操作，其他线程只能等待锁的释放，无法进行读操作。
   - 在`synchronized`实现锁的前提下，我们无法知道一个线程是否获得了锁。

   上面提到的三种情形，我们都可以通过`Lock`来解决，但`synchronized`关键字却无能为力。

#### 用法模板

`Lock`接口中声明了四种方法来获取锁：`lock()`、`tryLock()`、`tryLock(long time, TimeUnit unit)`和`lockInterruptibly()`，让我们来看看这四种方法通常是怎么用的。

注意：用`Lock`接口获取的锁必须**主动释放**。

1. **lock()：**获取所最常用的一个方法。如果锁被其它线程占有，则等待。当占有锁的线程出现异常时，不会主动释放锁，所以`lock()`方法的用法通常如下：

   ```java
   Lock lock = ...;
   lock.lock();
   try {
       //处理任务
   } catch(Exception ex) {
       //处理异常
   } finally {
       lock.unlock(); //释放锁
   }
   ```

   在`try-catch`块中处理任务，捕获异常，并且在`finally`中释放锁。保证锁总能被释放，不会出现死锁的情况。

2. **tryLock()：**该方法是有返回值的。它表示用来尝试获取锁，如果拿到锁，则返回true，否则返回false。该方法会立即返回，不会等待。

   ```java
   Lock lock = ...;
   if(lock.tryLock()) {
       try {
       	//处理任务
   	} catch(Exception ex) {
       	//处理异常
   	} finally {
       	lock.unlock(); //释放锁
   	}
   } else {
       //处理没有获得锁的情况
   }
   ```

3. **tryLock(long time, TimeUnit unit)：**和`tryLock()`方法类似，不过该方法在拿不到锁时，会等待一定的时间，等待结束拿到锁，返回true，否则返回false。

4. **lockInterruptibly()：**该方法比较特殊，当两个线程同时通过`lock.lockInterruptibly()`想获取某个锁时，假若此时线程A获取到了锁，而线程B只有在等待，那么对线程B调用`threadB.interrupt()`方法能够中断线程B的等待过程。也就是说，当通过这个方法去获取锁时，如果线程正在等待获取锁，则这个线程能够响应中断，即中断线程的等待状态。


   ```java
   Lock lock = ...;
   try {
       lock.lockInterruptibly();
       //货的锁执行
   } catch(InterruptedException ex) {
       //处理异常
   } finally {
   	lock.unlock(); //释放送
   }  
   ```

   注意，当一个线程获取了锁之后，是不会被interrupt()方法中断的。因为本身在前面的文章中讲过单独调用interrupt()方法不能中断正在运行过程中的线程，只能中断阻塞过程中的线程。

#### 相关概念

讲锁的使用前，得先讲点概念，否则小伙伴们看着的时候会有点懵。

**可重入锁**

如果锁具备可重入性，则称作为可重入锁。可重入性表明了锁的分配机制：基于对象的分配，而不是基于方法调用的分配。即分配对象锁，然后可以访问该对象的所有同步方法。如果分配方法锁，访问每个方法都要重新获取锁，效率就会大打折扣。

**可中断锁**

在`Java`中，`synchronized`不是可中断锁，而`Lock`是可中断锁。

如果某一线程A正在执行锁中的代码，另一线程B正在等待获取该锁，可能由于等待时间过长，线程B不想等待了，想先处理其他事情，我们可以让它中断自己或者在别的线程中中断它，这种就是可中断锁。

在前面演示`lockInterruptibly()`的用法时已经体现了`Lock`的可中断性。

**公平锁**

公平锁尽量以请求锁的顺序来获取锁。

当有多个线程在等待一个锁，当这个锁被释放时，等待时间最久的线程（最先请求的线程）会获得该锁，这种就是公平锁。

非公平锁无法保证锁的获取是按照请求锁的顺序进行的。这样就可能导致某个或者一些线程永远获取不到锁。

`synchronized`就是非公平锁，它无法保证等待的线程获取锁的顺序。

对于`ReentrantLock`和`ReentrantReadWriteLock`，它默认情况下是非公平锁，但是可以设置为公平锁。

**读写锁**

读写锁将对一个资源（比如文件）的访问分成了2个锁，一个读锁和一个写锁。

正因为有了读写锁，才使得多个线程之间的读操作不会发生冲突。

### 相关类

**可重入锁：ReentrantLock**

`ReentrantLock`实现了`Lock`接口，是最常用的一个锁实现类。下面是使用举例，一个锁，三个线程：

```java
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock; 
 
public class Test {
    public static void main(String args[]) {
		
		MyConditionService service = new MyConditionService();
		
        Thread t1 = new MyThread("A", service);
        Thread t2 = new MyThread("B", service);
        Thread t3 = new MyThread("C", service);

        t1.start();
        t2.start();
        t3.start();
    } 
}

class MyThread extends Thread {
    private MyConditionService service;

    public MyThread(String name, MyConditionService service) {
        super(name);
        this.service = service;
    }

    @Override public void run() {
        service.testMethod();
    }
}

class MyConditionService {
    /**
     * 可重入锁
     * */
    private Lock lock = new ReentrantLock();

    public void testMethod() {
        try {
            lock.lock();
            for(int i = 1; i <=3; i++) {
                System.out.println("Thread\t" + Thread.currentThread().getName()
                    + "\tin\t" + i);
            }
            System.out.println();
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

上述代码的结果如下：

![ReentrantLock使用举例1](/imgs/ReentrantLock使用举例1.png)

应该注意的是，**Lock 接口的实现类，实现的锁效果是对象锁**。

**读写锁：ReadWriteLock**

`ReadWriteLock`是读写锁的接口，它里面只定义了两个方法，用来获取读锁和写锁。

```java
public interface ReadWriteLock {
	//获取写锁
    Lock readLock();
 	//获取读锁
    Lock writeLock();
}
```

此接口并未实现`Lock`接口，使用的时候得注意。

关于读写锁的概念，前面讲**线程互斥**的部分有个链接，可以点击查看，不过需要梯子。

**可重入读写锁：ReentrantReadWriteLock**

该类是`ReadWriteLock`的实现类，方法很多，功能丰富，形如设置锁获取策略（公平锁，非公平锁），`Condition`支持等，不过最核心的方法只有两个：`readLock()`和`writeLock()`。
改造下上面的例子，将`MyConditionService`中的可重入锁改为读写锁。

```java
class MyConditionService {
    /**
     * 改动1：可重入锁变为读写锁
     * */
    private ReadWriteLock lock = new ReentrantReadWriteLock();

    public void testMethod() {
        try {
            //改动2：获取读锁
            lock.readLock().lock();
            //下面部分省略，内容和前面可重入锁例子保持一致
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            //改动3：释放读锁
            lock.readLock().unlock();
        }
    }
}
```

结果为：

![读写锁使用举例1](/imgs/读写锁使用举例1.png)

其实结果并不唯一，但大部分结果都有一个特点，那就是2个或者3个线程同时运行，因为两个线程的读操作不会冲突。不过还是会线程依次执行的情况，只是可能性比较小，因为线程的开始时间是随机的。

**`Condition`的使用**

**介绍**

`Condition`是在`java 1.5`中才出现的，它用来替代传统的`Object`的`wait()、notify()`实现线程间的协作，相比使用`Object`的`wait()、notify()`，使用`Condition`的`await()、signal()`这种方式实现线程间协作更加安全和高效。因此通常来说比较推荐使用`Condition`。JDK 也使用了`Condition`实现阻塞队列。

**注意点**

- `Condition`是个接口，基本的方法就是`await()`和`signal()`方法；
- `Condition`依赖于`Lock`接口，生成一个`Condition`的基本代码是`lock.newCondition()`
- `Condition`的使用，必须在`lock.lock()`和`lock.unlock`之间。

**使用举例**

下面使用`Condition`结合`Lock`，改写前面我们写的生产者消费者的例子，大家就明白怎么`Condition`用了：

```java
import java.util.LinkedList;
import java.util.Queue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * 使用 Condition 结合 Lock 改写生产者-消费者模型
 */
public class ProducerConsumerModelWithCondition {
    private static Lock lock = new ReentrantLock();
    /**
     * 两个线程各自最多运行21次
     */
    private static CountDownLatch count = new CountDownLatch(21);
    private static final int MAX_SIZE = 5;
    private static Queue<Long> queue = new LinkedList<>();
    private static Condition notFull = lock.newCondition();
    private static Condition notEmpty = lock.newCondition();

    public static void main(String[] args) {
        Producer2 producer = new Producer2("Producer", queue, MAX_SIZE,
            lock, notFull, notEmpty, count);
        Consumer2 consumer = new Consumer2("Consumer", queue, lock,
            notFull, notEmpty, count);

        producer.start();
        consumer.start();
    }
}

/**
 * 生产者线程
 */
class Producer2 extends Thread {

    private static final String TAG = "---生产者---";

    private Queue<Long> queue;
    private int maxSize;
    private Lock lock;
    private Condition notFull, notEmpty;
    private CountDownLatch count;

    public Producer2(String name, Queue<Long> queue, int maxSize,
        Lock lock, Condition notFull, Condition notEmpty, CountDownLatch count) {
        super(name);
        this.queue = queue;
        this.maxSize = maxSize;
        this.lock = lock;
        this.notFull = notFull;
        this.notEmpty = notEmpty;
        this.count = count;
    }

    @Override
    public void run() {
        try {
            lock.lock();
            while (count.getCount() > 0) {
                while (queue.size() == maxSize) {
                    System.out.println(TAG + "队列满了，生产者在等待消费者消费。");
                    //队列满，生产者等待
                    notFull.await();
                }
                System.out.println(TAG + " value: " + count.getCount());
                queue.add(count.getCount());
                count.countDown();
                //队列不为空，唤醒消费者
                notEmpty.signal();
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}

/**
 * 消费者线程
 */
class Consumer2 extends Thread {

    private static final String TAG = "---消费者---";

    private Queue<Long> queue;
    private Lock lock;
    private Condition notFull, notEmpty;
    private CountDownLatch count;

    public Consumer2(String name, Queue<Long> queue, Lock lock,
        Condition notFull, Condition notEmpty, CountDownLatch count) {
        super(name);
        this.queue = queue;
        this.lock = lock;
        this.notFull = notFull;
        this.notEmpty = notEmpty;
        this.count = count;
    }

    @Override public void run() {
        try {
            lock.lock();
            while (count.getCount() > 0) {
                while (queue.isEmpty()) {
                    System.out.println(TAG + "队列空了，消费者在等待生产者生产。");
                    //队列为空，消费者等待
                    notEmpty.await();
                }
                System.out.println(TAG + " value: " + queue.remove());
                //队列不为满，唤醒生产者
                notFull.signal();
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            lock.unlock();
        }
    }
}
```

我们定义了两个条件，一个是队列不为空的条件，一个是队列不为满的条件。队列为空时，消费者等待，不为空时，唤醒消费者，但是此时生产者获得了锁，故消费者无法消费（从另一种角度讲，读写互斥，不能同时进行）。队列为满时，生产者等待，不为满时，唤醒生产者，但是此时消费者获得了锁，故生产者无法生产。那是不是这样呢？看下结果：

![Condition实现生产者消费者模式结果图1](/imgs/Condition实现生产者消费者模式结果图1.png)

结果有没有符合你的预期？如果没有，请好好思考一下，相关思路我已经在上一段讲了。

**方法**

我们再看看`Condition`接口定义了什么方法：

```java
public interface Condition {

    //线程等待
    void await() throws InterruptedException;

    //线程等待，不响应中断
    void awaitUninterruptibly();

    //线程等待，如果在 nanosTimeout 时间内被唤醒，则返回已等待的时间，如果在 nanosTimeout 时间内未被唤醒，则返回负数，表示等待超时
    long awaitNanos(long nanosTimeout) throws InterruptedException;

    //线程等待规定的时间，此处的时间是时间跨度
    boolean await(long time, TimeUnit unit) throws InterruptedException;

    //线程等待到规定时间，此处的时间是截止点
    boolean awaitUntil(Date deadline) throws InterruptedException;

    //唤醒等待的线程
    void signal();

    //唤醒所有等待的线程
    void signalAll();
}
```

`Condition`接口的方法是相当简洁的，而且都是与等待和唤醒相关的方法，故使用并不复杂，而`signal`和`signalAll`方法就是`Object`的`notify`和`notifyAll`方法。不过`signal`方法和`notify`方法还是有一点区别的，**因为`Condition`的实现类（如`ConditionObject`）里通常维护着一个队列，该队列可以保证`signal`唤醒的是等待时间最长的线程。并不像`notify`，是随机唤醒线程**。

**相关类**

在上面的代码中，我们使用了`CountDownLatch`，这个类是`java.util.concurrent`包下的一个同步工具类，可以用来限制或者判断线程的执行次数和执行时长。十分有用。此处献上部分源码（方法的实现省略，只讲作用）：

```java
public class CountDownLatch {
    
    private static final class Sync extends AbstractQueuedSynchronizer {
        //AQS：队列同步器，这部分有点深入了，不符合本文使用的范围，故不讲，有兴趣的可以自行搜索。
    }

    /**
     * 此类的同步控制器。使用 AQS 状态表示计数
     */
    private final Sync sync;

    /**
     * 初始化 CountDownLatch，使用特定的计数
     * 
     * @param count 待设置的计数
     * @throws IllegalArgumentException 当计数为负时抛出
     */
    public CountDownLatch(int count) {
        //...
    }

    /**
     * 使当前线程在锁存器倒计数至零之前一直等待，除非线程被中断。
     * 
     * @throws InterruptedException 线程等待时被中断抛出
     */
    public void await() throws InterruptedException {
        //...
    }

    /**
     * 使当前线程在锁存器倒计数至零之前一直等待，
     * 除非线程被中断或超出了指定的等待时间。
     * 
     * @param timeout 等待的时间
     * @param unit 时间格式
     * @throws InterruptedException 线程等待时被中断抛出
     */
    public boolean await(long timeout, TimeUnit unit)
        throws InterruptedException {
        //...
    }

    /**
     * 递减锁存器的计数，如果计数到达零，则释放所有等待的线程。 
     */
    public void countDown() {
        //...
    }

    /**
     * 返回当前计数。 
     *
     * @return 当前的计数
     */
    public long getCount() {
        //...
    }

    /**
     * 返回标识此锁存器及其状态的字符串。
     * @return 描述此锁存器及其状态的字符串。
     */
    public String toString() {
        //...
    }
}
```

从上面各方法的解释中，我们可以知道该类的大致用法。例子就不举了，前面讲`Condition`的用法时已经用到了。

其实，`java`的`concurrent`包是个很重要的内容，我们还有一大块没有讲到，就是实现运算原子性的那个包`java.util.concurrent.atomic`。比如`AtomicInteger`，可以保证`Integer`在加1时，操作是原子操作。对于这些内容感兴趣的小伙伴，可以自行搜索，此处不做讲解。

## 线程池

### 什么是线程池？

线程池是一块内存空间，里面存放了众多(未死亡)的线程，池中线程执行调度由池管理器来管理。

### Java 的线程池框架？

话不多说，上图。

![Java线程池框架](/imgs/Java线程池框架.png)

说明：

- **Executor**：执行器接口，该接口定义执行`Runnable`任务。
- **ExecutorService**： 该接口定义提供对`Executor`的服务。
- **ScheduledExecutorService**：定时调度接口。
- **AbstractExecutorService**：执行框架抽象类。
- **ThreadPoolExecutor**：`JDK`中线程池的具体实现。
- **Executors**：线程池工厂类。

再上个详细版的框架图：

![Java线程池框架详细](/imgs/Java线程池框架详细.png)

### `Executor`接口

`Executor`是一个线程执行接口。任务执行的主要抽象不是`Thead`，而是`Executor`。

`Executor`将任务的提交过程与执行过程分离，并用`Runnable`来表示任务。源码如下：

```java
public interface Executor{
    void executor(Runnable command);
}
```

### `ExecutorService`接口

`ExecutorService`在`Executor`的基础上增加了一些方法。用来控制任务的终止与执行，是线程池接口。下面是该类的部分源码：

```java
public interface ExecutorService extends Executor {
    
    //终止方法
    void shutdown();
    List<Runnable> shutdownNow();
    boolean isShutdown();
    
    //检测任务是否执行完毕方法
    boolean isTerminated();
    boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException;

    //提交任务并执行方法
    <T> Future<T> submit(Callable<T> task);
    <T> Future<T> submit(Runnable task, T result);
    Future<?> submit(Runnable task);

    //批量处理方法
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) throws InterruptedException;
    <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) throws InterruptedException;    
    <T> T invokeAny(Collection<? extends Callable<T>> tasks) throws InterruptedException, ExecutionException;
    <T> T invokeAny(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException;
}
```

`submit`是`execute`方法的扩展，具有一个`Future`对象，该对象能够检测任务是否被取消或者是否执行完毕。另外`ExecutorService`提供了如终止线程池，批量处理等方法，是线程池接口，所有线程池在声明时都应该使用`ExecutorService`。

举例：

```java
// 单线程线程池
ExecutorService executorService1 = Executors.newSingleThreadExecutor();
// 大小为 10 的固定大小线程池
ExecutorService executorService2 = Executors.newFixedThreadPool(10);
// 周期执行的线程池
ExecutorService executorService3 = Executors.newScheduledThreadPool(10);
```

### `ScheduledExecutorService`接口

`ScheduledExecutorService`和`Timer`和`TimerTask`类似，主要用于解决那些需要任务重复执行的问题。包括延迟时间一次性执行、延迟时间周期性执行以及固定延迟时间周期性执行等。下面是改类的部分源码：

```java
public interface ScheduledExecutorService extends ExecutorService {
    // 带延迟时间的调度，只执行一次
    public ScheduledFuture<?> schedule(Runnable command, long delay, TimeUnit unit);
    // 带延迟时间的调度，只执行一次
    public <V> ScheduledFuture<V> schedule(Callable<V> callable, long delay, TimeUnit unit);
    // 带延迟时间的调度，循环执行，固定频率，相对于任务执行的开始时间
    public ScheduledFuture<?> scheduleAtFixedRate(Runnable command, long initialDelay, long period, TimeUnit unit);
    // 带延迟时间的调度，循环执行，固定延迟，相对于任务执行的结束时间
    public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command, long initialDelay, long delay, TimeUnit unit);
}
```

继承自`ExecutorService`的`ScheduledExecutorService`拥有`ExecutorService`的全部特性。

`ThreadPoolExecutor`线程池类

所有的线程池创建都是通过这个类。构造器的代码是嵌套调用，参数少的调用参数多的，比如两个参数的构造方法调用三个参数的构造方法，以此类推。参数最多为7个，该构造器代码如下：

```java
public ThreadPoolExecutor(int corePoolSize, // 核心线程数
    int maximumPoolSize, // 最大线程数
    long keepAliveTime, // 空闲线程存活时间。当线程数大于`corePoolSize`数时，
                        // 空闲时间超过该时间的线程将会被终结
    TimeUnit unit, // keepAliveTime 的单位
    BlockingQueue<Runnable> workQueue, // `Runnable`(任务)的阻塞等待队列。若线程池已经被占满，
                                       // 则该队列用于存放无法再放入线程池中的`Runnable`
    ThreadFactory threadFactory, // 在创建新线程时使用的工厂。一般用来定义线程了线程组、线程名称等信息。
                                 // 建议在使用线程池时自定义线程工厂，从而给新开的线程命名，并熟悉使用流程
    RejectedExecutionHandler handler // 线程池对拒绝任务的处理策略
) {
    if (corePoolSize < 0 || maximumPoolSize <= 0 || maximumPoolSize < corePoolSize || keepAliveTime < 0)
        throw new IllegalArgumentException();
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```

注意事项：

- 若线程池中的线程数量小于`corePoolSize`，即使线程池中的线程都处于空闲状态，也要创建新的线程，使线程池的线程数量等于`corePoolSize`。即`corePoolSize`是线程池中存在的最小线程数
- 当线程池中的线程数量大于`corePoolSize`时，如果某线程空闲时间超过`keepAliveTime`，线程将被终止
- 使用优先级：`corePoolSize`>`workQueue`>`maximumPoolSize`>`handler`，即核心线程未满，核心线程优先使用 ---> 核心线程满了，工作队列优先使用 ---> 工作队列满了，线程数量增加 ---> 线程数目达到最大值，使用拒绝策略

### `Executors`工厂方法

JDK内部提供了五种最常见的线程池。由`Executors`类的五个静态工厂方法创建。

- newSingleThreadExecutor：单线程 线程池
- newFixedThreadPool：固定大小 线程池 
- newCachedThreadPool：可缓存 线程池
- newScheduledThreadPool：定时任务调度 线程池 
- newSingleThreadScheduledExecutor：单线程、定时任务调度 线程池

让我们来一一说明。

**`newSingleThreadExecutor`单线程线程池**

该线程池中只有一个线程在工作，也就是相当于单线程串行执行所有任务。该线程池获取方法如下：

```java
// Executors 中的静态方法
public static ExecutorService newSingleThreadExecutor(ThreadFactory threadFactory) {
    return new FinalizableDelegatedExecutorService(
            new ThreadPoolExecutor(1, 1,
                                   0L, TimeUnit.MILLISECONDS,
                                   new LinkedBlockingQueue<Runnable>()));
}
```

这个方法返回单线程的`Executor`，将多个任务交给此`Exector`时，这个线程处理完一个任务后接着处理下一个`Runnable`(任务)，若该线程出现异常，将会有一个新的线程来替代。此线程池保证所有任务的执行顺序按照任务的提交顺序执行。同时`LinkedBlockingQueue`(阻塞队列)会无限的添加需要执行的`Runnable`。

**`newFixedThreadPool`固定大小线程池**

这个线程池每次提交一个任务就创建一个线程，直到线程数目达到线程池的最大值。线程池的大小一旦达到最大值就会保持不变，如果某个线程因为执行异常而结束，那么线程池会补充一个新线程。线程池的获取方法如下：

```java
// Executors 中的静态方法
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}
```

从上面的方法中可以看出，构造线程数目固定的线程池时，`corePoolSize`和`maximumPoolSize`是一样的，这样就保证了线程数目的恒定。

**`newCachedThreadPool`可缓存线程池**

如果线程池的线程数目超过了处理任务所需要的线程，那么就会回收部分空闲（60秒不执行任务）的线程，当任务数增加时，此线程池又可以智能的添加新线程来处理任务。此线程池不会对线程数目做限制，线程池大小完全依赖于操作系统（或者说`JVM`）能够创建的最大线程大小。

```java
// Executors 中的静态方法
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}
```

`SynchronousQueue`是个特殊的阻塞队列。其容量为0，即不存储内容。

当试图为`SynchronousQueue`添加`Runnable`时，执行会失败。只有当一边从`SynchronousQueue`取数据，一边向`SynchronousQueue`添加数据才可以成功。

`SynchronousQueue`仅仅起到数据交换的作用，并不保存线程。

`SynchronousQueue`保证了两个线程的同步，因为`newCachedThreadPool`的线程池大小是没有限制的，任务数目增加，就新开线程执行任务。但是如果任务到来时，线程还未增加，就没法处理任务了。这时就需要通过`SynchronousQueue`进行阻塞，等待线程的增加，线程增加后，将任务插入`SynchronousQueue`，同时新线程将任务取出，就保证了任务的执行。可以看出，`SynchronousQueue`其实是保证了线程同步。

使用`newCachedThreadPool`应该警惕的一点是，线程池数量根据用户的任务数创建相应的线程来处理，线程池不会对线程数目加以限制。数量完全依赖于`JVM`能够创建线程的数量。这样极有可能引起内存不足。导致 OOM，所以在一般编程中，`newCachedThreadPool`都是不推荐使用的。

**`newScheduledThreadPool`定时任务调度线程池**

该线程池大小无限制，支持定时以及周期性执行任务的需求。线程池的获取方法如下：

```java
// Executors 中的静态方法
public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
    return new ScheduledThreadPoolExecutor(corePoolSize);
}
```

而`ScheduledThreadPoolExecutor`的构造方法如下：

```java
public ScheduledThreadPoolExecutor(int corePoolSize) {
     super(corePoolSize, Integer.MAX_VALUE,
           DEFAULT_KEEPALIVE_MILLIS, MILLISECONDS,
           new DelayedWorkQueue());
}
```

从方法中可以看出，最大的线程池数量是`Integer.MAX_VALUE`，可被认为是大小无限制的。

如果打算做定时或者定周期的任务，建议使用`ScheduledThreadPoolExecutor`。此线程池可以代替`Timer`和`TimerTask`，后两者是`Java`中传统的定时器，存在诸多弊端，不建议使用。


**`newSingleThreadScheduledExecutor`单线程定时任务调度线程池**

此线程池和 `ScheduledThreadPoolExecutor`类似，获取方法如下：

```java
// DelegatedScheduledExecutorService 类作为代理类，作用是只暴露 ScheduledExecutorService 的方法，不暴露其他方法
public static ScheduledExecutorService newSingleThreadScheduledExecutor() {
    return new DelegatedScheduledExecutorService(
        new ScheduledThreadPoolExecutor(1));
}
```

### 总结

讲解了那么多类，下面让我们来总结下各个类的作用：

- Runnable/Callable：要在线程池中执行的任务
- Thread：执行任务的线程
- ThreadPool：包含线程的线程池
- Executor：线程任务执行接口
- ExecutorService：线程池执行任务的类
- Executors：创造线程池的工厂类，恰当的命名应该类似与`ExecutorFactory`

用杀猪来做个更形象的比喻：`Executors`可以用来获取杀猪房(`ThreadPool`)。`Thread`就是杀猪房里的屠夫。屠夫怎么工作，由杀猪房管理。`Runnable/Callable`就是被杀的猪，有正在杀的猪(执行中的任务)，有等着被杀的猪(等待中的任务)。`Executor`就是杀猪的工具，我们可以药杀、宰杀、电杀等等。而`ExecutorService`就相当于杀猪房的管理者，他可以决定杀猪房里的猪什么时候被杀，取消杀猪等等。很多时候，我们只负责把猪送进杀猪房，猪什么时候被杀，怎么被杀，我们不关心。我们只需要知道猪被杀了的结果，并拿到猪肉就可以了。

### 举例

讲了这么多，举个简单的例子了。

```java
public class JavaThreadPool {
    public static void main(String[] args) {
        // 创建一个固定线程数的线程池
        ExecutorService pool = Executors.newFixedThreadPool(2);
        // 创建实现了Runnable接口对象，Thread对象当然也实现了Runnable接口
        Thread t1 = new MyThread();
        Thread t2 = new MyThread();
        Thread t3 = new MyThread();
        Thread t4 = new MyThread();
        Thread t5 = new MyThread();
        // 将线程放入池中进行执行
        pool.execute(t1);
        pool.execute(t2);
        pool.execute(t3);
        pool.execute(t4);
        pool.execute(t5);
        // 关闭线程池
        pool.shutdown();
        if(pool.isShutdown()) {
            System.out.println("Nice!");
        }
    }
}

class MyThread extends Thread {
    @Override
    public void run() {
        System.out.println(Thread.currentThread().getName() + "正在执行。。。");
    }
}
```

### 线程池生命周期

线程池的状态大致可以分为以下四种：启动、执行、关闭、终止。控制线程池声明周期的方法主要是在`ExecutorService`接口中定义的。

- **启动：**线程池在`new`操作执行后就正式启动完成了。
- **执行：**线程池正在处理新任务，并接受新任务的到来。此时任务处于**RUNNING**状态。
- **关闭：**通过`shutdown()`和`shutdownNow()`触发。前者不再接受新任务，但是仍然会执行已提交正在执行的任务，包括那些进入队列还没有开始的任务，此时线程池处于**SHUTDOWN**状态；后者停止接受新的任务，并取消所有执行的任务和已经进入队列但是还没有执行的任务，此时线程池处于**STOP**状态。注意：关闭线程池可能会失败，得进行判断(`isShutdown()`)，并定义相关的处理机制。
- **终止：**一旦shutdown()或者shutdownNow()执行完毕，线程池就进入TERMINATED状态，即线程池就结束了。

### Java线程池扩展

**线程池的执行监控**

ThreadPoolExecutor中定义了三个空方法，用于监控线程的执行情况。

```java
protected void beforeExecute(Thread t, Runnable r) { }
protected void afterExecute(Runnable r, Throwable t) { }
protected void terminated() { }
```

如果想要监控线程的执行情况，可以自定义线程池实现类。

```java
// 自定义线程池
public class CustomFixedThreadPool {
    public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
            0L, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>()){

            @Override protected void beforeExecute(Thread t, Runnable r) {
                System.out.println("准备执行:" + ((MyTask)r).name);
            }

            @Override protected void afterExecute(Runnable r, Throwable t) {
                System.out.println("执行完成:" + ((MyTask)r).name);
            }

            @Override protected void terminated() {
                System.out.println("退出执行");
            }
        };
    }
}
// 测试
public class ThreadPoolTest {
    
    static class MyTask implements Runnable {
        public String name;    
        public MyTask(String name) {
            super();
            this.name = name;
        }
        
        @Override
        public void run() {
            try {
                Thread.sleep(500);
                System.out.println("执行中:"+this.name);
                Thread.sleep(500);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
    
    public static void main(String[] args) {
	ExecutorService es = CustomFixedThreadPool.newFixedThreadPool(5);
        for(int i=0;i<5;i++){
            MyTask task = new MyTask("Task - " + i);
            es.execute(task);
        }
        es.shutdown();
        if(es.isShutdown()) {
            System.out.println("Nice!");
        }
    }
}
```

**ThreadPoolExecutor的拒绝策略**

如果线程池中需要执行的任务过多，线程池对于某些任务就无法处理了。此时拒绝策略可以对这些无法处理的任务进行处理。可能丢弃掉，也可能用其他方式。

上面提到过，`ThreadPoolExecutor`类的构造方法中有一个`RejectedExecutionHandler`，用于定义拒绝策略。 其实JDK提供了一些内置的拒绝策略。如下图：

![线程池内置拒绝策略](/imgs/线程池内置拒绝策略.png)

除了上述策略之外，我们还可以自定义拒绝策略。

```java
public class RejectedPolicyHandleTest {
    public static void main(String[] args) {
    
    ExecutorService es = new ThreadPoolExecutor(5, 5, 0, TimeUnit.MILLISECONDS, new SynchronousQueue<Runnable>(), 
        Executors.defaultThreadFactory(), new RejectedExecutionHandler() {
            
            @Override
            public void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
                //实现自己的拒绝策略
            }
        }); 
        es.shutdown();
        if(es.isShutdown()) {
            System.out.println("Nice!");
        }
    }
}
```

Java 多线程暂时就讲这么多，Java 多线程涉及到的东西太多了。一本书都讲不完，更多的内容可上网搜索。本文仅仅是作为一个基础普及文，有不对的地方，请斧正，不胜感激。