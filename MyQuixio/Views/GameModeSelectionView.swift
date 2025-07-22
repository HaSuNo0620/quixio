import SwiftUI

struct GameModeSelectionView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("対戦モードを選択")
                .customFont(.bold, size: 28)
                .padding(.bottom, 40)

            // AIと対戦
            NavigationLink {
                GameSetupView(viewModel: GameViewModel())
            } label: {
                Text("AIと対戦")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor) // Color.themeが使えるようになります
                    .foregroundColor(themeManager.currentTheme.backgroundColor)
                    .cornerRadius(12)
            }

            // オンラインで対戦
            NavigationLink {
                MatchmakingView()
            } label: {
                Text("オンラインで対戦")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(themeManager.currentTheme.backgroundColor)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("モード選択")
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// プレビュー用のコードも修正
struct GameModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GameModeSelectionView()
        }
    }
}
