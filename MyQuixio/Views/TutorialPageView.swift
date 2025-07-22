import SwiftUI

struct TutorialPageView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            // ルールを説明する画像やGIFを表示
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            
            // タイトル
            Text(title)
                .customFont(.bold, size: 24)
                .foregroundColor(themeManager.currentTheme.textColor)

            // 説明文
            Text(description)
                .customFont(.regular, size: 16)
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.8))
                .multilineTextAlignment(.center) // 中央揃え
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct TutorialPageView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialPageView(
            imageName: "tutorial_goal", // プレースホルダー画像名
            title: "ゲームの目的",
            description: "自分の色の駒を縦、横、斜めのいずれかに5つ並べたプレイヤーが勝利です。"
        )
        .environmentObject(ThemeManager.shared)
    }
}
