/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import IrohaCrypto

extension WalletAssetId {
    var chain: Chain { .sora }

    var defaultSort: Int? {
        switch self {
        case .xor:
            return 0
        case .val:
            return 1
        case .pswap:
            return 2
        case .xst:
            return 3
        case .xstusd:
            return 4
        }
    }

    var chainId: String {
        return self.rawValue
    }

    var isFeeAsset: Bool {
        switch self {
        case .xor:
            return true
        default:
            return false
        }
    }
}
