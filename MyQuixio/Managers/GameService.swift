// Managers/GameService.swift

import Foundation
import FirebaseFirestore

class GameService: ObservableObject {
    
    // MARK: - Properties
    @Published var game: GameSession?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // 仮のユーザー情報（将来的に認証機能で置き換えます）
    private var currentUserID: String { "player_id_\(UIDevice.current.name)" }
    private var currentUserName: String { "Player_\(Int.random(in: 100...999))" }

    // MARK: - Matchmaking
    
    /// マッチメイキングを開始または待機中のゲームに参加します。
    func findAndJoinGame() {
        // まずはリスナーをクリア
        listener?.remove()
        
        // "waiting"状態のゲームを検索
        let query = db.collection("games")
            .whereField("status", isEqualTo: GameStatus.waiting.rawValue)
            .limit(to: 1)
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, !documents.isEmpty else {
                // 待機中のゲームがない場合は、新しいゲームを作成する
                print("No waiting games found. Creating a new one.")
                self?.createNewGame()
                return
            }
            
            // 待機中のゲームが見つかった場合
            if let gameToJoin = try? documents.first?.data(as: GameSession.self) {
                print("Found a game to join: \(gameToJoin.id ?? "N/A")")
                self.joinGame(gameToJoin)
            }
        }
    }

    /// 新しいゲームセッションを作成し、待機状態に入ります。
    private func createNewGame() {
        let initialBoard = Array(repeating: "empty", count: 25)
        
        let newGame = GameSession(
            board: initialBoard,
            hostPlayerID: self.currentUserID,
            guestPlayerID: nil,
            hostPlayerName: self.currentUserName,
            guestPlayerName: nil,
            status: .waiting,
            currentPlayerTurn: .host,
            winner: nil,
            createdAt: Timestamp()
        )
        
        do {
            let newDocument = try db.collection("games").addDocument(from: newGame)
            print("New game created with ID: \(newDocument.documentID)")
            // 作成したゲームの変更を監視開始
            self.listenForGameChanges(gameID: newDocument.documentID)
        } catch {
            print("Error creating new game: \(error.localizedDescription)")
        }
    }

    /// 既存の待機中ゲームに参加します。
    private func joinGame(_ gameToJoin: GameSession) {
        guard let gameID = gameToJoin.id else { return }
        
        // 自分の情報をゲストとして更新
        let updateData: [String: Any] = [
            "guestPlayerID": self.currentUserID,
            "guestPlayerName": self.currentUserName,
            "status": GameStatus.in_progress.rawValue
        ]
        
        db.collection("games").document(gameID).updateData(updateData) { error in
            if let error = error {
                print("Error joining game: \(error.localizedDescription)")
                return
            }
            print("Successfully joined game: \(gameID)")
            // 参加したゲームの変更を監視開始
            self.listenForGameChanges(gameID: gameID)
        }
    }
    
    // MARK: - Game State Listening
    
    /// 指定されたゲームIDのドキュメント変更をリアルタイムで監視します。
    private func listenForGameChanges(gameID: String) {
        self.listener = db.collection("games").document(gameID).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            do {
                // 変更があるたびに、@Publishedのgameプロパティを更新
                self?.game = try document.data(as: GameSession.self)
                print("Game data updated. Status: \(self?.game?.status.rawValue ?? "N/A")")
            } catch {
                print("Error decoding game data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        // このクラスが破棄されるときに、リスナーを必ず解放する
        print("GameService deinitialized. Removing listener.")
        listener?.remove()
    }

        // MARK: - In-Game Actions
        
        /// 盤面の状態と次の手番をFirestoreに更新します。
        func updateGame(board: [String], nextTurn: PlayerTurn) {
            guard let gameID = game?.id else {
                print("Error: Game ID is missing.")
                return
            }
            
            let updateData: [String: Any] = [
                "board": board,
                "currentPlayerTurn": nextTurn.rawValue
            ]
            
            db.collection("games").document(gameID).updateData(updateData) { error in
                if let error = error {
                    print("Error updating game: \(error.localizedDescription)")
                } else {
                    print("Game successfully updated.")
                }
            }
        }
}
