//
//  MenuView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/15/24.
//

import SwiftUI
import SpriteKit
import CoreData
struct MenuView: View {
    @StateObject private var scoreDataStack = ScoreDataStack.shared
    var onStartTapped: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Your highscore!")
                SharedText(fontSize: 40, text: "Help him climb!", fontStyle: .title3, color: .white)
                    .bold()
                Spacer()
                SomeButton("Start!", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onStartTapped()
                    }
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
    MenuView { }
}
