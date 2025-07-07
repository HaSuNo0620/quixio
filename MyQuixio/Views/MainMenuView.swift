// MARK: - MainMenuView.swift

import SwiftUI

struct MainMenuView: View {
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
                    
                    Text("Quixio")
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    // ゲーム開始ボタン
                    NavigationLink {
                        GameSetupView(viewModel: viewModel)
                    } label: {
                        Text("Play Game")
                            .font(.system(.title, design: .rounded).bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    Button("チュートリアル") {
                            isShowingTutorial = true
                        }
                    .font(.system(.title, design: .rounded).bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BoardBackground"))
                    .foregroundColor(Color("TextColor"))
                    .cornerRadius(20)
                    // 設定ボタン
                    Button {
                        isShowingSettings = true
                    } label: {
                        Text("Settings")
                            .font(.system(.title, design: .rounded).bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("BoardBackground"))
                            .foregroundColor(Color("TextColor"))
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
                VStack(spacing: 20) {
                                Text("Slide Game")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))

                                // --- ここから追加 ---
                                NavigationLink(destination: MatchmakingView()) {
                                    Text("オンライン対戦")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                // --- ここまで追加 ---
                                
                                // 既存の他のメニューボタン...
                                // 例: NavigationLink(destination: ContentView()) { ... }
                            }
                            .padding()
                            .navigationTitle("メインメニュー")
                            .navigationBarHidden(true)
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
