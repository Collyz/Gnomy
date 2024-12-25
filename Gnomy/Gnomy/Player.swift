//
//  Player.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/25/24.
//

import SpriteKit

class Player: SKSpriteNode {
    
    init(fileName: String, size: CGSize, position: CGPoint = CGPoint.zero) {
        let texture = SKTexture(imageNamed: fileName)
        super.init(texture: texture, color: .clear, size: size)
        

        self.name = "player"
        self.position = position
        self.zPosition = 0
        
        // Add physics
        self.physicsBody = SKPhysicsBody(texture: texture, size: size)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = true
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.restitution = 1
        self.physicsBody?.linearDamping = 3
        
        // Physics categories
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.platform
        self.physicsBody?.collisionBitMask = PhysicsCategory.platform
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func move(touching touch: CGPoint) {
        guard let touch = touch else { return }
        let speed = touch.x - position.x
        
    }
}
