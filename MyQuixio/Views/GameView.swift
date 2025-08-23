import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            // ターン表示テキスト
            Text(viewModel.turnIndicatorText)
                .customFont(.medium, size: 24)
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
            
            Spacer()
        }
        .navigationTitle(viewModel.gameMode == .vsAI ? "AIと対戦" : "オフライン対戦")
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}
