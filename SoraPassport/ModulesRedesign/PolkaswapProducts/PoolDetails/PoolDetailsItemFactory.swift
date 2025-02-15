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

import sorawallet
import SSFUtils
import SoraFoundation

final class PoolDetailsItemFactory {
    func createPoolDetailsItem(
        with assetManager: AssetManagerProtocol,
        poolInfo: PoolInfo,
        detailsFactory: DetailViewModelFactoryProtocol,
        viewModel: PoolDetailsViewModelProtocol?,
        farms: [UserFarm],
        service: PoolDetailsItemServiceProtocol
    ) -> PoolDetailsItem {

        let baseAsset = assetManager.assetInfo(for: poolInfo.baseAssetId)
        let targetAsset = assetManager.assetInfo(for: poolInfo.targetAssetId)
        let rewardAsset = assetManager.assetInfo(for: WalletAssetId.pswap.rawValue)
        
        let baseAssetSymbol = baseAsset?.symbol.uppercased() ?? ""
        let targetAssetSymbol = targetAsset?.symbol.uppercased() ?? ""
        
        let poolText = R.string.localizable.polkaswapPoolTitle(preferredLanguages: .currentLocale)
        
        let title = "\(baseAssetSymbol)-\(targetAssetSymbol) \(poolText)"
        
        let isRemoveLiquidityEnabled = farms.map {
            let pooledTokens = $0.pooledTokens ?? .zero
            let accountPoolBalance = poolInfo.accountPoolBalance ?? .zero
            return (pooledTokens / accountPoolBalance) == 1
        }.filter { $0 }.isEmpty
        
        let isThereLiquidity = poolInfo.baseAssetPooledByAccount != nil && poolInfo.targetAssetPooledByAccount != nil
        
        let detailsViewModels = detailsFactory.createPoolDetailViewModels(with: poolInfo, apy: nil, viewModel: viewModel)
        
        let detailsItem = PoolDetailsItem(title: title,
                                          firstAssetImage: baseAsset?.icon,
                                          secondAssetImage: targetAsset?.icon,
                                          rewardAssetImage: rewardAsset?.icon,
                                          isRemoveLiquidityEnabled: isRemoveLiquidityEnabled, 
                                          typeImage: isThereLiquidity ? .activePoolWithFarming : .inactivePoolWithFarming,
                                          isThereLiquidity: isThereLiquidity,
                                          detailsViewModels: detailsViewModels,
                                          poolInfo: poolInfo,
                                          service: service)
        detailsItem.handler = { [weak viewModel] type in
            viewModel?.infoButtonTapped(with: type)
        }

        return detailsItem
    }
    
    func farmsItem(with assetManager: AssetManagerProtocol, poolInfo: PoolInfo, farms: [Farm] = []) -> [FarmViewModel] {
        return poolInfo.farms.compactMap { userFarm in

            let baseAsset = assetManager.assetInfo(for: userFarm.baseAssetId)
            let poolAsset = assetManager.assetInfo(for: userFarm.poolAssetId)
            let rewardAsset = assetManager.assetInfo(for: userFarm.rewardAssetId)
            
            let baseAssetSymbol = baseAsset?.symbol ?? ""
            let poolAssetSymbol = poolAsset?.symbol ?? ""
            let rewardAssetSymbol = rewardAsset?.symbol ?? ""
            
            let baseAssetId = baseAsset?.assetId ?? ""
            let poolAssetId = poolAsset?.assetId ?? ""
            let rewardAssetId = rewardAsset?.assetId ?? ""

            let title = "\(baseAssetSymbol)-\(poolAssetSymbol)"
            let id = "\(baseAssetId)-\(poolAssetId)-\(rewardAssetId)"
            
            let rewards = NumberFormatter.cryptoAmounts.stringFromDecimal(userFarm.rewards ?? .zero) ?? ""
            let subtitle = R.string.localizable.poolDetailsReward(preferredLanguages: .currentLocale) + ": \(rewards) \(rewardAssetSymbol)"
            
            let accountPoolBalance = poolInfo.accountPoolBalance ?? .zero
            let pooledTokens = userFarm.pooledTokens ?? .zero
            let percentage = accountPoolBalance > 0 ? (pooledTokens / accountPoolBalance) * 100 : 0

            let percentageText = "\(NumberFormatter.percent.stringFromDecimal(percentage) ?? "")%"
            
            var aprText = ""
            if let apr = farms.first(where: { $0.rewardAsset?.assetId == userFarm.rewardAssetId })?.apr {
                aprText = "\(NumberFormatter.percent.stringFromDecimal(apr * 100) ?? "")% APR"
            }
            
            return FarmViewModel(identifier: id,
                                 title: title,
                                 subtitle: subtitle,
                                 baseAssetImage: RemoteSerializer.shared.image(with: baseAsset?.icon ?? ""),
                                 targetAssetImage: RemoteSerializer.shared.image(with: poolAsset?.icon ?? ""),
                                 rewardAssetImage: RemoteSerializer.shared.image(with: rewardAsset?.icon ?? ""),
                                 aprText: aprText,
                                 percentageText: percentageText,
                                 isFarmed: true)
        }
    }
    
