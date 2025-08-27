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

struct FlipAnimationModifier: ViewModifier {
    var isFlipped: Bool
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0) // Y軸を中心に回転
            )
    }
}

extension View {
    func flip(isFlipped: Bool) -> some View {
        self.modifier(FlipAnimationModifier(isFlipped: isFlipped))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .customFont(.bold, size: 18)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.accentColor)
            .foregroundColor(themeManager.currentTheme.backgroundColor)
            .cornerRadius(12)
            // ボタンが押されている時に少し縮むエフェクト
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct MainButtonModifier: ViewModifier {
    var color: Color
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .customFont(.bold, size: 28)
            .frame(maxWidth: 280, minHeight: 44)
            .padding(.vertical, 8)
            .background(color)
            .foregroundColor(themeManager.currentTheme.backgroundColor)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
    }
}
