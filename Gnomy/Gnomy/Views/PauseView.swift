//
//  PauseView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//

import SwiftUI
import SpriteKit

struct PauseView: View {
    @ObservedObject var viewModel: GameViewModel
    @State var controller: GameViewController
    @Binding var volumeValue: Float
    var onUnpause: () -> Void
    var quitToMenu: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 20, text: "Global High Score: \(viewModel.globalHighScore)", color: .white)
                    .padding()
                SharedText(fontSize: 20, text: "Your High Score: \(viewModel.highscore)", color: .white)
                    .padding()
                SharedText(fontSize: 24, text: "Master Volume", color: .white)
                Slider(
                    value: $volumeValue,
                    in: 0...1,
                    step: 0.1
                ) {
                    Text("Volume")
                } minimumValueLabel: {
                    Text("0")
                        .font(.custom("Chalkduster", size: 24))
                        .foregroundColor(.white)
                } maximumValueLabel: {
                    Text("100")
                        .font(.custom("Chalkduster", size: 24))
                        .foregroundColor(.white)
                }
                .padding()
                .onChange(of: volumeValue) { _, newVal in
                    controller.setVolume(newVal)
                }
                .padding()
                SomeButton("Resume", backgroundColor: .bgBlue, foregroundColor: .white, borderColor: .white)
                    .onTapGesture {
                        onUnpause()
                    }
                    .padding(.bottom, 50)
                SomeButton("Quit to Menu", backgroundColor: .bgBlue, foregroundColor: .white, borderColor: .white)
                    .onTapGesture {
                        quitToMenu()
                    }
                    .padding(.bottom, 250)
            }
            .background(
                Image("background")
                    .resizable()
                    .scaledToFill()
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    @Previewable @State var previewViewModel = GameViewModel(context: .preview)
    @Previewable @State var previewVolumeValue: Float = 0.5
    
    PauseView(viewModel: previewViewModel,
              controller: GameViewController(),
              volumeValue: $previewVolumeValue) {} quitToMenu: {}
}
