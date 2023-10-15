---
title: "回溯法-N皇后问题"
description: "本文讲解回溯法算法中的N皇后问题算法"
keywords: "算法,回溯法,N皇后问题"

date: 2019-07-18 22:58:03 +08:00
lastmod: 2019-07-18 22:58:03 +08:00

categories:
  - 算法
tags:
  - 回溯法

url: post/23FEAE8600134C1CB795530EDC7125F0.html
toc: true
---

**算法思想：回溯法**
**实际问题：N皇后问题**
**编写语言：Java**

<!--More-->

## 问题描述

&emsp;&emsp;N 皇后问题要求求解**在 N × N 的棋盘上放置 N 个皇后**，并使各皇后彼此不受攻击的所有可能的棋盘布局。皇后彼此不受攻击的约束条件是：**任何两个皇后均不能在棋盘上同一行、同一列或者同一对角线上出现**。

## 解题思路

&emsp;&emsp;由于N皇后问题不允许两个皇后在同一行，所以，可用一维数组 column 表示 N 皇后问题的解，column[i] 表示第 i 行的皇后所在的列号。由上述 column 数组求解 N 皇后问题，保证了任意两个皇后不在同一行上，我们只需判定皇后彼此不受攻击的其他条件，具体描述如下：
- 若 column[i] = column[j]，则第 i 行与第 j 行皇后在同一列上。包含 (i, column[i])，(j, column[j]) 的解不可行。
- 第 i 行的皇后在第 j 列，第 s 行皇后在第 t 列，即 column[i] = j 和 column[s] = t，若 |i - s| = |j - t|，则皇后在同一对角线上。因为棋盘为正方形，对角线的斜率为 1。包含这种放置方式的解不可行。

## Java 代码

&emsp;&emsp;有了上述的约束条件（即剪枝函数），则可以编写 Java 代码了。下面的 Java 代码采用的是**递归回溯**的方法（另有**迭代回溯**的方法）。

```java
import java.util.Scanner;
 
public class NQueenProblem {
    
    private static int result;
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        
        System.out.print("请输入皇后的数量：");
        int number = input.nextInt();
        
        // column[i] 表示第 i 行的皇后(也是第 i 个皇后)放在第 column[i] 列
        int[] column = new int[number];
        
        backtrack(column, 0, number);
        
        System.out.println("\n可行的结果数量为：" + result);
    }
    
    /**
     * 求取 N 皇后问题的解，输出所有可行的答案
     *
     * @param column 存储列数据的数组
     * @param row 当前求解的行数，，即从第 row 行开始求解放置方案
     * @param number 皇后的数量，即总行数
     */
    private static void backtrack(int[] column, int row, int number) {
        // 行数达标，输出结果
        if(row >= number) {
            System.out.println();
            for(int i = 0; i < number; i++) {
                for(int j = 0; j < number; j++) {
                    // 输出第 i 个皇后的位置
                    if(j == column[i]) {
                        System.out.print((i + 1) + " ");
                    } else {
                        System.out.print(0 + " ");
                    }
                }
                System.out.println();
            }
            
            result++;
        } else {
            for(int i = 0; i < number; i++) {
                column[row] = i;
                // 如果当前位置可以放皇后，则进行下一行的位置
                if(place(row, column)) {
                    backtrack(column, row + 1, number);
                }
            }
        }        
    }
    
    /**
     * 判断当前位置是否可以放皇后
     * 1、行相同或者列相同，不能放皇后
     * 2、|row1 - row2| = |column1 - column2|，即两个皇后不能处于
     *  对角线上(斜率为 1)
     *
     * @param row 当前位置所在的行数
     * @param column 列数组，用以通过行确定列。
     */
    private static boolean place(int row, int[] column) {
        for(int i = 0; i < row; i++) {
            if((column[i] == column[row]) || 
                (Math.abs(i - row) == Math.abs(column[i] - column[row]))) {
                return false;
            }
        }
		
        return true;
    }
}
```

## 实验结果

&emsp;&emsp;下图为皇后为 6 的结果：
![6 皇后结果实例](/imgs/回溯法-N皇后问题-6皇后.png)

&emsp;&emsp;下图为皇后为 4 的结果：
![6 皇后结果实例](/imgs/回溯法-N皇后问题-4皇后.png)

&emsp;&emsp;上面的实验结果可以验证代码的正确性。