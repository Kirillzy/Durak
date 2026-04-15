//
//  DurakDeck.swift
//  Durak
//
//  Created by Kirill Zhurbytskyy on 4/15/26.
//

import DeckOfPlayingCards
import PlayingCard

// We want our specific deck from the standard 52 to take values 5 and below out (except Ace)
// This will be the deck we use for our Durak games.
func durakDeck() -> Deck { // Returns a Deck object
    var tempDeck = Deck.standard52CardDeck()
    var allCards: [PlayingCard] = []
    
    // 1. Pull all cards out of the deck object
    // We do this because the tempDecks cards are not allowed to be peaked at, but we want to peak at it
    while let card = tempDeck.deal() {
        allCards.append(card)
    }
    
    // 2. Filter the array (Cards 6-14 are 6-Ace)
    let filteredCards = allCards.filter { card in
        card.rank.rawValue >= 6
    }
    
    return Deck(filteredCards.shuffled()) // Re-wrap in a Deck
}

func durakRank(_ rank: Int) -> String {
  switch rank {
  case 14: return "ace"
  case 11: return "jack"
  case 12: return "queen"
  case 13: return "king"
  default:
    return "\(rank)"
  }
}

// If we want to deal out our durakDeck, we would do durakCards.deal()

// To check for if the card could be placed down, we would check for if suits are equals and val is higher than table
