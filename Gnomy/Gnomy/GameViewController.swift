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
    var currGKScene: GKScene?
    var gameScene: GameScene?
    var skView: SKView?
    
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
    }

    func startGame() {
        // Replace the current view with the SpriteKit game scene
//        if let scene = GKScene(fileNamed: "GameScene"),
//           let sceneNode = scene.rootNode as? GameScene {
//            sceneNode.scaleMode = .aspectFill
//            let skView = SKView(frame: view.bounds)
//            skView.presentScene(sceneNode)
//            skView.ignoresSiblingOrder = true
//            skView.showsFPS = true
//            skView.showsNodeCount = true
//
//            // Transition to the game
//            DispatchQueue.main.async {
//                self.view.subviews.forEach { $0.removeFromSuperview() } // Remove existing views
//                self.view.addSubview(skView)
//            }
//        }
        if skView != nil {
            DispatchQueue.main.async {
                self.view.subviews.forEach { $0.removeFromSuperview() } 
                self.view.addSubview(self.skView!)
            }
        }
    }
    
    func pauseGame() {
        
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
