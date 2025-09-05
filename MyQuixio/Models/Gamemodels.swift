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

enum AILevel: String, CaseIterable {
    case easy = "簡単"
    case medium = "普通"
    case hard = "難しい"
    // ▼▼▼【ここから追加】▼▼▼
    case expert = "エキスパート"
    // ▲▲▲ 追加ここまで ▲▲▲
    
    var iconName: String {
        switch self {
        case .easy:
            return "tortoise.fill"        // 亀（簡単）
        case .medium:
            return "figure.walk"          // 人（普通）
        case .hard:
            return "brain.head.profile"   // 脳（難しい）
        // ▼▼▼【ここから追加】▼▼▼
        case .expert:
            return "crown.fill"           // 王冠（エキスパート）
        // ▲▲▲ 追加ここまで ▲▲▲
        }
    }
    // ▲▲▲ 追加ここまで ▲▲▲
}
