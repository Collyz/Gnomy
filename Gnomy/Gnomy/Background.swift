//
//  Background.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/27/24.
//
//
//  Player.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/25/24.
//

import SpriteKit

class Background: SKSpriteNode{
    private var rightHitBox: SKSpriteNode = SKSpriteNode()
    private var leftHitBox: SKSpriteNode = SKSpriteNode()
    
//    init(_ filename: String, _ size: CGSize)
//    {
//        let texture = SKTexture(imageNamed: filename)
//        super.init(texture: texture, color: .clear, size: size)
//        
//        self.name = "background"
//        self.scale(to: size)
//        self.position = position
//        self.zPosition = -1
//        self.scale(to: size)
//        self.texture!.filteringMode = .nearest
//        
//        // TODO: Remove commented out edgeloop physics body for background
////        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
////        self.physicsBody?.isDynamic = false // Static platform
////        self.physicsBody?.restitution = 0 // No bounce
////        self.physicsBody?.linearDamping = 0
////        self.physicsBody?.friction = 0
//        
//        // Set physics category
////        self.physicsBody?.categoryBitMask = PhysicsCategory.none
////        self.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect player contact
////        self.physicsBody?.collisionBitMask = PhysicsCategory.player // Allow collision with the player
////        
//        
//        // Hollow outline for background to keep player inside of it
//        let hitboxWidth: CGFloat = 1
//        setHitbox(node: &rightHitBox, size: CGSize(width: hitboxWidth, height: size.height),
//                  position: CGPoint(x: size.width / 2 - hitboxWidth / 2, y: 0), name: "rightHitbox")
//        setHitbox(node: &leftHitBox, size: CGSize(width: hitboxWidth, height: size.height),
//                  position: CGPoint(x: -size.width / 2 + hitboxWidth / 2, y: 0), name: "leftHitbox")
//        
//    }
    
    init(_ filename: String, _ size: CGSize, position: CGPoint = CGPoint.zero) {
        let texture = SKTexture(imageNamed: filename)
        super.init(texture: texture, color: .clear, size: size)
        
        self.name = "background"
        self.size = size
        self.position = position
        self.zPosition = -1
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Default anchor point
        
        // Create hitboxes for the left and right sides
        let hitboxWidth: CGFloat = 1 // Thin hitboxes
        setHitbox(&rightHitBox, CGSize(width: hitboxWidth, height: size.height),
                  CGPoint(x: size.width / 2 - hitboxWidth / 2, y: 0), "rightHitbox")
        setHitbox(&leftHitBox, CGSize(width: hitboxWidth, height: size.height),
                  CGPoint(x: -size.width / 2 + hitboxWidth / 2, y: 0), "leftHitbox")
        
        self.texture!.filteringMode = .nearest
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setHitbox(_ node: inout SKSpriteNode,_ size: CGSize, _ position: CGPoint, _ name: String) {
        node = SKSpriteNode(color: .clear, size: size)
        node.name = name
        node.position = position
        node.zPosition = -1
        
        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.restitution = 0
        node.physicsBody?.linearDamping = 0
        node.physicsBody?.friction = 0
        
        node.physicsBody?.categoryBitMask = PhysicsCategory.none
        node.physicsBody?.contactTestBitMask = PhysicsCategory.player
        node.physicsBody?.collisionBitMask = PhysicsCategory.player
        self.addChild(node)
    }
}
