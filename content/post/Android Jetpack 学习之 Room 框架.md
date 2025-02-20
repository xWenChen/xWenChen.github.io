---
title: "Android Jetpack 学习之 Room 框架"
description: "本文略讲了 Android Jetpack 的 Room 框架"
keywords: "Android,Jetpack,Room"

date: 2020-04-04T15:33:00+08:00

categories:
  - Android
  - Jetpack
tags:
  - Android
  - Jetpack
  - Room

url: post/106033A1B96B4792AC93374C0C39E7EE.html
toc: true
---

本文略讲了 Android Jetpack 的 Room 框架。

<!--More-->

Room 是 Google 官方推出的一个数据库框架，作为 Jetpack 包的一部分，是我们必须要掌握的内容。下面让我们看看如何使用。

首先，我们先讲下开发中常用的一些数据库知识。

## 数据库常用知识

SQLite 支持的数据类型。一般的开发中，基本的数据类型完全够用，下面是 SQLite 支持的基本数据类型：

| 存储类型 |                             描述                             |
| :------ | :---------------------------------------------------------- |
|   NULL |                       存储的是一个空值                       |
| INTEGER &#x2003; &#x2003; &#x2003; | 值是一个带符号的整数，根据值的大小存储在 1、2、3、4、6 或 8 字节中 |
|   REAL   |        值是一个浮点值，存储为 8 字节的 IEEE 浮点数字         |
|   TEXT   | 值是一个文本字符串，使用数据库编码（UTF-8、UTF-16BE 或 UTF-16LE）存储 |
|   BLOB   |            值是一个二进制数据，完全根据它的输入存            |

一般我们会将 SQL 中定义的关键字使用大写书写。而库名、表名、列名这些采用小写书写。

### 建库删库

创建数据库操作

```sql
-- 建库语句
CREATE DATABASE 数据库名称;

-- 举例
CREATE DATABASE mydata.db;
```

删除数据库操作

```sql
-- 删库语句
DROP DATABASE 数据库名;

-- 举例
DROP DATABASE mydata.db;
```

**注：SQLite 的建库方式不太一样**

### 建表删表

创建表

```sql
-- 建表语句
CREATE TABLE 表名(列名1 类型(尺寸) 属性(一个或者多个), 列名2 类型(可带尺寸) 属性(一个或者多个), ...);

-- 举例：创建一个存储人的信息表，包括id，姓，名，年龄
CREATE TABLE Person(
    id        INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
    lastName  TEXT      NOT NULL,  
    firstName TEXT      NOT NULL,
    age       INTEGER   NOT NULL
); 
```

删除表

```sql
-- 删表语句
DROP TABLE 表名;

-- 举例：创建删除上面创建的表
DROP TABLE Person;
```

### 重命名表

```sql
-- 重命名表语句
ALTER TABLE old_table_name RENAME TO new_table_name;

-- 举例：重命名上面创建的表
ALTER TABLE Person RENAME TO People;
```

### 新增字段删除字段

字段也可以叫做列。

增加字段

```sql
-- 增加字段语句
ALTER TABLE 表名 ADD COLUMN 字段名 类型 属性;

-- 举例：在上面的表中新增一项城市信息
DROP TABLE Person ADD COLUMN city INTEGER NOT NULL;
```

删除字段

```sql
-- 删除字段语句
ALTER TABLE 表名 DROP COLUMN 字段名;

-- 举例：删除上面新增的城市信息
DROP TABLE Person DROP COLUMN city;
```

修改字段

```sql
-- 修改字段语句
ALTER TABLE 表名 ALTER COLUMN 字段名 类型 属性;

-- 举例：修改上面的城市信息，城市名用文本存储
ALTER TABLE Person ALTER COLUMN city TEXT NOT NULL;
```

**注：sqlite 中暂时只支持重命名表和新增字段操作，删除字段等操作暂时不支持**

### 数据操作

#### 增加记录

```sql
-- 增加记录语句
-- 增加特定字段数据
INSERT INTO 表名(字段1, 字段, ...) VALUES (值1, 值2, ...);
-- 向所有列插入数据
INSERT INTO 表名 VALUES (值1, 值2, ...);

-- 举例：插入一个人的信息
INSERT INTO Person(id, lastName, firstName, age, city) VALUES (1, "张", "三", 23, "北京");
-- 举例：插入一个人的信息，向所有列都插入
INSERT INTO Person VALUES (1, "李", "四", 24, "上海");
```

