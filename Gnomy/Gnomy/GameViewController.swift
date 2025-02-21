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
    
    var viewModel: GameViewModel!
    
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
        // Setting the view model
        viewModel = GameViewModel(context: container.viewContext)

        setupMenuView()
        setupGameScene()
        setupMusicPlayer()
        
    }

    // Set the starting view to be the menu view
    private func setupMenuView() {
        currMenu = MenuView(
            viewModel: self.viewModel,
            onStartTapped: { self.startGame() }
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
                viewModel: self.viewModel,
                controller: self,
                volumeValue: Binding(
                    get: { self.currentVolume },
                    set: { newValue in
                        self.currentVolume = newValue
                        self.musicPlayer?.setVolume(newValue)
                    }
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

    // Updates the high score and global score
    func lossGame() {
        let roundScore = Int64(self.currScore())
        viewModel.updateHighScore(newScore: roundScore)
        Task {
            await viewModel.UpdateDeviceGlobalHighScore()
            await viewModel.UpdateS3()
        }
        if restartView == nil {
            restartView = RestartView(
                viewModel: self.viewModel,
                controller: self,
                onRestart: { self.restartGame() }
            )
        }
        showSwiftUIView(restartView)
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
