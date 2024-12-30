//
//  MenuView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/15/24.
//

import SwiftUI
import SpriteKit

struct MenuView: View {
    var onStartTapped: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Help him climb!")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color.black)
                SomeButton("Start!", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onStartTapped()
                    }
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
    MenuView { }
}
