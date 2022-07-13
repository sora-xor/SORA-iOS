package jp.co.soramitsu.xnetworking.subquery.factory

import jp.co.soramitsu.xnetworking.dbengine.DatabaseDriverFactory
import jp.co.soramitsu.xnetworking.dbengine.HistoryDatabaseProvider
import jp.co.soramitsu.xnetworking.networkclient.SoramitsuNetworkClient
import jp.co.soramitsu.xnetworking.subquery.SubQueryClient
import jp.co.soramitsu.xnetworking.subquery.graphql.fearlessHistoryGraphQLRequest
import jp.co.soramitsu.xnetworking.subquery.graphql.soraHistoryGraphQLRequest
import jp.co.soramitsu.xnetworking.subquery.history.SubQueryHistoryInfo
import jp.co.soramitsu.xnetworking.subquery.history.SubQueryHistoryItem
import jp.co.soramitsu.xnetworking.subquery.history.fearless.FearlessMapper
import jp.co.soramitsu.xnetworking.subquery.history.fearless.FearlessSubQueryResponse
import jp.co.soramitsu.xnetworking.subquery.history.sora.SoraMapper
import jp.co.soramitsu.xnetworking.subquery.history.sora.SoraSubqueryResponse
import kotlinx.serialization.DeserializationStrategy

actual class SubQueryClientFactory<T, R> {
    actual fun create(
        soramitsuNetworkClient: SoramitsuNetworkClient,
        baseUrl: String,
        pageSize: Int,
        deserializationStrategy: DeserializationStrategy<T>,
        jsonToHistoryInfo: (T) -> SubQueryHistoryInfo,
        historyIntoToResult: (SubQueryHistoryItem) -> R,
        historyRequest: String,
    ): SubQueryClient<T, R> {
        return SubQueryClient(
            soramitsuNetworkClient,
            baseUrl,
            pageSize,
            deserializationStrategy,
            jsonToHistoryInfo,
            historyIntoToResult,
            historyRequest,
            HistoryDatabaseProvider(DatabaseDriverFactory())
        )
    }
}

object SubQueryClientForFearless {
    fun build(
        soramitsuNetworkClient: SoramitsuNetworkClient,
        baseUrl: String,
        pageSize: Int,
    ): SubQueryClient<FearlessSubQueryResponse, SubQueryHistoryItem> {
        return SubQueryClientFactory<FearlessSubQueryResponse, SubQueryHistoryItem>().create(
            soramitsuNetworkClient = soramitsuNetworkClient,
            baseUrl = baseUrl,
            pageSize = pageSize,
            deserializationStrategy = FearlessSubQueryResponse.serializer(),
            historyIntoToResult = { it },
            historyRequest = fearlessHistoryGraphQLRequest(),
            jsonToHistoryInfo = { response -> FearlessMapper.map(response) },
        )
    }
}

object SubQueryClientForSora {
    fun build(
        soramitsuNetworkClient: SoramitsuNetworkClient,
        baseUrl: String,
        pageSize: Int,
    ): SubQueryClient<SoraSubqueryResponse, SubQueryHistoryItem> {
        return SubQueryClientFactory<SoraSubqueryResponse, SubQueryHistoryItem>().create(
            soramitsuNetworkClient = soramitsuNetworkClient,
            baseUrl = baseUrl,
            pageSize = pageSize,
            deserializationStrategy = SoraSubqueryResponse.serializer(),
            jsonToHistoryInfo = { response -> SoraMapper.map(response) },
            historyIntoToResult = { it },
            historyRequest = soraHistoryGraphQLRequest(),
        )
    }
}
