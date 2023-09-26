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
import CommonWallet
import SoraUIKit
import UIKit
import sorawallet
import SoraFoundation

protocol DetailViewModelDelegate: AnyObject {
    func networkFeeInfoButtonTapped()
    func swapFeeInfoButtonTapped()
    func minMaxReceivedInfoButtonTapped()
}

protocol DetailViewModelFactoryProtocol {
    func createPoolDetailViewModels(with poolInfo: PoolInfo, apy: Decimal?, viewModel: PoolDetailsViewModelProtocol) -> [DetailViewModel]
    func createSupplyLiquidityViewModels(with baseAssetAmount: Decimal,
                                         targetAssetAmount: Decimal,
                                         pool: PoolInfo?,
                                         apy: Decimal?,
                                         fiatData: [FiatData],
                                         focusedField: FocusedField,
                                         slippageTolerance: Float,
                                         isPresented: Bool,
                                         isEnabled: Bool,
                                         fee: Decimal,
                                         viewModel: LiquidityViewModelProtocol) -> [DetailViewModel]
    
    func createRemoveLiquidityViewModels(with baseAssetAmount: Decimal,
                                         targetAssetAmount: Decimal,
                                         pool: PoolInfo,
                                         apy: Decimal?,
                                         fiatData: [FiatData],
                                         focusedField: FocusedField,
                                         slippageTolerance: Float,
                                         isPresented: Bool,
                                         isEnabled: Bool,
                                         fee: Decimal,
                                         viewModel: LiquidityViewModelProtocol) -> [DetailViewModel]
    
    func createSwapViewModels(fromAsset: AssetInfo,
                              toAsset: AssetInfo,
                              slippage: Decimal,
                              amount: Decimal,
                              quote: SwapQuoteAmounts,
                              direction: SwapVariant,
                              fiatData: [FiatData],
                              swapFee: Decimal,
                              route: String,
                              viewModel: DetailViewModelDelegate) -> [DetailViewModel]
    
    func createSendingAssetViewModels(fee: Decimal,
                                      fiatData: [FiatData],
                                      viewModel: ConfirmSendingViewModelProtocol) -> [DetailViewModel]
}

final class DetailViewModelFactory {
    let assetManager: AssetManagerProtocol

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter.amount
        formatter.roundingMode = .floor
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.locale = !LocalizationManager.shared.isArabic ? LocalizationManager.shared.selectedLocale : nil
        return formatter
    }()
    
    let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter.amount
        formatter.roundingMode = .floor
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = !LocalizationManager.shared.isArabic ? LocalizationManager.shared.selectedLocale : nil
        return formatter
    }()
    
    init(assetManager: AssetManagerProtocol) {
        self.assetManager = assetManager
    }
}

