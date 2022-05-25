import Foundation
import IrohaCrypto

final class AddCreationWireframe: AccountCreateWireframeProtocol {
    func confirm(from view: AccountCreateViewProtocol?,
                 request: AccountCreationRequest,
                 metadata: AccountCreationMetadata) {
        guard let accountConfirmation = AccountConfirmViewFactory
            .createViewForAdding(request: request, metadata: metadata)?.controller else {
            return
        }

        if let navigationController = view?.controller.navigationController {
            navigationController.pushViewController(accountConfirmation, animated: true)
        }
    }
}
