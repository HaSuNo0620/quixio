import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // 背景色をZStackで管理
            themeManager.currentTheme.backgroundColor
                .edgesIgnoringSafeArea(.all)

            // GeometryReaderで画面サイズを取得
            GeometryReader { geometry in
                VStack {
                    // 上部の余白
                    Spacer()

                    // ターン表示テキスト
                    Text(viewModel.turnIndicatorText)
                        // フォントサイズを画面幅に応じて調整
                        .customFont(.medium, size: geometry.size.width * 0.07)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .padding(.vertical)

                    // ゲーム盤
                    GameBoardView(
                        board: viewModel.board,
                        selectedCoordinate: $viewModel.selectedCoordinate,
                        onTapCell: { row, col in
                            viewModel.handleTap(onRow: row, col: col)
                        }
                    )
                    .onAppear {
                        viewModel.resetGame()
                    }
                    .onChange(of: viewModel.currentPlayer) { _ in
                        if viewModel.gameMode == .vsAI {
                            viewModel.triggerAIMove()
                        }
                    }
                    .onReceive(viewModel.invalidMovePublisher) {
                        alertMessage = "そこには置けません"
                        showingAlert = true
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("無効な操作"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    
                    // 下部の余白
                    Spacer()
                }
                // VStackがGeometryReaderの全領域を使うように設定
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .navigationTitle(viewModel.gameMode == .vsAI ? "AIと対戦" : "オフライン対戦")
        .navigationBarTitleDisplayMode(.inline)
    }
}
