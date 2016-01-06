//
//  Country.swift
//  VCountries
//
//  Created by Eugene Chechkov on 6/5/15.
//  Copyright (c) 2015 Chechkov Eugene. All rights reserved.
//

import Foundation
import CoreData

@objc(Country)

class Country: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var defaultName: String
    @NSManaged var code: String
    @NSManaged var visited: NSNumber
    @NSManaged var planned: NSNumber
    
    var isVisited: Bool {
        get {
            return Bool(visited)
        }
        set {
            visited = NSNumber(bool: newValue)
            var error: NSError?
            do {
                try self.managedObjectContext!.save()
            } catch let error1 as NSError {
                error = error1
                print("Could not save \(error), \(error?.userInfo)")
            }
        }
    }
    
    var isPlanned: Bool {
        get {
            return Bool(planned)
        }
        set {
            planned = NSNumber(bool: newValue)
            var error: NSError?
            do {
                try self.managedObjectContext!.save()
            } catch let error1 as NSError {
                error = error1
                print("Could not save \(error), \(error?.userInfo)")
            }
        }
    }
}
