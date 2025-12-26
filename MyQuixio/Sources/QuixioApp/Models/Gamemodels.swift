// MyQuixio/Models/Gamemodels.swift

import Foundation

// ... (Player, Piece, GameMode enumsは変更なし) ...
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

enum AILevel: String, CaseIterable {
    case easy = "簡単"
    case medium = "普通"
    case hard = "難しい"
    case expert = "エキスパート"
    case ultimate = "アルティメット"
    #if DEBUG
        case forDataGeneration = "データ生成用" // UIには表示しない内部的なレベル
    #endif
    
    var iconName: String {
        switch self {
        case .easy:
            return "tortoise.fill"
        case .medium:
            return "figure.walk"
        case .hard:
            return "brain.head.profile"
        case .expert:
            return "crown.fill"
        case .ultimate:
            return "sparkles" // 究極AIのアイコン
        
        #if DEBUG
            case .forDataGeneration:
                return "shippingbox.fill" // 開発者向け機能のアイコン
        #endif
        }
    }
}
