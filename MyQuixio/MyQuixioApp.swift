//
//  MyQuixioApp.swift
//  MyQuixio
//
//  Created by 東佑貴 on 2025/06/19.
//

import SwiftUI
import FirebaseCore

@main
struct MyQuixioApp: App {
    
    // 👇 ThemeManagerのインスタンスを生成w
    @StateObject private var themeManager = ThemeManager()
    
    // 👇 このinit()メソッドを追加
    init() {
        FirebaseApp.configure()
        print("Firebase configured!")
        
        // --- 👇 ここからデバッグコードを追加 ---
        print("---------- 利用可能なフォント一覧 ----------")
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) | Font Names: \(names)")
        }
        print("--------------------------------------")
    }
    var body: some Scene {
            WindowGroup {
                // NavigationStackで囲むことで、NavigationLinkが機能するようになる
                NavigationStack {
                    MainMenuView()
                }
                // 👇 すべてのViewでthemeManagerを使えるようにする
                .environmentObject(themeManager)
            }
        }
}
