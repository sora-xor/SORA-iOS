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
import CommonWallet
import RobinHood
import SoraFoundation
import sorawallet
import Combine

final class SwapViewModel {
    @Published var snapshot: PolkaswapSnapshot = PolkaswapSnapshot()
    var snapshotPublisher: Published<PolkaswapSnapshot>.Publisher { $snapshot }
    
    var detailsItem: PoolDetailsItem?
    var setupItems: (([SoramitsuTableViewItemProtocol]) -> Void)?
    var reloadItems: (([SoramitsuTableViewItemProtocol]) -> Void)?
    
    weak var fiatService: FiatServiceProtocol?
    weak var view: LiquidityViewProtocol?
    weak var polkaswapNetworkFacade: PolkaswapNetworkOperationFactoryProtocol?
    var wireframe: LiquidityWireframeProtocol?
    let assetManager: AssetManagerProtocol?
    let detailsFactory: DetailViewModelFactoryProtocol
    let eventCenter: EventCenterProtocol
    let interactor: PolkaswapMainInteractorInputProtocol
    let networkFacade: WalletNetworkOperationFactoryProtocol?
    let itemFactory: PolkaswapItemFactory
    
    let debouncer = Debouncer(interval: 0.8)
    
    @Published var firstAsset: AssetProfile = AssetProfile()
    @Published var secondAsset: AssetProfile = AssetProfile()
    @Published var slippageToleranceText: String = ""
    @Published var selectedMarketText: String = ""
    @Published var reviewButtonTitle: String = ""
    @Published var isMiddleButtonEnabled: Bool = true
    @Published var isButtonEnabled: Bool = false
    @Published var isAccessoryViewHidden: Bool = true
    @Published var isNeedLoadingState: Bool = false
    @Published var isMarketLoadingState: Bool = false
    @Published var warningViewModel: WarningViewModel?
    @Published var firstLiquidityViewModel: WarningViewModel?
    @Published var details: [DetailViewModel]?
    
    var firstAssetPublisher: Published<AssetProfile>.Publisher { $firstAsset }
    var secondAssetPublisher: Published<AssetProfile>.Publisher { $secondAsset }
    var slippagePublisher: Published<String>.Publisher { $slippageToleranceText }
    var marketPublisher: Published<String>.Publisher { $selectedMarketText }
    var reviewButtonPublisher: Published<String>.Publisher { $reviewButtonTitle }
    var isMiddleButtonEnabledPublisher: Published<Bool>.Publisher { $isMiddleButtonEnabled }
    var isButtonEnabledPublisher: Published<Bool>.Publisher { $isButtonEnabled }
    var isAccessoryViewHiddenPublisher: Published<Bool>.Publisher { $isAccessoryViewHidden }
    var isNeedLoadingStatePublisher: Published<Bool>.Publisher { $isNeedLoadingState }
    var isMarketLoadingStatePublisher: Published<Bool>.Publisher { $isMarketLoadingState }
    var warningViewModelPublisher: Published<WarningViewModel?>.Publisher { $warningViewModel }
    var firstLiquidityViewModelPublisher: Published<WarningViewModel?>.Publisher { $firstLiquidityViewModel }
    var detailsPublisher: Published<[DetailViewModel]?>.Publisher { $details }
    
    var title: String? {
        return nil
    }
    
    var imageName: String? {
        return "Wallet/polkaswapLogo"
    }
    
    var isSwap: Bool {
        return true
    }
    
    var firstFieldEmptyStateFullFiatText: String? { R.string.localizable.swapWantFrom(preferredLanguages: .currentLocale) }
    var secondFieldEmptyStateFullFiatText: String? { R.string.localizable.swapWantTo(preferredLanguages: .currentLocale) }
    
    var actionButtonImage: UIImage? {
        return R.image.wallet.swapButton()
    }
    
    var middleButtonActionHandler: (() -> Void)?
    
