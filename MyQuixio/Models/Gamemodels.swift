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
enum AILevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    // ▼▼▼【ここから追加】▼▼▼
    // 各レベルに対応するアイコン名を定義
    var iconName: String {
        switch self {
        case .easy:
            return "tortoise.fill" // 亀（簡単）
        case .medium:
            return "figure.walk" // 人（普通）
        case .hard:
            return "brain.head.profile" // 脳（難しい）
        }
    }
    // ▲▲▲ 追加ここまで ▲▲▲
}
