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

import SSFUtils
import RobinHood

enum DexInfoError: Swift.Error {
    case unexpected
}

struct DexInfos: Decodable {
    var baseAssetId: SoraAssetId
    var syntheticBaseAssetId: SoraAssetId
    var isPublic: Bool
}

struct DexId {
    let id: UInt32
    var baseAssetId: String
    var syntheticBaseAssetId: String
}

protocol DexInfoService {
    func dexInfos() async throws -> [DexId]
    func getDexInfo(for assetId: String) async throws -> UInt32
}


final class DexInfoServiceDefault {
    private let engine: JSONRPCEngine
    private let operationManager: OperationManagerProtocol
    private var dexInfos: [DexId] = []
    
    init(
        engine: JSONRPCEngine,
        operationManager: OperationManagerProtocol = OperationManagerFacade.sharedManager
    ) {
        self.engine = engine
        self.operationManager = operationManager
        
        Task {
            dexInfos = (try? await dexInfos()) ?? []
        }
    }
}

extension DexInfoServiceDefault: DexInfoService {
    func getDexInfo(for assetId: String) async throws -> UInt32 {
        guard let id = dexInfos.first(where: { $0.baseAssetId == assetId })?.id else {
            dexInfos = try await dexInfos()
            return try await getDexInfo(for: assetId)
        }
        
        return id
    }
    
    func dexInfos() async throws -> [DexId] {
        if !dexInfos.isEmpty {
            return dexInfos
        }
            
        guard let runtimeProvider = ChainRegistryFacade.sharedRegistry.getRuntimeProvider(for: Chain.sora.genesisHash()) else {
            throw DexInfoError.unexpected
        }

        let fetchCoderFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()
        
        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: OperationManagerFacade.sharedManager
        )

        let storageOperation: CompoundOperationWrapper<[StorageResponse<DexInfos>]> =
            storageRequestFactory.queryItemsByPrefix(
                engine: engine,
                keys: { try [ StorageKeyFactory().dexInfosKeys() ] },
                factory: { try fetchCoderFactoryOperation.extractNoCancellableResultData() },
                storagePath: StorageCodingPath.dexInfos,
                at: nil
            )

        storageOperation.allOperations.forEach { $0.addDependency(fetchCoderFactoryOperation) }

        let mapOperation = ClosureOperation<[DexId]> {
            let response = try storageOperation.targetOperation.extractNoCancellableResultData()

            return response.compactMap { element in
                guard let id = element.key.uint32Array.last,
                      let baseAssetId = element.value?.baseAssetId.value,
                      let syntheticBaseAssetId = element.value?.syntheticBaseAssetId.value else {
                    return nil
                }
                return DexId(id: id, baseAssetId: baseAssetId, syntheticBaseAssetId: syntheticBaseAssetId)
            }
        }

        mapOperation.addDependency(storageOperation.targetOperation)

        let operations = CompoundOperationWrapper(
            targetOperation: mapOperation,
            dependencies: [fetchCoderFactoryOperation] + storageOperation.allOperations
        )
        
        operationManager.enqueue(operations: [operations.targetOperation] + operations.dependencies, in: .transient)
        
        return try await withCheckedThrowingContinuation { continuetion in
            operations.targetOperation.completionBlock = {
                do {
                    let result = try operations.targetOperation.extractNoCancellableResultData()
                    continuetion.resume(returning: result)
                } catch {
                    continuetion.resume(throwing: error)
                }
            }
        }
    }
}
