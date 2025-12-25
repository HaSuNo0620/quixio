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
                //                    .flip(isFlipped: viewModel.game?.currentPlayerTurn != viewModel.myTurn) // 自分のターンかどうかで反転
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.game?.currentPlayerTurn) // ターン変更でアニメーション
                
                // ここで$viewModel.displayBoardではなく、viewModel.displayBoardとして渡す
                GameBoardView(
                    board: viewModel.displayBoard,
                    selectedCoordinate: $viewModel.selectedCoordinate,
                    onTapCell: { row, col in
                        viewModel.handleTap(onRow: row, col: col)
                    }
                )
                .onAppear {
                    // OnlineGameViewのonAppearでFirebaseとの同期を開始する
                    viewModel.startMatchmaking()
                }
                
                Spacer()
            }
            .padding()
            
            if viewModel.isGameFinished {
                Color.black.opacity(0.6).ignoresSafeArea() // 背景を暗くする
                
                VStack(spacing: 20) {
                    Text(viewModel.winnerMessage)
                        .font(.title).fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // 新しい対戦を探すボタン
                    Button(action: {
                        viewModel.findNewGame()
                    }) {
                        Text("新しい対戦を探す")
                            .fontWeight(.bold)
                            .foregroundColor(Color("AppBackground"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    // メニューに戻るボタン
                    Button(action: {
                        dismiss()
                    }) {
                        Text("メニューに戻る")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 40)
            }
        }
            
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("対戦をやめる") { dismiss() }
                }
            }
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(title: Text("エラー"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

