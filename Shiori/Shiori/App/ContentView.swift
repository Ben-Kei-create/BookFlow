// ContentView.swift
// メインナビゲーション：ライブラリ / マイページ の2タブ構成
// 読書中は没入モードに切り替わり、タブバーは非表示になる
// 初回起動時はオンボーディングを表示する

import SwiftUI

struct ContentView: View {
    // MARK: - 状態
    @EnvironmentObject private var readingLogViewModel: ReadingLogViewModel
    @State private var selectedTab: AppTab = .library
    @State private var isReading = false
    @State private var selectedBook: Book?

    /// 初回起動判定（UserDefaults）
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            // 背景色: 生成り色（#FFFFFF / #000000 禁止）
            ShioriColors.kinari
                .ignoresSafeArea()

            if !hasCompletedOnboarding {
                // 初回起動：オンボーディング
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            } else if let book = selectedBook, isReading {
                // 没入型リーダー（タブバー非表示）
                ReaderView(
                    book: book,
                    onDismiss: { record in
                        // 読書記録を保存
                        if let record = record {
                            readingLogViewModel.addRecord(record)
                        }
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isReading = false
                            selectedBook = nil
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // メインタブ
                mainTabView
            }
        }
    }

    // MARK: - メインタブビュー
    /// ボタン枠を極力排除した、ミニマルなタブナビゲーション
    private var mainTabView: some View {
        VStack(spacing: 0) {
            // コンテンツ領域
            Group {
                switch selectedTab {
                case .library:
                    LibraryView(
                        onBookSelected: { book in
                            selectedBook = book
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isReading = true
                            }
                        }
                    )
                case .myPage:
                    MyPageView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // カスタムタブバー（韓国カフェ風ミニマリズム）
            customTabBar
        }
    }

    // MARK: - カスタムタブバー
    /// UIパーツ（ボタン枠）を排除したミニマルなタブバー
    private var customTabBar: some View {
        HStack {
            tabItem(tab: .library, icon: "book.fill", label: "ライブラリ")
            Spacer()
            tabItem(tab: .myPage, icon: "drop.fill", label: "マイページ")
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 12)
        .background(
            ShioriColors.kinari
                .shadow(color: ShioriColors.warmGray.opacity(0.1), radius: 8, y: -2)
        )
    }

    /// 個々のタブアイテム
    private func tabItem(tab: AppTab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(ShioriTypography.tabLabel())
            }
            .foregroundColor(selectedTab == tab ? ShioriColors.inkBlack : ShioriColors.warmGray)
            .opacity(selectedTab == tab ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - タブ定義
enum AppTab {
    case library
    case myPage
}