    var firstAssetBalance: BalanceData = BalanceData(identifier: WalletAssetId.xor.rawValue, balance: AmountDecimal(value: 0)) {
        didSet {
            let balanceText = setupFullBalanceText(from: firstAssetBalance)
            update(firstAsset, balance: balanceText)
            checkBalances()
            
            let inputedFiatText = setupInputedFiatText(from: inputedFirstAmount, assetId: firstAssetId)
            let fiatText = isEnoughtFirstAssetLiquidity ? inputedFiatText : R.string.localizable.commonNotEnoughBalance(preferredLanguages: .currentLocale)
            let amountColor: SoramitsuColor = isEnoughtFirstAssetLiquidity ? .fgPrimary : .statusError
            let fiatColor: SoramitsuColor = isEnoughtFirstAssetLiquidity ? .fgSecondary : .statusError
            var state: InputFieldState = focusedField == .one ? .focused : .default
            state = isEnoughtFirstAssetLiquidity ? state : .fail
            
            update(firstAsset, state: state, amountColor: amountColor, fiatColor: fiatColor)
            update(firstAsset, fiat: fiatText)
        }
    }
    
    var secondAssetBalance: BalanceData = BalanceData(identifier: WalletAssetId.xor.rawValue, balance: AmountDecimal(value: 0)) {
        didSet {
            let balanceText = setupFullBalanceText(from: secondAssetBalance)
            update(secondAsset, balance: balanceText)
        }
    }
    
    var firstAssetId: String = "" {
        didSet {
            guard let asset = assetManager?.assetInfo(for: firstAssetId) else { return }
            let image = RemoteSerializer.shared.image(with: asset.icon ?? "")
            update(firstAsset, symbol: asset.symbol, image: image)
            
            updateAssetsBalance()
            updateMiddleButton(isEnabled: !secondAssetId.isEmpty && !firstAssetId.isEmpty)
            
            if !firstAssetId.isEmpty, !secondAssetId.isEmpty {
                marketSourcer = SwapMarketSourcer(fromAssetId: firstAssetId, toAssetId: secondAssetId)
                interactor.checkIsPathAvailable(fromAssetId: firstAssetId, toAssetId: secondAssetId)
                loadQuote()
            }
        }
    }
    
    var secondAssetId: String = "" {
        didSet {
            guard let asset = assetManager?.assetInfo(for: secondAssetId) else { return }
            let image = RemoteSerializer.shared.image(with: asset.icon ?? "")
            update(secondAsset, symbol: asset.symbol, image: image)
            updateAssetsBalance()
            updateMiddleButton(isEnabled: !secondAssetId.isEmpty && !firstAssetId.isEmpty)
            
            if !firstAssetId.isEmpty, !secondAssetId.isEmpty {
                marketSourcer = SwapMarketSourcer(fromAssetId: firstAssetId, toAssetId: secondAssetId)
                interactor.checkIsPathAvailable(fromAssetId: firstAssetId, toAssetId: secondAssetId)
                loadQuote()
            }
        }
    }
    
    var inputedFirstAmount: Decimal = 0 {
        didSet(oldValue) {
            if oldValue != inputedFirstAmount, swapVariant == .desiredInput {
                loadQuote()
            }

            let inputedFiatText = setupInputedFiatText(from: inputedFirstAmount, assetId: firstAssetId)
            let text = isEnoughtFirstAssetLiquidity ? inputedFiatText : R.string.localizable.commonNotEnoughBalance(preferredLanguages: .currentLocale)
            let amountColor: SoramitsuColor = isEnoughtFirstAssetLiquidity ? .fgPrimary : .statusError
            let fiatColor: SoramitsuColor = isEnoughtFirstAssetLiquidity ? .fgSecondary : .statusError
            var state: InputFieldState = focusedField == .one ? .focused : .default
            state = isEnoughtFirstAssetLiquidity ? state : .fail
            
            update(firstAsset, state: state, amountColor: amountColor, fiatColor: fiatColor)
            update(firstAsset, fiat: text)
        }
    }
    
    var inputedSecondAmount: Decimal = 0 {
        didSet(oldValue) {
            if oldValue != inputedSecondAmount, swapVariant == .desiredOutput {
                loadQuote()
            }

            let inputedFiatText = setupInputedFiatText(from: inputedSecondAmount, assetId: secondAssetId)
            let state: InputFieldState = self.focusedField == .two ? .focused : .default
            update(secondAsset, state: state, amountColor: .fgPrimary, fiatColor: .fgSecondary)
            update(secondAsset, fiat: inputedFiatText)
        }
    }
    
