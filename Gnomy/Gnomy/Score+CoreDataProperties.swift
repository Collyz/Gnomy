//
//  Score+CoreDataProperties.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/20/25.
//
//

import Foundation
import CoreData


extension Score {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Score> {
        return NSFetchRequest<Score>(entityName: "Score")
    }

    @NSManaged public var localHighScore: Int64
    @NSManaged public var globalHighScore: Int64

}

extension Score : Identifiable {

}
