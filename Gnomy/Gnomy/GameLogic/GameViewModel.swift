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
    
    public func fetchUsername() -> Bool{
        username = playerInfoStack.fetchPlayerInfo().username ?? ""
        return username != ""
    }
    
    public func fetchHighScore() {
        highscore = playerInfoStack.fetchPlayerInfo().score
    }
    
    public func fetchGlobalHighScore() async {
        
    }
    
    public func saveUsername(_ username: String) -> Bool{
        var isValid = username.trimmingCharacters(in: .whitespacesAndNewlines).count > 4
        if isValid {
            isValid = playerInfoStack.saveUsername(username)
            self.username = username
            usernameError = ""
        } else if !isValid {
            usernameError = "Username must be longer than 4 characters and cannot contain spaces"
        }
        
        return isValid
    }
    
    public func saveHighScore(_ score: Int64) -> Bool {
        let result = playerInfoStack.saveScore(score)
        if result {
            self.highscore = score
        }
        return result
    }
    
    public func testDBStuff() {
        var databaseManager: DynamoDBManager!
        print("Running!")
        Task {
            print("init being called")
            databaseManager = try await DynamoDBManager(region: "us-east-1")
            print("after init")
        }
    }
    

}
