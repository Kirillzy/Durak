//
//  SubCardViews.swift
//  Durak
//
//  Created by Kirill Zhurbytskyy on 4/19/26.
//

import SwiftUI
import PlayingCard
import DeckOfPlayingCards

struct SubCardViews: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}



// MARK: - Card Back View
struct CardBack: View {
    var body: some View {
        Image("face-down")
            .resizable()
            .aspectRatio(contentMode: .fit) // added
            .frame(width: 70, height: 100)
            .background(Color.blue) // added
            .cornerRadius(6) // added
            .shadow(radius: 4)
    }
}

// MARK: - Individual Card View
struct CardView: View {
    let card: PlayingCard
    
    var body: some View {
        Image("\(durakRank(card.rank.rawValue))_of_\(card.suit.rawValue)")
            .resizable()
            .aspectRatio(contentMode: .fit) // added
            .frame(width: 70, height: 100)
            .background(Color.white) // added
            .cornerRadius(6) // added
            .shadow(radius: 4)
    }
}

// MARK: - Game Controls
struct GameControlsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            if viewModel.attacker == "Player" {
                // PASS: Only if cards are on table and AI isn't "thinking"
                actionButton(title: "PASS", color: .orange, disabled: viewModel.tableCards.isEmpty || viewModel.isProcessing) {
                    viewModel.playerPasses()
                }
            }
            else {
                // TAKE: Only if player is defending
                actionButton(title: "TAKE", color: .red, disabled: viewModel.isProcessing) {
                    viewModel.playerTakesCards()
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    func actionButton(title: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 40)
                    .background(disabled ? Color.gray.opacity(0.5) : color)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            .disabled(disabled)
        }
}

// MARK: - Game Over Screen
struct GameOverOverlay: View {
    let winner: String
    let resetAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 30) {
                Text(winner == "Player" ? "Victory!" : "Durak!")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(winner == "Player" ? .yellow : .red)
                                
                Text(winner == "Player" ? "The AI was no match." : "You've been left with the cards.")
                    .foregroundColor(.white)
                                
                Button("Play Again") {
                    resetAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }
}


#Preview {
    CardBack()
}
