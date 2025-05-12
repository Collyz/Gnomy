//
//  GameViewModel.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/20/25.
//

import SwiftUI
import Combine
import CoreData
import AWSS3
import ClientRuntime
import SwiftyJSON

struct User: Identifiable {
    let id = UUID()
    var name: String
    var score: Int64
}


// Just for previews (remove for publish launch)
extension NSManagedObjectContext {
    static var preview: NSManagedObjectContext {
        let container = NSPersistentContainer(name: "HighScore")
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
    @Published var username: String = ""
    @Published var highscore: Int64 = 0
    @Published var globalHighScore: Int64 = 0
    @Published var usernameError: String = ""
    @Published var leaderboard: [User] = []
    
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        // Set context for coredata
        self.context = context
        // Get the username stored
        self.getUsername()
        // Get the high score stored
        self.getHighScore()
        // Get the leaderboard
        Task {
            await getLeaderboard()
            await updateUsername(oldUsername: "NewTestUseradfasdfasfd", newUsername: "TestUser")
        }
    }
    
    // Gets the device highscore
    func getHighScore() {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let data = try context.fetch(fetchRequest)
            if let score = data.first {
                self.highscore = score.highscore
            } else {
                let newScore = Score(context: context)
                newScore.highscore = 0
                self.highscore = newScore.highscore
                try context.save()
            }
        } catch {
            print("Failed to fetch device high score: \(error)")
        }
    }
    
    func updateHighScore(newScore: Int64) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let data = try context.fetch(fetchRequest)
            if let userData = data.first {
                if newScore > userData.highscore {
                    userData.highscore = newScore
                    self.highscore = userData.highscore
                    try context.save()
                }
                Task {
                    await updateScore()
                }
            }
        } catch {
            print("Failed to update device high score: \(error)")
        }
    }
    
    func getUsername() {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let data = try context.fetch(fetchRequest)
            if let userData = data.first {
                print("got username: \(userData.username)")
                self.username = userData.username
            } else {
                print("username doesn't exist, making default 'Guest'")
                let updatedData = Score(context: context)
                updatedData.username = "Guest"
                self.username = updatedData.username
                try context.save()
            }
        } catch {
            print("Failed to fetch username: \(error)")
        }
    }
    
    func setUsername(newUsername: String) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let data = try context.fetch(fetchRequest)
            if let userData = data.first {
                print("attempting to add username starting point")
                if leaderboard.count > 0 {
                    var editIndex = 0
                    for i in 0...leaderboard.count - 1 {
                        if leaderboard[i].name == self.username {
                            editIndex = i
                            break
                        }
                    }
                    if leaderboard[editIndex].name == self.username	&& leaderboard[editIndex].name == userData.username{
                        Task {
                            await updateUsername(oldUsername: self.username, newUsername: newUsername)
                        }
                        userData.username = newUsername
                        self.username = newUsername
                        leaderboard[editIndex].name = newUsername
                        try context.save()
                        Task {
                            await getLeaderboard()
                        }
                    } else {
                        print("Updating username, not found in self and leaderboard")
                        userData.username = newUsername
                        self.username = newUsername
                        try context.save()
                        
                        // Appending the new username and highscore to the leaderboard and then calling the s3 leaderboard update func
                        leaderboard.append(User(name: newUsername, score: self.highscore))
                        Task {
                            await insertNewPlayer()
                            await getLeaderboard()
                        }
                    }
                } else {
                    print("Please connect to the internet to connect to the server")
                }
            } else {
                print("username doesn't exist .~.")
            }
        } catch {
            print("Failed to update username: \(error)")
        }
    }
    
    // Test the s3 connection
    func TestS3Connection() async {
        do {
            let serviceHandler = try await ServiceHandler() // Initialize the service handler
            let bucketName = "gnomyleaderboardbucket"
            
            // Check if we can list the files in the bucket
            let files = try await serviceHandler.listBucketFiles(bucket: bucketName)
            
            print("Successfully connected to S3 bucket '\(bucketName)'. Found files: \(files)")
        } catch {
            print("Failed to connect to S3 bucket: \(error)")
        }
    }
    
    func getLeaderboard() async {
        do {
            let serviceHandler = try await ServiceHandler()
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"
            
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
            
            if String(data: fileData, encoding: .utf8) != nil {
                let json = try JSON(data: fileData)
                var tempPlayers: [User] = []
                if let playersArray = json["players"].array {
                    for player in playersArray {
                        if let name = player["name"].string, let highscore = player["highscore"].int64 {
                            tempPlayers.append(User(name: name, score: highscore))
                        }
                    }
                } else {
                    print("No players found in the JSON.")
                }
                // Sorting the players
                self.leaderboard = tempPlayers.sorted { $0.score > $1.score }
                if leaderboard.count > 0 {
                    globalHighScore = leaderboard[0].score
                    print("set the global player high score \n")
                }
            } else {
                print("Failed to convert data to string")
            }
            
        } catch {
            print("Failed to fetch leaderboard data from S3: \(error)")
        }
    }
    
    func insertNewPlayer() async {
        if leaderboard.count > 0 {
            do {
                let serviceHandler = try await ServiceHandler()
                let bucketName = "gnomyleaderboardbucket"
                let fileName = "data.json"
                
                let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
                
                if String(data: fileData, encoding: .utf8) != nil {
                    var json = try JSON(data: fileData)
                    // Adding the last value in the leaderboard array
                    if var players = json["players"].array {
                        players.append(["name": leaderboard[leaderboard.count - 1].name, "highscore": leaderboard[leaderboard.count - 1].score])
                        json["players"] = JSON(players) // Set the updated players array
                    }
                    // Step 4: Convert the updated JSON back to Data
                    let updatedData = try json.rawData()
                    // Step 5: Upload the updated file to S3
                    try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
//                    print("File updated successfully.")
                }
                
            } catch {
                print("Failed to fetch leaderboard data from S3: \(error)")
            }
        }
    }
    
    func updateUsername(oldUsername: String, newUsername: String) async {
        if leaderboard.count > 0 {
            do {
                let serviceHandler = try await ServiceHandler()
                let bucketName = "gnomyleaderboardbucket"
                let fileName = "data.json"
                
                let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
                
                if String(data: fileData, encoding: .utf8) != nil {
                    var json = try JSON(data: fileData)
                    // updating just the username
                    if var players = json["players"].array {
                        for i in 0..<players.count {
                            if players[i]["name"].string == oldUsername {
                                players[i]["name"] = JSON(newUsername)
                                break
                            }
                        }
                        
                        json["players"] = JSON(players) // Set the updated players array
                    }
                    // Step 4: Convert the updated JSON back to Data
                    let updatedData = try json.rawData()
                
                    // Step 5: Upload the updated file to S3
                    try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
//                    print("File updated successfully.")
                }
                
                
            } catch {
                print("Failed to fetch leaderboard data from S3: \(error)")
            }
        }
    }
    
    func updateScore() async {
        self.getHighScore()
        if leaderboard.count > 0 {
            do {
                let serviceHandler = try await ServiceHandler()
                let bucketName = "gnomyleaderboardbucket"
                let fileName = "data.json"
                
                let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
                
                if String(data: fileData, encoding: .utf8) != nil {
                    var json = try JSON(data: fileData)
                    // updating just the username
                    if var players = json["players"].array {
                        for i in 0..<players.count {
                            if players[i]["name"].string == self.username {
                                players[i]["highscore"] = JSON(self.highscore)
                                break
                            }
                        }
                        
                        json["players"] = JSON(players) // Set the updated players array
                    }
                    // Step 4: Convert the updated JSON back to Data
                    let updatedData = try json.rawData()
                
                    // Step 5: Upload the updated file to S3
                    try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
//                    print("File updated successfully.")
                }
                
            } catch {
                print("Failed to fetch leaderboard data from S3: \(error)")
            }
            Task {
                await getLeaderboard()
            }
        }
    }
    
