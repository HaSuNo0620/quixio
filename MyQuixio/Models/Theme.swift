// MyQuixio/Models/Theme.swift

import Foundation
import SwiftUI

// Decodableプロトコルを追加して、JSONから初期化できるようにする
struct Theme: Identifiable, Decodable, Hashable {
    let id = UUID()
    let name: String
    let cellColor: Color
    let boardColor: Color
    let backgroundColor: Color
    let accentColor: Color
    let textColor: Color
    let circleColor: Color
    let crossColor: Color

    // JSONのキー("name", "cellColor"など)とプロパティ名を紐づける
    private enum CodingKeys: String, CodingKey {
        case name, cellColor, boardColor, backgroundColor, textColor, circleColor, crossColor,accentColor
    }

    // JSON読み込み失敗時のためのデフォルトテーマは残しておく
    static var `default`: Theme {
        return Theme(
            name: "Default",
            cellColor: Color("CellColor"),
            boardColor: Color("BoardBackground"),
            backgroundColor: Color("AppBackground"),
            accentColor: Color("AccentColor"),
            textColor: Color("TextColor"),
            circleColor: Color("CircleColor"),
            crossColor: Color("CrossColor")
        )
    }
}

// Color型を拡張して、16進数カラーコード文字列から初期化できるようにする
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (e.g. "FFF")
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (e.g. "FFFFFF")
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (e.g. "FFFFFFFF")
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Invalid format
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Theme {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let cellColorHex = try container.decode(String.self, forKey: .cellColor)
        cellColor = Color(hex: cellColorHex)

        let boardColorHex = try container.decode(String.self, forKey: .boardColor)
        boardColor = Color(hex: boardColorHex)

        let backgroundColorHex = try container.decode(String.self, forKey: .backgroundColor)
        backgroundColor = Color(hex: backgroundColorHex)
        
        let textColorHex = try container.decode(String.self, forKey: .textColor)
        textColor = Color(hex: textColorHex)
        
        // 👇 accentColorのデコード処理を追加
        let accentColorHex = try container.decode(String.self, forKey: .accentColor)
        accentColor = Color(hex: accentColorHex)
        
        let circleColorHex = try container.decode(String.self, forKey: .circleColor)
        circleColor = Color(hex: circleColorHex)
        
        let crossColorHex = try container.decode(String.self, forKey: .crossColor)
        crossColor = Color(hex: crossColorHex)
    }
}
