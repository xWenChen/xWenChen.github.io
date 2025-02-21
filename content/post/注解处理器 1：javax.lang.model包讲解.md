---
title: "注解处理器 1：javax.lang.model 包讲解"
description: "本文讲解了 java 中的语言模型"
keywords: "Java,注解处理器,语言模型,javax.lang.model包"

date: 2023-03-05T18:31:00+08:00

categories:
  - Java
  - 注解处理器
tags:
  - Java
  - 注解处理器
  - 语言模型

url: post/A90F3472990141F8B69A6EC73420C0D2.html
toc: true
---

本文讲解了 java 中的语言模型，主要是讲解 javax.lang.model 包。

<!--More-->

注：官方文档地址：[javax.lang.model](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/module-summary.html)

下篇文档：[注解处理器 2：java 注解处理器](04B5C92A04564560A1143F299EA9A57A.html)

下篇文档：[注解处理器 3：实战 Android Router 插件实现](A85ED138561142DBBFA335CE35A4289B.html)

## 概览

在自定义注解处理器的过程中，我们可以对 java 源码做处理。为了从源码中拿到自己想要的数据、信息，我们需要对源码进行建模。建模工作不需要我们手动实现，java 官方已经完成了这个工作，并且在 jdk 中定义好了相应的结构，供我们使用。下面以 java 11 为例，说明下 官方如何划分 java 语言模型。

java 的语言模型，在 jdk 中主要定义在 javax.lang.model 包及其子包中。如图：

![javax_lang_model包及其子包](/imgs/javax_lang_model包及其子包.webp)

- SourceVersion 是一个枚举类，用于表示当前 JDK 的版本

- AnnotatedConstruct 表示可以被注解的结构，这个结构可以是 element 或者 type。其相关类图如下：

   ![AnnotatedConstruct表示可以被注解的结构](/imgs/AnnotatedConstruct表示可以被注解的结构.webp)
   
- UnknownEntityException 是一个异常类，建模时如果读取到未知的实体，则会抛出该异常，其相关类图如下：

   ![UnknownEntityException是一个异常类](/imgs/UnknownEntityException是一个异常类.webp)

## SourceVersion

SourceVersion 是一个枚举类，用于表示当前 JDK 的版本。其定义十分简单，如图：

![SourceVersion是一个枚举类](/imgs/SourceVersion是一个枚举类.webp)

除了版本枚举值外，我们常用到的是 `latest()` 和 `latestSupported()` 两个方法。

## UnknownEntityException

在 java 语言建模的过程中，如果碰到无法识别的实体，则会抛出该异常。比如为 JDK 7 建模时碰到了 JDK 11 中定义的新内容。

### UnknownDirectiveException

当建模遇到无法识别的模块指令时，就会抛出 UnknownDirectiveException 异常。

模块指令与 Java 新特性有关。Java 语言在 Java 9 版本引入了一个新的特性：Java 9 Platform Module System (JPMS)，即 Java 平台模块化系统。模块化在包之上提供了更高层次的聚合。每个模块必须提供一个模块描述符，用于指定模块的依赖项、让其他模块使用的包等元数据。模块描述符是一个经过编译的模块声明，定义于 module-info.java 中。形如：

```java
module modulename {}
```

模块声明的主体可以是空的，也可以包含各种模块指令(module directives)，包括 requires、exports、provides…with、uses 和 opens。

## AnnotatedConstruct

AnnotatedConstruct 表示可以被注解的结构，这个结构可以是 element 或者 type。element 相关的注解是针对 element 的声明(如方面、变量的声明)，而 type 相关的注解是针对 type 名称的如何使用。最初的注解只能用于声明时，比如类、方法的声明，但是后续版本 java 扩展了注解的使用范围，比如可重复的注解、throw 上的注解、泛型上的注解等。具体可以看每个 java 版本的新增特性。

AnnotatedConstruct 定义的方法如下：

```java
public interface AnnotatedConstruct {
    // 返回当前结构直接持有的注解
    List<? extends AnnotationMirror> getAnnotationMirrors();
    /**
     * 根据注解类型返回注解，注意获取的结果 Annotation 中包含了 Class 对象
     * 但是该 Class 对象无法用于定位和加载相关类。尝试做这些操作时，会抛出
     * MirroredTypesException 异常
     * 
     * 注意该方法是对运行时的注解信息进行操作
     */
    <A extends Annotation> A getAnnotation(Class<A> annotationType);
    /**
     * 功能同上，该方法可以额外检测可重复的注解(java8 新特性)
     */
    <A extends Annotation> A[] getAnnotationsByType(Class<A> annotationType);
}
```

## Element

