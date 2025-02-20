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

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Score> {
        return NSFetchRequest<Score>(entityName: "Score")
    }

    @NSManaged public var localHighscore: NSNumber?
    @NSManaged public var globalHighscore: Int64

}

extension Score : Identifiable {

}
