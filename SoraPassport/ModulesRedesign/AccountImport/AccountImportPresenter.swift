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
import RobinHood

enum AccountImportContext: String {
    case sourceType
    case cryptoType
    case addressType
}

final class AccountImportPresenter {
    static let maxMnemonicLength: Int = 250
    static let maxMnemonicSize: Int = 24
    static let maxRawSeedLength: Int = 66
    static let maxKeystoreLength: Int = 4000

    weak var view: AccountImportViewProtocol?
    var wireframe: AccountImportWireframeProtocol!
    var interactor: AccountImportInteractorInputProtocol!

    private(set) var metadata: AccountImportMetadata?

    private(set) var selectedSourceType: AccountImportSource?
    private(set) var selectedCryptoType: CryptoType?
    private(set) var selectedNetworkType: Chain?
    private var isRawSeedWarningShown: Bool = false

    private(set) var sourceViewModel: InputViewModelProtocol?
    private(set) var usernameViewModel: InputViewModelProtocol?
    private(set) var passwordViewModel: InputViewModelProtocol?
    private(set) var derivationPathViewModel: InputViewModelProtocol?
    private let config: ApplicationConfigProtocol

    private lazy var jsonDeserializer = JSONSerialization()
    
    init(sourceType: AccountImportSource? = nil, config: ApplicationConfigProtocol) {
        self.selectedSourceType = sourceType
        self.config = config
    }

    private func applySourceType(_ value: String = "", preferredInfo: AccountImportPreferredInfo? = nil) {
        guard let selectedSourceType = selectedSourceType, let metadata = metadata else {
            return
        }

        if let preferredInfo = preferredInfo {
            selectedCryptoType = preferredInfo.cryptoType

            if let preferredNetwork = preferredInfo.networkType,
               metadata.availableNetworks.contains(preferredNetwork) {
                selectedNetworkType = preferredInfo.networkType
            } else {
                selectedNetworkType = metadata.defaultNetwork
            }

        } else {
            selectedCryptoType = selectedCryptoType ?? metadata.defaultCryptoType
            selectedNetworkType = selectedNetworkType ?? metadata.defaultNetwork
        }

        view?.setSource(type: selectedSourceType)

        applySourceTextViewModel(value)

        let username = preferredInfo?.username ?? ""
        applyUsernameViewModel(username)
        applyPasswordViewModel()
        applyAdvanced(preferredInfo)

        if let preferredInfo = preferredInfo {
            showUploadWarningIfNeeded(preferredInfo)
        }
    }

    private func applySourceTextViewModel(_ value: String = "") {
        guard let selectedSourceType = selectedSourceType else {
            return
        }

        let viewModel: InputViewModelProtocol

        let locale = localizationManager?.selectedLocale ?? Locale.current

        switch selectedSourceType {
        case .mnemonic:
            let placeholder = R.string.localizable
                .recoveryMnemonicPassphrase(preferredLanguages: locale.rLanguages)
            let inputHandler = InputHandler(value: value,
                                            maxLength: AccountImportPresenter.maxMnemonicLength,
                                            validCharacterSet: CharacterSet.englishMnemonic,
                                            predicate: NSPredicate.notEmpty,
                                            processor: MneminicProcessor(),
                                            normalizer: MneminicProcessor())
            viewModel = InputViewModel(inputHandler: inputHandler, placeholder: placeholder)
        case .seed:
            let placeholder: String = R.string.localizable.recoveryInputRawSeedHint(preferredLanguages: locale.rLanguages)
            let inputHandler = InputHandler(
                value: value,
                maxLength: AccountImportPresenter.maxRawSeedLength,
                predicate: NSPredicate.seed
            )
            viewModel = InputViewModel(inputHandler: inputHandler, placeholder: placeholder)
        default: viewModel = InputViewModel(inputHandler: InputHandler())
        }

        sourceViewModel = viewModel

        view?.setSource(viewModel: viewModel)
    }

    private func applyUsernameViewModel(_ username: String = "") {
        let processor = ByteLengthProcessor.username
        let processedUsername = processor.process(text: username)

        let inputHandler = InputHandler(value: processedUsername,
                                        required: false,
                                        predicate: NSPredicate.notEmpty,
                                        processor: processor)

        let viewModel = InputViewModel(inputHandler: inputHandler)
        usernameViewModel = viewModel

        view?.setName(viewModel: viewModel)
    }

    private func applyPasswordViewModel() {
        guard let selectedSourceType = selectedSourceType else {
            return
        }

        switch selectedSourceType {
        case .mnemonic, .seed:
            passwordViewModel = nil
        case .keystore:
            let viewModel = InputViewModel(inputHandler: InputHandler(required: false))
            passwordViewModel = viewModel

            view?.setPassword(viewModel: viewModel)
        }
    }

