// Views/GameSetupView.swift

import SwiftUI

struct GameSetupView: View {
    // 前の画面(MainMenuView)からViewModelを受け取る
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        Form {
            // MARK: - 対戦相手の選択
            Section(header: Text("対戦相手を選ぶ")) {
                // 👇 @Stateではなく、viewModelのプロパティに直接バインディングする
                Picker("モード", selection: $viewModel.gameMode) {
                    Label("vs AI", systemImage: "desktopcomputer").tag(GameMode.vsAI)
                    Label("vs 人間", systemImage: "person.2").tag(GameMode.vsHuman)
                }
                .pickerStyle(.segmented)
            }

            // MARK: - AIの強さの選択
            // 👇 viewModelの状態で表示を切り替える
            if viewModel.gameMode == .vsAI {
                Section(header: Text("AIの強さ")) {
                    Picker("AIの強さ", selection: $viewModel.aiLevel) {
                        ForEach(AILevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.inline) // より選択しやすいスタイルに変更
                    .labelsHidden() // Pickerのラベルは不要なので隠す
                }
            }
            
            // MARK: - ゲーム開始ボタン
            Section {
                // 👇 NavigationLinkの.onAppearを削除し、シンプルにする
                NavigationLink(destination: ContentView(viewModel: viewModel)) {
                    HStack {
                        Spacer()
                        Text("ゲーム開始")
                            .font(.headline.bold())
                        Spacer()
                    }
                }
                .foregroundColor(Color("AccentColor"))
            }
        }
        .navigationTitle("ゲーム設定")
        .background(Color("AppBackground").ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .onAppear {
            // この画面が表示されたら、必ずゲームをリセットする
            viewModel.resetGame()
        }
    }
}

#Preview {
    NavigationStack {
        GameSetupView(viewModel: GameViewModel())
    }
}
