//
//  GameScene.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/20/24.
//

import SpriteKit
import GameplayKit
import AVFoundation

enum BlockValues: CGFloat {
    case minSpawnY = 100.0
    case maxSpawnY = 280.0
    
}

// Bitmask categories
struct PhysicsCategory {
    static let none: UInt32 = 0x1 << 0
    static let player: UInt32 = 0x1 << 1
    static let platform: UInt32 = 0x1 << 2
    static let border: UInt32 = 0x1 << 3
}
// Block Atlas/
let blockAtlas = SKTextureAtlas(named: "Blocks")
let powerupAtlas = SKTextureAtlas(named: "PowerUps")

class GameScene: SKScene, SKPhysicsContactDelegate {
    var viewController: GameViewController?
    
    // Game logic
    private var firstTap = false // first jump check
    private var score: Int = 0
    private var platformY: CGFloat = -200
    private var nextAddY: CGFloat = 280
    private let blockNames: Array<String> = ["b_grass", "b_wood", "b_stone", "b_brick", "b_iron"]
    private let powerupNames: Array<String> = ["spring"]
    private var touchOffset: CGPoint?
//    private let pregenerateBlocks: Int = 1
    private var platformSize: CGSize?
    private var baseFloorSize: CGSize?
    private var spawnMoveBlock: Bool = false
    private var totalBlocks: Int = 0
    private var spawnBlocks = 12

    // Player
    private let player = Player(fileName: "player", position: CGPoint(x: 0, y: -5))
    
    // Nonplayer nodes
    private let cam = SKCameraNode()
    private let scoreNode = SKLabelNode(fontNamed: "Chalkboard SE")
    private var background = SKSpriteNode(imageNamed: "background")
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
        self.name = "GameScene"
        self.isPaused = true
        // Set up the scene and player
        addChild(player)
        player.playIdleAnimation()
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        camera = cam
        cam.position = CGPoint(x: 0, y: 400)
        
        createBg()
        createScoreLabel(at: CGPoint(x: frame.midX, y: frame.midY))
        createPauseButton()
        baseFloorSize = CGSize(width: self.bounds.width, height: 300)
        platformSize = CGSize(width: self.bounds.width/10, height: 30)

        // Generate the base floor
        createBaseFloor(at: CGPoint(x: 0, y: platformY), baseFloorSize!) // draw floor at (0, -200)
        player.position = CGPoint(x: 0,
                                  y: (-(baseFloorSize!.height / 2)) + (player.size.height)
                                  + player.size.height + 10 // set player on top of floor
                                )
        platformY = 210 //found manually setting nextPlatformY
        
        // Generate initial platforms above the base floor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
        
        // Code block to update the touchOffset of the player
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let tappedNode = atPoint(loc)
        // Jump only on the first tap to the screen that isn't on the pause button
        if(tappedNode.name == "pauseButton" || tappedNode.name == "pauseButtonTapArea") {
            pauseGame()
        } else if !firstTap{
            player.removeAllChildren()
            player.jump()
            firstTap = true
            // turn off idle animation
            player.stopIdleAnimation()
        }
        
        touchOffset = nil
        player.stopMovement()
//        touchOffset = touches.first?.location(in: self)
//        player.stopMovement()
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
        touchOffset = nil
        player.stopMovement()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchOffset = touch.location(in: self)
            player.move(touching: touchOffset!)
        }
