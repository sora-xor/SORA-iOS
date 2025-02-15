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
import Anchorage
import SoraFoundation

final class MoreMenuCell: SoramitsuTableViewCell {

    let categoryItem: CategoryItem = {
        let view = CategoryItem(frame: .zero)
        view.sora.cornerRadius = .max
        view.sora.clipsToBounds = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        contentView.addSubview(categoryItem)
    }

    func setupConstraints() {
        categoryItem.leadingAnchor == contentView.leadingAnchor + 16
        categoryItem.trailingAnchor == contentView.trailingAnchor - 16
        categoryItem.topAnchor == contentView.topAnchor + 8
        categoryItem.bottomAnchor == contentView.bottomAnchor - 8
    }
    
    func updateLayout() {
        let isRTL: Bool = LocalizationManager.shared.isRightToLeft
        let semanticContentAttribute: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        categoryItem.horizontalStack.semanticContentAttribute = semanticContentAttribute
        categoryItem.verticalStack.semanticContentAttribute = semanticContentAttribute
        categoryItem.subtitleView.semanticContentAttribute = semanticContentAttribute
        categoryItem.titleLabel.sora.alignment = isRTL ? .right : .left
        categoryItem.subtitleLabel.sora.alignment = isRTL ? .right : .left
    }
}

extension MoreMenuCell: SoramitsuTableViewCellProtocol {
    func set(item: SoramitsuTableViewItemProtocol, context: SoramitsuTableViewContext?) {
        guard let item = item as? MoreMenuItem else {
            return
        }

        categoryItem.titleLabel.sora.text = item.title
        categoryItem.subtitleLabel.sora.text = item.subtitle
        categoryItem.rightImageView.sora.picture = item.picture

        if let circleColor = item.circleColor {
            categoryItem.addCircle()
            categoryItem.circle.sora.backgroundColor = circleColor
        } else {
            categoryItem.hideCircle()
        }

        if let circleColorStream = item.circleColorStream {
            Task {
                for await color in circleColorStream {
                    if let color = color {
                        categoryItem.addCircle()
                        categoryItem.circle.sora.backgroundColor = color
                    } else {
                        categoryItem.hideCircle()
                    }
                }
            }
        }

        if let subtitleStream = item.subtitleStream {
            Task {
                for await subtitle in subtitleStream {
                    categoryItem.subtitleLabel.sora.text = subtitle
                }
            }
        }

        updateLayout()
    }
}

