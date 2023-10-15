---
title: "Java 反射"
description: "本文讲解了 Java 反射的知识"
keywords: "Java,反射"

date: 2020-02-11 14:07:00 +08:00
lastmod: 2020-02-11 14:07:00 +08:00

categories:
  - Java
tags:
  - 反射
  - Java

url: post/AF8917A624AB46D1807D4ED95479F799.html
toc: true
---

**本文主要讲解 Java 反射相关的基本知识**

<!--More-->

## 概念

相信每个 Java 语言攻城狮都或多或少听说过反射的概念。反射可以说是Java中最强大的技术了。JAVA反射机制是指在**运行状态(运行时)**中，动态获取信息以及动态调用对象方法的功能。

在 Java 中，通过类加载器和类路径可以唯一确定一个类。通过添加数据、指定实例名等方式，我们可以唯一确定一个类实例；我们可以把这个过程叫做映射。那么反过来，我们是否可以通过类名或者类实例去获取方法、属性、类路径等信息呢？答案当然是可以了。这就是反射。从逻辑上讲，映射和反射就是对立的两个概念，映射是实例映射类的过程，反射是类映射实例的过程

反射包含以下两个关键点：

- 对于任意一个类，都能够知道这个类的所有属性和方法；
- 对于任意一个对象，都能够调用它的任意方法和属性

简单来说反射就是解剖一个类，然后获取这个类中的属性和方法。前提是要获取这个类的Class对象。

## 构成基础

Java 语言的反射机制，依赖于 Class 类和 java.lang.reflect 类库。其主要的类如下：

- Class：表示类或者接口
- Field：表示类中的成员变量
- Method：表示类中的方法
- Constructor：表示类的构造方法
- Array：该类提供了动态创建数组和访问数组元素的静态方法

## Class 类

Class 类是 Java 中用来表示运行时类型信息的对应类。在 Java 中，每个类都有一个 Class 对象，当我们编写并且编译一个新创建的类，相关信息就会被写到 .class 文件里。当我们 **new 一个新对象**或者**引用静态成员变量**时，JVM 中的类加载器子系统便会将对应 Class 对象加载到 JVM 中。我们可以将 Class 类称为类类型，Class 对象称为类类型对象。

Class 类有以下的特点：

- Class 类是类，class 则是 Java 语言保留的关键字。
- Class 类只有一个私有的构造函数，只有 JVM 能够创建 Class 类的实例。
- 对于**同一个类(包名 + 类名相同，且由同一个类加载器加载)**的所有对象，在 JVM 中只有唯一一个对应的 Class 类实例来描述其类型信息。

.class 文件存储了一个 Class 的所有信息，比如所有的方法，所有的构造函数，所有的字段（成员属性）等等。JVM 启动的时候通过 .class 文件会将相关的类加载到内存中。

在上面的描述的基础上，我们便可以得到一个类的所有信息了。首先，让我们获取类的实例对象。有三种方法：

**forName 方法**

可以通过 `Class.forName` 方法获取类的实例：

```java
// 获取 String 类的实例
Class<String> clazz = Class.forName("java.lang.String");
```

**getClass 方法**

另外，我们也可以通过 `Object.getClass` 这个实例方法来获取类的实例。

```java
Class<String> clazz1 = "a".getClass();
// 数组对象的 getClass 方法
Class clazz2 = (new byte[1024]).getClass();
```

**使用 class 关键字**

还有一种方法是使用 class 关键字：

```java
// 类
Class clazz1 = Integer.class;
// 数组
Class clazz2 = int [][].class;
```

**使用 TYPE 属性**

另外，对于 Java 中定义的基本类型和 void 关键字，都有对应的包装类。在包装类中有一个静态属性 TYPE，保存了该包装类的类类型。如 Integer 类中定义的 TYPE：

```java
public static final Class<Integer> TYPE = (Class<Integer>) Class.getPrimitiveClass("int");
```

我们可以使用 TYPE 属性获取类对象，语法如下：

```java
Class clazz1 = Integer.TYPE;
Class clazz2 = Void.TYPE;
```

Java 的基本类型包括：boolean、byte、char、short、int、long、float、double。外加一个 void，可以用 TYPE 获取类对象。

