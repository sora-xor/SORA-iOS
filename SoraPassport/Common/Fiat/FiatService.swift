import Foundation
import RobinHood
import XNetworking

protocol FiatServiceObserverProtocol: AnyObject {
    func processFiat(data: [FiatData])
}

protocol FiatServiceProtocol: AnyObject {
    func getFiat(completion: @escaping ([FiatData]) -> Void)
    func add(observer: FiatServiceObserverProtocol)
    func remove(observer: FiatServiceObserverProtocol)
}

struct FiatServiceObserver {
    weak var observer: FiatServiceObserverProtocol?
}

final class FiatService {
    static let shared = FiatService()
    private let operationManager: OperationManager = OperationManager()
    private var expiredDate: Date = Date()
    private var fiatData: [FiatData] = []
    private var observers: [FiatServiceObserver] = []
    private let syncQueue = DispatchQueue(label: "co.jp.soramitsu.sora.fiat.service")

    private func updateFiatData(completion: (([FiatData]) -> Void)? = nil) {
        let queryOperation = SubqueryFiatInfoOperation<[FiatData]>(baseUrl: ConfigService.shared.config.subqueryURL)
        
        queryOperation.completionBlock = { [weak self] in
            guard let self = self, let response = try? queryOperation.extractNoCancellableResultData() else {
                completion?([])
                return
            }
            self.fiatData = response
            self.expiredDate = Date().addingTimeInterval(120)
            self.notify()
            completion?(response)
        }
        
        operationManager.enqueue(operations: [queryOperation], in: .transient)
    }
}

extension FiatService: FiatServiceProtocol {
    
    func getFiat(completion: @escaping ([FiatData]) -> Void) {
        if fiatData.isEmpty {
            updateFiatData(completion: completion)
            return
        }
        
        if expiredDate < Date() {
            updateFiatData()
        }
        
        completion(fiatData)
    }
    
    func add(observer: FiatServiceObserverProtocol) {
        syncQueue.async {
            self.observers = self.observers.filter { $0.observer != nil }

            if !self.observers.contains(where: { $0.observer === observer }) {
                self.observers.append(FiatServiceObserver(observer: observer))
            }
        }
    }

    func remove(observer: FiatServiceObserverProtocol) {
        syncQueue.async {
            self.observers = self.observers.filter { $0.observer != nil && $0.observer !== observer }
        }
    }
    
    func notify() {
        syncQueue.async {
            self.observers = self.observers.filter { $0.observer != nil }

            for wrapper in self.observers {
                guard let observer = wrapper.observer else {
                    continue
                }

                observer.processFiat(data: self.fiatData)
            }
        }
    }
}