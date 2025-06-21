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
                SharedText(fontSize: 24, text: "Global High Score: \(viewModel.globalHighScore)", color: .white)
                    .padding(.bottom, 10)
                SharedText(fontSize: 24, text: "Your High Score: \(viewModel.highscore)", color: .white)
                    .padding(.bottom, 30)
                Divider()
                    .frame(height: 1)
                    .overlay(Color.white)
                    .padding(.horizontal, 40)
                    .opacity(1)
                SharedText(fontSize: 24, text: "Volume", color: .white)
                    .padding(.top, 30)
                
                Slider(
                    value: $volumeValue,
                    in: 0...1,
                    step: 0.1
                ) {
                    Text("Volume")
                } minimumValueLabel: {
                    Text("0")
                        .font(.custom("Arial", size: 24))
                        .foregroundColor(.white)
                } maximumValueLabel: {
                    Text("100")
                        .font(.custom("Arial", size: 24))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                .onChange(of: volumeValue) { _, newVal in
                    controller.setVolume(newVal)
                }
                .padding()
                .padding(.bottom, 30)
                SomeButton("Resume", backgroundColor: .bgBlue, foregroundColor: .white, borderColor: .white)
                    .onTapGesture {
                        onUnpause()
                    }
                    .padding(.bottom, 20)
                SomeButton("Quit to Menu", backgroundColor: .bgBlue, foregroundColor: .white, borderColor: .white)
                    .onTapGesture {
                        quitToMenu()
                    }
                    .padding(.bottom, 170)
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
