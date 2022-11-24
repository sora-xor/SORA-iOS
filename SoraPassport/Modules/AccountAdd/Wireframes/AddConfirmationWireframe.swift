/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
//
final class AddConfirmationWireframe: AccountConfirmWireframeProtocol {
    var endAddingBlock: (() -> Void)?

    func proceed(from view: AccountConfirmViewProtocol?) {
        guard let navigationController = view?.controller.navigationController else {
            return
        }

        guard let endAddingBlock = endAddingBlock else {
            MainTransitionHelper.transitToMainTabBarController(closing: navigationController, animated: true)
            return
        }

        endAddingBlock()
    }
}
