---
title: "分治法-Strassen矩阵乘法"
description: "本文讲解分治法算法中的Strassen矩阵乘法算法"
keywords: "算法,动态规划算法,Strassen矩阵乘法"

date: 2018-08-15T11:57:29+08:00

categories:
  - 算法
tags:
  - 分治法

url: post/15EA418577D24F268632491FF73EFFA8.html
toc: true
---

**算法思想：分治法**

**实际问题：Strassen 矩阵乘法**

**编写语言：Java**

<!--More-->

## 问题描述

我们知道，两个大小为 2 * 2 的矩阵相乘，一般需要进行 8 次乘法。而Strassen矩阵乘法可以减少一次乘法，只需要 7 次，看似很少，但当数据量很大时，效率就会有显著提升。不过使用 Strassen矩阵乘法需要满足 矩阵边长为 2 的幂次方。因为该算法会用到分治，如果分治后矩阵两边边长不等，结果会出错。

使用下面的方法计算结果矩阵，假设两个长度为 2 的矩阵是 A，B，相乘后的结果矩阵为 C：
```
	M1 = A11(B12 - B22)	注：Anm 表示 A 矩阵第 n 行 k 列的值，Bnm，Cnm 同理
	M2 = (A11 + A12)B22
	M3 = (A21 + A22)B11	 
	M4 = A22(B21 - B11)
	M5 = (A11 + A22)(B11 + B22)
	M6 = (A12 - A22)(B21 + B22)
	M7 = (A11 - A21)(B11 + B12)
```
可得结果为：
```
	C11 = M5 + M4 - M2 + M6
	C12 = M1 + M2
	C21 = M3 + M4
	C22 = M5 + M1 - M3 - M7
```


## Java代码

```Java
public class StrassenMatrixMultiply
{
    public static void main(String[] args)
    {
        int[] a = new int[]
        {
            1, 1, 1, 1,
            2, 2, 2, 2,
            3, 3, 3, 3,
            4, 4, 4, 4
        };

        int[] b = new int[]
        {
            1, 2, 3, 4,
            1, 2, 3, 4,
            1, 2, 3, 4,
            1, 2, 3, 4
        };

        int length = 4;

        int[] c = sMM(a, b, length);

        for(int i = 0; i < c.length; i++)
        {
            System.out.print(c[i] + " ");

            if((i + 1) % length == 0) //换行
                System.out.println();
        }
    }

    public static int[] sMM(int[] a, int[] b, int length)
    {
        if(length == 2)
        {
            return getResult(a, b);
        }
        else
        {
            int tlength = length / 2;
            //把a数组分为四部分，进行分治递归
            int[] aa = new int[tlength * tlength];
            int[] ab = new int[tlength * tlength];
            int[] ac = new int[tlength * tlength];
            int[] ad = new int[tlength * tlength];
            //把b数组分为四部分，进行分治递归
            int[] ba = new int[tlength * tlength];
            int[] bb = new int[tlength * tlength];
            int[] bc = new int[tlength * tlength];
            int[] bd = new int[tlength * tlength];

            //划分子矩阵
            for(int i = 0; i < length; i++)
            {
                for(int j = 0; j < length; j++)
                {
                    /*
                     * 划分矩阵：
                     * 例子：将 4 * 4 的矩阵，变为 2 * 2 的矩阵，
                     * 那么原矩阵左上、右上、左下、右下的四个元素分别归为新矩阵
                    */
                    if(i < tlength)
                    {
                        if(j < tlength)
                        {
                            aa[i * tlength + j] = a[i * length + j];
                            ba[i * tlength + j] = b[i * length + j];
                        }
                        else
                        {
                            ab[i * tlength + (j - tlength)]
                            = a[i * length + j];
                            bb[i * tlength + (j - tlength)]
                            = b[i * length + j];
                        }
                    }
                    else
                    {
                        if(j < tlength)
                        {
                            //i 大于 tlength 时，需要减去 tlength，j同理
                            //因为 b，c，d三个子矩阵有对应了父矩阵的后半部分
                            ac[(i - tlength) * tlength + j]
                            = a[i * length + j];
                            bc[(i - tlength) * tlength + j]
                            = b[i * length + j];
                        }
                        else
                        {
                            ad[(i - tlength) * tlength + (j - tlength)]
                            = a[i * length + j];
                            bd[(i - tlength) * tlength + (j - tlength)]
                            = b[i * length + j];
                        }
                    }
                }
            }

            //分治递归
            int[] result = new int[length * length];

            //temp：4个临时矩阵
            int[] t1 = add(sMM(aa, ba, tlength), sMM(ab, bc, tlength));
            int[] t2 = add(sMM(aa, bb, tlength), sMM(ab, bd, tlength));
            int[] t3 = add(sMM(ac, ba, tlength), sMM(ad, bc, tlength));
            int[] t4 = add(sMM(ac, bb, tlength), sMM(ad, bd, tlength));

            //归并结果
            for(int i = 0; i < length; i++)
            {
                for(int j = 0; j < length; j++)
                {
                    if(i < tlength)
                    {
                        if(j < tlength)
                            result[i * length + j]
                            = t1[i * tlength + j];
                        else
                            result[i * length + j]
                            = t2[i * tlength + (j - tlength)];
                    }
                    else
                    {
                        if(j < tlength)
                            result[i * length + j]
                            = t3[(i - tlength) * tlength + j];
                        else
                            result[i * length + j]
                            = t4[(i - tlength) * tlength + (j - tlength)];
                    }
                }
            }

            return result;
        }
    }

    public static int[] getResult(int[] a, int[] b)
    {
        int p1 = a[0] * (b[1] - b[3]);
        int p2 = (a[0] + a[1]) * b[3];
        int p3 = (a[2] + a[3]) * b[0];
        int p4 = a[3] * (b[2] - b[0]);
        int p5 = (a[0] + a[3]) * (b[0] + b[3]);
        int p6 = (a[1] - a[3]) * (b[2] + b[3]);
        int p7 = (a[0] - a[2]) * (b[0] + b[1]);

        int c00 = p5 + p4 - p2 + p6;
        int c01 = p1 + p2;
        int c10 = p3 + p4;
        int c11 = p5 + p1 -p3 - p7;

        return new int[] {c00, c01, c10, c11};
    }

    public static int[] add(int[] a, int[] b)
    {
        int[] c = new int[a.length];
        for(int i = 0; i < a.length; i++)
            c[i] = a[i] + b[i];

        return c;
    }

    //返回一个数是不是2的幂次方
    public static boolean adjust(int num)
    {
        return (num & (num - 1)) == 0;
    }
}
```

## 运行结果

![结果示例](/imgs/分治法-Strassen矩阵乘法.jpg)

