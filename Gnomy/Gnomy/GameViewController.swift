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

enum GameViewState {
    case menu
    case game
    case pause
    case restart
}


class GameViewController: UIViewController {
    @Published var currentState: GameViewState = .menu
    @Published var currentVolume: Float = 0.0
    var currMenu: MenuView?
    var pauseMenu: PauseView?
    var restartView: RestartView?
    
    var currGKScene: GKScene?
    var gameScene: GameScene?
    var skView: SKView?
    
    var musicPlayer: MusicPlayer?
    
    // Updating the highscore
    var container: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Score CoreData
        container = NSPersistentContainer(name: "HighScore")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Unresolved error \(error)")
            }
        }
        
        let highScore = fetchHighScore()
        print("Current High Score: \(highScore)")
        

        // Start with the SwiftUI MenuView
        currMenu = MenuView(onStartTapped: {
            self.startGame()
        })
        let hostingController = UIHostingController(rootView: currMenu)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // load the game view
        currGKScene = GKScene(fileNamed: "GameScene")
        gameScene = currGKScene?.rootNode as? GameScene
        gameScene!.scaleMode = .aspectFill
        skView = SKView(frame: view.bounds)
        skView?.presentScene(gameScene!)
        skView?.ignoresSiblingOrder = true
        skView?.showsFPS = true // comment off for release
        skView?.showsNodeCount = true // comment off for release

        // pass self reference to gameviewcontroler
        gameScene?.viewController = self
        
        // Music Player
        musicPlayer = Gnomy.MusicPlayer()
        currentVolume = musicPlayer?.getVolume() ?? 0.5
    }

    func startGame() {
        // Replace the current view with the SpriteKit game scene
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() } 
                self.view.addSubview(self.skView!)
            }
            
            gameScene?.startGame()
        }
        musicPlayer?.playBgMusic()
    }
    
    func pauseGame() {
        // custom binding needed to get and set game volume from slider in view
        if pauseMenu == nil {
            pauseMenu = PauseView(controller: self, volumeValue: Binding(
                get: { self.currentVolume },
                set: { newValue in
                    self.currentVolume = newValue
                    self.musicPlayer?.setVolume(newValue)
                }
            ), onUnpause: {
                self.resumeGame()
            })
        }
        if let pauseMenu = pauseMenu {
            let hostingController = UIHostingController(rootView: pauseMenu)
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }

    
    func resumeGame() {
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(self.skView!)
            }
            if gameScene != nil {
                gameScene?.resumeGame()
            }
        }
        musicPlayer?.playBgMusic()
    }
    
    func lossGame() {
        if restartView == nil {
            // load restart view
            restartView = RestartView(controller: self, onRestart: {
                self.restartGame()
            })
        }
        if restartView != nil {
            let hostingController = UIHostingController(rootView: restartView)
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
        musicPlayer?.pauseBgMusic()
    }
    
    func restartGame() {
        
        
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(self.skView!)
            }
            if gameScene != nil {
                gameScene?.resetGame()
            }
        }
        
        musicPlayer?.playBgMusic()
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
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do{
                try container?.viewContext.save()
            } catch {
                print("An error occured while saving: \(error)")
            }
        }
    }
    
    func fetchHighScore() -> Int64 {
        let context = container.viewContext
        let fetchRequest = Score.createFetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            if let highScore = results.first {
                return highScore.highscore
            } else {
                // If no score exists, create a new one with a default value
                let newScore = Score(context: context)
                newScore.highscore = 0
                try context.save()
                return 0
            }
        } catch {
            print("Failed to fetch high score: \(error)")
            return 0
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
