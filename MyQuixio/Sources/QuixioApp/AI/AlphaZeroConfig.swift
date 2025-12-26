import Foundation

/// AlphaZero 系AIの探索パラメータをまとめた設定オブジェクト。
/// - iterations: MCTSの反復回数
/// - temperature: 行動選択の温度パラメータ（0に近いほど貪欲）
/// - addDirichletNoise: ルートノードに探索多様性のノイズを付与するか
struct AlphaZeroConfig {
    let iterations: Int
    let temperature: Double
    let addDirichletNoise: Bool

    static func forLevel(_ level: AILevel) -> AlphaZeroConfig {
        switch level {
        case .ultimate:
            return AlphaZeroConfig(iterations: 2000, temperature: 0.0, addDirichletNoise: false)
        #if DEBUG
        case .forDataGeneration:
            // データ生成時は多様性を確保する
            return AlphaZeroConfig(iterations: 400, temperature: 1.0, addDirichletNoise: true)
        #endif
        default:
            return AlphaZeroConfig(iterations: 200, temperature: 0.0, addDirichletNoise: false)
        }
    }
}
