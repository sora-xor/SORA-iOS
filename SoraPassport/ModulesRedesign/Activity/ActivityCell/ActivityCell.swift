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

final class ActivityCell: SoramitsuTableViewCell {

    private var assetItem: ActivityItem?
    private var localizationManager = LocalizationManager.shared

    private lazy var historyView: HistoryTransactionView = {
        let view = HistoryTransactionView()
        view.isUserInteractionEnabled = false
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
        contentView.backgroundColor = SoramitsuUI.shared.theme.palette.color(.bgSurface)
        contentView.addSubview(historyView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            historyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            historyView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            historyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            historyView.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
}

extension ActivityCell: CellProtocol {
    func set(item: ItemProtocol) {
        guard let item = item as? ActivityItem else {
            assertionFailure("Incorect type of item")
            return
        }
        
        assetItem = item

        historyView.sora.firstHistoryTransactionImage  = item.model.firstAssetImageViewModel
        historyView.firstCurrencyImageView.sora.loadingPlaceholder.type = item.model.firstAssetImageViewModel != nil ? .none : .shimmer

        historyView.sora.secondHistoryTransactionImage = item.model.secondAssetImageViewModel
        historyView.secondCurrencyImageView.sora.loadingPlaceholder.type = item.model.firstAssetImageViewModel != nil ? .none : .shimmer

        historyView.sora.titleText = item.model.title
        historyView.titleLabel.sora.loadingPlaceholder.type = item.model.title.isEmpty ? .shimmer : .none
        
        historyView.sora.subtitleText = item.model.subtitle
        historyView.subtitleLabel.sora.loadingPlaceholder.type = item.model.subtitle.isEmpty ? .shimmer : .none
        
        historyView.sora.transactionType = item.model.typeTransactionImage
        historyView.transactionTypeImageView.sora.loadingPlaceholder.type = item.model.typeTransactionImage == nil ? .shimmer : .none
        
        historyView.sora.upAmountText = item.model.firstBalanceText
        historyView.amountUpLabel.sora.loadingPlaceholder.type = .none
        
        historyView.sora.fiatText = item.model.fiatText
        historyView.fiatLabel.sora.loadingPlaceholder.type = item.model.fiatText.isEmpty ? .shimmer : .none
        
        historyView.sora.isNeedTwoTokens = item.model.isNeedTwoImage
        historyView.oneCurrencyImageView.sora.loadingPlaceholder.type = item.model.isNeedTwoImage ? .shimmer : .none
        
        historyView.sora.statusImage = item.model.status.image
        historyView.statusImageView.sora.loadingPlaceholder.type = item.model.status.image == nil ? .shimmer : .none
        
        
        let defaultAlignment: NSTextAlignment = localizationManager.isRightToLeft ? .right : .left
        let reversedAlignment: NSTextAlignment = localizationManager.isRightToLeft ? .left : .right
        historyView.amountUpLabel.sora.alignment = reversedAlignment
        historyView.titleLabel.sora.alignment = defaultAlignment
        historyView.subtitleLabel.sora.alignment = defaultAlignment
    }
}
