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
                SharedText(fontSize: 20, text: "Global High Score: \(viewModel.globalHighScore)", fontStyle: .title, color: .white)
                SharedText(fontSize: 20, text: "High Score: \(viewModel.highScore)", fontStyle: .title, color: .white)
                SharedText(fontSize: 40, text: "Help him climb!", fontStyle: .title3, color: .white)
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
    @Previewable @State var previewViewModel = GameViewModel(context: .init())
    MenuView(viewModel: previewViewModel, onStartTapped: {})
}
