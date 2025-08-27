import SwiftUI

struct GameSetupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedAILevel: AILevel = .medium
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                Text("AIの強さを選択")
                    .customFont(.bold, size: 32)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                VStack(spacing: 20) {
                    ForEach(AILevel.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedAILevel = level
                            }
                        } label: {
                            Text(level.rawValue)
                                .customFont(.bold, size: 22)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAILevel == level ? themeManager.currentTheme.accentColor : themeManager.currentTheme.accentColor.opacity(0.1))
                                .foregroundColor(selectedAILevel == level ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // ゲーム開始ボタン
                NavigationLink {
                    GameView(viewModel: GameViewModel(gameMode: .vsAI, aiLevel: selectedAILevel))
                } label: {
                    Text("ゲーム開始")
                        .customFont(.bold, size: 24)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("AIと対戦")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GameSetupView()
                .environmentObject(ThemeManager())
        }
    }
}
