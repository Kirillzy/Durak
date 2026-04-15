//
//  SimulateGame.swift
//  Durak
//
//  Created by Kirill Zhurbytskyy on 4/19/26.
//

import SwiftUI
import Combine
import DeckOfPlayingCards
import PlayingCard

class GameViewModel: ObservableObject {
    // @Published tells SwiftUI: "Reload any view using this if these change."
    @Published var deck: Deck = durakDeck()
    @Published var playerHand: [PlayingCard] = []
    @Published var aiHand: [PlayingCard] = []
    @Published var tableCards: [(attack: PlayingCard, defense: PlayingCard?)] = []
    
    // We treat this as the "bottom" card
    @Published var trumpCard: PlayingCard?
    
    @Published var attacker: String = "" // "Player" or "AI"
    
    @Published var isProcessing: Bool = false // Locks the UI
    @Published var isGameOver: Bool = false
    @Published var winner: String? = nil
    
    @Published var discardPile: [PlayingCard] = []
    
    // Persistent property to remember the suit after the card is taken
    @Published var trumpSuit: Suit? = nil
    
    @Published var aiStatusText: String = "" // Tracks AI's last move
    
    // Logic lives here, not in the View
    
    // Sets up the game
    func setupGame() {
        // Reset state for new game
        trumpSuit = nil // Change
        playerHand.removeAll()
        aiHand.removeAll()
        tableCards.removeAll()
        discardPile.removeAll()
        isGameOver = false
        winner = nil
        
        // Cards are already shuffled when we get the our deck = durakDeck(),
        // but we redo it since we wanna start over
        deck = durakDeck()
        
        // Deal 6 cards first
        for _ in 0..<6 {
            if let c = deck.deal() {
                playerHand.append(c)
            }
            if let c = deck.deal() {
                aiHand.append(c)
            }
        }
        
        // Set the trump card but we dont put it back due to the DeckOfPlayingCards constraint.
        // It stays in this variable until the deck is empty.
        if let lastCard = deck.deal() {
            trumpCard = lastCard
            // New change since game state forgets the suit at the end
            trumpSuit = lastCard.suit
        }
        
        // Determine who starts (Lowest Trump)
        determineFirstAttacker()
        
        // Ensure AI starts if it is the determined attacker
        if attacker == "AI" {
            triggerAITurn()
        }
    }
    
    
    // inout allows to change the function that was passed in instead of read-only
    private func refillHand(hand: inout [PlayingCard]) {
        while hand.count < 6 {
            if let card = deck.deal() {
                hand.append(card)
            }
            else if let finalCard = trumpCard {
                // Deck is empty! The next person who needs a card takes the trump.
                hand.append(finalCard)
                trumpCard = nil // It's finally taken
                break
            }
            else {
                // Deck AND trump card are both gone
                break
            }
        }
    }
    
    
    func playCard(_ card: PlayingCard) {
        // Prevents player spamming cards while AI is "thinking"
        guard !isProcessing else { return }
        
        if attacker == "Player" {
            // ATTACK LOGIC: Put a new card on the table
            if (canAttack(with: card)) {
                tableCards.append((attack: card, defense: nil))
                playerHand.removeAll { $0 == card }
                
                // Player has attacked, so the AI must defend
                triggerAITurn()
            }
        } else {
            // DEFENSE LOGIC: Find the first attack card that isn't defended yet
            if let index = tableCards.firstIndex(where: { $0.defense == nil }) {
                if (canDefend(attackCard: tableCards[index].attack, defenseCard: card)) {
                    tableCards[index].defense = card
                    playerHand.removeAll { $0 == card }
                    
                    // Player defended, now AI might want to thow in some more cards
                    triggerAITurn()
                }
            }
        }
        checkForWinner()
    }
    
    
    // Deals cards to the attacker and defender to make sure they are at 6 cards at least, unless deck is empty
    func dealCards() {
        // Attacker draws first, then defender
        if attacker == "Player" {
            refillHand(hand: &playerHand)
            refillHand(hand: &aiHand)
        } else {
            refillHand(hand: &aiHand)
            refillHand(hand: &playerHand)
        }
    }
    
    
    // This function is only called by setupGame, so at the start, and no other function needs to call it
    private func determineFirstAttacker() {
        guard let trump = trumpSuit else { return }
        // Filters by first only having the values that are the trump suit, and then map gets the min out of those.
        // 99 would be used if there was no trump cards.
        let playerMinTrump = playerHand.filter { $0.suit == trump }.map { $0.rank.rawValue }.min() ?? 99
        let aiMinTrump = aiHand.filter { $0.suit == trump }.map { $0.rank.rawValue }.min() ?? 99
        
        attacker = (playerMinTrump < aiMinTrump) ? "Player" : "AI"
    }
    
    
    func canAttack(with card: PlayingCard) -> Bool {
        // Rule: If table is empty, anything goes.
        // If not, card rank must match something already on the table.
        if tableCards.isEmpty { return true }
        
        let ranksOnTable = tableCards.flatMap { [$0.attack.rank, $0.defense?.rank].compactMap { $0 } }
        return ranksOnTable.contains(card.rank)
    }
    
    
    func canDefend(attackCard: PlayingCard, defenseCard: PlayingCard) -> Bool {
        guard let trump = trumpSuit else { return false }
        
        // 1. Same suit, higher rank
        if defenseCard.suit == attackCard.suit && defenseCard.rank.rawValue > attackCard.rank.rawValue {
            return true
        }
        
        // 2. Defense is Trump, Attack is not
        if defenseCard.suit == trump && attackCard.suit != trump {
            return true
        }
        
        return false
    }
    
    
    func defenderTakesTable() {
        // 1. Add all cards from the table to the defender's hand
        for pair in tableCards {
            if attacker == "Player" {
                aiHand.append(pair.attack)
                if let def = pair.defense { aiHand.append(def) }
            } else {
                playerHand.append(pair.attack)
                if let def = pair.defense { playerHand.append(def) }
            }
        }
        tableCards.removeAll()
        
        // 2. Refill attacker's hand only (Defender already took cards)
        // dealCards() - Actually we dont need this since we handle that in refill hand
        
        // 3. In Durak, if you take cards, you DON'T become the attacker.
        // The person to your left (or the same attacker) goes again.
        // (In 2-player, the attacker stays the attacker).
    }
    
    
    func endTurn(defenderTookCards: Bool) {
        if !defenderTookCards {
            // Cards go to discard pile (visual logic)
            // Instead of just clearing, move them to the discard pile
            for pair in tableCards {
                discardPile.append(pair.attack)
                if let def = pair.defense { discardPile.append(def) }
            }
            tableCards.removeAll()
        } else {
            // Defender adds all table cards to hand
            defenderTakesTable()
        }
        
        // REFILL PHASE
        dealCards()
        
        // Switch roles if defenderTookCard is false
        if (!defenderTookCards) {
            attacker = (attacker == "Player") ? "AI" : "Player"
        }
        
        // If it's now the AI's turn to start an attack:
        if attacker == "AI" {
            triggerAITurn()
        }
        checkForWinner()
    }
    
    
    func triggerAITurn() {
        // Refined guard to allow AI to start the game as attacker since previously that didnt work
        guard !isGameOver else { return }
        
        isProcessing = true // Lock UI immediately when AI starts its 1.5s "thinking"
        //aiStatusText = "AI is thinking..." - Not needed since it does it at the bottom already
        
        // Simulating "Thinking" time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.attacker == "AI" {
                self.aiAttack()
            }
            else if self.attacker == "Player" && self.tableCards.contains(where: { $0.defense == nil }) {
                self.aiDefend()
            }
            else {
                // If neither condition is met, release the lock
                self.isProcessing = false
            }
            // isProcessing is set to false inside aiAttack/aiDefend
        }
    }
    

    private func aiAttack() {
        // Find all playable cards
        let playable = aiHand.filter { canAttack(with: $0) }
        
        // Priority: Lowest Rank, Non-Trump first
        let sorted = playable.sorted { c1, c2 in
            let t = trumpCard?.suit
            if c1.suit == t && c2.suit != t { return false }
            if c1.suit != t && c2.suit == t { return true }
            return c1.rank.rawValue < c2.rank.rawValue
        }
        
        if let cardToPlay = sorted.first {
            // Logic to move card to table
            tableCards.append((attack: cardToPlay, defense: nil))
            aiHand.removeAll { $0 == cardToPlay }
            
            // After AI attacks, it waits for Player to defend
            // The "Loop" happens because once the player defends,
            // triggerAITurn() is called again, bringing us back here.
            isProcessing = false
            aiStatusText = "AI attacked"
            
        } else {
            // AI has no more cards to play or chooses to stop
            endTurn(defenderTookCards: false)
            isProcessing = false
            aiStatusText = "AI passed"
        }
    }

    
    private func aiDefend() {
        // Find the undefended card
        guard let index = tableCards.firstIndex(where: { $0.defense == nil }) else { return }
        let toBeat = tableCards[index].attack
        
        // Find lowest card that can beat it
        let playable = aiHand.filter { canDefend(attackCard: toBeat, defenseCard: $0) }
        let sorted = playable.sorted { $0.rank.rawValue < $1.rank.rawValue }
        
        if let cardToPlay = sorted.first {
            tableCards[index].defense = cardToPlay
            aiHand.removeAll { $0 == cardToPlay }
            
            isProcessing = false
            aiStatusText = "AI defended"
            
            // After defending, AI waits for Player to attack again or end turn
        } else {
            // AI cannot defend, must take cards
            endTurn(defenderTookCards: true)
            isProcessing = false
            aiStatusText = "AI took the cards"
        }
    }
    
    
    // For the "Pass" or "Done" button in SwiftUI
    func playerPasses() {
        // Guard against processing and ensure it's actually the player's turn to pass
        guard !isProcessing, attacker == "Player", !tableCards.isEmpty else { return }
        endTurn(defenderTookCards: false)
    }

    // For the "Take Cards" button
    func playerTakesCards() {
        // Guard against processing and ensure player is the one defending
        guard !isProcessing, attacker == "AI" else { return }
        endTurn(defenderTookCards: true)
    }
    
    
    private func checkForWinner() {
        // In Durak, you can only win if the deck (and trump card) is empty
        guard deck.count == 0 && trumpCard == nil else { return }
        
        if playerHand.isEmpty && aiHand.isEmpty {
            winner = "Draw"
            isGameOver = true
        }
        else if playerHand.isEmpty {
            winner = "Player"
            isGameOver = true
        }
        else if aiHand.isEmpty {
            winner = "AI"
            isGameOver = true
        }
    }
    
}
