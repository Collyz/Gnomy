//
//  GameViewModel.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/20/25.
//

import CoreData

struct User: Identifiable {
    let id = UUID()
    var name: String
    var score: Int64
}


// Just for previews (remove for publish launch)
extension NSManagedObjectContext {
    static var preview: NSManagedObjectContext {
        let container = NSPersistentContainer(name: "PlayerData")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null") // Use in-memory store
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load preview Core Data store: \(error)")
            }
        }
        return container.viewContext
    }
}

@MainActor class GameViewModel: ObservableObject {
    private var playerInfoStack = PlayerInfoStack.shared
    @Published var username: String = ""
    @Published var highscore: Int64 = 0
    @Published var globalHighScore: Int64 = 0
    @Published var usernameError: String = ""
    @Published var leaderboard: [User] = []
    
    
    init() { }
    
    public func fetchUsername() {
        username = playerInfoStack.fetchPlayerInfo().username ?? ""
    }
    
    public func fetchHighScore() {
        highscore = playerInfoStack.fetchPlayerInfo().score
    }
    
    public func saveUsername(_ username: String) -> Bool{
        var isValid = username.trimmingCharacters(in: .whitespacesAndNewlines).count > 4
        if isValid {
            isValid = playerInfoStack.saveUsername(username)
        }
        if !isValid {
            usernameError = "Username must be longer than 4 characters and cannot contain spaces"
        }
        return isValid
    }
    
    public func fetchGlobalHighScore() async {
        
    }
}
