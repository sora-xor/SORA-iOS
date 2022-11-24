/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import FearlessUtils

protocol ConnectionPoolProtocol {
    func setupConnection(for chain: ChainModel) throws -> ChainConnection
    func setupConnection(for chain: ChainModel, ignoredUrl: URL?) throws -> ChainConnection
    func getConnection(for chainId: ChainModel.Id) -> ChainConnection?
    func setDelegate(_ delegate: ConnectionPoolDelegate)
}

protocol ConnectionPoolDelegate: AnyObject {
    func connectionNeedsReconnect(url: URL, attempt: Int)
    func connectionUpdated(url: URL)
}

class ConnectionPool {
    let connectionFactory: ConnectionFactoryProtocol
    weak var delegate: ConnectionPoolDelegate?

    private var mutex = NSLock()

    private(set) var connectionsByChainIds: [ChainModel.Id: WeakWrapper] = [:]

    private func clearUnusedConnections() {
        connectionsByChainIds = connectionsByChainIds.filter { $0.value.target != nil }
    }

    init(connectionFactory: ConnectionFactoryProtocol) {
        self.connectionFactory = connectionFactory
    }
}

extension ConnectionPool: ConnectionPoolProtocol {
    func setDelegate(_ delegate: ConnectionPoolDelegate) {
        self.delegate = delegate
    }

    func setupConnection(for chain: ChainModel) throws -> ChainConnection {
        try setupConnection(for: chain, ignoredUrl: nil)
    }

    func setupConnection(for chain: ChainModel, ignoredUrl: URL?) throws -> ChainConnection {
        let node = chain.selectedNode ?? chain.nodes.first

        guard let url = node?.url else {
            throw JSONRPCEngineError.unknownError
        }

        mutex.lock()

        defer {
            mutex.unlock()
        }

        clearUnusedConnections()

        if let connection = connectionsByChainIds[chain.chainId]?.target as? ChainConnection {
            if connection.url == url {
                return connection
            } else {
                connectionsByChainIds[chain.chainId] = nil
            }
        }

        let connection = connectionFactory.createConnection(for: url, delegate: self)
        let wrapper = WeakWrapper(target: connection)
        Logger.shared.info("Connected node: \(url)")
        connectionsByChainIds[chain.chainId] = wrapper

        return connection
    }

    func getConnection(for chainId: ChainModel.Id) -> ChainConnection? {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        return connectionsByChainIds[chainId]?.target as? ChainConnection
    }
}

extension ConnectionPool: WebSocketEngineDelegate {
    func webSocketDidChangeState(engine: WebSocketEngine, from _: WebSocketEngine.State, to newState: WebSocketEngine.State) {
        guard let previousUrl = engine.url else {
            return
        }

        switch newState {
        case let .connecting(attempt):
            if attempt > 1 {
                // temporary disable autobalance , maybe this causing crashes
                delegate?.connectionNeedsReconnect(url: previousUrl, attempt: attempt)
            }
        case .connected:
            delegate?.connectionUpdated(url: previousUrl)

        case .notConnected:
            break
        case .waitingReconnection(attempt: let attempt):
            break
        }
    }
}
