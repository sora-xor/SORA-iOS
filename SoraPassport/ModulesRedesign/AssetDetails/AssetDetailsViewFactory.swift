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
import RobinHood


final class AssetDetailsViewFactory {
    static func createView(
        assetInfo: AssetInfo,
        assetManager: AssetManagerProtocol,
        fiatService: FiatServiceProtocol,
        assetViewModelFactory: AssetViewModelFactory,
        poolsService: PoolsServiceInputProtocol,
        poolViewModelsFactory: PoolViewModelFactory,
        providerFactory: BalanceProviderFactory,
        networkFacade: WalletNetworkOperationFactoryProtocol?,
        accountId: String,
        address: String,
        polkaswapNetworkFacade: PolkaswapNetworkOperationFactoryProtocol,
        qrEncoder: WalletQREncoderProtocol,
        sharingFactory: AccountShareFactoryProtocol,
        referralFactory: ReferralsOperationFactoryProtocol,
        assetsProvider: AssetProviderProtocol?,
        marketCapService: MarketCapServiceProtocol,
        farmingService: DemeterFarmingServiceProtocol,
        feeProvider: FeeProviderProtocol,
        dexService: DexInfoService
    )
    -> AssetDetailsViewController? {
        guard let selectedAccount = SelectedWalletSettings.shared.currentAccount,
              let aseetList = assetManager.getAssetList(),
              let assetsProvider = assetsProvider else { return nil }

        let historyService = HistoryService(operationManager: OperationManagerFacade.sharedManager,
                                            address: selectedAccount.address,
                                            assets: aseetList)

        let viewModelFactory = ActivityViewModelFactory(walletAssets: aseetList, assetManager: assetManager)
        
        let eventCenter = EventCenter.shared
        let priceInfoService = PriceInfoService.shared

        let wireframe = AssetDetailsWireframe(
            accountId: accountId,
            address: address,
            assetManager: assetManager,
            fiatService: fiatService,
            eventCenter: eventCenter,
            assetInfo: assetInfo,
            providerFactory: providerFactory,
            networkFacade: networkFacade,
            polkaswapNetworkFacade: polkaswapNetworkFacade,
            assetsProvider: assetsProvider,
            marketCapService: marketCapService,
            qrEncoder: qrEncoder,
            sharingFactory: sharingFactory, 
            farmingService: farmingService,
            feeProvider: feeProvider,
            dexService: dexService
        )
        
        let recentActivityService = RecentActivityItemService(assetId: assetInfo.assetId,
                                                              viewModelFactory: viewModelFactory,
                                                              historyService: historyService,
                                                              eventCenter: eventCenter,
                                                              assetsProvider: assetsProvider)
        
        let transferableItemService = TransferableItemService(assetInfo: assetInfo,
                                                              eventCenter: eventCenter,
                                                              assetsProvider: assetsProvider,
                                                              referralFactory: referralFactory)
        
        let itemsFactory = AssetDetailsItemFactory(assetsProvider: assetsProvider,
                                                   poolViewModelsFactory: poolViewModelsFactory,
                                                   historyService: historyService,
                                                   recentActivityService: recentActivityService,
                                                   wireframe: wireframe, 
                                                   poolsService: poolsService,
                                                   transferableItemService: transferableItemService)

        let viewModel = AssetDetailsViewModel(wireframe: wireframe,
                                              assetInfo: assetInfo,
                                              referralFactory: referralFactory,
                                              priceInfoService: priceInfoService,
                                              itemsFactory: itemsFactory)

        let view = AssetDetailsViewController(viewModel: viewModel)
        viewModel.view = view
        wireframe.controller = view
        return view
    }
}



