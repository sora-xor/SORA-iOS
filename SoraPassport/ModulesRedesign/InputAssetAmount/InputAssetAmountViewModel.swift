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

import UIKit
import SoraUIKit

import RobinHood
import SoraFoundation
import sorawallet

protocol InputAssetAmountViewModelProtocol: InputAccessoryViewDelegate {
    var inputedFirstAmount: Decimal { get set }
    func viewDidLoad()
    func choiceBaseAssetButtonTapped()
    func reviewButtonTapped()
    func selectAddress()
}

final class InputAssetAmountViewModel {
    
    weak var fiatService: FiatServiceProtocol?
    weak var view: InputAssetAmountViewProtocol?
    let assetManager: AssetManagerProtocol?
    let networkFacade: WalletNetworkOperationFactoryProtocol?
    var providerFactory: BalanceProviderFactory
    
    var firstAssetBalance: BalanceData = BalanceData(identifier: WalletAssetId.xor.rawValue, balance: AmountDecimal(value: 0)) {
        didSet {
            setupFullBalanceText(from: firstAssetBalance) { [weak self] text in
                DispatchQueue.main.async {
                    self?.view?.updateFirstAsset(balance: text)
                }
            }
        }
    }
    
    var firstAssetId: String = "" {
        didSet {
            guard let asset = assetManager?.assetInfo(for: firstAssetId) else {
                return
            }
            let image = RemoteSerializer.shared.image(with: asset.icon ?? "")
            view?.updateFirstAsset(symbol: asset.symbol, image: image)
            updateBalanceData()
            view?.set(firstAmountText: "0")
            inputedFirstAmount = 0
        }
    }
    
    var selectedAddress: String? {
        didSet {
            view?.updateRecipientView(with: selectedAddress ?? "")
            self.updateButtonState()
        }
    }
    
    var inputedFirstAmount: Decimal = 0 {
        didSet {
            if let fromAsset = assetManager?.assetInfo(for: firstAssetId), fromAsset.isFeeAsset {
                warningViewModel?.isHidden = firstAssetBalance.balance.decimalValue - inputedFirstAmount - fee > fee
            }
            
            let fiatText = setupInputedFiatText(from: inputedFirstAmount, assetId: firstAssetId)
            let text = validationText(with: fiatText, isEnoghtAssetBalance: checkBalances(), isEnoghtXorBalance: checkXorBalance())

            let amountColor: SoramitsuColor = checkBalances() && checkXorBalance() ? .fgPrimary : .statusError
            let fiatColor: SoramitsuColor = checkBalances() && checkXorBalance() ? .fgSecondary : .statusError
            let state: InputFieldState = checkBalances() && checkXorBalance() ? .focused : .fail
            
            view?.updateFirstAsset(state: state, amountColor: amountColor, fiatColor: fiatColor)
            view?.updateFirstAsset(fiatText: text)
            updateButtonState()
        }
    }
    
    private var warningViewModelFactory: WarningViewModelFactory
    private var warningViewModel: WarningViewModel? {
        didSet {
            guard let warningViewModel else { return }
            view?.updateWarinignView(model: warningViewModel)
        }
    }
    
