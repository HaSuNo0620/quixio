// Views/OnlineGameView.swift
import SwiftUI
import FirebaseFirestore

struct OnlineGameView: View {
    @ObservedObject var viewModel: OnlineGameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            VStack(spacing: 10) {
                Spacer()
                Text(viewModel.turnIndicatorText)
                    .font(.title3).fontWeight(.bold).foregroundColor(Color("TextColor"))
                    .padding(.horizontal).multilineTextAlignment(.center).frame(height: 50)
                    .flip(isFlipped: viewModel.game?.currentPlayerTurn != viewModel.myTurn) // 自分のターンかどうかで反転
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.game?.currentPlayerTurn) // ターン変更でアニメーション

                GameBoardView(
                    board: viewModel.displayBoard, // @Bindingではない
                    selectedCoordinate: $viewModel.selectedCoordinate,
                    onTapCell: { row, col in
                        viewModel.handleTap(onRow: row, col: col)
                    }
                )
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("対戦をやめる") { dismiss() }
                }
            }
        }
    }
}
