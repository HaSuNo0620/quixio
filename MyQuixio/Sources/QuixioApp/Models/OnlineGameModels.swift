// Models/OnlineGameModels.swift

import Foundation
import FirebaseFirestore

enum GameEndReason: String, Codable {
    case victory     // 通常の勝利
    case disconnection // 相手の切断
}

// Firestoreのドキュメントに対応するモデル
struct GameSession: Codable, Identifiable {
    @DocumentID var id: String?
    var board: [String]
    
    let hostPlayerID: String
    var guestPlayerID: String?
    
    let hostPlayerName: String
    var guestPlayerName: String?
    
    var status: GameStatus
    var currentPlayerTurn: PlayerTurn
    var winner: PlayerTurn?
    var endReason: GameEndReason? // ▼▼▼【ここを追加】▼▼▼
    
    let createdAt: Timestamp
    
    // CodingKeysにも追加
    enum CodingKeys: String, CodingKey {
        case id
        case board
        case hostPlayerID
        case guestPlayerID
        case hostPlayerName
        case guestPlayerName
        case status
        case currentPlayerTurn
        case winner
        case endReason // ▼▼▼【ここを追加】▼▼▼
        case createdAt
    }
}

extension GameSession {
    func myTurn(for userID: String) -> PlayerTurn? {
        if hostPlayerID == userID {
            return .host
        } else if guestPlayerID == userID {
            return .guest
        }
        return nil
    }
}

// 文字列で状態を管理するためのenum
enum GameStatus: String, Codable {
    case waiting      // プレイヤーを待っている状態
    case in_progress  // ゲーム進行中
    case finished     // ゲーム終了
}

// どちらのプレイヤーのターンか
enum PlayerTurn: String, Codable {
    case host   // ホストプレイヤー (Circle)
    case guest  // ゲストプレイヤー (Cross)
}
