//
//  GnomyGame.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/16/24.
//

import Foundation
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
            super.viewDidLoad()

            if let view = self.view as! SKView? {
                // Load the ScrollerModel scene
                let scene = ScrollerModel(size: view.bounds.size)
                scene.scaleMode = .aspectFill

                // Present the scene
                view.presentScene(scene)
                view.ignoresSiblingOrder = true
            }
        }
}
