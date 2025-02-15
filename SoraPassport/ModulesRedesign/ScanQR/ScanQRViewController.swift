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
import SoraUIKit
import SoraUI
import AVFoundation

protocol ScanQRViewProtocol: ControllerBackedProtocol, AdaptiveDesignable, ApplicationSettingsPresentable, AlertPresentable {
    func didReceive(session: AVCaptureSession)
    func presentAlert(title: String)
}

final class ScanQRViewController: SoramitsuViewController {

    private var qrFrameView: CameraFrameView = {
        let view: CameraFrameView = CameraFrameView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillColor = R.color.brandPMSBlack()!.withAlphaComponent(0.8)
        return view
    }()

    lazy var closeButton: ImageButton = {
        let view = ImageButton(size: CGSize(width: 24, height: 24))
        view.sora.tintColor = .fgSecondary
        view.sora.image = R.image.wallet.cross()
        view.sora.tintColor = .bgSurface
        view.sora.addHandler(for: .touchUpInside) { [weak self] in
            self?.close()
        }
        return view
    }()

    private let titleLabel: SoramitsuLabel = {
        var label = SoramitsuLabel()
        label.sora.textColor = .bgSurface
        label.sora.font = FontType.headline3
        label.sora.text = R.string.localizable.commonScanQr(preferredLanguages: .currentLocale)
        label.sora.alignment = .center
        return label
    }()

    private let scanLabel: SoramitsuLabel = {
        var label = SoramitsuLabel()
        label.sora.textColor = .bgSurface
        label.sora.font = FontType.textBoldL
        label.sora.text = R.string.localizable.scanQrFromReceiver(preferredLanguages: .currentLocale)
        label.sora.numberOfLines = 0
        label.sora.alignment = .center
        return label
    }()

    private lazy var galleryButton: SoramitsuButton = {
        let button = SoramitsuButton()
        button.sora.title = R.string.localizable.commonUploadFromLibrary(preferredLanguages: .currentLocale)
        button.sora.cornerRadius = .circle
        button.sora.backgroundColor = .accentPrimary
        button.sora.addHandler(for: .touchUpInside) { [weak self] in
            self?.viewModel.activateImport()
        }
        return button
    }()

    var viewModel: ScanQRViewModelProtocol

    init(viewModel: ScanQRViewModelProtocol) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
        adjustLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.prepareDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.prepareAppearance()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.handleDismiss()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.handleAppearance()
    }

    private func setupView() {
        soramitsuView.sora.backgroundColor = .custom(uiColor: .black)
        view.addSubview(qrFrameView)
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(scanLabel)
        view.addSubview(galleryButton)
    }

    private func setupConstraints() {
        let scanLabelBottomOffset = (UIScreen.main.bounds.maxY * 0.47) - ((UIScreen.main.bounds.width - 24 * 2) / 2) + (UIScreen.main.bounds.width - 24 * 2) + 32
        NSLayoutConstraint.activate([
            qrFrameView.topAnchor.constraint(equalTo: view.topAnchor),
            qrFrameView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qrFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 11),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            
            scanLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: scanLabelBottomOffset),
            
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            galleryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            galleryButton.heightAnchor.constraint(equalToConstant: 56),
            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }
    
    private func adjustLayout() {
        let width = UIScreen.main.bounds.width - 24 * 2
        qrFrameView.windowSize = CGSize(width: width, height: width)
        qrFrameView.windowPosition = CGPoint(x: 0.5, y: 0.47)
    }
    
    private func configureVideoLayer(with captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds

        qrFrameView.frameLayer = videoPreviewLayer
    }
}

extension ScanQRViewController: ScanQRViewProtocol {
    func didReceive(session: AVCaptureSession) {
        configureVideoLayer(with: session)
    }
    
    func presentAlert(title: String) {
        present(message: nil,
                title: title,
                closeAction: R.string.localizable.commonOk(preferredLanguages: .currentLocale),
                from: self)
    }
}
