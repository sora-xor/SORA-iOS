import UIKit

protocol OutboundUrlPresentable {
    @discardableResult
    func open(url: URL) -> Bool
}

extension OutboundUrlPresentable {
    func open(url: URL) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)

            return true
        } else {
            return false
        }
    }
}
