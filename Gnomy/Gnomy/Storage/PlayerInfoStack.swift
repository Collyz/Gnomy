
//
//  PlayerInfoStack.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 6/21/25.
//
import CoreData
// Define an observable class to encapsulate all Core Data-related functionality.
class PlayerInfoStack: ObservableObject {
    static let shared = PlayerInfoStack()
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "DataModel")
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to uses
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    // Returns the current players information, if it doesn't exist default values are createds
    public func fetchPlayerInfo() -> PlayerInfo {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<PlayerInfo> = PlayerInfo.fetchRequest()
        
        do {
            if let existingPlayer = try context.fetch(request).first {
                return existingPlayer
            } else {
                let newPlayer = PlayerInfo(context: context)
                newPlayer.username = "Guest"
                newPlayer.score = 0
                try context.save()
                return newPlayer
            }
        } catch {
            fatalError("Failed to fetch or create PlayerInfo: \(error)")
        }
    }
    
    // Saves a new input username
    public func saveUsername(_ newUsername: String) {
        guard !newUsername.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<PlayerInfo> = PlayerInfo.fetchRequest()
        
        do {
            if let existingPlayer = try context.fetch(request).first {
                existingPlayer.username = newUsername
            } else {
                let newPlayer = PlayerInfo(context: context)
                newPlayer.username = newUsername
                newPlayer.score = 0
            }

            try context.save()
            
        } catch {
            print("Failed to save player username: \(error)")
        }
    }

    
    public func save() {
        guard persistentContainer.viewContext.hasChanges else { return }
        
        do {
            // Attempt changes
            try persistentContainer.viewContext.save()
        } catch {
            // Handle the error
            print("Failed to save the context: \(error.localizedDescription)")
        }
    }
    
        
    private init() { }
    
    
}
