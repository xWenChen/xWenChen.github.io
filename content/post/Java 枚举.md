---
title: "Java 枚举"
description: "本文讲解了 Java 枚举的知识"
keywords: "Java,枚举"

date: 2020-02-07 15:49:00 +08:00
lastmod: 2020-02-07 15:49:00 +08:00

categories:
  - Java
tags:
  - 枚举
  - Java

url: post/7C235B0D830448A8964AF8A9F4278C59.html
toc: true
---

**本文主要讲解 Java 枚举相关的基本知识**

<!--More-->

## 概念

枚举的作用是定义一个取值范围，在该取值范围内取值，取值方式有以下特点：

- 取值只能在枚举定义的范围内进行。
- 范围内的所有值，彼此之间不能重复，每个值都具有唯一性。
- 取值可以取范围内定义的任意一个值。

Java 中的枚举是在 1.5 中加入，使用关键字 enum 标记，全称是 enumeration，其对应的类是 Enum 类。创建 enum 时，编译器会为你生成一个相关的类，这个类继承自 `java.lang.Enum`。

## 定义

枚举的定义是使用关键字 enum 进行定义的。如下：

```java
public enum Sex {
    MALE("male"), FEMALE("female"), UNKNOWN("unknown");

    /**
     * 构造方法默认是私有的
     * */
    Sex(String sexDescription) {
        this.sexDescription = sexDescription;
    }

    @Override 
    public String toString() {
        return "Sex Array: " + values();
    }
}
```

定义的枚举值，枚举值默认为从0开始的有序数值。即上面定义的枚举中，MALE == 0，FEMALE == 1，UNKNOWN == 2。

事实上，enum是一种受限制的类，并且具有自己的方法。让我们先来看看枚举有哪些常用方法：

| 方法名                                            | 返回类型                       | 方法说明                                            |
| :------------------------------------------------ | :----------------------------- | :-------------------------------------------------- |
| compareTo(E o) &emsp;&emsp;                       | int &emsp;&emsp;               | 比较与指定对象的顺序                                |
| equals(Object other) &emsp;&emsp;                 | boolean &emsp;&emsp;           | 比较与指定对象是否相等                              |
| getDeclaringClass() &emsp;&emsp;                  | Class<?> &emsp;&emsp;          | 获取枚举常量对应的 Class 对象                       |
| name() &emsp;&emsp;                               | String &emsp;&emsp;            | 返回此枚举常量的名称。方法被声明为final，不可被重写 |
| toString() &emsp;&emsp;                           | String &emsp;&emsp;            | 返回此枚举常量的描述                                |
| valueOf(Class enumType, String name) &emsp;&emsp; | T<T extends Enum> &emsp;&emsp; | 静态方法，返回指定类型的枚举常量。                  |
| valus() &emsp;&emsp;                              | static T[] &emsp;&emsp;        | 静态方法，返回枚举常量中的声明                      |

默认情况下，`name` 和 `toString` 方法都可以用来获取枚举常量的声明名字，但是二者的使用还是有所区别，具体的使用形式如下(以下文字摘自StackOverflow)：

这实际上取决于你想要对返回值做什么：

- 如果您需要获取用于声明枚举常量的确切名称，则应使用 `name()`，因为 `name` 方法被声明成了 final，不可被重写。二是因为 `toString` 方法可能已被覆盖。
- 如果您想以用户友好的方式打印枚举常量，您应该使用可以被重写的 `toString` 方法。

如果觉得使用 `name` 或者 `toString` 仍然有困惑，则可以自定义一个如 `getXXXDescription()` 的带有说明性质的方法。

**方法**

让我们来看看相关方法的使用：

```java
public class Main {
    public static void main(String[] args) {
        Sex male = Sex.MALE;
        // 比较大小，小于目标，返回负值(不一定为 -1)；大于目标，返回正值；等于目标，返回 0
        int sortSubtraction = male.compareTo(Sex.UNKNOWN);
        // 返回枚举实例的值，像 valueOf、values 等是静态方法，不能用在枚举实例上
        int value = male.ordinal();
        // 获取枚举实例的名字，此处返回的是：male
        String name = male.name();
        // 获取 Sex 中定义的所有枚举实例
        Sex[] sexs = Sex.values();
        // 获取女性性别
        Sex female = Sex.valueOf("female");
    }
}
```
**抽象方法**

