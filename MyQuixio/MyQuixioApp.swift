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
    
    // 👇 このinit()メソッドを追加
    init() {
        FirebaseApp.configure()
        print("Firebase configured!")
    }
    var body: some Scene {
            WindowGroup {
                // NavigationStackで囲むことで、NavigationLinkが機能するようになる
                NavigationStack {
                    MainMenuView()
                }
            }
        }
}
