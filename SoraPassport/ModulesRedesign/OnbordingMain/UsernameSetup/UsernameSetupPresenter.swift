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
import SoraFoundation
import SoraKeystore

enum UsernameSetupMode {
    case onboarding
    case editing
    case creating
}

final class UsernameSetupPresenter {
    weak var view: UsernameSetupViewProtocol?
    var wireframe: UsernameSetupWireframeProtocol!
    var viewModel: InputViewModel!
    var successEditingBlock: (() -> Void)?
    let settingsManager = SelectedWalletSettings.shared
    var mode: UsernameSetupMode = .onboarding
    var userName: String? {
        get { settingsManager.currentAccount?.username }
        set {
            let newUserName = newValue ?? ""
            if mode == .editing, let updated = settingsManager.currentAccount?.replacingUsername(newUserName) {
                settingsManager.save(value: updated)
            }
        }
    }
}

extension UsernameSetupPresenter: UsernameSetupPresenterProtocol {
    func setup() {
        let value = mode == .creating ? "" : userName ?? ""
        
        let inputHandling = InputHandler(value: value,
                                         required: false,
                                         predicate: NSPredicate.notEmpty,
                                         processor: ByteLengthProcessor.username)
        viewModel = InputViewModel(inputHandler: inputHandling)
        view?.set(viewModel: viewModel)
    }

    func proceed() {
        showNewFlow()
    }
    
    func endEditing() {
        successEditingBlock?()
    }

    func activateURL(_ url: URL) {
        if let view = view {
            wireframe.showWeb(url: url,
                              from: view,
                              style: .modal)
        }
    }
}

private extension UsernameSetupPresenter {
    func showOldFlow() {
        let value = viewModel.inputHandler.value

        let rLanguages = localizationManager?.selectedLocale.rLanguages
        let actionTitle = R.string.localizable.commonOk(preferredLanguages: rLanguages)
        let action = AlertPresentableAction(title: actionTitle) { [weak self] in
            self?.wireframe.proceed(from: self?.view, username: value)
        }

        let title = R.string.localizable.screenshotAlertTitle(preferredLanguages: rLanguages)
        let message = R.string.localizable.screenshotAlertText(preferredLanguages: rLanguages)
        let viewModel = AlertPresentableViewModel(title: title,
                                                  message: message,
                                                  actions: [action],
                                                  closeAction: nil)
        wireframe.present(viewModel: viewModel, style: .alert, from: view)
    }
    
    func showNewFlow() {
        wireframe.showWarning(from: view) { [weak self] in
            self?.wireframe.proceed(from: self?.view, username: self?.viewModel.inputHandler.value ?? "")
        }
    }
}
    
extension UsernameSetupPresenter: Localizable {
    func applyLocalization() {}
}
