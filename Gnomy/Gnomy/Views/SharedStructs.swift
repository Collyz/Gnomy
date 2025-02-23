//
//  SharedStructs.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 2/19/25.
//

import SwiftUI
import SpriteKit

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

struct SharedText: View {
    let fontSize: CGFloat
    let text: String
    let fontColor: Color
    
    init(fontSize: CGFloat, text: String, color: Color){
        self.fontSize = fontSize
        self.text = text
        self.fontColor = color
    }
    
    var body: some View {
        Text(text)
            .font(.custom("Chalkduster", size: fontSize))
            .foregroundColor(fontColor)
    }
}
