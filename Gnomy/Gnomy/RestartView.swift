//
//  RestartView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//


import SwiftUI
import SpriteKit

struct RestartView: View {
    var onRestart: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SomeButton("Restart", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
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

#Preview {
    
    PauseView {
        
    }
}
