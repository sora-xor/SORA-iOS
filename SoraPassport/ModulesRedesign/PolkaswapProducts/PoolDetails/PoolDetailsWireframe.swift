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
import UIKit
import SoraUIKit

import RobinHood

protocol PoolDetailsWireframeProtocol: AlertPresentable {
    func showLiquidity(
        on controller: UIViewController?,
        poolInfo: PoolInfo,
        farms: [UserFarm],
        type: Liquidity.TransactionLiquidityType,
        assetManager: AssetManagerProtocol,
        poolsService: PoolsServiceInputProtocol?,
        fiatService: FiatServiceProtocol?,
        farmingService: DemeterFarmingServiceProtocol,
        completionHandler: (() -> Void)?)
    
    func showFarmDetails(
        on viewController: UIViewController?,
        poolsService: PoolsServiceInputProtocol?,
        fiatService: FiatServiceProtocol?,
        assetManager: AssetManagerProtocol,
        farmingService: DemeterFarmingServiceProtocol,
        poolInfo: PoolInfo?,
        farm: Farm
    )
}

final class PoolDetailsWireframe: PoolDetailsWireframeProtocol {
    
    private let feeProvider: FeeProviderProtocol
    private let providerFactory: BalanceProviderFactory
    private let operationFactory: WalletNetworkOperationFactoryProtocol
    private let assetsProvider: AssetProviderProtocol?
    private let marketCapService: MarketCapServiceProtocol
    
    init(feeProvider: FeeProviderProtocol,
         providerFactory: BalanceProviderFactory,
         operationFactory: WalletNetworkOperationFactoryProtocol,
         assetsProvider: AssetProviderProtocol?,
         marketCapService: MarketCapServiceProtocol
    ) {
        self.feeProvider = feeProvider
        self.providerFactory = providerFactory
        self.operationFactory = operationFactory
        self.assetsProvider = assetsProvider
        self.marketCapService = marketCapService
    }
    
    @MainActor
    func showLiquidity(
        on controller: UIViewController?,
        poolInfo: PoolInfo,
        farms: [UserFarm],
        type: Liquidity.TransactionLiquidityType,
        assetManager: AssetManagerProtocol,
        poolsService: PoolsServiceInputProtocol?,
        fiatService: FiatServiceProtocol?,
        farmingService: DemeterFarmingServiceProtocol,
        completionHandler: (() -> Void)?) {
            guard let fiatService = fiatService,
                  let poolsService = poolsService else { return }
            
            guard let assetDetailsController = type == .add ? LiquidityViewFactory.createView(poolInfo: poolInfo,
                                                                                              assetManager: assetManager,
                                                                                              fiatService: fiatService,
                                                                                              poolsService: poolsService,
                                                                                              operationFactory: operationFactory,
                                                                                              assetsProvider: assetsProvider,
                                                                                              marketCapService: marketCapService)
                    :
                        LiquidityViewFactory.createRemoveLiquidityView(poolInfo: poolInfo,
                                                                       farms: farms,
                                                                       assetManager: assetManager,
                                                                       fiatService: fiatService,
                                                                       poolsService: poolsService,
                                                                       providerFactory: providerFactory,
                                                                       operationFactory: operationFactory,
                                                                       assetsProvider: assetsProvider,
                                                                       marketCapService: marketCapService,
                                                                       farmingService: farmingService,
                                                                       completionHandler: completionHandler) else { return }
            
            
            
            let containerView = BlurViewController()
            containerView.modalPresentationStyle = .overFullScreen
            
            let navigationController = UINavigationController(rootViewController: assetDetailsController)
            navigationController.navigationBar.backgroundColor = .clear
            navigationController.addCustomTransitioning()
            
            containerView.add(navigationController)
            
            controller?.present(containerView, animated: true)
        }
    
    @MainActor
    func showFarmDetails(
        on viewController: UIViewController?,
        poolsService: PoolsServiceInputProtocol?,
        fiatService: FiatServiceProtocol?,
        assetManager: AssetManagerProtocol,
        farmingService: DemeterFarmingServiceProtocol,
        poolInfo: PoolInfo?,
        farm: Farm
    ) {
        let walletService = WalletService(operationFactory: operationFactory)
        
        let wireframe = FarmDetailsWireframe(feeProvider: feeProvider,
                                             walletService: walletService,
                                             assetManager: assetManager)
        let userFarmService = UserFarmsService()
        
        let viewModel = FarmDetailsViewModel(farm: farm,
                                             poolInfo: poolInfo,
                                             poolsService: poolsService,
                                             fiatService: fiatService,
                                             providerFactory: providerFactory,
                                             operationFactory: operationFactory,
                                             assetsProvider: assetsProvider,
                                             marketCapService: marketCapService,
                                             farmingService: farmingService,
                                             detailsFactory: DetailViewModelFactory(assetManager: assetManager),
                                             wireframe: wireframe, 
                                             userFarmService: userFarmService)
        
        let view = FarmDetailsViewController(viewModel: viewModel)
        viewModel.view = view
        
        let containerView = BlurViewController()
        containerView.modalPresentationStyle = .overFullScreen

        let navigationController = UINavigationController(rootViewController: view)
        navigationController.navigationBar.backgroundColor = .clear
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        containerView.add(navigationController)
        
        viewController?.present(containerView, animated: true)
    }
}
