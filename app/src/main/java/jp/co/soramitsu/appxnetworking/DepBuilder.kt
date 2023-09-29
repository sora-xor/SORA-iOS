package jp.co.soramitsu.appxnetworking

import android.content.Context
import jp.co.soramitsu.xnetworking.basic.networkclient.SoramitsuNetworkClient
import jp.co.soramitsu.xnetworking.fearlesswallet.chainbuilder.FearlessChainsBuilder
import jp.co.soramitsu.xnetworking.fearlesswallet.txhistory.client.SubQueryClientForFearlessWallet
import jp.co.soramitsu.xnetworking.fearlesswallet.txhistory.client.SubQueryClientForFearlessWalletFactory
import jp.co.soramitsu.xnetworking.sorawallet.blockexplorerinfo.SoraWalletBlockExplorerInfo
import jp.co.soramitsu.xnetworking.sorawallet.mainconfig.SoraRemoteConfigProvider
import jp.co.soramitsu.xnetworking.sorawallet.tokenwhitelist.SoraTokensWhitelistManager
import jp.co.soramitsu.xnetworking.sorawallet.txhistory.client.SubQueryClientForSoraWallet
import jp.co.soramitsu.xnetworking.sorawallet.txhistory.client.SubQueryClientForSoraWalletFactory

object DepBuilder {

    private val soraNetworkClient = SoramitsuNetworkClient(logging = true)
    private val fearlessChainsBuilder = FearlessChainsBuilder(
        soraNetworkClient,
        "https://raw.githubusercontent.com/arvifox/arvifoxandroid/develop/felete/",
        "chains/index_android.json"
    )

    lateinit var subQueryClientForSoraWallet: SubQueryClientForSoraWallet
    lateinit var subQueryClientForFearlessWallet: SubQueryClientForFearlessWallet
    lateinit var networkService: NetworkService

    fun build(ctx: Context) {
        val soraRemoteConfigBuilder = SoraRemoteConfigProvider(
            ctx,
            soraNetworkClient,
            "https://config.polkaswap2.io/dev/common.json",
            "https://config.polkaswap2.io/dev/mobile.json",
        ).provide()
        subQueryClientForSoraWallet =
            SubQueryClientForSoraWalletFactory(
                ctx
            ).create(
                soraNetworkClient,
                30,
                soraRemoteConfigBuilder,
            )
        subQueryClientForFearlessWallet =
            SubQueryClientForFearlessWalletFactory(
                ctx
            ).create(
                soraNetworkClient,
                30,
            )
        networkService = NetworkService(
            soraNetworkClient,
            fearlessChainsBuilder,
            soraRemoteConfigBuilder,
            subQueryClientForFearlessWallet,
            subQueryClientForSoraWallet,
            SoraWalletBlockExplorerInfo(
                soraNetworkClient,
                soraRemoteConfigBuilder,
            ),
            SoraTokensWhitelistManager(
                soraNetworkClient
            ),
        )
    }
}