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
                Text("Help him home!")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color.black)
                Text("Start!")
                    .foregroundStyle(Color.black)
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