    func farmsItem(with farms: [Farm] = []) -> [FarmViewModel] {
        return farms.compactMap { farm in

            let baseAsset = farm.baseAsset
            let poolAsset = farm.poolAsset
            let rewardAsset = farm.rewardAsset
            
            let baseAssetSymbol = baseAsset?.symbol ?? ""
            let poolAssetSymbol = poolAsset?.symbol ?? ""
            
            let baseAssetId = baseAsset?.assetId ?? ""
            let poolAssetId = poolAsset?.assetId ?? ""
            let rewardAssetId = rewardAsset?.assetId ?? ""
            
            let id = "\(baseAssetId)-\(poolAssetId)-\(rewardAssetId)"
            let title = "\(baseAssetSymbol)-\(poolAssetSymbol)"
            
            let subtitle = "$" + farm.tvl.formatNumber()
            
            let aprText = "\(NumberFormatter.percent.stringFromDecimal(farm.apr * 100) ?? "")% APR"

            return FarmViewModel(identifier: id,
                                 title: title,
                                 subtitle: subtitle,
                                 baseAssetImage: RemoteSerializer.shared.image(with: baseAsset?.icon ?? ""),
                                 targetAssetImage: RemoteSerializer.shared.image(with: poolAsset?.icon ?? ""),
                                 rewardAssetImage: RemoteSerializer.shared.image(with: rewardAsset?.icon ?? ""),
                                 aprText: aprText,
                                 isFarmed: false)
        }
    }
    
    func farmDetail(with farm: Farm, 
                    poolInfo: PoolInfo?,
                    userFarmInfo: UserFarm?,
                    detailsFactory: DetailViewModelFactoryProtocol,
                    viewModel: FarmDetailsViewModelProtocol,
                    supplyItem: SupplyPoolItem?,
                    fiatData: [FiatData] = []
    ) -> FarmDetailsItem {
        let baseAssetSymbol = farm.baseAsset?.symbol ?? ""
        let poolAssetSymbol = farm.poolAsset?.symbol ?? ""
        let title = R.string.localizable.polkaswapFarmTitleTemplate("\(baseAssetSymbol)-\(poolAssetSymbol)", preferredLanguages: .currentLocale)
        
        
        let detailsViewModels = detailsFactory.createFarmDetailViewModels(with: farm, 
                                                                          userFarmInfo: userFarmInfo,
                                                                          poolInfo: poolInfo,
                                                                          fiatData: fiatData,
                                                                          viewModel: viewModel)
        
        let rewardsAmount = userFarmInfo?.rewards ?? .zero
        let pooledTokens = userFarmInfo?.pooledTokens ?? .zero
        
        var stackingState: FarmDetailsBottomButtonState = .stackingUnavailable

        if let pooledByAccount = poolInfo?.baseAssetPooledByAccount, !(pooledByAccount.isZero) {
            if pooledTokens.isZero {
                stackingState = rewardsAmount.isZero ? .startStacking : .startStackingWithRewards
            } else {
                stackingState = .editFarm
            }
        }
        
        let farmDetailsItem = FarmDetailsItem(title: title,
                                              subtitle: "$" + (farm.tvl).formatNumber() + " TVL",
                                              firstAssetImage: RemoteSerializer.shared.image(with: farm.baseAsset?.icon ?? ""),
                                              secondAssetImage: RemoteSerializer.shared.image(with: farm.poolAsset?.icon ?? ""),
                                              rewardAssetImage: RemoteSerializer.shared.image(with: farm.rewardAsset?.icon ?? ""),
                                              detailsViewModel: detailsViewModels,
                                              typeImage: (userFarmInfo?.pooledTokens ?? 0) > 0 ? .activeFarming : .incativeFarming,
                                              stackingState: stackingState,
                                              areThereRewards: !rewardsAmount.isZero,
                                              supplyItem: supplyItem)
        
        farmDetailsItem.onTapTopButton = { [weak viewModel] in
            viewModel?.claimRewardButtonTapped()
        }
        
        farmDetailsItem.onTapBottomButton = { [weak viewModel] in
            viewModel?.editFarmButtonTapped()
        }
        
        return farmDetailsItem
    }
    
    func createSupplyLiquidityItem(poolViewModel: ExplorePoolViewModel,
                                   viewModel: FarmDetailsViewModelProtocol) -> SupplyPoolItem {
        let supplyItem = SupplyPoolItem(poolViewModel: poolViewModel)
        
        supplyItem.onTap = { [weak viewModel] in
            viewModel?.supplyLiquidityTapped()
        }
        
        return supplyItem
    }
}

extension Decimal {
    var floatValue: Float {
        return NSDecimalNumber(decimal:self).floatValue
    }
}
