package jp.co.soramitsu.commonnetworking.networkclient

import io.ktor.client.HttpClient
import io.ktor.client.features.ClientRequestException
import io.ktor.client.features.HttpTimeout
import io.ktor.client.features.RedirectResponseException
import io.ktor.client.features.ResponseException
import io.ktor.client.features.ServerResponseException
import io.ktor.client.features.json.JsonFeature
import io.ktor.client.features.json.serializer.KotlinxSerializer
import io.ktor.client.features.logging.LogLevel
import io.ktor.client.features.logging.Logger
import io.ktor.client.features.logging.Logging
import io.ktor.client.features.logging.SIMPLE
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.request
import io.ktor.client.request.url
import io.ktor.client.utils.EmptyContent
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.contentType
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlin.coroutines.cancellation.CancellationException

class SoraNetworkClient(private val timeout: Long = 10000, private val logging: Boolean = false) {

    val httpClient = HttpClient(HttpEngineFactory().createEngine()) {
        if (logging) {
            install(Logging) {
                level = LogLevel.ALL
                logger = Logger.SIMPLE
            }
        }
        install(JsonFeature) {
            serializer = KotlinxSerializer(Json {
                isLenient = true
                ignoreUnknownKeys = true
            })
            acceptContentTypes = acceptContentTypes + ContentType.Any
        }
        install(HttpTimeout) {
            requestTimeoutMillis = timeout
            connectTimeoutMillis = timeout
            socketTimeoutMillis = timeout
        }
    }

    @Throws(SoraNetworkException::class, CancellationException::class)
    suspend fun get(url: String): String {
        return wrapInExceptionHandler {
            httpClient.get(url)
        }
    }

    @Throws(SoraNetworkException::class, CancellationException::class)
    suspend inline fun <reified Value : Any> createRequest(
        path: String,
        methodType: HttpMethod = HttpMethod.Get,
        body: Any = EmptyContent,
        contentType: ContentType? = null,
        headersList: List<Pair<String, String>>? = null
    ): Value {
        @Suppress("SwallowedException")
        return wrapInExceptionHandler {
            httpClient.request {
                if (!headersList.isNullOrEmpty()) {
                    headers {
                        headersList.forEach { pair ->
                            append(pair.first, pair.second)
                        }
                    }
                }
                method = methodType
                url(path)
                if (contentType != null) contentType(contentType)
                this.body = body
            }
        }
    }

    @Throws(SoraNetworkException::class, CancellationException::class)
    suspend inline fun <reified Value : Any> createJsonRequest(
        path: String,
        methodType: HttpMethod = HttpMethod.Get,
        body: Any = EmptyContent
    ): Value =
        createRequest(path, methodType, body, ContentType.Application.Json)

    @Throws(SoraNetworkException::class, CancellationException::class)
    suspend inline fun <reified Value : Any> createJsonRequest(
        path: String,
        methodType: HttpMethod = HttpMethod.Get,
        body: Any = EmptyContent,
        headers: List<Pair<String, String>>,
    ): Value =
        createRequest(path, methodType, body, ContentType.Application.Json, headers)

    @Throws(SoraNetworkException::class)
    inline fun <reified Type : Any> wrapInExceptionHandler(block: () -> Type): Type {
        return try {
            block.invoke()
        } catch (e: ResponseException) {
            val code: Int = when (e) {
                is RedirectResponseException -> 3
                is ClientRequestException -> 4
                is ServerResponseException -> 5
                else -> 0
            }
            throw CodeNetworkException(code, e.message.orEmpty(), e.cause)
        } catch (e: SerializationException) {
            throw SerializationNetworkException(e.message.orEmpty(), e.cause)
        } catch (e: Throwable) {
            throw GeneralNetworkException(e.message.orEmpty(), e.cause)
        }
    }
}

operator fun Headers.plus(other: Headers): Headers = when {
    this.isEmpty() -> other
    other.isEmpty() -> this
    else -> Headers.build {
        appendAll(this@plus)
        appendAll(other)
    }
}
