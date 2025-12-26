// ViewModels/OnlineGameViewModel.swift
import Foundation
import Combine
import FirebaseFirestore // Timestampのために必要



class OnlineGameViewModel: ObservableObject {
    
    private let gameService: GameService
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
    @Published var isOpponentOnline: Bool = true
    @Published var opponentReconnectRemaining: Int?
    
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
    
    init(gameService: GameService) {
        self.gameService = gameService
        gameService.$game
            .receive(on: DispatchQueue.main)
            .assign(to: \.game, on: self)
            .store(in: &cancellables)
        gameService.$isOpponentOnline
            .receive(on: DispatchQueue.main)
            .assign(to: \.isOpponentOnline, on: self)
            .store(in: &cancellables)
        gameService.$opponentReconnectRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: \.opponentReconnectRemaining, on: self)
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(gameService: GameService())
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
            let boardSize = displayBoard.count
            let colCount = displayBoard.first?.count ?? boardSize
            guard GameLogic.isPeripheral(row: row, column: col, rowCount: boardSize, colCount: colCount) && canSelect else {
                print("Invalid selection.")
                return
            }
            print("Selected piece at (\(row), \(col))")
            selectedCoordinate = (row, col)
        } else {
            guard let source = selectedCoordinate else { return }
            let destination = (row: row, col: col)
            
            // 既存のGameViewModelのロジックと同様に、有効な移動かチェック
            let boardSize = displayBoard.count
            let colCount = displayBoard.first?.count ?? boardSize
            let lastRow = max(boardSize - 1, 0)
            let lastCol = max(colCount - 1, 0)
            let isSameRow = (source.row == destination.row)
            let isSameCol = (source.col == destination.col)
            let isDestinationOnHorizontalEdge = (destination.col == 0 || destination.col == lastCol)
            let isDestinationOnVerticalEdge = (destination.row == 0 || destination.row == lastRow)
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
        let newBoard1D = BoardConverter.encode(newBoard2D)

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
    
    var displayBoard: [[Piece]] {
        return BoardConverter.decode(game?.board ?? [])
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
        
        // 自分が勝者かどうか
        let amIWinner = game.winner == myTurn
        
        if amIWinner {
            // 終了理由によってメッセージを出し分ける
            if game.endReason == .disconnection {
                return "相手が対戦から退出しました。\nあなたの勝ちです！"
            } else {
                return "あなたの勝ちです！"
            }
        } else {
            // 自分が敗者
            if game.endReason == .disconnection {
                // 自分が切断した側（leaveGameを呼び出した側）
                // このメッセージは基本表示されないが、念のため
                return "対戦から退出しました。"
            } else {
                return "あなたの負けです..."
            }
        }
    }
    
    // 新しい対戦を探すための関数
    func findNewGame() {
        self.game = nil // UIを即座に更新するためにローカルのゲームをリセット
        startMatchmaking()
    }
    
    func leaveGame() {
        Task {
            await gameService.leaveGame()
        }
    }
}