#### 删除记录

```sql
-- 删除记录语句
DELETE FROM 表名 WHERE 条件语句;

-- 举例：删除 id = 1 的的信息
DELETE FROM Person WHERE id=1;
```

#### 更新记录

```sql
-- 更新记录语句
UPDATE 表名 SET 字段1=值1, 字段2=值2 WHERE 条件语句;

-- 举例：更新 id = 1 的记录姓名为李四
UPDATE Person SET lastName="李", firstName="四" WHERE id=1;
```

#### 查询记录

```sql
-- 查询记录语句
-- 查询特定字段
SELECT 字段1, 字段2, ... FROM 表名 WHERE 条件语句;
-- 查询所有列
SELECT * FROM 表名 WHERE 条件语句;
-- 查询去重
SELECT DISTINCT 字段1, 字段2, ... FROM 表名

-- 举例：查询 id = 1 的个人的年龄，城市
SELECT age, city FROM Person WHERE id=1;
-- 举例：查询 id = 2 的个人的所有信息
SELECT * FROM Person WHERE id=2;
-- 举例：假如有4个人的信息，其中两人是北京的，两人是上海的。
-- 现在我只想知道目前数据库中有哪些城市信息，并不想他们重复
SELECT DISTINCT city FROM Person;
```

### WHERE 子句

WHERE 条件语句中可以使用的符号和关键字如下，! 表示非操作：

|     符号     |                             作用                        |
| :---------- | :----------------------------------------------------|
|  = 或者 ==   |                     判断两个数值是否相等                  |
|  != 或者 <>  |                    判断两个数值是否不相等                  |
| >, <, >=, <= &#x2003; &#x2003; &#x2003; |            作用就不介绍了，学过 C/C++/Java 的都懂          |
| !<(不小于)    |       < 的结果取反。比如 a=10, b=20, a<10为真，则a!<b为假  |
|  !>(不大于)    |     > 的结果取反。比如 a=10, b=20, a>10为假，则a!>b为假   |

WHERE 中还可以使用一些关键字：

|     关键字     |                             作用                      |
| :---------- | :----------------------------------------------------|
| BETWEEN |                     判断两个数值是否相等                  |
|     LIKE+%     |                    判断两个数值是否不相等           |
| NOT+IN |     查询不在目标范围中的数据   |

```sql
-- 查询年龄段不是 20 到 50 岁的人
-- 写法1：NOT+IN用法举例
SELECT * FROM Person WHERE age NOT IN(20, 50);
-- 写法2
SELECT * FROM Person WHERE age >20 AND age < 50;

-- LIKE+%用法举例
-- 查询居住在以 "Ne" 开始的城市里的人
SELECT * FROM Person WHERE city LIKE "Ne%";
-- LIKE+_用法举例
-- 查询居住在以京字结尾的城市的人，比如居住在北京、南京、东京、西京等等
SELECT * FROM Person WHERE city LIKE "_京";
```

#### 别名

SQL中可以起别名，使用关键字 AS(Alias的缩写)标识，输出的结果，原字段名会用别名替换。但是数据库字段不变，这样方面人阅读。需要拼接字段时，可以使用 CONCAT

```sql
-- 选择人的信息，字段重命名为姓名
SELECT lastName AS 姓, firstName AS 名 FROM Person;
-- 将姓名合在一起打印
SELECT CONCAT(lastName, firstName) AS 姓名 FROM Person;
```

#### 排序分组

排序使用 ORDER BY 语句，默认是升序，希望降序的话，可以使用 DESC 关键字。

```sql
-- 排序语法，[]包含的内容表示可选
SELECT 字段1, 字段2, ... FROM 表名 ORDER BY 字段名 [DESC]
```

分组使用 GROUP BY 语句。GROUP BY 语句用于结合聚合函数，根据一个或多个列对结果集进行分组。

```sql
-- 选出所有的姓名，按照姓分类，统计个数
SELECT lastName, SUM(firstName) AS nums FROM Person GROUP BY lastName; 
```

