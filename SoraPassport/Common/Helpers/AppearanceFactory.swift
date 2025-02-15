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
import UIKit
import SoraUI

import SoraUIKit

struct AppearanceFactory {
    static func applyGlobalAppearance() {
        configureGlobalNavigationBar()
        configureButtons()
        configureSearchBar()
        configureTabBarItem()
    }

    private static func configureButtons() {
        SoraButton.appearance().titleFont = .styled(for: .button)
        SoraButton.appearance().cornerRadius = 12.0
        SoraButton.appearance().shadowOpacity = 0

        GrayCopyButton.appearance().titleFont = .styled(for: .paragraph2)
        GrayCopyButton.appearance().cornerRadius = 24.0
        GrayCopyButton.appearance().shadowOpacity = 0
    }

    private static func configureSearchBar() {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([
            .foregroundColor: SoramitsuUI.shared.theme.palette.color(.accentPrimary)],
                                             for: .normal)
    }

    private static func configureGlobalNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: SoramitsuUI.shared.theme.palette.color(.fgPrimary) as Any]
        appearance.largeTitleTextAttributes = [.foregroundColor: SoramitsuUI.shared.theme.palette.color(.fgPrimary) as Any]
        appearance.backgroundEffect = UIBlurEffect(style: SoramitsuUI.shared.theme == .light ? .light : .dark)
        
        let scrollingAppearance = UINavigationBarAppearance()
        scrollingAppearance.configureWithTransparentBackground()
        scrollingAppearance.backgroundColor = .clear
        scrollingAppearance.titleTextAttributes = [.foregroundColor: SoramitsuUI.shared.theme.palette.color(.fgPrimary) as Any]
        scrollingAppearance.largeTitleTextAttributes = [.foregroundColor: SoramitsuUI.shared.theme.palette.color(.fgPrimary) as Any]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollingAppearance
        UINavigationBar.appearance().compactAppearance = scrollingAppearance
        UINavigationBar.appearance().tintColor = SoramitsuUI.shared.theme.palette.color(.accentPrimary)
        
        let backImage = R.image.wallet.backArrow()
        
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.clear], for: .normal)
    }
    
    private static func configureTabBarItem() {
        UITabBarItem.appearance().setTitleTextAttributes(FontType.textBoldXS.attributes, for: .normal)
    }
}
