问：在 Gradle 中如何定义一个变量，并通过命令行修改？

答：在Gradle中，可以在build.gradle文件中定义一个变量，并在命令行中使用-P选项修改它的值。以下是一个简单的示例，演示如何定义一个名为myVariable的变量，并在命令行中修改它。

1. 在build.gradle文件中定义一个名为myVariable的变量。可以使用ext关键字定义一个扩展属性：

    ```groovy
    ext {
        myVariable = "default_value"
    }
    ```

2. 在build.gradle文件中使用这个变量。例如，可以在一个任务中打印它的值：

    ```groovy
    task printMyVariable {
        doLast {
            println "myVariable: $myVariable"
        }
    }
    ```

3. 在命令行中使用-P选项修改myVariable的值。例如，要将myVariable的值更改为new_value，可以运行以下命令：

    ```bash
    ./gradlew printMyVariable -PmyVariable=new_value
    ```

    这将输出如下结果：

    ```
    myVariable: new_value
    ```

4. 如果不使用-P选项指定新值，myVariable将保留其默认值。

5. 可以通过 manifestPlaceholders 将变量塞入 manifest 文件。在 gradle 中定义 manifestPlaceholders。

   ```groovy
   productFlavors {
       debug {
           manifestPlaceholders = [name : "myTestName",
                                   test_value : myVariable]
       }
   }
   ```

6. 在 manifest 文件中使用 manifestPlaceholders。

   ```xml
   <meta-data
       android:name="com.test.mytest"
       android:resource="${test_value}" />
   ```