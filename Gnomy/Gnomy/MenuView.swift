//
//  MenuView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/15/24.
//

import SwiftUI
import SpriteKit

struct MenuView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Help him get home!")
                    .font(.title3)
                    .bold()
                NavigationLink(destination: GameView()) {
                    Text("Start!")
                        .foregroundStyle(Color("DarkGreen"))
                        .bold()
                        .font(.largeTitle)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 0)
                        .background(Color.yellow)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 10)
                        .padding(.bottom, 175)
                        .padding(.top, 220)
                }
            }.background(
                Image("menuBg")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.07)
            )
            .ignoresSafeArea()
        }
        }
}

#Preview {
    MenuView()
}
