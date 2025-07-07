// MyQuixio/Managers/GameService.swift を全体的に置き換え

import Foundation
import FirebaseFirestore


class GameService: ObservableObject {

    // MARK: - Properties
    @Published var game: GameSession?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var currentUserID: String { "player_id_\(UIDevice.current.name)" }
    var currentUserName: String { "Player_\(Int.random(in: 100...999))" }

    // MARK: - Matchmaking (async/await version)

    func findAndJoinGame() async throws {
        listener?.remove()
        
        let query = db.collection("games")
            .whereField("status", isEqualTo: GameStatus.waiting.rawValue)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        do {
            let snapshot = try await query.getDocuments()
            
            if let gameToJoinDoc = snapshot.documents.first {
                // 待機中のゲームに参加
                let gameToJoin = try gameToJoinDoc.data(as: GameSession.self)
                try await joinGame(gameToJoin)
            } else {
                // 待機中のゲームがなければ新規作成
                try await createNewGame()
            }
        }catch{
                // ▼▼▼【ここから修正】ネットワークエラーなどをキャッチして独自エラーをスローする ▼▼▼
                print("Error finding game: \(error.localizedDescription)")
                throw GameError.networkError(error)
                // ▲▲▲ 修正ここまで ▲▲▲
            }
            }

    private func createNewGame() async throws {
        let initialBoard = Array(repeating: "empty", count: 25)
        
        // ▼▼▼【修正点】`createdAt` を初期化時に追加 ▼▼▼
        let newGame = GameSession(
            board: initialBoard,
            hostPlayerID: self.currentUserID,
            hostPlayerName: self.currentUserName,
            status: .waiting,
            currentPlayerTurn: .host,
            createdAt: Timestamp() // 現在時刻を追加
        )
        // ▲▲▲ 修正ここまで ▲▲▲

        let newDocument = try db.collection("games").addDocument(from: newGame)
        print("New game created with ID: \(newDocument.documentID)")
        self.listenForGameChanges(gameID: newDocument.documentID)
    }

    private func joinGame(_ gameToJoin: GameSession) async throws {
        guard let gameID = gameToJoin.id else {
            throw GameError.gameNotFound
        }

        let updateData: [String: Any] = [
            "guestPlayerID": self.currentUserID,
            "guestPlayerName": self.currentUserName,
            "status": GameStatus.in_progress.rawValue
        ]
        do{
            try await db.collection("games").document(gameID).updateData(updateData)
            print("Successfully joined game: \(gameID)")
            self.listenForGameChanges(gameID: gameID)
        }catch{
            print("Error joining game: \(error.localizedDescription)")
                   throw GameError.couldNotJoinGame
        }
    }

    // MARK: - In-Game Actions (async/await version)

    func updateGame(board: [String], nextTurn: PlayerTurn) async {
        guard let gameID = game?.id else { return }
        let updateData: [String: Any] = ["board": board, "currentPlayerTurn": nextTurn.rawValue]
        
        do {
            try await db.collection("games").document(gameID).updateData(updateData)
        } catch {
            print("Error updating game: \(error.localizedDescription)")
        }
    }

    func endGame(winner: PlayerTurn) async {
        guard let gameID = game?.id else { return }
        let updateData: [String: Any] = ["winner": winner.rawValue, "status": GameStatus.finished.rawValue]

        do {
            try await db.collection("games").document(gameID).updateData(updateData)
        } catch {
            print("Error ending game: \(error.localizedDescription)")
        }
    }

    func leaveGame() async {
        guard let gameID = game?.id else { return }
        listener?.remove()
        do {
            try await db.collection("games").document(gameID).delete()
        } catch {
            print("Error leaving game: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Game State Listening (変更なし)
    private func listenForGameChanges(gameID: String) {
        self.listener = db.collection("games").document(gameID).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            do {
                self?.game = try document.data(as: GameSession.self)
            } catch {
                print("Error decoding game data: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        print("GameService deinitialized. Removing listener.")
        listener?.remove()
    }
}
