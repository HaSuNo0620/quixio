// Views/MatchmakingView.swift
import SwiftUI

struct MatchmakingView: View {
    @StateObject private var viewModel = OnlineGameViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if let game = viewModel.game {
                switch game.status {
                case .waiting:
                    Text("対戦相手を探しています...")
                        .font(.title)
                    ProgressView()
                
                case .in_progress:
                    // 👇 正しい遷移先を指定する
                    NavigationLink(destination: OnlineGameView(viewModel: viewModel)) {
                        VStack(spacing: 10) {
                            Text("対戦相手が見つかりました！")
                                .font(.title)
                            Text("\(game.hostPlayerName) vs \(game.guestPlayerName ?? "...")")
                                .font(.headline)
                            Text("タップして対戦開始").foregroundColor(.accentColor).padding(.top)
                        }
                    }

                case .finished:
                    Text("ゲーム終了").font(.title)
                }
            } else {
                Text("オンライン対戦").font(.largeTitle)
                Button("対戦相手を探す") {
                    viewModel.startMatchmaking()
                }
                .buttonStyle(.borderedProminent).padding()
            }
        }
        .navigationTitle("マッチメイキング")
        .navigationBarTitleDisplayMode(.inline)
    }
}
