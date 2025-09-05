import SwiftUI

struct GameSetupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedAILevel: AILevel = .medium
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: screenWidth * 0.1) { // 👈 spacing
                    Spacer()
                    
                    Text("AIの強さを選択")
                        .customFont(.bold, size: screenWidth * 0.08) // 👈 font size
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    VStack(spacing: screenWidth * 0.05) { // 👈 spacing
                        ForEach(AILevel.allCases, id: \.self) { level in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedAILevel = level
                                }
                            } label: {
                                Text(level.rawValue)
                                    .customFont(.bold, size: screenWidth * 0.08) // 👈 font size
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedAILevel == level ? themeManager.currentTheme.accentColor : themeManager.currentTheme.accentColor.opacity(0.1))
                                    .foregroundColor(selectedAILevel == level ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                                    .cornerRadius(screenWidth * 0.03) // 👈 corner radius
                            }
                        }
                    }
                    .padding(.horizontal, screenWidth * 0.05) // 👈 padding
                    
                    // ゲーム開始ボタン
                    NavigationLink {
                        GameView(viewModel: GameViewModel(gameMode: .vsAI, aiLevel: selectedAILevel))
                    } label: {
                        Text("ゲーム開始")
                            .customFont(.bold, size: screenWidth * 0.06) // 👈 font size
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LinearGradient(gradient: Gradient(colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(screenWidth * 0.03) // 👈 corner radius
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, screenWidth * 0.1) // 👈 padding
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("AIと対戦")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
