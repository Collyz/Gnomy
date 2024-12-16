//
//  ScrollerModel.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/16/24.
//

import Foundation
import SpriteKit

class ScrollerModel: SKScene {

    override func didMove(to view: SKView) {
            // Set up the scene when it’s first presented
            let player = SKSpriteNode(imageNamed: "player.png")
            player.position = CGPoint(x: size.width / 2, y: size.height / 2)
            player.name = "player"  // Give the sprite a name
            addChild(player)
        }
    
    
}
