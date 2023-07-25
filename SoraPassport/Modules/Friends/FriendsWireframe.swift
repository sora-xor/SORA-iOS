import Foundation
import UIKit
import CommonWallet
import SoraUIKit

final class FriendsWireframe: FriendsWireframeProtocol {

    private(set) var walletContext: CommonWalletContextProtocol
    private(set) var assetManager: AssetManagerProtocol

    init(walletContext: CommonWalletContextProtocol,
         assetManager: AssetManagerProtocol) {
        self.walletContext = walletContext
        self.assetManager = assetManager
    }

    func showLinkInputViewController(from controller: UIViewController, delegate: InputLinkPresenterOutput) {
        guard let inputLinkController = ReferralViewFactory.createInputLinkView(with: delegate) else { return }
        
        let containerView = BlurViewController()
        containerView.modalPresentationStyle = .overFullScreen
        
        let navigationController = UINavigationController(rootViewController: inputLinkController)
        navigationController.navigationBar.backgroundColor = .clear
        
        containerView.add(navigationController)
        controller.present(containerView, animated: true)
    }

    func showInputRewardAmountViewController(from controller: UIViewController,
                                             fee: Decimal,
                                             bondedAmount: Decimal,
                                             type: InputRewardAmountType,
                                             delegate: InputRewardAmountPresenterOutput) {

        guard let viewController = ReferralViewFactory.createInputRewardAmountView(with: fee,
                                                                                   bondedAmount: bondedAmount,
                                                                                   type: type,
                                                                                   walletContext: walletContext,
                                                                                   delegate: delegate),
              let navigationController = controller.navigationController
        else {
            return
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }

    func showReferrerScreen(from controller: UIViewController, referrer: String) {
        let viewController = ReferralViewFactory.createReferrerView(with: referrer)
        controller.present(viewController, animated: true, completion: nil)
    }

    func showActivityViewController(from controller: UIViewController, shareText: String) {
        let textToShare = [ shareText ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        controller.present(activityViewController, animated: true, completion: nil)
    }
    
    func showActivityDetails(from controller: UIViewController?, model: Transaction, completion: (() -> Void)?) {
        guard let activityDetailsController = ReferralViewFactory.createActivityDetailsView(assetManager: assetManager,
                                                                                            model: model,
                                                                                            completion: completion),
              let controller = controller
        else {
            return
        }
        let containerView = BlurViewController()
        containerView.modalPresentationStyle = .overFullScreen
        containerView.completionHandler = completion
        containerView.add(activityDetailsController)
        
        controller.present(containerView, animated: true)
    }
}
