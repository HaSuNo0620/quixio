// MARK: - HapticManager.swift

import SwiftUI

// アプリ全体でハプティクスを管理するクラス
class HapticManager: ObservableObject {

    // シングルトンパターン：アプリ内で常に唯一のインスタンスを共有する
    static let shared = HapticManager()

    // プライベートなイニシャライザで、外部からのインスタンス化を防ぐ
    private init() { }

    // 通知のフィードバック
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // 設定値を永続化しつつ、UIとバインドできるようにする
    @Published var isHapticsEnabled: Bool = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "isHapticsEnabled")
        }
    }

    /// 衝撃フィードバックを再生する
    /// - Parameter style: 衝撃の強さ (.light, .medium, .heavy, .soft, .rigid)
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 通知フィードバックを再生する
    /// - Parameter type: 通知の種類 (.success, .warning, .error)
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
}
