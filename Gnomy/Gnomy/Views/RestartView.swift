//
//  RestartView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//


import SwiftUI
import SpriteKit

struct RestartView: View {
    var highScore: Int64
    @State var controller: GameViewController
    var onRestart: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 50, text: "High Score: \(highScore)", fontStyle: .largeTitle, color: .white)
                Text("")
                SharedText(fontSize: 50, text: "Score: \(controller.currScore())", fontStyle: .largeTitle, color: .white)
                Spacer()
                SomeButton("Restart", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onRestart()
                    }
                Spacer()
            }.background(
                Image("background")
                    .resizable()
                    .scaledToFill()
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let controller = GameViewController()
    RestartView(highScore: 0, controller: controller) {

    }
}
