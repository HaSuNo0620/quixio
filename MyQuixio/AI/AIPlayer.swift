// MyQuixio/AI/AIPlayer.swift

import Foundation

// MARK: - MCTS Node Class
private class MCTSNode {
    var move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?
    var parent: MCTSNode?
    var children: [MCTSNode] = []
    var wins: Double = 0
    var visits: Int = 0
    var boardState: [[Piece]]
    var currentPlayer: Player

    init(boardState: [[Piece]], currentPlayer: Player, move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))? = nil, parent: MCTSNode? = nil) {
        self.boardState = boardState
        self.currentPlayer = currentPlayer
        self.move = move
        self.parent = parent
    }
    
    func selectChild() -> MCTSNode? {
        let explorationConstant: Double = 1.414
        var bestScore = -Double.infinity
        var bestChild: MCTSNode?

        for child in children {
            if child.visits == 0 {
                return child
            }
            let winRate = child.wins / Double(child.visits)
            let explorationTerm = explorationConstant * sqrt(log(Double(self.visits)) / Double(child.visits))
            let score = winRate + explorationTerm
            if score > bestScore {
                bestScore = score
                bestChild = child
            }
        }
        return bestChild
    }
    
    func rollout() -> Player? {
        var currentBoard = self.boardState
        var turnPlayer = self.currentPlayer
        
        for _ in 0..<25 {
            if let winnerInfo = GameLogic.checkForWinner(on: currentBoard, playerMapping: { $0.player }) {
                return winnerInfo.player
            }
            
            let moves = GameLogic.getAllPossibleMoves(for: turnPlayer, on: currentBoard)
            guard let randomMove = moves.randomElement() else {
                return nil
            }
            
            let piece = Piece.mark(turnPlayer)
            currentBoard = GameLogic.slide(board: currentBoard, from: randomMove.source, to: randomMove.destination, piece: piece)
            
            turnPlayer = (turnPlayer == .circle) ? Player.cross : Player.circle
        }
        
        return nil
    }
}


// MARK: - AIPlayer Class (MCTS Implementation)
class AIPlayer {

    func getBestMove(for board: [[Piece]], level: AILevel) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        
        if level == .easy {
            return GameLogic.getAllPossibleMoves(for: .cross, on: board).randomElement()
        }
        
        // ▼▼▼【ここから修正】データ生成用のシミュレーション回数を追加 ▼▼▼
        let simulationCount: Int
        switch level {
        case .medium:
            simulationCount = 1000
        case .hard:
            simulationCount = 4000
        case .expert:
            simulationCount = 8000
//        case .forDataGeneration:  データ生成用の高速設定
//            simulationCount = 200  大幅に回数を減らして速度を優先
        default:
            simulationCount = 1000
        }
        // ▲▲▲ 修正ここまで ▲▲▲

        return findBestMoveByMCTS(board: board, iterations: simulationCount)
    }

    private func findBestMoveByMCTS(board: [[Piece]], iterations: Int) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        let rootNode = MCTSNode(boardState: board, currentPlayer: .cross)
        
        for _ in 0..<iterations {
            var node = rootNode
            while !node.children.isEmpty {
                if let selectedNode = node.selectChild() {
                    node = selectedNode
                } else {
                    break
                }
            }
            
            let possibleMoves = GameLogic.getAllPossibleMoves(for: node.currentPlayer, on: node.boardState)
            if !possibleMoves.isEmpty && GameLogic.checkForWinner(on: node.boardState, playerMapping: { $0.player }) == nil {
                for move in possibleMoves {
                    let nextPlayer = (node.currentPlayer == .cross) ? Player.circle : Player.cross
                    let newBoard = GameLogic.slide(board: node.boardState, from: move.source, to: move.destination, piece: .mark(node.currentPlayer))
                    let newNode = MCTSNode(boardState: newBoard, currentPlayer: nextPlayer, move: move, parent: node)
                    node.children.append(newNode)
                }
            }
            
            let rolloutNode = node.children.isEmpty ? node : node.children.randomElement()!
            let winner = rolloutNode.rollout()

            var tempNode: MCTSNode? = rolloutNode
            while tempNode != nil {
                tempNode!.visits += 1
                if let winner = winner {
                    if winner == .cross {
                        tempNode!.wins += 1
                    } else if winner == .circle {
                        tempNode!.wins -= 1
                    }
                }
                tempNode = tempNode!.parent
            }
        }
        
        var bestMove: (source: (row: Int, col: Int), destination: (row: Int, col: Int))? = nil
        var maxVisits = -1
        
        for child in rootNode.children {
            if child.visits > maxVisits {
                maxVisits = child.visits
                bestMove = child.move
            }
        }
        
        return bestMove ?? GameLogic.getAllPossibleMoves(for: .cross, on: board).randomElement()
    }
}
