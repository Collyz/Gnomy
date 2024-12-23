//
//  GameScene.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/20/24.
//

import SpriteKit
import GameplayKit

// Bitmask categories
struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let platform: UInt32 = 0x1 << 1
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Player
    private let player = SKSpriteNode(imageNamed: "player")
    private var touchOffset: CGPoint?    // Touch offset
    // Blocks
    private var blocks: Array<SKSpriteNode> = Array()
    
    
    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -9)
        physicsWorld.contactDelegate = self // Respond to contacts

        createBackground()
        createPlayer(upwardVel: 1300)
        generatePlatform(at: CGPoint(x: 0, y: -400)) // Test platform
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
        // -----
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
        // -----
        
        // Code block to update the touchOffset of the player
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        touchOffset = CGPoint(x: loc.x - player.position.x, y:loc.y - player.position.y)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
        touchOffset = nil
    }
    
    // called everytime a *move touch* is input
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // move on touch move
        movePlayer(touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
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
        if player.position.y < -600 {
//            player.removeFromParent()
//            generateCollectable()
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 1400)
        }
        
        if (player.physicsBody?.velocity.dy)! <= 0 {
            for block in blocks {
                block.physicsBody?.categoryBitMask = 1
                block.physicsBody?.collisionBitMask = 1
            }
        } else{
            for block in blocks {
                block.physicsBody?.categoryBitMask = 0
                block.physicsBody?.collisionBitMask = 0
            }
        }
        
    }
    
    
    
    
    func movePlayer(_ touches: Set<UITouch>) {
        // TODO: move player offset from touch (i.e. from finger)
        guard let touch = touches.first else { return }
        let touchPos = touch.location(in: self)
        if let offset = touchOffset {
            var newPosition = CGPoint(x: touchPos.x - offset.x, y: player.position.y)

            // Constrain the player's movement within screen bounds
            let leftBound = frame.minX + 100
            let rightBound = frame.maxX - 100
            newPosition.x = max(leftBound, min(newPosition.x, rightBound))

            // Update the player's position
            player.position = newPosition
        }
    }
    
    
    // MARK: - Player generations
    func createPlayer(upwardVel velocity: Int) {
        player.name = "player"
        player.size = CGSize(width: 90, height: 90)
        
        // adding physics
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.allowsRotation = false
        player.position = CGPoint(x: 0, y:0)
        
        player.texture!.filteringMode = .nearest;
        player.zPosition = 0;
        addChild(player)
        player.physicsBody?.velocity = CGVector(dx: 0, dy: velocity)
    }
    
    // MARK: - Background generation
    func createBackground() {
        // Background
        let background = SKSpriteNode(imageNamed: "background")
        background.name = "background"
        background.zPosition = -1
        background.scale(to: CGSize(width: 620, height: 1400))
        addChild(background)
    }
    
    // MARK: - Platform Generation
    func generatePlatform(at position: CGPoint){
        let block = SKSpriteNode(imageNamed: "b_grass")
        block.name = "platform"
        block.scale(to: CGSize(width: 130, height: 60))
        block.position = position

        // Add physics to the platform
        block.physicsBody = SKPhysicsBody(texture: block.texture!, size: block.size)
        block.physicsBody?.isDynamic = false // Static platform
        block.physicsBody?.categoryBitMask = PhysicsCategory.platform
        block.physicsBody?.contactTestBitMask = PhysicsCategory.player
        block.physicsBody?.collisionBitMask = PhysicsCategory.player
        block.physicsBody?.restitution = 0 // No bounce

        block.texture!.filteringMode = .nearest
        block.zPosition = 1
        addChild(block)
        blocks.append(block)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which body is the player
        let playerBody = (contact.bodyA.node?.name == "player") ? contact.bodyA : contact.bodyB
        // make player jump up again
        if (contact.contactNormal.dy == -1 || playerBody.velocity.dy == 0) {
            playerBody.velocity = CGVector(dx: 0, dy: 1400)
        }
        
        

        // Ensure the other body is a platform
//        guard platformBody.categoryBitMask == PhysicsCategory.platform else { return }
//
//        // Check if the player is falling onto the platform
//        if let playerPhysicsBody = playerBody.node?.physicsBody, playerPhysicsBody.velocity.dy <= 0 {
//            print("fallin")
//            // Stop the player's downward movement and place the player on top of the platform
//            playerPhysicsBody.velocity = CGVector(dx: 0, dy: 0)
//            if let platformNode = platformBody.node, let playerNode = playerBody.node as? SKSpriteNode {
//                playerNode.position.y = platformNode.frame.maxY + playerNode.size.height / 2
//            }
//        }
    }

}

