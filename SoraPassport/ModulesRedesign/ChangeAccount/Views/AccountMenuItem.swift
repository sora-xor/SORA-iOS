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

import SoraUIKit

final class AccountMenuItem: NSObject {
    
    static var itemHeight: CGFloat {
        72
    }
    
    let title: String
    let image: UIImage?
    var isSelected: Bool
    var isMultiselectionMode: Bool
    let onTap: (() -> ())?
    let onMore: (() -> ())?
    
    init(title: String,
         image: UIImage?,
         isSelected: Bool,
         isMultiselectionMode: Bool,
         onTap: (()->())? = nil,
         onMore: (()->())? = nil) {
        self.title = title
        self.image = image
        self.isSelected = isSelected
        self.isMultiselectionMode = isMultiselectionMode
        self.onTap = onTap
        self.onMore = onMore
    }
    
}

extension AccountMenuItem: SoramitsuTableViewItemProtocol {
    var cellType: AnyClass {
        AccountTableViewCell.self
    }
    
    var backgroundColor: SoramitsuColor {
        .custom(uiColor: .clear)
    }
    
    var clipsToBounds: Bool {
        false
    }
    
    func itemHeight(forWidth width: CGFloat, context: SoramitsuTableViewContext?) -> CGFloat {
        return AccountMenuItem.itemHeight
    }
    
    func itemActionTap(with context: SoramitsuTableViewContext?) {
        onTap?()
    }
    
    func itemActionMore(with context: SoramitsuTableViewContext?) {
        onMore?()
    }
}
