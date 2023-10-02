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
import IrohaCrypto

protocol CreateAccountServiceProtocol {
    func createAccount(request: AccountCreationRequest,
                       mnemonic: IRMnemonicProtocol,
                       completion: @escaping (Result<AccountItem, Error>?) -> Void)
}

final class CreateAccountService: CreateAccountServiceProtocol {
    let accountRepository: AnyDataProviderRepository<AccountItem>
    let accountOperationFactory: AccountOperationFactoryProtocol
    let settings: SelectedWalletSettingsProtocol
    let eventCenter: EventCenterProtocol
    let operationManager: OperationManagerProtocol = OperationManager()
    private var currentOperation: Operation?
    
    init(accountRepository: AnyDataProviderRepository<AccountItem>,
         accountOperationFactory: AccountOperationFactoryProtocol,
         settings: SelectedWalletSettingsProtocol,
         eventCenter: EventCenterProtocol) {
        self.accountRepository = accountRepository
        self.accountOperationFactory = accountOperationFactory
        self.settings = settings
        self.eventCenter = eventCenter
    }
    
    func createAccount(request: AccountCreationRequest,
                       mnemonic: IRMnemonicProtocol,
                       completion: @escaping (Result<AccountItem, Error>?) -> Void) {
        let operation = accountOperationFactory.newAccountOperation(request: request, mnemonic: mnemonic)
        guard currentOperation == nil else {
            return
        }

        let persistentOperation = accountRepository.saveOperation({
            let accountItem = try operation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)
            return [accountItem]
        }, { [] })

        persistentOperation.addDependency(operation)

        let connectionOperation: BaseOperation<AccountItem> = ClosureOperation {
            let accountItem = try operation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return accountItem
        }

        connectionOperation.addDependency(persistentOperation)

        currentOperation = connectionOperation

        connectionOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.currentOperation = nil

                switch connectionOperation.result {
                case .success(let accountItem):
                    self?.settings.save(value: accountItem)
                    self?.eventCenter.notify(with: SelectedAccountChanged())
                case .none:
                    let error = BaseOperationError.parentOperationCancelled
                    completion(.failure(error))
                case .some(.failure(_)):
                    break
                }
                
                completion(connectionOperation.result)
            }
        }

        operationManager.enqueue(operations: [operation, persistentOperation, connectionOperation], in: .sync)
    }
}

