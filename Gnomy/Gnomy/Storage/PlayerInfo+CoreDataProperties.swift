//
//  PlayerInfo+CoreDataProperties.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 6/21/25.
//
//

import Foundation
import CoreData


extension PlayerInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlayerInfo> {
        return NSFetchRequest<PlayerInfo>(entityName: "PlayerInfo")
    }

    @NSManaged public var score: Int64
    @NSManaged public var username: String?

}

extension PlayerInfo : Identifiable {

}
