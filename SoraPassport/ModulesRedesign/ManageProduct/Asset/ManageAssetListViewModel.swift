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

import UIKit
import SoraUIKit
import CommonWallet
import RobinHood

protocol ManageAssetListViewModelProtocol: Produtable {
    typealias ItemType = AssetListItem
}

final class ManageAssetListViewModel {

    var setupNavigationBar: ((WalletViewMode) -> Void)?
    var setupItems: (([SoramitsuTableViewItemProtocol]) -> Void)?
    var reloadItems: (([SoramitsuTableViewItemProtocol]) -> Void)?
    var dissmiss: ((Bool) -> Void)?
    var updateHandler: (() -> Void)?

    var assetItems: [AssetListItem] = [] {
        didSet {
            setupTableViewItems(with: assetItems)
        }
    }

    var filteredAssetItems: [AssetListItem] = [] {
        didSet {
            setupTableViewItems(with: filteredAssetItems)
        }
    }

    var isNeedZeroBalance: Bool = false {
        didSet {
            setupTableViewItems(with: isActiveSearch ? filteredAssetItems : assetItems)
        }
    }

    var mode: WalletViewMode = .view {
        didSet {
            if mode == .view {
                saveUpdates()
            }

            setupNavigationBar?(mode)

            assetItems.forEach { item in
                item.assetViewModel.mode = mode
            }

            setupTableViewItems(with: isActiveSearch ? filteredAssetItems : assetItems)
        }
    }

    var isActiveSearch: Bool = false {
        didSet {
            setupTableViewItems(with: isActiveSearch ? filteredAssetItems : assetItems)
        }
    }

    var searchText: String = "" {
        didSet {
            guard !searchText.isEmpty else {
                setupTableViewItems(with: assetItems)
                return
            }
            filterAssetList(with: searchText.lowercased())
        }
    }

    weak var assetManager: AssetManagerProtocol?
    var assetViewModelFactory: AssetViewModelFactory
    weak var fiatService: FiatServiceProtocol?
    var providerFactory: BalanceProviderFactory
    var poolService: PoolsServiceInputProtocol
    var networkFacade: WalletNetworkOperationFactoryProtocol?
    var accountId: String
    var address: String
    var polkaswapNetworkFacade: PolkaswapNetworkOperationFactoryProtocol
    var qrEncoder: WalletQREncoderProtocol
    var sharingFactory: AccountShareFactoryProtocol
    var wireframe: AssetListWireframeProtocol = AssetListWireframe()
    weak var view: UIViewController?
    let referralFactory: ReferralsOperationFactoryProtocol
    private weak var assetsProvider: AssetProviderProtocol?
    private var marketCapService: MarketCapServiceProtocol
    private var priceTrendService: PriceTrendServiceProtocol = PriceTrendService()

    init(assetViewModelFactory: AssetViewModelFactory,
         fiatService: FiatServiceProtocol,
         assetManager: AssetManagerProtocol?,
         providerFactory: BalanceProviderFactory,
         poolService: PoolsServiceInputProtocol,
         networkFacade: WalletNetworkOperationFactoryProtocol?,
         accountId: String,
         address: String,
         polkaswapNetworkFacade: PolkaswapNetworkOperationFactoryProtocol,
         qrEncoder: WalletQREncoderProtocol,
         sharingFactory: AccountShareFactoryProtocol,
         referralFactory: ReferralsOperationFactoryProtocol,
         assetsProvider: AssetProviderProtocol?,
         marketCapService: MarketCapServiceProtocol,
         updateHandler: (() -> Void)?
    ) {
        self.assetViewModelFactory = assetViewModelFactory
        self.fiatService = fiatService
        self.assetManager = assetManager
        self.providerFactory = providerFactory
        self.poolService = poolService
        self.networkFacade = networkFacade
        self.accountId = accountId
        self.address = address
        self.polkaswapNetworkFacade = polkaswapNetworkFacade
        self.qrEncoder = qrEncoder
        self.sharingFactory = sharingFactory
        self.referralFactory = referralFactory
        self.updateHandler = updateHandler
        self.assetsProvider = assetsProvider
        self.marketCapService = marketCapService
    }
}

extension ManageAssetListViewModel: ManageAssetListViewModelProtocol {
    var searchBarPlaceholder: String {
        R.string.localizable.assetListSearchPlaceholder(preferredLanguages: .currentLocale)
    }

    func viewDidLoad() {
        setupNavigationBar?(mode)
        assetsProvider?.add(observer: self)
    }
    
    func viewDissmissed() {
        updateHandler?()
    }
}