    var slippageTolerance: Float = 0.5 {
        didSet {
            let slippageToleranceText = "\(slippageTolerance)%"
            update(slippageTolerance: slippageToleranceText)
            loadQuote()
        }
    }
    
    var selectedMarket: LiquiditySourceType = .smart {
        didSet {
            loadQuote()
            update(selectedMarket: selectedMarket.titleForLocale(.current))
        }
    }
    
    var amounts: SwapQuoteAmounts? {
        didSet {
            switch swapVariant {
            case .desiredInput:
                inputedSecondAmount = amounts?.toAmount ?? 0
                let formatter = NumberFormatter.inputedAmoutFormatter(with: assetManager?.assetInfo(for: secondAssetId)?.precision ?? 0)
                set(secondAsset, amount: formatter.stringFromDecimal(inputedSecondAmount) ?? "")
            case .desiredOutput:
                inputedFirstAmount = amounts?.toAmount ?? 0
                let formatter = NumberFormatter.inputedAmoutFormatter(with: assetManager?.assetInfo(for: firstAssetId)?.precision ?? 0)
                set(firstAsset, amount: formatter.stringFromDecimal(inputedFirstAmount) ?? "")
            }
            
            updateWarningModel()
        }
    }
    
    var focusedField: FocusedField = .one {
        didSet {
            swapVariant = focusedField == .one ? .desiredInput : .desiredOutput
            setAccessoryView(isHidden: focusedField == .two)
        }
    }
    var swapVariant: SwapVariant = .desiredInput
    var marketSourcer: SwapMarketSourcerProtocol?

    private var quote: SwapValues?
    private var quoteParams: PolkaswapMainInteractorQuoteParams?
    
    private let feeProvider: FeeProviderProtocol
    private var fiatData: [FiatData] = [] {
        didSet {
            updateAssetsBalance()
        }
    }
    private var fee: Decimal = 0 {
        didSet {

        }
    }
    private var dexId: UInt32 = 0
    private var minBuy: Decimal = 0
    private var selectedTokenId: String
    private var selectedSecondTokenId: String
    private weak var assetsProvider: AssetProviderProtocol?
    private var lpServiceFee: LPFeeServiceProtocol
    private let marketCapService: MarketCapServiceProtocol
    
    private var warningViewModelFactory: WarningViewModelFactory

    private var isEnoughtFirstAssetLiquidity: Bool {
        if inputedFirstAmount > firstAssetBalance.balance.decimalValue {
            return false
        }

        if let fromAsset = assetManager?.assetInfo(for: firstAssetId),
           fromAsset.isFeeAsset,
           inputedFirstAmount + fee > firstAssetBalance.balance.decimalValue {
            return false
        }

        return true
    }
    
    init(
        selectedTokenId: String = WalletAssetId.xor.rawValue,
        selectedSecondTokenId: String = "",
        wireframe: LiquidityWireframeProtocol?,
        fiatService: FiatServiceProtocol?,
        assetManager: AssetManagerProtocol?,
        detailsFactory: DetailViewModelFactoryProtocol,
        eventCenter: EventCenterProtocol,
        interactor: PolkaswapMainInteractor,
        networkFacade: WalletNetworkOperationFactoryProtocol?,
        assetsProvider: AssetProviderProtocol?,
        lpServiceFee: LPFeeServiceProtocol,
        polkaswapNetworkFacade: PolkaswapNetworkOperationFactoryProtocol?,
        warningViewModelFactory: WarningViewModelFactory = WarningViewModelFactory(),
        marketCapService: MarketCapServiceProtocol,
        itemFactory: PolkaswapItemFactory
    ) {
        self.assetsProvider = assetsProvider
        self.fiatService = fiatService
        self.wireframe = wireframe
        self.assetManager = assetManager
        self.detailsFactory = detailsFactory
        self.feeProvider = FeeProvider()
        self.interactor = interactor
        self.networkFacade = networkFacade
        self.selectedTokenId = selectedTokenId
        self.selectedSecondTokenId = selectedSecondTokenId
        self.eventCenter = eventCenter
        self.lpServiceFee = lpServiceFee
        self.polkaswapNetworkFacade = polkaswapNetworkFacade
        self.warningViewModelFactory = warningViewModelFactory
        self.marketCapService = marketCapService
        self.itemFactory = itemFactory
        self.eventCenter.add(observer: self)
    }
}

