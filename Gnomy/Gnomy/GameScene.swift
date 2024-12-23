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
    private var score: Int = 0
    private let cam = SKCameraNode()
    private let scoreNode = SKLabelNode(fontNamed: "Chalkduster")
    private let background = SKSpriteNode(imageNamed: "background")
    
    // Blocks
    private var blocks: Array<Block> = Array()
    
    
    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -9)
        physicsWorld.contactDelegate = self // Respond to contacts
        self.camera = cam
        createBackground()
        generateBaseFloor(at: CGPoint(x: 0, y: -1000), CGSize(width: 700, height: 200))
        displayScore(at: CGPoint(x: frame.midX, y: frame.midY))
        createPlayer()
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
        jump()
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
    
    // MARK: - called before each frame is rendered
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
        
        // Player moves through blocks if going up, else do not fall through
        if (player.physicsBody?.velocity.dy)! <= 0 {
            for block in blocks {
                if(block.name != "floor") {
                    block.physicsBody?.categoryBitMask = 1
                    block.physicsBody?.collisionBitMask = 1
                }
            }
        } else{
            for block in blocks {
                if(block.name != "floor") {
                    block.physicsBody?.categoryBitMask = 0
                    block.physicsBody?.collisionBitMask = 0
                }
            }
        }
        
    }
    
    
    
    override func didSimulatePhysics() {
        print(cam.frame.midY)
        if player.position.y < -400 {
            cam.position.y = -400
        } else {
            cam.position.y = player.position.y
        }
        background.position.y = cam.position.y
        scoreNode.position.y = cam.position.y + 400
    }
    
    // MARK: - Moves the player sideways based on player movement
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
    func createPlayer() {
        player.name = "player"
        player.size = CGSize(width: 90, height: 90)
        player.position = CGPoint(x: 0, y: -900)
        
        // adding physics
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0 // No bounce
        player.texture!.filteringMode = .nearest;
        player.zPosition = 0;
        addChild(player)
    }
    
    // MARK: - Background assignments
    func createBackground() {
        // Background
        background.name = "background"
        background.zPosition = -1
        background.scale(to: CGSize(width: 620, height: 1400))
        addChild(background)
    }
    
    // MARK: - Platform Generation
    func generatePlatform(at position: CGPoint) {
        let block = Block(imageNamed: "b_grass")
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
    
    // MARK: - Starting Floor Generation
    func generateBaseFloor(at position: CGPoint, _ dimensions: CGSize) {
        let baseFloor = Block(imageNamed: "b_grass")
        baseFloor.scored = true
        baseFloor.isBaseFloor = true
        baseFloor.name = "floor"
        baseFloor.scale(to: dimensions)
        baseFloor.position = position
        
        // Add physics to floor
        baseFloor.physicsBody = SKPhysicsBody(texture: baseFloor.texture!, size: baseFloor.size)
        baseFloor.physicsBody?.isDynamic = false
        baseFloor.physicsBody?.allowsRotation = false
        baseFloor.zPosition = 1
        addChild(baseFloor)
        blocks.append(baseFloor)
    }
    
    // MARK: Score Display
    func displayScore( at position: CGPoint) {
        scoreNode.name = "score"
        scoreNode.text = String(self.score)
        scoreNode.fontSize = 65
        scoreNode.fontColor = SKColor.darkGreen
        scoreNode.position = position
        scoreNode.zPosition = 1
        addChild(scoreNode)
    }
    
    func jump() {
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 1400)
    }
    
    
    // MARK: - Handles collission
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which body is the player
        let playerBody = (contact.bodyA.node?.name == "player") ? contact.bodyA : contact.bodyB
        let platformBody = playerBody == contact.bodyA ? contact.bodyB : contact.bodyA
        
        guard let platformNode = platformBody.node as? Block else { return }
        // make player jump up again
        if (contact.contactNormal.dy == -1 && platformNode.name != "floor") {
            jump()
            if platformNode.scored == false{
                platformNode.scored = true
                score += 1;
                guard let temp = self.childNode(withName: "score") as? SKLabelNode else { return }
                temp.text = String(score)
            }
        }
    }

}

