import SwiftUI
import FirebaseCore

// Firebaseを正しく初期化するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    // 機能: アプリ起動時にFirebaseを初期化するエントリポイント。
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MyQuixioApp: App {
    // AppDelegateをSwiftUIアプリのライフサイクルに接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // アプリの状態（フォアグラウンドかバックグラウンドか）を監視
    @Environment(\.scenePhase) private var scenePhase
    
    // --- ▼▼▼【ここから修正】抜けていたStateObjectを再追加 ---
    // アプリ全体で利用するオブジェクトを生成・管理する
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var gameService = GameService()   // オンライン機能用
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var hapticManager = HapticManager.shared

    var body: some Scene {
        // 機能: ルートのWindowGroupを定義し、環境オブジェクトを注入。
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
                .environmentObject(themeManager)
                .environmentObject(gameService)
                .environmentObject(soundManager)
                .environmentObject(hapticManager)
                .task {
                    // 追加提案: ネットワーク切断時のリトライ処理をタスクで監視すると更に安定。
                    let userID = gameService.currentUserID.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !userID.isEmpty else { return }
                    ConnectionService.shared.goOnline(userID: userID)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            // 機能: アプリ状態の変化に応じて接続ステータスを更新。
            switch newPhase {
            case .active:
                // アプリがフォアグラウンドに戻った
                let userID = gameService.currentUserID.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !userID.isEmpty else { return }
                ConnectionService.shared.goOnline(userID: userID)
            case .inactive, .background:
                // アプリがバックグラウンドに移行した
                let userID = gameService.currentUserID.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !userID.isEmpty else { return }
                ConnectionService.shared.goOffline(userID: userID)
            @unknown default:
                break
            }
        }
    }
}
