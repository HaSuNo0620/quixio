// MARK: - HapticManager.swift

import SwiftUI

// アプリ全体でハプティクスを管理するクラス
class HapticManager {
    
    // シングルトンパターン：アプリ内で常に唯一のインスタンスを共有する
    static let shared = HapticManager()
    
    // プライベートなイニシャライザで、外部からのインスタンス化を防ぐ
    private init() { }
    
    // 衝撃のフィードバック
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    // 通知のフィードバック
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// 衝撃フィードバックを再生する
    /// - Parameter style: 衝撃の強さ (.light, .medium, .heavy, .soft, .rigid)
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 通知フィードバックを再生する
    /// - Parameter type: 通知の種類 (.success, .warning, .error)
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
}
