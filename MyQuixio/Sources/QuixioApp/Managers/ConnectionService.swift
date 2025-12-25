// Managers/ConnectionService.swift をこの内容に置き換えてください

import Foundation
import FirebaseDatabase

// ユーザーの接続状態を保存するためのモデル
struct UserConnection {
    let isOnline: Bool
    let lastSeen: Any
}

class ConnectionService {
    public static let shared = ConnectionService()
    private let dbRef: DatabaseReference

    private init() {
        // Realtime Databaseのルートを参照
        dbRef = Database.database().reference()
    }

    /// ユーザーの接続状態を監視するパスを返す
    private func userStatusRef(for userID: String) -> DatabaseReference {
        return dbRef.child("userStatus").child(userID)
    }

    /// ユーザーがオンラインになったことをRealtime Databaseに記録する
    func goOnline(userID: String) {
        let userStatusRef = userStatusRef(for: userID)
        let connectionData: [String: Any] = [
            "isOnline": true,
            "lastSeen": ServerValue.timestamp()
        ]
        
        // --- Presence機能の核心 ---
        // 接続が切れたら、isOnlineをfalseにし、最終オンライン時刻を記録するようサーバーに予約する
        userStatusRef.onDisconnectSetValue(connectionData.merging(["isOnline": false]) { (_, new) in new })
        
        // 予約が完了したら、現在の状態をオンラインとして書き込む
        userStatusRef.setValue(connectionData)
    }

    /// ユーザーが意図的にオフラインになる（アプリ終了時など）
    func goOffline(userID: String) {
        let userStatusRef = userStatusRef(for: userID)
        let offlineData: [String: Any] = [
            "isOnline": false,
            "lastSeen": ServerValue.timestamp()
        ]
        userStatusRef.setValue(offlineData)
    }

    /// 特定のユーザーの接続状態の監視を開始する
    func observeConnection(for userID: String, completion: @escaping (Bool) -> Void) -> DatabaseHandle {
        let userStatusRef = userStatusRef(for: userID)
        
        let handle = userStatusRef.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let isOnline = value["isOnline"] as? Bool else {
                completion(false) // データがなければオフラインと見なす
                return
            }
            completion(isOnline)
        }
        return handle
    }

    /// ユーザーの監視を停止する
    func removeObserver(with handle: DatabaseHandle, for userID: String) {
        let userStatusRef = userStatusRef(for: userID)
        userStatusRef.removeObserver(withHandle: handle)
    }
}
