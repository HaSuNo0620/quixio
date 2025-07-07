import SwiftUI

struct TutorialView: View {
    // このViewを閉じるための機能
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // タイトルバーと閉じるボタンのためにNavigationViewで囲む
        NavigationView {
            // 設定画面のようなレイアウトのためにFormを使用
            Form {
                Section(header: Text("1. 目的")) {
                    Label {
                        Text("縦・横・斜めのいずれかに、自分の色の駒を5つ揃えることを目指します。")
                    } icon: {
                        Image(systemName: "target")
                            .foregroundColor(Color("AccentColor"))
                    }
                }

                Section(header: Text("2. 操作方法")) {
                    Label("動かしたい列/行の外周マスをタップします（空または自分の駒のみ）。", systemImage: "1.circle.fill")
                    Label("同じ列/行の反対側のマスをタップすると、移動が実行されます。", systemImage: "2.circle.fill")
                }

                Section(header: Text("3. 駒の動き")) {
                    Text("操作が完了すると、最初にタップしたマスにあった駒が盤上から取り除かれ、次にタップしたマスにあなたの新しい駒が置かれます。")

                    // 図解のプレースホルダー
                    VStack(alignment: .center, spacing: 5) {
                        Text("例：Cの駒を選び、左端に動かす場合").font(.caption).foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            Text("[ A | B | C | D | E ]")
                            Image(systemName: "arrow.right")
                            Text("[ N | A | B | D | E ]")
                        }
                        .font(.system(.callout, design: .monospaced))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("ゲームのルール")
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーの右上に「閉じる」ボタンを配置
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
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
