//
//  Score+CoreDataProperties.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/19/25.
//
//

import Foundation
import CoreData


extension Score {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Score> {
        return NSFetchRequest<Score>(entityName: "Score")
    }

    @NSManaged public var highscore: Int64

}

extension Score : Identifiable {

}
