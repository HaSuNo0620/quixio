import SwiftUI

struct HumanOpponentSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            Text("対戦方法を選択")
                .customFont(.bold, size: 28)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.bottom, 40)

            // オンライン対戦
            NavigationLink(destination: MatchmakingView()) {
                VStack(alignment: .leading) {
                    Text("オンライン対戦")
                        .customFont(.bold, size: 18)
                    Text("世界中のプレイヤーと対戦")
                    .customFont(.regular, size: 14)
                    .opacity(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(themeManager.currentTheme.accentColor)
                .foregroundColor(themeManager.currentTheme.backgroundColor)
                .cornerRadius(12)
            }

            // オフライン対戦（1台で）
            NavigationLink(destination: GameView(viewModel: GameViewModel(gameMode: .vsHuman))) {
                VStack(alignment: .leading) {
                    Text("オフライン対戦 (1台で)")
                        .customFont(.bold, size: 18)
                    Text("このデバイスを交互に使って対戦")
                        .customFont(.regular, size: 14)
                        .opacity(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(themeManager.currentTheme.accentColor)
                .foregroundColor(themeManager.currentTheme.backgroundColor)
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("対人戦")
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

struct HumanOpponentSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HumanOpponentSelectionView()
                .environmentObject(ThemeManager())
        }
    }
}
