// Models/OnlineGameModels.swift

import Foundation
import FirebaseFirestore

// Firestoreのドキュメントに対応するモデル
struct GameSession: Codable, Identifiable {
    @DocumentID var id: String? // FirestoreのドキュメントIDを自動でマッピング
    
    var board: [String] // "empty", "circle", "cross" のような文字列で管理
    
    let hostPlayerID: String
    var guestPlayerID: String?
    
    let hostPlayerName: String
    var guestPlayerName: String?
    
    var status: GameStatus
    var currentPlayerTurn: PlayerTurn
    var winner: PlayerTurn?
    
    let createdAt: Timestamp // Firebaseが提供する日時型
    
    // CodingKeysを使って、Swiftのプロパティ名とFirestoreのフィールド名を一致させる
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
        case createdAt
    }
}

// 文字列で状態を管理するためのenum
enum GameStatus: String, Codable {
    case waiting      // ゲスト参加待ち
    case in_progress  // 対戦中
    case finished     // 対戦終了
}

enum PlayerTurn: String, Codable {
    case host
    case guest
}
