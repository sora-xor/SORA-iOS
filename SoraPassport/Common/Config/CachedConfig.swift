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

import RobinHood
import CoreData

struct CachedConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case configId
        case explorerUrl
        case typesUrl
        case nodes
    }
    let configId: String
    let explorerUrl: String
    let typesUrl: String
    let nodes: [CachedNode]
    
    init(configId: String, explorerUrl: String, typesUrl: String, nodes: [CachedNode]) {
        self.configId = configId
        self.explorerUrl = explorerUrl
        self.typesUrl = typesUrl
        self.nodes = nodes
    }
}

extension CachedConfig: Identifiable {
    var identifier: String { configId }
    var id: String { configId }
}

extension CDConfig: CoreDataCodable {
    var entityIdentifierFieldName: String { #keyPath(CDConfig.configId) }

    public func populate(from decoder: Decoder, using context: NSManagedObjectContext) throws {
        let config = try CachedConfig(from: decoder)

        configId = config.configId
        explorerUrl = config.explorerUrl
        typesUrl = config.typesUrl
        
        nodes = NSSet(array: config.nodes.map { remoteNode in
            let node = CDNode(context: context)
            node.address = remoteNode.address
            node.name = remoteNode.name
            return node
        })
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CachedConfig.CodingKeys.self)

        try container.encode(configId, forKey: .configId)
        try container.encode(explorerUrl, forKey: .explorerUrl)
        try container.encode(typesUrl, forKey: .typesUrl)
        try container.encode(nodes as? Set<CDNode>, forKey: .nodes)

    }
}
