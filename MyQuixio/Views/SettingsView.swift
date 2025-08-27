// MyQuixio/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    // サウンド設定の状態を管理するための仮の変数
    @State private var areSoundEffectsOn = true
    @State private var isMusicOn = false

    var body: some View {
        // ZStackを使い、背景色とリストを明確に分離する
        ZStack {
            // 最下層に背景色を配置
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // FormやListをZStackの上に配置
            Form {
                themeSelectorSection
                soundSettingsSection
            }
            .scrollContentBackground(.hidden) // Formのデフォルト背景を透明にする
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
        }
    }

    // MARK: - View Components

    /// テーマ選択のためのセクション
    private var themeSelectorSection: some View {
           Section(
               header: Text("テーマ")
                   .foregroundColor(themeManager.currentTheme.textColor)
           ) {
               NavigationLink(destination: ThemeSelectionView()) {
                   HStack {
                       Text("現在のテーマ")
                           .foregroundColor(themeManager.currentTheme.textColor)
                       Spacer()
                       Text(themeManager.currentTheme.name)
                           .foregroundColor(.secondary)
                   }
               }
           }
           .listRowBackground(themeManager.currentTheme.cellColor)
       }


    /// サウンド設定のためのセクション
    private var soundSettingsSection: some View {
        Section(
            header: Text("サウンド")
                .foregroundColor(themeManager.currentTheme.textColor) // ヘッダーの色を明示的に指定
        ) {
            Toggle("効果音", isOn: $areSoundEffectsOn)
            Toggle("BGM", isOn: $isMusicOn)
        }
        .listRowBackground(themeManager.currentTheme.cellColor)
        .foregroundColor(themeManager.currentTheme.textColor) // Toggleのラベル色を設定
        .tint(themeManager.currentTheme.accentColor) // Toggleのスイッチ色を設定
    }

    /// 完了ボタン
    private var doneButton: some View {
        Button("完了") {
            dismiss()
        }
        .foregroundColor(themeManager.currentTheme.accentColor)
    }
}

// プレビュー用のコード
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .environmentObject(ThemeManager())
    }
}