#### 通配符

SQL 中存在通配符

|     符号     |                             作用                      |
| :---------- | :----------------------------------------------------|
| * | 匹配所有结果集 |
| % |                      替代一个或多个字符                |
| _ | 替代一个字符 |
|    [charlist]     |    字符列中的任何单一字符           |
|   [^charlist] 或者 [!charlist] &#x2003; &#x2003; &#x2003; |   不在字符列中的任何单一字符    |

用法举例上面都有了，此处就不赘述了。举一个：

```sql
-- 查询居住的城市以 "A" 或 "L" 或 "N" 开头的人
SELECT * FROM Person WHERE city LIKE "[ALN]%";
-- 查询居住的城市不以 "A" 或 "L" 或 "N" 开头的人
SELECT * FROM Person WHERE city LIKE "[!ALN]%";
```

### 自增主键和联合主键

自增主键是一个字段，可以用来唯一标识一条记录。而联合主键可以是多个字段构成，联合起来唯一标识一条记录。

自增主键的使用：

```sql
CREATE TABLE Person(
    id        INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT, -- 设置了自增主键
    lastName  TEXT      NOT NULL,  
    firstName TEXT      NOT NULL,
    age       INTEGER   NOT NULL
); 
```

联合主键的使用，假设人的名字不会重复。

```sql
CREATE TABLE Person(
    lastName  TEXT      NOT NULL,  
    firstName TEXT      NOT NULL,
    age       INTEGER   NOT NULL,
    PRIMARY KEY(lastName, firstName) -- 设置了联合主键，唯一标识一条记录
);
```

通常联合主键和自增主键二者设置其中一个即可

### 外键

**外键的作用是与另一张表建立联系，以保证数据的一致性。**

假设 Person 表有以下数据：

| id_p | lastName | firstName | age  |   city   |
| :-- | :------ | :------- | :-- | :------ |
|  1 &#x2003; &#x2003; &#x2003;|  Adams &#x2003; &#x2003; &#x2003;|   John &#x2003; &#x2003; &#x2003;|  23 &#x2003; &#x2003; &#x2003;|  London  &#x2003; &#x2003; &#x2003;|
|  2   |   Bush   |  George      |  22  | New York     |
|  3   |  Carter     |  Thomas   |  24  | Beijing  |

现有一张 Orders 表进行排序：

| id_o | orderNo | id_p |
| :-- | :----- | :-- |
|  1 　&#x2003; &#x2003; &#x2003;|  77895　&#x2003; &#x2003; &#x2003;|  3　&#x2003; &#x2003; &#x2003;|
|  2   |  44678  |  3   |
|  3   |  22456  |  1   |
|  4   |  24562  |  1   |

Order 的建表语句如下，建立了与 Person 表的外键依赖：

```sql
CREATE TABLE Orders(
	id_o int NOT NULL,
	orderNo int NOT NULL,
	id_p int, -- 依赖于 Person 表的主键 id_p
	PRIMARY KEY (id_o),
	FOREIGN KEY (id_p) REFERENCES Persons(id_p)
);
```

当执行命令往 Orders 中插入数据时

```sql
INSERT INTO Orders VALUES(1, 22456, 5);
```

发生错误 Error: foreign key constraint failed。因为 Person 表中没有 id_p 为5记录，这边插入了，那边没有记录，两边数据就不一致了。所以插入失败了。

由上可知，添加了外键。两个表之间的增、删、改操作便会保持同步。

### 事务

**事务(transaction)是保证数据库操作完整与准确的重要手段。事务提供了一种机制，可用来将一系列数据库更改归入一个逻辑操作。更改数据库后，所做的更改可以作为一个单元进行提交或取消。**事务可确保遵循**原子性、一致性、隔离性和持续性**（ACID）这几种属性，以使数据能够正确地提交到数据库中。

**原子性**

事务必须是原子工作单元。对于其数据修改，要么全都执行，要么全都不执行。

**一致性**

事务在完成时，必须使所有的数据都保持一致状态。在相关数据库中，所有规则都必须应用于事务的修改，以保持所有数据的完整性。事务结束时，所有的内部数据结构都必须是正确的。举个例子，事务开始时，所有数据都是写状态，那么结束时，所有数据就都得是写状态。不能说事务结束时，一部分数据是读状态，还有一部分数据处于写状态。

