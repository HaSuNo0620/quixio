import SwiftUI

class ThemeManager: ObservableObject {
    // ▼▼▼【この行を追加】▼▼▼
    static let shared = ThemeManager() // アプリ全体で共有するインスタンス

    @Published var currentTheme: Theme = .standard
    
    // ▼▼▼【追加】外部から新しいインスタンスを作れないようにする ▼▼▼
    private init() {}

    func applyTheme(_ theme: Theme) {
        self.currentTheme = theme
    }
}
