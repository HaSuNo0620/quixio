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
    @Published var aiLevel: AILevel = .normal
    @Published var isSoundEnabled: Bool = true
    
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
                playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                return
            }
            playSound(named: "tap.mp3")
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
                playSound(named: "error.mp3")
                HapticManager.shared.playImpact(style: .light)
                invalidMovePublisher.send()
                self.selectedCoordinate = nil
            }
        }
    }
    
    func executeMove(from source: (row: Int, col: Int), to destination: (row: Int, col: Int)) {
        playSound(named: "slide.mp3")
        HapticManager.shared.playImpact(style: .rigid)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            self.slide(from: source, to: destination)
        }
        
        if let result = self.checkWinner() {
            playSound(named: "win.mp3")
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
        // 自分の盤面(self.board)を、新しい汎用関数に渡して結果を返すだけ
        return checkForWinner(on: self.board)
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
    private func playSound(named soundName: String) {
        // サウンドを鳴らすかどうかのチェックを、この場所に集約する
        if isSoundEnabled {
            SoundManager.shared.playSound(named: soundName)
        }
    }
    
    private func slide(board: [[Piece]], from: (row: Int, col: Int), to: (row: Int, col: Int), for player: Player) -> [[Piece]] {
        var tempBoard = board
        let pieceToSlide = Piece.mark(player)
        
        if from.row == to.row { // 水平方向の移動
            var rowArray = tempBoard[from.row]
            
            // ★★★ ここからが修正箇所 ★★★
            // 検索するのではなく、指定された座標(from.col)の要素を直接削除する
            rowArray.remove(at: from.col)
            // ★★★ 修正ここまで ★★★
            
            if to.col == 0 {
                rowArray.insert(pieceToSlide, at: 0)
            } else {
                rowArray.append(pieceToSlide)
            }
            tempBoard[from.row] = rowArray
            
        } else { // 垂直方向の移動
            var colArray = tempBoard.map { $0[from.col] }
            
            // ★★★ ここからが修正箇所 ★★★
            // 検索するのではなく、指定された座標(from.row)の要素を直接削除する
            colArray.remove(at: from.row)
            // ★★★ 修正ここまで ★★★
            
            if to.row == 0 {
                colArray.insert(pieceToSlide, at: 0)
            } else {
                colArray.append(pieceToSlide)
            }
            for i in 0..<5 {
                tempBoard[i][from.col] = colArray[i]
            }
        }
        return tempBoard
    }
    
    // 既存のslideメソッドは、新しいメソッドを呼び出す形に書き換える
    private func slide(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
        self.board = slide(board: self.board, from: from, to: to, for: self.currentPlayer)
    }
    
    private func checkLine(line: [Piece]) -> Player? {
        // 最初の駒を取得
        let firstPiece = line[0]
        
        // 最初の駒が空(.empty)の場合は、誰もそのラインを制していない
        guard case .mark(let player) = firstPiece else {
            return nil
        }
        
        // line内の全ての駒がfirstPieceと等しいかを確認
        // allSatisfyは配列の全ての要素が条件を満たす場合にtrueを返す
        if line.allSatisfy({ $0 == firstPiece }) {
            // 全て同じ駒であれば、その駒のプレイヤーを勝者として返す
            return player
        }
        
        // ラインが揃っていない場合はnilを返す
        return nil
    }
    
    // 戻り値を (Player, [(row: Int, col: Int)])? に変更
    private func checkForWinner(on board: [[Piece]]) -> (player: Player, line: [(row: Int, col: Int)])? {
        // Check rows
        for r in 0..<5 {
            if let p = checkLine(line: board[r]) {
                let winningCoords = (0..<5).map { (r, $0) } // 勝利した行の座標を生成
                return (player: p, line: winningCoords)     // プレイヤーと座標を返す
            }
        }
        // Check columns
        for c in 0..<5 {
            let colLine = board.map { $0[c] }
            if let p = checkLine(line: colLine) {
                let winningCoords = (0..<5).map { ($0, c) } // 勝利した列の座標を生成
                return (player: p, line: winningCoords)     // プレイヤーと座標を返す
            }
        }
        // Check diagonals
        let diag1 = (0..<5).map { board[$0][$0] }
        if let p = checkLine(line: diag1) {
            let winningCoords = (0..<5).map { ($0, $0) }      // 勝利した対角線の座標を生成
            return (player: p, line: winningCoords)         // プレイヤーと座標を返す
        }
        let diag2 = (0..<5).map { board[$0][4-$0] }
        if let p = checkLine(line: diag2) {
            let winningCoords = (0..<5).map { ($0, 4-$0) }  // 勝利した逆対角線の座標を生成
            return (player: p, line: winningCoords)         // プレイヤーと座標を返す
        }
        
        return nil // 勝者がいない場合はnilを返す
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 少し思考時間を短縮
                // AIPlayerに、現在の盤面とAIレベルを渡して、最善手を計算してもらう
                if let bestMove = self.aiPlayer.getBestMove(for: self.board, level: self.aiLevel) {
                    self.executeMove(from: bestMove.source, to: bestMove.destination)
                } else {
                    // 万が一、手が見つからなかった場合（起こらないはず）
                    print("AI could not find a valid move.")
                }
                
                self.isAITurn = false
            }
        }

}