extension SwapViewModel: EventVisitorProtocol {
    func processNewBlockAppeared(event: NewBlockEvent) {
        loadQuote()
    }
}

extension SwapViewModel: LiquidityViewModelProtocol {
    func reload() {
        snapshot = createSnapshot()
    }
    
    private func createSnapshot() -> PolkaswapSnapshot {
        var snapshot = PolkaswapSnapshot()
        
        let sections = [ contentSection() ]
        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
        
        return snapshot
        
    }
    
    private func contentSection() -> PolkaswapSection {
        var items: [PolkaswapSectionItem] = []
        
        let polkaswapItem = itemFactory.createPolkaswapItem(with: self)
        let detailsItem = itemFactory.createSwapDetailsItem(with: self)
        
        items.append(contentsOf: [
            .polkaswap(polkaswapItem),
            .space(SoramitsuTableViewSpacerItem(space: 16, color: .custom(uiColor: .clear))),
            .details(detailsItem)
        ])
        
        return PolkaswapSection(items: items)
    }
    
    func didSelect(variant: Float) {
        switch focusedField {
        case .one:
            guard firstAssetBalance.balance.decimalValue > 0 else { return }
            let isFeeAsset = assetManager?.assetInfo(for: firstAssetId)?.isFeeAsset ?? false
            let value = firstAssetBalance.balance.decimalValue * (Decimal(string: "\(variant)") ?? 0)
            inputedFirstAmount = isFeeAsset ? value - fee : value
            let formatter = NumberFormatter.inputedAmoutFormatter(with: assetManager?.assetInfo(for: firstAssetId)?.precision ?? 0)
            set(firstAsset, amount: formatter.stringFromDecimal(inputedFirstAmount) ?? "")
        case .two:
            guard secondAssetBalance.balance.decimalValue > 0 else { return }
            let isFeeAsset = assetManager?.assetInfo(for: secondAssetId)?.isFeeAsset ?? false
            let value = secondAssetBalance.balance.decimalValue * (Decimal(string: "\(variant)") ?? 0)
            inputedSecondAmount = isFeeAsset ? value - fee : value
            let formatter = NumberFormatter.inputedAmoutFormatter(with: assetManager?.assetInfo(for: firstAssetId)?.precision ?? 0)
            set(secondAsset, amount: formatter.stringFromDecimal(inputedSecondAmount) ?? "")
        }
    }
    
    func viewDidLoad() {
        firstAssetId = selectedTokenId
        secondAssetId = selectedSecondTokenId
        selectedMarket = .smart
        slippageTolerance = 0.5

        middleButtonActionHandler = { [weak self] in
            guard let self = self else { return }

            let tmpAssetId = self.firstAssetId
            self.firstAssetId = self.secondAssetId
            self.secondAssetId = tmpAssetId
            
            let firstFormatter = NumberFormatter.inputedAmoutFormatter(with: self.assetManager?.assetInfo(for: self.firstAssetId)?.precision ?? 0)
            self.set(self.secondAsset, amount: firstFormatter.stringFromDecimal(self.inputedFirstAmount) ?? "")
            
            let secondFormatter = NumberFormatter.inputedAmoutFormatter(with: self.assetManager?.assetInfo(for: self.secondAssetId)?.precision ?? 0)
            self.set(self.firstAsset, amount: secondFormatter.stringFromDecimal(self.inputedSecondAmount) ?? "")
            
            if self.focusedField == .one {
                self.inputedSecondAmount = self.inputedFirstAmount
            } else {
                self.inputedFirstAmount = self.inputedSecondAmount
            }

            self.focus(field: self.focusedField == .one ? .two : .one)
            self.update(isNeedLoadingState: true)
        }

        updateMiddleButton(isEnabled: false)
        setupButton(isEnabled: false)
        updateAssetsBalance()
        assetsProvider?.add(observer: self)
        updateDetails()
        reload()
    }
    
    
    func choiсeBaseAssetButtonTapped() {
        guard let assetManager = assetManager,
              let fiatService = fiatService,
              let assets = assetManager.getAssetList()?.filter({ $0.identifier != secondAssetId }) else { return }
        
        let factory = AssetViewModelFactory(walletAssets: assets,
                                            assetManager: assetManager,
                                            fiatService: fiatService)
        
        wireframe?.showChoiсeBaseAsset(on: view?.controller,
                                       assetManager: assetManager,
                                       fiatService: fiatService,
                                       assetViewModelFactory: factory,
                                       assetsProvider: assetsProvider,
                                       assetIds: assets.map { $0.identifier },
                                       marketCapService: marketCapService) { [weak self] assetId in
            self?.firstAssetId = assetId
        }
    }
    