枚举可以继承自 Enum 类，但是 Enum 类中的方法除了 toString 以外，其他的都被声明为了 final。所以即使我们继承了 Enum，也只能重写 toString 方法。但是，在枚举中，我们可以定义抽象方法，自己实现，如下：

```java
public enum EnumDemo {
    // 实现方法后，必须加分号，故建议在 enum 中还是形成加分号的习惯
    FIRST {
        @Override public String getInfo() {
            return "first";
        }
    },
    SECOND {
        @Override public String getInfo() {
            return "second";
        }
    };

    /**
     * 抽象方法，需要被重写
     * */
    public abstract String getInfo();
}
```

**实现接口**

上面定义了两个枚举实例都实现了抽象方法。另外，enum 也可以实现接口，如下：

```java
interface I {
    void doSth();
}

public enum EnumDemo2 implements I{
    ONE;
    public void doSth() {
        // 实现接口中的方法
    }
}
```

注意：enum 不能继承类，因为所有的类都继承自 Enum 类，Java 不允许多重继承。

**使用 switch 语句**

```java
public void getTrafficInstruct(Sex sex) {
    switch (sex) {
        case MALE:
            ...
            break;
        case FEMALE:
            ...
            break;
        default:
            ...
            break;
    }
}
```

## EnumSet 枚举集合

EnumSet 是一个专为枚举设计的集合类，EnumSet中的所有元素都必须是指定枚举类型的枚举值。其有以下一些特点：

- EnumSet 方法是个抽象类，无暴露出来的构造器，不能通过new关键字创建，只能通过其他的方法创建。创建的结果是 EnumSet 的子类。
- EnumSet 集合不允许加入 null 元素，如果试图插入 null 元素，EnumSet 将抛出 NullPointerException 异常。
- EnumSet 的集合元素是有序的，EnumSet 以枚举值在 Enum 类内的定义顺序来决定集合元素的顺序。
- EnumSet 在内部以位向量的形式存储，这种存储形式非常紧凑、高效。因此EnumSet对象占用内存很小，运行效率很好。

EnumSet 中的常用方法介绍：

| 方法名                                    | 返回类型                | 方法说明                                                     |
| :---------------------------------------- | :---------------------- | :----------------------------------------------------------- |
| allOf(Class<E> elementType) &emsp;&emsp;  | EnumSet<E> &emsp;&emsp; | 静态方法，将一个枚举包含的所有枚举值添加到新的集合中         |
| of(E e) &emsp;&emsp;                      | EnumSet<E> &emsp;&emsp; | 静态方法，根据指定的枚举值创建 EnumSet，of 方法有许多同名方法，可以传入不同数量的参数 |
| noneOf(Class<E> elementType) &emsp;&emsp; | EnumSet<E> &emsp;&emsp; | 静态方法，创建一个不包含任何枚举值的 EnumSet                 |
| retainAll(Collection<?> c) &emsp;&emsp;   | boolean &emsp;&emsp;    | 移除当前集合中所有不在 c 中的元素，即求当前 EnumSet 和 c 的交集 |
| containsAll(Collection<?> c) &emsp;&emsp; | boolean &emsp;&emsp;    | 判断当前 EnumSet 是否包含所有 c 中的元素                     |

下面，让我们实际来用用这些方法。

首先，定义一个枚举类：

```java
// 一周的枚举类
public enum Day {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY;
}

// 工作人员类
public class Worker {
    // 工作人员的姓名
    String name;
    // 工作人员哪几天在上班
    Set<Day> availableDays;

    public Worker(String name, Set<Day> availableDays) {
        this.name = name;
        this.availableDays = availableDays;
    }
}
```

想象一个场景，在一些工作中，比如医生、客服，不是每个工作人员每天都在的。每个人可工作的时间是不一样的，比如张三可能是周一和周三，李四可能是周四和周六。现在，我们有一些问题需要回答：

- 有没有哪天一个人都不会来？
- 有哪些天至少会有一个人来？
- 有哪些天至少会有两个人来？
- 有哪些天所有人都会来，以便开会？
- 哪些人周一和周二都会来？

现在，我们便来回答上面的问题：

1. 首先，我们需要构建几个工作人员：
```java
// of 方法有不同参数数量的重载方法
new Worker("张三", EnumSet.of(Day.MONDAY, Day.TUESDAY, Day.WEDNESDAY)),
new Worker("李四", EnumSet.of(Day.TUESDAY, Day.THURSDAY, Day.SATURDAY)),
new Worker("王五", EnumSet.of(Day.TUESDAY, Day.THURSDAY))
```

