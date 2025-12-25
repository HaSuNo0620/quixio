// MyQuixio/Views/TutorialPageView.swift

import SwiftUI

struct TutorialPageView: View {
    let imageName: String
    let title: String
    let description: String

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width

            VStack(spacing: screenHeight * 0.05) { // 👈 spacing
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    // 画像の高さを画面の高さの40%に設定
                    .frame(height: screenHeight * 0.4)
                    .cornerRadius(20)
                    .shadow(radius: 5)

                VStack(alignment: .center, spacing: screenHeight * 0.03) { // 👈 spacing
                    Text(title)
                        .customFont(.bold, size: screenWidth * 0.08) // 👈 font size
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .customFont(.regular, size: screenWidth * 0.045) // 👈 font size
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(screenWidth * 0.02) // 👈 line spacing
                }
                // 水平パディングを画面幅の8%に
                .padding(.horizontal, screenWidth * 0.08)
            }
            .frame(width: screenWidth, height: screenHeight) // VStackを中央に配置
        }
    }
}
