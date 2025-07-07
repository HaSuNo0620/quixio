// Views/MatchmakingView.swift
import SwiftUI

struct MatchmakingView: View {
    @StateObject private var viewModel = OnlineGameViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if let game = viewModel.game {
                // --- ゲームセッションが始まってからの表示 ---
                switch game.status {
                case .waiting:
                    Text("対戦相手を探しています...")
                        .font(.title)
                    ProgressView() // くるくる回るインジケータ
                case .in_progress:
                    Text("対戦相手が見つかりました！")
                        .font(.title)
                    Text("\(game.hostPlayerName) vs \(game.guestPlayerName ?? "...")")
                    // ここから実際のゲーム画面(ContentView)に遷移するロジックを後で追加
                case .finished:
                    Text("ゲーム終了！")
                        .font(.title)
                    // 勝敗表示などを後で追加
                }
            } else {
                // --- 初期画面 ---
                Text("オンライン対戦")
                    .font(.largeTitle)
                Button("対戦相手を探す") {
                    viewModel.startMatchmaking()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}
