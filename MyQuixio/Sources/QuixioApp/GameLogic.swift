// MyQuixio/GameLogic.swift

import Foundation

/// ゲームのコアロジックを管理する静的なヘルパー
struct GameLogic {

    // 機能: 盤面の外周にあるマスかを判定するヘルパー。
    static func isPeripheral(row: Int, column: Int, rowCount: Int? = nil, colCount: Int? = nil, defaultSize: Int = 5) -> Bool {
        let rows = rowCount ?? defaultSize
        let cols = colCount ?? rowCount ?? defaultSize
        guard rows > 0, cols > 0 else { return false }
        let lastRow = rows - 1
        let lastCol = cols - 1
        return row == 0 || row == lastRow || column == 0 || column == lastCol
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
    // 機能: 任意の盤面表現を勝者判定し、勝利ラインの座標を返す。
    // 追加提案: 盤面サイズを引数で受け、柔軟に勝利条件を変更できるようにする。
    static func checkForWinner<T>(on board: [[T]], playerMapping: (T) -> Player?) -> (player: Player, line: [(row: Int, col: Int)])? {
        guard let firstRow = board.first, !firstRow.isEmpty else { return nil }
        let rowCount = board.count
        let colCount = firstRow.count
        guard board.allSatisfy({ $0.count == colCount }) else { return nil }

        // 横ラインのチェック
        for r in 0..<rowCount {
            if let winner = checkLine(line: board[r], playerMapping: playerMapping) {
                let winningCoords = (0..<colCount).map { (r, $0) }
                return (player: winner, line: winningCoords)
            }
        }

        // 縦ラインのチェック
        for c in 0..<colCount {
            let colLine = board.map { $0[c] }
            if let winner = checkLine(line: colLine, playerMapping: playerMapping) {
                let winningCoords = (0..<rowCount).map { ($0, c) }
                return (player: winner, line: winningCoords)
            }
        }

        let diagLength = min(rowCount, colCount)

        // 斜めラインのチェック (左上から右下)
        let diag1 = (0..<diagLength).map { board[$0][$0] }
        if let winner = checkLine(line: diag1, playerMapping: playerMapping) {
            let winningCoords = (0..<diagLength).map { ($0, $0) }
            return (player: winner, line: winningCoords)
        }

        // 斜めラインのチェック (右上から左下)
        let diag2 = (0..<diagLength).map { board[$0][colCount - 1 - $0] }
        if let winner = checkLine(line: diag2, playerMapping: playerMapping) {
            let winningCoords = (0..<diagLength).map { ($0, colCount - 1 - $0) }
            return (player: winner, line: winningCoords)
        }

        return nil
    }

    /**
     * 1つのライン（5マス）をチェックして、勝者がいるか判定します。
     */
    // 機能: ライン上の全要素が同一プレイヤーかを判定する低レベル処理。
    private static func checkLine<T>(line: [T], playerMapping: (T) -> Player?) -> Player? {
        guard let first = line.first, let firstPlayer = playerMapping(first) else { return nil }

        // ライン上の全ての要素が最初と同じプレイヤーかチェック
        let isWin = line.allSatisfy { playerMapping($0) == firstPlayer }

        return isWin ? firstPlayer : nil
    }

    /**
     * 汎用的な盤面スライドアクション。
     */
    // 機能: 端から駒を押し出すスライド操作を行い、新しい盤面を返す。
    static func slide<T>(board: [[T]], from: (row: Int, col: Int), to: (row: Int, col: Int), piece: T) -> [[T]] {
        guard let firstRow = board.first, !firstRow.isEmpty else { return board }
        let rowCount = board.count
        let colCount = firstRow.count
        guard board.allSatisfy({ $0.count == colCount }),
              board.indices.contains(from.row),
              board.indices.contains(to.row),
              board[from.row].indices.contains(from.col),
              board[to.row].indices.contains(to.col) else { return board }

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
            for i in 0..<rowCount {
                tempBoard[i][from.col] = colArray[i]
            }
        }
        return tempBoard
    }
    
    // 機能: プレイヤーが取り得る全てのスライド移動候補を列挙する。
    // 追加提案: 相手駒を押し出せるかなど、ゲームルールに応じたフィルタリングを追加するとAI精度向上に寄与。
    static func getAllPossibleMoves(
        for player: Player,
        on board: [[Piece]],
        allowPushingOpponent: Bool = true
    ) -> [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] {
        guard let firstRow = board.first, !firstRow.isEmpty else { return [] }
        let rowCount = board.count
        let colCount = firstRow.count
        guard board.allSatisfy({ $0.count == colCount }) else { return [] }

        let lastRow = rowCount - 1
        let lastCol = colCount - 1

        var possibleMoves: [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] = []
        for r in 0..<rowCount {
            for c in 0..<colCount {
                if isPeripheral(row: r, column: c, rowCount: rowCount, colCount: colCount) {
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
                            (r, 0), (r, lastCol), (0, c), (lastRow, c)
                        ].filter { $0.0 != source.row || $0.1 != source.col }
                        
                        for dest in destinations {
                            let newMove = (source: source, destination: (row: dest.0, col: dest.1))
                            if !allowPushingOpponent, containsOpponentOnPath(move: newMove, board: board, currentPlayer: player) {
                                continue
                            }
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

    /// 移動経路に相手駒が含まれるかをチェックし、禁止設定時にフィルタリングする。
    private static func containsOpponentOnPath(
        move: (source: (row: Int, col: Int), destination: (row: Int, col: Int)),
        board: [[Piece]],
        currentPlayer: Player
    ) -> Bool {
        let path = pathCoordinates(from: move.source, to: move.destination, rowCount: board.count, colCount: board.first?.count ?? 0)
        for (r, c) in path {
            guard board.indices.contains(r), board[r].indices.contains(c) else { continue }
            if let owner = board[r][c].player, owner != currentPlayer {
                return true
            }
        }
        return false
    }

    /// スライド方向に存在するマスの座標を取得する（sourceとdestinationを含む）。
    private static func pathCoordinates(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int),
        rowCount: Int,
        colCount: Int
    ) -> [(Int, Int)] {
        guard rowCount > 0, colCount > 0 else { return [] }
        if from.row == to.row {
            let range: ClosedRange<Int>
            if to.col == 0 {
                range = 0...from.col
            } else {
                range = from.col...(colCount - 1)
            }
            return range.map { (from.row, $0) }
        } else if from.col == to.col {
            let range: ClosedRange<Int>
            if to.row == 0 {
                range = 0...from.row
            } else {
                range = from.row...(rowCount - 1)
            }
            return range.map { ($0, from.col) }
        } else {
            return []
        }
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
