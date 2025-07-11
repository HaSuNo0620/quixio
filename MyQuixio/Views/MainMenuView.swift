// MARK: - MainMenuView.swift

import SwiftUI

struct MainMenuView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    // このメインメニューが、アプリ全体のViewModelを所有・管理する
    @StateObject private var viewModel = GameViewModel()
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var isShowingTutorial = false
    @State private var isShowingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AppBackground").edgesIgnoringSafeArea(.all)
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("QUIXIO")
                        .customFont(.extrabold, size: 60)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    // ゲーム開始ボタン
                    NavigationLink {
                        GameSetupView(viewModel: viewModel)
                    } label: {
                        Text("Play Game")
                            .customFont(.bold, size: 20)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    NavigationLink{ MatchmakingView()
                    } label:{
                        Text("オンライン対戦")
                            .customFont(.bold, size: 20)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    Button("チュートリアル") {
                        isShowingTutorial = true
                    }
                    .customFont(.bold, size: 20)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.boardBackgroundColor)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .cornerRadius(20)
                    // 設定ボタン
                    Button {
                        isShowingSettings = true
                    } label: {
                        Text("Settings")
                            .customFont(.bold, size: 20)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.boardBackgroundColor)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .onAppear {
                    if !hasSeenTutorial {
                        // まだチュートリアルを見ていない場合、表示準備
                        isShowingTutorial = true
                    }
                }
                .padding(40)
                .sheet(isPresented: $isShowingTutorial, onDismiss: {
                    // シートが閉じられたら、「見た」という記録を残す
                    hasSeenTutorial = true
                }) {
                    // 表示するシートの内容
                    TutorialView()
                }
                .sheet(isPresented: $isShowingSettings) {
                    // 設定画面をそれ自身のNavigationViewで囲む
                    NavigationView {
                        SettingsView(viewModel: viewModel)
                    }}
            }
        }
    }
    
}
#Preview {
    // プレビュー用に、シートを表示するための仮の親Viewを用意する
    VStack {
        Text("チュートリアルのプレビュー")
    }
    .sheet(isPresented: .constant(true)) {
        // isPresentedに.constant(true)を渡すことで、プレビューでは常にシートが表示された状態になる
        TutorialView()
    }
}
