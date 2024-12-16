//
//  MenuView.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 12/15/24.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("title")
                .resizable()
                .scaledToFit()
                .padding(15)
            Text("Help him get home!")
                .font(.title3)
                .bold()
            Spacer()
            
            Button {
                // TODO: Start Game
            } label: {
                Text("Start!")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 25)
                    .padding(.vertical, 0)
            }.background(
                Capsule(style: .circular)
                    .fill(Color("playBtn"))
            )
            Spacer()
        }.background(Color("DarkGreen"))
    }
}

#Preview {
    MenuView()
}