    private func showUploadWarningIfNeeded(_ preferredInfo: AccountImportPreferredInfo) {
        guard let metadata = metadata else {
            return
        }

        if preferredInfo.networkType == nil {
            let locale = localizationManager?.selectedLocale
            let message = "accountImportJsonNoNetwork"//R.string.localizable.accountImportJsonNoNetwork(preferredLanguages: locale?.rLanguages)
            view?.setUploadWarning(message: message)
            return
        }

        if let preferredNetwork = preferredInfo.networkType,
           !metadata.availableNetworks.contains(preferredNetwork) {
            let locale = localizationManager?.selectedLocale ?? Locale.current
            let message = "accountImportWrongNetwork"//R.string.localizable
                //.accountImportWrongNetwork(preferredNetwork.titleForLocale(locale),
                     //                      metadata.defaultNetwork.titleForLocale(locale))
            view?.setUploadWarning(message: message)
            return
        }
    }

    private func applyAdvanced(_ preferredInfo: AccountImportPreferredInfo?) {
        guard let selectedSourceType = selectedSourceType else {
            let locale = localizationManager?.selectedLocale
            let warning = "accountImportJsonNoNetwork"//R.string.localizable.accountImportJsonNoNetwork(preferredLanguages: locale?.rLanguages)
            view?.setUploadWarning(message: warning)
            return
        }

        switch selectedSourceType {
        case .mnemonic, .seed:
//            applyCryptoTypeViewModel(preferredInfo)
            applyDerivationPathViewModel()
//            applyNetworkTypeViewModel(preferredInfo)
        case .keystore:
//            applyCryptoTypeViewModel(preferredInfo)
            derivationPathViewModel = nil
//            applyNetworkTypeViewModel(preferredInfo)
        }
    }

    private func applyDerivationPathViewModel() {
        guard let cryptoType = selectedCryptoType else {
            return
        }

        guard let sourceType = selectedSourceType else {
            return
        }

        let predicate: NSPredicate
        let placeholder: String

        if cryptoType == .sr25519 {
            if sourceType == .mnemonic {
                predicate = NSPredicate.deriviationPathHardSoftPassword
                placeholder = DerivationPathConstants.hardSoftPasswordPlaceholder
            } else {
                predicate = NSPredicate.deriviationPathHardSoft
                placeholder = DerivationPathConstants.hardSoftPlaceholder
            }
        } else {
            if sourceType == .mnemonic {
                predicate = NSPredicate.deriviationPathHardPassword
                placeholder = DerivationPathConstants.hardPasswordPlaceholder
            } else {
                predicate = NSPredicate.deriviationPathHard
                placeholder = DerivationPathConstants.hardPlaceholder
            }
        }

        let inputHandling = InputHandler(required: false, predicate: predicate)

        let viewModel = InputViewModel(inputHandler: inputHandling,
                                       placeholder: placeholder)

        self.derivationPathViewModel = viewModel

        view?.setDerivationPath(viewModel: viewModel)
    }

    private func presentDerivationPathError(sourceType: AccountImportSource,
                                            cryptoType: CryptoType) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        switch cryptoType {
        case .sr25519:
            if sourceType == .mnemonic {
                _ = wireframe.present(error: AccountCreationError.invalidDerivationHardSoftPassword,
                                      from: view,
                                      locale: locale) { [weak self] in
                    self?.view?.resetFocus()
                }
            } else {
                _ = wireframe.present(error: AccountCreationError.invalidDerivationHardSoft,
                                      from: view,
                                      locale: locale) { [weak self] in
                    self?.view?.resetFocus()
                }
            }

        case .ed25519, .ecdsa:
            if sourceType == .mnemonic {
                _ = wireframe.present(error: AccountCreationError.invalidDerivationHardPassword,
                                      from: view,
                                      locale: locale) { [weak self] in
                    self?.view?.resetFocus()
                }
            } else {
                _ = wireframe.present(error: AccountCreationError.invalidDerivationHard,
                                      from: view,
                                      locale: locale) { [weak self] in
                    self?.view?.resetFocus()
                }
            }
        }
    }

    func validateSourceViewModel() -> Error? {
        guard let viewModel = sourceViewModel, let selectedSourceType = selectedSourceType else {
            return nil
        }

        switch selectedSourceType {
        case .mnemonic:
            return validateMnemonic(value: viewModel.inputHandler.value)
        case .seed:
            return viewModel.inputHandler.completed ? nil : AccountCreateError.invalidSeed
        case .keystore:
            return validateKeystore(value: viewModel.inputHandler.value)
        }
    }

    func validateMnemonic(value: String) -> Error? {
        let mnemonicSize = value.components(separatedBy: CharacterSet.whitespaces).count
        return mnemonicSize > AccountImportPresenter.maxMnemonicSize ?
            AccountCreateError.invalidMnemonicSize : nil
    }

    func validateKeystore(value: String) -> Error? {
        guard let data = value.data(using: .utf8) else {
            return AccountCreateError.invalidKeystore
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return nil
        } catch {
            return AccountCreateError.invalidKeystore
        }
    }
}

