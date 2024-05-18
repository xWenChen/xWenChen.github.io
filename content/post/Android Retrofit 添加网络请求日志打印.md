---
title: "Android Retrofit 添加网络请求日志打印"
description: "本文讲解了 Android 中如何打印 okhttp 网络请求的信息。"
keywords: "Android,Retrofit,OkHttp"

date: 2023-12-26 19:53:00 +08:00
lastmod: 2023-12-26 19:53:00 +08:00

categories:
  - Android
  - OkHttp
tags:
  - Android
  - Retrofit
  - OkHttp

url: post/B3EF493D842A4181AC4E74BCE1C93EB8.html
toc: true
---

本文讲解了 Android 中如何打印 okhttp 网络请求的信息。

<!--More-->

在 Android 中，要打印 okhttp 的网络请求，主要是在**最后的拦截器之后**添加一个打印日志的拦截器。可以使用两种方式：

- 添加 implementation `'com.squareup.okhttp3:logging-interceptor:3.9.1'` 依赖，使用 HttpLoggingInterceptor 拦截器 `OkHttpClient.Builder().addInterceptor(HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.BODY))`。但是这种方式无法有效的区分 headers 和 RequestBody。

- 自定义日志拦截器，HttpLogInterceptor。注意如果 contentType 是 application/json，则请求体得是 json 串。此时如果使用 `@FormUrlEncoded` + `@Field` 则达不到效果，需要使用 `@Body` 注解。

自定义日志拦截器，可以打印以下信息：url、Request 和 Response 的 method、headers 和 body 信息。以下代码主要是针对请求和响应都是 json 串的场景，其他协议结构需要特殊处理。

```kotlin
package com.my.android.example

import android.util.Log
import okhttp3.Interceptor
import okhttp3.RequestBody
import okhttp3.Response
import okhttp3.ResponseBody
import okio.Buffer
import java.nio.charset.StandardCharsets
import java.util.concurrent.TimeUnit

/**
 * 主要打印 url method code body headers 信息
 */
class HttpLogInterceptor : Interceptor {
    companion object {
        const val TAG = "HttpLogInterceptor"
    }
    val UTF8 = StandardCharsets.UTF_8

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val requestBody = request.body
        // 拿到请求体数据
        val bodyStr = concatBodyStr(requestBody)

        Log.d(TAG, "发送请求："
                + "\n url：${request.url}"
                + "\n method：${request.method}"
                + "\n 请求头：${request.headers}"
                + "\n 请求 body: $bodyStr"
        )

        // 开始请求的时间戳
        val startNs = System.nanoTime()
        // 处理请求，得到响应
        val response = chain.proceed(request)
        // 请求耗时
        val tookMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNs)

        val responseBody = response.body

        val rspBodyStr = concatRspBodyStr(responseBody)

        Log.d(TAG, "收到响应："
                + "\n 请求 url：${response.request.url}"
                + "\n code：${response.code}"
                + "\n method：${response.request.method}"
                + "\n 请求耗时(ms)：$tookMs"
                + "\n 请求头：${response.request.headers}"
                + "\n 请求 body: $bodyStr"
                + "\n 响应 body：$rspBodyStr"
        )

        return response
    }

    private fun concatBodyStr(requestBody: RequestBody?): String {
        requestBody ?: return ""

        val buffer = Buffer()
        requestBody.writeTo(buffer)

        return requestBody.contentType()?.run {
            val charset = this.charset(UTF8) ?: UTF8
            // 从 buffer 数据读取字符串
            buffer.readString(charset)
        } ?: ""
    }

    private fun concatRspBodyStr(responseBody: ResponseBody?): String {
        val rspSource = responseBody?.source() ?: return ""
        rspSource.request(Long.MAX_VALUE)
        val buffer = rspSource.buffer

        return responseBody.contentType()?.run {
            val charset = try {
                this.charset(UTF8) ?: UTF8
            } catch (e: Exception) {
                Log.e(TAG, "", e)
                UTF8
            }
            buffer.clone().readString(charset)
        } ?: ""
    }
}
```