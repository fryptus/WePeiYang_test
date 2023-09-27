package com.twt.service.common

import androidx.annotation.Keep
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

// 天外太难服务基础配置
abstract class BaseServer(baseUrl:String) {

    open val client = OkHttpClient.Builder()
        .retryOnConnectionFailure(false)
        .build()

    open val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create(GsonBuilder().create()))
            .build()
    }

    inline operator fun <reified T> invoke(): T = retrofit.create(T::class.java)
}

@Keep
data class WBYBaseData<T>(
        val error_code: Int,
        val message: String,
        val result: T?,
)