// MyQuixio/AI/PredictionModel.swift

import CoreML
import Vision

/// Core MLモデル（QuixioModel.mlmodel）を管理し、予測を行うクラス
class PredictionModel {
    
    // シングルトンインスタンス
    static let shared = PredictionModel()
    
    private let model: QuixioModel?
    
    private init() {
        do {
            // 生成されたQuixioModelクラスのインスタンスを作成
            model = try QuixioModel(configuration: MLModelConfiguration())
        } catch {
            print("Error initializing Core ML model: \(error)")
            model = nil
        }
    }
    
    /// 現在の盤面と手番プレイヤーから、ポリシー（有望な手の確率）とバリュー（勝率）を予測する
    /// - Parameters:
    ///   - board: 現在の盤面 `[[Piece]]`
    ///   - currentPlayer: 現在の手番プレイヤー `Player`
    /// - Returns: (ポリシーの配列, バリュー) のタプル。予測に失敗した場合はnil。
    func predict(board: [[Piece]], currentPlayer: Player) -> (policy: [Double], value: Double)? {
        guard let model = model else {
            print("Model is not loaded.")
            return nil
        }
        
        do {
            // 1. 盤面データをモデルの入力形式（MLMultiArray）に変換
            let modelInput = try convertBoardToMLMultiArray(board: board, currentPlayer: currentPlayer)
            
            // 2. モデルにデータを入力して予測を実行
            let prediction = try model.prediction(input_1: modelInput)
            
            // 3. 予測結果を使いやすい形式に変換
            let policyOutput = prediction.policy
            let valueOutput = prediction.value
            
            // MLMultiArrayをSwiftの[Double]配列に変換
            let policyArray = (0..<policyOutput.count).map { Double(truncating: policyOutput[$0]) }
            let value = Double(truncating: valueOutput[0])
            
            return (policy: policyArray, value: value)
            
        } catch {
            print("Error during prediction: \(error)")
            return nil
        }
    }
    
    /// 盤面データをMLMultiArrayに変換するヘルパー関数
    private func convertBoardToMLMultiArray(board: [[Piece]], currentPlayer: Player) throws -> MLMultiArray {
        // モデルの入力形状は (1, 3, 5, 5) -> 1はバッチサイズ, 3はチャンネル, 5x5は盤面
        let multiArray = try MLMultiArray(shape: [1, 3, 5, 5], dataType: .float32)
        
        for r in 0..<5 {
            for c in 0..<5 {
                let piece = board[r][c]
                
                // チャンネル0: 自分の駒 (Circle)
                // チャンネル1: 相手の駒 (Cross)
                // チャンネル2: 手番プレイヤー (全員に1 or -1)
                
                // PyTorchの (C, H, W) 形式に合わせる
                let index1: [NSNumber] = [0, 0, NSNumber(value: r), NSNumber(value: c)]
                let index2: [NSNumber] = [0, 1, NSNumber(value: r), NSNumber(value: c)]
                
                switch piece {
                case .mark(.circle):
                    multiArray[index1] = 1.0
                    multiArray[index2] = 0.0
                case .mark(.cross):
                    multiArray[index1] = 0.0
                    multiArray[index2] = 1.0
                case .empty:
                    multiArray[index1] = 0.0
                    multiArray[index2] = 0.0
                }
            }
        }
        
        // チャンネル2に手番プレイヤーの情報を設定
        let playerValue: Float = (currentPlayer == .circle) ? 1.0 : -1.0
        for r in 0..<5 {
            for c in 0..<5 {
                let index3: [NSNumber] = [0, 2, NSNumber(value: r), NSNumber(value: c)]
                multiArray[index3] = NSNumber(value: playerValue)
            }
        }
        
        return multiArray
    }
}
