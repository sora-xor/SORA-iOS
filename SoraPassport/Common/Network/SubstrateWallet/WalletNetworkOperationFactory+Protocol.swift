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

import BigInt

import SSFUtils
import Foundation
import IrohaCrypto
import RobinHood
import Starscream
import xxHash_Swift

enum WalletNetworkOperationFactoryError: Error {
    case invalidAmount
    case invalidAsset
    case invalidChain
    case invalidReceiver
    case invalidContext
}

extension WalletNetworkOperationFactory: WalletNetworkOperationFactoryProtocol {
    func getPoolsDetails() throws -> CompoundOperationWrapper<[PoolDetails]> {
        CompoundOperationWrapper(targetOperation: .init())
    }

    func fetchBalanceOperation(_ assets: [String]) -> CompoundOperationWrapper<[BalanceData]?> {
        return CompoundOperationWrapper<[BalanceData]?>.createWithResult(nil)
    }

    func fetchTransactionHistoryOperation(_ filter: WalletHistoryRequest,
                                          pagination: Pagination)
        -> CompoundOperationWrapper<AssetTransactionPageData?> {
        let operation = ClosureOperation<AssetTransactionPageData?> {
            nil
        }

        return CompoundOperationWrapper(targetOperation: operation)
    }

    func transferMetadataOperation(_ info: TransferMetadataInfo) -> CompoundOperationWrapper<TransferMetaData?> {
        guard let asset = accountSettings.assets.first(where: { $0.identifier == info.assetId }) else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        let chain = asset.chain

        guard let amount = Decimal(1.0).toSubstrateAmount(precision: asset.precision) else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        guard let receiver = try? Data(hexStringSSF: info.receiver) else {
            let error = WalletNetworkOperationFactoryError.invalidReceiver
            return createCompoundOperation(result: .failure(error))
        }

        let feeAsset = accountSettings.assets.first(where: { $0.isFeeAsset }) ?? asset

        let compoundReceiver = createAccountInfoFetchOperation(receiver)

        let feeOperation = createExtrinsicFeeServiceOperation(asset: asset.identifier,
                                                              amount: amount,
                                                              receiver: info.receiver,
                                                              chain: chain)

        let mapOperation: ClosureOperation<TransferMetaData?> = ClosureOperation {
            let fee = try feeOperation.extractResultData(throwing: BaseOperationError.parentOperationCancelled)
            
            guard let bigIntFee = BigUInt(fee) else {
                return nil
            }

            let decimalFee = Decimal.fromSubstrateAmount(bigIntFee, precision: feeAsset.precision) ?? 0

            let amount = AmountDecimal(value: decimalFee)

            let feeDescription = FeeDescription(identifier: feeAsset.identifier,
                                                assetId: feeAsset.identifier,
                                                type: FeeType.fixed.rawValue,
                                                parameters: [amount])

            if let receiverInfo = try compoundReceiver.targetOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled) {
                let context = TransferMetadataContext(data: receiverInfo.data,
                                                      precision: asset.precision).toContext()
                return TransferMetaData(feeDescriptions: [feeDescription], context: context)
            } else {
                return TransferMetaData(feeDescriptions: [feeDescription])
            }
        }

        let dependencies = [feeOperation] /* + compoundInfo.allOperations */ + compoundReceiver.allOperations

        dependencies.forEach { mapOperation.addDependency($0) }

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    func transferOperation(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        switch info.type {
        case .swap:
            return swapOperationWrapper(info)
        case .liquidityAdd:
            return liquidityAddOperationWrapper(info)
        case .liquidityAddNewPool:
            return newLiquidityAddOperationWrapper(info)
        case .liquidityAddToExistingPoolFirstTime:
            return liquidityAddOperationWrapper(info)
        case .liquidityRemoval:
            return liquidityRemovalOperationWrapper(info)
        case .demeterClaimReward:
            return claimRewardDemeterOperationWrapper(info)
        case .demeterDeposit:
            return depositDemeterOperationWrapper(info)
        case .demeterWithdraw:
            return withdrawDemeterOperationWrapper(info)
        case .outgoing, .incoming, .slash, .reward, .extrinsic, .referral, .migration:
            return transferOperationWrapper(info)
        }
    }

