// MARK: - GameViewModel.swift

import SwiftUI
import Combine

struct GameState {
    let board: [[Piece]]
    let currentPlayer: Player
}

// ObservableObject: このオブジェクトの変更をViewが監視できるようにする
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var board: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
    @Published var currentPlayer: Player = .circle
    @Published var selectedCoordinate: (row: Int, col: Int)? = nil
    @Published var winner: Player? = nil
    @Published var gameMode: GameMode
    @Published var isAITurn: Bool = false
    @Published var winningLine: [(row: Int, col: Int)]? = nil
    @Published var aiLevel: AILevel = .medium
    @Published private var history: [GameState] = []
    
    private let aiPlayer = AIPlayer()
    
    let invalidMovePublisher = PassthroughSubject<Void, Never>()
    
    // MARK: - Initializer
    
    // vs AIモードとAIレベルを引数で受け取るイニシャライザ
    init(gameMode: GameMode, aiLevel: AILevel) {
        self.gameMode = gameMode
        self.aiLevel = aiLevel
    }
    
    // vs 人モード用のイニシャライザ
    init(gameMode: GameMode) {
        self.gameMode = gameMode
    }
    
    // デフォルトのイニシャライザは廃止

    // MARK: - Game Logic Methods
    
    func handleTap(onRow row: Int, col column: Int) {
        guard self.winner == nil else { return }
        guard !self.isAITurn else { return } // AIの思考中はタップを無効化
        
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
            guard self.isPeripheral(row: row, column: column) && canSelect else {
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
    
    private func isPeripheral(row: Int, column: Int) -> Bool {
        return row == 0 || row == 4 || column == 0 || column == 4
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
            // 履歴が空の場合は何もしない
            guard !history.isEmpty else { return }

            var stateToRestore: GameState?

            // AI対戦モードで、かつプレイヤーのターンの場合
            if gameMode == .vsAI && !isAITurn {
                // AIの手の前の状態を履歴から取り出す（使わない）
                history.popLast()
                // プレイヤーの手の前の状態を履歴から取り出し、復元対象とする
                stateToRestore = history.popLast()
            } else {
                // 対人戦モードの場合は、直前の状態を復元対象とする
                stateToRestore = history.popLast()
            }
            
            // 復元する状態がある場合
            if let state = stateToRestore {
                self.board = state.board
                self.currentPlayer = state.currentPlayer
                self.winner = nil
                self.winningLine = nil
                self.selectedCoordinate = nil
            } else {
                // 復元する状態がなければ（履歴が空になった場合）、ゲームを初期状態にリセットする
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
            if isAITurn {
                return "考え中..."
            } else {
                return "あなたの番です"
            }
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

                if let bestMove = self.aiPlayer.getBestMove(for: self.board, level: self.aiLevel) {
                    await MainActor.run {
                        self.executeMove(from: bestMove.source, to: bestMove.destination)
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
