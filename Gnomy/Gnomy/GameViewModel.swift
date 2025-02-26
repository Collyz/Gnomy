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
    let name: String
    let score: Int64
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
    @Published var username: String = "Guest"
    @Published var highScore: Int64 = 0
    @Published var globalHighScore: Int64 = 0
    @Published var usernameError: String = ""
    @Published var players: [User] = []
    
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        // Set context for coredata
        self.context = context
        // Get the username stored
        FetchUsername()
        // Get the high score stored
        FetchHighScore()
        // CHANGING
        Task {
            await FetchDataFromS3()
        }
    }

    // Get the local high score if it exists, otherwise create it and assign a value of zero
    func FetchHighScore() {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let score = scores.first {
                highScore = score.localHighScore
            } else {
                let newScore = Score(context: context)
                newScore.localHighScore = 0
                try context.save()
                highScore = newScore.localHighScore
            }
        } catch {
            print("Failed to fetch local high score: \(error)")
        }
    }

    // Update the local high score with the new value (should be the updated curr score from the game)
    func UpdateHighScore(newScore: Int64) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            let existingHighScore = scores.first
            if newScore > existingHighScore!.localHighScore {
                // Apply the new score if it is bigger than the stored score
                existingHighScore!.localHighScore = newScore
                // Save the changes
                try context.save()
                // Updating the highScore that is shown in the views asynchronously
                DispatchQueue.main.async {
                    self.highScore = existingHighScore!.localHighScore
                    print("local high score: \(self.highScore)")
                }
                // Update the s3 score since your new score is better than the one stored in the cloud
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.5)) {
                    Task {
                        print("UPDATING S3 SCORE")
                        await self.UpdateS3()
                    }
                }
            }
            
        } catch {
            print("Failed to update high score: \(error)")
        }
        
    }
    
    func FetchUsername() {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let request = try context.fetch(fetchRequest)
            if let data = request.first {
                if data.username != "Guest" {
                    // If the username already exists, just grab it
                    print("The username is: \(data.username)")
                    self.username = data.username
                } else {
                    // If the username doesn't exist make it guest and force the user to change it ("Guest" username forces username change)
                    print("setting username to Guest")
                    data.username = "Guest"
                    // Saving the username
                    try context.save()
                    // Setting the username to the default Guest username
                    self.username = data.username
                }
            }
        } catch {
            print("Failed to find username: \(error)")
        }
    }
    
    // Update the username stored locally as well as updating S3 json if the username exists
    func UpdateUsername(newUsername: String) async {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let request = try context.fetch(fetchRequest)
            
            // The username exists, meaning we need to update the S3 JSON
            if !CheckExistingUsername(tryUsername: newUsername) {
                if let data = request.first {
                    // Before we update, update the S3 with the new username
                    let canUpdate = await updateS3Username(newUsername: newUsername)
                    
                    if canUpdate {
                        data.username = newUsername
                        try context.save()
                        self.username = newUsername
                    } else {
                        print("Cannot save the username")
                    }
                }
            }
        } catch {
            print("Error updating username: \(error)")
        }
    }

    
    
    // Used only in the menu view to set the username during the first login
    func SetUsernameFromUser(tryName: String) {
        var isEmptyName = false
        var isDisconnected = false
        var isUniqueName = true
        // Remove newline characters and empty spaces
        let strippedName = tryName.trimmingCharacters(in: .whitespacesAndNewlines)

        if strippedName.isEmpty {
            // not changing default Guest username, invalid username
            usernameError = "Cannot be only empty spaces!"
            isEmptyName = true
            return
        } else {
            // Username isn't empty GOOD!"
            isEmptyName = false
        }
        
        if !isEmptyName && players.count > 0 {
            // Got leaderboard conncted to internet GOOD!
            isDisconnected = false
        } else {
            // DIDNT GET the leaderboard
            usernameError = "Connect to the internet!"
            isDisconnected = true
            return
        }
        if !isEmptyName && !isDisconnected {
            for player in players {
                if player.name == strippedName {
                    // Username isn't unique : (")
                    usernameError = "The username already exists!"
                    isUniqueName = false
                    return
                }
            }
        }
        
        if isUniqueName && !isEmptyName && !isDisconnected {
            // username is unique GOOD!
            print("adding the username, it is unique, nonempty, and connected to internet")
            Task {
                await UpdateUsername(newUsername: strippedName)
            }
            usernameError = ""
            
        } else {
            print("something failed")
            username = "Guest"
        }
    }
    
    func CheckExistingUsername(tryUsername: String) -> Bool {
        if players.count > 0 && tryUsername.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            for player in players {
                if player.name == tryUsername {
                    return false
                }
            }
            return true
        }
        return false
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
    
    // Function to fetch data from S3 and print it
    // Fetch player data from S3 and store it
    func FetchDataFromS3() async {
        do {
            let serviceHandler = try await ServiceHandler()
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"

            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)

            if String(data: fileData, encoding: .utf8) != nil {
//                print("Received JSON: \(jsonString)")
//                print("\n")

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
                // Sorting and storing the player information
                self.players = tempPlayers.sorted { $0.score > $1.score }
            } else {
                print("Failed to convert data to string.")
            }
        } catch {
            print("Failed to fetch data from S3: \(error)")
        }
    }
    
    func UpdateS3() async {
        do {
            let serviceHandler = try await ServiceHandler() // Initialize the service handler
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"

            // Step 1: Read the current file from S3
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
//            print("read data: \(fileData)")
            // Step 2: Parse the existing JSON
            var json = try JSON(data: fileData)
            
            // Step 3: Update the data (e.g., add or update a player's highscore)
            var updated = false
            if var players = json["players"].array {
                for i in 0..<players.count {
                    if players[i]["name"].string == UIDevice.current.name {
                        if players[i]["highscore"].int64Value < highScore {
                            players[i]["highscore"] = JSON(highScore) // Update the players highscore
                        }
                        updated = true
                        break
                    }
                }
                // If phone_name wasn't found, add it
                if !updated {
                    players.append(["name": UIDevice.current.name, "highscore": highScore])
                }
                json["players"] = JSON(players) // Set the updated players array
            }
            // Step 4: Convert the updated JSON back to Data
            let updatedData = try json.rawData()
            // Step 5: Upload the updated file to S3
            try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
            print("File updated successfully.")
        } catch {
            print("Error updating file: \(error)")
        }
        await FetchDataFromS3()
    }
    
    func updateS3Username(newUsername: String) async -> Bool{
        var result: Bool = false
        do {
            let serviceHandler = try await ServiceHandler() // Initializing the service handler
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"
            // Reading the file first
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
            // Parse into a json object
            var jsonData = try JSON(data: fileData)
            var usernameExists: Bool = false
            // Loop through the data read from s3 and if the username exists, replace it with the new username
            if var playerData = jsonData["players"].array {
                for i in 0..<playerData.count {
                    if playerData[i]["name"].string == username {
                        usernameExists = true
                        playerData[i]["name"] = JSON(newUsername)
                    }
                }
                // After checking if the username exists, if it doesn't, add it
                if !usernameExists {
                    print("the username doesn't exist, adding username")
                    playerData.append(["name": newUsername, "highscore": highScore])
                }
                jsonData["players"] = JSON(playerData) // Set the updated players data
            }
            // Converted the JSON back to data for s3
            let updatedData = try jsonData.rawData()
            // Uploading the updated file to s3
            try await serviceHandler.createFile(bucket: bucketName, key: fileName, withData: updatedData)
            print("Username updated successfully.")
            result = true
            return result
        } catch {
            print("Error updating username: \(error)")
        }
        return result
    }
    
}
