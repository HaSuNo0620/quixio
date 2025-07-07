// MARK: - ContentView.swift

import SwiftUI

struct ContentView: View {
    
    // @StateObject: このView専用のViewModelインスタンスを生成・保持する
    @State private var isShowingResetAlert = false
    @State private var isShowingSettings: Bool = false
    @State private var invalidAttempts: Int = 0
    @ObservedObject var viewModel: OnlineGameViewModel

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            NavigationStack { // この行を追加
                VStack(spacing: 10) {
                    Spacer()
                    
                   Text(viewModel.turnIndicatorText)
                       .font(.title3)
                       .fontWeight(.bold)
                       .foregroundColor(Color("TextColor"))
                       .padding(.horizontal)
                       .multilineTextAlignment(.center)
                       .frame(height: 50) // 高さを確保してレイアウトのガタつきを防ぐ
                       .transition(.opacity.animation(.easeInOut)) // テキストが切り替わる際にフェード効果
                       .id("turnIndicator_" + viewModel.turnIndicatorText) // テキストの変更を確実に検知させるためのID

                    
                    // 盤面の表示は、専門のGameBoardViewに任せる
                    GameBoardView(
                                        board: viewModel.displayBoard, // 2DのPiece配列を渡す
                                        selectedCoordinate: $viewModel.selectedCoordinate,
                                        onTapCell: { row, col in
                                            viewModel.handleTap(onRow: row, col: col)
                                        }
                                    ).shake(times: invalidAttempts) // ◀️ shakeモディファイアを適用
                        .onReceive(viewModel.invalidMovePublisher) { _ in
                            // ViewModelから通知が来たら、invalidAttemptsの数を増やしてアニメーションを発動
                            withAnimation(.default) {
                                self.invalidAttempts += 1
                            }
                        }
                    
                    Spacer()
                    
                    Button {
                        // ボタンが押されたら、アラート表示用の変数をtrueにする
                        isShowingResetAlert = true
                    } label: {
                        // ボタンの見た目
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text("ゲームをリセット")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor")) //
                        .cornerRadius(12)
                        .shadow(radius: 5, y: 3)
                    }
                    .padding(.horizontal, 40) // 横幅の調整
                    .padding(.vertical)
                    
                    Spacer()
                }
                .padding()
                // --- ★★★ ここからが変更箇所(1) ★★★ ---
                .toolbar { // 画面の上部にツールバーアイテムを追加
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
                    // isShowingSettingsがtrueになったら、このシートを表示する
                    NavigationView {
                            SettingsView(viewModel: viewModel)
                        }
                }
                
            }
                // --- ★★★ ここまでが変更箇所(1) ★★★ ---
            // 勝利画面
            if let winner = viewModel.winner {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeIn))

                VStack(spacing: 20) {
                    Text("WINNER!")
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                    Image(systemName: winner == .circle ? "circle.fill" : "xmark")
                        .resizable()
                        .fontWeight(.bold)
                        .frame(width: 70, height: 70)
                        .foregroundColor(winner == .circle ? Color("CircleColor") : Color("CrossColor"))
                        .shadow(radius: 5)
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.resetGame()
                        }
                    } label: {
                        Text("Play Again")
                            .font(.system(.title3, design: .rounded).bold())
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }
                    .padding(.top, 30)
                }
                .padding(40)
                .background(.regularMaterial)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // AIの思考中インジケーター（おまけ）
            if viewModel.isAITurn {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView() // くるくる回るインジケーター
                    .scaleEffect(2)
            }
        }

        .alert("ゲームをリセット", isPresented: $isShowingResetAlert) {
            Button("リセットする", role: .destructive) {
                viewModel.resetGame()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("現在のゲームの状況は失われます。本当によろしいですか？")
        }
        
        .onChange(of: viewModel.currentPlayer) {
                    // AI戦モードで、かつ新しいプレイヤーがAI(✕)なら
                    if viewModel.gameMode == .vsAI && viewModel.currentPlayer == .cross && viewModel.winner == nil {
                        // ViewModelに「AIの番だよ」と伝えるだけ！
                        viewModel.triggerAIMove()
                    }
                }    }
}

struct ShakeEffect: AnimatableModifier {
    var times: CGFloat = 0
    let amplitude: CGFloat = 10 // 揺れ幅

    var animatableData: CGFloat {
        get { times }
        set { times = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: sin(times * .pi * 2) * amplitude)
    }
}

// .shake() という形で簡単に呼び出せるようにするための拡張
extension View {
    func shake(times: Int) -> some View {
        self.modifier(ShakeEffect(times: CGFloat(times)))
    }
}


#Preview {
    ContentView(viewModel: GameViewModel())
}
