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
    @State private var highscore: Int64 = 0
    @State private var hasUsername: Bool = false
//    @State private var username: String = ""
//    @State private var validUsername: Bool = true
//    @State private var existingUsername: Bool = true
    
    var onStartTapped: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            if hasUsername {
                SharedText(fontSize: 30, text: "Welcome \n \(viewModel.username)!", color: .white)
                    .padding(.bottom, 10)
                SharedText(fontSize: 25, text: "Your High Score: \(highscore)", color: .white)
                                    .padding(.bottom, 30)

                SomeButton("Start!", backgroundColor: Color.bgBlue, foregroundColor: Color.white, borderColor: Color.white)
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
                        playerInfoStack.saveUsername(username)
                    }
                    
                // Error message from viewmodel
                SharedText(fontSize: 20, text: viewModel.usernameError, color: .white)
                    .padding(.bottom, 300)
            }
            Spacer()
        }.background(
            Image("background")
                .resizable()
                .scaledToFill()
        )
        .ignoresSafeArea()
        .onAppear {
            var info = playerInfoStack.fetchPlayerInfo()
            username = info.username ?? "Guest"
            highscore = info.score as! Int64
        }
    }
}

#Preview {
    @Previewable @State var previewHighScore: Int64 = 0
    @Previewable @State var previewGlobalHighScore: Int64 = 0
    @Previewable @State var previewViewModel = GameViewModel()
    MenuView(viewModel: previewViewModel, onStartTapped: {})
}
