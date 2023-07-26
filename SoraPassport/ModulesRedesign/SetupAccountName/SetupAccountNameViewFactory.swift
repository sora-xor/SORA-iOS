import Foundation
import SoraFoundation
import RobinHood

final class SetupAccountNameViewFactory {
    static func createViewForOnboarding(mode: UsernameSetupMode = .onboarding, endAddingBlock: (() -> Void)? = nil) -> UsernameSetupViewProtocol? {
        let localizationManager = LocalizationManager.shared
        let view = SetupAccountNameViewController()
        let presenter = UsernameSetupPresenter()
        presenter.mode = mode
        let wireframe = UsernameSetupWireframe(localizationManager: localizationManager, endAddingBlock: endAddingBlock)

        view.presenter = presenter
        presenter.view = view
        presenter.wireframe = wireframe

        presenter.localizationManager = localizationManager

        return view
    }
    
    static func createViewForImport(endAddingBlock: (() -> Void)? = nil) -> UsernameSetupViewProtocol? {
        guard let accountItem = SelectedWalletSettings.shared.currentAccount else { return nil }
        
        let localizationManager = LocalizationManager.shared
        let view = SetupAccountNameViewController()
        let accountRepository: CoreDataRepository<AccountItem, CDAccountItem> =
            UserDataStorageFacade.shared.createRepository()
        
        let presenter = SetupNameImportAccountPresenter(currentAccount: accountItem,
                                                        accountRepository: AnyDataProviderRepository(accountRepository),
                                                        eventCenter: EventCenter.shared,
                                                        operationManager: OperationManager())
        let wireframe = UsernameSetupWireframe(localizationManager: localizationManager)

        view.presenter = presenter
        presenter.view = view
        presenter.wireframe = wireframe

        presenter.localizationManager = localizationManager
        presenter.completion = endAddingBlock
        
        return view
    }

    static func createViewForAdding(isGoogleBackupSelected: Bool = false,
                                    isNeedSetupName: Bool = true,
                                    endEditingBlock: (() -> Void)?) -> UsernameSetupViewProtocol? {
        let localizationManager = LocalizationManager.shared
        let view = SetupAccountNameViewController()
        let presenter = UsernameSetupPresenter()
        let wireframe = AddUsernameWireframe(localizationManager: localizationManager,
                                             isGoogleBackupSelected: isGoogleBackupSelected,
                                             isNeedSetupName: isNeedSetupName)

        view.presenter = presenter
        presenter.view = view
        presenter.wireframe = wireframe
        presenter.mode = .creating
        wireframe.endAddingBlock = endEditingBlock

        return view
    }
}
