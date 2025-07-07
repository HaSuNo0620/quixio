// ViewModels/OnlineGameViewModel.swift
import Foundation
import Combine
import FirebaseFirestore // Timestampのために必要

class OnlineGameViewModel: ObservableObject {
    @Published var gameService = GameService()
    @Published var game: GameSession?
    @Published var selectedCoordinate: (row: Int, col: Int)? = nil
    
    // ▼▼▼【ここから追加】エラーハンドリング用のプロパティ ▼▼▼
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    // ▲▲▲ 追加ここまで ▲▲▲
    
    private var cancellables = Set<AnyCancellable>()
    
    // 👇 自分がどちらのプレイヤーか判定するプロパティ
    var myTurn: PlayerTurn? {
        // GameServiceが持つ仮のIDと比較
        guard let game = game else { return nil }
        if game.hostPlayerID == gameService.currentUserID {
            return .host
        } else if game.guestPlayerID == gameService.currentUserID {
            return .guest
        }
        return nil
    }
    
    init() {
        gameService.$game
            .assign(to: \.game, on: self)
            .store(in: &cancellables)
    }
    
    func startMatchmaking() {
        Task {
            do {
                try await gameService.findAndJoinGame()
            } catch let error as GameError {
                // 補足した独自エラーのメッセージを設定
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } catch {
                // その他の予期せぬエラー
                self.errorMessage = GameError.unknownError.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    // MARK: - Game Logic (ここから追加)
    
    func handleTap(onRow row: Int, col: Int) {
        guard let game = game, let myTurn = myTurn else { return }
        
        // 自分のターンでなければ何もしない
        guard game.currentPlayerTurn == myTurn else {
            print("Not your turn.")
            return
        }
        
        if selectedCoordinate == nil {
            // TODO: 一人プレイ用のViewModelから、駒を選択できるかのチェックロジックを後で持ってくる
            print("Selected piece at (\(row), \(col))")
            selectedCoordinate = (row, col)
        } else {
            guard let source = selectedCoordinate else { return }
            let destination = (row: row, col: col)
            
            // TODO: 一人プレイ用のViewModelから、有効な移動かのチェックロジックを後で持ってくる
            print("Executing move from \(source) to \(destination)")
            executeMove(from: source, to: destination)
            
            selectedCoordinate = nil
        }
    }
    
    /// 盤面データをスライドさせるヘルパー関数 (GameViewModelからコピー)
    private func slide(board: [String], from: (row: Int, col: Int), to: (row: Int, col: Int), for player: PlayerTurn) -> [String] {
        let board2D = board.to2D()
        let pieceToSlide = (player == .host) ? "circle" : "cross"

        let newBoard2D = GameLogic.slide(board: board2D, from: from, to: to, piece: pieceToSlide)

        // 2Dを1Dに戻して返す
        return newBoard2D.flatMap { $0 }
    }
    
    var displayBoard: [[Piece]] {
        guard let board_1d = game?.board else {
            // ゲームがまだなければ空の盤面を返す
            return Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        }
        
        var board_2d = [[Piece]]()
        for i in 0..<5 {
            var row = [Piece]()
            for j in 0..<5 {
                let index = i * 5 + j
                switch board_1d[index] {
                case "circle":
                    row.append(.mark(.circle))
                case "cross":
                    row.append(.mark(.cross))
                default:
                    row.append(.empty)
                }
            }
            board_2d.append(row)
        }
        return board_2d
    }
    
    /// UI表示用のターン表示テキスト
    var turnIndicatorText: String {
        guard let game = game else { return "..." }
        
        switch game.status {
        case .waiting:
            return "対戦相手を探しています..."
        case .in_progress:
            if game.currentPlayerTurn == myTurn {
                return "あなたのターンです"
            } else {
                return "相手のターンです"
            }
        case .finished:
            if game.winner == myTurn {
                return "あなたの勝ちです！"
            } else if game.winner == nil {
                return "引き分けです"
            } else {
                return "あなたの負けです..."
            }
        }
    }
    
    // MARK: - UI Computed Properties (ここから追加)
    
    var isGameFinished: Bool {
        return game?.status == .finished
    }
    
    var winnerMessage: String {
        guard let game = game, game.status == .finished else { return "" }
        
        if let winner = game.winner {
            return winner == myTurn ? "あなたの勝利です！" : "あなたの負けです..."
        }
        return "引き分けです" // 今後引き分け処理を実装する場合
    }
    
    // ... (既存のinit, myTurn, startMatchmaking, handleTap)
    
    private func executeMove(from source: (row: Int, col: Int), to destination: (row: Int, col: Int)) {
        guard let game = game, let myTurn = myTurn else { return }
        let newBoard = slide(board: game.board, from: source, to: destination, for: myTurn)

        Task {
            if let winner = checkForWinner(on: newBoard) {
                await gameService.endGame(winner: winner)
            } else {
                let nextTurn: PlayerTurn = (myTurn == .host) ? .guest : .host
                await gameService.updateGame(board: newBoard, nextTurn: nextTurn)
            }
        }
    }

    // MARK: - Game Logic Helpers (ここから追加)
    
    /// 盤面をチェックして勝者を判定する (GameViewModelから移植・改造)
    private func checkForWinner(on board: [String]) -> PlayerTurn? {
        let board2D = board.to2D() // 既存のヘルパーで2D配列に変換

        // 汎用ロジックを呼び出す
        // `String` から `Player?` へのマッピングを提供
        let result = GameLogic.checkForWinner(on: board2D) { pieceString in
            switch pieceString {
            case "circle": return .circle
            case "cross": return .cross
            default: return nil
            }
        }
        
        // GameLogicからの結果 (Player) をこのViewModelで使うPlayerTurnに変換
        if let winner = result?.player {
            return winner == .circle ? .host : .guest
        }
        return nil
    }
    
    private func checkLine(line: [String]) -> PlayerTurn? {
        let firstPiece = line[0]
        guard firstPiece != "empty" else { return nil }
        
        if line.allSatisfy({ $0 == firstPiece }) {
            return firstPiece == "circle" ? .host : .guest
        }
        return nil
    }
    
    // ゲーム離脱用の関数を追加
    func leaveGame() {
        Task {
            await gameService.leaveGame()
        }
    }
}
   // 便利なヘルパー拡張
   extension Array where Element == String {
       func to2D() -> [[String]] {
           return stride(from: 0, to: self.count, by: 5).map {
               Array(self[$0..<Swift.min($0 + 5, self.count)])
           }
       }
   }
