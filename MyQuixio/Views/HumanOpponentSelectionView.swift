// MyQuixio/Views/HumanOpponentSelectionView.swift

import SwiftUI

struct HumanOpponentSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameService: GameService
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width

            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: screenWidth * 0.03) { // 👈 spacing
                    
                    Text("対戦方法を選択")
                        .customFont(.bold, size: screenWidth * 0.09) // 👈 font size
                        .foregroundColor(themeManager.currentTheme.textColor)

                    // オフライン対戦
                    NavigationLink(destination: GameView(viewModel: GameViewModel(gameMode: .vsHuman))) {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: screenWidth * 0.15)) // 👈 icon size
                            Text("オフラインで対戦")
                                .customFont(.medium, size: screenWidth * 0.05) // 👈 font size
                        }
                        .modifier(SelectionButtonModifier(color: themeManager.currentTheme.accentColor))
                    }
                    
                    // オンライン対戦
                    NavigationLink(destination: MatchmakingView(gameService: gameService)) {
                        VStack {
                            Image(systemName: "globe.asia.australia.fill")
                                .font(.system(size: screenWidth * 0.15)) // 👈 icon size
                            Text("オンラインで対戦")
                                .customFont(.medium, size: screenWidth * 0.05) // 👈 font size
                        }
                        .modifier(SelectionButtonModifier(color: themeManager.currentTheme.accentColor))
                    }
                }
                .padding(.horizontal, screenWidth * 0.05) // 👈 padding
            }
            .navigationTitle("友達と対戦")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ボタン用の共通モディファイア (もしなければViewModifiers.swiftなどに追加)
struct SelectionButtonModifier: ViewModifier {
    var color: Color
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.cellColor)
            .foregroundColor(color)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
    }
}