    func choiсeTargetAssetButtonTapped() {
        guard let assetManager = assetManager,
              let fiatService = fiatService,
              let assets = assetManager.getAssetList()?.filter({ $0.identifier != firstAssetId }) else { return }

        let factory = AssetViewModelFactory(walletAssets: assetManager.getAssetList() ?? [],
                                            assetManager: assetManager,
                                            fiatService: fiatService)
        
        wireframe?.showChoiсeBaseAsset(on: view?.controller,
                                       assetManager: assetManager,
                                       fiatService: fiatService,
                                       assetViewModelFactory: factory,
                                       assetsProvider: assetsProvider,
                                       assetIds: assets.map { $0.identifier },
                                       marketCapService: marketCapService) { [weak self] assetId in
            self?.secondAssetId = assetId
        }
    }
    
    func changeSlippageTolerance() {
        wireframe?.showSlippageTolerance(on: view?.controller.navigationController,
                                         currentLocale: slippageTolerance,
                                         completion: { [weak self] slippageTolerance in
            self?.slippageTolerance = slippageTolerance
        })
    }
    
    func changeMarket() {
        wireframe?.showChoiсeMarket(on: view?.controller.navigationController,
                                    selectedMarket: selectedMarket,
                                    markets: (marketSourcer?.getMarketSources().filter { $0 == .smart || $0 == .tbc }) ?? [ .smart ],
                                    completion: { [weak self] market in
            self?.selectedMarket = market
        })
    }
    
    func reviewButtonTapped() {
        guard let assetManager = assetManager, let amounts = amounts, let quoteParams = quoteParams, let details = details else { return }
        wireframe?.showSwapConfirmation(on: view?.controller.navigationController,
                                        baseAssetId: firstAssetId,
                                        targetAssetId: secondAssetId,
                                        assetManager: assetManager,
                                        eventCenter: eventCenter,
                                        firstAssetAmount: inputedFirstAmount,
                                        secondAssetAmount: inputedSecondAmount,
                                        slippageTolerance: slippageTolerance,
                                        market: selectedMarket,
                                        details: details,
                                        amounts: amounts,
                                        fee: fee,
                                        swapVariant: swapVariant,
                                        networkFacade: networkFacade,
                                        minMaxValue: minBuy,
                                        dexId: dexId,
                                        lpFee: amounts.lpAmount,
                                        quoteParams: quoteParams,
                                        assetsProvider: assetsProvider,
                                        fiatData: fiatData,
                                        polkaswapNetworkFacade: polkaswapNetworkFacade)
    }
    
    func recalculate(field: FocusedField) {}
}

extension SwapViewModel: PolkaswapMainInteractorOutputProtocol {
    func didCheckPath(fromAssetId: String, toAssetId: String, isAvailable: Bool) {
        guard !firstAssetId.isEmpty, !secondAssetId.isEmpty else { return }

        if !isAvailable {
            setupButton(isEnabled: false)
        } else {
            setupMarketButton(isLoadingState: true)
            interactor.loadMarketSources(fromAssetId: fromAssetId, toAssetId: toAssetId)
        }
    }
    