在获取到了类的实例对象后，我们便可以获取其中存储的信息了。在这之前，我们先讲一下 AccessibleObject。

## AccessibleObject

AccessibleObject 是 Field、Method、Constructor 三个类共同继承的父类，它提供了将反射的对象标记为，在使用时取消默认 Java 语言访问控制检查的能力。并且 AccessibleObject 实现了 AnnotatedElement 接口，提供了与获取注解相关的能力。这句话有点绕。举个例子。类 A 有一个私有成员 test(声明为 private)。类 B 是不能访问的，但是通过 AccessibleObject 提供的方法，我们却可以将 `A.test` 属性的限制范围设置为可访问，这样我们便能在 B 类中访问 `A.test` 属性了。

```java
public class A {
    private int test = 1;
}

public class B {
    public void getTest() {
        A a = new A();
        // 获取类对象
        Class clazz = a.getClass();
        // 改变修饰符
        clazz.getField("test").setAccessible(true);
        // 获取 test 属性的值，此处 getInt 仍然需要传入 Object 实例，原因后面解释
        System.out.println(clazz.getField("test").getInt(a));
    }
}
```

在讲了 AccessibleObject 类，我们来看看反射机制中我们经常用过的类。

## Field

Field 提供了有关类或接口的单个属性的信息，以及对它的动态访问的能力。

**动态访问**

对于类的某些属性，其修饰符是使用 private，外部是无法访问的，但是通过 Field 的 setAccessible 方法，我们便可以访问到这些属性。例子在上面已经列举到了，此处就不列举了。

下面来看看我们经常用到的一些方法：

| 方法名                                                       | 作用                                                  |
| :----------------------------------------------------------- | :---------------------------------------------------- |
| getFields() &emsp;&emsp;                                     | 获取类中public类型的属性 &emsp;&emsp;                 |
| getDeclaredFields() &emsp;&emsp;                             | 获取类中所有的属性，但不包括继承的属性 &emsp;&emsp;   |
| getField(String name) &emsp;&emsp;                           | 获取类中名称为 name 的属性 &emsp;&emsp;               |
| getType() &emsp;&emsp;                                       | 返回变量的类类型，返回值是 Class &emsp;&emsp;         |
| getGenericType() &emsp;&emsp;                                | 返回变量的类型，返回值是 Type &emsp;&emsp;            |
| isEnumConstant() &emsp;&emsp;                                | 判断当前变量是否是枚举类 &emsp;&emsp;                 |
| getModifiers() &emsp;&emsp;                                  | 以整数形式，返回此对象的 Java 语言修饰符 &emsp;&emsp; |
| getName() &emsp;&emsp;                                       | 获取属性的名字 &emsp;&emsp;                           |
| get(Object obj) &emsp;&emsp;                                 | 返回指定对象 obj 上此 Field 的值 &emsp;&emsp;         |
| set(Object obj, Object value) &emsp;&emsp;                   | 将指定对象的此 Field 设置为指定的新值 &emsp;&emsp;    |
| isAnnotationPresent(Class<? extends Annotation> annotationClass) &emsp;&emsp; | 判断是否有指定的注解 &emsp;&emsp;                     |

下面，让我们来一一举例。首先，我们定义一个类，包含一些必要的数据：

```java
public class TestField {
    // a、是 public 的，b 是 protected 的，c、d 是 private 的。其中 d 是 static 的
    public String a = "a";
    protected int b = 2;
    private String c = "c";
    private static String d = "d";
}

public class TestField2 extends TestField {
    public int e = 1;
    private int f = 2;
}
```

**getFields 方法和 getName 方法**

然后，让我们来测试下获取字段和打印名字的方法：

```java
public static void main(String[] args) {
    TestField testField = new TestField();
    Class clazz1 = testField.getClass();
    Field[] fields1 = clazz1.getFields();
    // 打印属性名
    // 结果是 a，说明 getFields 只会获取声明为 public 的属性
    for (Field f : fields1) {
        System.out.print(f.getName() + " ");
    }
}
```

让我们加入继承关系，将 TestField 类改为 TestField2 类，其余代码保持不变：

```java
public static void main(String[] args) {
    TestField2 testField = new TestField2();
    ...
}
```

得到的结果是 e、a，说明** getFields 方法可以获取从父类继承来的公共属性**。

