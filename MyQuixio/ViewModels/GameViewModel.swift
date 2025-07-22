// MARK: - GameViewModel.swift

import SwiftUI
import Combine

// ObservableObject: このオブジェクトの変更をViewが監視できるようにする
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // @Published: このプロパティが変更されたら、Viewに通知する
    @Published var board: [[Piece]] = Array(repeating: Array(repeating: .empty, count: 5), count: 5)
    @Published var currentPlayer: Player = .circle
    @Published var selectedCoordinate: (row: Int, col: Int)? = nil
    @Published var winner: Player? = nil
    @Published var gameMode: GameMode = .vsAI
    @Published var isAITurn: Bool = false
    @Published var winningLine: [(row: Int, col: Int)]? = nil
    @Published var aiLevel: AILevel = .medium
//    @Published var isSoundEnabled: Bool = true
    
    private let aiPlayer = AIPlayer()
    
    let invalidMovePublisher = PassthroughSubject<Void, Never>()
    
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
//                playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                return
            }
            SoundManager.shared.playSound(named: "tap.mp3")
//            playSound(named: "tap.mp3")
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
//                playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                self.selectedCoordinate = nil
            }
        }
    }
    
    func executeMove(from source: (row: Int, col: Int), to destination: (row: Int, col: Int)) {
//        playSound(named: "slide.mp3")
        SoundManager.shared.playSound(named: "slide.mp3")
        HapticManager.shared.playImpact(style: .rigid)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            self.slide(from: source, to: destination)
        }
        
        if let result = self.checkWinner() {
            SoundManager.shared.playSound(named: "win.mp3")
//            playSound(named: "win.mp3")
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
    
    // --- ★★★ 既存のcheckWinnerメソッドを、このコードに置き換える ★★★ ---
    private func checkWinner() -> (player: Player, line: [(row: Int, col: Int)])? {
        // 汎用ロジックを呼び出す
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
    }
    
    /// サウンドを再生する専門のヘルパーメソッド
//    private func playSound(named soundName: String) {
//        // サウンドを鳴らすかどうかのチェックを、この場所に集約する
//        if isSoundEnabled {
//            SoundManager.shared.playSound(named: soundName)
//        }
//    }
    
    // 既存のslideメソッドは、新しいメソッドを呼び出す形に書き換える
    private func slide(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
        let pieceToSlide = Piece.mark(self.currentPlayer)
        self.board = GameLogic.slide(board: self.board, from: from, to: to, piece: pieceToSlide)
    }
    
    var turnIndicatorText: String {
        // まず勝者が決まっているかチェック
        if let winner = winner {
            if gameMode == .vsAI {
                return winner == .circle ? "あなたの勝利です！" : "AIの勝利です"
            } else {
                return winner == .circle ? "◯ の勝利です！" : "✕ の勝利です"
            }
        }
        
        // AI対戦モードの場合
        if gameMode == .vsAI {
            if isAITurn {
                return "相手（AI）が考えています..."
            } else {
                return "あなたの番です"
            }
        }
        
        // 2人対戦モードの場合
        if gameMode == .vsHuman {
            return currentPlayer == .circle ? "◯ の番です" : "✕ の番です"
        }
        
        // 上記のいずれにも当てはまらない場合 (念のため)
        return ""
    }

    func triggerAIMove() {
        guard !isAITurn, winner == nil, gameMode == .vsAI, currentPlayer == .cross else { return }

        isAITurn = true

        // Taskを使って非同期処理を開始
        Task {
            do {
                // 0.5秒間、非同期に待機します。UIはブロックされません。
                try await Task.sleep(nanoseconds: 500_000_000)

                // AIPlayerに、現在の盤面とAIレベルを渡して、最善手を計算してもらう
                if let bestMove = self.aiPlayer.getBestMove(for: self.board, level: self.aiLevel) {
                    // UIの更新はメインスレッドで行うことを保証
                    await MainActor.run {
                        self.executeMove(from: bestMove.source, to: bestMove.destination)
                        self.isAITurn = false
                    }
                } else {
                    // 万が一、手が見つからなかった場合
                    print("AI could not find a valid move.")
                    await MainActor.run {
                        self.isAITurn = false
                    }
                }
            } catch {
                // Taskがキャンセルされた場合のエラーハンドリング
                print("AI thinking task was cancelled: \(error)")
                await MainActor.run {
                    self.isAITurn = false
                }
            }
        }
    }

}