//
//    // Fetch player data from S3 and store it
//    func FetchDataFromS3() async {
//        do {
//            let serviceHandler = try await ServiceHandler()
//            let bucketName = "gnomyleaderboardbucket"
//            let fileName = "data.json"
//
//            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
//
//            if String(data: fileData, encoding: .utf8) != nil {
////                print("Received JSON: \(jsonString)")
////                print("\n")
//
//                let json = try JSON(data: fileData)
//                var tempPlayers: [User] = []
//
//                if let playersArray = json["players"].array {
//                    for player in playersArray {
//                        if let name = player["name"].string, let highscore = player["highscore"].int64 {
//                            tempPlayers.append(User(name: name, score: highscore))
//                        }
//                    }
//                } else {
//                    print("No players found in the JSON.")
//                }
//                // Sorting and storing the player information
//                self.players = tempPlayers.sorted { $0.score > $1.score }
//                print(players)
//                print("\n")
//                if players.count > 0 {
//                    globalHighScore = players[0].score
//                    print("set the gloabl player high score \n")
//                }
//            } else {
//                print("Failed to convert data to string.")
//            }
//        } catch {
//            print("Failed to fetch data from S3: \(error)")
//        }
//    }
//    
//    func UpdateS3() async {
//        do {
//            let serviceHandler = try await ServiceHandler() // Initialize the service handler
//            let bucketName = "gnomyleaderboardbucket"
//            let fileName = "data.json"
//
//            // Step 1: Read the current file from S3
//            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
////            print("read data: \(fileData)")
//            // Step 2: Parse the existing JSON
//            var json = try JSON(data: fileData)
//            
//            // Step 3: Update the data (e.g., add or update a player's highscore)
//            var updated = false
//            if var players = json["players"].array {
//                for i in 0..<players.count {
//                    if players[i]["name"].string == UIDevice.current.name {
//                        if players[i]["highscore"].int64Value < highScore {
//                            players[i]["highscore"] = JSON(highScore) // Update the players highscore
//                        }
//                        updated = true
//                        break
//                    }
//                }
//                // If phone_name wasn't found, add it
//                if !updated {
//                    players.append(["name": UIDevice.current.name, "highscore": highScore])
//                }
//                json["players"] = JSON(players) // Set the updated players array
//            }
//            // Step 4: Convert the updated JSON back to Data
//            let updatedData = try json.rawData()
//            // Step 5: Upload the updated file to S3
//            try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
//            print("File updated successfully.")
//        } catch {
//            print("Error updating file: \(error)")
//        }
//        await FetchDataFromS3()
//    }
//    
//    func updateS3Username(newUsername: String) async -> Bool{
//        var result: Bool = false
//        do {
//            let serviceHandler = try await ServiceHandler() // Initializing the service handler
//            let bucketName = "gnomyleaderboardbucket"
//            let fileName = "data.json"
//            // Reading the file first
//            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
//            // Parse into a json object
//            var jsonData = try JSON(data: fileData)
//            var usernameExists: Bool = false
//            // Loop through the data read from s3 and if the username exists, replace it with the new username
//            if var playerData = jsonData["players"].array {
//                for i in 0..<playerData.count {
//                    if playerData[i]["name"].string == username {
//                        usernameExists = true
//                        playerData[i]["name"] = JSON(newUsername)
//                    }
//                }
//                // After checking if the username exists, if it doesn't, add it
//                if !usernameExists {
//                    print("the username doesn't exist, adding username")
//                    playerData.append(["name": newUsername, "highscore": highScore])
//                }
//                jsonData["players"] = JSON(playerData) // Set the updated players data
//            }
//            // Converted the JSON back to data for s3
//            let updatedData = try jsonData.rawData()
//            // Uploading the updated file to s3
//            try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
//            print("Username updated successfully.")
//            result = true
//            return result
//        } catch {
//            print("Error updating username: \(error)")
//        }
//        return result
//    }
//    
}
