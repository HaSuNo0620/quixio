// MyQuixio/GameLogic.swift

import Foundation

/// ゲームのコアロジックを管理する静的なヘルパー
struct GameLogic {

    
    static func isPeripheral(row: Int, column: Int) -> Bool {
        return row == 0 || row == 4 || column == 0 || column == 4
    }
    /**
     * 汎用的な勝者判定ロジック。
     * 盤面のデータ型に依存しないようにジェネリクスを使用します。
     * - Parameters:
     * - board: 2次元配列で表現された盤面。
     * - playerMapping: 盤面の要素からプレイヤーを特定するためのクロージャ。
     * - Returns: 勝者プレイヤーと、勝利ラインの座標のタプル。勝者がいなければnil。
     * 
     */
    static func checkForWinner<T>(on board: [[T]], playerMapping: (T) -> Player?) -> (player: Player, line: [(row: Int, col: Int)])? {
        // 横ラインのチェック
        for r in 0..<5 {
            if let winner = checkLine(line: board[r], playerMapping: playerMapping) {
                let winningCoords = (0..<5).map { (r, $0) }
                return (player: winner, line: winningCoords)
            }
        }

        // 縦ラインのチェック
        for c in 0..<5 {
            let colLine = board.map { $0[c] }
            if let winner = checkLine(line: colLine, playerMapping: playerMapping) {
                let winningCoords = (0..<5).map { ($0, c) }
                return (player: winner, line: winningCoords)
            }
        }

        // 斜めラインのチェック (左上から右下)
        let diag1 = (0..<5).map { board[$0][$0] }
        if let winner = checkLine(line: diag1, playerMapping: playerMapping) {
            let winningCoords = (0..<5).map { ($0, $0) }
            return (player: winner, line: winningCoords)
        }

        // 斜めラインのチェック (右上から左下)
        let diag2 = (0..<5).map { board[$0][4 - $0] }
        if let winner = checkLine(line: diag2, playerMapping: playerMapping) {
            let winningCoords = (0..<5).map { ($0, 4 - $0) }
            return (player: winner, line: winningCoords)
        }

        return nil
    }

    /**
     * 1つのライン（5マス）をチェックして、勝者がいるか判定します。
     */
    private static func checkLine<T>(line: [T], playerMapping: (T) -> Player?) -> Player? {
        guard let firstPlayer = playerMapping(line[0]) else { return nil }

        // ライン上の全ての要素が最初と同じプレイヤーかチェック
        let isWin = line.allSatisfy { playerMapping($0) == firstPlayer }

        return isWin ? firstPlayer : nil
    }

    /**
     * 汎用的な盤面スライドアクション。
     */
    static func slide<T>(board: [[T]], from: (row: Int, col: Int), to: (row: Int, col: Int), piece: T) -> [[T]] {
        var tempBoard = board

        if from.row == to.row { // 横スライド
            var rowArray = tempBoard[from.row]
            rowArray.remove(at: from.col)
            if to.col == 0 {
                rowArray.insert(piece, at: 0)
            } else {
                rowArray.append(piece)
            }
            tempBoard[from.row] = rowArray
        } else { // 縦スライド
            var colArray = tempBoard.map { $0[from.col] }
            colArray.remove(at: from.row)
            if to.row == 0 {
                colArray.insert(piece, at: 0)
            } else {
                colArray.append(piece)
            }
            for i in 0..<5 {
                tempBoard[i][from.col] = colArray[i]
            }
        }
        return tempBoard
    }
    
    static func getAllPossibleMoves(for player: Player, on board: [[Piece]]) -> [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] {
            var possibleMoves: [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] = []
            for r in 0..<5 {
                for c in 0..<5 {
                    if isPeripheral(row: r, column: c) {
                        let piece = board[r][c]
                        var canSelect = false
                        
                        switch piece {
                        case .empty:
                            canSelect = true
                        case .mark(let owner) where owner == player:
                            canSelect = true
                        default:
                            break
                        }
                        
                        if canSelect {
                            let source = (row: r, col: c)
                            let destinations = [
                                (r, 0), (r, 4), (0, c), (4, c)
                            ].filter { $0.0 != source.row || $0.1 != source.col }
                            
                            for dest in destinations {
                                let newMove = (source: source, destination: (row: dest.0, col: dest.1))
                                if !possibleMoves.contains(where: { $0.source == newMove.source && $0.destination == newMove.destination }) {
                                    possibleMoves.append(newMove)
                                }
                            }
                        }
                    }
                }
            }
            return possibleMoves
        }
}
extension Piece {
    var player: Player? {
        if case .mark(let owner) = self {
            return owner
        }
        return nil
    }
}

// Player enum を `OnlineGameViewModel` でも使えるように、`GameModels.swift` から移動もしくは公開アクセスレベルに変更が必要。
// ここでは OnlineGameModels に Player を定義し直すことで対応します。
// GameModels.swift の Player を OnlineGameModels.swift にもコピーするか、
// 共通のモデルファイルに移動するのが理想的です。
