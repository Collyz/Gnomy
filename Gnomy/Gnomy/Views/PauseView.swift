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

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 20, text: "Global High Score: \(viewModel.globalHighScore)", color: .white)
                Text("\n")
                SharedText(fontSize: 20, text: "Your High Score: \(viewModel.highScore)", color: .white)
                Text("\n")
                SharedText(fontSize: 24, text: "Master Volume", color: .white)
                Slider(
                    value: $volumeValue,
                    in: 0...1,
                    step: 0.1
                ) {
                    Text("Volume")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("100")
                }
                .padding()
                .onChange(of: volumeValue) { _, newVal in
                    controller.setVolume(newVal)
                }
                Spacer()
                SomeButton("Resume", backgroundCOlor: .bgBlue, foregroundColor: .white, borderColor: .white)
                    .onTapGesture {
                        onUnpause()
                    }
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
              volumeValue: $previewVolumeValue) {}
}
