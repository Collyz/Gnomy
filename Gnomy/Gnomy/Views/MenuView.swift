//
//  MenuView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/15/24.
//

import SwiftUI
import SpriteKit
import CoreData
struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    var onStartTapped: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Top Scores!")
                    .font(.custom("Chalkduster", size: 20))
                    .foregroundColor(.white)
                    .underline().offset(y: -5)
                ForEach(viewModel.players.prefix(3)) { player in
                    SharedText(fontSize: 15, text: "\(player.name): \(player.score)", fontStyle: .title, color: .white)
                }
                Text("\n")
                SharedText(fontSize: 20, text: "Your High Score: \(viewModel.highScore)", fontStyle: .title, color: .white)
                Text("\n")
                SharedText(fontSize: 40, text: "Go climb!", fontStyle: .title3, color: .white).underline()
                    .bold()
                Spacer()
                SomeButton("Start!", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onStartTapped()
                    }
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
    MenuView(viewModel: previewViewModel, onStartTapped: {})
}
