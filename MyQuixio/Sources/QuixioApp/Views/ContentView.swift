// Views/ContentView.swift

import SwiftUI

struct ContentView: View {
    
    // このViewが一人プレイ用の「頭脳」を所有・管理する
    @ObservedObject var viewModel: GameViewModel
    // 👇 環境オブジェクトとしてThemeManagerを受け取る
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    // Viewの状態を管理する変数
    @State private var isShowingResetAlert = false
    @State private var isShowingSettings: Bool = false
    @State private var isShowingTutorial = false
    @State private var invalidAttempts: Int = 0

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            
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

                // 盤面表示
                GameBoardView(
                    board: viewModel.board,
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
                
                // ゲームリセットボタン
                Button {
                    isShowingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("ゲームをリセット")
                    }
                    .customFont(.medium, size: 20)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(themeManager.currentTheme.accentColor)
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
                    SettingsView()
                }
            }
                
            // --- 👇 ここからが書き直す部分(1) ---
            // 勝利画面
            if let winner = viewModel.winner {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeIn))

                VStack(spacing: 20) {
                    Text("WINNER!")
                        .customFont(.extrabold, size: 60)
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
            
            // --- 👇 ここからが書き直す部分(2) ---
            // AI思考中インジケーター
            if viewModel.isAITurn {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(2)
                    .tint(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
                // ▼▼▼【2. ツールバーを追加・修正】▼▼▼
                .toolbar {
                    // ★ヘルプボタンを追加
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingTutorial.toggle()
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                    
                    // ★メインメニューに戻るボタン
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        .padding(.leading, 8) // 少しだけ間隔を調整
                    }
                }
                // ▼▼▼【3. シートを追加】▼▼▼
                .sheet(isPresented: $isShowingTutorial) {
                    TutorialView()
                        .environmentObject(themeManager) // テーマを渡す
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                        .environmentObject(themeManager)
                }
                .onReceive(viewModel.$winner) { winner in
                    if winner != nil {
                        SoundManager.shared.playSound(named: "win.mp3")
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
    ContentView(viewModel: GameViewModel(gameMode: .vsAI))
}
