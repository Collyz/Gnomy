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
    // Game logic
    private var firstTap = false // first jump check
    private var score: Int = 0
    private var nextPlatformY: CGFloat = 0
    private let nextAddY: CGFloat = 250
    
    // Player
    private let player = SKSpriteNode(imageNamed: "player")
    private var touchOffset: CGPoint?    // Touch offset
    
    private let cam = SKCameraNode()
    private let scoreNode = SKLabelNode(fontNamed: "Chalkduster")
    private let background = SKSpriteNode(imageNamed: "background")
    private let pauseButton = SKSpriteNode(imageNamed: "pause")
    
    // Blocks
    private var blocks: Array<Block> = Array()
    
    
    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self // Respond to contacts
        camera = cam
        camera?.position = CGPoint(x: 0, y: -400)
        createBackground()
        nextPlatformY += -1000
        generateBaseFloor(at: CGPoint(x: 0, y: nextPlatformY), CGSize(width: 700, height: 200))
        displayScore(at: CGPoint(x: frame.midX, y: frame.midY))
        createPlayer()
        addPauseButton()
        generatePlatform()
        
        // TODO: Pregenerate blocks?? or Iteravely???
        if blocks.count <= 25 {
            while blocks.count <= 25 {
                generatePlatform()
            }
        }
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
            jump()
            firstTap = true
        }
        
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
        // TODO: Generate the platforms if there are fewer than 3/4 platforms on the screen
//        for block in blocks {
//            if block.position.y - player.position.y > self.bounds.height {
//                blocks.removeFirst()
//            }
//        }
    }
    
    override func didSimulatePhysics() {
//        print("camera frame maxY \(cam.frame.maxY), camera frame minY \(cam.frame.minY) player position y: \(player.position.y)")
//        print(cam.frame.height)
        if cam.position.y - player.position.y < 0 {
            cam.position.y = player.position.y
        } else if cam.position.y - player.position.y > (self.bounds.height / 2) + 100{
            // TODO: insert pause functionality and loss screen
            print("removedPlayer")
            player.removeFromParent()
        }
        background.position.y = cam.position.y
        scoreNode.position.y = cam.position.y + 400
        pauseButton.position.y = cam.position.y + 600
    }
    
    // MARK: - Moves the player sideways based on player movement
    func movePlayer(_ touches: Set<UITouch>) {
        // Moves player offset from touch (i.e. from finger)
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
        
        // Adding physics
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 0 // No bounce
        
        // Set physics category
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.platform
        player.physicsBody?.collisionBitMask = PhysicsCategory.platform

        player.texture!.filteringMode = .nearest
        player.zPosition = 0
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
    func generatePlatform() {
        let block = Block(imageNamed: "b_wood")
        block.name = "platform"
        block.scale(to: CGSize(width: 130, height: 30))
        block.position = CGPoint(x: CGFloat.random(in: frame.minX + block.size.width...frame.maxX - block.size.width), y: nextPlatformY)
        nextPlatformY += block.size.height + nextAddY

        // Add physics to the platform
        block.physicsBody = SKPhysicsBody(texture: block.texture!, size: block.size)
        block.physicsBody?.isDynamic = false // Static platform
        block.physicsBody?.restitution = 0 // No bounce
        
        // Set physics category
        player.physicsBody?.categoryBitMask = PhysicsCategory.platform
        player.physicsBody?.contactTestBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.player
        
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
    
    // MARK: - Player jumps
    func jump() {
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 700)
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

