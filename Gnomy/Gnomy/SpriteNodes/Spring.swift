//
//  Spring.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/5/25.
//

import SpriteKit
class Spring: SKSpriteNode{
    public var usedUp: Bool = false
    
    init(_ filename: String, _ position: CGPoint)
    {
        let texture = powerupAtlas.textureNamed(filename)
        texture.filteringMode = .nearest
        
        let size = CGSize(width: 32, height: 32)
        
        super.init(texture: texture, color: .clear, size: size)
        self.name = "spring"
//        self.scale(to: size)
        self.position = position
        
        // position the powerup above the block position
        self.position.y = self.position.y + 32

        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.restitution = 0
        
        // Set physics category
        self.physicsBody?.categoryBitMask = PhysicsCategory.powerup
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect player contact
        self.physicsBody?.collisionBitMask = PhysicsCategory.player // Allow collision with the player
        
        self.texture!.filteringMode = .nearest
        self.zPosition = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Optional: Visual bounce effect
    func bounceEffect() {
        let bounce = SKAction.sequence([
            SKAction.scaleY(to: 2, duration: 0.2),
            SKAction.scaleY(to: 1.0, duration: 0.2)
        ])
        self.run(bounce)
    }
    
}
