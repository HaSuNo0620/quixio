// MyQuixio/AI/AlphaZeroAIPlayer.swift

import Foundation

// MARK: - AlphaZero MCTS Node
private class AlphaZeroNode {
    var move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?
    var parent: AlphaZeroNode?
    var children: [AlphaZeroNode] = []
    
    var visits: Int = 0
    var totalValue: Double = 0.0 // Q値: このノードの平均価値
    var priorProbability: Double = 0.0 // P値: ポリシーネットワークから得た事前確率
    
    var boardState: [[Piece]]
    var currentPlayer: Player

    init(boardState: [[Piece]], currentPlayer: Player, priorProbability: Double, move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))? = nil, parent: AlphaZeroNode? = nil) {
        self.boardState = boardState
        self.currentPlayer = currentPlayer
        self.priorProbability = priorProbability
        self.move = move
        self.parent = parent
    }
    
    /// UCB1スコアに似た、PUCTアルゴリズムに基づいて次に探索すべき子ノードを選択
    func selectChild() -> AlphaZeroNode? {
        let explorationConstant: Double = 1.5 // 探索の度合いを調整する定数
        var bestScore = -Double.infinity
        var bestChild: AlphaZeroNode?

        for child in children {
            let qValue = child.totalValue / (Double(child.visits) + 1e-8) // 平均価値
            let uValue = explorationConstant * child.priorProbability * sqrt(Double(self.visits)) / (1.0 + Double(child.visits))
            let score = qValue + uValue
            
            if score > bestScore {
                bestScore = score
                bestChild = child
            }
        }
        return bestChild
    }
}

// MARK: - AlphaZero AI Player
class AlphaZeroAIPlayer {
    
    private let predictionModel = PredictionModel.shared
    private let iterations: Int
    
    init(level: AILevel) {
        switch level {
        case .ultimate:
            self.iterations = 2000 // 高速な思考
        default:
            self.iterations = 200
        }
    }
    
    func getBestMove(for board: [[Piece]], currentPlayer: Player) -> (source: (row: Int, col: Int), destination: (row: Int, col: Int))? {
        
        let rootNode = AlphaZeroNode(boardState: board, currentPlayer: currentPlayer, priorProbability: 1.0)
        
        for _ in 0..<iterations {
            var node = rootNode
            
            // 1. Selection - UCBスコアが最も高いノードを末端まで選択
            while !node.children.isEmpty {
                if let selectedNode = node.selectChild() {
                    node = selectedNode
                } else {
                    break
                }
            }
            
            // 2. Expansion & Evaluation - 末端ノードを展開し、NNで評価
            let (policy, value) = expandAndEvaluate(node: node)
            
            // 3. Backup - 評価結果をルートまで遡って更新
            backup(node: node, value: value)
        }
        
        // 最終的に、最も訪問回数が多かった手を選択する
        var bestMove = rootNode.children.max(by: { $0.visits < $1.visits })?.move
        
        return bestMove ?? GameLogic.getAllPossibleMoves(for: currentPlayer, on: board).randomElement()
    }
    
    private func expandAndEvaluate(node: AlphaZeroNode) -> (policy: [Double]?, value: Double) {
        // 勝敗がついていれば、その結果を返す
        if let winnerInfo = GameLogic.checkForWinner(on: node.boardState, playerMapping: { $0.player }) {
            return (nil, winnerInfo.player == node.currentPlayer ? 1.0 : -1.0)
        }
        
        // NNで予測
        guard let prediction = predictionModel.predict(board: node.boardState, currentPlayer: node.currentPlayer) else {
            return (nil, 0.0) // 予測失敗時は価値0
        }
        
        // Expansion: 合法手に対応する子ノードを作成
        let legalMoves = GameLogic.getAllPossibleMoves(for: node.currentPlayer, on: node.boardState)
        let policySum = legalMoves.reduce(0.0) { sum, move in
            let index = moveToIndex(move: move)
            return sum + prediction.policy[index]
        }
        
        for move in legalMoves {
            let nextPlayer = (node.currentPlayer == .cross) ? Player.circle : Player.cross
            let newBoard = GameLogic.slide(board: node.boardState, from: move.source, to: move.destination, piece: .mark(node.currentPlayer))
            
            let index = moveToIndex(move: move)
            let priorProb = prediction.policy[index] / (policySum + 1e-8) // 合法手だけで確率を正規化
            
            let newNode = AlphaZeroNode(boardState: newBoard, currentPlayer: nextPlayer, priorProbability: priorProb, move: move, parent: node)
            node.children.append(newNode)
        }
        
        return (prediction.policy, prediction.value)
    }
    
    private func backup(node: AlphaZeroNode, value: Double) {
        var tempNode: AlphaZeroNode? = node
        var valueToPropagate = value
        
        while tempNode != nil {
            tempNode!.visits += 1
            // 相手の手番の価値は反転させる
            tempNode!.totalValue += (tempNode!.currentPlayer == node.currentPlayer) ? valueToPropagate : -valueToPropagate
            tempNode = tempNode!.parent
        }
    }
    
    // (source, dest) を 50次元のインデックスに変換するヘルパー
    private func moveToIndex(move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))) -> Int {
        let sourceIndex = move.source.row * 5 + move.source.col
        // destは現状使わないが、将来的な拡張のために残す
        // let destIndex = move.destination.row * 5 + move.destination.col
        return sourceIndex
    }
}
