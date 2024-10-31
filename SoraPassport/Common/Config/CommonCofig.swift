//
//  CommonCofig.swift
//  SoraPassport
//
//  Created by Ivan Shlyapkin on 10/27/24.
//  Copyright © 2024 Soramitsu. All rights reserved.
//

import Foundation

struct Nodes: Decodable {
    let name: String
    let address: String
}

struct CommonCofig: Decodable {
    let SUBQUERY_ENDPOINT: String
    let DEFAULT_NETWORKS: [Nodes]
}


struct MobileCofig: Decodable {
    let soracard: Bool
    let substrate_types_ios: String
}