**getDeclaredFields 方法**

在上面的基础上，我们来看看 getDeclaredFields 方法，我们保持 TestField2 类不变，改变 Field 的获取方式：

```java
public static void main(String[] args) {
    ...
    Field[] fields1 = clazz1.getDeclaredFields();
    ...
}
```

最后打印出来的结果是 `e f`，说明不管修饰符是什么，属性都可以被获取到，但是从父类继承来的变量不能被获取。

**getField(String name) 和 getDeclaredField(String name) 方法**

从上面的代码中可以看出，一个类的属性可以不只有一个，所以可以指定名称，获取到特定的变量，参数应该是类中有的属性的名称。这两个方法的作用范围和上面举例的几个方法一样。此处就不再重复举例了。

**Field.getType() 和 Field.getGenericType() 方法**

默认情况下，这两个的返回值是一样的。但是如果有签名，两者的返回值可能就不一样了。

```java
public static void main(String[] args) {
        ...
        System.out.print(clazz1.getField("a").getType() + " ");
        ...
}
```

上面的代码，执行结果会输出 a 属性的类型，为 `class java.lang.String`

**Field.getModifiers() 方法**

此方法返回的是一个整型值，其代表意义可以查看 Modifier 这个类，该类在 JDK 的反射包下，定义了所有可用整型值代表的意思。此处举几个简单的例子：

```java
public class Modifier {
    ...
    // 整型值这么定义是为了方便位运算，在求取修饰符的整型值时，会使用下面的值进行或运算。

    // 被 public 修饰，会返回该整型值
    public static final int PUBLIC           = 0x00000001;
    // 被 private 修饰，会返回该整型值
    public static final int PRIVATE          = 0x00000002;
    // 被 protected 修饰，会返回该整型值
    public static final int PROTECTED        = 0x00000004;
    // 被 static 修饰，会返回该整型值
    public static final int STATIC           = 0x00000008;
    // 被 final 修饰，会返回该整型值
    public static final int FINAL            = 0x00000010;
    // 被 synchronized 修饰，会返回该整型值
    public static final int SYNCHRONIZED     = 0x00000020;
    // 被 volatile 修饰，会返回该整型值
    public static final int VOLATILE         = 0x00000040;
    // 被 transient 修饰，会返回该整型值
    public static final int TRANSIENT        = 0x00000080;
    // 被 native 修饰，会返回该整型值
    public static final int NATIVE           = 0x00000100;
    // 被 interface 修饰，会返回该整型值
    public static final int INTERFACE        = 0x00000200;
    // 被 abstract 修饰，会返回该整型值    
    public static final int ABSTRACT         = 0x00000400;
    // 被 strictfp 修饰，会返回该整型值
    public static final int STRICT           = 0x00000800;
    
    ...
}
```

举例说明，在，第一段代码的基础上，获取属性 d 的修饰符。d 是使用 private static 修饰的：

```java
public static void main(String[] args) {
    // 输出结果 10
    System.out.println(clazz1.getDeclaredField("d").getModifiers());
}
```

上面的输出结果是 10，而在 Modifier 类中，private 的值是 2(二进制0010)，static 的值是 8(二进制1000)，0010 | 1000 = 1010。二进制换成10进制，刚好等于 10。

**Field.get(Object obj) 方法**

这个方法会得到某个对象的该属性的值。

在此之前，让我们看段代码：

```java
public static void main(String[] args) {
    TestField testField1 = new TestField();
    TestField testField2 = new TestField();

    Class clazz1 = testField1.getClass();
    Class clazz2 = testField2.getClass();
    // 输出的结果为：true
    System.out.println(clazz1 == clazz2);
}
```

上面的代码输出的最终结果为 true，说明两个对象拿到的 Class 对象是同一个。可以理解为某一个类的 Class 对象是单例。

现在，让我们讲讲 get 方法。为什么我们要传入实例对象作为参数呢？就是为了明确，是为了得到哪一个对象的此属性值。因为在更多的场景下，同一个类的相同属性可能有不同的值，比如 Student 类有一个 name 属性，张三的 name 是张三，李四的 name 是李四。这样，同样是name，值却不一样。这便是使用 Field.get(Object obj) 时需要传入 obj 的原因。