    func liquidityAddOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {

        let assetA: String = info.source
        let assetB: String = info.destination
        let desiredA = AmountDecimal(string: info.context?[TransactionContextKeys.firstAssetAmount] ?? "0") ?? .init(value: 0)
        let desiredB = AmountDecimal(string: info.context?[TransactionContextKeys.secondAssetAmount] ?? "0") ?? .init(value: 0)
        let slippage = AmountDecimal(string: info.context?[TransactionContextKeys.slippage] ?? "0") ?? .init(value: 0)
        let minA = desiredA.decimalValue * (Decimal(1) - slippage.decimalValue / 100)
        let minB = desiredB.decimalValue * (Decimal(1) - slippage.decimalValue / 100)

        guard
            let assetA = accountSettings.assets.first(where: { $0.identifier == assetA }),
            let assetB = accountSettings.assets.first(where: { $0.identifier == assetB })
        else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        guard let amountA = desiredA.decimalValue.toSubstrateAmount(precision: assetA.precision),
              let amountB = desiredB.decimalValue.toSubstrateAmount(precision: assetB.precision),
              let amountMinA = minA.toSubstrateAmount(precision: assetA.precision),
              let amountMinB = minB.toSubstrateAmount(precision: assetB.precision),
              let dexId = info.context?[TransactionContextKeys.dex]
        else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()

            let depositCall = try callFactory.depositLiquidity(
                dexId: dexId,
                assetA: assetA.identifier,
                assetB: assetB.identifier,
                desiredA: amountA,
                desiredB: amountB,
                minA: amountMinA,
                minB: amountMinB
            )

            return try builder
                .adding(call: depositCall)
        }

