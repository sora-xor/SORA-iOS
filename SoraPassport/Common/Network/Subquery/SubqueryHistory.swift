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
import SoraFoundation

struct SubqueryPageInfo: Decodable {
    let endCursor: String?
    let hasNextPage: Bool
}

struct SubqueryTransfer: Decodable {
    enum CodingKeys: String, CodingKey {
        case amount
        case receiver = "to"
        case sender = "from"
        case assetId
        case extrinsicId
        case extrinsicHash
    }

    let amount: String
    let receiver: String
    let sender: String
    let assetId: String
    let extrinsicId: String?
    let extrinsicHash: String?
}

struct SubqueryRewardOrSlash: Decodable {
    let amount: String
    let isReward: Bool
    let era: Int?
    let validator: String?
}

struct SubqueryExtrinsic: Decodable {
    let hash: String
    let module: String
    let call: String
    let fee: String
    let success: Bool
}

struct SubquerySwap: Decodable {
    let baseAssetId: String
    let targetAssetId: String
    let baseAssetAmount: String
    let targetAssetAmount: String
    let liquidityProviderFee: String
    let selectedMarket: String
}

struct SubqueryHistoryElement: Decodable {
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case timestamp
        case blockHash
        case address
        case fee = "networkFee"
        case data
        case execution
    }

    let identifier: String
    let timestamp: SubqueryTimestamp
    let blockHash: String
    let address: String
    let fee: String
    let data: JSON
    let execution: SubqueryExecution
}

struct SubqueryLiquidity: Decodable {
    let baseAssetId: String
    let targetAssetId: String
    let targetAssetAmount: String
    let baseAssetAmount: String
    let type: TransactionLiquidityType
}

struct SubqueryCreatePoolLiquidity: Decodable {
    let inputAssetA: String
    let inputAssetB: String
    let inputADesired: String
    let inputBDesired: String
}

struct SubqueryReferral: Decodable {
    let to: String
    let from: String
    let amount: String?
}

enum TransactionLiquidityType: String, Decodable {
    case deposit = "Deposit"
    case removal = "Removal"
}

extension TransactionType {
    var transactionLiquidityType: TransactionLiquidityType? {
        switch self {
        case .liquidityAdd, .liquidityAddNewPool, .liquidityAddToExistingPoolFirstTime:
            return .deposit
        case .liquidityRemoval:
            return .removal
        case .incoming, .outgoing, .reward, .slash, .swap, .migration, .extrinsic, .referral, .demeterDeposit, .demeterWithdraw, .demeterClaimReward:
            return nil
        }
    }
}

extension TransactionLiquidityType {
    var localizedString: String {
        let preferredLanguages = LocalizationManager.shared.selectedLocale.rLanguages
        switch self {
        case .deposit:
            return R.string.localizable.commonAddLiquidity(preferredLanguages: preferredLanguages).uppercased()
        case .removal:
            return R.string.localizable.commonRemove(preferredLanguages: preferredLanguages).uppercased()
        }
    }
}

struct SubqueryTimestamp: Decodable {
    let value: Int
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let val = try? container.decode(Int.self) {
            value = val
        } else if let val1 = try? container.decode(String.self) {
            value = Int(val1) ?? 0
        } else {
            value = 0
        }
    }
}

struct SubqueryError: Decodable {
    let moduleErrorId: Int
    let moduleErrorIndex: Int
    let nonModuleErrorMessage: String?
}

struct SubqueryExecution: Decodable {
    let error: SubqueryError?
    let success: Bool
}

struct SubqueryHistoryData: Decodable {
    struct HistoryElements: Decodable {
        let pageInfo: SubqueryPageInfo
        let nodes: [SubqueryHistoryElement]
    }

    let historyElements: HistoryElements
}

struct SubqueryRewardOrSlashData: Decodable {
    struct HistoryElements: Decodable {
        let nodes: [SubqueryHistoryElement]
    }

    let historyElements: HistoryElements
}
