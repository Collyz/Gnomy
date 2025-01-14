//
//  RestartView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/29/24.
//


import SwiftUI
import SpriteKit

struct RestartView: View {
    @State var controller: GameViewController
    var onRestart: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Score: \(controller.currScore())")
                    .font(.custom("Chalkduster", size: 50))
                    .font(.largeTitle)
                    .foregroundStyle(Color.white)
                SomeButton("Restart", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onRestart()
                    }
                Spacer()
            }.background(
                Image("background")
                    .resizable()
                    .scaledToFill()
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let controller = GameViewController()
    RestartView(controller: controller) {

    }
}
