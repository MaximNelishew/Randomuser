import UIKit
import CoreData
import EGOCache

final class StorageManager: DatabaseWorker, Coredata {

    public static var shared = StorageManager()
    fileprivate(set) public var appDelegate: AppDelegate!
    fileprivate(set) public var viewContext: NSManagedObjectContext!

    let quene = DispatchQueue(label: "com.StorageManager.setdb")
    let group = DispatchGroup()
    
    public let cache: EGOCache = EGOCache.global()
    internal(set) public var database: Database?
    
    func setdb(_ results: [Results], _ info: Info) {
        group.enter()
        quene.async(group: group, execute: { [self] in
            switch database {
            case nil:
                database = Database(results: results, info: info)
                do { group.leave() }
            default:
                database?.results.append(contentsOf: results)
                do { group.leave() }
            }
        })
        group.notify(queue: .main, execute: {
            defer { updaterGroup.leave() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [self] in
                guard let jsonData = try? database?.jsonData() else { return }
                let timestamp = String(Int(Date().timeIntervalSince1970))
                saveObject(appDelegate, JsondataEntity.self, viewContext, keyJsonData, jsonData)
                cache.setData(jsonData, forKey: keyJsonData + timestamp, withTimeoutInterval: 2592000) // 2592000 sec == 1 month
            })
        })
    }
    
    func getdb(_ completion: @escaping InfRes) {
        guard let db: Database = database else { return }
        completion(db.results, db.info)
    }
    
    func statusdb(_ status: Status, state: @escaping State) {
        guard let db = StorageManager().database else { return }
        switch status {
            case .count:
                state(db.results.count)
            break
                // default: break
        }
    }
    
    private init() {
        DispatchQueue.main.async {
            guard let delegate: AppDelegate = (UIApplication.shared.delegate as? AppDelegate), let context = try? delegate.persistentContainer.viewContext else { fatalError("ERROR") }
            self.appDelegate = delegate
            self.viewContext = context
        }
    }
}