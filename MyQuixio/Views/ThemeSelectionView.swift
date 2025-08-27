// MyQuixio/Views/ThemeSelectionView.swift

import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        // ZStackで背景色を設定
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            // Listを使ってテーマ一覧を表示
            List {
                ForEach(themeManager.themes) { theme in
                    Button(action: {
                        // このテーマを選択する
                        themeManager.setTheme(to: theme)
                    }) {
                        HStack {
                            Text(theme.name)
                            Spacer()
                            // 現在選択中のテーマにチェックマークを表示
                            if theme.id == themeManager.currentTheme.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                    }
                    .listRowBackground(themeManager.currentTheme.cellColor)
                }
            }
            .scrollContentBackground(.hidden) // Listの背景を透明にする
            .navigationTitle("テーマ選択")
            .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

struct ThemeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ThemeSelectionView()
        }
        .environmentObject(ThemeManager())
    }
}
