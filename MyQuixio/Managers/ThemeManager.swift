// Managers/ThemeManager.swift
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .standard // デフォルトテーマ
    
    func applyTheme(_ theme: Theme) {
        self.currentTheme = theme
    }
}
