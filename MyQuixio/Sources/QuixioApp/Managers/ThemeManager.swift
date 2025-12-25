// MyQuixio/Managers/ThemeManager.swift

import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme
    let themes: [Theme]

    init() {
        // ステップ1: JSONからテーマを読み込む
        self.themes = ThemeManager.loadThemes()
        
        // ステップ2: 以前選択したテーマ名をUserDefaultsから取得
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedThemeName")
        
        // ステップ3: 保存されたテーマがあればそれを、なければJSONの最初のテーマを現在のテーマに設定
        self.currentTheme = themes.first { $0.name == savedThemeName } ?? themes.first ?? Theme.default
    }

    // ユーザーが新しいテーマを選択したときに呼び出されるメソッド
    func setTheme(to theme: Theme) {
        currentTheme = theme
        // 選択されたテーマの名前をUserDefaultsに保存して、次回起動時に復元できるようにする
        UserDefaults.standard.set(theme.name, forKey: "selectedThemeName")
    }

    // JSONファイルから[Theme]の配列を読み込む静的メソッド
    private static func loadThemes() -> [Theme] {
        // 1. プロジェクト内から "Themes.json" の場所(URL)を探す
        guard let url = Bundle.main.url(forResource: "Themes", withExtension: "json") else {
            print("❌ Error: Could not find Themes.json in the bundle.")
            return [Theme.default] // 見つからなければデフォルトテーマだけを返す
        }

        // 2. URLからファイルの中身(データ)を読み込む
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Error: Could not load data from Themes.json.")
            return [Theme.default] // 読み込めなければデフォルトテーマだけを返す
        }

        // 3. 読み込んだデータを[Theme]の配列にデコード(変換)する
        let decoder = JSONDecoder()
        if let loadedThemes = try? decoder.decode([Theme].self, from: data) {
            print("✅ Successfully loaded \(loadedThemes.count) themes from JSON.")
            return loadedThemes // 成功したらテーマの配列を返す
        }

        // デコードに失敗した場合
        print("❌ Error: Could not decode Themes.json. Check the JSON format.")
        return [Theme.default] // 失敗したらデフォルトテーマだけを返す
    }
}
