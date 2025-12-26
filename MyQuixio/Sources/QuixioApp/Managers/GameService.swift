// MyQuixio/Managers/GameService.swift を全体的に置き換え

import Foundation
import FirebaseFirestore
import FirebaseDatabase
import Combine

class GameService: ObservableObject {

    // MARK: - Properties
    @Published var game: GameSession?
    @Published var isOpponentOnline: Bool = true
    @Published var opponentReconnectRemaining: Int?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var opponentConnectionHandle: DatabaseHandle?
    private var reconnectCountdownTimer: Timer?

    var currentUserID: String {
            let userIDKey = "myQuixio.persistentUserID"
            
            // UserDefaultsに保存されたIDがあればそれを返す
            if let savedID = UserDefaults.standard.string(forKey: userIDKey) {
                return savedID
            }
            
            // なければ新しいUUIDを生成して保存し、それを返す
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: userIDKey)
            print("Generated and saved new persistent user ID: \(newID)")
            return newID
        }

    var currentUserName: String {
        let userNameKey = "myQuixio.persistentUserName"
        
        if let savedName = UserDefaults.standard.string(forKey: userNameKey) {
            return savedName
        }
        
        let newName = "Player_\(Int.random(in: 100...999))"
        UserDefaults.standard.set(newName, forKey: userNameKey)
        return newName
    }

    // MARK: - Matchmaking (async/await version)
    
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

    // joinGameをトランザクション内で実行できるよう、引数にtransactionオブジェクトを追加

    func findAndJoinGame() async throws {
        listener?.remove()

        let query = db.collection("games")
            .whereField("status", isEqualTo: GameStatus.waiting.rawValue)
            .whereField("hostPlayerID", isNotEqualTo: currentUserID)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        if let gameToJoinDoc = snapshot.documents.first {
            let gameID = gameToJoinDoc.documentID
            print("Found a game to join: \(gameID). Attempting to join via transaction.")

            do {
                // async/awaitに対応したトランザクションを実行
                try await db.runTransaction { (transaction, errorPointer) -> Void in
                    let gameRef = self.db.collection("games").document(gameID)
                    
                    // 1. トランザクション内でドキュメントを読み込む
                    let gameDocument: DocumentSnapshot
                    do {
                        gameDocument = try transaction.getDocument(gameRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return
                    }

                    // 2. 読み込んだゲームがまだ "waiting" 状態か再確認
                    guard let gameData = try? gameDocument.data(as: GameSession.self),
                          gameData.status == .waiting else {
                        // すでに他の誰かが参加していた場合、エラーを作成してトランザクションを失敗させる
                        let raceConditionError = NSError(
                            domain: "AppErrorDomain",
                            code: 409, // 409 Conflict
                            userInfo: [NSLocalizedDescriptionKey: "Failed to join the game due to a race condition. Please try again."]
                        )
                        errorPointer?.pointee = raceConditionError
                        return
                    }
                    
                    // 3. ゲームが参加可能なら、ゲスト情報を更新
                    let updateData: [String: Any] = [
                        "guestPlayerID": self.currentUserID,
                        "guestPlayerName": self.currentUserName,
                        "status": GameStatus.in_progress.rawValue
                    ]
                    transaction.updateData(updateData, forDocument: gameRef)
                }
                
                // トランザクションが成功した場合のみ、リスナーを開始
                print("Transaction successful. Joined game: \(gameID)")
                self.listenForGameChanges(gameID: gameID)

            } catch {
                // トランザクションが失敗した場合（競合が発生した場合など）
                print("Transaction failed: \(error.localizedDescription). Trying to find another game.")
                // マッチメイキングを再試行する
                try await self.findAndJoinGame()
            }

        } else {
            // 参加できるゲームがなければ、新しいゲームを作成
            print("No waiting games found. Creating a new one.")
            try await createNewGame()
        }
    }

    // 以前の private func joinGame(...) は不要になるので削除しても構いません。
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

    func endGame(winner: PlayerTurn, reason: GameEndReason = .victory) async {
        stopMonitoringOpponentConnection() // 監視を停止
        guard let gameID = game?.id else { return }
        let updateData: [String: Any] = [
            "winner": winner.rawValue,
            "status": GameStatus.finished.rawValue,
            "endReason": reason.rawValue
        ]

            do {
                try await db.collection("games").document(gameID).updateData(updateData)
            } catch {
                print("Error ending game: \(error.localizedDescription)")
            }
        }


    func leaveGame() async {
        stopMonitoringOpponentConnection()
        // 自分がどちらのプレイヤーか判定
        guard let gameID = game?.id,
              let myPlayerId = game?.hostPlayerID == currentUserID ? PlayerTurn.host : (game?.guestPlayerID == currentUserID ? PlayerTurn.guest : nil)
        else {
            return
        }
        listener?.remove() // リスナーを解除
        
        // 相手プレイヤーを勝者としてゲームを終了させる
        let winner: PlayerTurn = (myPlayerId == .host) ? .guest : .host
        let updateData: [String: Any] = [
            "winner": winner.rawValue,
            "status": GameStatus.finished.rawValue,
            "endReason": GameEndReason.disconnection.rawValue // 終了理由を「切断」にする
        ]

        do {
            // ドキュメントを削除するのではなく、更新する
            try await db.collection("games").document(gameID).updateData(updateData)
        } catch {
            print("Error leaving game: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Game State Listening
    private func listenForGameChanges(gameID: String) {
           // 既存のリスナーがあれば解除してから新しいリスナーを設定
           listener?.remove()
           
           self.listener = db.collection("games").document(gameID).addSnapshotListener { [weak self] documentSnapshot, error in
               
               // 1. スナップショット取得時にエラーがあれば、コンソールに出力して処理を中断
               if let error = error {
                   print("Error fetching document snapshot: \(error.localizedDescription)")
                   return
               }
               
               // 2. ドキュメントが存在し、データがあることを確認
               guard let document = documentSnapshot, document.exists else {
                   print("Document does not exist or has been deleted.")
                   // ドキュメントが削除された場合、ローカルのゲームもnilにする
                   DispatchQueue.main.async {
                       self?.game = nil
                   }
                   return
               }
               
               // 3. do-catchブロックでデコードを試みる
               do {
                   // デコードを試み、成功したらメインスレッドでgameプロパティを更新
                   let decodedGame = try document.data(as: GameSession.self)
                   DispatchQueue.main.async {
                       self?.game = decodedGame
                       if decodedGame.status == .in_progress {
                           self?.monitorOpponentConnection()
                       } else {
                           self?.stopMonitoringOpponentConnection()
                       }
                   }
               } catch {
                   // デコードに失敗した場合、エラーの詳細をコンソールに出力
                   print("Error decoding game data: \(error.localizedDescription)")
                   // デコードに失敗した場合は、安全のためにローカルのゲームをnilにする
                   DispatchQueue.main.async {
                       self?.game = nil
                   }
               }
           }
       }

    private func monitorOpponentConnection() {
        guard let game = game, let opponentID = getOpponentID() else { return }
        
        // 既存の監視があれば停止
        stopMonitoringOpponentConnection()
        
        print("Starting to monitor opponent: \(opponentID)")
        opponentConnectionHandle = ConnectionService.shared.observeConnection(for: opponentID) { [weak self] isOnline in
            guard let self = self, self.game?.status == .in_progress else { return }

            if isOnline {
                print("Opponent \(opponentID) is online.")
                DispatchQueue.main.async {
                    self.isOpponentOnline = true
                    self.opponentReconnectRemaining = nil
                }
                self.stopReconnectCountdown()
            } else {
                print("Opponent \(opponentID) went offline. Starting 30-second timer.")
                DispatchQueue.main.async {
                    self.isOpponentOnline = false
                    self.startReconnectCountdown()
                }
            }
        }
    }
    
    private func stopMonitoringOpponentConnection() {
        if let handle = opponentConnectionHandle, let opponentID = getOpponentID() {
            print("Stopping opponent monitoring for: \(opponentID)")
            ConnectionService.shared.removeObserver(with: handle, for: opponentID)
            self.opponentConnectionHandle = nil
        }
        stopReconnectCountdown()
        DispatchQueue.main.async {
            self.isOpponentOnline = true
            self.opponentReconnectRemaining = nil
        }
    }

    private func startReconnectCountdown() {
        stopReconnectCountdown()
        opponentReconnectRemaining = 30
        reconnectCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard var remaining = self.opponentReconnectRemaining else { return }
            remaining -= 1
            DispatchQueue.main.async {
                self.opponentReconnectRemaining = max(remaining, 0)
            }
            if remaining <= 0 {
                timer.invalidate()
                Task {
                    await self.handleOpponentDisconnection()
                }
            }
        }
    }

    private func stopReconnectCountdown() {
        reconnectCountdownTimer?.invalidate()
        reconnectCountdownTimer = nil
    }

    private func handleOpponentDisconnection() async {
        guard let game = game, game.status == .in_progress else { return }
        
        // 自分がどちらのプレイヤーか判定
        let myPlayerId = game.hostPlayerID == currentUserID ? PlayerTurn.host : PlayerTurn.guest
        
        // 自分が勝者となる
        await endGame(winner: myPlayerId, reason: .disconnection)
    }

    private func getOpponentID() -> String? {
        guard let game = game else { return nil }
        let isHost = game.hostPlayerID == currentUserID
        return isHost ? game.guestPlayerID : game.hostPlayerID
    }
    
    
    deinit {
        print("GameService deinitialized. Removing listener.")
        listener?.remove()
        stopMonitoringOpponentConnection() // deinit時にも監視を停止
    }
}
