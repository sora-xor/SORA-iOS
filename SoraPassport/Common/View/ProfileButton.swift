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
import SoraUI

@IBDesignable
final class ProfileButton: BackgroundedContentControl {
    private(set) var titleLabel: UILabel!
    private(set) var subtitleLabel: UILabel!

    public var roundedBackgroundView: RoundedView? {
        return self.backgroundView as? RoundedView
    }

    lazy var highlitedOnAnimation: ViewAnimatorProtocol = TransformAnimator.highlightedOn

    lazy var highlitedOffAnimation: ViewAnimatorProtocol = TransformAnimator.highlightedOff

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }

        set {
            let oldValue = super.isHighlighted
            super.isHighlighted = newValue

            if !oldValue, newValue {
                layer.removeAllAnimations()
                highlitedOnAnimation.animate(view: self, completionBlock: nil)
            }

            if oldValue, !newValue {
                layer.removeAllAnimations()
                highlitedOffAnimation.animate(view: self, completionBlock: nil)
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        configure()
    }

    public func configure() {
        self.backgroundColor = UIColor.clear

        if self.backgroundView == nil {
            self.backgroundView = RoundedView()
            self.backgroundView?.isUserInteractionEnabled = false
        }

        if self.contentView == nil {
            let contentView = UIView()

            titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true

            subtitleLabel = UILabel()
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subtitleLabel)

            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

            self.contentView = contentView
            self.contentView?.isUserInteractionEnabled = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let currentContentView = contentView else { return }

        let contentSize = CGSize(width: bounds.size.width - contentInsets.left - contentInsets.right,
                                 height: bounds.size.height - contentInsets.top - contentInsets.bottom)
        let contentX = contentInsets.left
        let contentY = contentInsets.top

        currentContentView.frame = CGRect(origin: CGPoint(x: contentX, y: contentY), size: contentSize)
    }
}
