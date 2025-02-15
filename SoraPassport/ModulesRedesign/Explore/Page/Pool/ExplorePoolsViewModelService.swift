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
import Combine
import BigInt

final class ExplorePoolsViewModelService {
    var apyService: APYServiceProtocol
    let itemFactory: ExploreItemFactory
    var poolsService: ExplorePoolsServiceInputProtocol
    
    @Published var viewModels: [ExplorePoolViewModel] = {
        let serialNumbers = Array(1...20)
        let shimmersAssetItems = serialNumbers.map {
            ExplorePoolViewModel(serialNumber: String($0))
        }
        return shimmersAssetItems
    }()
    
    init(
        itemFactory: ExploreItemFactory,
        poolsService: ExplorePoolsServiceInputProtocol,
        apyService: APYServiceProtocol
    ) {
        self.poolsService = poolsService
        self.itemFactory = itemFactory
        self.apyService = apyService
    }
    
    func setup() {
        Task {
            let fiatData = await FiatService.shared.getFiat()
            let pools = (try? await poolsService.getPools(with: fiatData)) ?? []
            
            viewModels = pools.enumerated().compactMap { (index, pool) in
                return itemFactory.createPoolsItem(with: pool, serialNumber: String(index + 1))
            }
            
            async let viewModels = (pools.enumerated().concurrentMap { (index, pool) in
                let apy = await self.apyService.getApy(for: pool.baseAssetId, targetAssetId: pool.targetAssetId)
                return self.itemFactory.createPoolsItem(with: pool, serialNumber: String(index + 1), apy: apy)
            })

            let result = (try? await viewModels) ?? []
            
            if result.isEmpty {
                setup()
            } else {
                self.viewModels = result
            }
        }
    }
}