    private let feeProvider: FeeProviderProtocol
    private var fiatData: [FiatData] = []
    private var fee: Decimal = 0 {
        didSet {
            let feeAssetSymbol = assetManager?.getAssetList()?.first { $0.isFeeAsset }?.symbol ?? ""
            warningViewModel = warningViewModelFactory.insufficientBalanceViewModel(feeAssetSymbol: feeAssetSymbol, feeAmount: fee)
            
            guard !checkXorBalance() else { return }
            
            let fiatText = setupInputedFiatText(from: inputedFirstAmount, assetId: firstAssetId)
            let text = validationText(with: fiatText, isEnoghtAssetBalance: checkBalances(), isEnoghtXorBalance: checkXorBalance())
            
            let amountColor: SoramitsuColor = checkBalances() && checkXorBalance() ? .fgPrimary : .statusError
            let fiatColor: SoramitsuColor = checkBalances() && checkXorBalance() ? .fgSecondary : .statusError
            let state: InputFieldState = checkBalances() && checkXorBalance() ? .focused : .fail
            
            self.view?.updateFirstAsset(state: state, amountColor: amountColor, fiatColor: fiatColor)
            self.view?.updateFirstAsset(fiatText: text)
            self.updateButtonState()
        }
    }
    private var selectedTokenId: String? = WalletAssetId.xor.rawValue
    private let wireframe: InputAssetAmountWireframeProtocol
    private var balances: [BalanceData] = []
    private weak var assetsProvider: AssetProviderProtocol?
    private var qrEncoder: WalletQREncoderProtocol
    private var sharingFactory: AccountShareFactoryProtocol
    private var marketCapService: MarketCapServiceProtocol
    init(
        selectedTokenId: String?,
        selectedAddress: String?,
        fiatService: FiatServiceProtocol?,
        assetManager: AssetManagerProtocol?,
        providerFactory: BalanceProviderFactory,
        networkFacade: WalletNetworkOperationFactoryProtocol?,
        wireframe: InputAssetAmountWireframeProtocol,
        assetsProvider: AssetProviderProtocol?,
        qrEncoder: WalletQREncoderProtocol,
        sharingFactory: AccountShareFactoryProtocol,
        warningViewModelFactory: WarningViewModelFactory = WarningViewModelFactory(),
        marketCapService: MarketCapServiceProtocol
    ) {
        self.selectedAddress = selectedAddress
        self.fiatService = fiatService
        self.assetManager = assetManager
        self.providerFactory = providerFactory
        self.feeProvider = FeeProvider()
        self.networkFacade = networkFacade
        self.selectedTokenId = selectedTokenId
        self.wireframe = wireframe
        self.assetsProvider = assetsProvider
        self.qrEncoder = qrEncoder
        self.sharingFactory = sharingFactory
        self.marketCapService = marketCapService
        self.warningViewModelFactory = warningViewModelFactory
    }
}

extension InputAssetAmountViewModel: InputAssetAmountViewModelProtocol {
    
    func didSelect(variant: Float) {
        guard firstAssetBalance.balance.decimalValue > fee  else { return }
        let isFeeAsset = assetManager?.assetInfo(for: firstAssetId)?.isFeeAsset ?? false
        let value = firstAssetBalance.balance.decimalValue * (Decimal(string: "\(variant)") ?? 0)
        inputedFirstAmount = isFeeAsset ? value - fee : value
        let formatter = NumberFormatter.inputedAmoutFormatter(with: assetManager?.assetInfo(for: firstAssetId)?.precision ?? 0)
        view?.set(firstAmountText: formatter.stringFromDecimal(inputedFirstAmount) ?? "")
    }
    
    func viewDidLoad() {
        updateBalanceData()
        
        if let selectedAddress = selectedAddress {
            view?.updateRecipientView(with: selectedAddress)
        } else {
            changeAddress()
        }
        
        firstAssetId = selectedTokenId ?? WalletAssetId.xor.rawValue
        view?.setupButton(isEnabled: false)
        assetsProvider?.add(observer: self)
        
        Task { [weak self] in
            guard let self else { return }
            self.fee = await self.feeProvider.getFee(for: .outgoing)
            self.fiatData = await self.fiatService?.getFiat() ?? []
        }
    }
    
    func choiceBaseAssetButtonTapped() {
        guard
            let assetManager = assetManager,
            let fiatService = fiatService,
            let assets = assetManager.getAssetList() else {
            return
        }
        
        let factory = AssetViewModelFactory(walletAssets: assets,
                                            assetManager: assetManager,
                                            fiatService: fiatService)
        
        wireframe.showChoiceBaseAsset(on: view?.controller,
                                      assetManager: assetManager,
                                      fiatService: fiatService,
                                      assetViewModelFactory: factory,
                                      assetsProvider: assetsProvider,
                                      assetIds: assets.map { $0.identifier },
                                      marketCapService: marketCapService) { [weak self] assetId in
            self?.firstAssetId = assetId
        }
    }
    
    func reviewButtonTapped() {
        guard let fiatService = fiatService,
              let assetManager = assetManager,
              let networkFacade = networkFacade else {
            return
        }
        
        wireframe.showConfirmSendingAsset(on: view?.controller.navigationController,
                                          assetId: firstAssetId,
                                          walletService: WalletService(operationFactory: networkFacade),
                                          assetManager: assetManager,
                                          fiatService: fiatService,
                                          recipientAddress: selectedAddress ?? "",
                                          firstAssetAmount: inputedFirstAmount,
                                          fee: fee,
                                          assetsProvider: assetsProvider)
    }
    
    func selectAddress() {
        changeAddress()
    }
}

extension InputAssetAmountViewModel: AssetProviderObserverProtocol {
    func processBalance(data: [BalanceData]) {
        updateBalanceData()
    }
}

