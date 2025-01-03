//
//  Player.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/25/24.
//

import SpriteKit

class Player: SKSpriteNode {
    private let moveSpeed: CGFloat = 4;
    private var feetHitBox: SKSpriteNode!
    
    init(fileName: String, size: CGSize, position: CGPoint = CGPoint.zero) {
        let texture = SKTexture(imageNamed: fileName)
        super.init(texture: texture, color: .clear, size: size)
        

        self.name = "player"
        self.position = position
        self.zPosition = 2
        
        // TODO: REMOVE player hitbox *FOR NOW* so weird jumps don't occur
        // Add physics
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = true
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.restitution = 0
        self.physicsBody?.linearDamping = 1
        
        // Physics categories
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.none // Detect contact with platforms
        self.physicsBody?.collisionBitMask = PhysicsCategory.none // Allow physical collision with platforms
        
        // Add a thin hitbox for the player's feet
        addFeetHitbox(size: size)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Add a thin hitbox to the player's feet
    private func addFeetHitbox(size: CGSize) {
        let hitboxHeight: CGFloat = 5 // Thin hitbox height
        let hitboxSize = CGSize(width: size.width * 0.8, height: hitboxHeight) // Slightly smaller than the player's width
        feetHitBox = SKSpriteNode(color: .clear, size: hitboxSize) // Invisible hitbox
        feetHitBox.name = "hitbox"
        feetHitBox.position = CGPoint(x: 0, y: -size.height / 2 - hitboxHeight / 2) // Just below the player's main body
        feetHitBox.zPosition = self.zPosition - 1

        feetHitBox.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
        feetHitBox.physicsBody?.isDynamic = false // Static physics body
        feetHitBox.physicsBody?.categoryBitMask = PhysicsCategory.none // Same category as the player
        feetHitBox.physicsBody?.contactTestBitMask = PhysicsCategory.none // Detect contact with platforms
        feetHitBox.physicsBody?.collisionBitMask = PhysicsCategory.none // No collisions, only contacts

        self.addChild(feetHitBox) // Add the hitbox as a child node of the player
    }
    
    // MARK: - Based on the distance from the player and the touch, move the player
    func move(touching touch: CGPoint?) {
        guard let touch = touch else { return }
        let dist = touch.x - position.x
        physicsBody?.velocity = CGVector(dx: dist * moveSpeed, dy: physicsBody?.velocity.dy ?? 0)
    }
    
    // MARK: - Player jump
    func jump() {
        guard let velocity = self.physicsBody?.velocity else { return }
        if velocity.dy <= 0 { // Only allow jumping if falling or stationary
            self.physicsBody?.velocity = CGVector(dx: velocity.dx, dy: 0) // Reset vertical velocity
            self.physicsBody?.velocity = CGVector(dx: velocity.dx, dy: 800) // Reset vertical velocity
        }
    }

}
