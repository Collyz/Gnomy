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
    private let nextAddY: CGFloat = 200
    private let blockNames: Array<String> = ["b_grass", "b_wood", "b_stone", "b_brick", "b_iron"]
    
    // Player
    private let player = SKSpriteNode(imageNamed: "player")
    private var touchOffset: CGPoint?    // Touch offset
    
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
        // Debug
//        let cameraFrame = CGRect(
//                x: cam.position.x,
//                y: cam.position.y,
//                width: 10,
//                height: 10
//            )
//        debugOutline = SKShapeNode(rect: cameraFrame)
        
        // this method is called when your game scene is ready to run
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self // Respond to contacts
        camera = cam
        cam.position = CGPoint(x: 0, y: 400)
        createBackground()
        nextPlatformY = -nextAddY
        generateBaseFloor(at: CGPoint(x: 0, y: nextPlatformY), CGSize(width: 700, height: 200))
        displayScore(at: CGPoint(x: frame.midX, y: frame.midY))
        createPlayer()
        addPauseButton()
        nextPlatformY += nextAddY
        while(blocks.count < 7) {
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
        
        // Smoothly interpolate toward the target X position
        if let targetX = targetX {
            let currentX = player.position.x
            let newX = lerp(start: currentX, end: targetX, t: 0.2)

            if abs(newX - currentX) > 0.1 {
                player.position.x = newX
            }
        }
        
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
        scoreNode.position.y = cam.position.y + 600
        pauseButton.position.y = cam.position.y + 700
//        debugOutline.position.y = cam.position.y
        
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
        
        // Removes blocks if past the bottom of the screen + 100 pixels, check didBegin for block generation
        for block in blocks {
            if block.position.y < cam.position.y && cam.position.y - block.position.y  > self.bounds.height / 2 + 100 {
                blocks.remove(at: blocks.firstIndex(of: block)!).removeFromParent()
            }
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
    
    // MARK: - Moves the player sideways based on player movement
//    func movePlayer(_ touches: Set<UITouch>) {
//        // Moves player offset from touch (i.e. from finger)
//        // TODO: lerp movement for smoothness
//        guard let touch = touches.first else { return }
//        let touchPos = touch.location(in: self)
//        if let offset = touchOffset {
//            var newPosition = CGPoint(x: touchPos.x - offset.x, y: player.position.y)
//
//            // Constrain the player's movement within screen bounds
//            let leftBound = frame.minX + 100
//            let rightBound = frame.maxX - 100
//            newPosition.x = max(leftBound, min(newPosition.x, rightBound))
//
//            // Update the player's position
//            player.position = newPosition
//        }
//    }
    
    func movePlayer(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let touchPos = touch.location(in: self)
        if let offset = touchOffset {
            let calculatedTargetX = touchPos.x - offset.x

            // Constrain the player's movement within screen bounds
            let leftBound = frame.minX + 60
            let rightBound = frame.maxX - 60
            targetX = max(leftBound, min(calculatedTargetX, rightBound))
        }
    }

    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }

    // MARK: - Player generation
    func createPlayer() {
        player.name = "player"
        player.size = CGSize(width: 70, height: 70)
        player.position = CGPoint(x: 0, y: 0)
        
        // Adding physics
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.restitution = 1
        player.physicsBody?.linearDamping = 0.5
        // Set physics category
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.platform
        player.physicsBody?.collisionBitMask = PhysicsCategory.platform
        // Scaling
        player.texture!.filteringMode = .nearest
        // Appear above background
        player.zPosition = 1
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
        let block = Block(imageNamed: blockNames[score / 100])
        block.name = "platform"
        block.scale(to: CGSize(width: 130, height: 30))
        block.position = CGPoint(x: CGFloat.random(in: frame.minX + block.size.width...frame.maxX - block.size.width), y: nextPlatformY)
        nextPlatformY += block.size.height + nextAddY

        // Add physics to the platform
        block.physicsBody = SKPhysicsBody(texture: block.texture!, size: block.size)
        block.physicsBody?.isDynamic = false // Static platform
//        block.physicsBody?.restitution = 0 // No bounce
        
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
        
        // Set physics category
        player.physicsBody?.categoryBitMask = PhysicsCategory.platform
        player.physicsBody?.contactTestBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.player
        
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
        if (contact.contactNormal.dy == -1 || platformNode.isBaseFloor || !platformNode.isBaseFloor) && firstTap {
            jump()
            // generate blocks so there are always 7
            // TODO: Don't like the while block here, generate 7 at the start, then just call generatePlatform once
            while(blocks.count < 7) {
                generatePlatform()
            }
            // scoring
            // TODO: Decide if scoring should be based on blocks jumped on or blocks passed for future updates where there are powerups and enemies
            if platformNode.scored == false{
                platformNode.scored = true
                score += 1;
                guard let temp = self.childNode(withName: "score") as? SKLabelNode else { return }
                temp.text = String(score)
            }
        }
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