        let depositLiquidityOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try depositLiquidityOperation.extractResultData() ?? ""

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(depositLiquidityOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [depositLiquidityOperation])
    }

    func newLiquidityAddOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {

        let assetA: String = info.source
        let assetB: String = info.destination
        let desiredA = AmountDecimal(string: info.context?[TransactionContextKeys.firstAssetAmount] ?? "0") ?? .init(value: 0)
        let desiredB = AmountDecimal(string: info.context?[TransactionContextKeys.secondAssetAmount] ?? "0") ?? .init(value: 0)
        let slippage = AmountDecimal(string: info.context?[TransactionContextKeys.slippage] ?? "0") ?? .init(value: 0)
        let minA = desiredA.decimalValue * (Decimal(1) - slippage.decimalValue / 100)
        let minB = desiredB.decimalValue * (Decimal(1) - slippage.decimalValue / 100)

        guard
            let assetA = accountSettings.assets.first(where: { $0.identifier == assetA }),
            let assetB = accountSettings.assets.first(where: { $0.identifier == assetB })
        else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        guard let amountA = desiredA.decimalValue.toSubstrateAmount(precision: assetA.precision),
              let amountB = desiredB.decimalValue.toSubstrateAmount(precision: assetB.precision),
              let amountMinA = minA.toSubstrateAmount(precision: assetA.precision),
              let amountMinB = minB.toSubstrateAmount(precision: assetB.precision)
        else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()

            let dexId = info.context?[TransactionContextKeys.dex] ?? "0"
            let registerCall = try callFactory.register(dexId: dexId,
                                                        baseAssetId: assetA.identifier,
                                                        targetAssetId: assetB.identifier)
            let initializeCall = try callFactory.initializePool(dexId: dexId,
                                                                baseAssetId: assetA.identifier,
                                                                targetAssetId: assetB.identifier)

            let depositCall = try callFactory.depositLiquidity(
                dexId: dexId,
                assetA: assetA.identifier,
                assetB: assetB.identifier,
                desiredA: amountA,
                desiredB: amountB,
                minA: amountMinA,
                minB: amountMinB
            )

            return try builder
                .with(shouldUseAtomicBatch: true)
                .adding(call: registerCall)
                .adding(call: initializeCall)
                .adding(call: depositCall)
        }

        let depositLiquidityOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try depositLiquidityOperation.extractResultData() ?? ""

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(depositLiquidityOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [depositLiquidityOperation])
    }

    func liquidityRemovalOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {

        guard let context = info.context else {
            let error = WalletNetworkOperationFactoryError.invalidContext
            return createCompoundOperation(result: .failure(error))
        }

        let dexId: String = info.context?[TransactionContextKeys.dex] ?? "0"
        let assetA: String = info.source
        let assetB: String = info.destination
        let desiredA = Decimal(string: context[TransactionContextKeys.firstAssetAmount] ?? "0") ?? .zero
        let desiredB = Decimal(string: context[TransactionContextKeys.secondAssetAmount] ?? "0") ?? .zero

        let firstReserves = Decimal(string: context[TransactionContextKeys.firstReserves] ?? "0") ?? .zero
        let totalIssuances = Decimal(string: context[TransactionContextKeys.totalIssuances] ?? "0") ?? .zero

        let assetDesired = (desiredA / firstReserves * totalIssuances) 

        let slippage = Decimal(string: context[TransactionContextKeys.slippage] ?? "0") ?? .zero
        
        let minA = (desiredA - desiredA / Decimal(100) * slippage)
        let minB = (desiredB - desiredB / Decimal(100) * slippage)

        guard
            let assetA = accountSettings.assets.first(where: { $0.identifier == assetA }),
            let assetB = accountSettings.assets.first(where: { $0.identifier == assetB })
        else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        guard let assetDesired = assetDesired.toSubstrateAmount(precision: assetA.precision),
              let amountMinA = minA.toSubstrateAmountRoundingDown(precision: assetA.precision),
              let amountMinB = minB.toSubstrateAmountRoundingDown(precision: assetB.precision)
        else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()

            let withdrawCall = try callFactory.withdrawLiquidityCall(
                dexId: dexId,
                assetA: assetA.identifier,
                assetB: assetB.identifier,
                assetDesired: assetDesired,
                minA: amountMinA,
                minB: amountMinB
            )

            return try builder
                .adding(call: withdrawCall)
        }

        let removeLiquidityOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try removeLiquidityOperation.extractResultData() ?? ""

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(removeLiquidityOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [removeLiquidityOperation])
    }

    private func transferOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        guard
            let asset = accountSettings.assets.first(where: { $0.identifier == info.asset }) else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        guard let amount = info.amount.decimalValue.toSubstrateAmount(precision: asset.precision) else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()

            let transferCall = try callFactory.transfer(to: info.destination, asset: asset.identifier, amount: amount)

            return try builder
                .adding(call: transferCall)
        }

        let transferOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try transferOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(transferOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation,
                                        dependencies: [transferOperation])
    }

    private func swapOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        guard
            let asset = accountSettings.assets.first(where: { $0.identifier == info.asset }),
            accountSettings.assets.first(where: { $0.identifier == info.destination }) != nil
        else {
            let error = WalletNetworkOperationFactoryError.invalidAsset
            return createCompoundOperation(result: .failure(error))
        }

        guard let context = info.context else {
            let error = WalletNetworkOperationFactoryError.invalidContext
            return createCompoundOperation(result: .failure(error))
        }

        guard let amountCall = info.amountCall else {
            let error = WalletNetworkOperationFactoryError.invalidReceiver
            return createCompoundOperation(result: .failure(error))
        }

        let sourceType: String = context[TransactionContextKeys.marketType] ?? ""
        let dexId: String = context[TransactionContextKeys.dex] ?? "0"
        let marketType: LiquiditySourceType = LiquiditySourceType(rawValue: sourceType) ?? .smart
        let marketCode = marketType.code
        let filter = marketType.filter

        let builderClosure: ExtrinsicBuilderClosure = { builder in
            let call = try SubstrateCallFactory().swap(
                from: asset.identifier,
                to: info.destination,
                dexId: dexId,
                amountCall: amountCall,
                type: marketCode,
                filter: filter
            )
            return try builder.adding(call: call)
        }

        let wrapper = createExtrinsicServiceOperation(closure: builderClosure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try wrapper
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(wrapper)

        return CompoundOperationWrapper(targetOperation: mapOperation,
                                        dependencies: [wrapper])
    }

    func searchOperation(_ searchString: String) -> CompoundOperationWrapper<[SearchData]?> {
        return CompoundOperationWrapper<[SearchData]?>.createWithResult(nil)
    }

    func contactsOperation() -> CompoundOperationWrapper<[SearchData]?> {
        return CompoundOperationWrapper<[SearchData]?>.createWithResult(nil)
    }

    func withdrawalMetadataOperation(_ info: WithdrawMetadataInfo)
        -> CompoundOperationWrapper<WithdrawMetaData?> {
        return CompoundOperationWrapper<WithdrawMetaData?>.createWithResult(nil)
    }

    func withdrawOperation(_ info: WithdrawInfo) -> CompoundOperationWrapper<Data> {
        return CompoundOperationWrapper<Data>.createWithResult(Data())
    }
    
    private func claimRewardDemeterOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()
            
            let rewardAsset: String = info.context?[TransactionContextKeys.rewardAsset] ?? ""
            let isFarm: Bool = info.context?[TransactionContextKeys.isFarm] == "1"

            let demeterCall = try callFactory.claimRewardFromDemeterFarmCall(
                baseAssetId: info.source,
                targetAssetId: info.destination,
                rewardAssetId: rewardAsset,
                isFarm: isFarm
            )

            return try builder.adding(call: demeterCall)
        }

        let transferOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try transferOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(transferOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [transferOperation])
    }
    
    private func depositDemeterOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        guard let amount = info.amount.decimalValue.toSubstrateAmount(precision: 18) else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()
            
            let rewardAsset: String = info.context?[TransactionContextKeys.rewardAsset] ?? ""
            let isFarm: Bool = info.context?[TransactionContextKeys.isFarm] == "1"

            let demeterCall = try callFactory.depositLiquidityToDemeterFarmCall(
                baseAssetId: info.source,
                targetAssetId: info.destination,
                rewardAssetId: rewardAsset,
                isFarm: isFarm,
                amount: amount
            )

            return try builder.adding(call: demeterCall)
        }

        let transferOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try transferOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(transferOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [transferOperation])
    }
    
    private func withdrawDemeterOperationWrapper(_ info: TransferInfo) -> CompoundOperationWrapper<Data> {
        guard let amount = info.amount.decimalValue.toSubstrateAmount(precision: 18) else {
            let error = WalletNetworkOperationFactoryError.invalidAmount
            return createCompoundOperation(result: .failure(error))
        }

        let closure: ExtrinsicBuilderClosure = { builder in
            let callFactory = SubstrateCallFactory()
            
            let rewardAsset: String = info.context?[TransactionContextKeys.rewardAsset] ?? ""
            let isFarm: Bool = info.context?[TransactionContextKeys.isFarm] == "1"

            let demeterCall = try callFactory.withdrawLiquidityFromDemeterFarmCall(
                baseAssetId: info.source,
                targetAssetId: info.destination,
                rewardAssetId: rewardAsset,
                isFarm: isFarm,
                amount: amount
            )

            return try builder.adding(call: demeterCall)
        }

        let transferOperation = createExtrinsicServiceOperation(closure: closure)

        let mapOperation: ClosureOperation<Data> = ClosureOperation {
            let hashString = try transferOperation
                .extractResultData(throwing: BaseOperationError.parentOperationCancelled)

            return try Data(hexStringSSF: hashString)
        }

        mapOperation.addDependency(transferOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [transferOperation])
    }
}
