import Foundation
@testable import SoraPassport
import RobinHood
import CoreData

final class UserStoreTestFacade: CoreDataCacheFacadeProtocol {
    let databaseService: CoreDataServiceProtocol

    init() {
        let modelName = "UserStore"
        let bundle = Bundle(for: UserStoreFacade.self)
        let modelURL = bundle.url(forResource: modelName, withExtension: "momd")

        let configuration = CoreDataServiceConfiguration(modelURL: modelURL!,
                                                         storageType: .inMemory)

        databaseService = CoreDataService(configuration: configuration)
    }

    func createCoreDataCache<T, U>(filter: NSPredicate?, mapper: AnyCoreDataMapper<T, U>)
        -> CoreDataRepository<T, U> where T: Identifiable & Codable, U: NSManagedObject {

            return CoreDataRepository(databaseService: databaseService,
                                      mapper: mapper,
                                      filter: filter)
    }
}
