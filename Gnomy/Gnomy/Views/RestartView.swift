//
//  RestartView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//


import SwiftUI
import SpriteKit

struct RestartView: View {
    @ObservedObject var viewModel: GameViewModel
    @State var controller: GameViewController
    var onRestart: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 30, text: "Global High Score: \(viewModel.globalHighScore)", fontStyle: .largeTitle, color: .white)
                Text("")
                SharedText(fontSize: 30, text: "High Score: \(viewModel.highScore)", fontStyle: .largeTitle, color: .white)
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
    @Previewable @State var previewViewModel = GameViewModel(context: .preview)
    let controller = GameViewController()
    RestartView(viewModel: previewViewModel,
                controller: controller ) {}
}
