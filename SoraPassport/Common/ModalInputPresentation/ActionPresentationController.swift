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

import UIKit
import SoraFoundation

class ActionPresentationController: UIPresentationController {
    var backgroundViewColor: UIColor = UIColor.black.withAlphaComponent(0.19) {
        didSet {
            backgroundView?.backgroundColor = backgroundViewColor
        }
    }

    private var backgroundView: UIView?

    private var keyboardHandler: KeyboardHandler?

    // MARK: Initialization

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?,
         keyboardHandler: KeyboardHandler? = nil) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        if let modalInputView = presentedViewController.view as? ModalInputViewProtocol {
            modalInputView.presenter = self
        }

        self.keyboardHandler = keyboardHandler
    }

    private func configureBackgroundView(on view: UIView) {
        if let currentBackgroundView = backgroundView {
            view.insertSubview(currentBackgroundView, at: 0)
        } else {
            let newBackgroundView = UIView(frame: view.bounds)
            newBackgroundView.backgroundColor = backgroundViewColor
            view.insertSubview(newBackgroundView, at: 0)
            backgroundView = newBackgroundView
        }

        backgroundView?.frame = view.bounds
    }

    private func attachCancellationGesture() {
        let cancellationGesture = UITapGestureRecognizer(target: self,
                                                         action: #selector(actionDidCancel(gesture:)))
        backgroundView?.addGestureRecognizer(cancellationGesture)
    }

    // MARK: Keyboard Input Handling

    private func configureKeyboardHandlerIfNeeded() {
        if let keyboardHandler = keyboardHandler {
            keyboardHandler.animateOnFrameChange = { [weak self] (newBounds) in
                self?.animateKeyboardBoundsChange(with: newBounds)
            }
        }
    }

    private func animateKeyboardBoundsChange(with newBounds: CGRect) {
        guard
            let containerView = containerView,
            let presentedView = presentedView else {
                return
        }

        let keyboardBounds = containerView.convert(newBounds, to: nil)

        let layoutFrame = containerView.safeAreaLayoutGuide.layoutFrame

        var originY = keyboardBounds.minY - presentedView.frame.size.height
        originY = max(originY, layoutFrame.minY)
        originY = min(originY, layoutFrame.maxY - presentedView.frame.size.height)
        presentedView.frame = CGRect(x: layoutFrame.minX,
                                     y: originY,
                                     width: presentedView.frame.size.width,
                                     height: presentedView.frame.size.height)
    }

    // MARK: Presentation overridings

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }

        configureBackgroundView(on: containerView)
        attachCancellationGesture()
        configureKeyboardHandlerIfNeeded()

        animateBackgroundAlpha(fromValue: 0.0, toValue: 1.0)
    }

    override func dismissalTransitionWillBegin() {
        animateBackgroundAlpha(fromValue: 1.0, toValue: 0.0)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let presentedView = presentedView else {
            return CGRect.zero
        }

        guard let containerView = containerView else {
            return CGRect.zero
        }

        let layoutFrame = containerView.safeAreaLayoutGuide.layoutFrame

        return CGRect(x: layoutFrame.minX,
                      y: layoutFrame.maxY - presentedView.frame.size.height,
                      width: presentedView.frame.size.width,
                      height: presentedView.frame.size.height)
    }

    // MARK: Animation

    func animateBackgroundAlpha(fromValue: CGFloat, toValue: CGFloat) {
        backgroundView?.alpha = fromValue

        let animationBlock: (UIViewControllerTransitionCoordinatorContext) -> Void = { _ in
            self.backgroundView?.alpha = toValue
        }

        presentingViewController.transitionCoordinator?
            .animate(alongsideTransition: animationBlock, completion: nil)
    }

    // MARK: Action

    @objc func actionDidCancel(gesture: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}

extension ActionPresentationController: ModalInputViewPresenterProtocol {
    func hide(view: ModalInputViewProtocol, animated: Bool) {
        keyboardHandler?.animateOnFrameChange = nil
        presentedView?.resignFirstResponder()

        presentingViewController.dismiss(animated: animated, completion: nil)
    }
}