一个典型的 java 代码包括模块、包、类/接口、方法、构造函数、变量等。这些构成程序的每一个部分，都可以被称为程序的一个元素。java 语言会针对这些元素进行建模，对元素建模涉及的类主要定义在 [javax.lang.model.element](https://docs.oracle.com/en/java/javase/11/docs/api/java.compiler/javax/lang/model/element/package-summary.html) 包中。

注意虽然 javax.lang.model.element 包中定义的内容不会对方法体内的具体代码实现进行建模(如没有 for 循环或 try-finally 块的表示)。但是 element 建模仍然可以模拟一些仅出现在方法体内的结构，例如局部变量和匿名类。

Element 中的类和接口主要包含异常(Exception)、枚举(Enum)、接口(Interface)三大部分。

![Element包中的类和接口](/imgs/Element包中的类和接口.webp)

### 枚举

Element 定义的枚举包含 Modifier、NestingKind、ElementKind、ModuleElement.DirectiveKind。

![Element包中的枚举](/imgs/Element包中的枚举.webp)

本节暂时只讲 Modifier、NestingKind；ElementKind、ModuleElement.DirectiveKind 后面跟随其他内容讲解。

#### Modifier

Modifier 类中定义的枚举值每个都对应了一个修饰符关键字：

![Modifier类中定义的枚举值](/imgs/Modifier类中定义的枚举值.webp)

#### NestingKind

NestingKind 类中定义的枚举值表示类的类型：

![NestingKind类中定义的枚举值](/imgs/NestingKind类中定义的枚举值.webp)

下面的代码标注了各个注解值表示的类：

```java
import java.lang.annotation.*;
import static java.lang.annotation.RetentionPolicy.*;
import javax.lang.model.element.*;
import static javax.lang.model.element.NestingKind.*;

@Retention(RUNTIME)
@interface Nesting {
    NestingKind value();
}

interface Shape {
   String name();
}

// NestingExamples 是 TOP_LEVEL 顶层类
@Nesting(TOP_LEVEL)
public class NestingExamples {
    // 静态类 MemberClass1 是 MEMBER 成员类
    @Nesting(MEMBER)
    static class MemberClass1{}

    @Nesting(MEMBER)
    class MemberClass2{}

    public static void main(String... argv) {
        // LocalClass 是局部类
        @Nesting(LOCAL)
        class LocalClass{};
        // new 接口是匿名类
        @Nesting(ANONYMOUS)
        Shape circle = new Shape() {
            @Override
            public String name() {
                return null;
            }
        }
        // 其他代码省略
    }
}
```

- 顶层类：在 .java 文件中，处于最外层的类就称为顶层类，在其外部不存在将其包围起来的任何代码块

- 内部类：在一个类的内部定义一个类就被称为内部类，包括静态类、成员类、局部类、匿名类：

   - 静态类(static class): 不用创建类的对象就可以直接创建静态类的对象。静态类可以引用外部类的静态变量与静态方法，非静态的不能引用。

      ```java
      class OutClass {
          static class InnerStatic {
              // 其他代码省略
          }
      }

      public class Test {
          public static void main(String[] args) {
              OutClass.InnerStatic clazz = new OutClass.InnerStatic();
          }
      }
      ```

   - 成员类(member class): 只有创建类的对象，才可创建成员类的对象；可以在类的成员方法中创建成员类对象。

      ```java
      class OutClass {
         class Inner {
             // 其他代码省略
         }

         void m1() {
             // 内部类对象创建方式 1
             Inner inner = new Inner();
         }
      }

      public class Test {
          public static void main(String[] args) {
              // 内部类对象创建方式 2
              OutClass out = new OutClass();
              OutClass.Inner oi = out.new Inner();
          }
      }
      ```   

   - 局部类(local class): 在方法内部可定义局部类，仅在该方法内才可以创建对象，一旦方法执行完毕，则生命周期结束；在包含局部类的方法中，局部类仅能引用有 final 修饰的变量。

      ```java
      class OutClass {
          void m1() {
              class Local {
                  final int a = 2; // 不能是 static 的
                  // int a = 10; 错误
              }
        
              Local local = new Local();
          }
      }
      ```

   - 匿名类(anonymous class): 无类名的类，类的定义与对象的创建被合并在一起。

### 接口

接口部分主要是 java 定义的方便我们使用的内容，包括：注解、元素、模块指令的相关内容。

#### 注解

元素注解相关的类主要包含以下三部分，后续有机会讲解实际代码时，再做详细阐述：

![元素注解相关的类](/imgs/元素注解相关的类.webp)

#### 模块指令

模块是 java 9 新增的特性。模块指令相关类主要用来表示这一特性。这部分就不细讲了，略过。

![模块相关类](/imgs/模块相关类.webp)

#### 元素

javax.lang.model.element 包中，与元素相关的类如下：

![element包中元素相关类](/imgs/element包中元素相关类.webp)

##### ElementKind

ElementKind 枚举表示 java 元素的种类。这些枚举值是我们熟悉 Element 体系的基础。

![ElementKind枚举](/imgs/ElementKind枚举.webp)

可以看出，java 划分出的元素类型，基本包含了代码的方方面面：

- 组件：module，又可叫模块。
- 包：package
- 类：class/interface/enum
- 方法：method/constructor
- 代码块：init block
- 变量：field/local variable/resource variable/enum constant
- 参数：parameter/excepter parameter/type parameter
- 注解：annotation type
- 其他：other

##### Element

在了解了元素的类型之后，我们就可以看元素接口及其子类了。

![元素接口及其子类](/imgs/元素接口及其子类.webp)

下面是每个子类的讲解：

- ExecutableElement：可执行的元素，对应的 ElementKind 为：
   - method
   - constructor
   - static init block
   - instance init block
   - annotation type

- ModuleElement：模块元素，提供对模块、模块指令、模块成员的访问

- PackageElement：包元素、提供对包、包成员的访问

- Parameterizable：具有参数的元素，是 ExecutableElement 和 TypeElement的父接口

- QualifiedNameable：具有限定名称的元素，包括：模块、包和类/接口/枚举

- TypeElement：表示类或者接口的元素，java 中定义枚举是一种类，注解是一种接口。此类与 DeclaredType 关系密切

- TypeParameterElement：表示泛型类、接口、方法或构造函数元素的实际参数类型。每个参数类型都会声明一个 TypeVariable

- VariableElement：表示变量、枚举常量、方法/构造函数的参数(method or constructor parameter)、局部变量、资源变量或异常参数(exception parameter)

###### Element

Element 类定义的方法如下：

```java
public interface Element extends AnnotatedConstruct {
    // 返回此元素相关的 Type
    TypeMirror asType();
    // 返回此元素的种类
    ElementKind getKind();
    // 返回此元素的修饰符(不包括注解)
    Set<Modifier> getModifiers();
    // 返回此元素的名称(作用同 Class 类中的一致)
    Name getSimpleName();
    // 返回包含此元素的最里面的元素
    Element getEnclosingElement();
    // 返回此元素包含的元素
    List<? extends Element> getEnclosedElements();
    // Object 中定义的方法
    boolean equals(Object var1);
    // Object 中定义的方法
    int hashCode();
    // 父类 AnnotatedConstruct 定义的方法
    List<? extends AnnotationMirror> getAnnotationMirrors();
    // 父类 AnnotatedConstruct 定义的方法
    <A extends Annotation> A getAnnotation(Class<A> var1);
    // 父类 AnnotatedConstruct 定义的方法
    <R, P> R accept(ElementVisitor<R, P> var1, P var2);
}
```

此处重点讲解下 `getEnclosingElement()` 和 `getEnclosedElements()` 方法。

`getEnclosingElement()` 方法返回直接包含此元素的外层元素。如果 A 包含 B，B 包含 C，则此方法返回的是 B，而不是 A。`getEnclosingElement()` 方法返回规则如下：

- 如果当前元素的声明在词法上直接包含在另一个元素 Other 的声明中，则返回 Other 元素。
- 如果当前元素是一个泛型类型参数，则返回类型参数对应的泛型元素(对 A\<T\> 中的 T 元素使用此方法，则会返回 A\<T\>)。
- 如果当前元素是方法或构造函数的参数，则返回声明该参数的可执行元素(ExecutableElement)。
- 如果当前元素是顶层类型(top-level type)，则返回顶层类型的包。
- 如果当前元素是一个包，当它的模块存在时，返回它的模块；否则返回 null。
- 如果如果当前元素是一个模块，则返回 null

`getEnclosedElements()` 方法返回直接包含在该元素中的元素，调用此方法查询被包含的元素，可能查出包括隐式声明的强制元素(如查类时，可能得到默认的无参构造器，或者枚举的隐式值和 valueOf 方法)。查询出的列表后，可以使用 `ElementFilter` 类提供的方法筛选出我们想要的元素。

`getEnclosedElements()` 方法的包含规则如下：

- 类或接口包含它直接声明的字段、方法、构造函数和成员类型。
- 包(Package) 包含它下面的顶级类和接口，但不包含子包(subpackages)。
- 模块将包含 包(Package)。
- 其他种类的元素目前不考虑包含任何元素(可能随着 java 版本变化而变化)

###### Parameterizable

Parameterizable 表示元素具有泛型参数(type parameters)。其类定义如下：

```java
public interface Parameterizable extends Element {
    // 获取泛型参数列表
    List<? extends TypeParameterElement> getTypeParameters();
}
```

###### QualifiedNameable

QualifiedNameable 类表示元素具有全限定名称，比如 Element 类具有全限定名 javax.lang.model.element.Element，具有名称 Element。其类定义如下：

```java
public interface QualifiedNameable extends Element {
    // 元素的全限定名称
    Name getQualifiedName();
}
```

###### VariableElement

VariableElement 类表示字段、枚举常量、方法或构造函数的参数、局部变量、资源变量或异常参数(try-catch 中的参数)。其类定义如下：

```java
public interface VariableElement extends Element {
    // 获取被视为编译时常量的 final 字段的值
    // 如果不是编译时常量，则返回 null。
    Object getConstantValue();
    // 返回当前变量元素的简单名称
    @Override
    Name getSimpleName();
    // 获取包含当前元素的元素
    // 方法或构造函数参数的外层元素是声明参数的 ExecutableElement
    @Override
    Element getEnclosingElement();
}
```

`getConstantValue()` 方法获取的是被视为编译时常量的 final 字段的值，如果不是编译时常量，则返回 null。并非所有 final 字段都具有常量值，如枚举常量不被视为编译时常量。要具有编译时常量值(Constant Value)，字段的类型必须是 java 基本类型或字符串。`getConstantValue()` 方法返回的值的类型是基本类型的包装类型(如 Long)或字符串。

`getSimpleName()` 方法获取的是变量元素的简单名称。对于方法和构造函数的参数，每个参数的名称必须各不相同。如果参数的原始名称不可用，则 VariableElement 接口的实现类可以合成名称，以满足该区别性要求。

###### TypeParameterElement

TypeParameterElement 类表示泛型类、接口、方法或构造函数元素的实际参数类型。每个参数类型都会声明一个 TypeVariable。其类定义如下：

```java
public interface TypeParameterElement extends Element {
    // 返回由包含此类型参数(泛型参数)的泛型类、接口、方法或构造函数。
    Element getGenericElement();
    // 返回此类型参数的边界。由泛型的 extends 子句指定。
    // 如果没有使用 extends 子句，那么结果是 java.lang.Object。
    List<? extends TypeMirror> getBounds();
    // 返回包含此元素的元素，作用同 getGenericElement 方法
    @Override
    Element getEnclosingElement();
}
```



###### ModuleElement

ModuleElement 类表示模块元素，提供了对模块、模块指令及模块成员的信息的访问。其类定义如下：

```java
public interface ModuleElement extends Element, QualifiedNameable {
    // 返回模块的全限定名
    @Override
    Name getQualifiedName();
    // 返回模块的名称
    @Override
    Name getSimpleName();
    // 返回当前元素包含的元素
    @Override
    List<? extends Element> getEnclosedElements();
    // 判断 module 是否是 open 的
    boolean isOpen();
    // 判断是否是未命名的模块
    boolean isUnnamed();
    // 返回包含当前元素的元素
    @Override
    Element getEnclosingElement();
    // 返回模块声明中包含的指令
    List<? extends Directive> getDirectives();
    // 模块指令类型枚举
    enum DirectiveKind {
        REQUIRES,
        EXPORTS,
        OPENS,
        USES,
        PROVIDES
    };
    // 代表模块指令
    interface Directive {
        // 指令类型
        DirectiveKind getKind();
        // 将指令访问器应用到当前指令上
        <R, P> R accept(DirectiveVisitor<R, P> v, P p);
    }
    // 指令访问器
    interface DirectiveVisitor<R, P> {
        default R visit(Directive d) {
            return d.accept(this, null);
        }
        default R visit(Directive d, P p) {
            return d.accept(this, p);
        }
        R visitRequires(RequiresDirective d, P p);
        R visitExports(ExportsDirective d, P p);
        R visitOpens(OpensDirective d, P p);
        R visitUses(UsesDirective d, P p);
        R visitProvides(ProvidesDirective d, P p);
        default R visitUnknown(Directive d, P p) {
            throw new UnknownDirectiveException(d, p);
        }
    }
    // Requires 指令
    interface RequiresDirective extends Directive {
        boolean isStatic();
        boolean isTransitive();
        ModuleElement getDependency();
    }
    // Exports 指令
    interface ExportsDirective extends Directive {
        PackageElement getPackage();
        List<? extends ModuleElement> getTargetModules();
    }
    // Opens 指令
    interface OpensDirective extends Directive {
        PackageElement getPackage();
        List<? extends ModuleElement> getTargetModules();
    }
    // Provides 指令
    interface ProvidesDirective extends Directive {
        TypeElement getService();
        List<? extends TypeElement> getImplementations();
    }
    // Uses 指令
    interface UsesDirective extends Directive {
        TypeElement getService();
    }
}
```

###### PackageElement

PackageElement 类表示包元素。提供了对包及其成员的信息的访问。其类定义如下：

```java
public interface PackageElement extends Element, QualifiedNameable {
    // 返回包的全限定名
    Name getQualifiedName();
    // 返回包名
    @Override
    Name getSimpleName();
    // 返回当前元素包含的元素
    @Override
    List<? extends Element> getEnclosedElements();
    // 判断是否是未命名的包
    boolean isUnnamed();
    // 返回包含当前元素的元素
    @Override
    Element getEnclosingElement();
}
```

###### TypeElement

TypeElement 类表示类或接口(class or interface)元素。TypeElement 提供了对有关类及其成员的信息的访问。注意在 element 包中，枚举被定义为一种类，注解被定义为是一种接口。

TypeElement 表示类或接口元素(element)，而 DeclaredType 表示类或接口类型(type)，后者是前者的使用(或调用)，可以理解为 TypeElement 是类声明，而 DeclaredType 是类的实例。这种区别在泛型中最为明显，单个 element 可以定义所有 type。例如，元素 java.util.Set 可以对应原始类型 java.util.Set、可以对应参数化类型(泛型) java.util.Set\<String\>、java.util.Set\<Number\>或其他参数化类型。

TypeElement 类接口返回的每个 element 列表的元素排序，都是按照程序中元素来源的自然顺序。例如，如果元素来源是 Java 源代码，则元素顺序将按 java 源代码中的顺序返回。

```java
public interface TypeElement extends Element, Parameterizable, QualifiedNameable {
    // 返回当前元素包含的元素
    // 注意包含强制元素(比如构造函数和枚举的枚举值和 valueOf 方法)
    @Override
    List<? extends Element> getEnclosedElements();
    // 返回当前元素的 NestingKind(类的类型)
    NestingKind getNestingKind();
    // 返回当前元素的全限定名，但不包含泛型信息
    // 比如 java.util.Set<E> 返回的是 "java.util.Set"
    Name getQualifiedName();
    // 返回元素的名称
    @Override
    Name getSimpleName();
    // 返回当前元素的直接父类。如果当前元素表示接口或java.lang.Object 类，
    // 则返回分类为 TypeKind.NONE 的 NoType
    TypeMirror getSuperclass();
    // 返回类或接口直接实现的接口类型    
    List<? extends TypeMirror> getInterfaces();
    // 按声明顺序返回类型参数。
    List<? extends TypeParameterElement> getTypeParameters();
    // 返回包含当前元素的元素
    @Override
    Element getEnclosingElement();
}
```

###### ExecutableElement

ExecutableElement 表示类或接口中的方法、构造函数、init 代码块(静态或者实例)、注解类型的元素。同 ExecutableType 类对应。其类定义如下：

```java
public interface ExecutableElement extends Element, Parameterizable {
    // 按声明顺序返回当前元素的实际类型参数(泛型参数)列表
    List<? extends TypeParameterElement> getTypeParameters();
    // 返回当前元素的返回类型。如果元素不是方法，或者是不返回值的方法，
    // 则返回类型为 TypeKind.VOID 的 NoType。
    TypeMirror getReturnType();
    // 按声明顺序返回当前元素的参数列表
    List<? extends VariableElement> getParameters();
    // 返回当前元素的接收者类型，java 8 新特性
    TypeMirror getReceiverType();
    // 返回方法或构造函数是否接受可变长度的参数
    boolean isVarArgs();
    // 判断方法是否是默认方法，java 8 新特性
    // 详见 https://www.cnblogs.com/huahuayu/p/12390338.html
    boolean isDefault();
    // 按声明顺序返回方法或构造函数的 throws 子句中列出的异常
    List<? extends TypeMirror> getThrownTypes();
    // 返回注解的默认值。如果不是注解或者注解无默认值，则返回 null。
    AnnotationValue getDefaultValue();
    // 返回方法、构造函数、init 代码块的名称
    @Override
    Name getSimpleName();
}
```

`getReceiverType()` 方法获取的是当前元素的接收者类型

- 如果元素没有接收者类型，则返回类型为 TypeKin.NONE 的 NoType。
- 如果此元素是实例方法(非静态方法)或内部类的构造函数，则该元素的接收者类型是由包含该元素的元素(见`getEnclosingElement()`方法)派发的接收者类型
- 如果此元素是静态方法、非内部类的构造函数或 init 代码块(静态或实例)，则接收者类型

`getSimpleName()` 方法获取的是方法、构造函数、init 代码块的名称。

- 如果是构造函数，则返回 "\<init\>"
- 如果是静态 init 代码块，则返回 "\<clinit\>"
- 如果是匿名类或实例 init 代码块，则返回空名称

### 异常

当建模 java 失败时(如低版本解析了高版本的源码)，可能会抛出异常，Element 相关的异常主要包括三个：

- UnknownAnnotationValueException

- UnknownDirectiveException

- UnknownElementException

## Type

type 的相关类主要定义在 javax.lang.model.type 包中，在 java.lang.reflect 中也有部分对应。Type 体系的引入是对 java 泛型的一种补充。因为 java 的泛型信息在运行时将会被擦除，泛型擦除将导致程序在运行期间无法获取到泛型的具体声明。所以 java 引入了 Type，Type 的引入使得**开发者在程序运行期内可以获取泛型的具体声明**。

泛型的官方解释见 [点我跳转Generic Types](https://docs.oracle.com/javase/tutorial/java/generics/types.html)。注意记忆文档中出现的英文术语(比如泛型叫 generic type)，能帮助我们快速读懂源码和理解 javax.lang.model 包的架构以及包提供的能力。

在阅读下面的内容前，我们需要先明确几个概念：

- ArrayList\<E\> 中的 E 称为类型参数变量(type parameters，也叫 type variables)
- ArrayList\<Integer\> 中的 Integer 称为实际类型参数
- 整个称为 ArrayList\<E\> 泛型类型(generic type)
- 整个 ArrayList\<Integer\> 称为参数化的泛型类型 ParameterizedType

当我们准备获取泛型数据时，也应该注意泛型信息的来源：

- 如果开发者获取的是类里的变量声明，则返回的是泛型类相关的数据，比如 ArrayList\<E\> 中的 E。

- 如果开发者获取的是对象里的变量声明，则返回的是泛型对象的类型，比如 ArrayList\<Integer\> 中的 Integer。

### java.lang.reflect.Type 接口

在讲解 javax.lang.model.type 包前，我们先看下 java.lang.reflect 包。

在 java 的反射包中，也有 type 的部分对应。这些对应类的根接口是 java.lang.reflect.Type，而 Class 类继承了 java.lang.reflect.Type 接口，又由于 Class 类是反射的基础，所以我们可以看出：**java.lang.reflect.Type 的使用是针对泛型的反射场景(运行时获取泛型信息)，java.lang.reflect.Type 和泛型、反射息息相关**。

java.lang.reflect.Type 有 5 个子类，如下图：

![Type子类](/imgs/Type子类.webp)

#### ParameterizedType

ParameterizedType 代表即带参数的类型，也可以说带<>的类型。例如 List\<String\>, User\<T\> 等。其源码如下：

```java
interface ParameterizedType extends Type {
     //获取参数类型 <> 里面的那些值, 例如 Map.Entry<K,V> 的 [K,V] 数组
     Type[] getActualTypeArguments(); 
     //获取参数类型 <> 前面的值，例如 Map.Entry<K,V> 的 MMap.Entry
     Type getRawType();
     //获取所属类的类型，如 Map.Entry<K,V> 的 Map
     Type getOwnerType();
}
```

下面是代码示例，用于获取 entry 对象的声明：

```java
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.util.*;

public class Test {
    public TypeTest.Pair<String, Long> entry = new TypeTest.Pair<>();
    public static void main(String[] args) throws NoSuchFieldException {
        Class clz = Test.class;
        // getGenericType 获取变量的声明类型
        Type genericType2 = clz.getField("entry").getGenericType();

        // 输出结果：TypeTest$Pair<java.lang.String, java.lang.Long>
        System.out.println("参数类型2: " + genericType2.getTypeName());

        if (genericType2 instanceof ParameterizedType) {
            ParameterizedType pType = (ParameterizedType) genericType2;
            Type[] types = pType.getActualTypeArguments();

            // 输出结果：[class java.lang.String, class java.lang.Long]
            System.out.println("参数类型列表: " + Arrays.asList(types));
            // 输出结果：class TypeTest$Pair
            System.out.println("参数原始类型: " + pType.getRawType());
            // 输出结果：class TypeTest
            System.out.println("参数父类类型: " + pType.getOwnerType());
        }
    }
}

class TypeTest {
    static class Pair<K, V> {
        public Map<K, V> map = new HashMap<>();
    }
}
```

输出结果如下，注意如果参数没有 Owner Type，则将输出 null：

```
> Task :Test.main()

参数类型2: TypeTest$Pair<java.lang.String, java.lang.Long>
参数类型列表: [class java.lang.String, class java.lang.Long]
参数原始类型: class TypeTest$Pair
参数父类类型: class TypeTest
```

#### TypeVariable

TypeVariable 代表泛型变量类型，其有以下三种形式：

- T value 声明中的 T
- List\<T\> list 声明中的 T, 
- Map\<K,V\> map 声明中的 K 和 V。

其源码定义如下：

```java
public interface TypeVariable<D extends GenericDeclaration> extends Type, AnnotatedElement {
    // 返回此类型参数的上界列表，如果没有上界则放回Object
    // 例如  V extends Number & Serializable
    // 有两个上界，Number 和 Serializable
    Type[] getBounds();
    // 类型参数声明时的载体，
    // 例如 class TypeTest<T, V extends Number & Serializable>，
    // 那么 V 的载体就是TypeTest
    D getGenericDeclaration();

    String getName();
    // Java 1.8 加入了 AnnotatedType
    // 如果泛型参数类型的上界(extends)用注解标记了，
    // 我们可以通过它拿到相应的注解
    AnnotatedType[] getAnnotatedBounds();
}
```

从 TypeVariable 的定义看到其也有一个泛型参数，要求需要是 GenericDeclaration 的子类，从 JDK 源码中看到，只有三个类实现了这个接口,分别是：

```
java.lang.reflect.Method,
java.lang.reflect.Constructor，
java.lang.Class
```

这里就对应上了泛型的一个知识点：泛型参数的声明只能在类(Class，Interface)、方法和构造函数这三个地方，其他地方我们只能使用。

下面是代码示例，用于获取 TypeTest.Pair 类中 map 和 value 的声明：

```java
import java.lang.reflect.*;
import java.util.*;

public class Test {
    public static void main(String[] args) throws NoSuchFieldException {
        Class clz = TypeTest.Pair.class;
        // getGenericType 获取变量的声明类型
        Type mapType = clz.getField("map").getGenericType();

        // 输出结果：java.util.Map<K, V>
        System.out.println("声明类型: " + mapType.getTypeName());

        if (mapType instanceof ParameterizedType) {
            ParameterizedType pType = (ParameterizedType) mapType;
            Type[] types = pType.getActualTypeArguments();

            List<String> names = new ArrayList<>();
            for (Type type : types) {
                names.add(type.getClass().getSimpleName());
            }

            // 输出结果：[K, V]
            System.out.println("参数类型列表: " + Arrays.asList(types));
            // [TypeVariableImpl, TypeVariableImpl]
            System.out.println("实际类型列表: " + names);
        }

        System.out.println("\n===================================");

        // getGenericType 获取变量的声明类型
        Type valueType = clz.getField("value").getGenericType();
        // 输出结果：java.util.Map<K, V>
        System.out.println("声明类型: " + valueType.getTypeName());
        if (valueType instanceof TypeVariable) {
            TypeVariable pType = (TypeVariable) valueType;
            System.out.println("实际类型: " + pType.getGenericDeclaration());
        }
    }
}

class TypeTest {
    static class Pair<K, V> {
        public Map<K, V> map = new HashMap<>();

        public V value = null;
    }
}
```

输出结果如下，

```
> Task :Test.main()

声明类型: java.util.Map<K, V>
参数类型列表: [K, V]
实际类型列表: [TypeVariableImpl, TypeVariableImpl]

===================================
声明类型: V
实际类型: class TypeTest$Pair
```

#### WildcardType

WildcardType 代表通配符类型，即带有 ? 的泛型参数。形如<?>、<? extends String>、<? super Integer> 中的泛型类型(其实就是就是 ?)就属于WildcardType。

其源码定义如下：

```java
public interface WildcardType extends Type {
    // 如果有extends 则返回的是extends对象的type 否则是[object]
    Type[] getUpperBounds();
    // 如果有super 则返回的是super 对象的type 否则是[]
    Type[] getLowerBounds();
}
```

下面是代码示例：

```java
import java.lang.reflect.*;
import java.util.*;

public class Test {
    public static void main(String[] args) throws NoSuchFieldException {
        Class c = TypeTest.class;
        Field[] fields = c.getDeclaredFields();
        for (Field field : fields) {
            ParameterizedType type = (ParameterizedType) field.getGenericType();
            for (Type type1 : type.getActualTypeArguments()) {
                System.out.println("getTypeName():  " + type1.getTypeName());
                if (type1 instanceof WildcardType) {
                    System.out.println("getUpperBounds(): " + Arrays.toString(((WildcardType) type1).getUpperBounds()));
                    System.out.println("getLowerBounds(): " + Arrays.toString(((WildcardType) type1).getLowerBounds()));
                    System.out.println("===========================");
                }
            }
        }
    }
}

class TypeTest {
    List<? extends String> sList;//属于WildcardType
    List<?> list;//属于WildcardType
    List<? super Integer> iList;//属于WildcardType
}
```

输出结果如下，

```
> Task :Test.main()

getTypeName():  ? extends java.lang.String
getUpperBounds(): [class java.lang.String]
getLowerBounds(): []
===========================
getTypeName():  ?
getUpperBounds(): [class java.lang.Object]
getLowerBounds(): []
===========================
getTypeName():  ? super java.lang.Integer
getUpperBounds(): [class java.lang.Object]
getLowerBounds(): [class java.lang.Integer]
===========================
```

#### GenericArrayType

GenericArrayType 代表范型数组。如果组成数组的元素中有范型(元素类型是 TypeVariable(即有泛型符号) 或者 ParameterizedType(即有 <>))，则该数组属于GenericArrayType。

其源码定义如下：

```java
public interface GenericArrayType extends Type {
    // 返回改数组类型元素的类型，例如T[] 返回的是T
    Type getGenericComponentType();
}
```

下面是代码示例：

```java
public class Test {
    public static void main(String[] args) throws NoSuchFieldException {
        Class c = TypeTest.class;
        Field[] fields = c.getDeclaredFields();
        for (Field field : fields) {
            Type type = field.getGenericType();
            if (type instanceof GenericArrayType) {
                System.out.println(((GenericArrayType) type).getGenericComponentType());
            }
            System.out.println("==================================");
        }

    }
}

class TypeTest<T> {
    T[] ts;
    List<String>[] lists;
}
```

输出结果如下，

```
> Task :Test.main()

T
==================================
java.util.List<java.lang.String>
==================================
```


### javax.lang.model.type 包

与 element 包类似，javax.lang.model.type 包的类主要也分为异常(Exception)、枚举(Enum)、接口(Interface)三大部分。

![type包概览](/imgs/type包概览.webp)

此处只讲下枚举和接口部分，异常部分就不讲了。

#### 枚举

type 包中只有 TypeKind 一个枚举，其说明如下：

![TypeKind枚举](/imgs/TypeKind枚举.webp)

大多数枚举值都见名知意，此处只解释几个：

##### UNION

UNION 表示或的关系，从集合的角度讲，是并集的关系。UNION 主要体现在 try-catch 的异常类型声明中，是 java 1.7 版本新增的特性。

```java
try {
     // 代码省略
} catch (Exception1 | Exception2 ex) {
     // Exception1 | Exception2 中的 | 就是 UNION 类型
}
```

##### INTERSECTION

INTERSECTION 表示与的关系，从集合的角度讲，是交集的关系。INTERSECTION 主要体现在泛型范围的指定中，是 java 1.8 版本新增的特性。

```java
class ChildC<T extends ClassA & InterfaceB> {
    // T extends ClassA & InterfaceB 中的 & 就是 INTERSECTION 类型
}
```

#### 接口

如上图，接口部分主要是 Type 的真正实现类。Type 体系中，TypeMirror 接口是所有类型的父类，可以看作是 java.lang.reflect.Type 的镜像。

- ArrayType：表示数组类型

- DeclaredType：表示类或者接口类型

- ErrorType：表示不能解析的类型

- ExecutableType：表示可执行的类型，对应方法、构造函数、或者 init 代码块

- IntersectionType：表示 & 类型

- NoType：表示没有实际的类型可以匹配

- NullType： 表示空类型

- PrimitiveType：表示 java 八种基本类型

- ReferenceType：表示引用类型。包括类和接口类型、数组类型、泛型变量类型和空类型(class/interface types、array types、type variables、the null type)

- TypeVariable：表示泛型变量类型，对应 TypeKind.TYPEVAR

- UnionType：表示 | 类型

- WildcardType：表示通配符类型

TypeMirror 的子类表示的类型，都能在 TypeKind 中找到对应的常量。

##### TypeMirror

TypeMirror 表示 Java 语言中的类型，是所有类型的根类型。类型包括基本类型、声明类型(类和接口类型)、数组类型、泛型变量类型、空类型、通配符类型参数、方法或者构造函数的签名和返回类型，以及对应于包、模块和关键字 void 的伪类型。

类型的比较应该使用 javax.lang.model.util.Types 中提供的方法。

如果要判断 TypeMirror 类，应使用访问者(visitor)或使用 getKind() 方法判断，使用 instanceof 不一定可靠。

TypeMirror 类的定义如下：

```java
public interface TypeMirror extends AnnotatedConstruct {
    // 获取 type 的类型
    TypeKind getKind();
    // 将访问器应用到当前 type 上
    <R, P> R accept(TypeVisitor<R, P> var1, P var2);

    boolean equals(Object var1);
    int hashCode();
    String toString();
}
```

TypeMirror 的子类中，如果没有定义额外的方法，那么本文就不列举了。本文只列举下定义了额外方法的子类

##### ArrayType

ArrayType 表示数组类型，其类定义如下：

```java
public interface ArrayType extends ReferenceType {
    // 返回数组内包含的元素的类型
    TypeMirror getComponentType();
}
```

##### DeclaredType

DeclaredType 表示我们声明的类型，可以是类或者接口类型，包括参数化类型(泛型类型)，例如 java.util.Set\<String\> 及其原始类型 java.util.Set。其类定义如下：

```java
public interface DeclaredType extends ReferenceType {
    // 返回此 type 对应的元素，详见 TypeElement 的讲解
    Element asElement();
    // 返回包含此 type 的 type，只有内部类才有结果
    // 无对应的结果则返回类型为 TypeKind.NONE 的 NoType。
    TypeMirror getEnclosingType();
    // 返回此类型的实际类型参数。
    // 对于嵌套在参数化类型(parameterized type，即泛型)中的类型，
    // 例如 Outer<String>.Inner<Number>，仅包括 Inner 的类型参数
    List<? extends TypeMirror> getTypeArguments();
}
```

##### ExecutableType

ExecutableType 表示可执行的类型，对应方法、构造函数、或者 init 代码块。

当 ExecutableType 表示某种引用类型(类或者接口)的方法/构造函数/init 代码块时。如果该引用类型是泛型的，那么它的实际类型参数将被替换为该接口的方法返回的任何类型。

ExecutableType 的类定义如下：

```java
public interface ExecutableType extends TypeMirror {
    // 返回当前可执行类型的泛型参数声明的泛型变量
    List<? extends TypeVariable> getTypeVariables();
    // 同 ExecutableElement 中的方法
    TypeMirror getReturnType();
    // 返回当前可执行类型的泛型参数的类型
    List<? extends TypeMirror> getParameterTypes();
    // 同 ExecutableElement 中的方法
    TypeMirror getReceiverType();
    // 同 ExecutableElement 中的方法
    List<? extends TypeMirror> getThrownTypes();
}
```

##### IntersectionType

IntersectionType 表示 & 类型。其类定义如下：

```java
public interface IntersectionType extends TypeMirror {
    // 获取泛型的边界列表
    List<? extends TypeMirror> getBounds();
}
```

##### TypeVariable

TypeVariable 表示泛型变量，具体可见 java.lang.reflect.TypeVariable 的讲解。类型变量也可以隐式声明，如通配符类型的捕获转换。其类定义如下：

```java
public interface TypeVariable extends ReferenceType {
    // 返回与泛型变量对应的元素
    Element asElement();
    // 返回此类型变量的上限
    // 如果声明此类型变量时没有明确的上限，则结果为 java.lang.Object
    // 如果用多个上限声明，结果是交集类型
    TypeMirror getUpperBound();
    // 返回此类型变量的下限，无合适结果时下限为 NullType
    TypeMirror getLowerBound();
}
```

##### UnionType

UnionType 表示 | 类型，其类定义如下：

```java
public interface UnionType extends TypeMirror {
    // 返回 | 的结果列表(或表达式的拆分)
    List<? extends TypeMirror> getAlternatives();
}
```

##### WildcardType

WildcardType 表示泛型中的通配符类型。其类定义如下：

```java
public interface WildcardType extends TypeMirror {
    // 返回通配符的上限。由 extends 语句定义
    TypeMirror getExtendsBound();
    // 返回通配符的下限。由 super 语句定义
    TypeMirror getSuperBound();
}
```

## utils

javax.lang.model.util 包提供了一些方便我们使用的方法和类。其主要有以下类：

![util包概览](/imgs/util包概览.webp)

本文重点讲解下 Elements 和 Types 类。

### javax.lang.model.util.Elements

javax.lang.model.util.Elements 是针对 model 下 element 体系的工具类，我们可以使用 `ProcessingEnvironment.getElementUtils()` 方法获取到 Elements 的实例。

Elements 主要方法如下：

![Elements定义](/imgs/Elements定义.webp)

Elements 类的定义如下：

```java
public interface Elements {
    // 根据包的全限定名返回包元素
    PackageElement getPackageElement(CharSequence name);
    // 根据包的全限定名从指定模块中返回包元素
    default PackageElement getPackageElement(
        ModuleElement module, 
        CharSequence name
    ) {
        return null;
    }
    // 根据包的全限定名获取所有包元素。不同模块可能存在多个相同名称的包元素
    default Set<? extends PackageElement> getAllPackageElements(
        CharSequence name
    ) {
       // 方法实现省略，见代码后的方法讲解
    }
    // 根据全限定名获取 TypeElement
    TypeElement getTypeElement(CharSequence name);
    // 根据全限定名从指定的模块中获取 TypeElement
    default TypeElement getTypeElement(
        ModuleElement module, 
        CharSequence name
    ) {
        return null;
    }
    // 根据全限定名获取所有类型元素，不同模块可能存在多个相同名称的类型元素
    default Set<? extends TypeElement> getAllTypeElements(CharSequence name) {
        // 代码实现省略，见代码后的方法讲解
    }
    // 根据全限定名返回对应的模块元素。如果找不到指定的模块，则返回 null
    default ModuleElement getModuleElement(CharSequence name) {
        return null;
    }
    // 获取所有模块元素
    default Set<? extends ModuleElement> getAllModuleElements() {
        return Collections.emptySet();
    }
    // 返回注解元素的值，包括默认值
    Map<? extends ExecutableElement, ? extends AnnotationValue> getElementValuesWithDefaults(
        AnnotationMirror anno
    );
    // 返回元素 e 的文档注释。文档注释以 "/**" 开头、以 "*/" 结尾
    String getDocComment(Element e);
    // 判断元素是否被弃用了
    boolean isDeprecated(Element e);
    // 返回给定元素的来源
    default Elements.Origin getOrigin(Element e) {
        return Elements.Origin.EXPLICIT;
    }
    // 根据被注解的结构获取注解元素的来源
    default Elements.Origin getOrigin(
        AnnotatedConstruct c, 
        AnnotationMirror a
    ) {
        return Elements.Origin.EXPLICIT;
    }
    // 返回指定模块指令的来源
    default Elements.Origin getOrigin(
        ModuleElement m, 
        Directive directive
    ) {
        return Elements.Origin.EXPLICIT;
    }
    // 判断方法是否是桥接方法，桥接方法是 JDK 1.5 引入泛型后，
    // 为了使 Java 的泛型方法生成的字节码和 1.5 版本前的字节码相兼容，
    // 由编译器自动生成的方法
    default boolean isBridge(ExecutableElement e) {
        return false;
    }
    // 返回元素的二进制名
    // 二进制名即元素的原名，与 TypeElement.getQualifiedName() 一样
    // 比如 Object 的 binary name 是 java.lang.Object
    // Thread 的 binary name 是 java.lang.Thread
    // 二进制名的定义可见 jls 13.1 The Form of a Binary
    Name getBinaryName(TypeElement type);
    // 返回元素对应的包。一个包元素对应的包就是它自己
    PackageElement getPackageOf(Element type);
    // 返回元素对应的模块。模块元素对应的模块就是它自己
    // 如果该元素没有对应的模块，则返回 null
    default ModuleElement getModuleOf(Element type) {
        return null;
    }
    // 返回类型元素的所有成员，无论是继承的还是直接声明的
    // 对于一个类，结果还包括它的构造函数，但不包括本地类或匿名类
    List<? extends Element> getAllMembers(TypeElement type);
    // 返回元素上存在的所有注解，无论是直接存在还是通过继承而存在
    List<? extends AnnotationMirror> getAllAnnotationMirrors(Element e);
    // 测试 hider 是否隐藏了 hidden
    // hider 和 hidden 可以是一种类型、方法或字段
    boolean hides(Element hider, Element hidden);
    // 判断 overrider 方法是否作为给定 type 的成员覆盖了 overridden 方法
    boolean overrides(
        ExecutableElement overrider, 
        ExecutableElement overridden, 
        TypeElement type
    );
    // 返回代表基本类型或字符串的常量表达式的文本
    // 返回的文本采用合适的形式表示源代码中的值
    // value 的类型是基本类型或者 String
    // 方法返回的结果同 VariableElement.getConstantValue()
    // 相关定义可见 jls 15.28 Constant Expression, 4.12.4 final Variables
    String getConstantExpression(Object value);
    // 打印 elements 的内容到 writer 中，此方法主要用于调试
    void printElements(Writer w, Element... elements);
    // 返回与 cs 内容一致的 Name 对象
    Name getName(CharSequence cs);
    // 判断元素是否是函数式接口
    // 函数式接口定义见 jls 9.8 Functional Interfaces
    boolean isFunctionalInterface(TypeElement type);
    // 元素或其他语言模型内容的来源
    public static enum Origin {
        // 显式声明
        EXPLICIT,
        // 强制构造
        MANDATED,
        // 合成构造
        SYNTHETIC;

        private Origin() {
        }
        // 判断来源是显示或隐式声明的
        public boolean isDeclared() {
            return this != SYNTHETIC;
        }
    }
}
```

- `Origin` 类表示元素或其他 java 语言建模内容的来源。Java 9 的新特性。来源是指元素或其他建模内容代表的结构，在源代码中是通过显式、隐式或其他方法声明的。注意在未来的 jdk 版本中可能会添加其他类型的来源值。
   
   - EXPLICIT 代表显式声明，表明元素是在源代码中显式声明
   - MANDATED 代表强制构造，强制构造是一种未在源代码中明确声明的构造，但其存在性是 jls 规范强制要求的。这样的构造被称为隐式声明。强制构造的一个示例是类中的默认构造函数，另一个示例是隐式声明的容器注解，用于保存多个可重复注解。更具体的内容见：
   
      - jls 8.8.9 Default Constructor
      - jls 8.9.3 Enum Members
      - jls 9.6.3 Repeatable Annotation Types
      - jls 9.7.5 Multiple Annotations of the Same Type

      jls 是 The Java™ Language Specification 的缩写，中文意思为 java 语言规范。

    - SYNTHETIC 代表合成构造，表示在源代码中既未隐式也未显式声明的构造。这种构造通常是由编译器创建的中间转换产物

- `getAllPackageElements​(CharSequence name)` 方法根据包的全限定名获取所有包元素。不同模块可能存在多个相同名称的包元素。

   此方法的默认实现会首先调用 getAllModuleElements 方法获取模块集：
      
   - 如果模块集为空，则调用 getPackageElement(name) 方法
      
      - 如果 getPackageElement(name) 方法结果为 null，则返回一组空的包元素(空集合)
      - 如果 getPackageElement(name) 方法结果不为 null，则返回包含结果的集合
      
   - 如果模块集不为空，则遍历模块并将 getPackageElement(module, name) 方法的任何非空结果合并，最终返回合并后的集合。

- `getAllTypeElements(CharSequence name)` 方法根据类型元素的全限定名获取所有类型元素。不同模块可能存在多个相同名称的类型元素。

   此方法的默认实现同 `getAllPackageElements​(CharSequence name)` 方法类似，会首先调用 getAllModuleElements 方法获取模块集：
   
   - 如果模块集为空，则调用 getTypeElement(name) 方法
    
      - 如果 getTypeElement(name) 方法结果为 null，则返回一组空的类型元素；
      - 如果 getTypeElement(name) 方法结果不为 null，则返回包含结果的类型元素集合
      
   - 如果模块集不为空，则迭代模块并将 getTypeElement(module, name) 方法的任何非空结果合并，最终返回合并后的集合。

- `getOrigin(Element e)` 方法会获取元素的来源，即元素是如何被创建的，比如来自源码，或者编译器生成(如每个类都有的无参构造器)。

   注意即使此方法返回了 EXPLICIT，但是如果该元素是根据 class 文件创建的，那么该来源信息实际上仍有可能并不代表元素对应于源码中显式声明的构造。这是由于 class 文件保留源码信息的限制，例如某些版本的 class 文件不保留构造函数是由开发者显式声明还是编译器隐式声明为默认构造函数的信息。

- `getOrigin​(AnnotatedConstruct c, AnnotationMirror a)` 方法根据被注解的结构 c，获取注解元素 a 的来源。例如注解如果是编译器隐式声明的容器注解，以用于保存可重复的注解，则注解元素的来源是 Elements.Origin MANDATED。

   注意同单参的方法原因类似，即使此方法返回了 EXPLICIT，结果也不一定准确。至少某些版本的 class 文件格式不保留注解是由程序员显式声明还是编译器隐式声明为容器注解的信息。

   本方法中提到的一些术语的定义(如可重复注解)，可见 jls 9.6.3 Repeatable Annotation Types 和 jls 9.7.5 Multiple Annotations of the Same Type。

- `getOrigin​(ModuleElement m, ModuleElement.Directive directive)` 方法用于获取模块指令的来源。注意如果此方法返回了 EXPLICIT，其结果也不一定准确。原因同上面讲的类似。至少某些版本的 class 文件格式不保留 uses 指令是由程序员显式声明还是编译器作为合成构造添加的。

- `overrides​(ExecutableElement overrider, ExecutableElement overridden, TypeElement type)` 方法用于判断 overrider 方法是否作为给定 type 的成员覆盖了 overridden 方法。当一个非抽象方法重写了一个抽象方法时，也可以说是前者实现了后者。

   在最简单和最典型的用法中，类型参数(type)的值是类或接口，其直接包含 overrider。例如假设 m1 表示方法 String.hashCode，m2 表示 Object.hashCode。然后我们可以判断类 String 中的 m1方法是否覆盖了 m2 方法，结果是肯定的：

   ```java
   assert elements.overrides(
       m1, 
       m2, 
       elements.getTypeElement("java.lang.String")
   );
   ```

   有一种有趣的情况，下面的代码中类型 A 中的方法不会覆盖类型 B 中的同名方法：

   ```java
   class A { 
       public void m() {

       } 
   }
   interface B { 
       void m(); 
   }
   // ... 代表代码省略
   m1 = ...; // A.m
   m2 = ...; // B.m
   assert ! elements.overrides(
       m1,
       m2,
       elements.getTypeElement("A")
   );
   ```

   但是当 m1 方法被视为第三种类型 C 的成员时，A 中的方法则确实会覆盖了 B 中的方法：

   ```java
   class C extends A implements B {

   }
   // ...
   assert elements.overrides(
       m1, 
       m2, 
       elements.getTypeElement("C")
   );
   ```

#### javax.lang.model.util.ElementFilter

javax.lang.model.util.ElementFilter 是一个只包含静态字段和静态方法的工具类，表示元素过滤器，主要用于让我们从 Element 从筛选出自己感兴趣的内容，包括字段、方法、构造函数、类型、包、模块、模块指令，返回的内容可以是列表(List)或者集合(Set)。注意此类方法返回的内容是不可修改的，并且是线程不安全的。简洁表示如下图所示：

![ElementFilter定义](/imgs/ElementFilter定义.webp)

ElementFilter 类的定义如下：

```java
public class ElementFilter {
    private static final Set<ElementKind> CONSTRUCTOR_KIND;
    private static final Set<ElementKind> FIELD_KINDS;
    private static final Set<ElementKind> METHOD_KIND;
    private static final Set<ElementKind> PACKAGE_KIND;
    private static final Set<ElementKind> MODULE_KIND;
    private static final Set<ElementKind> TYPE_KINDS;

    static {
        CONSTRUCTOR_KIND = Collections.unmodifiableSet(
            EnumSet.of(ElementKind.CONSTRUCTOR)
        );
        FIELD_KINDS = Collections.unmodifiableSet(
            EnumSet.of(ElementKind.FIELD, ElementKind.ENUM_CONSTANT)
        );
        METHOD_KIND = Collections.unmodifiableSet(
            EnumSet.of(ElementKind.METHOD)
        );
        PACKAGE_KIND = Collections.unmodifiableSet(
            EnumSet.of(ElementKind.PACKAGE)
        );
        MODULE_KIND = Collections.unmodifiableSet(
            EnumSet.of(ElementKind.MODULE)
        );
        TYPE_KINDS = Collections.unmodifiableSet(
            EnumSet.of(
                ElementKind.CLASS, 
                ElementKind.ENUM, 
                ElementKind.INTERFACE, 
                ElementKind.ANNOTATION_TYPE
            )
        );
    }

    private ElementFilter() {
    }
    // 返回 elements 中的字段列表
    public static List<VariableElement> fieldsIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            FIELD_KINDS, 
            VariableElement.class
        );
    }
    // 返回 elements 中的字段列表
    public static Set<VariableElement> fieldsIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements, 
            FIELD_KINDS, 
            VariableElement.class
        );
    }
    // 返回 elements 中的构造函数列表
    public static List<ExecutableElement> constructorsIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            CONSTRUCTOR_KIND, 
            ExecutableElement.class
        );
    }
    // 返回 elements 中的构造函数列表
    public static Set<ExecutableElement> constructorsIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements,
            CONSTRUCTOR_KIND,
            ExecutableElement.class
        );
    }
    // 返回 elements 中的方法列表
    public static List<ExecutableElement> methodsIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            METHOD_KIND,
            ExecutableElement.class
        );
    }
    // 返回 elements 中的方法列表
    public static Set<ExecutableElement> methodsIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements, 
            METHOD_KIND, 
            ExecutableElement.class
        );
    }
    // 返回 elements 中的类型列表
    public static List<TypeElement> typesIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            TYPE_KINDS, 
            TypeElement.class
        );
    }
    // 返回 elements 中的类型列表
    public static Set<TypeElement> typesIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements, 
            TYPE_KINDS, 
            TypeElement.class
        );
    }
    // 返回 elements 中的包列表
    public static List<PackageElement> packagesIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            PACKAGE_KIND, 
            PackageElement.class
        );
    }
    // 返回 elements 中的包列表
    public static Set<PackageElement> packagesIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements, 
            PACKAGE_KIND, 
            PackageElement.class
        );
    }
    // 返回 elements 中的模块列表
    public static List<ModuleElement> modulesIn(
        Iterable<? extends Element> elements
    ) {
        return listFilter(
            elements, 
            MODULE_KIND, 
            ModuleElement.class
        );
    }
    // 返回 elements 中的模块列表
    public static Set<ModuleElement> modulesIn(
        Set<? extends Element> elements
    ) {
        return setFilter(
            elements, 
            MODULE_KIND,
            ModuleElement.class
        );
    }
    // 真正的实现方法，用于获取元素中对应的数据
    private static <E extends Element> List<E> listFilter(
        Iterable<? extends Element> elements, 
        Set<ElementKind> targetKinds, 
        Class<E> clazz
    ) {
        List<E> list = new ArrayList();
        Iterator var4 = elements.iterator();

        while(var4.hasNext()) {
            Element e = (Element)var4.next();
            if (targetKinds.contains(e.getKind())) {
                list.add((Element)clazz.cast(e));
            }
        }

        return list;
    }
    // 真正的实现方法，用于获取元素中对应的数据
    private static <E extends Element> Set<E> setFilter(
        Set<? extends Element> elements, 
        Set<ElementKind> targetKinds, 
        Class<E> clazz
    ) {
        Set<E> set = new LinkedHashSet();
        Iterator var4 = elements.iterator();

        while(var4.hasNext()) {
            Element e = (Element)var4.next();
            if (targetKinds.contains(e.getKind())) {
                set.add((Element)clazz.cast(e));
            }
        }

        return set;
    }
    // 返回模块指令列表中的 exports 指令
    public static List<ExportsDirective> exportsIn(
        Iterable<? extends Directive> directives
    ) {
        return listFilter(
            directives, 
            DirectiveKind.EXPORTS, 
            ExportsDirective.class
        );
    }
    // 返回模块指令列表中的 opens 指令
    public static List<OpensDirective> opensIn(
        Iterable<? extends Directive> directives
    ) {
        return listFilter(
            directives, 
            DirectiveKind.OPENS, 
            OpensDirective.class
        );
    }
    // 返回模块指令列表中的 provides 指令
    public static List<ProvidesDirective> providesIn(
        Iterable<? extends Directive> directives
    ) {
        return listFilter(
            directives, 
            DirectiveKind.PROVIDES, 
            ProvidesDirective.class
        );
    }
    // 返回模块指令列表中的 requires 指令
    public static List<RequiresDirective> requiresIn(
        Iterable<? extends Directive> directives
    ) {
        return listFilter(
            directives, 
            DirectiveKind.REQUIRES, 
            RequiresDirective.class
        );
    }
    // 返回模块指令列表中的 uses 指令
    public static List<UsesDirective> usesIn(
        Iterable<? extends Directive> directives
    ) {
        return listFilter(
            directives, 
            DirectiveKind.USES, 
            UsesDirective.class
        );
    }
    // 真正的实现方法，用于获取模块指令中对应的指令
    private static <D extends Directive> List<D> listFilter(
        Iterable<? extends Directive> directives, 
        DirectiveKind directiveKind, 
        Class<D> clazz
    ) {
        List<D> list = new ArrayList();
        Iterator var4 = directives.iterator();

        while(var4.hasNext()) {
            Directive d = (Directive)var4.next();
            if (d.getKind() == directiveKind) {
                list.add((Directive)clazz.cast(d));
            }
        }

        return list;
    }
}
```

### javax.lang.model.util.Types

javax.lang.model.util.Types 是针对 model 下 type 体系的工具类，我们可以使用 `ProcessingEnvironment.getTypeUtils()` 方法获取到 Types 的实例。

其主要方法如下：

![Types定义](/imgs/Types定义.webp)

Types 类的定义如下：

```java
public interface Types {
    // 返回与 TypeMirror 对应的元素
    Element asElement(TypeMirror t);
    // 判断两个 TypeMirror 代表的类型是否相同
    boolean isSameType(TypeMirror t1, TypeMirror t2);
    // 判断 first 是否是 second 的子类
    // 任何类型都被认为是其自身的子类
    // subtype 的定义可以见 jls 4.10 Subtyping
    boolean isSubtype(TypeMirror first, TypeMirror second);
    // 判断 first 是否可分配给 second
    // 类似的使用理解可以见 Class.isAssignableFrom 方法
    // Assignable 的定义可以见 jls 5.2 Assignment Conversion
    boolean isAssignable(TypeMirror first, TypeMirror second);
    // 判断 first 是否包含 second
    // 具体的定义可以见 jls 4.5.1.1 Type Argument Containment and Equivalence
    boolean contains(TypeMirror first, TypeMirror second);
    // 测试 first 的签名是否是 second 的子签名
    // 方法签名由 方法名+形参列表 组成，与返回值无关
    // 方法签名的定义可以见 jls 8.4.2 Method Signature
    boolean isSubsignature(ExecutableType first, ExecutableType second);
    // 返回类型 t 的直接父类
    List<? extends TypeMirror> directSupertypes(TypeMirror t);
    // 返回类型 t 经过泛型擦除后的类型
    // 如果 t 是包或者模块，则将抛出 IllegalArgumentException
    // 类型擦除的定义详见 jls 4.6 Type Erasure
    TypeMirror erasure(TypeMirror t);
    // 返回基本类型装箱后的类型
    TypeElement boxedClass(PrimitiveType t);
    // 返回包装类型拆箱后的基本类型
    PrimitiveType unboxedType(TypeMirror t);
    // 返回对 t 进行泛型捕获转换后的类型
    // 如果 t 是可执行的类型、包或者模块，会抛出 IllegalArgumentException
    // 泛型捕获转换的定义见 jls 5.1.10 Capture Conversion
    TypeMirror capture(TypeMirror t);
    // 返回 t 对应的基本类型
    // 如果 t 不是基本类型，将抛出 IllegalArgumentException
    PrimitiveType getPrimitiveType(TypeKind kind);
    // 返回 NullType
    NullType getNullType();
    // 获取 NoType
    NoType getNoType(TypeKind kind);
    // 返回数组类型，数组中元素的类型是 componentType
    ArrayType getArrayType(TypeMirror componentType);
    // 返回一个新的通配符类型参数
    // 边界可以都不指定，也可以指定其中一个，但不能同时指定两个边界
    // 当边界不需要指定时，对应的参数传入 null 即可
    WildcardType getWildcardType(
        TypeMirror extendsBounds, 
        TypeMirror superBounds
    );
    // 返回对应于类型 typeElem 和参数 typeArgs 的 DeclaredType
    DeclaredType getDeclaredType(
        TypeElement typeElem, 
        TypeMirror... typeArgs
    );
    // 返回对应于类型 typeElem 和参数 typeArgs 的 DeclaredType
    // 该 DeclaredType 是 DeclaredType 的成员类型(member class)
    // 如果 containing 为空或者不是泛型，则该方法等价于同名的双参方法
    DeclaredType getDeclaredType(
        DeclaredType containing, 
        TypeElement typeElem, 
        TypeMirror... typeArgs
    );
    // 从 containing 类型看元素 element 的类型
    TypeMirror asMemberOf(DeclaredType containing, Element element);
}
```

- `asElement(TypeMirror t)` 方法的作用是返回与 TypeMirror 对应的元素。TypeMirror 可以是 DeclaredType 或 TypeVariable。如果 TypeMirror 没有相应的 Element，则返回 null。

- `isSameType(TypeMirror t1, TypeMirror t2)` 方法的作用是判断两个 TypeMirror 对象代表的类型是否相同。注意如果此方法的任一参数表示通配符 ?，则此方法将返回 false。因为通配符 ? 表示不确定的类型，所以通配符与其本身不是同一类型。此知识点可以使用官方提供的一段会在编译时报错的代码：

   ```java
   List<?> list = new ArrayList<Object>();
   list.add(list.get(0));
   ```

   通配符的官方文档见：https://docs.oracle.com/javase/tutorial/extra/generics/wildcards.html。 官方的解释是 ? 表示不确定的类型，由于不确定 List<?> 中的 ? 代表了什么类型，所以不能向 list 中添加数据。

   ![问号的说明](/imgs/问号的说明.webp)

   另外由于注解只是与类型 type 关联的元数据，因此在判断两个 TypeMirror 对象是否为同一类型时，不会考虑任一参数上的注解集。所以即使两个 TypeMirror 对象有不同的注解，但他们仍然可以被认为是相同的。

- `directSupertypes(TypeMirror t)` 方法会返回类型 t 的直接父类

   - 如果类型实现了接口，则接口类型将出现在列表的最后
   - 对于没有直接父接口的接口类型，将返回代表 java.lang.Object 的 TypeMirror
   - 如果参数 t 是可执行的类型、包或者模块，会抛出 IllegalArgumentException 错误

- `getNoType(TypeKind kind)` 方法会返回 NoType(伪类型)，TypeKind 可以是 TypeKind.VOID 或者 TypeKind.NONE。要获取与包或模块对应的伪类型，可以先分别使用 `Elements.getPackageElement(CharSequence)` 或 `Elements.getModuleElement(CharSequence)` 将名称转换为包或模块的 element。再调用元素的 `asType()` 方法

- `getDeclaredType(TypeElement typeElem, TypeMirror... typeArgs)` 方法会根据类型元素 typeElem 和泛型参数 typeArgs 返回对应的 DeclaredType。例如给定 Set 的类型和 String 的泛型参数，此方法会返回参数化类型 Set\<String\>。

   类型参数 typeArgs 的数量必须等于类型元素 typeElem 声明的形式类型参数的数量。数量可以为零。当为零时，并且类型元素是带泛型的，则返回类型元素的原始类型(如 Set)。

   如果返回了参数化类型，则其类型元素不得包含在通用外部类中。例如对于参数化类型 Outer\<String\>.Inner\<Number\> 可以首先使用此方法获取类型 Outer\<String\>，然后调用 `getDeclaredType(DeclaredType, TypeElement, TypeMirror...)` 来构造。

- `asMemberOf(DeclaredType containing, Element element)` 是从包含类型 containing 看元素 element 的类型。当元素 element 被视为给定类型 containing 的成员或直接包含给定泛型中时，返回该元素的类型。例如当 Set.add 方法(element)被视为参数化类型 Set\<String\>(containing) 的成员时，add 方法是一个 ExecutableType(返回值)，其参数为 String 类型。

## 总结

至此，javax.lang.model 包的内容我们就大致讲解完成了，了解了这个包里定义的内容、提供的功能，我们才能更好的掌握和使用编译时注解处理器(APT)、反射等技术。

本文并未细致的讲解包中每个知识点，不足之处还请大家谅解，有什么遗漏或者不对的地方，欢迎指出。同时感谢大家的耐心阅读。