**隔离性**

在同一个环境中可能有多个事务并发执行，而每个事务都应表现为独立执行。串行的执行一系列事务的效果应该同于并发的执行它们。要达到隔离性，需要做到以下两点：

- 在一个事务执行过程中，数据的中间的(可能不一致)状态不应该被暴露给所有的其他事务。 
- 两个并发的事务应该不能操作同一项数据。数据库管理系统通常使用锁来实现这个特征。

**持久性**

事务完成之后，它对于系统的影响是永久性的。该修改即使出现系统故障也将一直保持。

#### 事务的三种模式

- 自动提交事务：每条单独的语句都是一个事务。
-  显式事务：每个事务均以**BEGIN TRANSACTION**语句显式开始，以**COMMIT**或**ROLLBACK**语句显式结束。
-  隐性事务：在上个事务完成时新事务隐式启动，但每个事务仍以**COMMIT**或**ROLLBACK**语句显式完成。

数据库的基础知识就讲到这，还有许多内容没有涉及到。更多的基础知识可以参考晚上的教程。

## Room框架

Room 持久性库在 SQLite 的基础上提供了一个抽象层，让用户能够在充分利用 SQLite 的强大功能的同时，获享更强健的数据库访问机制。Room框架由 Google 官方维护。进行数据库操作时，官方推荐使用 Room。

Room主要由三个部分组成，使用注解标识数据库操作。具体操作 SQL 的代码可以不用写，编译时自动生成：

- **数据库**：包含**数据库持有者**，并作为应用已保留的持久关系型数据的底层连接的主要接入点。使用`@Database`注解标识。一个类在使用`@Database`注解时，应当注意以下三点：
- 是 `RoomDatabase` 抽象类的子类。
   - 在注解中添加与数据库关联的实体列表(Entity，标识数据库中的表)。
   - 包含抽象方法，该抽象方法具有 0 个参数，且返回使用`@Dao`注解的类。

在运行时，可以通过调用 `Room.databaseBuilder()`或 `Room.inMemoryDatabaseBuilder()` 获取`Database`实例对象。

- **Entity**：表示数据库中的表。使用`@Entity`标识

- **DAO**：包含用于访问数据库的方法。使用`@DAO`标识
   - @Insert：插入操作
   - @Delete：删除操作
   - @Update：更新操作
   - @Query：查询操作

下面是一张官方的说明图，说明上面三个组件之间的关系。

![不同组件之间的关系](/imgs/不同组件之间的关系.webp)

我们先来举一个简单的例子，讲讲 Room 框架如何使用。假设我们要存储一次打卡记录。打卡记录以时间戳存储。通常的时间戳，我们会精确到毫秒。但这可能是不够的。因为存在机器打卡的情况，所以需要更加精确的时间戳。Java 8 的新版时间 API 就采用了 秒 + 秒内纳秒 的形式。一个 CPU 指令执行的最小时间也得几十纳秒。所以精确到纳秒是绰绰有余的。

对于类型的选择，我们知道，Java 中，int 是用 4 个字节表示，最大值为 2147483647 (2^31-1，21亿多)，而 1 秒等于 10 亿纳秒(1 * 1000(毫秒) * 1000(微秒) * 1000(纳秒))，所以用 int 来存储纳秒是可行的。

首先，让我们导入 Room 框架，Room 有很多包，这里只导入了部分：

```groovy
// 引入 Room Database
implementation 'android.arch.persistence.room:runtime:1.1.0'
// 引入额外的处理注解的工具
annotationProcessor 'android.arch.persistence.room:compiler:1.1.0'
//添加测试支持，我们可以对数据库进行androidTest（后面会介绍）
implementation 'android.arch.persistence.room:testing:1.1.0'
```

那么现在，就让我们来定义一张数据库表，这是使用 Room 的第一步：