extension DetailViewModelFactory: DetailViewModelFactoryProtocol {
    func createPoolDetailViewModels(with poolInfo: PoolInfo, apy: Decimal?, viewModel: PoolDetailsViewModelProtocol) -> [DetailViewModel] {
        var viewModels: [DetailViewModel] = []
        
        let baseAsset = assetManager.assetInfo(for: poolInfo.baseAssetId)
        let targetAsset = assetManager.assetInfo(for: poolInfo.targetAssetId)
        let rewardAsset = assetManager.assetInfo(for: WalletAssetId.pswap.rawValue)
        
        let baseAssetSymbol = baseAsset?.symbol.uppercased() ?? ""
        let targetAssetSymbol = targetAsset?.symbol.uppercased() ?? ""
        
        if let apyValue = apy {
            let apyText = "\(percentFormatter.stringFromDecimal(apyValue * 100) ?? "")% APY"
            let assetAmountText = SoramitsuTextItem(text: apyText,
                                                    fontData: FontType.textBoldS,
                                                    textColor: .fgPrimary,
                                                    alignment: .right)
            let apyDetailsViewModel = DetailViewModel(title: Constants.apyTitle,
                                                      assetAmountText: assetAmountText)
            apyDetailsViewModel.infoHandler = { [weak viewModel] in
                viewModel?.apyInfoButtonTapped()
            }
            viewModels.append(apyDetailsViewModel)
        }

        let rewardText = SoramitsuTextItem(text: rewardAsset?.symbol ?? "",
                                           fontData: FontType.textS,
                                           textColor: .fgPrimary,
                                           alignment: .right)
        let rewardDetailsViewModel = DetailViewModel(title: R.string.localizable.polkaswapRewardPayout(preferredLanguages: .currentLocale),
                                                     rewardAssetImage: rewardAsset?.icon,
                                                     assetAmountText: rewardText)
        viewModels.append(rewardDetailsViewModel)
        
        if let yourPoolShare = poolInfo.yourPoolShare {
            let poolShareText = NumberFormatter.cryptoAssets.stringFromDecimal(yourPoolShare) ?? ""
            let yourPoolShareText = SoramitsuTextItem(text: "\(poolShareText)%",
                                                          fontData: FontType.textS,
                                                          textColor: .fgPrimary,
                                                          alignment: .right)
            let yourPoolShareViewModel = DetailViewModel(title: R.string.localizable.poolShareTitle1(preferredLanguages: .currentLocale),
                                                                     assetAmountText: yourPoolShareText)
            viewModels.append(yourPoolShareViewModel)
        }
        
        let baseAssetPooledByAccount = poolInfo.baseAssetPooledByAccount ?? 0
        let basePooledAmount = formatter.stringFromDecimal(baseAssetPooledByAccount) ?? ""
        let baseAssetPooledText = SoramitsuTextItem(text: "\(basePooledAmount) \(baseAssetSymbol)",
                                                    fontData: FontType.textS,
                                                    textColor: .fgPrimary,
                                                    alignment: .right)
        let basePooledAmountDetailsViewModel = DetailViewModel(title: "Your \(baseAssetSymbol) pooled",
                                                               assetAmountText: baseAssetPooledText)
        if baseAssetPooledByAccount > 0 {
            viewModels.append(basePooledAmountDetailsViewModel)
        }
        
        let targetAssetPooledByAccount = poolInfo.targetAssetPooledByAccount ?? 0
        let targetPooledAmount = formatter.stringFromDecimal(targetAssetPooledByAccount) ?? ""
        let targetAssetPooledText = SoramitsuTextItem(text: "\(targetPooledAmount) \(targetAssetSymbol)",
                                                      fontData: FontType.textS,
                                                      textColor: .fgPrimary,
                                                      alignment: .right)
        let targetPooledAmountDetailsViewModel = DetailViewModel(title: "Your \(targetAssetSymbol) pooled",
                                                                 assetAmountText: targetAssetPooledText)
        if targetAssetPooledByAccount > 0 {
            viewModels.append(targetPooledAmountDetailsViewModel)
        }

        return viewModels
    }
    
