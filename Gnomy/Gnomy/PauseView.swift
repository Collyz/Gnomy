//
//  PauseView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//

import SwiftUI
import SpriteKit

struct PauseView: View {
    var onUnpause: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SomeButton("Resume", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onUnpause()
                    }
                Spacer()
            }.background(
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.07)
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
            .padding(.top, 220)
    }
}

#Preview {
    
    PauseView {
        
    }
}
