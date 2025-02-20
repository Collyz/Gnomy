//
//  GameViewModel.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/20/25.
//

import Combine
import CoreData
import AWSS3
import ClientRuntime
import SwiftyJSON

class GameViewModel: ObservableObject {
    @Published var highScore: Int64 = 0
    @Published var globalHighScore: Int64 = 0
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchHighScore()
        fetchDeviceGlobalHighScore()
    }

    // Get the local high score if it exists, otherwise create it and assign a value of zero
    func fetchHighScore() {
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
    func updateHighScore(newScore: Int64) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingHighScore = scores.first, newScore > existingHighScore.localHighScore {
                // Apply the new score if it is bigger than the stored score
                existingHighScore.localHighScore = newScore
                // Save the changes
                try context.save()
                // Updating the highScore with the new score if it is bigger than the old
                DispatchQueue.main.async {
                    self.highScore = existingHighScore.localHighScore
                }
            }
        } catch {
            print("Failed to update high score: \(error)")
        }
    }
    
    // Get the device global high score (i.e. the high score that is pulled from s3
    func fetchDeviceGlobalHighScore() {
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
    func updateDeviceGlobalHighScore(newScore: Int64) {
        let fetchRequest: NSFetchRequest<Score> = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingGlobalScore = scores.first, newScore > existingGlobalScore.globalHighScore {
                existingGlobalScore.globalHighScore = newScore
                try context.save()
                DispatchQueue.main.async {
                    self.globalHighScore = newScore
                }
            }
        } catch {
            print("Failed to update global high score: \(error)")
        }
    }
    
    // Test the s3 connection
    func testS3Connection() async {
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
    func fetchDataFromS3() async {
        do {
            let serviceHandler = try await ServiceHandler() // Initialize the service handler
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"
            
            // Read the file from S3
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
            
            // Convert the Data to a string for printing
            if let jsonString = String(data: fileData, encoding: .utf8) {
                print("Fetched JSON data")
                
                // Parse the JSON using SwiftyJSON
                let json = try JSON(data: fileData)
                if let players = json["players"].array {
                    for player in players {
                        if let name = player["name"].string, let highscore = player["highscore"].int {
                            print("Player: \(name), Highscore: \(highscore)")
                        }
                    }
                } else {
                    print("No players found in the JSON.")
                }
            } else {
                print("Failed to convert data to string.")
            }
        } catch {
            print("Failed to fetch data from S3: \(error)")
        }
    }
    
    func fetchGlobalHighscore() async -> Int64{
        do {
            let serviceHandler = try await ServiceHandler() // Initialize the service handler
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"
            
            // Read the file from S3
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)
            
            var maxScore: Int64 = -1
            // Convert the Data to a string for printing
            if let jsonString = String(data: fileData, encoding: .utf8) {
                print("Fetched JSON data")
                
                // Parse the JSON using SwiftyJSON
                let json = try JSON(data: fileData)
                if let players = json["players"].array {
                    for player in players {
                        if player["name"] == "gnomy_player" {
                            if let tempScore = player["highscore"].int64 {
                                if maxScore < tempScore{
                                    maxScore = tempScore
                                }
                            }
                        }
                    }
                } else {
                    print("No players found in the JSON.")
                }
            } else {
                print("Failed to convert data to string.")
            }
            print("biggest score from json: \(maxScore)")
            return maxScore
        } catch {
            print("Failed to fetch data from S3: \(error)")
        }
        return -1
    }
    
    func UpdateGlobalHighscore() async {
        do {
            let serviceHandler = try await ServiceHandler() // Initialize the service handler
            let bucketName = "gnomyleaderboardbucket"
            let fileName = "data.json"

            // Step 1: Read the current file from S3
            let fileData = try await serviceHandler.readFile(bucket: bucketName, key: fileName)

            // Step 2: Parse the existing JSON
            var json = try JSON(data: fileData)
            
            // Step 3: Update the data (e.g., add or update a player's highscore)
            var updated = false
            if var players = json["players"].array {
                for i in 0..<players.count {
                    if players[i]["name"].string == "gnomy_player" {
                        players[i]["highscore"] = JSON(globalHighScore) // Update Alice's highscore
                        updated = true
                        break
                    }
                }
                // If gnomy_player wasn't found, add her
                if !updated {
                    players.append(["name": "gnomy_player", "highscore": globalHighScore])
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
        
    }
    
}