extension AccountImportPresenter: AccountImportPresenterProtocol {

    func setup() {
        interactor.setup()
    }
    
    func validateAccount(completion: ((Result<AccountItem?, Swift.Error>?) -> Void)?) {
        guard 
            let sourceType = selectedSourceType,
            let cryptoType = selectedCryptoType,
            let networkType = selectedNetworkType,
            let sourceViewModel = sourceViewModel,
            let usernameViewModel = usernameViewModel else {
            return
        }
              
        switch sourceType {
        case .mnemonic:
            let mnemonic = sourceViewModel.inputHandler.value
            let username = usernameViewModel.inputHandler.value
            let derivationPath = derivationPathViewModel?.inputHandler.value ?? ""
            let request = AccountImportMnemonicRequest(mnemonic: mnemonic,
                                                       username: username,
                                                       networkType: networkType,
                                                       derivationPath: derivationPath,
                                                       cryptoType: cryptoType)
            interactor.validateAccountWithMnemonic(request: request, completion: completion)
        case .seed:
            let seed = sourceViewModel.inputHandler.value
            let username = usernameViewModel.inputHandler.value
            let derivationPath = derivationPathViewModel?.inputHandler.value ?? ""
            let request = AccountImportSeedRequest(seed: seed,
                                                   username: username,
                                                   networkType: networkType,
                                                   derivationPath: derivationPath,
                                                   cryptoType: cryptoType)
            interactor.validateAccountWithSeed(request: request, completion: completion)
        case .keystore:
            let keystore = sourceViewModel.inputHandler.value
            let password = passwordViewModel?.inputHandler.value ?? ""
            let username = usernameViewModel.inputHandler.value
            let request = AccountImportKeystoreRequest(keystore: keystore,
                                                       password: password,
                                                       username: username,
                                                       networkType: networkType,
                                                       cryptoType: cryptoType)

            interactor.validateAccountWithKeystore(request: request, completion: completion)
        }
    }

    func proceed() {
        guard
            let selectedSourceType = selectedSourceType,
            let selectedCryptoType = selectedCryptoType,
            let sourceViewModel = sourceViewModel,
            let usernameViewModel = usernameViewModel else {
            return
        }

        if let error = validateSourceViewModel() {
            _ = wireframe.present(error: error,
                                  from: view,
                                  locale: localizationManager?.selectedLocale) { [weak self] in
                self?.view?.resetFocus()
            }
            return
        }

        guard let selectedNetworkType = selectedNetworkType else {
            return
        }
        
        if
            let derivationPathViewModel = derivationPathViewModel,
            !derivationPathViewModel.inputHandler.completed {
            presentDerivationPathError(sourceType: selectedSourceType, cryptoType: selectedCryptoType)
            return
        }
        
        validateAccount { [weak self] result in
            switch result {
            case .success:
                self?.wireframe.proceed(from: self?.view,
                                        sourceType: selectedSourceType,
                                        cryptoType: selectedCryptoType,
                                        networkType: selectedNetworkType,
                                        sourceViewModel: sourceViewModel,
                                        usernameViewModel: usernameViewModel,
                                        passwordViewModel: self?.passwordViewModel,
                                        derivationPathViewModel: self?.derivationPathViewModel)
            case .failure(let error):
                self?.didReceiveAccountImport(error: error)
            case .none:
                let error = BaseOperationError.parentOperationCancelled
                self?.didReceiveAccountImport(error: error)
            }
        }
    }

    func activateURL(_ url: URL) {
        if let view = view {
            wireframe.showWeb(url: url,
                              from: view,
                              style: .modal)
        }
    }
}

extension AccountImportPresenter: AccountImportInteractorOutputProtocol {
    func didReceiveAccountImport(metadata: AccountImportMetadata) {
        self.metadata = metadata
        
        selectedCryptoType = metadata.defaultCryptoType
        selectedNetworkType = metadata.defaultNetwork

        applySourceType()
    }

    func didCompleteAccountImport() {}

    func didReceiveAccountImport(error: Error) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        guard !wireframe.present(error: error, from: view, locale: locale, completion: { [weak self] in
            self?.view?.resetFocus()
        }) else {
            return
        }

        _ = wireframe.present(error: CommonError.undefined,
                              from: view,
                              locale: locale) { [weak self] in
            self?.view?.resetFocus()
        }
    }

    func didSuggestKeystore(text: String, preferredInfo: AccountImportPreferredInfo?) {
        selectedSourceType = .keystore

        applySourceType(text, preferredInfo: preferredInfo)
    }
}

extension AccountImportPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            applySourceType()
        }
    }
}
