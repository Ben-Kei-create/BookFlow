// ShioriApp.swift
// 「Shiori（栞）」- 没入型読書アプリ
// アプリケーションのエントリーポイント

import SwiftUI

@main
struct ShioriApp: App {
    // MARK: - 状態管理
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var readingLogViewModel = ReadingLogViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(libraryViewModel)
                .environmentObject(readingLogViewModel)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.light)
        }
    }
}
