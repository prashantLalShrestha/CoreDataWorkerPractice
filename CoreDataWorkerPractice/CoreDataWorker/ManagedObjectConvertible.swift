//
//  ManagedObjectConvertible.swift
//  Pay2Nepal
//
//  Created by Inficare Pvt. Ltd. on 02/07/2018.
//  Copyright © 2018 Inficare. All rights reserved.
//

import CoreData

protocol ManagedObjectConvertible {
    associatedtype ManagedObject: NSManagedObject, ManagedObjectProtocol
    func toManagedObject(in context: NSManagedObjectContext) -> ManagedObject?
}
