//
//  GameScene.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/20/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // player
    private let player = SKSpriteNode(imageNamed: "player")
    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -9) // world gravity
        let background = SKSpriteNode(imageNamed: "background")
        background.name = "background"
        background.zPosition = -1;
        background.scale(to: CGSize(width: 620, height: 1400))
        addChild(background)
        generateCollectable()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
        //FROM TUTORIAL quite nice :3
//        guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//        let tappedNode = nodes(at: location) //allows you to get the nodes quite easily
//        guard let tapped = tappedNode.first else { return }
//        
//        if tapped.name != "background" {
//            tapped.removeFromParent()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.generateCollectable()
//            }
//        }
        //END OF ----- FROM TUTORIAL quite nice :3
        
        // get the players location and move to finger only x pos
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        player.position.x = loc.x
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // this method is called before each frame is rendered
        //FROM TUTORIAL quite nice :3
//        for node in children {
//            if node.position.y < -700 {
//                node.removeFromParent()
//                generateCollectable()
//            }
//        }
        //END OF ----- FROM TUTORIAL quite nice :3
        
        // On the update, move the player to the finger position
        //TODO: remove this update once base floor is created
        if(player.position.y < -700) {
            player.removeFromParent()
            generateCollectable()
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // move on touch move
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        player.position.x = loc.x
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
    }
    
    func movePlayer(touchPos: CGPoint) {
        //TODO: move player offset from touch (i.e. from finger)
    }
    
    func generateCollectable() {
        
        player.name = "collectable"
        player.size = CGSize(width: 90, height: 90)
        
        // adding physics
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        
        player.texture!.filteringMode = .nearest;
        player.zPosition = 0;
        addChild(player)
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 700)
    }
}

