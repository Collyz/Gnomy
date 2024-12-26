//
//  Player.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/25/24.
//

import SpriteKit

class Player: SKSpriteNode {
    private let moveSpeed: CGFloat = 4;
    
    init(fileName: String, size: CGSize, position: CGPoint = CGPoint.zero) {
        let texture = SKTexture(imageNamed: fileName)
        super.init(texture: texture, color: .clear, size: size)
        

        self.name = "player"
        self.position = position
        self.zPosition = 2
        
        // Add physics
        self.physicsBody = SKPhysicsBody(texture: texture, size: size)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = true
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.restitution = 0
        self.physicsBody?.linearDamping = 1
        
        // Physics categories
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.platform // Detect contact with platforms
        self.physicsBody?.collisionBitMask = PhysicsCategory.platform // Allow physical collision with platforms
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
