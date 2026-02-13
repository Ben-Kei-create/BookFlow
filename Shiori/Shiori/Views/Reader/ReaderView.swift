// ReaderView.swift
// 没入型リーダービュー
// TabView(PageStyle) による横めくりUI
// SpriteKit背景、ハプティクス、チラ見せブラーを統合

import SwiftUI
import SpriteKit

/// メインリーダー画面
/// 「読む」のではなく「言葉を浴びる」没入体験を提供する
struct ReaderView: View {
    // MARK: - プロパティ
    @StateObject private var viewModel: ReaderViewModel
    let onDismiss: () -> Void

    /// ドラッグ状態の追跡（抵抗制御用）
    @GestureState private var dragOffset: CGFloat = 0
    /// ページめくりアニメーション制御
    @State private var isPageTransitioning = false

    init(book: Book, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ReaderViewModel(book: book))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // レイヤー1: SpriteKit背景（感情テーマに応じて変化）
            immersiveBackground

            // レイヤー2: ページコンテンツ（TabView横めくり）
            pageContent

            // レイヤー3: 次ページのチラ見せ（クリフハンガー）
            if !viewModel.nextPagePreview.isEmpty {
                cliffhangerPreview
            }

            // レイヤー4: UIオーバーレイ（メニュー、ページインジケータ）
            overlayUI

            // レイヤー5: メニュー（タップで表示/非表示）
            if viewModel.isMenuVisible {
                readerMenu
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(!viewModel.isMenuVisible)
        .onTapGesture(count: 2) {
            // ダブルタップ：共感マーク追加（簡易実装）
            viewModel.addEmpathy(at: NSRange(location: 0, length: 10))
        }
        .onTapGesture(count: 1) {
            // シングルタップ：メニュー表示切替
            viewModel.toggleMenu()
        }
    }

    // MARK: - レイヤー1: 没入型背景

    /// SpriteKitシーンによる動的背景
    private var immersiveBackground: some View {
        SpriteView(
            scene: createBackgroundScene(),
            options: [.allowsTransparency]
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// 現在の感情テーマに応じたSpriteKitシーンを生成
    private func createBackgroundScene() -> SKScene {
        let scene = ImmersiveBackgroundScene(
            size: UIScreen.main.bounds.size,
            theme: viewModel.currentTheme
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - レイヤー2: ページコンテンツ

    /// TabView (PageStyle) による横めくりUI
    /// .drawingGroup() でGPUアクセラレーション適用
    private var pageContent: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(Array(viewModel.book.pages.enumerated()), id: \.offset) { index, pageText in
                PageView(
                    text: pageText,
                    pageIndex: index,
                    empathyMarks: viewModel.getEmpathyMarks(),
                    theme: viewModel.currentTheme
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .drawingGroup() // GPU描画最適化（Metal）
        .onChange(of: viewModel.currentPageIndex) { _, newIndex in
            viewModel.changePage(to: newIndex)
        }
    }

    // MARK: - レイヤー3: クリフハンガー（次ページチラ見せ）

    /// 次ページの最初の1行をブラーして「チラ見せ」する
    private var cliffhangerPreview: some View {
        VStack {
            Spacer()
            Text(viewModel.nextPagePreview)
                .font(ShioriTypography.body())
                .foregroundColor(ShioriColors.inkBlack.opacity(0.3))
                .lineSpacing(ShioriTypography.bodyLineSpacing)
                .kerning(ShioriTypography.bodyKerning)
                .blur(radius: 6)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .allowsHitTesting(false)
        }
    }

    // MARK: - レイヤー4: UIオーバーレイ

    /// ページインジケータとプログレスバー
    private var overlayUI: some View {
        VStack {
            Spacer()
            HStack {
                // ページ番号
                Text("\(viewModel.currentPageIndex + 1) / \(viewModel.book.totalPages)")
                    .font(ShioriTypography.pageIndicator())
                    .foregroundColor(
                        viewModel.currentTheme == .darkness
                            ? ShioriColors.warmGray
                            : ShioriColors.warmGray.opacity(0.6)
                    )

                Spacer()

                // 読書進捗
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                    .tint(ShioriColors.dustyRose.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .allowsHitTesting(false)
    }

    // MARK: - レイヤー5: リーダーメニュー

    /// タップで表示されるメニュー（章の切れ目の広告表示もここ）
    private var readerMenu: some View {
        VStack {
            // トップバー
            HStack {
                Button {
                    // 読書セッション記録を保存
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(ShioriColors.inkBlack)
                        .padding(12)
                }

                Spacer()

                Text(viewModel.book.title)
                    .font(ShioriTypography.caption())
                    .foregroundColor(ShioriColors.warmGray)

                Spacer()

                // PencilKit メモボタン（プレースホルダー）
                Button {
                    // TODO: PencilKit手書きメモレイヤーを開く
                } label: {
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(ShioriColors.inkBlack)
                        .padding(12)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 48)
            .background(
                LinearGradient(
                    colors: [ShioriColors.kinari, ShioriColors.kinari.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Spacer()
        }
        .transition(.opacity)
    }
}
