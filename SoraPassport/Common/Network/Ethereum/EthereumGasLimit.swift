import Foundation

struct EthereumGasLimit {
    let mint: UInt
    let transfer: UInt
}

extension EthereumGasLimit {
    static var estimated: EthereumGasLimit {
        EthereumGasLimit(mint: 350000, transfer: 100000)
    }
}
