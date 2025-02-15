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
import SoraFoundation

final class PooledCell: SoramitsuTableViewCell {
    
    private var activityItem: PooledItem?
    private var localizationManager = LocalizationManager.shared

    private let titleLabel: SoramitsuLabel = {
        let label = SoramitsuLabel()
        label.sora.font = FontType.headline2
        label.sora.textColor = .fgPrimary
        return label
    }()

    private let fullStackView: SoramitsuStackView = {
        var view = SoramitsuStackView()
        view.sora.backgroundColor = .bgSurface
        view.sora.axis = .vertical
        view.sora.cornerRadius = .max
        view.sora.distribution = .fill
        view.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        contentView.addSubview(fullStackView)
        fullStackView.addArrangedSubviews(titleLabel)
        fullStackView.setCustomSpacing(16, after: titleLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fullStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            fullStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fullStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fullStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
    
    private func updateSemantics() {
        let semanticContentAttribute: UISemanticContentAttribute = localizationManager.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
        let alignment: NSTextAlignment = localizationManager.isRightToLeft ? .right : .left
        
        fullStackView.semanticContentAttribute = semanticContentAttribute
        titleLabel.sora.alignment = alignment
    }
}

extension PooledCell: SoramitsuTableViewCellProtocol {
    func set(item: SoramitsuTableViewItemProtocol, context: SoramitsuTableViewContext?) {
        guard let item = item as? PooledItem else {
            assertionFailure("Incorect type of item")
            return
        }
        
        titleLabel.sora.text = R.string.localizable.assetDetailsYourPools(item.assetSymbol, preferredLanguages: .currentLocale)
        
        fullStackView.arrangedSubviews.filter { $0 is PoolView }.forEach { subview in
            fullStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let poolViews = item.poolViewModels.map { poolModel -> PoolView in
            let poolView = PoolView(mode: .view)
            poolView.firstCurrencyImageView.sora.loadingPlaceholder.type = .none
            poolView.secondCurrencyImageView.sora.loadingPlaceholder.type = .none
            poolView.rewardImageView.sora.loadingPlaceholder.type = .none
            poolView.titleLabel.sora.loadingPlaceholder.type = .none
            poolView.subtitleLabel.sora.loadingPlaceholder.type = .none
            poolView.amountUpLabel.sora.loadingPlaceholder.type = .none
            poolView.sora.firstPoolImage = poolModel.baseAssetImage
            poolView.sora.secondPoolImage = poolModel.targetAssetImage
            poolView.sora.rewardTokenImage = poolModel.rewardAssetImage
            poolView.sora.titleText = poolModel.title
            poolView.sora.subtitleText = poolModel.subtitle
            poolView.sora.upAmountText = poolModel.fiatText
            poolView.amountDownLabel.sora.attributedText = poolModel.deltaArributedText
            poolView.sora.addHandler(for: .touchUpInside) {
                item.openPoolDetailsHandler?(poolModel.identifier)
            }
            poolView.isRightToLeft = localizationManager.isRightToLeft
            return poolView
        }

        fullStackView.addArrangedSubviews(poolViews)
        activityItem = item
        
        updateSemantics()
    }
}

