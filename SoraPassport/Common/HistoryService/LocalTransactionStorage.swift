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

protocol LocalTransactionStorageProtocol {
    var transactions: [String: [Transaction]] { get set }
}

final class LocalTransactionStorage: LocalTransactionStorageProtocol {
    
    static let shared = LocalTransactionStorage()
    var transactions: [String: [Transaction]] = [:]
    var currentAccount = SelectedWalletSettings.shared
    
    init() {
        EventCenter.shared.add(observer: self)
    }
}

extension LocalTransactionStorage: EventVisitorProtocol {
    func processNewTransactionCreated(event: NewTransactionCreatedEvent) {
        guard let address = currentAccount.currentAccount?.address else { return }
        var transactions = transactions[address] ?? []
        transactions.append(event.item)
        self.transactions[address] = transactions
    }
    
    func processNewTransaction(event: WalletNewTransactionInserted) {
        if let transaction = event.items.first,
           let address = currentAccount.currentAccount?.address,
           var transactions = transactions[address],
           let foundedTransactionIndex = transactions.firstIndex(where: { $0.base.txHash == transaction.extrinsicHash.toHex(includePrefix: true) }) {
            
            transactions[foundedTransactionIndex].base.status = transaction.processingResult.isSuccess ? .success : .failed
            self.transactions[address] = transactions
        }
    }
}
