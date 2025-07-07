// Views/MatchmakingView.swift
import SwiftUI

struct MatchmakingView: View {
    @StateObject private var viewModel = OnlineGameViewModel()
    @Environment(\.dismiss) var dismiss
    
    // 経過時間タイマー用のState
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            if let game = viewModel.game {
                switch game.status {
                case .waiting:
                    Text("対戦相手を探しています...")
                        .font(.title)
                    ProgressView()
                        .padding()
                    // 経過時間表示
                                       Text("経過時間: \(elapsedTime)秒")
                                           .foregroundColor(.secondary)
                                       
                                       // キャンセルボタン
                                       Button("キャンセル") {
                                           viewModel.leaveGame() // ゲームセッションを削除
                                           dismiss() // 前の画面に戻る
                                       }
                                       .padding(.top, 40)
                                       .tint(.red)
                
                case .in_progress:
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
        .onAppear(perform: startTimer) // Viewが表示されたらタイマー開始
        .onDisappear(perform: stopTimer) // Viewが閉じられたらタイマー停止
        .navigationTitle("マッチメイキング")
        .navigationBarTitleDisplayMode(.inline)
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
