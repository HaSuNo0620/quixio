// MyQuixio/ViewModels/GameViewModel.swift

import SwiftUI
import Combine

struct GameState {
    let board: [[Piece]]
    let currentPlayer: Player
}

class GameViewModel: ObservableObject {
    
    @Published var board: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
    @Published var currentPlayer: Player = .circle
    @Published var selectedCoordinate: (row: Int, col: Int)? = nil
    @Published var winner: Player? = nil
    @Published var gameMode: GameMode
    @Published var isAITurn: Bool = false
    @Published var winningLine: [(row: Int, col: Int)]? = nil
    @Published var aiLevel: AILevel
    @Published private var history: [GameState] = []
    
    // ▼▼▼【ここから修正】AIプレイヤーのインスタンスを2種類保持するように変更 ▼▼▼
    private let mctsAIPlayer = AIPlayer()
    private var alphaZeroAIPlayer: AlphaZeroAIPlayer? // 新しいAIはレベルに応じて初期化
    // ▲▲▲ 修正ここまで ▲▲▲
    
    let invalidMovePublisher = PassthroughSubject<Void, Never>()
    
    // vs AIモードとAIレベルを引数で受け取るイニシャライザ
    init(gameMode: GameMode, aiLevel: AILevel) {
        self.gameMode = gameMode
        self.aiLevel = aiLevel
        // ▼▼▼【ここから追加】AIレベルがultimateなら、AlphaZeroAIを初期化する ▼▼▼
        if aiLevel == .ultimate {
            self.alphaZeroAIPlayer = AlphaZeroAIPlayer(level: aiLevel)
        }
        // ▲▲▲ 追加ここまで ▲▲▲
    }
    
    // vs 人モード用のイニシャライザ
    init(gameMode: GameMode) {
        self.gameMode = gameMode
        self.aiLevel = .medium // デフォルト値を設定
    }
    
    // (handleTap, executeMove などの他のメソッドは変更なし)
    func handleTap(onRow row: Int, col column: Int) {
        guard self.winner == nil else { return }
        guard !self.isAITurn else { return }
        
        if self.selectedCoordinate == nil {
            let piece = self.board[row][column]
            var canSelect = false
            switch piece {
            case .empty:
                canSelect = true
            case .mark(let owner):
                if owner == self.currentPlayer {
                    canSelect = true
                }
            }
            guard GameLogic.isPeripheral(row: row, column: column) && canSelect else {
                SoundManager.shared.playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                return
            }
            SoundManager.shared.playSound(named: "tap.mp3")
            HapticManager.shared.playImpact(style: .medium)
            self.selectedCoordinate = (row: row, col: column)
        } else {
            guard let source = self.selectedCoordinate else { return }
            let destination = (row: row, col: column)
            
            if source.row == destination.row && source.col == destination.col {
                self.selectedCoordinate = nil
                return
            }
            
            let isSameRow = (source.row == destination.row)
            let isSameCol = (source.col == destination.col)
            let isDestinationOnHorizontalEdge = (destination.col == 0 || destination.col == 4)
            let isDestinationOnVerticalEdge = (destination.row == 0 || destination.row == 4)
            let isValidRowMove = isSameRow && isDestinationOnHorizontalEdge
            let isValidColMove = isSameCol && isDestinationOnVerticalEdge
            
            if isValidRowMove || isValidColMove {
                executeMove(from: source, to: destination)
                self.selectedCoordinate = nil
            } else {
                SoundManager.shared.playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                self.selectedCoordinate = nil
            }
        }
    }
    
    func executeMove(from source: (row: Int, col: Int), to destination: (row: Int, col: Int)) {
        saveCurrentState()
        SoundManager.shared.playSound(named: "slide.mp3")
        HapticManager.shared.playImpact(style: .rigid)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            self.slide(from: source, to: destination)
        }
        if let result = self.checkWinner() {
            SoundManager.shared.playSound(named: "win.mp3")
            HapticManager.shared.playNotification(type: .success)
            withAnimation(.easeInOut.delay(0.5)) {
                self.winner = result.player
                self.winningLine = result.line
            }
        } else {
            self.currentPlayer = (self.currentPlayer == .circle) ? .cross : .circle
        }
    }
    
    private func checkWinner() -> (player: Player, line: [(row: Int, col: Int)])? {
        return GameLogic.checkForWinner(on: self.board) { piece in
            if case .mark(let player) = piece {
                return player
            }
            return nil
        }
    }
    
    func resetGame() {
        HapticManager.shared.playImpact(style: .soft)
        self.board = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
        self.currentPlayer = .circle
        self.selectedCoordinate = nil
        self.winner = nil
        self.winningLine = nil
        self.history = []
    }
    
    func undoMove() {
        guard !history.isEmpty else { return }
        var stateToRestore: GameState?
        if gameMode == .vsAI && !isAITurn {
            history.popLast()
            stateToRestore = history.popLast()
        } else {
            stateToRestore = history.popLast()
        }
        if let state = stateToRestore {
            self.board = state.board
            self.currentPlayer = state.currentPlayer
            self.winner = nil
            self.winningLine = nil
            self.selectedCoordinate = nil
        } else {
            resetGame()
        }
    }
    
    private func saveCurrentState() {
        let currentState = GameState(board: self.board, currentPlayer: self.currentPlayer)
        history.append(currentState)
    }
    
    private func slide(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
        let pieceToSlide = Piece.mark(self.currentPlayer)
        self.board = GameLogic.slide(board: self.board, from: from, to: to, piece: pieceToSlide)
    }
    
    var turnIndicatorText: String {
        if let winner = winner {
            if gameMode == .vsAI {
                return winner == .circle ? "あなたの勝利です！" : "AIの勝利です"
            } else {
                return winner == .circle ? "◯ の勝利です！" : "✕ の勝利です"
            }
        }
        if gameMode == .vsAI {
            if isAITurn { return "考え中..." }
            else { return "あなたの番です" }
        }
        if gameMode == .vsHuman {
            return currentPlayer == .circle ? "◯ の番です" : "✕ の番です"
        }
        return ""
    }
    
    func triggerAIMove() {
        guard !isAITurn, winner == nil, gameMode == .vsAI, currentPlayer == .cross else { return }
        isAITurn = true
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                
                // AIレベルに応じて使用するAIを切り替える
                let bestMove: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?
                
                if self.aiLevel == .ultimate {
                    // ▼▼▼【★修正箇所】▼▼▼
                    // alphaZeroAIPlayer.getBestMoveは(move:..., policy:...)のタプルを返すようになったため、
                    // 結果から.moveプロパティを取り出すように修正します。
                    let result = self.alphaZeroAIPlayer?.getBestMove(for: self.board, currentPlayer: .cross)
                    bestMove = result?.move
                    // ▲▲▲ 修正ここまで ▲▲▲
                } else {
                    // こちらはMCTS AIなので、既存のコードのままでOKです。
                    bestMove = self.mctsAIPlayer.getBestMove(for: self.board, level: self.aiLevel)
                }
                
                if let move = bestMove {
                    await MainActor.run {
                        self.executeMove(from: move.source, to: move.destination)
                        self.isAITurn = false
                    }
                } else {
                    print("AI could not find a valid move.")
                    await MainActor.run {
                        self.isAITurn = false
                    }
                }
            } catch {
                print("AI thinking task was cancelled: \(error)")
                await MainActor.run {
                    self.isAITurn = false
                }
            }
        }
    }
}
