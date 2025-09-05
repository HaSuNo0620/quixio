// ViewModels/OnlineGameViewModel.swift
import Foundation
import Combine
import FirebaseFirestore // Timestampのために必要



class OnlineGameViewModel: ObservableObject {
    
    @Published var gameService = GameService()
    @Published var game: GameSession? {
        didSet {
                   print("\n--- [\(myRoleForPrint)] Game State Did Update ---")
                   if let game = game {
                       print("Status: \(game.status), Current Turn: \(game.currentPlayerTurn)")
                       print("My Turn? \(game.currentPlayerTurn == myTurn)")
                   } else {
                       print("Game object is now nil.")
                   }
                   print("-------------------------------------\n")
               }
    }
    @Published var selectedCoordinate: (row: Int, col: Int)? = nil
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published private var isProcessingMove = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private var myRoleForPrint: String {
        switch myTurn {
        case .host: return "HOST"
        case .guest: return "GUEST"
        default: return "UNKNOWN"
        }
    }
    
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
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            } catch {
                print("An unexpected error occurred. Error type: \(type(of: error))")
                print("Error details: \(error)")
                
                // ▼▼▼【ここから修正】UI更新をメインスreadで行う ▼▼▼
                await MainActor.run {
                    // ユーザーには汎用的なメッセージを表示
                    self.errorMessage = GameError.unknownError.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Game Logic (ここから追加)
    
    func handleTap(onRow row: Int, col: Int) {
        
        guard !isProcessingMove else { return }
        guard let game = game, let myTurn = myTurn else { return }
        guard game.currentPlayerTurn == myTurn else {
            print("Not your turn.")
            return
        }
        
        if selectedCoordinate == nil {
            let piece = self.displayBoard[row][col]
            var canSelect = false
            switch piece {
            case .empty:
                canSelect = true
            case .mark(let owner):
                let myPlayer: Player = (myTurn == .host) ? .circle : .cross
                if owner == myPlayer {
                    canSelect = true
                }
            }
            // 盤面の周辺部でなければ選択できない
            guard self.isPeripheral(row: row, col: col) && canSelect else {
                print("Invalid selection.")
                return
            }
            print("Selected piece at (\(row), \(col))")
            selectedCoordinate = (row, col)
        } else {
            guard let source = selectedCoordinate else { return }
            let destination = (row: row, col: col)
            
            // 既存のGameViewModelのロジックと同様に、有効な移動かチェック
            let isSameRow = (source.row == destination.row)
            let isSameCol = (source.col == destination.col)
            let isDestinationOnHorizontalEdge = (destination.col == 0 || destination.col == 4)
            let isDestinationOnVerticalEdge = (destination.row == 0 || destination.row == 4)
            let isValidRowMove = isSameRow && isDestinationOnHorizontalEdge
            let isValidColMove = isSameCol && isDestinationOnVerticalEdge
            
            if isValidRowMove || isValidColMove {
                print("Executing move from \(source) to \(destination)")
                executeMove(from: source, to: destination)
                selectedCoordinate = nil
            } else {
                print("Invalid move.")
                selectedCoordinate = nil
            }
        }
    }
    
    private func executeMove(from source: (row: Int, col: Int), to destination: (row: Int, col: Int)) {
        guard let game = game, let myTurn = myTurn else { return }
        
        isProcessingMove = true
        
        let playerToMove: Player = (myTurn == .host) ? .circle : .cross
        let pieceToSlide = Piece.mark(playerToMove)
        
        // GameLogicのslide関数を直接使用
        let newBoard2D = GameLogic.slide(board: displayBoard, from: source, to: destination, piece: pieceToSlide)
        let newBoard1D = newBoard2D.flatMap { $0 }.map { (piece: Piece) in
            switch piece {
            case .mark(.circle): return "circle"
            case .mark(.cross): return "cross"
            case .empty: return "empty"
            }
        }

        Task {
            // GameLogicのcheckForWinnerを直接使用
            if let result = GameLogic.checkForWinner(on: newBoard2D, playerMapping: { (piece: Piece) -> Player? in
                if case .mark(let player) = piece {
                    return player
                }
                return nil
            }) {
                let winnerTurn: PlayerTurn = (result.player == .circle) ? .host : .guest
                await gameService.endGame(winner: winnerTurn)
            } else {
                let nextTurn: PlayerTurn = (myTurn == .host) ? .guest : .host
                await gameService.updateGame(board: newBoard1D, nextTurn: nextTurn)
            }
            await MainActor.run {
                        self.isProcessingMove = false
                    }
        }
    }

    private func isPeripheral(row: Int, col: Int) -> Bool {
        return row == 0 || row == 4 || col == 0 || col == 4
    }
    
    var displayBoard: [[Piece]] {
        guard let board_1d = game?.board else {
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
