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
import SSFUtils

struct EventRecord: Decodable {
    enum CodingKeys: String, CodingKey {
        case phase
        case event
    }

    let phase: Phase
    let event: Event

    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)

        phase = try container.decode(Phase.self, forKey: .phase)
        event = try container.decode(Event.self, forKey: .event)
    }
}

extension EventRecord {
    var extrinsicIndex: UInt32? {
        if case let .applyExtrinsic(index) = phase {
            return index
        } else {
            return nil
        }
    }
}

enum Phase: Decodable {
    static let extrinsicField = "ApplyExtrinsic"
    static let finalizationField = "Finalization"
    static let initializationField = "Initialization"

    case applyExtrinsic(index: UInt32)
    case finalization
    case initialization

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)

        switch type {
        case Phase.extrinsicField:
            let index = try container.decode(StringScaleMapper<UInt32>.self).value
            self = .applyExtrinsic(index: index)
        case Phase.finalizationField:
            self = .finalization
        case Phase.initializationField:
            self = .initialization
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unexpected phase"
            )
        }
    }
}

struct EventWrapper: Decodable {}

struct Event: Decodable {
    let section: String
    let method: String
    let data: JSON

    init(from decoder: Decoder) throws {
        var unkeyedContainer = try decoder.unkeyedContainer()

        section = try unkeyedContainer.decode(String.self)
        var arrayContainer = try unkeyedContainer.nestedUnkeyedContainer()
        method = try arrayContainer.decode(String.self)
        data = try arrayContainer.decode(JSON.self)
    }
}

private extension Optional {
    func unwrap(throwing error: Error) throws -> Wrapped {
        guard let value = self else { throw error }
        return value
    }
}

enum ExtrinsicStatus: Decodable {
    static let readyField = "ready"
    static let broadcastField = "broadcast"
    static let inBlockField = "inBlock"
    static let finalizedField = "finalized"

    case ready
    case broadcast([String])
    case inBlock(String)
    case finalized(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(JSON.self)

        let decodingError = DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unexpected extrinsic state"
        )

        let type = try (decoded.dictValue?.keys.first ?? decoded.stringValue).unwrap(throwing: decodingError)
        let value = try decoded[type].unwrap(throwing: decodingError)

        switch type {
        case ExtrinsicStatus.readyField:
            self = .ready
        case ExtrinsicStatus.broadcastField:
            self = .broadcast(
                try value.arrayValue
                    .unwrap(throwing: decodingError)
                    .map { try $0.stringValue.unwrap(throwing: decodingError) }
            )
        case ExtrinsicStatus.inBlockField:
            self = .inBlock(try value.stringValue.unwrap(throwing: decodingError))
        case ExtrinsicStatus.finalizedField:
            self = .finalized(try value.stringValue.unwrap(throwing: decodingError))
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unexpected extrinsic state"
            )
        }
    }
}
