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
                    // 👇 ここをNavigationLinkに書き換える
                    NavigationLink(destination: OnlineGameView(viewModel: viewModel)) {
                        VStack {
                            Text("対戦相手が見つかりました！")
                                .font(.title)
                            Text("\(game.hostPlayerName) vs \(game.guestPlayerName ?? "...")")
                                .font(.headline)
                                .padding(.top, 5)
                            Text("タップして対戦開始")
                                .foregroundColor(Color("AccentColor"))
                                .padding(.top, 20)
                        }
                    }

                case .finished:
                    // (変更なし)
                    Text("ゲーム終了！")
                        .font(.title)
                }
            } else {
                // (変更なし)
                Text("オンライン対戦")
                    .font(.largeTitle)
                Button("対戦相手を探す") {
                    viewModel.startMatchmaking()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("マッチメイキング")
        .navigationBarTitleDisplayMode(.inline)
    }
}