2. 开始解决问题：
```java
/**
 * 解决问题：哪些天一个人都不会来？
 * */
private void noneOfPeopleCome() {
    // 定义一个包含所有日期的集合
    Set<Day> days = EnumSet.allOf(Day.class);
    // 排除掉不来人的日子
    for(Worker w : workers){
         days.removeAll(w.getAvailableDays());
    }
    
    System.out.println(days);
}

/**
 * 解决问题：有哪些天至少会有一个人来？这是求工作人员工作日子的并集
 * */
private void atLeastOnePeopleCome() {
    // 先创建一个空集合
    Set<Day> days = EnumSet.noneOf(Day.class);
    // 开始添加日子，集合的特性保证了不会有重复的元素被添加
    for(Worker w : workers){
         days.addAll(w.getAvailableDays());
    }
    
    System.out.println(days);
}

/**
 * 解决问题：有哪些天所有人都会来？这是求工作人员工作日子的交集
 * */
private void allPeopleCome() {
    // 拿到所有工作日子
    Set<Day> days = EnumSet.allOf(Day.class);
    for(Worker w : workers){
        // 求交集，保留所有在 w 中的枚举元素，如果二者不存在交叉，则 days 变为空
         days.retainAll(w.getAvailableDays());
    }
    
    System.out.println(days);
}

/**
 * 解决问题：哪些人周一和周二都会来？
 * */
private void specificDayPeopleCome() {
    // 对象从日子变成了人
    Set<Worker> availableWorkers = new HashSet<>();
    for(Worker w : workers){
         if(w.getAvailableDays().containsAll(EnumSet.of(Day.MONDAY,Day.TUESDAY))){
             availableWorkers.add(w);
         }
    }
    
    // 输出结果
    for(Worker w : availableWorkers){
         System.out.println(w.getName());
    }
}
```

至此，我想 EnumSet 的大概用法已经讲的差不多了。

## EnumMap 枚举字典

EnumMap 类继承自 AbstractMap 抽象类，在 EnumMap 对相应方法做了特别的实现。**保证 key 为枚举类型，并且键值对按照枚举类定义的顺序有序**。明白了这个区别，剩下的便是常规的 Map 操作了。下面举个例子，接着上面的内容，现在，我要回答一个问题：哪些天至少会有两个人来？

这就涉及到了每一天来的人数了，需要统计。用上 EnumMap 刚好合适。

```java
/**
 * 解决问题：哪些天至少会有两个人来？
 * */
private void atLeastTwoPeopleCome() {
    // EnumMap Key 值为枚举类型，先创建一个 Key 为 Day 类型的空的 EnumMap，单参构造器是为了告诉 EnumMap Key 的类型，不含任何元素
    Map<Day, Integer> countMap = new EnumMap<>(Day.class);
    // 先统计出每天的人数
    for(Worker w : workers){
         for(Day d : w.getAvailableDays()){
             Integer count = countMap.get(d);
             countMap.put(d, count==null?1:count+1);
         }
    }
    // 再找出至少有两个人的天，注意 Map.Entry 的用法
    Set<Day> days = EnumSet.noneOf(Day.class);
    for(Map.Entry<Day, Integer> entry : countMap.entrySet()){
        if(entry.getValue()>=2){
            days.add(entry.getKey());
        }
    }

    System.out.println(days);
}
```

有人说，枚举使用起来占内存，可以使用注解代替。但是我想说：

1. 枚举的使用绝不可能是程序 OOM 的罪魁祸首。与其花心思进行枚举的优化，不如多找找图片的显示、视频的播放、内存泄漏等问题。
2. 如果你觉得枚举降低了性能，那么**[这篇文章](https://juejin.cn/post/6844903976219967501)**可能会让你的信念动摇。
3. 在程序内部，可以使用注解代替枚举，因为编译器会帮你检查。但是如果需要将程序的接口暴露出去，或者是提供 Jar 包、aar 包，建议还是使用枚举。这样可以规范代码，避免使用出错。

至此，枚举的使用介绍便告一段落了。基于以上情况，个人觉得使用枚举还是很 OK 的。**一句话，想用就用。Enum 相比于注解，有着很多优秀的特性，可以帮助我们写出更优秀的代码。**