extension ManageAssetListViewModel: AssetProviderObserverProtocol {
    func processBalance(data: [BalanceData]) {
        let ids = (assetManager?.getAssetList() ?? []).map { $0.identifier }
        let balanceData = data.filter { ids.contains($0.identifier) }
        self.items(with: balanceData)
    }
}

private extension ManageAssetListViewModel {
    func items(with balanceItems: [BalanceData]) {
        Task {
            async let fiatData = self.fiatService?.getFiat() ?? []
            
            async let assetInfo = self.marketCapService.getMarketCap()
            
            let poolItemInfo = await PoolItemInfo(fiatData: fiatData, marketCapInfo: assetInfo)

            self.assetItems = balanceItems.compactMap { balance in
                
                let deltaPrice = priceTrendService.getPriceTrend(for: balance.identifier,
                                                                 fiatData: poolItemInfo.fiatData,
                                                                 marketCapInfo: poolItemInfo.marketCapInfo)
                
                guard let assetInfo = assetManager?.assetInfo(for: balance.identifier),
                      let viewModel = assetViewModelFactory.createAssetViewModel(with: balance,
                                                                                 fiatData: poolItemInfo.fiatData,
                                                                                 mode: mode,
                                                                                 priceDelta: deltaPrice) else {
                    return nil
                }
                
                let item = AssetListItem(assetInfo: assetInfo,
                                         assetViewModel: viewModel,
                                         balance: balance.balance.decimalValue)

                item.assetHandler = { [weak self] identifier in
                    self?.showAssetDetails(with: assetInfo)
                }
        
                item.favoriteHandle = { item in
                    item.assetInfo.visible = !item.assetInfo.visible
                }
                
                return item
            }.sorted { $0.assetViewModel.isFavorite && !$1.assetViewModel.isFavorite }
        }
    }

    func filterAssetList(with query: String) {
        filteredAssetItems = self.assetItems.filter { item in
            return item.assetInfo.assetId.lowercased().contains(query) ||
            item.assetInfo.symbol.lowercased().contains(query) ||
            item.assetViewModel.title.lowercased().contains(query)
        }
    }

    func saveUpdates() {
        let assetInfos = self.assetItems.map({ $0.assetInfo })
        assetManager?.saveAssetList(assetInfos)
    }    
    
    func setupTableViewItems(with items: [AssetListItem]) {
        if mode == .edit || isActiveSearch {
            setupItems?(items)
            return
        }

        let aboveZero = items.filter { WalletAssetId(rawValue: $0.assetInfo.assetId) != nil || $0.assetInfo.visible || !$0.balance.isZero }
        let underZero = items.filter { WalletAssetId(rawValue: $0.assetInfo.assetId) == nil && !$0.assetInfo.visible && $0.balance.isZero }
        var resultItems: [SoramitsuTableViewItemProtocol] = aboveZero
        
        if aboveZero.count < items.count, underZero.count > 0 {
            let zeroItem = ZeroBalanceItem(isShown: isNeedZeroBalance)

            zeroItem.buttonHandler = { [weak self] in
                guard let self = self else { return }
                self.isNeedZeroBalance = !self.isNeedZeroBalance
                self.reloadItems?([zeroItem])
            }

            resultItems.append(zeroItem)
        }
        
        if isNeedZeroBalance {
            resultItems.append(contentsOf: underZero)
        }

        setupItems?(resultItems)
    }

    func setupBalanceDataProvider() {
        let ids = (assetManager?.getAssetList() ?? []).map { $0.identifier }
        if let balanceData = assetsProvider?.getBalances(with: ids) {
            items(with: balanceData)
        }
    }
    
    func showAssetDetails(with assetInfo: AssetInfo) {
        guard let assetManager = assetManager, let fiatService = fiatService else { return }

        let factory = AssetViewModelFactory(walletAssets: [assetInfo],
                                            assetManager: assetManager,
                                            fiatService: fiatService)

        let poolFactory = PoolViewModelFactory(walletAssets: assetManager.getAssetList() ?? [],
                                            assetManager: assetManager,
                                               fiatService: fiatService)

        wireframe.showAssetDetails(on: view,
                                   assetInfo: assetInfo,
                                   assetManager: assetManager,
                                   fiatService: fiatService,
                                   assetViewModelFactory: factory,
                                   poolsService: poolService,
                                   poolViewModelsFactory: poolFactory,
                                   providerFactory: providerFactory,
                                   networkFacade: networkFacade,
                                   accountId: accountId,
                                   address: address,
                                   polkaswapNetworkFacade: polkaswapNetworkFacade,
                                   qrEncoder: qrEncoder,
                                   sharingFactory: sharingFactory,
                                   referralFactory: referralFactory,
                                   assetsProvider: assetsProvider,
                                   marketCapService: marketCapService)
    }
}
