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
import SoraKeystore
import SoraFoundation

import SoraUIKit
import RobinHood
import SSFCloudStorage

final class AccountImportedWireframe {

    private weak var currentController: AccountImportedViewProtocol?
    private var endAddingBlock: (() -> Void)?
    
    init(currentController: AccountImportedViewProtocol? = nil,
         endAddingBlock: (() -> Void)? = nil) {
        self.currentController = currentController
        self.endAddingBlock = endAddingBlock
    }
}

extension AccountImportedWireframe: AccountImportedWireframeProtocol {
    @MainActor 
    func showSetupPinCode() {
        let view = PinViewFactory.createRedesignPinSetupView()
        
        let containerView = BlurViewController()
        containerView.isClosable = false
        containerView.modalPresentationStyle = .overFullScreen
        containerView.add(view?.controller)
        
        currentController?.controller.present(containerView, animated: true)
    }
    
    func showBackepedAccounts(accounts: [OpenBackupAccount]) {
        guard let viewController = BackupedAccountsViewFactory.createView(
            with: accounts,
            endAddingBlock: endAddingBlock
        )?.controller else { return }
        currentController?.controller.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func dismiss(completion: (() -> Void)?) {
        currentController?.controller.dismiss(animated: true, completion: completion)
    }
}
