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
                SharedText(fontSize: 24, text: "Global High Score: \(viewModel.globalHighScore)", color: .white)
                Text("\n")
                SharedText(fontSize: 24, text: "High Score: \(viewModel.highScore)", color: .white)
                Text("\n")
                SharedText(fontSize: 24, text: "Score: \(controller.currScore())", color: .white)
                Text("\n")
                SomeButton("Restart", backgroundColor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
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
