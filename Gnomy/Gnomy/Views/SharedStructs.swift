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
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    
    init(_ buttonLabel: String, backgroundColor: Color, foregroundColor: Color, borderColor: Color) {
        self.buttonLabel = buttonLabel
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
    }
    
    var body: some View {
        Text(buttonLabel)
            .font(.custom("Century Gothic", size: 35))
            .font(.largeTitle)
            .padding(.horizontal, 25)
            .padding(.vertical, 0)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 3))
            .shadow(radius: 10)
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
            .font(.custom("Arial", size: fontSize))
            .foregroundColor(fontColor)
    }
}
