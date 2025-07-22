// Views/GameSetupView.swift

import SwiftUI

struct GameSetupView: View {
    // 前の画面(MainMenuView)からViewModelを受け取る
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isGameActive = false

    // GameSetupView.swift の body の中身を置き換え

    var body: some View {
        VStack(spacing: 20) {
            Text("AIの強さを選択")
                .customFont(.bold, size: 28)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.bottom, 40)
            
            // --- AIレベル選択ボタン ---
            ForEach(AILevel.allCases, id: \.self) { level in
                Button(action: {
                    viewModel.aiLevel = level
                }) {
                    HStack {
                        Image(systemName: level.iconName)
                            .font(.title)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                                .customFont(.bold, size: 18)
                            // ここに各レベルの説明文などを追加しても良い
                        }
                        Spacer()
                    }
                    .padding()
                    .background(themeManager.currentTheme.accentColor.opacity(viewModel.aiLevel == level ? 0.2 : 0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.aiLevel == level ? themeManager.currentTheme.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain) // ボタンのデフォルトスタイルを無効化して、カスタムスタイルを全面に適用
                .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            Spacer()
            
            // --- ゲーム開始ボタン ---
            NavigationLink(destination: ContentView(viewModel: viewModel), isActive: $isGameActive) { EmptyView() }
            
            Button("ゲーム開始") {
                self.isGameActive = true
            }
            .buttonStyle(PrimaryButtonStyle()) // 以前作成したボタンスタイルを適用
            
        }
        .padding()
        .navigationTitle("AI対戦設定")
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    NavigationStack {
        GameSetupView(viewModel: GameViewModel())
    }
}