    func didLoadMarketSources(_ serverMarketSources: [String], fromAssetId: String, toAssetId: String) {
        guard !firstAssetId.isEmpty, !secondAssetId.isEmpty, let marketSourcer = marketSourcer else { return }

        marketSourcer.didLoad(serverMarketSources)
        setupMarketButton(isLoadingState: false)
        updateSelectedMarketSourceIfNecessary()
        loadQuote()
    }
    
    func didLoadQuote(_ quote: SwapValues?, dexId: UInt32, params: PolkaswapMainInteractorQuoteParams) {
        guard updateButtonState()  else {
            update(isNeedLoadingState: false)
            return
        }

        guard let quote = quote else {
            setupButton(isEnabled: false)
            update(isNeedLoadingState: false)
            updateReviewButton(title: R.string.localizable.polkaswapNoSuchPool(preferredLanguages: .currentLocale))
            return
        }

        guard updateButtonState() else {
            update(isNeedLoadingState: false)
            return
        }

        guard params.fromAssetId == firstAssetId, params.toAssetId == secondAssetId else {
            update(isNeedLoadingState: false)
            return
        }
        
        updateDetails(params: params, quote: quote, dexId: dexId) { [weak self] in
            guard let self = self, self.checkBalances() else {
                self?.update(isNeedLoadingState: false)
                return
            }

            // check if exchanging to XOR, we'll receive enough XOR to pay nework fee from it
            if let toAsset = self.assetManager?.assetInfo(for: self.secondAssetId),
               toAsset.isFeeAsset {
                let xorAmount = self.swapVariant == .desiredInput ? self.minBuy : self.inputedSecondAmount
                let xorAmountFuture = self.secondAssetBalance.balance.decimalValue + xorAmount
                guard xorAmountFuture > self.fee else {
                    self.update(isNeedLoadingState: false)
                    self.setupButton(isEnabled: false)
                    return
                }
            }

            self.setupButton(isEnabled: true)
        }
    }
    
    func didUpdatePoolSubscription() {
        loadQuote()
    }
}

extension SwapViewModel: AssetProviderObserverProtocol {
    func processBalance(data: [BalanceData]) {
        updateAssetsBalance()
    }
}

extension SwapViewModel {
    
    func updateAssetsBalance() {
        if !firstAssetId.isEmpty, let firstAssetBalance = assetsProvider?.getBalances(with: [firstAssetId]).first {
            self.firstAssetBalance = firstAssetBalance
        }
        
        if !secondAssetId.isEmpty, let secondAssetBalance = assetsProvider?.getBalances(with: [secondAssetId]).first {
            self.secondAssetBalance = secondAssetBalance
        }
    }
    
    func setupFullBalanceText(from balanceData: BalanceData) -> String {
        let balance = NumberFormatter.polkaswapBalance.stringFromDecimal(balanceData.balance.decimalValue) ?? ""
        var fiatBalanceText = ""
        
        if let usdPrice = fiatData.first(where: { $0.id == balanceData.identifier })?.priceUsd?.decimalValue {
            let fiatDecimal = balanceData.balance.decimalValue * usdPrice
            fiatBalanceText = "$" + (NumberFormatter.fiat.stringFromDecimal(fiatDecimal) ?? "")
        }
        
        return fiatBalanceText.isEmpty ? "\(balance)" : "\(balance) (\(fiatBalanceText))"
    }
    
    func setupInputedFiatText(from inputedAmount: Decimal, assetId: String) -> String {
        guard let asset = assetManager?.assetInfo(for: assetId) else { return "" }

        let usdPrice = fiatData.first(where: { $0.id == asset.assetId })?.priceUsd?.decimalValue ?? 0
        let fiatDecimal = inputedAmount * usdPrice
        let fiatText = "$" + (NumberFormatter.fiat.stringFromDecimal(fiatDecimal) ?? "")

        return fiatText
    }
    
