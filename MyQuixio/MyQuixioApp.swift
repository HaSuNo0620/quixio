import SwiftUI
import FirebaseCore

// Firebaseを正しく初期化するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
                .environmentObject(themeManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // アプリがフォアグラウンドに戻った
                ConnectionService.shared.goOnline(userID: gameService.currentUserID)
            case .inactive, .background:
                // アプリがバックグラウンドに移行した
                ConnectionService.shared.goOffline(userID: gameService.currentUserID)
            @unknown default:
                break
            }
        }
    }
}
