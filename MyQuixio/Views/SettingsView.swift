// MARK: - SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // ContentViewからViewModelを受け取るためのプロパティ
    @ObservedObject var viewModel: GameViewModel
    
    // このビューを閉じるための環境変数
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
                    // headerとfooterを両方()の中に記述します
                    Section(header: Text("サウンド設定"), footer: Text("アプリ内の効果音のオン/オフを切り替えます。")) {
                        Toggle(isOn: $viewModel.isSoundEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(Color("AccentColor"))
                                Text("サウンドエフェクト")
                            }
                        }
                    }
            // 👇 テーマ選択セクションを追加
                        Section(header: Text("テーマ")) {
                            ForEach(Theme.allThemes) { theme in
                                HStack {
                                    Text(theme.name)
                                    Spacer()
                                    if themeManager.currentTheme.id == theme.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(theme.accentColor) // テーマの色をチェックマークに反映
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // タップされたらテーマを適用
                                    themeManager.applyTheme(theme)
                                }
                            }
                        }
                }
        .navigationTitle("設定")
            .toolbar { // ◀️ ここから追加
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss() // ◀️ ボタンが押されたらViewを閉じる
                    }
                }
            } // ◀️ ここまで追加
    }
}
