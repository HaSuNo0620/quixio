// MARK: - SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // ContentViewからViewModelを受け取るためのプロパティ
    @ObservedObject var viewModel: GameViewModel
    
    // このビューを閉じるための環境変数
    @Environment(\.dismiss) var dismiss
    
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
