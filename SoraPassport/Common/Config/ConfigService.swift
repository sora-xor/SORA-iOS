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

enum ConfigServiceError: Error {
    case invalidResponse
}

protocol ConfigServiceProtocol: AnyObject {
    var config: RemoteConfig { get }
    func setupConfig(completion: @escaping () -> Void)
}

struct RemoteConfig {
    var subqueryURL: URL
    var defaultNodes: Set<ChainNodeModel>
    var typesURL: URL?
    var isSoraCardEnabled: Bool
    
    init(subqueryUrlString: String = ApplicationConfig.shared.subqueryUrl.absoluteString,
         typesUrlString: String = ApplicationConfig.shared.subqueryUrl.absoluteString,
         defaultNodes: Set<ChainNodeModel> = ApplicationConfig.shared.defaultChainNodes,
         isSoraCardEnabled: Bool = false) {
        self.subqueryURL = URL(string: subqueryUrlString) ?? ApplicationConfig.shared.subqueryUrl
        self.typesURL = URL(string: typesUrlString)
        self.defaultNodes = defaultNodes
        self.isSoraCardEnabled = isSoraCardEnabled
    }
}

final class ConfigService {
    static let shared = ConfigService()
    private let operationManager: OperationManager = OperationManager()
    private let storage: CoreDataRepository<CachedConfig, CDConfig>
    var config: RemoteConfig = RemoteConfig()
    private let reachabilityManager: ReachabilityManagerProtocol? = ReachabilityManager.shared
    
    init() {
        let mapper: CodableCoreDataMapper<CachedConfig, CDConfig> = CodableCoreDataMapper(
            entityIdentifierFieldName: #keyPath(CDConfig.configId)
        )
        storage = SubstrateDataStorageFacade.shared.createRepository(mapper: AnyCoreDataMapper(mapper))
    }
}

extension ConfigService: ConfigServiceProtocol {
    
    func setupConfig(completion: @escaping () -> Void) {
        guard reachabilityManager?.isReachable ?? false else {
            self.config = ApplicationConfig.shared.remoteConfig
            completion()
            return
        }
        
        let commonUrl = URL(string: ApplicationConfig.shared.commonConfigUrl)!
        let commonOperation = GitHubConfigOperationFactory<CommonCofig>().fetchData(commonUrl)
        
        let mobileUrl = URL(string: ApplicationConfig.shared.mobileConfigUrl)!
        let mobileOperation = GitHubConfigOperationFactory<MobileCofig>().fetchData(mobileUrl)
        
        let mapOperation = ClosureOperation<Void> {
            do {
                guard let commonResponse = try commonOperation.extractNoCancellableResultData(),
                      let mobileResponse = try mobileOperation.extractNoCancellableResultData() else {
                    throw ConfigServiceError.invalidResponse
                }
                
                let nodes: Set<ChainNodeModel> = Set(commonResponse.DEFAULT_NETWORKS.compactMap({ node in
                    guard let url = URL(string: node.address) else { return nil }
                    return ChainNodeModel(url: url, name: node.name, apikey: nil)
                }))
                
                self.config = RemoteConfig(
                    subqueryUrlString: commonResponse.SUBQUERY_ENDPOINT,
                    typesUrlString: mobileResponse.substrate_types_ios,
                    defaultNodes: nodes,
                    isSoraCardEnabled: mobileResponse.soracard
                )
                completion()

                Task { [weak self] in
                    try? await self?.saveConfig(commonResponse: commonResponse, mobileResponse: mobileResponse)
                }
            } catch {
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        let cachedConfig = try await self.getConfig()
                        
                        let nodes: Set<ChainNodeModel> = Set(cachedConfig.nodes.compactMap({ node in
                            guard let url = URL(string: node.address) else { return nil }
                            return ChainNodeModel(url: url, name: node.name, apikey: nil)
                        }))
                        
                        self.config = RemoteConfig(
                            subqueryUrlString: cachedConfig.explorerUrl,
                            typesUrlString: cachedConfig.typesUrl,
                            defaultNodes: nodes,
                            isSoraCardEnabled: false
                        )

                        completion()
                    } catch {
                        self.config = ApplicationConfig.shared.remoteConfig
                        completion()
                    }
                }
            }
        }
        
        mapOperation.addDependency(commonOperation)
        mapOperation.addDependency(mobileOperation)
        
        operationManager.enqueue(operations: [commonOperation, mobileOperation, mapOperation], in: .blockAfter)
    }
    
    private func saveConfig(commonResponse: CommonCofig, mobileResponse: MobileCofig) async throws {
        let nodes: [CachedNode] = commonResponse.DEFAULT_NETWORKS.compactMap {
            CachedNode(name: $0.name, address: $0.address)
        }
        
        let saveOperation = storage.saveOperation({[
            CachedConfig(
                configId: "localConfig",
                explorerUrl: commonResponse.SUBQUERY_ENDPOINT,
                typesUrl: mobileResponse.substrate_types_ios,
                nodes: nodes
            )
        ]}, {[]})
        operationManager.enqueue(operations: [saveOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            saveOperation.completionBlock = {
                continuation.resume()
            }
        }
    }
    
    private func getConfig() async throws -> CachedConfig {
        let fetchOperation = storage.fetchOperation(by: { "localConfig" }, options: RepositoryFetchOptions())
        operationManager.enqueue(operations: [fetchOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchOperation.completionBlock = {
                    guard let config = try? fetchOperation.extractNoCancellableResultData() else {
                        continuation.resume(throwing: ConfigServiceError.invalidResponse)
                        return
                    }
                    continuation.resume(returning: config)
            }
        }
    }
}