//        touchOffset = touches.first?.location(in: self)
//        player.move(touching: touchOffset!)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // called when *move touch* ends
        touchOffset = nil
        player.stopMovement()
    }
    
    // MARK: - called before each frame is rendered
    override func update(_ currentTime: TimeInterval) {
        // this method is called before each frame is rendered (https://developer.apple.com/documentation/spritekit/responding-to-frame-cycle-events)
        // Generate and remove blocks
        for block in blocks {
            if cam.position.y - (block.position.y - block.size.height) > (self.bounds.height / 2) + 100{
                // blocks will score even if passed (love past me fr fr)
                if(block.scored == false) {
                    scoreUpdate(true)
                    block.scored = true;
                }
                blocks.remove(at: blocks.firstIndex(of: block)!)
                block.removeFromParent()
            }
        }
        if blocks.count < spawnBlocks {
            createPlatform()
        }
        
        // lerp camera movement
        let targetY = max(player.position.y + cameraVerticalOffset, cam.position.y)
        let cameraMoveSpeed: CGFloat = 0.05
        let newY = cam.position.y + (targetY - cam.position.y) * cameraMoveSpeed
        cam.position.y = newY
        // the user loses if you fall below the cameras view
        if cam.position.y - (player.position.y - player.size.height) > (self.bounds.height / 2) + 100 {
            // TODO: insert pause functionality and loss screen/restart
            player.removeFromParent()
            lossGame()
        }
        
        // Update background,pausebutton, and score
        background.position.y = cam.position.y
        scoreNode.position.y = cam.position.y + (frame.height/2) - 200
        pauseButton.position.y = cam.position.y + (frame.height/2) - 100
        
        
//        debugOutline.position.y = cam.position.y
        
        guard let velocity = player.physicsBody?.velocity else { return }
        if velocity.dy > 0 {
            jumpingGravity()
        } else {
            fallingGravity()
        }

    }
    
    // MARK: - Handles collission
    func didBegin(_ contact: SKPhysicsContact) {
        
        let playerBody = (contact.bodyA.node?.name == "player") ? contact.bodyA : contact.bodyB
        let otherBody = playerBody == contact.bodyA ? contact.bodyB : contact.bodyA
        
        if let platformNode = otherBody.node as? Block {
        // Ensure the player is landing on the top of the platform
            if contact.contactNormal.dy > 0 {
                // Player is falling onto the platform
                player.jump()
                
                dirtParticles(platformNode)
                // scoring
                // TODO: Decide if scoring should be based on blocks jumped on or blocks passed for future updates where there are powerups and enemies
                // Scoring
                if platformNode.scored == false && !platformNode.isBaseFloor {
                    platformNode.scored = true
                    scoreUpdate(true)
                }
            }
        } else if let springNode = otherBody.node as? Spring {
            // Ensure the player is landing on top of the spring
//            print("Player hit the spring!")
            
            // Perform a super jump
                player.springJump()
            
            // Optional: Add a bounce animation or particle effect for spring
            springNode.bounceEffect()
        }
    }
    
    // After collision end
    func didEnd(_ contact: SKPhysicsContact) {
        
    }

    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }
    
    // MARK: - Background assignments
    func createBg() {
        
        background = Background("background", CGSize(width: 620, height: 1400))
        addChild(background)
    }
    
    // MARK: - Platform Generation
    func createPlatform() {
        totalBlocks += 1
        var blockPos = CGPoint()
        var isMovingBlock = false;
        
        nextAddY = CGFloat.random(in: BlockValues.minSpawnY.rawValue...BlockValues.maxSpawnY.rawValue)
        
        if totalBlocks % 7 == 0 || totalBlocks % 15 == 0{
            blockPos = CGPoint(
                x: 0,
                y: platformY
            )
            isMovingBlock = true
        } else {
            blockPos = CGPoint(
                x: CGFloat.random(in: frame.minX + platformSize!.width + 40...frame.maxX - platformSize!.width - 40),
                y: platformY
            )
        }
        
        let block = Block(blockNames[(score / 100) % blockNames.count], platformSize!, blockPos, nextAddY)
        block.moving = isMovingBlock
        
        let currSeconds = Calendar.current.component(.second, from: Date())
        if !block.moving && (currSeconds == 30 || currSeconds == 58) {
            let spring = Spring(powerupNames[0], blockPos)
            addChild(spring)
        }
        
        addChild(block)
        blocks.append(block)

        block.moveSideToSide(frame.width)
        platformY += nextAddY
        
    }
    
    // MARK: - Starting Floor Generation
    func createBaseFloor(at position: CGPoint, _ size: CGSize) {
        let baseFloor = Block("base_floor", size, position, nextAddY)
        baseFloor.name = "floor"
        baseFloor.isBaseFloor = true // Mark it as the base floor for logic checks
        addChild(baseFloor)
    }
    
    // MARK: Score Display
    func createScoreLabel( at position: CGPoint) {
        scoreNode.name = "score"
        scoreNode.text = String(self.score)
        scoreNode.fontSize = 65
        scoreNode.fontColor = SKColor.darkGreen
        scoreNode.position = position
        scoreNode.zPosition = 1
        addChild(scoreNode)
    }
    
    // MARK: - Pause button assignments
    func createPauseButton() {
        pauseButton.name = "pauseButton"
        pauseButton.size = CGSize(width: 50, height: 50)
        pauseButton.position = CGPoint(x: 230, y: 0)
        pauseButton.zPosition = 1
        
        // make pause easier to tap on by adding an invisible node behind it
        let invisibleNode = SKSpriteNode(color: .clear, size: CGSize(width: 100, height: 100))
        invisibleNode.name = "pauseButtonTapArea"
        invisibleNode.position  = CGPoint(x: 0, y: 0)
        invisibleNode.zPosition = pauseButton.zPosition - 1
        pauseButton.addChild(invisibleNode)
        addChild(pauseButton)
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
    
    
    // MARK: - Update gravity (for fast falling)
    func fallingGravity() {
        if physicsWorld.gravity.dy == -4 {
            physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        }
    }
    
    // MARK: - Update gravity (for jumping)
    func jumpingGravity() {
        if physicsWorld.gravity.dy == -10 {
            physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        }
    }
    // MARK: - Particles only if the block isn't the base floor
    func dirtParticles(_ platformNode: Block) {
        if !platformNode.isBaseFloor {
            let dirtExplosion = SKEmitterNode(fileNamed: "DirtBounce")!
            dirtExplosion.position = platformNode.position
            dirtExplosion.position.y = dirtExplosion.position.y + 10
            
            dirtExplosion.zPosition = 2
            let explodeAction = SKAction.run({self.addChild(dirtExplosion)})
            let wait = SKAction.wait(forDuration: 1)
            let removeExplodeAction = SKAction.run({dirtExplosion.removeFromParent()})
            let sequence = SKAction.sequence([explodeAction, wait, removeExplodeAction])
            
            self.run(sequence)
        }
    }
    
    // MARK: - Score update
    func scoreUpdate(_ increment: Bool) {
        if(increment) {
            score+=1
            scoreNode.text = String(score)
        } else {
            score = 0
            scoreNode.text = String(score)
        }
    }
    
    func getScore() -> Int {
        return score
    }
    
    
    // MARK: - Starts the game
    func startGame() {
        isPaused = false
    }
    
    // MARK: - Pauses the game
    func pauseGame() {
        isPaused = !isPaused
        viewController?.pauseGame()
    }
    
    func resumeGame() {
        isPaused = false
    }
    
    func lossGame() {
        isPaused = true
        viewController?.lossGame()
    }
    
    // TODO: - Proper reset: RESETS score, camera, player, regenerates platforms, [recyle pause, scorelabelnode and background?]
    func resetGame() {
        firstTap = false
        scoreUpdate(false)
        for block in blocks {
            block.removeFromParent()
        }
        for child in self.children {
            if child is Spring {
                child.removeFromParent()
            }
        }
        blocks.removeAll()
        platformY = 210
        player.removeFromParent()
        
        player.addStartPlatform(size: player.size)
        cam.position = CGPoint(x: 0, y: 400)
        player.position = CGPoint(x: 0,
                                  y: (-(baseFloorSize!.height / 2)) + (player.size.height)
                                  + player.size.height + 10)
        addChild(player)
        
    }


}