```java
// 1、定义部分数据库常量
public interface RecordConstant {
    /**
     * 数据库名
     * */
    String DATABASE_NAME = "app_database";
    /**
     * 表名
     * */
    String TABLE_NAME = "record";
    /**
     * 一次打卡记录的时间标识分为两段，当前秒数(主时间)，和秒内的纳秒数(副时间)
     * */
    String PRIMARY_TIME_COLUMN_ANME = "click_second";
    String SECONDARY_TIME_COLUMN_ANME = "nano_in_second";
}

// 2. 定义数据表 Record
// 使用 @Entity 标识这是一张数据表
@Entity(tableName = RecordConstant.TABLE_NAME)
public class Record {
    // 设置主键、自增
    @PrimaryKey(autoGenerate = true)
    private long id;
    // @ColumnInfo 设置数据库字段名
    @ColumnInfo(name = RecordConstant.PRIMARY_TIME_COLUMN_ANME)
    private long clickSecond;
    // 设置数据库字段名，副时间
    @ColumnInfo(name = RecordConstant.SECONDARY_TIME_COLUMN_ANME)
    private int nanoInSecond;

    public Record() {
    }

    // 不映射数据库的字段或方法，使用 @Ignore 标记
    @Ignore
    public Record(long clickSecond, int nanoInSecond) {
        this.clickSecond = clickSecond;
        this.nanoInSecond = nanoInSecond;
    }

    public long getId() {return id;}
    public void setId(long id) {this.id = id;}

    public long getClickSecond() {return clickSecond;}
    public void setClickSecond(long clickSecond) {this.clickSecond = clickSecond;}

    public int getNanoInSecond() {return nanoInSecond;}

    public void setNanoInSecond(int nanoInSecond) {this.nanoInSecond = nanoInSecond;}
}
```

也许代码看不出什么效果，可以看看 Android Studio 做的处理，建表时的注解高亮：

![建表时的注解高亮](/imgs/建表时的注解高亮.jpg)

第二步，定义 Dao 数据库操作类，我们定义最常用的增删改查操作：

```java
// @Dao 标识这是一个 Dao 类
@Dao
public interface RecordDao {
    /**
     * 下面的方法介绍包括增删查改，数据根据主键匹配，多个数据可以用列表和数据存储
     * */
    // ---------------插入----------------
    /**
     * @Insert 标识这个方法是数据库插入操作
     * 插入一条数据
     * OnConflictStrategy.REPLACE表示如果已经有数据，那么就覆盖掉
     *
     * @param record 待插入数据库的数据
     *
     * @return 被插入数据的主键值（即行号）
     * */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    long insert(Record record);

    /**
     * 插入多组数据
     *
     * @param records 待插入数据库的一组数据，使用列表存储
     *
     * @return 被插入的数据的主键列表
     * */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    List<Long> insertAll(List<Record> records);

    /**
     * 插入多组数据
     *
     * @param records 待插入数据库的一组数据，使用数组存储
     *
     * @return 被插入的数据的主键列表
     * */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    List<Long> insertAll(Record... records);

    // ---------------删除----------------
    /**
     * @Delete 标识这个方法是删除操作
     * 删除一行数据库数据，待删除数据通过主键匹配
     *
     * @param record 待删除的数据
     *
     * @return 被删除数据的数目
     * */
    @Delete
    int delete(Record record);

    /**
     * 删除一组数据，被删除的数据通过列表存储
     *
     * @param records 待删除的数据
     *
     * @return 被删除数据的数目
     * */
    @Delete
    int deleteAll(List<Record> records);

    // ---------------查询----------------
    /**
     * @Query 标识这是查询操作，具体怎么查询。得定义 SQL 语句
     * 得到数据库中存储的所有数据
     *
     * @return 数据库中所有的数据的列表
     * */
    @Query("SELECT * FROM " + RecordConstant.TABLE_NAME)
    List<Record> queryAll();

    /**
     * 查询一个数据段内的数据，根据时间大小比较，区间左闭右开
     * : 相当于 Groovy 语言中的 $，起到了模版字符串的作用
     *
     * @param startInclude 时间段的开始时间
     * @param endExclude 时间段的结束时间
     *
     * @return 时间段内的数据
     * */
    @Query("SELECT * FROM " + RecordConstant.TABLE_NAME
        + " WHERE " + RecordConstant.PRIMARY_TIME_COLUMN_ANME + " >= :startInclude"
        + " AND " + RecordConstant.PRIMARY_TIME_COLUMN_ANME + " < :endExclude")
    List<Record> queryByTimeInterval(long startInclude, long endExclude);

    // ---------------更新----------------

    /**
     * @Update 标识这是一个数据库更新操作
     * 更新已有数据，根据主键匹配，返回类型int代表更新的条目数目
     *
     * @param record 带更新的数据
     */
    @Update
    int update(Record record);

    /**
     * 更新已有数据，根据主键匹配，返回类型int代表更新的条目数目
     *
     * @param records 带更新的数据
     */
    @Update
    int updateAll(List<Record> records);
}
```

