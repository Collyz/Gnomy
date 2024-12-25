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
    static let none: UInt32 = 0x1 << 0
    static let player: UInt32 = 0x1 << 1
    static let platform: UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Game logic
    private var firstTap = false // first jump check
    private var score: Int = 0
    private var nextPlatformY: CGFloat = 0
    private let nextAddY: CGFloat = 200
    private let blockNames: Array<String> = ["b_grass", "b_wood", "b_stone", "b_brick", "b_iron"]
    private var touchOffset: CGPoint?
    private let pregenerateBlocks: Int = 60
    
    // Player
    private let player = Player(fileName: "player", size: CGSize(width: 64, height: 64), position: CGPoint(x: 0, y: 0))
        
    
    private let cam = SKCameraNode()
    private let scoreNode = SKLabelNode(fontNamed: "Chalkduster")
    private let background = SKSpriteNode(imageNamed: "background")
    private let pauseButton = SKSpriteNode(imageNamed: "pause")
    
    // Blocks
    private var blocks: Array<Block> = Array()
    
    // Debug
//    private var debugOutline = SKShapeNode()
    private var targetX: CGFloat?
    
    // Camera
    private let cameraVerticalOffset: CGFloat = 200
    // Adjust this value to view lower
    
    
    override func didMove(to view: SKView) {
        addChild(player)
        // Debug
//        let cameraFrame = CGRect(
//                x: cam.position.x,
//                y: cam.position.y,
//                width: 10,
//                height: 10
//            )
//        debugOutline = SKShapeNode(rect: cameraFrame)
        
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self // Respond to contacts
        camera = cam
        cam.position = CGPoint(x: 0, y: 400)
        createBackground()
        nextPlatformY = -nextAddY
        generateBaseFloor(at: CGPoint(x: 0, y: nextPlatformY), CGSize(width: 700, height: 200))
        displayScore(at: CGPoint(x: frame.midX, y: frame.midY))
        addPauseButton()
        nextPlatformY += nextAddY - 100
        while(blocks.count < pregenerateBlocks) {
            generatePlatform()
        }
//        addCameraDebugOutline()
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
        let tappedNode = atPoint(loc)
        // Jump only on the first tap to the screen that isn't on the pause button
        if(tappedNode.name == "pauseButton") {
            isPaused = !isPaused
        } else if !firstTap{
            player.jump()
            firstTap = true
        }
        
        touchOffset = touches.first!.location(in: self)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
        
        touchOffset = nil
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // called everytime a *move touch* is input
        touchOffset = touches.first!.location(in: self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // called when *move touch* ends
        touchOffset = nil
    }
    
    // MARK: - called before each frame is rendered
    override func update(_ currentTime: TimeInterval) {
        // this method is called before each frame is rendered
        
        player.move(touching: touchOffset)
        
        // lerp camera movement
        let targetY = max(player.position.y + cameraVerticalOffset, cam.position.y)
        let cameraMoveSpeed: CGFloat = 0.05
        let newY = cam.position.y + (targetY - cam.position.y) * cameraMoveSpeed
        cam.position.y = newY
        
        if cam.position.y - (player.position.y - player.size.height) > (self.bounds.height / 2) + 100 {
            // TODO: insert pause functionality and loss screen/restart
            player.removeFromParent()
        }
        
        // Update background,pausebutton, and score
        background.position.y = cam.position.y
        scoreNode.position.y = cam.position.y + 500
        pauseButton.position.y = cam.position.y + 600
        
//        debugOutline.position.y = cam.position.y
        
//        // Player moves through blocks if going up, else do not fall through
//        if (player.physicsBody?.velocity.dy)! <= 0 {
//            for block in blocks {
//                if(block.name != "floor") {
//                    block.physicsBody?.categoryBitMask = 1
//                    block.physicsBody?.collisionBitMask = 1
//                }
//            }
//        } else{
//            for block in blocks {
//                if(block.name != "floor") {
//                    block.physicsBody?.categoryBitMask = 0
//                    block.physicsBody?.collisionBitMask = 0
//                }
//            }
//        }
        
        if let body = player.physicsBody {
            let dy = body.velocity.dy
            if dy >= 0 {
                body.collisionBitMask = 0
            } else {
                body.collisionBitMask = PhysicsCategory.platform
            }
        }
        
        // Removes blocks out of view
        for block in blocks {
            if block.position.y < cam.position.y && cam.position.y - block.position.y  > self.bounds.height / 2 + 100 {
                blocks.remove(at: blocks.firstIndex(of: block)!).removeFromParent()
            }
        }
        if blocks.count < pregenerateBlocks {
            generatePlatform()
        }
    }
    
    override func didSimulatePhysics() {
//        print("camera frame maxY \(cam.frame.maxY), camera frame minY \(cam.frame.minY) player position y: \(player.position.y)")
//        print(cam.frame.height)
//        if cam.position.y - player.position.y < 0 {
//            cam.position.y = player.position.y - 10
//        } else if cam.position.y - player.position.y > (self.bounds.height / 2) + 100{
//            // TODO: insert pause functionality and loss screen
//            player.removeFromParent()
//        }
//        background.position.y = cam.position.y
//        scoreNode.position.y = cam.position.y + 700
//        pauseButton.position.y = cam.position.y + 600

    }

    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
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
    func generatePlatform() {
        let block = Block(imageNamed: blockNames[score / 100])
        block.name = "platform"
        block.scale(to: CGSize(width: 130, height: 30))
        block.position = CGPoint(x: CGFloat.random(in: frame.minX + block.size.width...frame.maxX - block.size.width), y: nextPlatformY)
        nextPlatformY += block.size.height + nextAddY

        // Add physics to the platform
        block.physicsBody = SKPhysicsBody(texture: block.texture!, size: block.size)
        block.physicsBody?.isDynamic = false // Static platform
        block.physicsBody?.restitution = 0 // No bounce
        
        // Set physics category
        block.physicsBody?.categoryBitMask = PhysicsCategory.platform
        block.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect player contact
        block.physicsBody?.collisionBitMask = PhysicsCategory.player // Allow collision with the player
        
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
        
        // Set physics category
        baseFloor.physicsBody?.categoryBitMask = PhysicsCategory.platform
        baseFloor.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect player contact
        baseFloor.physicsBody?.collisionBitMask = PhysicsCategory.player // Allow collision with the player

        
        addChild(baseFloor)
        nextPlatformY += nextAddY
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
    
    // MARK: - Pause button assignments
    func addPauseButton() {
        pauseButton.name = "pauseButton"
        pauseButton.size = CGSize(width: 50, height: 50)
        pauseButton.position = CGPoint(x: 230, y: 0)
        pauseButton.zPosition = 2
        addChild(pauseButton)
    }
    
    // MARK: - Handles collission
    func didBegin(_ contact: SKPhysicsContact) {
        
        let playerBody = (contact.bodyA.node?.name == "player") ? contact.bodyA : contact.bodyB
        let platformBody = playerBody == contact.bodyA ? contact.bodyB : contact.bodyA
        
        guard let platformNode = platformBody.node as? Block else { return }
        // Ensure the player is landing on the top of the platform
        if contact.contactNormal.dy < 0 {
            // Player is falling onto the platform
            if !platformNode.isBaseFloor {
                player.jump()
                // scoring
                // TODO: Decide if scoring should be based on blocks jumped on or blocks passed for future updates where there are powerups and enemies

                if platformNode.scored == false {
                    platformNode.scored = true
                    score += 1
                    scoreNode.text = String(score)
                }
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        
    }

    
//    func addCameraDebugOutline() {
//        debugOutline.strokeColor = .red // Visible color
//        debugOutline.lineWidth = 2 // Thickness of the outline
//        debugOutline.zPosition = 10 // Ensure it renders above other elements
//        
//        // Add the debug outline as a child of the camera
////        cam.addChild(debugOutline)
//        addChild(debugOutline)
//    }


}