    func createSupplyLiquidityViewModels(with baseAssetAmount: Decimal,
                                         targetAssetAmount: Decimal,
                                         pool: PoolInfo?,
                                         apy: Decimal?,
                                         fiatData: [FiatData],
                                         focusedField: FocusedField,
                                         slippageTolerance: Float,
                                         isPresented: Bool,
                                         isEnabled: Bool,
                                         fee: Decimal,
                                         viewModel: LiquidityViewModelProtocol) -> [DetailViewModel] {
        var viewModels: [DetailViewModel] = []
        
        let resultAmount = !isPresented ? targetAssetAmount : calculateAddLiquidityAmount(
            baseAmount: baseAssetAmount,
            reservesFirst: pool?.baseAssetReserves ?? 0,
            reservesSecond: pool?.targetAssetReserves ?? 0,
            focusedField: focusedField)

        let poolShareDecimal = estimateAddingShareOfPool(amount: focusedField == .one ? resultAmount : baseAssetAmount,
                                                      pooled: pool?.targetAssetPooledByAccount ?? 0,
                                                      reserves: pool?.targetAssetReserves ?? 0)

        let poolShareText = NumberFormatter.cryptoAssets.stringFromDecimal(poolShareDecimal) ?? ""
        let yourPoolShareText = SoramitsuTextItem(text: "\(poolShareText)%",
                                                      fontData: FontType.textS,
                                                      textColor: .fgPrimary,
                                                      alignment: .right)
        let yourPoolShareViewModel = DetailViewModel(title: R.string.localizable.poolShareTitle1(preferredLanguages: .currentLocale),
                                                                 assetAmountText: yourPoolShareText)
        viewModels.append(yourPoolShareViewModel)
        
        if let apyValue = apy {
            let apyText = "\(percentFormatter.stringFromDecimal(apyValue * 100) ?? "")% APY"
            let assetAmountText = SoramitsuTextItem(text: apyText,
                                                    fontData: FontType.textBoldS,
                                                    textColor: .fgPrimary,
                                                    alignment: .right)
            let apyDetailsViewModel = DetailViewModel(title: Constants.apyTitle,
                                                      assetAmountText: assetAmountText)
            apyDetailsViewModel.infoHandler = {
                viewModel.apyInfoButtonTapped()
            }
            viewModels.append(apyDetailsViewModel)
        }
        
        
        let rewardAsset = assetManager.assetInfo(for: WalletAssetId.pswap.rawValue)
        
        let rewardText = SoramitsuTextItem(text: rewardAsset?.symbol ?? "",
                                           fontData: FontType.textS,
                                           textColor: .fgPrimary,
                                           alignment: .right)
        let rewardDetailsViewModel = DetailViewModel(title: R.string.localizable.polkaswapRewardPayout(preferredLanguages: .currentLocale),
                                                     rewardAssetImage: rewardAsset?.icon,
                                                     assetAmountText: rewardText)
        viewModels.append(rewardDetailsViewModel)
        
        let feeText = SoramitsuTextItem(text: "\(NumberFormatter.cryptoAssets.stringFromDecimal(fee) ?? "") XOR",
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let feeAssetId = assetManager.getAssetList()?.first { $0.isFeeAsset }?.assetId
        let usdPrice = (fiatData.first { $0.id == feeAssetId }?.priceUsd ?? 0).decimalValue
        let fiatFeeText = SoramitsuTextItem(text: "$\(NumberFormatter.fiat.stringFromDecimal(usdPrice * fee) ?? "")" ,
                                            fontData: FontType.textBoldXS,
                                            textColor: .fgSecondary,
                                            alignment: .right)
        let feeViewModel = DetailViewModel(title: R.string.localizable.networkFee(preferredLanguages: .currentLocale),
                                                               assetAmountText: feeText,
                                                               fiatAmountText: fiatFeeText)
        viewModels.append(feeViewModel)
        
        return viewModels
    }
    
    func createRemoveLiquidityViewModels(with baseAssetAmount: Decimal,
                                         targetAssetAmount: Decimal,
                                         pool: PoolInfo,
                                         apy: Decimal?,
                                         fiatData: [FiatData],
                                         focusedField: FocusedField,
                                         slippageTolerance: Float,
                                         isPresented: Bool,
                                         isEnabled: Bool,
                                         fee: Decimal,
                                         viewModel: LiquidityViewModelProtocol) -> [DetailViewModel] {
        let poolShareDecimal = estimateRemoveShareOfPool(amount: targetAssetAmount,
                                                         pooled: pool.targetAssetPooledByAccount ?? 0,
                                                         reserves: pool.targetAssetReserves ?? 0)

        let poolShareText = NumberFormatter.cryptoAssets.stringFromDecimal(poolShareDecimal) ?? ""
        let yourPoolShareText = SoramitsuTextItem(text: "\(poolShareText)%",
                                                      fontData: FontType.textS,
                                                      textColor: .fgPrimary,
                                                      alignment: .right)
        let yourPoolShareViewModel = DetailViewModel(title: R.string.localizable.poolShareTitle1(preferredLanguages: .currentLocale),
                                                                 assetAmountText: yourPoolShareText)
        
        let apyValue = apy ?? 0
        let apyText = "\(percentFormatter.stringFromDecimal(apyValue * 100) ?? "")% APY"
        let assetAmountText = SoramitsuTextItem(text: apyText,
                                                fontData: FontType.textBoldS,
                                                textColor: .fgPrimary,
                                                alignment: .right)
        let apyDetailsViewModel = DetailViewModel(title: Constants.apyTitle,
                                                  assetAmountText: assetAmountText)
        apyDetailsViewModel.infoHandler = {
            viewModel.apyInfoButtonTapped()
        }
        
        let feeText = SoramitsuTextItem(text: "\(NumberFormatter.cryptoAssets.stringFromDecimal(fee) ?? "") XOR",
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let feeAssetId = assetManager.getAssetList()?.first { $0.isFeeAsset }?.assetId
        let usdPrice = (fiatData.first { $0.id == feeAssetId }?.priceUsd ?? 0).decimalValue
        let fiatFeeText = SoramitsuTextItem(text: "$\(NumberFormatter.fiat.stringFromDecimal(usdPrice * fee) ?? "")" ,
                                            fontData: FontType.textBoldXS,
                                            textColor: .fgSecondary,
                                            alignment: .right)
        let feeViewModel = DetailViewModel(title: R.string.localizable.networkFee(preferredLanguages: .currentLocale),
                                                               assetAmountText: feeText,
                                                               fiatAmountText: fiatFeeText)
        
        return [ yourPoolShareViewModel,
                 apyDetailsViewModel,
                 feeViewModel]
    }
    
    func createSwapViewModels(fromAsset: AssetInfo,
                              toAsset: AssetInfo,
                              slippage: Decimal,
                              amount: Decimal,
                              quote: SwapQuoteAmounts,
                              direction: SwapVariant,
                              fiatData: [FiatData],
                              swapFee: Decimal,
                              route: String,
                              viewModel: DetailViewModelDelegate) -> [DetailViewModel] {
        let minMaxValue = direction == .desiredInput ? quote.toAmount * (1 - slippage / 100.0) : quote.toAmount * (1 + slippage / 100.0)
        let minMaxReceivedViewModel = minMaxReceivedViewModel(asset: direction == .desiredInput ? toAsset : fromAsset,
                                                              title: direction.title,
                                                              minBuyValue: minMaxValue,
                                                              slippage: slippage,
                                                              fiatData: fiatData,
                                                              viewModel: viewModel)
        
        let fromAssetToAssetAmount = amount / quote.toAmount
        let fromAssetToAssetAmountText = NumberFormatter.cryptoAssets.stringFromDecimal(fromAssetToAssetAmount) ?? ""
        let fromAssetToAssetAmountTextItem = SoramitsuTextItem(text: fromAssetToAssetAmountText,
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let fromAssetToAsset = DetailViewModel(title: "\(fromAsset.symbol) / \(toAsset.symbol)",
                                               assetAmountText: fromAssetToAssetAmountTextItem)
        
        let toAssetFromAssetAmount =  quote.toAmount / amount
        let toAssetFromAssetAmountText = NumberFormatter.cryptoAssets.stringFromDecimal(toAssetFromAssetAmount) ?? ""
        let toAssetFromAssetTextItem = SoramitsuTextItem(text: toAssetFromAssetAmountText,
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let toAssetFromAsset = DetailViewModel(title: "\(toAsset.symbol) / \(fromAsset.symbol)",
                                               assetAmountText: toAssetFromAssetTextItem)
        
        let routeTextItem = SoramitsuTextItem(text: route,
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let routeModel = DetailViewModel(title: R.string.localizable.route(preferredLanguages: .currentLocale),
                                         assetAmountText: routeTextItem)
        
        let feeText = SoramitsuTextItem(text: "\(NumberFormatter.cryptoAssets.stringFromDecimal(swapFee) ?? "") XOR",
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let feeAssetId = assetManager.getAssetList()?.first { $0.isFeeAsset }?.assetId
        let usdPrice = (fiatData.first { $0.id == feeAssetId }?.priceUsd ?? 0).decimalValue
        let fiatFeeText = SoramitsuTextItem(text: "$\(NumberFormatter.fiat.stringFromDecimal(usdPrice * swapFee) ?? "")" ,
                                            fontData: FontType.textBoldXS,
                                            textColor: .fgSecondary,
                                            alignment: .right)
        let feeViewModel = DetailViewModel(title: R.string.localizable.networkFee(preferredLanguages: .currentLocale),
                                                               assetAmountText: feeText,
                                                               fiatAmountText: fiatFeeText)
        
        feeViewModel.infoHandler = { [weak viewModel] in
            viewModel?.networkFeeInfoButtonTapped()
        }
        
        let lpFeeText = SoramitsuTextItem(text: "\(NumberFormatter.cryptoAssets.stringFromDecimal(quote.lpAmount) ?? "") XOR",
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let fiatLpFeeText = SoramitsuTextItem(text: "$\(NumberFormatter.fiat.stringFromDecimal(usdPrice * quote.lpAmount) ?? "")" ,
                                            fontData: FontType.textBoldXS,
                                            textColor: .fgSecondary,
                                            alignment: .right)
        let lpFeeViewModel = DetailViewModel(title: R.string.localizable.polkaswapLiquidityTotalFee(preferredLanguages: .currentLocale),
                                             assetAmountText: lpFeeText,
                                             fiatAmountText: fiatLpFeeText)
        
        lpFeeViewModel.infoHandler = { [weak viewModel] in
            viewModel?.swapFeeInfoButtonTapped()
        }
        
        return [minMaxReceivedViewModel, fromAssetToAsset, toAssetFromAsset, routeModel, feeViewModel, lpFeeViewModel]
    }
    
    func createSendingAssetViewModels(fee: Decimal,
                                      fiatData: [FiatData],
                                      viewModel: ConfirmSendingViewModelProtocol) -> [DetailViewModel] {
        let feeText = SoramitsuTextItem(text: "\(NumberFormatter.cryptoAssets.stringFromDecimal(fee) ?? "") XOR",
                                        fontData: FontType.textS,
                                        textColor: .fgPrimary,
                                        alignment: .right)
        let feeAssetId = assetManager.getAssetList()?.first { $0.isFeeAsset }?.assetId
        let usdPrice = (fiatData.first { $0.id == feeAssetId }?.priceUsd ?? 0).decimalValue
        let fiatFeeText = SoramitsuTextItem(text: "$\(NumberFormatter.fiat.stringFromDecimal(usdPrice * fee) ?? "")" ,
                                            fontData: FontType.textBoldXS,
                                            textColor: .fgSecondary,
                                            alignment: .right)
        let feeViewModel = DetailViewModel(title: R.string.localizable.networkFee(preferredLanguages: .currentLocale),
                                                               assetAmountText: feeText,
                                                               fiatAmountText: fiatFeeText)
        feeViewModel.infoHandler = { [weak viewModel] in
            viewModel?.networkFeeInfoButtonTapped()
        }
        return [feeViewModel]
    }
}

private extension DetailViewModelFactory {
    
    func estimateAddingShareOfPool(amount: Decimal, pooled: Decimal, reserves: Decimal) -> Decimal {
        return (pooled + amount) / (amount + reserves) * 100
    }
    
    func calculateAddLiquidityAmount(
        baseAmount: Decimal,
        reservesFirst: Decimal,
        reservesSecond: Decimal,
        focusedField: FocusedField
    ) -> Decimal {
        guard focusedField == .one else {
            return baseAmount * reservesFirst / reservesSecond
        }
        
        return baseAmount * reservesSecond / reservesFirst
    }
    
    func estimateRemoveShareOfPool(amount: Decimal, pooled: Decimal, reserves: Decimal) -> Decimal {
        if (amount - reserves) == 0 {
            return 0
        }
        return abs((pooled - amount) / (amount - reserves) * 100) 
    }
    
    func minMaxReceivedViewModel(asset: AssetInfo,
                                 title: String,
                                 minBuyValue: Decimal,
                                 slippage: Decimal,
                                 fiatData: [FiatData],
                                 viewModel: DetailViewModelDelegate) -> DetailViewModel {
        let minBuyToken = asset.symbol
        let minBuyText = NumberFormatter.cryptoAssets.stringFromDecimal(minBuyValue) ?? ""
        let minBuyValueText = SoramitsuTextItem(text: "\(minBuyText) \(minBuyToken)",
                                                fontData: FontType.textS,
                                                textColor: .fgPrimary,
                                                alignment: .right)
        
        let minBuyUsdPrice = (fiatData.first { $0.id == asset.identifier }?.priceUsd ?? 0).decimalValue
        let minBuyFiatText = SoramitsuTextItem(text: "~$\(NumberFormatter.fiat.stringFromDecimal(minBuyUsdPrice * minBuyValue) ?? "")" ,
                                               fontData: FontType.textBoldXS,
                                               textColor: .fgSecondary,
                                               alignment: .right)
        
        let minMaxReceivedViewModel = DetailViewModel(title: title,
                                                      assetAmountText: minBuyValueText,
                                                      fiatAmountText: minBuyFiatText)
        
        minMaxReceivedViewModel.infoHandler = { [weak viewModel] in
            viewModel?.minMaxReceivedInfoButtonTapped()
        }
        
        return minMaxReceivedViewModel
    }
}