我们仍然可以看看 Android Studio 做的注解高亮：

![Dao的注解高亮](/imgs/Dao的注解高亮.jpg)

可以看出，Android Studio 在如何提升我们的开发效率上面，是下足了功夫的。其对SQL语句的高亮可大大提升可读性，方便我们的开发

第三步，定义数据库：

```java
// 使用 @Database 标明这是一个数据库对象，并且指明了数据库中的数据表和数据库版本，数据表可以生命不止一张。
// // 采用双重锁的方案实现单例，使用单例是因为数据库对象全局只有一个
@Database(entities = {Record.class}, version = 1)
public abstract class AppDatabase extends RoomDatabase {
    private static volatile AppDatabase singleton;
    /**
     * 创建获取 Dao 的抽象方法，有多少个 Entity 就创建多少个 Dao 方法
     * */
    public abstract RecordDao recordDao();
    
    private AppDatabase(){}
    public static AppDatabase getInstance(Context context) {
        if(singleton == null) {
            synchronized (AppDatabase.class) {
                if(singleton == null) {
                    singleton = Room.databaseBuilder(
                        context.getApplicationContext(),
                        AppDatabase.class,
                        RecordConstant.DATABASE_NAME)
                        // 数据库有变动时，使用这个方法
                        //.addMigrations(MIGRATION_1_2)
                        .build();
                }
            }
        }
        return singleton;
    }

    /**
     * 迁移升级方法示例。
     * 定义用于数据库升级和迁移的对象，版本从1升到2
     * 版本从2升到3，就定义MIGRATION_2_3，依次类推
     */
    public static final Migration MIGRATION_1_2 = new Migration(1, 2) {
        @Override public void migrate(@NonNull SupportSQLiteDatabase database) {
            // 实现数据库变动代码
            //database.execSQL("ALTER TABLE record " +
            // "ADD COLUMN date INTEGER NOT NULL DEFAULT 0");
        }
    };
}
```

现在，我们定义了数据库、数据表、以及 Dao 操作。那么，让我们来实际用一下，定义一个数据库操作管理类：

