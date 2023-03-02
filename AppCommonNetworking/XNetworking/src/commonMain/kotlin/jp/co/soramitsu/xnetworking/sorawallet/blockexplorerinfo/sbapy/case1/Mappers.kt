package jp.co.soramitsu.xnetworking.sorawallet.blockexplorerinfo.sbapy.case1

import jp.co.soramitsu.xnetworking.common.Utils.toDoubleNan
import jp.co.soramitsu.xnetworking.sorawallet.blockexplorerinfo.sbapy.SbApyInfo

internal fun mapSoraWalletSbApyCase1(subQuerySbApyResponse: SoraWalletSbApyCase1Response): List<SbApyInfo> {
    return subQuerySbApyResponse.data.poolXYKs.nodes.map {
        SbApyInfo(
            id = it.id,
            priceUsd = it.priceUSD?.toDoubleNan(),
            sbApy = it.strategicBonusApy?.toDoubleNan(),
        )
    }
}