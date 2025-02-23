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
        self.context = context
        FetchUsername()
        FetchHighScore()
        FetchDeviceGlobalHighScore()
        Task {
            await FetchDataFromS3()
            await UpdateDeviceGlobalHighScore()	
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
                // Updating the highScore that is shown in the views
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
            UpdateDeviceGlobalHighScore(newScore: newScore)
            
        } catch {
            print("Failed to update high score: \(error)")
        }
        
    }
    
    // Get the device global high score (i.e. the high score that is pulled from s3
    func FetchDeviceGlobalHighScore() {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let score = scores.first {
                globalHighScore = score.globalHighScore
            } else {
                let newScore = Score(context: context)
                newScore.globalHighScore = 0
            }
        } catch {
            print("Failed to fetch global high score: \(error)")
        }
    }
    
    // Update the global high score (i.e. update the s3 json file if possible)
    func UpdateDeviceGlobalHighScore(newScore: Int64) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingGlobalScore = scores.first, newScore > existingGlobalScore.globalHighScore {
                existingGlobalScore.globalHighScore = newScore
                try context.save()
                DispatchQueue.main.async {
                    self.globalHighScore = newScore
                }
            } else {
//                print("not updating, local score higher than global score")
            }
        } catch {
            print("Failed to update global high score: \(error)")
        }
    }
    
    func UpdateDeviceGlobalHighScore() async{
        if players.count > 0 {
            UpdateDeviceGlobalHighScore(newScore: players[0].score)
        } else {
            print("nothing pulled from servers")
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
                    print("setting username to Guest")
                    data.username = "Guest"
                    try context.save()
                    // Setting the username to the default Guest username
                    self.username = data.username
                }
            }
        } catch {
            print("Failed to find username: \(error)")
        }
    }
    
    func UpdateUsername(newUsername: String) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let request = try context.fetch(fetchRequest)
            if let data = request.first {
                data.username = newUsername
                try context.save()
                self.username = newUsername
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
            UpdateUsername(newUsername: strippedName)
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
        } else {
            return false
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
    
    
    
}