同样的，set(Object obj, Object value) 方法也是一样的逻辑。

## Method

Method 代表了一个类所具有的方法，下面是 Method 类中用到的一些常用方法。

| 方法名                                          | 作用                                                  |
| :---------------------------------------------- | :---------------------------------------------------- |
| getReturnType() &emsp;&emsp;                    | 获取方法的返回类型 &emsp;&emsp;                       |
| getParameterTypes() &emsp;&emsp;                | 获取方法中参数的类型 &emsp;&emsp;                     |
| getParameterCount() &emsp;&emsp;                | 获取方法中参数的数量&emsp;&emsp;                      |
| getExceptionTypes() &emsp;&emsp;                | 获取方法抛出的异常 &emsp;&emsp;                       |
| invoke(Object obj, Object... args) &emsp;&emsp; | 执行指定对象的该方法 &emsp;&emsp;                     |
| isDefault() &emsp;&emsp;                        | 判断方法是否是被 default 修饰的方法 &emsp;&emsp;      |
| getModifiers() &emsp;&emsp;                     | 以整数形式，返回此对象的 Java 语言修饰符 &emsp;&emsp; |
| getName() &emsp;&emsp;                          | 获取方法的名字 &emsp;&emsp;                           |
| getDefaultValue(Object obj) &emsp;&emsp;        | 获取声明的默认值 &emsp;&emsp;                         |
| getDeclaredAnnotations()                        | 获取修饰方法的所有注解 &emsp;&emsp;                   |

同样的，我们根据例子来说明。

首先，我们改造一下 TestField 类，定义几个方法，其中有静态方法，有参无参方法，有无返回值的方法：

```java
public class TestField {
    public void m1() { }
    
    public void m1(int a, int b) { }

    private int m2(int a, int b) { return a + b; }
    
    public static void sm3() { }
}
```

**getReturnType 和 getParameterTypes 方法**

写的测试代码如下：

```java
public static void main(String[] args) {
    TestField testField1 = new TestField();

    Class clazz1 = testField1.getClass();

    try {
        Method m1 = clazz1.getMethod("m1", new Class[]{int.class, int.class});
        // 获取方法需要传入参数类型
        Class[] parameterizedType1 = m1.getParameterTypes();
        // 获取返回类
        System.out.println(m1.getReturnType());
        // 此处不会输出结果，因为是空数组
        for(Class c : parameterizedType1) {
            System.out.println(c.getName());
        }
        Method m2 = clazz1.getMethod("m1", new Class[0]);
        Class[] parameterizedType2 = m2.getParameterTypes();
        System.out.println(m2.getReturnType());
        for(Class c : parameterizedType2) {
            System.out.println(c.getName());
        }
    } catch (NoSuchMethodException e) {
        e.printStackTrace();
    }
}
```

最终的输出结果为：void、int int、void

上面获取 Method 实例时，需要传入参数类型。为什么呢？因为**一个类中可能有许多同名方法，需要用参数来进行区分。**

更多的方法使用和 Field 的用法一致。此处就不细讲了。

## Constructor

常用方法汇总：

| 方法名                                        | 作用                                                         |
| :-------------------------------------------- | :----------------------------------------------------------- |
| isVarArgs() &emsp;&emsp;                      | 判断构造器的参数是否是可变长度的。即构造器的参数一个或所有被...声明 &emsp;&emsp; |
| getParameterTypes() &emsp;&emsp;              | 获取方法中参数的类型 &emsp;&emsp;                            |
| getParameterCount() &emsp;&emsp;              | 获取方法中参数的数量&emsp;&emsp;                             |
| getExceptionTypes() &emsp;&emsp;              | 获取方法抛出的异常 &emsp;&emsp;                              |
| newInstance(Object ... initargs) &emsp;&emsp; | 该方法用于构造新实例 &emsp;&emsp;                            |
| getModifiers() &emsp;&emsp;                   | 以整数形式，返回此对象的 Java 语言修饰符 &emsp;&emsp;        |
| getName() &emsp;&emsp;                        | 获取方法的名字 &emsp;&emsp;                                  |
| getDeclaredAnnotations()                      | 获取修饰方法的所有注解 &emsp;&emsp;                          |

