package jp.co.soramitsu.commonnetworking.subquery

object SubQueryMapper {

    fun map(subQuerySbApyResponse: SubQuerySbApyResponse): List<SbApyInfo> {
        return subQuerySbApyResponse.data.poolXYKEntities.nodes.firstOrNull()?.pools?.edges?.map {
            SbApyInfo(
                tokenId = it.node.targetAssetId,
                priceUsd = it.node.priceUSD?.toDouble(),
                sbApy = it.node.strategicBonusApy?.toDouble(),
            )
        } ?: emptyList()
    }
}