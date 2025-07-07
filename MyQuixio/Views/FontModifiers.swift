// Views/FontModifiers.swift

import SwiftUI

// フォント名をenumで管理すると、タイプミスを防げる
enum CustomFont: String {
    case bold = "MPLUSRounded1c-Bold"
    case regular = "MPLUSRounded1c-Regular"
    case medium = "MPLUSRounded1c-Medium"
    case light = "MPLUSRounded1c-Light"
    case thin = "MPLUSRounded1c-Thin"
    case black = "MPLUSRounded1c-Black"
    case extrabold = "MPLUSRounded1c-ExtraBold"
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