extension InputAssetAmountViewModel {
    func updateBalanceData() {
        if !firstAssetId.isEmpty, let balance = assetsProvider?.getBalances(with: [firstAssetId]).first {
            firstAssetBalance = balance
        }
    }
    
    func setupFullBalanceText(from balanceData: BalanceData, complention: @escaping (String) -> Void) {
        let balance = NumberFormatter.polkaswapBalance.stringFromDecimal(balanceData.balance.decimalValue) ?? ""
        var fiatBalanceText = ""
        
        if let usdPrice = fiatData.first(where: { $0.id == balanceData.identifier })?.priceUsd?.decimalValue {
            let fiatDecimal = balanceData.balance.decimalValue * usdPrice
            fiatBalanceText = "$" + (NumberFormatter.fiat.stringFromDecimal(fiatDecimal) ?? "")
        }
        
        let balanceText = fiatBalanceText.isEmpty ? "\(balance)" : "\(balance) (\(fiatBalanceText))"
        complention(balanceText)
    }
    
    func setupInputedFiatText(from inputedAmount: Decimal, assetId: String) -> String {
        guard let asset = assetManager?.assetInfo(for: assetId) else { return "" }
        
        var fiatText = ""
        
        if let usdPrice = fiatData.first(where: { $0.id == asset.assetId })?.priceUsd?.decimalValue {
            let fiatDecimal = inputedAmount * usdPrice
            fiatText = "$" + (NumberFormatter.fiat.stringFromDecimal(fiatDecimal) ?? "")
        }
        
        return fiatText
    }
    
    func checkBalances() -> Bool {
        // check if balance is enough
        if inputedFirstAmount > firstAssetBalance.balance.decimalValue {
            view?.setupButton(isEnabled: false)
            return false
        }

        // check if exchanging from XOR, and have not enough XOR to pay the fee
        if let fromAsset = assetManager?.assetInfo(for: firstAssetId),
           fromAsset.isFeeAsset,
           inputedFirstAmount + fee > firstAssetBalance.balance.decimalValue {
            view?.setupButton(isEnabled: false)
            return false
        }

        return true
    }
    
    func checkXorBalance() -> Bool {
        guard let xorBalance = assetsProvider?.getBalances(with: [WalletAssetId.xor.rawValue]).first else {
            view?.setupButton(isEnabled: false)
            return false
        }

        // check have enough XOR to pay the fee
        if fee > xorBalance.balance.decimalValue {
            view?.setupButton(isEnabled: false)
            return false
        }

        return true
    }
    
    func validationText(with text: String, isEnoghtAssetBalance: Bool, isEnoghtXorBalance: Bool) -> String {
        if !isEnoghtXorBalance {
            return R.string.localizable.errorTransactionFeeTitle(preferredLanguages: .currentLocale)
        }
        
        if !isEnoghtAssetBalance {
            return R.string.localizable.commonNotEnoughBalance(preferredLanguages: .currentLocale)
        }

        return text
    }
    
    func changeAddress() {
        guard let networkFacade = networkFacade,
              let dataProvider = try? providerFactory.createContactsDataProvider(),
              let assetManager = assetManager else { return }

        wireframe.showSelectAddress(on: view?.controller,
                                    assetId: firstAssetId,
                                    dataProvider: dataProvider,
                                    walletService: WalletService(operationFactory: networkFacade),
                                    networkFacade: networkFacade,
                                    assetManager: assetManager,
                                    qrEncoder: qrEncoder,
                                    sharingFactory: sharingFactory,
                                    assetsProvider: assetsProvider,
                                    providerFactory: providerFactory,
                                    feeProvider: feeProvider,
                                    marketCapService: marketCapService) { [weak self] result in
            self?.selectedAddress = result.firstName
            if let assetId = result.receiverInfo?.assetId {
                self?.firstAssetId = assetId
            }
            self?.view?.focusFirstField()
        }
    }
    
    private func updateButtonState() {
        if firstAssetId.isEmpty {
            view?.setupButton(isEnabled: false)
            return
        }
        
        if inputedFirstAmount == .zero {
            view?.setupButton(isEnabled: false)
            return
        }
        
        if !checkBalances() {
            view?.setupButton(isEnabled: false)
            return
        }
        
        if !checkXorBalance() {
            view?.setupButton(isEnabled: false)
            return
        }
        
        if selectedAddress?.isEmpty ?? true {
            view?.setupButton(isEnabled: false)
            return
        }

        view?.setupButton(isEnabled: true)
    }
}

