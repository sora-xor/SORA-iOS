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
import SoraKeystore
import SSFUtils
import RobinHood

typealias RuntimeServiceProtocol = RuntimeRegistryServiceProtocol & RuntimeCodingServiceProtocol

final class SplashInteractor: SplashInteractorProtocol {
    weak var presenter: SplashPresenterProtocol!
    let settings: SettingsManagerProtocol
    let socketService: WebSocketServiceProtocol
    let configService: ConfigServiceProtocol
    let reachabilityManager: ReachabilityManagerProtocol? = ReachabilityManager.shared
    let eventCenter: EventCenterProtocol
    private var assetProvider: AssetsInfoProvider?
    private let whitelistService: WhitelistService

    init(settings: SettingsManagerProtocol,
         socketService: WebSocketServiceProtocol,
         configService: ConfigServiceProtocol,
         eventCenter: EventCenterProtocol,
         whitelistService: WhitelistService = WhitelistServiceDefault()
    ) {
        self.settings = settings
        self.socketService = socketService
        self.configService = configService
        self.eventCenter = eventCenter
        self.whitelistService = whitelistService
        self.eventCenter.add(observer: self)
    }

    func setup() {
        configService.setupConfig { [weak self] in
            self?.socketService.setup()
            self?.loadGenesis()
        }
    }

    private func loadGenesis() {
        let provider = GenesisProvider(engine: socketService.connection!)
        provider.load(completion: { [weak self] genesis in
            self?.didLoadGenesis(genesis)
        })
    }

    private func didLoadGenesis(_ genesis: String?) {
        if let genesis = genesis {
            self.settings.set(value: genesis, for: SettingsKey.externalGenesis.rawValue)
            Logger.shared.info("Runtime update gen: " + genesis)
        }

        DispatchQueue.main.async {
            self.startChain()
        }
        
        if let genesis {
            loadAssetsInfo(chainId: genesis)
        }
    }

    private func loadAssetsInfo(chainId: String) {
        let storage: CoreDataRepository<AssetInfo, CDAssetInfo> = SubstrateDataStorageFacade.shared.createRepository()
        assetProvider = AssetsInfoProvider(
            engine: socketService.connection!,
            storageKeyFactory: StorageKeyFactory(),
            storage: storage,
            chainId: chainId,
            whitelistService: whitelistService
        )
        assetProvider?.load { [weak self] assetInfos in
            Task {
                let assetsIds = assetInfos.filter { $0.visible }.map { $0.assetId }
                await PriceInfoService.shared.setup(for: assetsIds)
            }
        }
    }

    private func startChain() {
        let dbMigrator = UserStorageMigrator(
            targetVersion: UserStorageParams.modelVersion,
            storeURL: UserStorageParams.storageURL,
            modelDirectory: UserStorageParams.modelDirectory,
            keystore: Keychain(),
            settings: settings,
            fileManager: FileManager.default
        )
        let logger = Logger.shared
//it should not be here, but since we're trying to limit chain sync to the splash screen, we need working settings and have to migrate them because robinhood does not support lightweight migration (yet?)
        do {
            try dbMigrator.migrate()
        } catch {
            logger.error(error.localizedDescription)
        }

        let settings = SelectedWalletSettings.shared
        let chainRegistry = ChainRegistryFacade.sharedRegistry

        settings.setup(runningCompletionIn: .main) { result in
            switch result {
            case let .success(maybeAccount):
                if let metaAccount = maybeAccount {
                    chainRegistry.performHotBoot()
                    logger.debug("Selected account: \(metaAccount.address)")
                } else {

                    if chainRegistry.getRuntimeProvider(for: Chain.sora.genesisHash()) != nil {
                        self.presenter.setupComplete()
                    } else {
                        chainRegistry.performColdBoot()
                    }

                    logger.debug("No selected account")
                }
            case let .failure(error):
                logger.error("Selected account setup failed: \(error)")
            }
        }
    }
}

extension SplashInteractor: EventVisitorProtocol {
    func processRuntimeCoderReady(event: RuntimeCoderCreated) {
        self.presenter.setupComplete()
    }
}
