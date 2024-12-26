//
//  Block.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/23/24.
//
import SpriteKit
class Block: SKSpriteNode{
    public var scored: Bool = false;
    public var isBaseFloor: Bool = false;
    
    init(_ filename: String, _ size: CGSize, _ position: CGPoint, _ nextAddY: CGFloat, _ platformY: inout CGFloat)
    {
        let texture = SKTexture(imageNamed: filename)
        super.init(texture: texture, color: .clear, size: size)
        
        self.name = "platform"
        self.scale(to: size)
        self.position = position
        platformY += nextAddY

        // Add physics to the platform
        // Add physics to only the top of the platform
        let topLeftPoint = CGPoint(x: -size.width / 2, y: size.height / 2) // Top-left relative to the platform
        let topRightPoint = CGPoint(x: size.width / 2, y: size.height / 2) // Top-right relative to the platform
        self.physicsBody = SKPhysicsBody(edgeFrom: topLeftPoint, to: topRightPoint)
        self.physicsBody?.isDynamic = false // Static platform
        self.physicsBody?.restitution = 0 // No bounce
        
        // Set physics category
        self.physicsBody?.categoryBitMask = PhysicsCategory.platform
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect player contact
        self.physicsBody?.collisionBitMask = PhysicsCategory.player // Allow collision with the player
        
        self.texture!.filteringMode = .nearest
        self.zPosition = 1
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