```java
// 数据库操作不能在主线程，所以需要开启异步线程执行
public class DbTaskManager {
    /**
     * 执行异步操作的线程池
     * */
    private ExecutorService executor;
    /**
     * 数据库实例
     * */
    private AppDatabase database;
    /**
     * 上下文环境
     * */
    private Context context;

    public DbTaskManager(Context context, AppDatabase database) {
        // 创建线程数量为 5 的固定线程池
        executor = Executors.newFixedThreadPool(5);
        this.context = context;
        if(database != null) {
            this.database = database;
        } else {
            this.database = AppDatabase.getInstance(context);
        }
    }

    /**
     * 取消所有正在执行的任务，并终结线程池
     * */
    public void cancel() {
        executor.shutdown();
    }

    /**
     * 增删查改操作：增
     * */
    public boolean insert(Record record) {
        return runInsert(record);
    }
    /**
     * 增删查改操作：删
     * */
    public boolean delete(Record record) {
        return runDelete(record);
    }

    /**
     * 增删查改操作：查
     * */
    public List<Record> queryAll() {
        return runQueryAll();
    }
    /**
     * 增删查改操作：改
     * */
    public boolean update(Record record) {
        return runUpdate(record);
    }

    /**
     * 实际的插入操作
     * */
    private boolean runInsert(final Record record) {
        // Future + Callable，异步支持操作，并获取结果
        Callable<Boolean> callable = new Callable<Boolean>() {
            @Override public Boolean call() throws Exception {
                return database.recordDao().insert(record) > -1;
            }
        };

        boolean result;
        try {
            Future<Boolean> task = executor.submit(callable);
            result = task.get();
        } catch (Exception e) {
            result = false;
        }

        return result;
    }

    /**
     * 实际的删除操作
     * */
    private boolean runDelete(final Record record) {
        Callable<Boolean> callable = new Callable<Boolean>() {
            @Override public Boolean call() throws Exception {
                return database.recordDao().delete(record) > 0;
            }
        };

        boolean result;
        try {
            Future<Boolean> task = executor.submit(callable);
            result = task.get();
        } catch (Exception e) {
            result = false;
        }

        return result;
    }

    /**
     * 实际的查询操作，查询所有记录
     * */
    private List<Record> runQueryAll() {
        Callable<List<Record>> callable = new Callable<List<Record>>() {
            @Override public List<Record> call() throws Exception {
                return database.recordDao().queryAll();
            }
        };

        List<Record> result;
        try {
            Future<List<Record>> task = executor.submit(callable);
            result = task.get();
        } catch (Exception e) {
            result = new ArrayList<>(0);
        }

        return result;
    }

    /**
     * 得到某天的所有打卡记录
     *
     * @param instant 可以构建出某个日期的时间戳，是 Java8 中新增的时间 API
     *
     * @return 某天的所有打卡记录的列表
     * */
    public List<Record> querySomedayRecords(Instant instant) {
        // ZonedDateTime 包含着最全的时间信息
        ZonedDateTime zonedDateTime = instant.atZone(ZoneId.of(TimeUtil.ZONE_ID));
        // 获得查询范围的起止事件，单位是秒
        final long startInclude = TimeUtil.getTimeInstant(zonedDateTime);
        // 天数加 1 天
        final long endExclude = TimeUtil.getTimeInstant(zonedDateTime.plus(1, ChronoUnit.DAYS));

        Callable<List<Record>> callable = new Callable<List<Record>>() {
            @Override public List<Record> call() throws Exception {
                if(startInclude == -1 || endExclude == -1) {
                    return null;
                }
                return database.recordDao().queryByTimeInterval(startInclude, endExclude);
            }
        };

        List<Record> result;
        try {
            Future<List<Record>> task = executor.submit(callable);
            result = task.get();
        } catch (Exception e) {
            result = new ArrayList<>(0);
        }

        return result;
    }

    /**
     * 实际的更新操作
     * */
    private boolean runUpdate(final Record record) {
        Callable<Boolean> callable = new Callable<Boolean>() {
            @Override public Boolean call() throws Exception {
                return database.recordDao().update(record) > 0;
            }
        };

        boolean result;
        try {
            Future<Boolean> task = executor.submit(callable);
            result = task.get();
        } catch (Exception e) {
            result = false;
        }

        return result;
    }
}
```

上面的代码便是 Room 框架实际的定义与使用了。现在，让我们探索一点更高级的东西。

### 联合主键

如果我们希望在数据表中添加联合主键，则我们可以这样使用：

```java
// 使用 @Entity 的 primaryKeys 属性设计联合主键
@Entity(tableName = RecordConstant.TABLE_NAME,
    primaryKeys = {RecordConstant.PRIMARY_TIME_COLUMN_ANME,
        RecordConstant.SECONDARY_TIME_COLUMN_ANME})
public class Record {
    // 设置主键、自增
    // @PrimaryKey(autoGenerate = true)
    // private long id;
    // 秒 + 纳秒可以唯一标识一条记录
    // @ColumnInfo 设置数据库字段名
    @ColumnInfo(name = RecordConstant.PRIMARY_TIME_COLUMN_ANME)
    private long clickSecond;
    // 设置数据库字段名，副时间
    @ColumnInfo(name = RecordConstant.SECONDARY_TIME_COLUMN_ANME)
    private int nanoInSecond;
}
```

### 外键

**Android官方明确禁止 Android Room 外键引用**，因为有可能会导致性能损耗，更具体的原因这里就不做解释了。有能力的可以翻墙出去看看。虽然 Android Room 不允许外键引用，但**保留了 @Embedded 内嵌对象这一设计**，其实通过Room的@Embedded内嵌对象，可以变通的实现外键引用，且性能更佳。

