// Views/ContentView.swift

import SwiftUI

struct ContentView: View {
    
    // 一人プレイ専用のViewModelを、自分自身で生成・管理する
    @StateObject private var viewModel = GameViewModel()
    
    @State private var isShowingResetAlert = false
    @State private var isShowingSettings: Bool = false
    @State private var invalidAttempts: Int = 0

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            VStack(spacing: 10) {
                Spacer()
                
                Text(viewModel.turnIndicatorText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextColor"))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                    .frame(height: 50)
                    .id("turnIndicator_" + viewModel.turnIndicatorText)

                GameBoardView(
                    board: viewModel.board, // GameViewModelが持つBindingを渡す
                    selectedCoordinate: $viewModel.selectedCoordinate,
                    onTapCell: { row, col in
                        viewModel.handleTap(onRow: row, col: col)
                    }
                )
                .shake(times: invalidAttempts)
                .onReceive(viewModel.invalidMovePublisher) { _ in
                    withAnimation(.default) {
                        self.invalidAttempts += 1
                    }
                }
                
                Spacer()
                
                Button {
                    isShowingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("ゲームをリセット")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AccentColor"))
                    .cornerRadius(12)
                    .shadow(radius: 5, y: 3)
                }
                .padding(.horizontal, 40)
                .padding(.vertical)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationView {
                    // GameViewModelを渡す
                    SettingsView(viewModel: viewModel)
                }
            }
                
            // 勝利画面
            if let winner = viewModel.winner {
                // (ここのコードは変更なし)
            }
            
            // AI思考中インジケーター
            if viewModel.isAITurn {
                // (ここのコードは変更なし)
            }
        }
        .alert("ゲームをリセット", isPresented: $isShowingResetAlert) {
            Button("リセットする", role: .destructive) { viewModel.resetGame() }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("現在のゲームの状況は失われます。本当によろしいですか？")
        }
        .onChange(of: viewModel.currentPlayer) {
            if viewModel.gameMode == .vsAI && viewModel.currentPlayer == .cross && viewModel.winner == nil {
                viewModel.triggerAIMove()
            }
        }
    }
}

#Preview {
    // ContentView自身がViewModelを持つので、引数は不要
    ContentView()
}
