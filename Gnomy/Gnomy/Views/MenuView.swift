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
    @StateObject private var playerInfoStack = PlayerInfoStack.shared
    @ObservedObject var viewModel: GameViewModel
    @State private var username: String = ""
    @State private var hasUsername: Bool = false
//    @State private var username: String = ""
//    @State private var validUsername: Bool = true
//    @State private var existingUsername: Bool = true
    
    var onStartTapped: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if hasUsername {
                SharedText(fontSize: 30, text: "Welcome back, \(viewModel.username)!", color: .white)
                    .padding(.bottom, 10)
                
                SharedText(fontSize: 25, text: "Your High Score: \(viewModel.highscore)", color: .white)
                    .padding(.bottom, 30)

                SomeButton("Start!", backgroundColor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
                    .onTapGesture {
                        onStartTapped()
                    }
            } else {
                TextField("Enter a username", text: $username)
                    .font(.system(size: 24))
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.5)))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                    .onSubmit {
                        hasUsername = viewModel.saveUsername(username)
                    }

                SharedText(fontSize: 20, text: "Enter your username to begin", color: .white)
                    .padding(.bottom, 25)
            }
                    
                // Error message from viewmodel
                SharedText(fontSize: 20, text: viewModel.usernameError, color: .red)
                .padding(.horizontal, 25)
                .padding(.bottom, 250)
            
            Spacer()
        }.background(
            Image("background")
                .resizable()
                .scaledToFill()
        )
        .ignoresSafeArea()
        .onAppear {
            let info = playerInfoStack.fetchPlayerInfo()
            if info.username != "" {
                hasUsername = true
            }
            viewModel.fetchUsername()
            viewModel.fetchHighScore()
        }
    }
}

#Preview {
    @Previewable @State var previewGlobalHighScore: Int64 = 0
    @Previewable @State var previewViewModel = GameViewModel()
    MenuView(viewModel: previewViewModel, onStartTapped: {})
}
