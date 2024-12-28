//
//  GameScene.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/20/24.
//

import SpriteKit
import GameplayKit
import AVFoundation

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
    private var platformY: CGFloat = -200
    private let nextAddY: CGFloat = 280
    private let blockNames: Array<String> = ["b_grass", "b_wood", "b_stone", "b_brick", "b_iron"]
    private var touchOffset: CGPoint?
    private let pregenerateBlocks: Int = 50
    private var platformSize: CGSize?
    private var baseFloorSize: CGSize?
    
    // Game Audio
    private var backgroundMusicPlayer: AVAudioPlayer? = nil
    
    // Player
    private let player = Player(fileName: "player", size: CGSize(width: 64, height: 64), position: CGPoint(x: 0, y: 0))
    
    // Nonplayer nodes
    private let cam = SKCameraNode()
    private let scoreNode = SKLabelNode(fontNamed: "Chalkduster")
    private var background: SKSpriteNode?
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
        // Set up the scene and player
        addChild(player)
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        camera = cam
        cam.position = CGPoint(x: 0, y: 400)
        createBackground()
        displayScore(at: CGPoint(x: frame.midX, y: frame.midY))
        addPauseButton()
        baseFloorSize = CGSize(width: self.bounds.width, height: 300)
        platformSize = CGSize(width: self.bounds.width/10, height: 30)

        // Generate the base floor
        generateBaseFloor(at: CGPoint(x: 0, y: platformY), baseFloorSize!) // draw floor at (0, -200)
        player.position = CGPoint(x: 0,
                                  y: (-(baseFloorSize!.height / 2)) + (player.size.height)
                                  + player.size.height + 10) // set player on top of floor
        platformY = 210 //found manually setting nextPlatformY
        
        // Generate initial platforms above the base floor
        while blocks.count < pregenerateBlocks {
            generatePlatform()
        }
        
        getAudio()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
        
        // Code block to update the touchOffset of the player
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let tappedNode = atPoint(loc)
        // Jump only on the first tap to the screen that isn't on the pause button
        if(tappedNode.name == "pauseButton") {
            pauseGame()
            playAudio()
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
        // lose if fall below cam
        if cam.position.y - (player.position.y - player.size.height) > (self.bounds.height / 2) + 100 {
            // TODO: insert pause functionality and loss screen/restart
            player.removeFromParent()
            resetGame()
        }
        
        // Update background,pausebutton, and score
        background!.position.y = cam.position.y
        scoreNode.position.y = cam.position.y + 500
        pauseButton.position.y = cam.position.y + 600
        
//        debugOutline.position.y = cam.position.y
        
        if let body = player.childNode(withName: "hitbox")?.physicsBody {
            let dy = body.velocity.dy
            if dy >= 0 {
                body.collisionBitMask = 0
            } else {
                body.collisionBitMask = PhysicsCategory.platform
            }
        }
        

    }
    
    override func didSimulatePhysics() {
        
    }

    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }
    
    // MARK: - Background assignments
    func createBackground() {
        // Background
        background = Background("background", CGSize(width: 620, height: 1400))
        addChild(background!)
    }
    
    // MARK: - Platform Generation
    func generatePlatform() {
        let blockPos = CGPoint(
            x: CGFloat.random(in: frame.minX + platformSize!.width...frame.maxX - platformSize!.width),
            y: platformY
        )
        
        let block = Block(
            blockNames[(score / 100) % blockNames.count],
            platformSize!,
            blockPos,
            nextAddY,
            &platformY
        )
        addChild(block)
        blocks.append(block)
    }
    
    // MARK: - Starting Floor Generation
    func generateBaseFloor(at position: CGPoint, _ size: CGSize) {
        let baseFloor = Block(blockNames[0], size, position, nextAddY, &platformY)
        baseFloor.name = "floor"
        baseFloor.isBaseFloor = true // Mark it as the base floor for logic checks
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
        if contact.contactNormal.dy > 0 {
            // Player is falling onto the platform
            player.jump()
            // scoring
            // TODO: Decide if scoring should be based on blocks jumped on or blocks passed for future updates where there are powerups and enemies

            if platformNode.scored == false && !platformNode.isBaseFloor {
                platformNode.scored = true
                score += 1
                scoreNode.text = String(score)
            }
        }
    }
    
    // After collision end
    func didEnd(_ contact: SKPhysicsContact) {
        
    }
    
    // TODO: - Proper reset: RESETS score, camera, player, regenerates platforms, [recyle pause, scorelabelnode and background?]
    func resetGame() {
        pauseGame()
        score = 0
        for block in blocks {
            block.scored = false
        }
        pauseGame()
        scoreNode.text = String(score)
        player.resignFirstResponder()
        cam.position = CGPoint(x: 0, y: 400)
        player.position = CGPoint(x: 0, y: 0)
        addChild(player)
        firstTap = false
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
    
    
    // MARK: Gets the audio file and makes sure the audio isn't nil
    func getAudio() {
        guard let musicURL = Bundle.main.url(forResource: "bg_sound_1", withExtension: "wav") else {
            print("music file not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
            backgroundMusicPlayer!.numberOfLoops = -1 // infinite loop
            backgroundMusicPlayer!.prepareToPlay()
            backgroundMusicPlayer!.volume = 0.5
            playAudio()
        } catch {
            print("failed to initialize AVAudioPlayer: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - Audio play/pause
    func playAudio() {
        if !backgroundMusicPlayer!.isPlaying {
            backgroundMusicPlayer!.play()
        } else {
            backgroundMusicPlayer!.pause()
        }
    }
    
    // MARK: - Pauses the game
    func pauseGame() {
        isPaused = !isPaused
        
    }


}

