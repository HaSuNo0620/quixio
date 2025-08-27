import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: screenWidth * 0.05) { // spacing
                    Text("Quixio")
                        // フォントサイズを画面幅の20%に
                        .font(.custom("MPLUSRounded1c-Black", size: screenWidth * 0.2))
                        .foregroundColor(themeManager.currentTheme.textColor)
                        // paddingを画面幅の10%に
                        .padding(.bottom, screenWidth * 0.1)

                    // コンピュータと対戦する画面へのリンク
                    NavigationLink(destination: GameSetupView()) {
                        Text("コンピュータと対戦")
                            // 画面幅に応じて計算した値を渡す
                            .modifier(MainButtonModifier(
                                color: themeManager.currentTheme.accentColor,
                                fontSize: screenWidth * 0.07,
                                verticalPadding: screenWidth * 0.03,
                                cornerRadius: screenWidth * 0.04
                            ))
                    }

                    // 友達と対戦する画面へのリンク
                    NavigationLink(destination: HumanOpponentSelectionView()) {
                        Text("友達と対戦")
                            .modifier(MainButtonModifier(
                                color: themeManager.currentTheme.accentColor,
                                fontSize: screenWidth * 0.07,
                                verticalPadding: screenWidth * 0.03,
                                cornerRadius: screenWidth * 0.04
                            ))
                    }
                    
                    // チュートリアル画面へのリンク
                    NavigationLink(destination: TutorialView()) {
                        Text("あそびかた")
                            .modifier(MainButtonModifier(
                                color: themeManager.currentTheme.accentColor,
                                fontSize: screenWidth * 0.07,
                                verticalPadding: screenWidth * 0.03,
                                cornerRadius: screenWidth * 0.04
                            ))
                    }
                    
                    // 設定画面へのリンク
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .padding(screenWidth * 0.03) // padding
                            .background(themeManager.currentTheme.cellColor)
                            .clipShape(Circle())
                    }
                    .padding(.top, screenWidth * 0.05) // padding
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// ... Preview ...
