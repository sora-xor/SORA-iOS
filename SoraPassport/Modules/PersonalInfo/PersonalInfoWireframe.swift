import Foundation

final class PersonalInfoWireframe: PersonalInfoWireframeProtocol {
    lazy var rootAnimator: RootControllerAnimationCoordinatorProtocol = RootControllerAnimationCoordinator()

    func showPassphraseBackup(from view: PersonalInfoViewProtocol?) {
        guard let passphraseView = AccessBackupViewFactory.createView() else {
            return
        }

        let navigationController = SoraNavigationController(rootViewController: passphraseView.controller)
        rootAnimator.animateTransition(to: navigationController)
    }
}
