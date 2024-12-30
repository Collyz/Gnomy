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

class GameViewController: UIViewController {
    var currMenu: MenuView?
    var pauseMenu: PauseView?
    var restartView: RestartView?
    
    var currGKScene: GKScene?
    var gameScene: GameScene?
    var skView: SKView?
    
    var pauseView: PauseView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        
        // load the pause view
        pauseMenu = PauseView(onUnpause: {
            if self.gameScene != nil {
                self.resumeGame()
            }
        })
        
        // load restart view
        restartView = RestartView(onRestart: {
            self.restartGame()
        })
        
        // pass self reference to gameviewcontroler
        gameScene?.viewController = self
    }

    func startGame() {
        // Replace the current view with the SpriteKit game scene
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() } 
                self.view.addSubview(self.skView!)
            }
        }
    }
    
    func pauseGame() {
        print("paused")
        if pauseMenu != nil {
            let hostingController = UIHostingController(rootView: pauseMenu)

            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }
    
    func resumeGame() {
        print("resumed")
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.view.addSubview(self.skView!)
            }
            if gameScene != nil {
                gameScene?.resumeGame()
            }
        }
    }
    
    func lossGame() {
        if restartView != nil {
            let hostingController = UIHostingController(rootView: restartView)
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
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
