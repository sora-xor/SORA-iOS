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
import UIKit
import SoraKeystore
import RobinHood
import SSFUtils
import UIKit

final class ChangeAccountPresenter {
    weak var view: ChangeAccountViewProtocol?
    
    var wireframe: ChangeAccountWireframeProtocol!
    var endUpdatingBlock: (() -> Void)?

    private let settingsManager: SelectedWalletSettingsProtocol
    private let eventCenter: EventCenterProtocol
    private var mode: ChangeAccountViewController.Mode = .view
    private var accounts: [AccountItem] = []
    private var accountViewModels: [AccountMenuItem] = []
    private let accountRepository: AnyDataProviderRepository<AccountItem>
    private let operationManager: OperationManagerProtocol
    private let iconGenerator = PolkadotIconGenerator()
    private let serviceCoordinator: ServiceCoordinatorProtocol

    init(settingsManager: SelectedWalletSettingsProtocol,
         eventCenter: EventCenterProtocol,
         accountRepository: AnyDataProviderRepository<AccountItem>,
         operationManager: OperationManagerProtocol,
         serviceCoordinator: ServiceCoordinatorProtocol) {
        self.accountRepository = accountRepository
        self.operationManager = operationManager
        self.settingsManager = settingsManager
        self.eventCenter = eventCenter
        self.serviceCoordinator = serviceCoordinator
    }
    
    private func getAccounts() {
        let persistentOperation = accountRepository.fetchAllOperation(with: RepositoryFetchOptions())
        
        persistentOperation.completionBlock = { [weak self] in
            guard let accounts = try? persistentOperation.extractNoCancellableResultData() else {
                return
            }
            
            DispatchQueue.main.async {
                self?.handle(accounts: accounts)
            }
        }
        OperationQueue().addOperation(persistentOperation)
    }
    
    private func handle(accounts: [AccountItem]) {
        self.accounts = accounts

        let address = settingsManager.currentAccount?.address ?? ""

        accountViewModels = makeModels(from: accounts, selectedAccountAddress: address)
        
        view?.update(with: accountViewModels)
    }
    
    private func makeModels(from accounts: [AccountItem], selectedAccountAddress: String) -> [AccountMenuItem] {
        return accounts.enumerated().map { [weak self] (index, account) -> AccountMenuItem in
            
            let icon = try? iconGenerator.generateFromAddress(account.address)
                .imageWithFillColor(UIColor.white,
                                    size: CGSize(width: 40.0, height: 40.0),
                                    contentScale: UIScreen.main.scale)
            
            return AccountMenuItem(title: account.username.isEmpty ? account.address : account.username,
                                   image: icon,
                                   isSelected: account.address == selectedAccountAddress,
                                   isMultiselectionMode: mode == .edit,
                                   onTap: { self?.selectItem(at: index) },
                                   onMore: { self?.editItem(at: index) })
        }
    }
    
    
}

extension ChangeAccountPresenter: ChangeAccountPresenterProtocol {

    func onAction() {
        switch mode {
        case .view:
            addOrCreateAccount()
        case .edit:
            exportAccounts()
        }
    }
    func set(mode: ChangeAccountViewController.Mode) {
        self.mode = mode

        switch mode {
        case .view:
            getAccounts()
        case .edit:
            for currentIndex in 0...accountViewModels.count - 1 {
                accountViewModels[currentIndex].isSelected = false
            }
            _ = accountViewModels.map { $0.isMultiselectionMode = true }
            view?.update(with: accountViewModels)
        }
    }

    func reload() {
        getAccounts()
    }
    
    func selectItem(at index: Int) {

        switch mode {
        case .view:
            guard settingsManager.currentAccount != accounts[index] else {
                return
            }

            for currentIndex in 0...accountViewModels.count - 1 {
                accountViewModels[currentIndex].isSelected = currentIndex == index
            }
            view?.update(with: accountViewModels)

            let accountItem = accounts[index]

            settingsManager.save(value: accountItem)
            eventCenter.notify(with: SelectedAccountChanged())
            view?.controller.dismiss(animated: true)

        case .edit:
            guard accountViewModels.indices.contains(index) else { return }
            accountViewModels[index].isSelected.toggle()
            view?.update(with: accountViewModels)
        }
    }

    func editItem(at index: Int) {
        guard let view = view?.controller else {
            return
        }

        let accountItem = accounts[index]
        wireframe.showEdit(account: accountItem, from: view)
    }

    private func exportAccounts() {
        guard let view = view?.controller else { return }
        let accountItemsToExport: [AccountItem] = accountViewModels
            .enumerated()
            .filter { $1.isSelected }
            .enumerated()
            .compactMap { index, _ in
                if accounts.indices.contains(index) {
                    return accounts[index]
                } else {
                    return nil
                }
            }

        wireframe?.showExportAccounts(accounts: accountItemsToExport, from: view)
    }

    private func addOrCreateAccount() {
        guard let view = view?.controller else {
            return
        }

        wireframe?.showStart(from: view) { [weak self] in
            self?.getAccounts()
            self?.serviceCoordinator.checkMigration()
        }
    }
    
    private func createAccount() {
        guard let view = view?.controller else {
            return
        }

        wireframe?.showSignUp(from: view) { [weak self] in
            self?.getAccounts()
        }
    }

    private func importAccount() {
        guard let view = view?.controller else {
            return
        }

        wireframe?.showAccountRestore(from: view, completion: { [weak self] in
            self?.getAccounts()
        })
    }
    
    func endUpdating() {
        endUpdatingBlock?()
    }
}
