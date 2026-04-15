Durak SwiftUI

This game is my own personal spin and implementation of a game I played growing up called Durak, where I learned from my parents (An Eastern European card game). This app of mine is entirely in SwiftUI, where it should dynamically size to fit to each persons screen so that it could be played against the AI. 

Project Team

    Lead Developer: Just me.


What the App Does: 
    
    The app allows a single player to engage in a game of Durak against an AI opponent.

    Core Mechanics: Supports attacking, defending, and trump card logic.

    Adaptive/Dynamic UI: Cards automatically "crunch" together and scale down as your hand grows to ensure the game remains playable on mobile screens.

    Visuals: Features a 2-column "pairs" grid for the play area and a status badge to track roles and the current trump suit, as well as the AI status message to signal to the player what it has done.


Setup - Getting the game ready

    Open the project in Xcode.

    No dependences are needed.

    Just click to run the simulator (CMD+R) or the start play button on the top left corner


How to Play

    Setup

        Each player starts with 6 cards.

        The card dealt after the initial hands is the Trump Card. Its suit becomes the "Trump Suit," which beats all other suits regardless of rank.

    Roles

        There are two roles: Attacker and Defender. The player with the lowest-ranking Trump card in their hand starts as the first Attacker.

    The Attacker's Goal

    The Attacker tries to get rid of cards by playing them into the center.

        First Move: You can play any card (starting with your lowest non-Trump card is recommended).

        Follow-up Attacks: You can only attack with cards that match the rank of any card already on the table. (Example: If there is a 6 and an 8 on the table, you can only play other 6s or 8s).

        Passing: If you cannot or do not want to attack anymore, you Pass. All cards on the table are moved to the discard pile, your turn ends, and you become the Defender for the next round.

    The Defender's Goal

    The Defender must "beat" every card the Attacker plays.

        Matching Suit: You can beat a card by playing a higher-ranking card of the same suit.

        Using Trumps: If the Attacker plays a non-Trump card, you can beat it with any Trump card. If the Attacker plays a Trump card, you must beat it with a higher-ranking Trump.

        Taking: If you cannot (or choose not to) defend, you must Take. All cards on the table are added to your hand. If you take, you skip your next turn to attack and must defend again.

    Turn Structure & Drawing

        After each turn, players draw back up to 6 cards from the deck.

        The Attacker draws first, then the Defender.

        If you already have 6 or more cards (from "Taking"), you do not draw.

    How the Game Ends

    Once the draw pile is empty, the game enters the end phase. The goal is to be the first to empty your hand.

        Win: You empty your hand before the AI.

        Loss: The AI empties its hand before you.

        Draw: Both you and the AI play your final cards on the same turn.
