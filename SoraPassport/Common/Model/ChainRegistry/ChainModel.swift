import Foundation
import RobinHood
import CommonWallet

class ChainModel: Codable {
    // swiftlint:disable:next type_name
    typealias Id = String

    struct TypesSettings: Codable, Hashable {
        let url: URL
        let overridesCommon: Bool
    }

    struct ExternalApi: Codable, Hashable {
        let type: String
        let url: URL
    }

    struct ExternalApiSet: Codable, Hashable {
        let staking: ExternalApi?
        let history: ExternalApi?
        let crowdloans: ExternalApi?
    }

    enum TypesUsage {
        case onlyCommon
        case both
        case onlyOwn
    }

    let chainId: Id
    let parentId: Id?
    let name: String
    var assets: Set<ChainAssetModel>
    let nodes: Set<ChainNodeModel>
    let addressPrefix: UInt16
    let types: TypesSettings?
    let icon: URL?
    let options: [ChainOptions]?
    let externalApi: ExternalApiSet?
    let selectedNode: ChainNodeModel?
    let customNodes: Set<ChainNodeModel>?
    let iosMinAppVersion: String?

    init(
        chainId: Id,
        parentId: Id? = nil,
        name: String,
        assets: Set<ChainAssetModel> = [],
        nodes: Set<ChainNodeModel>,
        addressPrefix: UInt16,
        types: TypesSettings? = nil,
        icon: URL?,
        options: [ChainOptions]? = nil,
        externalApi: ExternalApiSet? = nil,
        selectedNode: ChainNodeModel? = nil,
        customNodes: Set<ChainNodeModel>? = nil,
        iosMinAppVersion: String?
    ) {
        self.chainId = chainId
        self.parentId = parentId
        self.name = name
        self.assets = assets
        self.nodes = nodes
        self.addressPrefix = addressPrefix
        self.types = types
        self.icon = icon
        self.options = options
        self.externalApi = externalApi
        self.selectedNode = selectedNode
        self.customNodes = customNodes
        self.iosMinAppVersion = iosMinAppVersion
    }

    var isEthereumBased: Bool {
        options?.contains(.ethereumBased) ?? false
    }

    var isTestnet: Bool {
        options?.contains(.testnet) ?? false
    }

    var isTipRequired: Bool {
        options?.contains(.tipRequired) ?? false
    }

    var isPolkadotOrKusama: Bool {
        name.lowercased() == "polkadot" || name.lowercased() == "kusama"
    }

    var isWestend: Bool {
        name.lowercased() == "westend"
    }

    var hasStakingRewardHistory: Bool {
        isPolkadotOrKusama || isWestend
    }

    var hasCrowdloans: Bool {
        options?.contains(.crowdloans) ?? false
    }

    var isSupported: Bool {
        true
//        AppVersion.stringValue?.versionLowerThan(iosMinAppVersion) == false
    }

    func utilityAssets() -> Set<ChainAssetModel> {
        assets.filter { $0.isUtility }
    }

    var typesUsage: TypesUsage {
        if let types = types {
            return types.overridesCommon ? .onlyOwn : .both
        } else {
            return .onlyCommon
        }
    }

    var erasPerDay: UInt32 {
        let oldChainModel = Chain(rawValue: name)
        switch oldChainModel {
        case .polkadot: return 1
//        case .kusama, .westend, .rococo: return 4
        default: return 1 // We have staking only for above chains
        }
    }

    var emptyURL: URL {
        URL(string: "")!
    }

    var chainAssets: [ChainAsset] {
        assets.map {
            ChainAsset(chain: self, asset: $0.asset)
        }
    }

    func utilityChainAssets() -> [ChainAsset] {
        assets.filter { $0.isUtility }.map {
            ChainAsset(chain: self, asset: $0.asset)
        }
    }

    func replacingSelectedNode(_ node: ChainNodeModel?) -> ChainModel {
        ChainModel(
            chainId: chainId,
            parentId: parentId,
            name: name,
            assets: assets,
            nodes: nodes,
            addressPrefix: addressPrefix,
            types: types,
            icon: icon,
            options: options,
            externalApi: externalApi,
            selectedNode: node,
            customNodes: customNodes,
            iosMinAppVersion: iosMinAppVersion
        )
    }

    func replacingCustomNodes(_ newCustomNodes: [ChainNodeModel]) -> ChainModel {
        ChainModel(
            chainId: chainId,
            parentId: parentId,
            name: name,
            assets: assets,
            nodes: nodes,
            addressPrefix: addressPrefix,
            types: types,
            icon: icon,
            options: options,
            externalApi: externalApi,
            selectedNode: selectedNode,
            customNodes: Set(newCustomNodes),
            iosMinAppVersion: iosMinAppVersion
        )
    }
}

extension ChainModel: Hashable {
    static func == (lhs: ChainModel, rhs: ChainModel) -> Bool {
        lhs.chainId == rhs.chainId
            && lhs.externalApi == rhs.externalApi
            && lhs.assets == rhs.assets
            && lhs.options == rhs.options
            && lhs.types == rhs.types
            && lhs.icon == rhs.icon
            && lhs.name == rhs.name
            && lhs.addressPrefix == rhs.addressPrefix
            && lhs.selectedNode == rhs.selectedNode
            && lhs.nodes == rhs.nodes
            && lhs.iosMinAppVersion == rhs.iosMinAppVersion
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(chainId)
    }
}

extension ChainModel: Identifiable {
    var identifier: String { chainId }
}

enum ChainOptions: String, Codable {
    case ethereumBased
    case testnet
    case crowdloans
    case orml
    case tipRequired

    case unsupported

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let options = ChainOptions(rawValue: rawValue) {
            self = options
        } else {
            self = .unsupported
        }
    }
}

extension ChainModel {
    func polkascanAddressURL(_ address: String) -> URL? {
        URL(string: "https://polkascan.io/\(name)/account/\(address)")
    }

    func subscanAddressURL(_ address: String) -> URL? {
        URL(string: "https://\(name).subscan.io/account/\(address)")
    }

    func subscanExtrinsicUrl(_ extrinsicHash: String) -> URL? {
        URL(string: "https://\(name).subscan.io/extrinsic/\(extrinsicHash)")
    }
}
