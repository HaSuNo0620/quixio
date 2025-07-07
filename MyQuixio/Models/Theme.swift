// Models/Theme.swift

import SwiftUI

// アプリの配色テーマを定義する構造体
struct Theme: Identifiable, Equatable {
    let id = UUID()
    let name: String
    
    // UIの主要な色
    let accentColor: Color
    let backgroundColor: Color
    let textColor: Color
    let boardBackgroundColor: Color
    let cellColor: Color
    
    // 駒の色
    let circleColor: Color
    let crossColor: Color
    
    // Equatableに準拠させるために必要 (idだけで比較)
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - テーマの定義
extension Theme {
    
    // 1. 標準テーマ (私たちが今まで使ってきた色)
    static let standard = Theme(
        name: "標準 (Standard)",
        accentColor: Color("AccentColor"),
        backgroundColor: Color("AppBackground"),
        textColor: Color("TextColor"),
        boardBackgroundColor: Color("BoardBackground"),
        cellColor: Color("CellColor"),
        circleColor: Color("CircleColor"),
        crossColor: Color("CrossColor")
    )
    
    // 2. 森テーマ (緑と茶色を基調)
    static let forest = Theme(
        name: "森 (Forest)",
        accentColor: Color(hex: "#4CAF50"), // 深い緑
        backgroundColor: Color(hex: "#F5F5F5"), // 明るい背景
        textColor: Color(hex: "#3E2723"), // ダークブラウン
        boardBackgroundColor: Color(hex: "#A1887F"), // 木目調の茶色
        cellColor: Color(hex: "#D7CCC8"), // 明るい石の色
        circleColor: Color(hex: "#81C784"), // 葉っぱの緑
        crossColor: Color(hex: "#E65100")  // 紅葉のオレンジ
    )
    
    // 3. 海テーマ (青と白を基調)
    static let ocean = Theme(
        name: "海 (Ocean)",
        accentColor: Color(hex: "#2196F3"), // 鮮やかな青
        backgroundColor: Color(hex: "#E3F2FD"), // 薄い水色
        textColor: Color(hex: "#0D47A1"), // 深い青
        boardBackgroundColor: Color(hex: "#90A4AE"), // 曇り空の灰色
        cellColor: Color(hex: "#FFFFFF"), // 白
        circleColor: Color(hex: "#1DE9B6"), // エメラルドグリーン
        crossColor: Color(hex: "#FFC107")  // 砂浜の黄色
    )
    
    // アプリで利用可能な全テーマのリスト
    static let allThemes: [Theme] = [standard, forest, ocean]
}


// MARK: - 色を16進数で指定するためのヘルパー
// (このコードをファイルの末尾に追加してください)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
