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
    @ObservedObject var viewModel: GameViewModel
    @State private var username: String = ""
    @State private var validUsername: Bool = true
    @State private var existingUsername: Bool = true
    var onStartTapped: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if viewModel.username != "Guest" {
                Spacer()
                Spacer()
                if viewModel.highScore == 0 {
                    SharedText(fontSize: 30, text: "Welcome \(viewModel.username)!", color: .white)
                        .padding(.bottom, 10)
                } else {
                    SharedText(fontSize: 30, text: "Welcome back, \(viewModel.username)!", color: .white)
                        .padding(.bottom, 10)
                }
                SharedText(fontSize: 20, text: "Top Scores!", color: .white)
                    .underline().offset(y: -5)
                ForEach(viewModel.players.prefix(3)) { player in
                    SharedText(fontSize: 20, text: "\(player.name): \(player.score)", color: .white)
                }
                Text("\n")
                SharedText(fontSize: 25, text: "Your High Score: \(viewModel.highScore)", color: .white)
                Spacer()
                Text("\n")
                SomeButton("Start!", backgroundCOlor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onStartTapped()
                }
            } else {
                TextField("Enter a username", text: self.$username)
                    .font(.system(size: 24)) // Increase font size
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5))) // background color
                    .foregroundColor(.white) // Text color
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                    .onSubmit {
                        print("User pressed Enter, trying to saving username: \(self.username)")
                        viewModel.SetUsernameFromUser(tryName: self.username)
                    }
                // Error message from viewmodel
                SharedText(fontSize: 20, text: viewModel.usernameError, color: .white)
                Spacer()
                Spacer()
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

#Preview {
    @Previewable @State var previewHighScore: Int64 = 0
    @Previewable @State var previewGlobalHighScore: Int64 = 0
    @Previewable @State var previewViewModel = GameViewModel(context: .preview)
    MenuView(viewModel: previewViewModel, onStartTapped: {})
}
