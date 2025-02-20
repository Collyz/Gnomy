//
//  RestartView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//


import SwiftUI
import SpriteKit

struct RestartView: View {
    @Binding var highScore: Int64
    @Binding var globalHighScore: Int64
    @State var controller: GameViewController
    var onRestart: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 30, text: "Global High Score: \(globalHighScore)", fontStyle: .largeTitle, color: .white)
                Text("")
                SharedText(fontSize: 30, text: "High Score: \(highScore)", fontStyle: .largeTitle, color: .white)
                Text("")
                SharedText(fontSize: 30, text: "Score: \(controller.currScore())", fontStyle: .largeTitle, color: .white)
                Text("")
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
    @Previewable @State var previewHighScore: Int64 = 0
    @Previewable @State var previewGlobalHighScore: Int64 = 0
    let controller = GameViewController()
    RestartView(highScore: $previewHighScore,
                globalHighScore: $previewGlobalHighScore,
                controller: controller) {

    }
}
