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

final class ConfirmOptionsCell: SoramitsuTableViewCell {
    
    private lazy var optionsView: OptionsView = {
        let view = OptionsView()
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.marketLabel.sora.isHidden = true
        view.marketButton.sora.isHidden = true
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
        contentView.addSubview(optionsView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            optionsView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            optionsView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            optionsView.topAnchor.constraint(equalTo: contentView.topAnchor),
        ])
    }
}

extension ConfirmOptionsCell: SoramitsuTableViewCellProtocol {
    func set(item: SoramitsuTableViewItemProtocol, context: SoramitsuTableViewContext?) {
        guard let item = item as? ConfirmOptionsItem else {
            assertionFailure("Incorect type of item")
            return
        }
        
        optionsView.slipageButton.sora.title = item.toleranceText
        optionsView.marketButton.sora.title = item.market?.titleForLocale(.current)
        optionsView.marketLabel.sora.isHidden = item.market == nil
        optionsView.marketButton.sora.isHidden = item.market == nil
    }
}

