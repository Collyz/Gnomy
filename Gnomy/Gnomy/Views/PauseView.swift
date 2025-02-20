//
//  PauseView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//

import SwiftUI
import SpriteKit

struct PauseView: View {
    var highScore: Int64
    @State var controller: GameViewController
    @Binding var volumeValue: Float
    var onUnpause: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SharedText(fontSize: 30, text: "High Score: \(highScore)", fontStyle: .title, color: .white)
                SharedText(fontSize: 24, text: "Master Volume", fontStyle: .title, color: .white)
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
    @Previewable @State var previewVolumeValue: Float = 0.5
    PauseView(highScore: 0, controller: GameViewController(), volumeValue: $previewVolumeValue) {}
}
