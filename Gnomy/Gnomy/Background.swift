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
    
    init(_ filename: String, _ size: CGSize, position: CGPoint = CGPoint.zero) {
        let texture = SKTexture(imageNamed: filename)
        super.init(texture: texture, color: .clear, size: size)
        
        self.name = "background"
        self.size = size
        self.position = position
        self.zPosition = 0
        
        
        // Create hitboxes for the left and right sides
        let hitboxWidth: CGFloat = 1 // Thin hitboxes
        setHitbox(&rightHitBox, CGSize(width: hitboxWidth, height: size.height),
                  CGPoint(x: size.width / 2 - hitboxWidth / 2 + 40, y: 0), "rightHitbox")
        setHitbox(&leftHitBox, CGSize(width: hitboxWidth, height: size.height),
                  CGPoint(x: -size.width / 2 + hitboxWidth / 2 - 40, y: 0), "leftHitbox")
        
        self.texture!.filteringMode = .nearest
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setHitbox(_ node: inout SKSpriteNode,_ size: CGSize, _ position: CGPoint, _ name: String) {
        node = SKSpriteNode(color: .clear, size: size)
        node.name = name
        node.position = position
        node.zPosition = 1
        
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