```java
// 加入我们想要增加年、月、日，代码可能就会变成这样
@Entity(tableName = RecordConstant.TABLE_NAME)
public class Record {
    ....
    @ColumnInfo(name = RecordConstant.YEAR)
    private int year;
    @ColumnInfo(name = RecordConstant.MONTH)
    private int month;
    @ColumnInfo(name = RecordConstant.DAY)
    private int day;
    ...
}
```

这样子看起来是有点多余的。所幸，我们可以将这三个包装进一个类，命名为 Date，使用  @Embedded 包含打卡记录里。

```java
// 定义日期类
public class Date {
    @ColumnInfo(name = RecordConstant.YEAR)
    private int year;
    @ColumnInfo(name = RecordConstant.MONTH)
    private int month;
    @ColumnInfo(name = RecordConstant.DAY)
    private int day;
}

@Entity(tableName = RecordConstant.TABLE_NAME)
public class Record {
    ....
    @ColumnInfo(name = RecordConstant.PRIMARY_TIME_COLUMN_ANME)
    private long clickSecond;
    @ColumnInfo(name = RecordConstant.SECONDARY_TIME_COLUMN_ANME)
    private int nanoInSecond;
    // 包含进日期对象
    @Embedded
    private Date date;
    ...
}
```

### 事务

Room 框架默认是事务安全的，我们在使用注解后，重新编译项目，AS 会自动生成相关的代码，下面，以 insert 方法为例：

```java
// 定义 insert 方法
@Insert(onConflict = OnConflictStrategy.REPLACE)
long insert(Record record);
```

如下图，编译过后，点击左侧的按钮，便可以看到 AS 生成的对应代码：

![insert方法对应的按钮](/imgs/insert方法对应的按钮.jpg)

生成的代码如下：

可以看到，插入操作操作是在事务中进行的：

![插入操作在事务中进行](/imgs/插入操作在事务中进行.jpg)

我们想要自写事务操作的话，就可以仿照官方的代码模式，这么做：

```java
// 在 DbTaskManager 中，定义下面的方法，使用了事务。
// 事务的使用有一个标准模版
public boolean createOrUpdateRecord(long id) {
    long newId;
    /**
     * 标准模块
     * database.beginTransaction();
     * try {
     *     database.setTransactionSuccessful();
     * } finally {
     *     database.endTransaction();
     * }
     */
    database.beginTransaction();
    try {
        List<Record> records = database.recordDao().queryAll();
        boolean isIn = false;
        Record record = null;
        for(Record record2 : records) {
            if(record2.getId() == id) {
                record = record2;
                break;
            }
        }
        if(record != null) {
            newId = database.recordDao().update(record);
        } else {
            newId = database.recordDao().insert(record);
        }
        // 设置事务成功，防止回滚或其他异常
        database.setTransactionSuccessful();
    } finally {
        database.endTransaction();
    }
    
    return newId > 0;
}
```

### 总结

1. Room 框架中数据库的匹配是以主键进行匹配的，包括增、删、改，其返回结果也是数据项的主键。查询操作可以不用主键匹配，但得自定义 SQL 语句
2. 下面是 Room 中用到的一些常用注解的总结：
   - @Database：数据库类的标识，使用`entities`属性标记数据库中的表，使用`version`属性标识数据库版本
   - @Entity：数据库表的标识，使用`tableName`指定数据表的名称，使用`primaryKeys`指定数据表中的联合主键
   - @PrimaryKey：数据表中主键字段的标识
   - @ColumnInfo：数据表中字段的标识，使用`name`指定字段名称
   - @Ignore：当某个字段或者方法不想映射到数据表中时，可以使用此注解，取消映射关系
   - @Dao：Dao 操作类的标识注解
   - @Insert：数据表数据插入操作的标识，使用`onConflict`属性指定插入冲突时的策略，策略存在`OnConflictStrategy`类中
   - @Delete：数据表数据删除操作的标识
   - @Query：数据表数据查询操作的标识。查询时需要输入 SQL 语句，":"用于充当模版字符串的标识
   - @Update：数据表数据更新操作的标识
   - @Embedded：可以在数据库中使用内嵌对象
3. Room 默认生成的`Dao`实现类代码是线程安全的，如不放心，可自己调用数据库的事务操作，保证线程安全