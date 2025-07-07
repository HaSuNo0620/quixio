// Views/OnlineGameView.swift

import SwiftUI

struct OnlineGameView: View {
    
    // オンライン専用のViewModelを受け取る
    @ObservedObject var viewModel: OnlineGameViewModel
    
    // このViewを閉じてマッチメイキング画面に戻るためのもの
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack(spacing: 10) {
                Spacer()
                
                // OnlineGameViewModelが提供するテキストを表示
                Text(viewModel.turnIndicatorText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                    .frame(height: 50)
                    .id(viewModel.turnIndicatorText) // テキストの変更を確実に検知

                // 盤面表示
                GameBoardView(
                    board: viewModel.displayBoard, // OnlineGameViewModelが提供する盤面
                    selectedCoordinate: $viewModel.selectedCoordinate,
                    onTapCell: { row, col in
                        viewModel.handleTap(onRow: row, col: col)
                    }
                )
                
                Spacer()
                
                // TODO: オンライン用の「降参する」ボタンなどを後で実装
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true) // 標準の戻るボタンを隠す
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("対戦をやめる") {
                        // TODO: "本当にやめますか？"というアラートを出す
                        viewModel.leaveGame() // ゲームから離脱する処理を呼び出す
                        dismiss() // 画面を閉じる
                    }
                }
            }
            
            // 勝利/敗北画面
            if viewModel.isGameFinished {
                 Rectangle()
                     .fill(.ultraThinMaterial)
                     .ignoresSafeArea()
                     .transition(.opacity.animation(.easeIn))

                 VStack(spacing: 20) {
                     Text(viewModel.winnerMessage) // ViewModelからのメッセージ
                         .font(.system(size: 40, weight: .heavy, design: .rounded))
                     
                     Button {
                         dismiss() // マッチメイキング画面に戻る
                     } label: {
                         Text("OK")
                             .font(.system(.title3, design: .rounded).bold())
                             .padding(.horizontal, 40)
                             .padding(.vertical, 15)
                             .background(Color("AccentColor"))
                             .foregroundColor(.white)
                             .clipShape(Capsule())
                     }
                     .padding(.top, 30)
                 }
                 .padding(40)
                 .background(.regularMaterial)
                 .cornerRadius(25)
                 .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                 .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    // プレビュー用に、中身が入ったViewModelを渡す
    let previewViewModel = OnlineGameViewModel()
    let initialBoard = Array(repeating: "empty", count: 25)
    previewViewModel.game = GameSession(board: initialBoard, hostPlayerID: "p1", guestPlayerID: "p2", hostPlayerName: "Player 1", guestPlayerName: "Player 2", status: .in_progress, currentPlayerTurn: .host, winner: nil, createdAt: Timestamp())
    
    return NavigationStack {
        OnlineGameView(viewModel: previewViewModel)
    }
}
