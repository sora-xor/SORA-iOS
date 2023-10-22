// This file is part of the SORA network and Polkaswap app.

// Copyright (c) 2022, 2023, Polka Biome Ltd. All rights reserved.
// SPDX-License-Identifier: BSD-4-Clause

// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:

// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or other
// materials provided with the distribution.
//
// All advertising materials mentioning features or use of this software must display
// the following acknowledgement: This product includes software developed by Polka Biome
// Ltd., SORA, and Polkaswap.
//
// Neither the name of the Polka Biome Ltd. nor the names of its contributors may be used
// to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY Polka Biome Ltd. AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Polka Biome Ltd. BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import SoraUIKit
import CommonWallet
import sorawallet
import FearlessUtils
import SoraFoundation

final class PoolDetailsItemFactory {
    func createAccountItem(
        with assetManager: AssetManagerProtocol,
        poolInfo: PoolInfo,
        apy: Decimal?,
        detailsFactory: DetailViewModelFactoryProtocol,
        viewModel: PoolDetailsViewModelProtocol,
        pools: [StakedPool]
    ) -> SoramitsuTableViewItemProtocol {

        let baseAsset = assetManager.assetInfo(for: poolInfo.baseAssetId)
        let targetAsset = assetManager.assetInfo(for: poolInfo.targetAssetId)
        let rewardAsset = assetManager.assetInfo(for: WalletAssetId.pswap.rawValue)
        
        let baseAssetSymbol = baseAsset?.symbol.uppercased() ?? ""
        let targetAssetSymbol = targetAsset?.symbol.uppercased() ?? ""
        
        let poolText = R.string.localizable.polkaswapPoolTitle(preferredLanguages: .currentLocale)
        
        let title = "\(baseAssetSymbol)-\(targetAssetSymbol) \(poolText)"
        
        let detailsViewModels = detailsFactory.createPoolDetailViewModels(with: poolInfo, apy: apy, viewModel: viewModel)

        let isRemoveLiquidityEnabled = pools.map {
            let pooledTokens = Decimal.fromSubstrateAmount($0.pooledTokens, precision: 18) ?? .zero
            let accountPoolBalance = poolInfo.accountPoolBalance ?? .zero
            return (pooledTokens / accountPoolBalance) == 1
        }.filter { $0 }.isEmpty
        
        let isThereLiquidity = poolInfo.baseAssetPooledByAccount != nil && poolInfo.targetAssetPooledByAccount != nil
        
        let detailsItem = PoolDetailsItem(title: title,
                                          firstAssetImage: baseAsset?.icon,
                                          secondAssetImage: targetAsset?.icon,
                                          rewardAssetImage: rewardAsset?.icon,
                                          detailsViewModel: detailsViewModels,
                                          isRemoveLiquidityEnabled: isRemoveLiquidityEnabled,
                                          isThereLiquidity: isThereLiquidity)
        detailsItem.handler = { type in
            viewModel.infoButtonTapped(with: type)
        }

        return detailsItem
    }
    
    
    func stakedItem(with assetManager: AssetManagerProtocol, poolInfo: PoolInfo, stakedPool: StakedPool) -> SoramitsuTableViewItemProtocol {
        let rewardAsset = assetManager.assetInfo(for: stakedPool.rewardAsset.value)
        let rewardSymbol = rewardAsset?.symbol.uppercased() ?? ""
        
        let accountPoolBalance = poolInfo.accountPoolBalance ?? .zero
        let pooledTokens = Decimal.fromSubstrateAmount(stakedPool.pooledTokens, precision: 18) ?? .zero
        let percentage = accountPoolBalance > 0 ? (pooledTokens / accountPoolBalance) * 100 : 0

        let progressTitle = R.string.localizable.polkaswapFarmingPoolShare(preferredLanguages: .currentLocale)

        let text = SoramitsuTextItem(text: "\(NumberFormatter.percent.stringFromDecimal(percentage) ?? "")%",
                                     fontData: FontType.textS,
                                     textColor: .fgPrimary,
                                     alignment: .right)

        let progressDetails = DetailViewModel(title: progressTitle,
                                              assetAmountText: text,
                                              type: .progress(percentage.floatValue))
        
        let rewardText = SoramitsuTextItem(text: rewardSymbol,
                                           fontData: FontType.textS,
                                           textColor: .fgPrimary,
                                           alignment: .right)

        let rewardDetailsViewModel = DetailViewModel(title: R.string.localizable.polkaswapRewardPayout(preferredLanguages: .currentLocale),
                                                     rewardAssetImage: rewardAsset?.icon,
                                                     assetAmountText: rewardText)

        let title = R.string.localizable.polkaswapFarmingStakedFor(rewardSymbol, preferredLanguages: .currentLocale)
        return StakedItem(title: title, detailsViewModel: [rewardDetailsViewModel, progressDetails])
    }
}

extension Decimal {
    var floatValue: Float {
        return NSDecimalNumber(decimal:self).floatValue
    }
}
