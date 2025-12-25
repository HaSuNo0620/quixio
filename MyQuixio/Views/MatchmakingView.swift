// Views/MatchmakingView.swift
import SwiftUI

struct MatchmakingView: View {
    @StateObject private var viewModel: OnlineGameViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    // 経過時間タイマー用のState
    @State private var elapsedTime = 0
    @State private var timer: Timer?

    init(gameService: GameService) {
        _viewModel = StateObject(wrappedValue: OnlineGameViewModel(gameService: gameService))
    }
    
    var body: some View {
        GeometryReader { geometry in // 👈 GeometryReaderを追加
            let screenWidth = geometry.size.width
            
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: screenWidth * 0.1)  {
                    if let game = viewModel.game {
                        switch game.status {
                        case .waiting:
                            Text("対戦相手を探しています...")
                                .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                                .foregroundColor(themeManager.currentTheme.textColor)
                            ProgressView()
                                .scaleEffect(screenWidth * 0.006) // 👈 scaleEffect
                                .tint(themeManager.currentTheme.accentColor)
                            // 経過時間表示
                            Text("経過時間: \(elapsedTime)秒")
                                .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                                .foregroundColor(.secondary)
                            
                            // キャンセルボタン
                            Button("キャンセル") {
                                Task {
                                    await viewModel.leaveGame() // leaveGameをawaitで呼び出す
                                    dismiss()
                                }
                            }
                            .padding(.top, screenWidth * 0.1) // 👈 padding
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            
                        case .in_progress:
                            NavigationLink(destination: OnlineGameView(viewModel: viewModel)) {
                                VStack(spacing: screenWidth * 0.1) {
                                    Text("対戦相手が見つかりました！")
                                        .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                                    Text("\(game.hostPlayerName) vs \(game.guestPlayerName ?? "...")")
                                        .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                                    Text("タップして対戦開始")
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                        .padding(.top)
                                }
                            }
                            
                        case .finished:
                            Text("ゲーム終了")
                                .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                        }
                    } else
                    {
                        Text("オンライン対戦")
                            .customFont(.medium, size: screenWidth * 0.06) // 👈 font size
                        Button("対戦相手を探す") {
                            viewModel.startMatchmaking() // こちらは内部でTaskを起動するので変更なし
                        }
                        .buttonStyle(.borderedProminent).padding()
                    }
                }
                }
                .onAppear(perform: startTimer) // Viewが表示されたらタイマー開始
                .onDisappear(perform: stopTimer) // Viewが閉じられたらタイマー停止
                .navigationTitle("マッチメイキング")
                .navigationBarTitleDisplayMode(.inline)
                .alert("エラー", isPresented: $viewModel.showErrorAlert) {
                    Button("OK") {
                        // アラートを閉じる
                        viewModel.showErrorAlert = false
                    }
                } message: {
                    Text(viewModel.errorMessage)
                }
            }
    }
    private func startTimer() {
           // 0.1秒ごとにelapsedTimeを更新するタイマー
           timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
               elapsedTime += 1
           }
       }
       
       private func stopTimer() {
           timer?.invalidate()
           timer = nil
           elapsedTime = 0
       }
}
