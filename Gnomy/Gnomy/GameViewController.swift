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

enum GameViewState {
    case menu, game, pause, restart
}

class GameViewController: UIViewController {
    @Published var currentState: GameViewState = .menu
    @Published var currentVolume: Float = 0.0
    @Published var highScore: Int64 = 0
    
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
        
        // Core Data Setup
        container = NSPersistentContainer(name: "HighScore")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Unresolved error \(error)")
            }
        }

        highScore = getHighScore()
        
        setupMenuView()
        setupGameScene()
        setupMusicPlayer()
        
        // async func call
        Task {
            await testS3Connection()
        }
    }

    // Set the starting view to be the menu view
    private func setupMenuView() {
        currMenu = MenuView(
            highScore: Binding(
                get: { self.getHighScore() },
                set: { _ in }
            ),
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
                    get: { self.getHighScore() },
                    set: { _ in}
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
        updateHighScore(newScore: currScore())
        if restartView == nil {
            restartView = RestartView(
                highScore: Binding(
                    get: { self.highScore },
                    set: { _ in }
                ),
                controller: self,
                onRestart: { self.restartGame() }
            )
        }
        showSwiftUIView(restartView)
        updateHighScore(newScore: currScore())
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

    func getHighScore() -> Int64{
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        var resultScore: Int64 = -1
        do {
            let scores = try context.fetch(fetchRequest)
            
            // Check if we have a Score object
            if let score = scores.first {
                resultScore = score.highscore
                print("got the existing score object\(highScore)")
            } else {
                // No existing score, create a default one
                print("Creating a new score object to store")
                let newScore = Score(context: context)
                newScore.highscore = 0
                try context.save()
                resultScore = newScore.highscore
            }
        } catch {
            print("Error fetching high score: \(error)")
        }
        return resultScore
    }

    func updateHighScore(newScore: Int) {
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        
        do {
            let scores = try context.fetch(fetchRequest)
            if let existingScore = scores.first, newScore > existingScore.highscore {
                existingScore.highscore = Int64(newScore)
                try context.save()
                highScore = Int64(newScore)
            }
        } catch {
            print("Error updating high score: \(error)")
        }
    }

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


    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
