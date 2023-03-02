package jp.co.soramitsu.xnetworking.txhistory.subquery.response.fearless

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class FearlessSubQueryResponse(
    @SerialName("data")
    val data: FearlessSubQueryResponseData
)

@Serializable
data class FearlessSubQueryResponseData(
    @SerialName("historyElements")
    val historyElements: FearlessHistoryResponseDataElements
)

@Serializable
data class FearlessHistoryResponseDataElements(
    @SerialName("nodes")
    val nodes: List<FearlessHistoryResponseItem>,
    @SerialName("pageInfo")
    val pageInfo: FearlessHistoryResponsePageInfo,
)

@Serializable
data class FearlessHistoryResponsePageInfo(
    @SerialName("endCursor")
    val endCursor: String?,
    @SerialName("hasNextPage")
    val hasNextPage: Boolean,
)

@Serializable
data class FearlessHistoryResponseItem(
    @SerialName("id")
    val id: String,
    @SerialName("timestamp")
    val timestamp: String,
    @SerialName("address")
    val address: String,
    @SerialName("reward")
    val reward: FearlessRewardItem?,
    @SerialName("transfer")
    val transfer: FearlessTransferItem?,
    @SerialName("extrinsic")
    val extrinsic: FearlessExtrinsicItem?,
)

@Serializable
data class FearlessRewardItem(
    @SerialName("era")
    val era: Int,
    @SerialName("amount")
    val amount: String,
    @SerialName("isReward")
    val isReward: Boolean,
    @SerialName("validator")
    val validator: String,
)

@Serializable
data class FearlessTransferItem(
    @SerialName("amount")
    val amount: String,
    @SerialName("to")
    val to: String,
    @SerialName("from")
    val from: String,
    @SerialName("fee")
    val fee: String,
    @SerialName("block")
    val block: String? = null,
    @SerialName("success")
    val success: Boolean,
    @SerialName("extrinsicHash")
    val extrinsicHash: String? = null
)

@Serializable
data class FearlessExtrinsicItem(
    @SerialName("hash")
    val hash: String,
    @SerialName("module")
    val module: String,
    @SerialName("call")
    val call: String,
    @SerialName("fee")
    val fee: String,
    @SerialName("success")
    val success: Boolean
)