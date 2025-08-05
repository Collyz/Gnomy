
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
        let container = NSPersistentContainer(name: "PlayerData")
        
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
                newPlayer.username = ""
                newPlayer.score = 0
                try context.save()
                return newPlayer
            }
        } catch {
            fatalError("Failed to fetch or create PlayerInfo: \(error)")
        }
    }
    
    // Save the generated playerID
    public func setPlayerID() {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<PlayerInfo> = PlayerInfo.fetchRequest()
        do {
            // Check if the core data is empty
            if try context.fetch(request).isEmpty {
                // No PlayerInfo exists — create and save a new one
                let newPlayerInfo = PlayerInfo(context: context)
                newPlayerInfo.playerID = UUID().uuidString
                try context.save()
            } else {
                // Core data is not empty check for playerID
                if let existingPlayerInfo = try context.fetch(request).first {
                    if ((existingPlayerInfo.playerID) == nil) { // playerID is empty, generate a new one
                        existingPlayerInfo.playerID = UUID().uuidString
                        try context.save()
                    }
                }
                
            }
        } catch {
            print("Failed to fetch or create player ID: \(error)")
        }
    }
    
    // Saves a new input username
    public func saveUsername(_ newUsername: String) -> Bool{
        guard !newUsername.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
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
        return true
    }
    
    public func saveScore(_ newScore: Int64) -> Bool {
        guard newScore >= 0 else { return false }
        
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<PlayerInfo> = PlayerInfo.fetchRequest()
        
        do {
            if let existingPlayer = try context.fetch(request).first {
                if existingPlayer.score < newScore {
                    existingPlayer.score = newScore
                    try context.save()
                    return true
                } else {
                    try context.save()
                    return false
                }
            } else {
                let newPlayer = PlayerInfo(context: context)
                newPlayer.username = ""
                newPlayer.score = newScore
            }
            
            try context.save()
            
        } catch {
            print("Failed to save player score: \(error)")
        }
        return true
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