现在，让我们讲讲构造器。按照管理，先上代码。此处我们定义了两个不同参数的构造器，一个共有，一个私有：

```java
public class TestField {
    private int a;
    
    public TestField() {
        a = 1;
    }
    
    private TestField(int a) {
        this.a = a;
    }
}
```

然后，我们来进行使用。先获取无参的构造器，然后将其当作有参的构造器使用：

```java
public static void main(String[] args) {
        TestField testField1 = new TestField();

        Class clazz1 = testField1.getClass();

        try {
            Constructor c1 = clazz1.getConstructor(new Class[0]);
            c1.newInstance(new Object[]{2});
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
```

上面的使用便报错了，报的是参数非法错误：IllegalArgumentException。首先，我们知道，一个类可以有很多个构造器，它们以参数区分。上面的例子拿的无参的构造器，却当作有参的使用，肯定报错。这也就是说，**拿到的构造器的参数列表，必须和构造新实例时的参数列表完全一致**。另外，上面的 `newInstance` 方法便是构造器类的核心方法，用于创建新的实例。

另外，让我们做下实验，看能否获取到非 public 的构造器，从 private protected public 三者中测试。关键代码改成下面的代码，分别更改上面定义的类的单参构造器的访问级别。

```java
try {
    Constructor c1 = clazz1.getConstructor(new Class[]{int.class});
    c1.newInstance(new Object[]{2});
} catch (Exception e) {
    e.printStackTrace();
}
```

经过测试，发现**只能获取 public 级别的构造器，私有的和受保护的都不能**。获取私有的和受保护的构造器会报没有此方法错误：NoSuchMethodException。

至此，反射框架中的几个主要类也讲完了。接下来便是各种应用了。

## 动态工厂

工厂模式就不详讲了。此处讲一个动态工厂模式。采用反射的方式。采用这种方式可以省去很多代码，尤其是像 if、switch 这种分支判断代码。

首先，我们定义一个基础的业务父类(也可以是接口)：

```java
public abstract class BaseService {
    protected Context context;

    public BaseService(Context context) {
        this.context = context;
    }
}
```

然后，我们定义一个工厂类，用于获取服务类实例。获取的过程是动态的：

```java
public class ServiceFactory {
    // 定义一个实例缓存
    private final static ConcurrentHashMap<String, BaseService> hashMap = new ConcurrentHashMap<>();

    // 定义获取服务的方法
    public synchronized static <T> T getService(Context context, Class<? extends BaseService> serviceClass) {
        // 定义服务类实例
        BaseService baseService;
            
        baseService = hashMap.get(serviceClass.getName());

        if (baseService == null) {
            try {
                // 传入对应的参数类型列表，获取构造器，getDeclaredConstructor 可以获取私有的构造器
                Constructor<? extends BaseService> constructor = serviceClass.getDeclaredConstructor(Context.class);
                constructor.setAccessible(true);
                baseService = constructor.newInstance(context);
                putService(businessService);
            } catch (Throwable e) {
                throw new RuntimeException("get the service failed:" + serviceClass.getSimpleName(), e);
            }
        }

        return (T) baseService;
    }

    // 缓存服务类实例
    private static void putService(BaseService baseService) {
        String clsName = baseService.getClass().getName();

        if (!hashMap.containsKey(clsName)) {
            hashMap.put(clsName, baseService);
        }
    }    
    
    // 清除缓存
    public static void clear() {
        hashMap.clear();
        System.gc();
        Runtime.getRuntime().runFinalization();
    }
}
```

然后，我们就可以动态创建自己业务上的服务类了。

首先需要定义构造器，然后定义获取实例的方法。

```java
public class TesterviceImpl extends BaseService {
    private static final String TAG = "TesterviceImpl";
    
    // 只能通过此方法获取实例，构造器是私有的
    public static TesterviceImpl getInstance(Context context) {
        return ServiceFactory.getService(context, TesterviceImpl.class);
    }
    // 私有的构造器，防止调用构造器创建新实例
    private TesterviceImpl(Context context) {
        super(context);
    }

    // ---------------------------下面便是业务方法------------------------------
    public void a() {}
    ...
}
```

最后便可以通过类似 `TesterviceImpl getInstance(context).a()` 的代码获取实例并调用类里面的方法了。