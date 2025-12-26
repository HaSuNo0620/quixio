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
        let explorationConstant: Double = 1.5 // 探索の度合いを調整する定数 (c_puct)
        var bestScore = -Double.infinity
        var bestChild: AlphaZeroNode?

        for child in children {
            // Q(s,a): 子ノードの平均価値
            let qValue = child.totalValue / (Double(child.visits) + 1e-8)
            
            // U(s,a): 探索ボーナス項
            // P(s,a) * (sqrt(N(s)) / (1 + N(s,a)))
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
    private let config: AlphaZeroConfig
    private let allowPushingOpponent = false // ルールに合わせて相手駒を押さない合法手のみを探索

    init(config: AlphaZeroConfig) {
        self.config = config
    }

    convenience init(level: AILevel) {
        self.init(config: AlphaZeroConfig.forLevel(level))
    }
    
    /// - Parameters:
    ///   - board: 現在の盤面
    ///   - currentPlayer: 現在のプレイヤー
    ///   - isTraining: 自己対戦の学習データ生成モードか否か
    ///   - temperature: 手の選択のランダム性を制御する温度パラメータ
    /// - Returns: 最善手と探索確率のタプル
    func getBestMove(
        for board: [[Piece]],
        currentPlayer: Player,
        isTraining: Bool = false,
        temperature: Double? = nil
    ) -> (move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?, policy: [Move: Double]) {
        let resolvedTemperature = temperature ?? config.temperature
        
        let rootNode = AlphaZeroNode(boardState: board, currentPlayer: currentPlayer, priorProbability: 1.0)
        
        // 最初にルートノードを展開・評価
        expandAndEvaluate(node: rootNode)
        
        // 【★修正】自己対戦（学習）時のみ、探索の多様性を確保するためにルートノードにディリクレノイズを追加
        if isTraining || config.addDirichletNoise {
            addDirichletNoise(to: rootNode)
        }
        
        for _ in 0..<config.iterations {
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
            let value = expandAndEvaluate(node: node)
            
            // 3. Backup - 評価結果をルートまで遡って更新
            backup(node: node, value: value)
        }
        
        // 【★修正】最終的な手の選択と探索確率の計算
        let (bestMove, policy) = selectMoveAndCreatePolicy(from: rootNode, temperature: resolvedTemperature)
        
        // 万が一手が選択できなかった場合のフォールバック
        guard let finalMove = bestMove else {
            let randomMove = GameLogic.getAllPossibleMoves(for: currentPlayer, on: board, allowPushingOpponent: allowPushingOpponent).randomElement()
            return (randomMove, [:])
        }
        
        return (finalMove, policy)
    }
    
    private func expandAndEvaluate(node: AlphaZeroNode) -> Double {
        // 勝敗がついていれば、その結果を返す
        if let winnerInfo = GameLogic.checkForWinner(on: node.boardState, playerMapping: { $0.player }) {
            // ゲームの価値は現在の手番のプレイヤーから見たもの
            return winnerInfo.player == node.currentPlayer ? 1.0 : -1.0
        }
        
        // NNで予測
        guard let prediction = predictionModel.predict(board: node.boardState, currentPlayer: node.currentPlayer) else {
            // モデル未ロード時は一様分布のポリシーで展開し、価値は中立とする
            let fallbackMoves = GameLogic.getAllPossibleMoves(for: node.currentPlayer, on: node.boardState, allowPushingOpponent: allowPushingOpponent)
            if fallbackMoves.isEmpty { return 0.0 }
            let prior = 1.0 / Double(fallbackMoves.count)
            for move in fallbackMoves {
                let nextPlayer = (node.currentPlayer == .cross) ? Player.circle : Player.cross
                let newBoard = GameLogic.slide(board: node.boardState, from: move.source, to: move.destination, piece: .mark(node.currentPlayer))
                let newNode = AlphaZeroNode(boardState: newBoard, currentPlayer: nextPlayer, priorProbability: prior, move: move, parent: node)
                node.children.append(newNode)
            }
            return 0.0
        }
        
        // Expansion: 合法手に対応する子ノードを作成
        let legalMoves = GameLogic.getAllPossibleMoves(for: node.currentPlayer, on: node.boardState, allowPushingOpponent: allowPushingOpponent)
        if legalMoves.isEmpty {
             return 0.0 // 手がない場合は引き分け
        }
        
        let policySum = legalMoves.reduce(0.0) { sum, move in
            let index = moveToIndex(move: move)
            return sum + prediction.policy[index]
        }
        
        for move in legalMoves {
            let nextPlayer = (node.currentPlayer == .cross) ? Player.circle : Player.cross
            // slideメソッドは新しい盤面を返す想定
            let newBoard = GameLogic.slide(board: node.boardState, from: move.source, to: move.destination, piece: .mark(node.currentPlayer))
            
            let index = moveToIndex(move: move)
            // 合法手だけで確率を正規化
            let priorProb = prediction.policy[index] / (policySum + 1e-8)
            
            let newNode = AlphaZeroNode(boardState: newBoard, currentPlayer: nextPlayer, priorProbability: priorProb, move: move, parent: node)
            node.children.append(newNode)
        }
        
        // NNから予測された現在の盤面の価値を返す
        return prediction.value
    }
    
    private func backup(node: AlphaZeroNode, value: Double) {
        var tempNode: AlphaZeroNode? = node
        
        while let currentNode = tempNode {
            currentNode.visits += 1
            // 価値は常に「そのノードの手番のプレイヤー」から見たものになるように調整
            // 親ノードは相手の手番なので、価値を反転させる
            let valueForNode = (currentNode.currentPlayer == node.currentPlayer) ? value : -value
            currentNode.totalValue += valueForNode
            tempNode = currentNode.parent
        }
    }
    
    // 【★追加】ディリクレノイズを追加するメソッド
    private func addDirichletNoise(to node: AlphaZeroNode) {
        // AlphaZero論文で使われているパラメータ
        let epsilon = 0.25
        let alpha: Double = 0.03

        // ガンマ分布からサンプリングするのが正しいが、簡易的に実装
        var noise = (0..<node.children.count).map { _ in -log(Double.random(in: 1e-8...1.0)) * alpha }
        let noiseSum = noise.reduce(0, +)
        if noiseSum > 0 {
            noise = noise.map { $0 / noiseSum }
        }

        for (i, child) in node.children.enumerated() {
            child.priorProbability = (1.0 - epsilon) * child.priorProbability + epsilon * noise[i]
        }
    }
    
    // 【★追加】温度パラメータに基づいて手を選択し、学習用のポリシーを生成するメソッド
    private func selectMoveAndCreatePolicy(from rootNode: AlphaZeroNode, temperature: Double) -> (move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?, policy: [Move: Double]) {
        
        guard !rootNode.children.isEmpty else {
            return (nil, [:])
        }

        var policy: [Move: Double] = [:]
        
        // ポリシー(学習ターゲット)の計算: 正規化された訪問回数
        let totalVisits = Double(rootNode.children.reduce(0) { $0 + $1.visits })
        if totalVisits > 0 {
            for child in rootNode.children {
                if let move = child.move {
                    let moveKey = Move(source: .init(row: move.source.row, col: move.source.col),
                                       destination: .init(row: move.destination.row, col: move.destination.col))
                    policy[moveKey] = Double(child.visits) / totalVisits
                }
            }
        }

        // 手の選択
        let selectedMove: (source: (row: Int, col: Int), destination: (row: Int, col: Int))?
        
        if temperature < 1e-4 { // 温度がほぼ0なら、最も訪問回数が多い手を確定的に選択 (Greedy)
            selectedMove = rootNode.children.max(by: { $0.visits < $1.visits })?.move
        } else { // 温度が0より大きいなら、訪問回数に応じた確率で手を選択
            let visitCounts = rootNode.children.map { pow(Double($0.visits), 1.0 / temperature) }
            let sumCounts = visitCounts.reduce(0, +)
            
            guard sumCounts > 0 else {
                return (rootNode.children.randomElement()?.move, policy)
            }
            
            let probabilities = visitCounts.map { $0 / sumCounts }
            
            let randomValue = Double.random(in: 0...1)
            var cumulativeProbability: Double = 0.0
            var selectedIndex = rootNode.children.count - 1 // フォールバック
            for i in 0..<rootNode.children.count {
                cumulativeProbability += probabilities[i]
                if randomValue < cumulativeProbability {
                    selectedIndex = i
                    break
                }
            }
            selectedMove = rootNode.children[selectedIndex].move
        }
        
        return (selectedMove, policy)
    }
    
    // (source, dest) を 50次元のインデックスに変換するヘルパー
    private func moveToIndex(move: (source: (row: Int, col: Int), destination: (row: Int, col: Int))) -> Int {
        let sourceIndex = move.source.row * 5 + move.source.col
        // destは現状使わないが、将来的な拡張のために残す
        // let destIndex = move.destination.row * 5 + move.destination.col
        return sourceIndex
    }
}
