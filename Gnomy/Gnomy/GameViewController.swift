//
//  GameViewController.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/20/24.
//

import UIKit
import SwiftUI
import SpriteKit
import GameplayKit
import CoreData
import ClientRuntime
import AWSS3
import SwiftyJSON


enum GameViewState {
    case menu, game, pause, restart
}

class GameViewController: UIViewController {
    @Published var currentState: GameViewState = .menu
    @Published var currentVolume: Float = 0.0
    @Published var highScore: Int64 = 0
    @Published var globalHighScore: Int64 = 0
    
    var currMenu: MenuView?
    var pauseMenu: PauseView?
    var restartView: RestartView?
    
    var currGKScene: GKScene?
    var gameScene: GameScene?
    var skView: SKView?
    
    var musicPlayer: MusicPlayer?
    var container: NSPersistentContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
//        print(UIDevice.current.name)
        // Core Data Setup
        container = NSPersistentContainer(name: "HighScore")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Unresolved error \(error)")
            }
        }

        highScore = getLocalHighScore()
        
        setupMenuView()
        setupGameScene()
        setupMusicPlayer()
        
        // async func call
        Task {
            globalHighScore = await fetchGlobalHighscore()
//            await testS3Connection()
//            await fetchDataFromS3()
            print("global high score: \(globalHighScore)")
//            	
        }
    }

    // Set the starting view to be the menu view
    private func setupMenuView() {
        currMenu = MenuView(
            highScore: Binding(
                get: { self.getLocalHighScore() },
                set: { _ in }
            ),
            globalHighScore: Binding(
                get: { self.getDeviceGlobalHighscore()},
                set: { _ in}),
            onStartTapped: {
            self.startGame()}
        )
        
        showSwiftUIView(currMenu!)
    }

    // Set the game scene from the appropriate files
    private func setupGameScene() {
        currGKScene = GKScene(fileNamed: "GameScene")
        gameScene = currGKScene?.rootNode as? GameScene
        gameScene?.scaleMode = .aspectFill
        
        skView = SKView(frame: view.bounds)
        skView?.presentScene(gameScene)
        skView?.ignoresSiblingOrder = true
        skView?.showsFPS = true // Comment off for release
        skView?.showsNodeCount = true // Comment off for release
        
        gameScene?.viewController = self
    }

    // Set the music player and default volume (50%)
    private func setupMusicPlayer() {
        musicPlayer = Gnomy.MusicPlayer()
        currentVolume = musicPlayer?.getVolume() ?? 0.5
    }

    // Function to start the game scene
    func startGame() {
        if let skView = skView {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(skView)
            }
            gameScene?.startGame()
        }
        musicPlayer?.playBgMusic()
    }

    // Function to pause the game
    func pauseGame() {
        if pauseMenu == nil {
            pauseMenu = PauseView(
                controller: self,
                volumeValue: Binding(
                    get: { self.currentVolume },
                    set: { newValue in
                        self.currentVolume = newValue
                        self.musicPlayer?.setVolume(newValue)
                    }
                ), highScore: Binding(
                    get: { self.getLocalHighScore() },
                    set: { _ in}
                ),
                globalHighScore: Binding(
                    get: { self.globalHighScore },
                    set: { _ in }
                ),
                onUnpause: { self.resumeGame() }
            )
        }
        showSwiftUIView(pauseMenu)
    }

    func resumeGame() {
        if let skView = skView {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(skView)
            }
            gameScene?.resumeGame()
        }
        musicPlayer?.playBgMusic()
    }

    func lossGame() {
        updateHighScore(newScore: Int64(self.currScore()))
        if restartView == nil {
            restartView = RestartView(
                highScore: Binding(
                    get: { self.highScore },
                    set: { _ in }
                ),
                globalHighScore: Binding(
                    get: { self.globalHighScore },
                    set: { _ in }
                ),
                controller: self,
                onRestart: { self.restartGame() }
            )
        }
        showSwiftUIView(restartView)
        updateHighScore(newScore: Int64(self.currScore()))
        musicPlayer?.pauseBgMusic()
    }

    func restartGame() {
        if let skView = skView {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(skView)
            }
            gameScene?.resetGame()
        }
        musicPlayer?.playBgMusic()
    }

    // Helper fucntion to show a new SwiftUI view
    private func showSwiftUIView<T: View>(_ swiftUIView: T?) {
        if let view = swiftUIView {
            let hostingController = UIHostingController(rootView: view)
            addChild(hostingController)
            hostingController.view.frame = self.view.bounds
            self.view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }

    func setVolume(_ volume: Float) {
        musicPlayer?.setVolume(volume)
    }

    func getVolume() -> Float {
        return musicPlayer?.getVolume() ?? 0
    }

    func currScore() -> Int {
        return gameScene?.getScore() ?? 0
    }

    func getLocalHighScore() -> Int64{
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        var resultScore: Int64 = -1
        do {
            let scores = try context.fetch(fetchRequest)
            
            // Check if we have a Score object
            if let score = scores.first {
                resultScore = score.localHighscore
                print("got the existing highscore object \(highScore)")
            } else {
                // No existing score, create a default one
                print("Creating a new score object to store local score")
                let newScore = Score(context: context)
                newScore.localHighscore = 0
                try context.save()
                resultScore = newScore.localHighscore
            }
        } catch {
            print("Error fetching high score: \(error)")
        }
        return resultScore
    }
    
    func getDeviceGlobalHighscore() -> Int64{
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        var resultGlobalScore: Int64 = -1
        do {
            let globalScores = try context.fetch(fetchRequest)
            
            if let globalScore = globalScores.first {
                resultGlobalScore = globalScore.globalHighscore
                print("got the existing GLOBAL highscore object \(globalScore.globalHighscore)")
            } else {
                print("Creating a new score object to store device global score")
                let newGlobalScore = Score(context: context)
                newGlobalScore.globalHighscore = 0
                try context.save()
                resultGlobalScore = newGlobalScore.globalHighscore
            }
        } catch {
            print("Error fetching high score: \(error)")
        }
        
        return resultGlobalScore
    }

    func updateHighScore(newScore: Int64) {
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingScore = scores.first, newScore > existingScore.localHighscore {
                existingScore.localHighscore = newScore
                try context.save()
                highScore = newScore
                print("Updated high score to: \(highScore)")
                if highScore > globalHighScore {
                    updateDeviceGlobalHighscore(newScore: highScore)
                    
                }
            }
        } catch {
            print("Error updating high score: \(error)")
        }
    }
    
    func updateDeviceGlobalHighscore(newScore: Int64) {
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingScore = scores.first, newScore > existingScore.globalHighscore {
                existingScore.globalHighscore = newScore
                try context.save()
                globalHighScore = newScore
                print("Updated GLOBAL high score to: \(globalHighScore)")
                Task {
                    await UpdateGlobalHighscore()
                }
            }
        } catch {
            print("Error updating high score: \(error)")
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
