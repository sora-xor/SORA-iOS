//
//  RuntimeVersionService.swift
//  SoraPassport
//
//  Created by Ivan Shlyapkin on 10/28/24.
//  Copyright © 2024 Soramitsu. All rights reserved.
//

import RobinHood
import CoreData
import SSFUtils
import SSFModels

enum RuntimeVersionServiceError: Error {
    case invalidResponse
}

protocol RuntimeVersionService {
    func fetch(with connection: JSONRPCEngine) async throws -> RuntimeVersion
}

final class RuntimeVersionServiceDefault {
    private let operationManager = OperationManager()
    private let storage: CoreDataRepository<RuntimeVersion, CDMetadataVersion>
    private let fileRepository: FileRepositoryProtocol = FileRepository()
    private let reachabilityManager: ReachabilityManagerProtocol? = ReachabilityManager.shared
    
    init() {
        let mapper: CodableCoreDataMapper<RuntimeVersion, CDMetadataVersion> = CodableCoreDataMapper(
            entityIdentifierFieldName: #keyPath(CDMetadataVersion.specVersion)
        )
        storage = SubstrateDataStorageFacade.shared.createRepository(mapper: AnyCoreDataMapper(mapper))
    }
}

extension RuntimeVersionServiceDefault: RuntimeVersionService {
    func fetch(with connection: JSONRPCEngine) async throws -> RuntimeVersion {
        guard reachabilityManager?.isReachable ?? false else {
            if let version = try? await getVersion() {
                return version
            }
            return (try? await getFileVersion())!
        }
        
        let remoteRuntimeVersionOperation = JSONRPCOperation<[String], RuntimeVersion>(
            engine: connection,
            method: RPCMethod.getRuntimeVersion,
            timeout: 60
        )
        operationManager.enqueue(operations: [remoteRuntimeVersionOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            remoteRuntimeVersionOperation.completionBlock = {

                let result = remoteRuntimeVersionOperation.result

                switch result {
                case let .success(version):
                    continuation.resume(returning: version)
                    Task { [weak self] in
                        try? await self?.saveVersion(version: version)
                    }
                case .failure:
                    Task { [weak self] in
                        guard let version = try? await self?.getVersion() else {
                            
                            let fileVersion = (try? await self?.getFileVersion())!
                            continuation.resume(returning: fileVersion)
                            return
                        }
                        continuation.resume(returning: version)
                    }

                case .none:
                    continuation.resume(throwing: RuntimeVersionServiceError.invalidResponse)
                }
            }
        }
    }
    
    private func saveVersion(version: RuntimeVersion) async throws {
        let saveOperation = storage.saveOperation({[version]}, {[]})
        operationManager.enqueue(operations: [saveOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            saveOperation.completionBlock = {
                continuation.resume()
            }
        }
    }
    
    private func getVersion() async throws -> RuntimeVersion {
        let fetchOperation = storage.fetchAllOperation(with: RepositoryFetchOptions())
        operationManager.enqueue(operations: [fetchOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchOperation.completionBlock = {
                guard let config = try? fetchOperation.extractNoCancellableResultData().first else {
                    continuation.resume(throwing: RuntimeVersionServiceError.invalidResponse)
                    return
                }
                continuation.resume(returning: config)
            }
        }
    }
    
    private func getFileVersion() async throws -> RuntimeVersion {
        let filePath = ApplicationConfig.shared.versionParh ?? ""
        let localFileOperation = fileRepository.readOperation(at: filePath)
        operationManager.enqueue(operations: [localFileOperation], in: .transient)
        
        return try await withCheckedThrowingContinuation { continuation in
            localFileOperation.completionBlock = {
                guard let versionData = try? localFileOperation.extractNoCancellableResultData(),
                      let version = try? JSONDecoder().decode(RuntimeVersion.self, from: versionData) else {
                    continuation.resume(throwing: RuntimeVersionServiceError.invalidResponse)
                    return
                }
                continuation.resume(returning: version)
            }
        }
    }
}

extension RuntimeVersion: Identifiable {
    
    public var identifier: String { String(specVersion) }
    
    enum CodingKeys: String, CodingKey {
        case specVersion
        case transactionVersion
    }
}

extension CDMetadataVersion: CoreDataCodable {
    var entityIdentifierFieldName: String { #keyPath(CDMetadataVersion.specVersion) }

    public func populate(from decoder: Decoder, using context: NSManagedObjectContext) throws {
        let version = try RuntimeVersion(from: decoder)

        specVersion = Int32(bitPattern: version.specVersion)
        transactionVersion = Int32(bitPattern: version.transactionVersion)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RuntimeVersion.CodingKeys.self)

        try container.encode(UInt32(bitPattern: specVersion), forKey: .specVersion)
        try container.encode(UInt32(bitPattern: transactionVersion), forKey: .transactionVersion)
    }
}
