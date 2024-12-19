//
//  ContentView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/9/24.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    var scene: SKScene {
        let scene = ScrollerModel(size: CGSize(width: 300, height: 844))
        scene.scaleMode = .resizeFill
        return scene
    }
    var body: some View {
            ZStack {
                // Display the SpriteKit scene
                SpriteView(scene: scene)
                    .ignoresSafeArea()

                // Add a pause button on top
                Button(action: {
                    // TODO: Implement pause functionality
                    print("Pause button tapped!")
                }) {
                    Image(systemName: "pause.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.black)
                }
                .position(x: UIScreen.main.bounds.width - 40, y: 10) // Position at the top-right
            }.navigationBarBackButtonHidden(true)
        }
}

#Preview {
    GameView()
}

