// AIPlayer.swift

import Foundation

class AIPlayer {

    // MARK: - AI Configuration
    private struct AIConfig {
        static let winScore: Int = 1000000
        static let unblockableReachScore: Int = 200000
        static let forcedWinScore: Int = 50000
        static let initiativeScore: Int = 10000
        static let createFour: Int = 1000, blockFour: Int = 1200
        static let createThree: Int = 300, blockThree: Int = 350
        static let createTwo: Int = 10, blockTwo: Int = 12
        static let centerControlScore: Int = 3
    }

    private struct ThreatCounts {
        var unblockableReaches = 0
        var openThrees = 0
        var fours = 0
        var threes = 0
        var twos = 0
    }

    // MARK: - Public Interface
    // このクラスの唯一の公開メソッド。ViewModelから呼び出される。
    func getBestMove(for board: [[Piece]], level: AILevel) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        switch level {
        case .easy:
            return findRandomMove(board: board)
        case .medium:
            return findNormalMove(board: board)
        case .hard:
            return findHardMove(board: board)
        }
    }

    // MARK: - AI Move Logic
    private func findRandomMove(board: [[Piece]]) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        return getAllPossibleMoves(for: .cross, on: board).randomElement()
    }
    
    private func findNormalMove(board: [[Piece]]) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        let aiPlayer = Player.cross
        let humanPlayer = Player.circle
        let aiMoves = getAllPossibleMoves(for: aiPlayer, on: board)
        
        let winningMoves = aiMoves.filter { move in
            let tempBoard = slide(board: board, from: move.source, to: move.destination, for: aiPlayer)
            return checkForWinner(on: tempBoard)?.player == aiPlayer
        }
        if let move = winningMoves.randomElement() { return move }
        
        let humanMoves = getAllPossibleMoves(for: humanPlayer, on: board)
        let blockingMoves = humanMoves.compactMap { humanMove -> ((Int, Int), (Int, Int))? in
            let tempBoard = slide(board: board, from: humanMove.source, to: humanMove.destination, for: humanPlayer)
            if checkForWinner(on: tempBoard)?.player == humanPlayer {
                // Find an AI move that blocks this specific threat
                return aiMoves.first { $0.destination == humanMove.destination }
            }
            return nil
        }
        if let move = blockingMoves.randomElement() { return move }
        
        return aiMoves.randomElement()
    }

    private func findHardMove(board: [[Piece]]) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        var bestScore = -Int.max
        var bestMoves: [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] = []
        let moves = getAllPossibleMoves(for: .cross, on: board)

        for move in moves {
            let newBoard = slide(board: board, from: move.source, to: move.destination, for: .cross)
            let moveScore = minimax(board: newBoard, depth: 2, alpha: -Int.max, beta: Int.max, isMaximizing: false)
            if moveScore > bestScore {
                bestScore = moveScore
                bestMoves = [move]
            } else if moveScore == bestScore {
                bestMoves.append(move)
            }
        }
        return bestMoves.randomElement() ?? moves.randomElement()
    }

    private func minimax(board: [[Piece]], depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        let evaluation = evaluate(board: board)
        if depth == 0 || abs(evaluation) >= AIConfig.initiativeScore {
            return evaluation
        }
        if isMaximizing {
            var maxEval = -Int.max
            var currentAlpha = alpha
            for move in getAllPossibleMoves(for: .cross, on: board) {
                let newBoard = slide(board: board, from: move.source, to: move.destination, for: .cross)
                let eval = minimax(board: newBoard, depth: depth - 1, alpha: currentAlpha, beta: beta, isMaximizing: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if beta <= currentAlpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            var currentBeta = beta
            for move in getAllPossibleMoves(for: .circle, on: board) {
                let newBoard = slide(board: board, from: move.source, to: move.destination, for: .circle)
                let eval = minimax(board: newBoard, depth: depth - 1, alpha: alpha, beta: currentBeta, isMaximizing: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= alpha { break }
            }
            return minEval
        }
    }

    // MARK: - Evaluation Logic
    private func evaluate(board: [[Piece]]) -> Int {
        if let winnerInfo = checkForWinner(on: board) {
            return winnerInfo.player == .cross ? AIConfig.winScore : -AIConfig.winScore
        }
        let aiThreats = countThreats(on: board, for: .cross)
        let humanThreats = countThreats(on: board, for: .circle)
        return calculateScore(aiThreats: aiThreats, humanThreats: humanThreats, board: board)
    }

    private func countThreats(on board: [[Piece]], for player: Player) -> ThreatCounts {
        var counts = ThreatCounts()
        var lines: [[Piece]] = []
        for r in 0..<5 { lines.append(board[r]) }
        for c in 0..<5 { lines.append(board.map { $0[c] }) }
        lines.append((0..<5).map { board[$0][$0] })
        lines.append((0..<5).map { board[$0][4-$0] })
        
        for line in lines {
            let playerCount = line.filter { $0 == .mark(player) }.count
            let opponentPlayer: Player = (player == .cross) ? .circle : .cross
            let opponentCount = line.filter { $0 == .mark(opponentPlayer) }.count
            let emptyCount = line.filter { $0 == .empty }.count
            if playerCount > 0 && opponentCount > 0 { continue }
            if playerCount == 4 && emptyCount == 1 {
                if let emptyIndex = line.firstIndex(of: .empty), emptyIndex > 0 && emptyIndex < 4 {
                    counts.unblockableReaches += 1
                } else {
                    counts.fours += 1
                }
            } else if playerCount == 3 && emptyCount == 2 && line.first == .empty && line.last == .empty {
                counts.openThrees += 1
            } else if playerCount == 3 {
                counts.threes += 1
            } else if playerCount == 2 {
                counts.twos += 1
            }
        }
        return counts
    }

    private func calculateScore(aiThreats: ThreatCounts, humanThreats: ThreatCounts, board: [[Piece]]) -> Int {
        if humanThreats.unblockableReaches > 0 { return -AIConfig.unblockableReachScore }
        if aiThreats.unblockableReaches > 0 { return AIConfig.unblockableReachScore }
        if humanThreats.openThrees >= 2 { return -AIConfig.forcedWinScore }
        if aiThreats.openThrees >= 2 { return AIConfig.forcedWinScore }
        if humanThreats.openThrees > 0 { return -AIConfig.initiativeScore }
        if aiThreats.openThrees > 0 { return AIConfig.initiativeScore }
        var score = 0
        score += aiThreats.fours * AIConfig.createFour
        score += aiThreats.threes * AIConfig.createThree
        score += aiThreats.twos * AIConfig.createTwo
        score -= humanThreats.fours * AIConfig.blockFour
        score -= humanThreats.threes * AIConfig.blockThree
        score -= humanThreats.twos * AIConfig.blockTwo
        let centerPositions = [(1,1), (1,2), (1,3), (2,1), (2,2), (2,3), (3,1), (3,2), (3,3)]
        for pos in centerPositions {
            if board[pos.0][pos.1] == .mark(.cross) {
                score += AIConfig.centerControlScore
            } else if board[pos.0][pos.1] == .mark(.circle) {
                score -= AIConfig.centerControlScore
            }
        }
        return score
    }

    // MARK: - Game Logic Helpers (Copied from GameViewModel)
    private func getAllPossibleMoves(for player: Player, on board: [[Piece]]) -> [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] {
        var possibleMoves: [(source: (row: Int, col: Int), destination: (row: Int, col: Int))] = []
        for r in 0..<5 {
            for c in 0..<5 {
                if isPeripheral(row: r, column: c) {
                    let piece = board[r][c]
                    var canSelect = false
                    if case .empty = piece { canSelect = true }
                    if case .mark(let owner) = piece, owner == player { canSelect = true }
                    if canSelect {
                        let source = (row: r, col: c)
                        let dests = [(r, 0), (r, 4), (0, c), (4, c)].filter { $0.0 != source.row || $0.1 != source.col }
                        for dest in dests {
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
    
    private func slide(board: [[Piece]], from: (row: Int, col: Int), to: (row: Int, col: Int), for player: Player) -> [[Piece]] {
        var tempBoard = board
        let pieceToSlide = Piece.mark(player)
        if from.row == to.row {
            var rowArray = tempBoard[from.row]
            rowArray.remove(at: from.col)
            if to.col == 0 { rowArray.insert(pieceToSlide, at: 0) } else { rowArray.append(pieceToSlide) }
            tempBoard[from.row] = rowArray
        } else {
            var colArray = tempBoard.map { $0[from.col] }
            colArray.remove(at: from.row)
            if to.row == 0 { colArray.insert(pieceToSlide, at: 0) } else { colArray.append(pieceToSlide) }
            for i in 0..<5 { tempBoard[i][from.col] = colArray[i] }
        }
        return tempBoard
    }

    private func checkForWinner(on board: [[Piece]]) -> (player: Player, line: [(row: Int, col: Int)])? {
        for r in 0..<5 {
            if let p = checkLine(line: board[r]) { return (p, (0..<5).map { (r, $0) }) }
        }
        for c in 0..<5 {
            let colLine = board.map { $0[c] }
            if let p = checkLine(line: colLine) { return (p, (0..<5).map { ($0, c) }) }
        }
        let diag1 = (0..<5).map { board[$0][$0] }
        if let p = checkLine(line: diag1) { return (p, (0..<5).map { ($0, $0) }) }
        let diag2 = (0..<5).map { board[$0][4-$0] }
        if let p = checkLine(line: diag2) { return (p, (0..<5).map { ($0, 4-$0) }) }
        return nil
    }
    
    private func checkLine(line: [Piece]) -> Player? {
        guard let firstPiece = line.first, case .mark(let player) = firstPiece else { return nil }
        return line.allSatisfy { $0 == firstPiece } ? player : nil
    }
    
    private func isPeripheral(row: Int, column: Int) -> Bool {
        return row == 0 || row == 4 || column == 0 || column == 4
    }
}
