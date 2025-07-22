import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var soundManager = SoundManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("サウンド設定")) {
                    Toggle("サウンド", isOn: $soundManager.isSoundEnabled)
                }
                Section(header: Text("テーマ")) {
                    ForEach(Theme.allThemes) { theme in
                        Button(action: {
                            themeManager.applyTheme(theme)
                        }) {
                            HStack {
                                Text(theme.name)
                                Spacer()
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(themeManager.currentTheme.textColor)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .tint(themeManager.currentTheme.accentColor)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // ★この呼び出しが正しく動作するようになります★
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
