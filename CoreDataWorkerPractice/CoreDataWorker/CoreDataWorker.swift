//
//  CoreDataWorker.swift
//  Pay2Nepal
//
//  Created by Inficare Pvt. Ltd. on 02/07/2018.
//  Copyright © 2018 Inficare. All rights reserved.
//

import Foundation

protocol CoreDataWorkerProtocol {
    func get<Entity: ManagedObjectConvertible>
        (with predicate: NSPredicate?,
         sortDescriptors: [NSSortDescriptor]?,
         fetchLimit: Int?,
         completion: @escaping (Result<[Entity]>) -> Void)
    func upsert<Entity: ManagedObjectConvertible>
        (entities: [Entity],
         completion: @escaping (Error?) -> Void)
    
}

extension CoreDataWorkerProtocol {
    func get<Entity: ManagedObjectConvertible>
        (with predicate: NSPredicate? = nil,
         sortDescriptors: [NSSortDescriptor]? = nil,
         fetchLimit: Int? = nil,
         completion: @escaping (Result<[Entity]>) -> Void) {
        get(with: predicate,
            sortDescriptors: sortDescriptors,
            fetchLimit: fetchLimit,
            completion: completion)
    }
}

public enum CoreDataWorkerError: Error{
    case cannotFetch(String)
    case cannotSave(Error)
}

public enum CoreDataResult<Value> {
    case success(Value)
    case failure(CoreDataWorkerError)
}

public typealias CoreDataResultCallback<Value> = (CoreDataResult<Value>) -> Void

class CoreDataWorker: CoreDataWorkerProtocol {
    let coreData: CoreDataServiceProtocol
    
    init(coreData: CoreDataServiceProtocol = CoreDataStack.shared) {
        self.coreData = coreData
    }
    
    func get<Entity: ManagedObjectConvertible> (with predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil, completion: @escaping CoreDataResultCallback<[Entity]>) {
        coreData.performForegroundTask { context in
            do {
                let fetchRequest = Entity.ManagedObject.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.sortDescriptors = sortDescriptors
                if let fetchLimit = fetchLimit {
                    fetchRequest.fetchLimit = fetchLimit
                }
                let results = try context.fetch(fetchRequest) as? [Entity.ManagedObject]
                let items: [Entity] = results?.compactMap { $0.toEntity() as? Entity } ?? []
                completion(.success(items))
            } catch {
                let fetchError = CoreDataWorkerError.cannotFetch("Cannot fetch error: \(error))")
                completion(.failure(fetchError))
            }
        }
    }
    
    func upsert<Entity: ManagedObjectConvertible> (entities: [Entity], completion: @escaping (Error?) -> Void) {
        
        coreData.performBackgroundTask { context in
            let e = entities.compactMap({ (entity) -> Entity.ManagedObject? in
                      // inserts new or update old
                      // needs to delete old too if new doesn't have the old
                return entity.toManagedObject(in: context)
            })
            print(e.count)
            do {
                try context.save()
                completion(nil)
            } catch {
                completion(CoreDataWorkerError.cannotSave(error))
            }
        }
    }
    
    func delete<Entity: ManagedObjectConvertible> (entities: [Entity], completion: @escaping (Error?) -> Void) {
        
        coreData.performBackgroundTask { context in
            let entity = entities.compactMap({ (entity) -> Entity.ManagedObject? in
                return entity.toManagedObject(in: context)
            })
            if let e = entity.first {
                context.delete(e)
            }
            do {
                try context.save()
                completion(nil)
            } catch {
                completion(CoreDataWorkerError.cannotSave(error))
            }
        }
    }
}
