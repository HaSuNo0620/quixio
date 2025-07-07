// MARK: - GameSetupView.swift

import SwiftUI

struct GameSetupView: View {
    // 前の画面(MainMenuView)からViewModelを受け取る
    @ObservedObject var viewModel: GameViewModel
    
    // この画面の中だけで使う、選択内容を一時的に保持する変数
    @State private var selectedGameMode: GameMode = .vsAI
    @State private var selectedAILevel: AILevel = .normal

    var body: some View {
        // FormをVStackの代わりにトップレベルのコンテナにする
        Form {
            // MARK: - 対戦相手の選択
            Section(header: Text("対戦相手を選ぶ")) {
                Picker("モード", selection: $selectedGameMode) {
                    Label("vs AI", systemImage: "desktopcomputer").tag(GameMode.vsAI)
                    Label("vs 人間", systemImage: "person.2").tag(GameMode.vsHuman)
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear) // 背景色をクリアに

            // MARK: - AIの強さの選択 (vs AIが選ばれている時だけ表示)
            if selectedGameMode == .vsAI {
                Section(header: Text("AIの強さ")) {
                    // カスタムリスト形式でAIレベルを選択
                    ForEach(AILevel.allCases, id: \.self) { level in
                        HStack {
                            Text(level.rawValue)
                            Spacer()
                            if selectedAILevel == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AccentColor"))
                            }
                        }
                        .contentShape(Rectangle()) // 行全体をタップ可能に
                        .onTapGesture {
                            selectedAILevel = level
                        }
                    }
                }
            }
            
            // MARK: - ゲーム開始ボタン
            Section {
                NavigationLink {
                    // ゲーム画面に遷移する
                    ContentView(viewModel: viewModel)
                        .onAppear {
                            // ゲーム画面が表示される直前に、設定をViewModelに反映させる
                            viewModel.gameMode = self.selectedGameMode
                            if self.selectedGameMode == .vsAI {
                                viewModel.aiLevel = self.selectedAILevel
                            }
                            viewModel.resetGame()
                        }
                } label: {
                    HStack {
                        Spacer()
                        Text("ゲーム開始")
                            .font(.headline.bold())
                        Spacer()
                    }
                }
                .foregroundColor(Color("AccentColor"))
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("ゲーム設定")
        // Form自体に背景色を設定すると、スクロールしても追従する
        .background(Color("AppBackground").ignoresSafeArea())
        .scrollContentBackground(.hidden) // iOS 16以降のForm背景色の設定方法
    }
}

#Preview {
    NavigationStack {
        GameSetupView(viewModel: GameViewModel())
    }
}
