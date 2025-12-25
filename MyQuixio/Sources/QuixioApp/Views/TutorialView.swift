import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            VStack {
                // ページ形式のTabViewを設置
                TabView {
                    TutorialPageView(
                        imageName: "tutorial_goal",
                        title: "ゲームの目的",
                        description: "自分の色の駒（○または×）を、縦・横・斜めのいずれかに一直線に5つ並べたプレイヤーが勝利です。"
                    )
                    
                    TutorialPageView(
                        imageName: "tutorial_move", // GIFアニメーションにするとさらに分かりやすい
                        title: "駒の動かし方",
                        description: "自分の番になったら、盤面の外周にある自分の色の駒、または誰のものでもない駒（灰色）を1つ選びます。"
                    )
                    
                    TutorialPageView(
                        imageName: "tutorial_slide", // GIFアニメーション推奨
                        title: "スライドイン",
                        description: "選んだ駒は、盤面の反対側の端までスライドして押し込まれます。その列にあった駒は、押し出される形で1マスずつずれます。"
                    )

                    TutorialPageView(
                        imageName: "tutorial_win",
                        title: "勝利条件",
                        description: "このアクションを繰り返し、先に5つの駒を一直線に並べましょう！"
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .always)) // ページインジケータ（点々）を常に表示
            }
            .navigationTitle("遊び方")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
        }
        .tint(themeManager.currentTheme.accentColor)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
            .environmentObject(ThemeManager())
    }
}