    func updateDetails(params: PolkaswapMainInteractorQuoteParams? = nil,
                       quote: SwapValues? = nil,
                       dexId: UInt32 = 0,
                       completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        
        group.enter()
        fiatService?.getFiat { [weak self] fiatData in
            self?.fiatData = fiatData
            group.leave()
        }
        
        group.enter()
        feeProvider.getFee(for: .swap) { [weak self] fee in
            self?.fee = fee
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            self.quote = quote
            self.quoteParams = params
            self.dexId = dexId
            
            guard let params = params,
                  let quote = quote,
                  let fromAsset = self.assetManager?.assetInfo(for: self.firstAssetId),
                  let toAsset = self.assetManager?.assetInfo(for: self.secondAssetId) else { return }
            
            
            guard let amounts = SwapQuoteAmountsFactory().createAmounts(fromAsset: fromAsset,
                                                                        toAsset: toAsset,
                                                                        params: params,
                                                                        quote: quote) else { return }
            self.amounts = amounts
            
            let amount = self.swapVariant == .desiredInput ? self.inputedFirstAmount : self.inputedSecondAmount
            let route = self.quote?.route.compactMap({ self.assetManager?.assetInfo(for: $0)?.symbol }).joined(separator: " → ")
            
            self.minBuy = amounts.toAmount * (1 - Decimal(Double(self.slippageTolerance)) / 100.0)
            self.details = self.detailsFactory.createSwapViewModels(fromAsset: fromAsset,
                                                                    toAsset: toAsset,
                                                                    slippage: Decimal(Double(self.slippageTolerance)),
                                                                    amount: amount,
                                                                    quote: amounts,
                                                                    direction: self.swapVariant,
                                                                    fiatData: self.fiatData,
                                                                    swapFee: self.fee,
                                                                    route: route ?? "",
                                                                    viewModel: self)
            self.update(isNeedLoadingState: false)
            completion?()
        }
    }
    
    func updateSelectedMarketSourceIfNecessary() {
        guard let marketSourcer = marketSourcer else { return }

        if !marketSourcer.contains(selectedMarket) {
            selectedMarket = marketSourcer.getMarketSources().last ?? .smart
        }
    }

    func loadQuote() {
        updateReviewButton(title: R.string.localizable.review(preferredLanguages: .currentLocale))

        let amount: String
        if swapVariant == .desiredInput {
            let assetInfo = assetManager?.assetInfo(for: firstAssetId)
            amount = String(inputedFirstAmount.toSubstrateAmount(precision: Int16(assetInfo?.precision ?? 0)) ?? 0)
        } else {
            let assetInfo = assetManager?.assetInfo(for: secondAssetId)
            amount = String(inputedSecondAmount.toSubstrateAmount(precision: Int16(assetInfo?.precision ?? 0)) ?? 0)
        }

        // request quote
        guard let marketSourcer = marketSourcer,
                marketSourcer.isLoaded() else {
            return
        }

        let filterMode: FilterMode = selectedMarket == .smart ? .disabled : .allowSelected
        let liquiditySources = marketSourcer.getServerMarketSources()
        let params = PolkaswapMainInteractorQuoteParams(fromAssetId: firstAssetId,
                                                        toAssetId: secondAssetId,
                                                        amount: amount,
                                                        swapVariant: swapVariant,
                                                        liquiditySources: liquiditySources,
                                                        filterMode: filterMode)

        debouncer.perform { [weak self] in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                self?.interactor.quote(params: params)
            }
        }
    }
    
    func updateButtonState() -> Bool {
        guard !firstAssetId.isEmpty && !secondAssetId.isEmpty else {
            setupButton(isEnabled: false)
            return false
        }

        if let marketSourcer = marketSourcer, marketSourcer.isLoaded() && marketSourcer.isEmpty() {
            setupButton(isEnabled: false)
            return false
        }

        if swapVariant == .desiredInput && inputedFirstAmount == 0.0 {
            setupButton(isEnabled: false)
            return false
        } else if swapVariant == .desiredOutput && inputedSecondAmount == 0.0 {
            setupButton(isEnabled: false)
            return false
        }

        return true
    }
    
    func checkBalances() -> Bool {
        // check if balance is enough
        if inputedFirstAmount > firstAssetBalance.balance.decimalValue {
            setupButton(isEnabled: false)
            return false
        }

        // check if exchanging from XOR, and have not enough XOR to pay the fee
        if let fromAsset = assetManager?.assetInfo(for: firstAssetId),
           fromAsset.isFeeAsset,
           inputedFirstAmount + fee > firstAssetBalance.balance.decimalValue {
            setupButton(isEnabled: false)
            return false
        }

        return true
    }
    
    func updateWarningModel() {
        guard let feeAsset = assetManager?.getAssetList()?.first(where: { $0.isFeeAsset }),
              let feeAssetBalance = assetsProvider?.getBalances(with: [feeAsset.assetId]).first else { return }

        var isDisclamerHidden = true

        if feeAsset.assetId == firstAssetId {
            isDisclamerHidden = firstAssetBalance.balance.decimalValue - inputedFirstAmount - fee > fee
        } else {
            isDisclamerHidden = feeAssetBalance.balance.decimalValue - fee > fee
        }
        
        if firstAssetId.isEmpty ||
            secondAssetId.isEmpty ||
            inputedFirstAmount == 0 ||
            inputedSecondAmount == 0 ||
            firstAssetBalance.balance.decimalValue == 0 {
            isDisclamerHidden = true
        }

        warningViewModel = warningViewModelFactory.insufficientBalanceViewModel(
            feeAssetSymbol: feeAsset.symbol,
            feeAmount: fee,
            isHidden: isDisclamerHidden
        )
    }
}


