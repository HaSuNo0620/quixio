import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isShowingTutorial = false
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // --- タイトル ---
            VStack {
                Text("Quixio")
                    .customFont(.black, size: 64)
                Text("究極の戦略ボードゲーム")
                    .customFont(.medium, size: 18)
            }
            .foregroundColor(themeManager.currentTheme.accentColor)

            Spacer()

            // --- メインボタン ---
            // vs AI
            NavigationLink(destination: GameSetupView(viewModel: GameViewModel())) {
                Label("vs AI", systemImage: "person.fill")
                    .customFont(.bold, size: 22)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(themeManager.currentTheme.backgroundColor)
                    .cornerRadius(16)
                    .shadow(radius: 4, y: 4)
            }

            // vs 人
            NavigationLink(destination: HumanOpponentSelectionView()) {
                Label("vs 人", systemImage: "person.2.fill")
                    .customFont(.bold, size: 22)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeManager.currentTheme.accentColor.opacity(0.8)) // 少しスタイルを変える
                    .foregroundColor(themeManager.currentTheme.backgroundColor)
                    .cornerRadius(16)
                    .shadow(radius: 4, y: 4)
            }

            Spacer()

            // --- 設定などのボタン ---
            HStack(spacing: 30) {
                Button(action: { isShowingTutorial.toggle() }) {
                    Label("遊び方", systemImage: "info.circle.fill")
                        .customFont(.bold, size: 16)
                }
                
                Button(action: { isShowingSettings.toggle() }) {
                    Label("設定", systemImage: "gearshape.fill")
                        .customFont(.bold, size: 16)
                }
            }
            .foregroundColor(themeManager.currentTheme.accentColor.opacity(0.8))
            .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $isShowingTutorial) {
            TutorialView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .environmentObject(themeManager)
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .environmentObject(ThemeManager.shared)
    }
}
