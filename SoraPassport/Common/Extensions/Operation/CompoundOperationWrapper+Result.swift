/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood

extension CompoundOperationWrapper {
    static func createWithError(_ error: Error) -> CompoundOperationWrapper<ResultType> {
        let operation = BaseOperation<ResultType>()
        operation.result = .failure(error)
        return CompoundOperationWrapper(targetOperation: operation)
    }

    static func createWithResult(_ result: ResultType) -> CompoundOperationWrapper<ResultType> {
        let operation = BaseOperation<ResultType>()
        operation.result = .success(result)
        return CompoundOperationWrapper(targetOperation: operation)
    }
}
