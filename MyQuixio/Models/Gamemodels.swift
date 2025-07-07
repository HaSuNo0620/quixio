// MARK: - GameModels.swift

import Foundation

enum Player: Equatable {
    case circle
    case cross
}

enum Piece: Equatable {
    case empty
    case mark(Player)
}

enum GameMode {
    case vsHuman
    case vsAI
}
// CaseIterable を追加
enum AILevel: String, CaseIterable, Identifiable {
    case easy = "Easy (ランダム)"
    case normal = "Normal (攻防一体)"
    case hard = "Hard (先読み)"
    
    var id: String { self.rawValue }
}
