//
//  ScoreDataStack.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/19/25.
//
// Define an observable class to encapsulate all Core Data-related functionality.

import Foundation
import CoreData
class ScoreDataStack: ObservableObject {
    static let shared = ScoreDataStack()
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "HighScore")
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
        
    private init() { }
}
