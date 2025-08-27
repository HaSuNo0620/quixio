// MyQuixio/Views/MainMenuView.swift

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Quixio")
                    .font(.custom("MPLUSRounded1c-Black", size: 60))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.bottom, 30) // タイトルとボタンの間にスペースを追加

                // --- 👇 「プレイ」ボタンを2つのボタンに置き換え ---
                
                // コンピュータと対戦する画面へのリンク
                NavigationLink(destination: GameSetupView()) {
                    Text("コンピュータと対戦")
                        .modifier(MainButtonModifier(color: themeManager.currentTheme.accentColor))
                }

                // 友達と対戦する画面へのリンク
                NavigationLink(destination: HumanOpponentSelectionView()) {
                    Text("友達と対戦")
                        .modifier(MainButtonModifier(color: themeManager.currentTheme.accentColor))
                }
                
                // --- 👆 ここまでが変更点 ---

                // チュートリアル画面へのリンク
                NavigationLink(destination: TutorialView()) {
                    Text("あそびかた")
                        .modifier(MainButtonModifier(color: themeManager.currentTheme.accentColor))
                }
                
                // 設定画面へのリンク
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(10)
                        .background(themeManager.currentTheme.cellColor)
                        .clipShape(Circle())
                }
                .padding(.top, 20) // 設定ボタンの上にスペースを追加
            }
        }
        .navigationBarHidden(true)
    }
}


struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainMenuView()
                .environmentObject(ThemeManager())
        }
    }
}