extension SwapViewModel: DetailViewModelDelegate {
    func minMaxReceivedInfoButtonTapped() {
        wireframe?.present(
            message: swapVariant.message,
            title: swapVariant.title,
            closeAction: R.string.localizable.commonOk(preferredLanguages: .currentLocale),
            from: view
        )
    }
    
    func networkFeeInfoButtonTapped() {
        wireframe?.present(
            message: R.string.localizable.polkaswapNetworkFeeInfo(preferredLanguages: .currentLocale),
            title: R.string.localizable.networkFee(preferredLanguages: .currentLocale),
            closeAction: R.string.localizable.commonOk(preferredLanguages: .currentLocale),
            from: view
        )
    }
    
    func swapFeeInfoButtonTapped() {
        wireframe?.present(
            message: R.string.localizable.polkaswapLiquidityTotalFeeDesc(preferredLanguages: .currentLocale),
            title: R.string.localizable.polkaswapLiquidityTotalFee(preferredLanguages: .currentLocale),
            closeAction: R.string.localizable.commonOk(preferredLanguages: .currentLocale),
            from: view
        )
    }
}

extension SwapViewModel {
    func update(_ asset: AssetProfile, state: InputFieldState, amountColor: SoramitsuColor, fiatColor: SoramitsuColor) {
        asset.state = state
        asset.amountColor = amountColor
        asset.fiatColor = fiatColor
    }
    
    func update(_ asset: AssetProfile, fiat: String) {
        asset.fiat = fiat
    }
    
    func update(_ asset: AssetProfile, balance: String) {
        asset.balance = balance
    }
    
    func update(_ asset: AssetProfile, symbol: String, image: UIImage?) {
        asset.symbol = symbol
        asset.image = image
    }
    
    func updateMiddleButton(isEnabled: Bool) {
        isMiddleButtonEnabled = isEnabled
    }
    
    func update(slippageTolerance: String) {
        slippageToleranceText = slippageTolerance
    }
    
    func update(selectedMarket: String) {
        selectedMarketText = selectedMarket
    }
    
    func set(_ asset: AssetProfile, amount: String) {
        asset.amount = amount
    }
    
    func setAccessoryView(isHidden: Bool) {
        isAccessoryViewHidden = isHidden
    }
    
    func update(isNeedLoadingState: Bool) {
        self.isNeedLoadingState = isNeedLoadingState
    }
    
    func focus(field: FocusedField) {
        switch field {
        case .one:
            firstAsset.isFirstResponder = true
        case .two:
            secondAsset.isFirstResponder = true
        }
    }
    
    func setupButton(isEnabled: Bool) {
        isButtonEnabled = isEnabled
    }
    
    func setupMarketButton(isLoadingState: Bool) {
        isMarketLoadingState = isLoadingState
    }
    
    func updateReviewButton(title: String) {
        reviewButtonTitle = title
    }
}
