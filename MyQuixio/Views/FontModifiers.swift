// Views/FontModifiers.swift

import SwiftUI

// フォント名をenumで管理すると、タイプミスを防げる
enum CustomFont: String {
    case bold = "RoundedMplus1c-Bold"
    case regular = "RoundedMplus1c-Regular"
    case medium = "RoundedMplus1c-Medium"
    case light = "RoundedMplus1c-Light"
    case thin = "RoundedMplus1c-Thin"
    case black = "RoundedMplus1c-Black"
    case extrabold = "RoundedMplus1c-ExtraBold"
    // 他のウェイトも追加可能
}

// 独自のViewModifierを定義
struct CustomFontModifier: ViewModifier {
    var font: CustomFont
    var size: CGFloat
    
    func body(content: Content) -> some View {
        content.font(.custom(font.rawValue, size: size))
    }
}

// .customFont()という形で簡単に呼び出せるようにするための拡張
extension View {
    func customFont(_ font: CustomFont, size: CGFloat) -> some View {
        self.modifier(CustomFontModifier(font: font, size: size))
    }
}
