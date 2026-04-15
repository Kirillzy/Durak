//
//  Game.swift
//  Durak
//
//  Created by Kirill Zhurbytskyy on 4/15/26.
//

import SwiftUI
import DeckOfPlayingCards
import PlayingCard

struct Game: View {
    @StateObject private var viewModel = GameViewModel()
    
    // Updated to 2 columns for pairs on the table
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Helper to calculate how much cards should overlap
    // As the hand grows, we increase the negative spacing to keep cards visible
    private func dynamicSpacing(for count: Int) -> CGFloat {
        if count <= 6 { return -30 } // Default overlap
        if count <= 10 { return -45 } // Start crunching
        return -55 // Max crunch for huge large hands
    }

    // Helper to slightly shrink cards if the hand is huge
    private func dynamicScale(for count: Int) -> CGFloat {
        return count > 12 ? 0.85 : 1.0
    }
    
    var body: some View {
        ZStack {
            // Dark green "Poker Table" background
            Color.green.mix(with: .black, by: 0.2).ignoresSafeArea()
            
            GeometryReader { geometry in
                let tableWidth = geometry.size.width * 0.8
                let tableHeight = geometry.size.height * 0.7
                
                // AI HAND (TOP)
                ScrollView(.horizontal, showsIndicators: false) {
                    // Spacing and Scale now react to the number of cards so they dont go off screen
                    HStack(spacing: dynamicSpacing(for: viewModel.aiHand.count)) {
                        ForEach(0..<viewModel.aiHand.count, id: \.self) { _ in
                            CardBack()
                                .scaleEffect(dynamicScale(for: viewModel.aiHand.count))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(width: geometry.size.width, height: 120)
                // Positioned near the top of the screen
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.08)

                // THE TABLE (CENTER)
                ZStack(alignment: .bottomTrailing) {
                    // Table Surface
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color.brown.mix(with: .black, by: 0.35))
                    
                    HStack(spacing: 10) {
                        // PLAY AREA
                        ScrollView(.vertical, showsIndicators: false) {
                            // 2-column grid to show pairs side-by-side
                            LazyVGrid(columns: columns, spacing: 25) {
                                ForEach(0..<viewModel.tableCards.count, id: \.self) { i in
                                    // ZStack allows the defense card to sit on top of the attack card
                                    ZStack(alignment: .topLeading) {
                                        CardView(card: viewModel.tableCards[i].attack)
                                        
                                        if let defenseCard = viewModel.tableCards[i].defense {
                                            CardView(card: defenseCard)
                                                .offset(x: 18, y: 18) // Offset creates the "covered" look
                                        }
                                    }
                                    .frame(height: 110)
                                }
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))

                        // SIDEBAR: Deck, Discard, and Controls
                        VStack(spacing: 15) {
                            // Visual representation of the discard pile
                            ZStack {
                                if !viewModel.discardPile.isEmpty {
                                    CardBack()
                                        .rotationEffect(.degrees(-5))
                                        .opacity(0.4)
                                }
                            }
                            .frame(height: 100)
                            
                            // The Deck and the Trump Card (horizontal at the bottom)
                            ZStack(alignment: .trailing) {
                                if let trump = viewModel.trumpCard {
                                    CardView(card: trump)
                                        .rotationEffect(.degrees(90))
                                        .offset(x: 15, y: 0)
                                }
                                
                                // Show the card back if there are cards left in the deck
                                if viewModel.deck.count > 0 || viewModel.trumpCard != nil {
                                    CardBack()
                                        .overlay(
                                            // Displays remaining cards (Deck + the Trump Card itself)
                                            Text("\(viewModel.deck.count + (viewModel.trumpCard != nil ? 1 : 0))")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                                        )
                                }
                            }
                            .frame(height: 100)

                            // PLAYER ACTIONS (PASS for attacker, TAKE for defender)
                            if viewModel.attacker == "Player" {
                                Button(action: { viewModel.playerPasses() }) {
                                    Text("PASS")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 35)
                                        .background(viewModel.tableCards.isEmpty || viewModel.isProcessing ? Color.gray : Color.orange)
                                        .cornerRadius(8)
                                }
                                .disabled(viewModel.tableCards.isEmpty || viewModel.isProcessing)
                            } else {
                                Button(action: { viewModel.playerTakesCards() }) {
                                    Text("TAKE")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 35)
                                        .background(viewModel.isProcessing ? Color.gray : Color.red)
                                        .cornerRadius(8)
                                }
                                .disabled(viewModel.isProcessing)
                            }
                            // AI Action Log
                            Text(viewModel.aiStatusText)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .frame(height: 30)
                            Spacer().frame(height: 40)
                        }
                        .frame(width: 100)
                        .padding(.vertical, 20)
                    }
                    .padding(15)
                    
                    // Display current role (Attacker) and the Trump suit
                    statusBadgeView
                }
                .frame(width: tableWidth, height: tableHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.5)
                
                // 3. PLAYER HAND (BOTTOM)
                VStack(spacing: 5) {
                    if viewModel.isProcessing {
                        Text("AI is thinking...")
                            .font(.caption2.italic())
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        // Dynamic spacing and scale applied so card dont go off screen
                        HStack(spacing: dynamicSpacing(for: viewModel.playerHand.count)) {
                            ForEach(viewModel.playerHand, id: \.self) { card in
                                CardView(card: card)
                                    .scaleEffect(dynamicScale(for: viewModel.playerHand.count))
                                    .opacity(viewModel.isProcessing ? 0.6 : 1.0)
                                    .onTapGesture {
                                        if !viewModel.isProcessing {
                                            withAnimation(.spring()) {
                                                viewModel.playCard(card)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .frame(width: geometry.size.width, height: 150)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.92)
            }
            
            // Win/Loss Overlay
            if viewModel.isGameOver, let winner = viewModel.winner {
                GameOverOverlay(winner: winner) {
                    viewModel.setupGame()
                }
            }
        }
        .onAppear {
            viewModel.setupGame()
        }
    }
    
    // UI component for the turn indicator and trump suit info
    private var statusBadgeView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(viewModel.attacker == "Player" ? "ATTACKER" : "DEFENDER")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(viewModel.attacker == "Player" ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            
            HStack(spacing: 4) {
                Text("Trump:")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Text(viewModel.trumpSuit?.description ?? "None")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 15)
        .padding(.bottom, 15)
    }
}

#Preview {
    Game()
}
