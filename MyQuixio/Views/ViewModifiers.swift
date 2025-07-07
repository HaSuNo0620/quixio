// Views/ViewModifiers.swift

import SwiftUI

// シェイクアニメーションを定義する本体
struct ShakeEffect: AnimatableModifier {
    var times: CGFloat = 0
    let amplitude: CGFloat = 10 // 揺れ幅

    var animatableData: CGFloat {
        get { times }
        set { times = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: sin(times * .pi * 2) * amplitude)
    }
}

// .shake() という形で簡単に呼び出せるようにするためのView拡張
extension View {
    func shake(times: Int) -> some View {
        self.modifier(ShakeEffect(times: CGFloat(times)))
    }
}
