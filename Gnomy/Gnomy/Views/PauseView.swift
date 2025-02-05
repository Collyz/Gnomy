//
//  PauseView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//

import SwiftUI
import SpriteKit

struct PauseView: View {
    @State var controller: GameViewController
    @Binding var volumeValue: Float
    var onUnpause: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Master Volume")
                    .font(.custom("ChalkDuster", size: 24))
                    .font(.title)
                    .foregroundColor(.white)
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


struct SomeButton: View {
    let buttonLabel: String
    let backgroundCOlor: Color
    let foregroundColor: Color
    let borderColor: Color
    
    init(_ buttonLabel: String, backgroundCOlor: Color, foregroundColor: Color, borderColor: Color) {
        self.buttonLabel = buttonLabel
        self.backgroundCOlor = backgroundCOlor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
    }
    
    var body: some View {
        Text(buttonLabel)
            .font(.custom("Chalkduster", size: 35))
            .font(.largeTitle)
            .padding(.horizontal, 25)
            .padding(.vertical, 0)
            .foregroundColor(foregroundColor)
            .background(backgroundCOlor)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 3))
            .shadow(radius: 10)
            .padding(.bottom, 175)
            
            
    }
}

#Preview {
    @Previewable @State var previewVolumeValue: Float = 0.5
    PauseView(controller: GameViewController(), volumeValue: $previewVolumeValue) {
        
    }
}
