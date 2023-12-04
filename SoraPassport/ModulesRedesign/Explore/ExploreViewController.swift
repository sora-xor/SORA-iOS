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
import SoraFoundation
import Combine

final class ExploreViewController: SoramitsuViewController, ControllerBackedProtocol {
    
    var viewModels: [ExplorePageViewModelProtocol]

    lazy var scrollDelegate: ExploreScrollViewDelegate = {
        let delegate = ExploreScrollViewDelegate()
        delegate.delegate = segmentViewModel
        return delegate
    }()
    
    lazy var segmentViewModel: TitleSegmentControlViewModel = {
        let viewModel = TitleSegmentControlViewModel()
        viewModel.delegate = self
        return viewModel
    }()
    
    private lazy var segmentView: TitleSegmentControl = {
        let view = TitleSegmentControl(frame: .zero)
        view.viewModel = segmentViewModel
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.delegate = scrollDelegate
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        let slides = createSlides()
        setupSlideScrollView(slides: slides)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(3), height: scrollView.frame.size.height)
    }
    
    init(viewModels: [ExplorePageViewModelProtocol]) {
        self.viewModels = viewModels
    }

    private func setupView() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        soramitsuView.sora.backgroundColor = .bgPage
        view.addSubview(scrollView)
        view.addSubview(segmentView)
        
        NSLayoutConstraint.activate([
            segmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentView.heightAnchor.constraint(equalToConstant: 35),
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 16),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    func createSlides() -> [ExplorePageView] {
        let assetsPage = ExplorePageView()
        let poolsPage = ExplorePageView()
        let farmsPage = ExplorePageView()
        return [assetsPage, poolsPage, farmsPage]
    }
    
    func setupSlideScrollView(slides : [ExplorePageView]) {
        scrollView.isPagingEnabled = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        
        scrollView.addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        for i in 0 ..< slides.count {
            slides[i].viewModel = viewModels[i]
            
            stackView.addArrangedSubview(slides[i])
            slides[i].heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
            slides[i].widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        }
    }
}

extension ExploreViewController: Localizable {
    private var languages: [String]? {
        localizationManager?.preferredLocalizations
    }
    
    func applyLocalization() {
        let languages = localizationManager?.preferredLocalizations
        navigationItem.title = R.string.localizable.commonExplore(preferredLanguages: languages)
    }
}

extension ExploreViewController: TitleSegmentControlViewModelDelegate {
    func changeCurrentPage(to number: Int) {
        let pageWidth = scrollView.bounds.width
        let offset = number * Int(pageWidth)
        
        UIView.animate(withDuration: 0.33, animations: { [weak self] in
          self?.scrollView.contentOffset.x = CGFloat(offset)
        })
    }
}