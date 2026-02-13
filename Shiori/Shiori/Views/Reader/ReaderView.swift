// ReaderView.swift
// 没入型リーダービュー — ZStack 5層構造
// TabView(PageStyle) による横めくりUI
// SpriteKit背景、ハプティクス、チラ見せブラー、ページスライダーを統合

import SwiftUI
import SpriteKit

/// メインリーダー画面
/// 「読む」のではなく「言葉を浴びる」没入体験を提供する
struct ReaderView: View {
    // MARK: - プロパティ
    @StateObject private var viewModel: ReaderViewModel
    let onDismiss: (ReadingRecord?) -> Void

    /// ドラッグ状態の追跡（抵抗制御用）
    @GestureState private var dragOffset: CGFloat = 0
    /// ページめくりアニメーション制御
    @State private var isPageTransitioning = false
    /// クリフハンガーのブラー値（タップで晴れる）
    @State private var cliffhangerBlur: CGFloat = 6
    /// SpriteKitシーン参照（テーマ切り替え用）
    @State private var backgroundScene: ImmersiveBackgroundScene?

    init(book: Book, onDismiss: @escaping (ReadingRecord?) -> Void) {
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

            // レイヤー4: UIオーバーレイ（ページインジケータ）
            overlayUI

            // レイヤー5: メニュー（タップで表示/非表示）
            if viewModel.isMenuVisible {
                readerMenu
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(!viewModel.isMenuVisible)
        .onTapGesture(count: 2) {
            // ダブルタップ：共感マーク追加
            viewModel.addEmpathy(at: NSRange(location: 0, length: 10))
        }
        .onTapGesture(count: 1) {
            // シングルタップ：メニュー表示切替
            viewModel.toggleMenu()
        }
        .onChange(of: viewModel.currentTheme) { _, newTheme in
            // SpriteKitシーンのテーマをリアクティブに更新
            backgroundScene?.applyTheme(newTheme)
        }
        .onChange(of: viewModel.currentPageIndex) { _, _ in
            // ページが変わったらクリフハンガーのブラーをリセット
            cliffhangerBlur = 6
        }
    }

    // MARK: - レイヤー1: 没入型背景

    /// SpriteKitシーンによる動的背景
    private var immersiveBackground: some View {
        SpriteView(
            scene: getOrCreateBackgroundScene(),
            options: [.allowsTransparency]
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// SpriteKitシーンを取得または生成する（テーマ切り替え時に再生成しない）
    private func getOrCreateBackgroundScene() -> SKScene {
        if let scene = backgroundScene {
            return scene
        }
        let scene = ImmersiveBackgroundScene(
            size: UIScreen.main.bounds.size,
            theme: viewModel.currentTheme
        )
        scene.scaleMode = .resizeFill
        DispatchQueue.main.async {
            backgroundScene = scene
        }
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
    /// タップでブラーが「晴れる」アニメーション
    private var cliffhangerPreview: some View {
        VStack {
            Spacer()
            Text(viewModel.nextPagePreview)
                .font(ShioriTypography.body())
                .foregroundColor(ShioriColors.inkBlack.opacity(0.3))
                .lineSpacing(ShioriTypography.bodyLineSpacing)
                .kerning(ShioriTypography.bodyKerning)
                .blur(radius: cliffhangerBlur)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .onTapGesture {
                    // タップでブラーが晴れる演出
                    withAnimation(.easeOut(duration: 0.6)) {
                        cliffhangerBlur = 0
                    }
                }
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

    /// タップで表示されるメニュー（ページスライダー付き）
    private var readerMenu: some View {
        VStack {
            // トップバー
            HStack {
                Button {
                    // 読書セッション記録を生成して返す
                    let record = viewModel.createReadingRecord()
                    onDismiss(record)
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

            // ボトムバー：ページスライダー
            VStack(spacing: 8) {
                // ページスライダー（ミニマルデザイン）
                Slider(
                    value: Binding(
                        get: { Double(viewModel.currentPageIndex) },
                        set: { viewModel.changePage(to: Int($0)) }
                    ),
                    in: 0...Double(max(viewModel.book.totalPages - 1, 1)),
                    step: 1
                )
                .tint(ShioriColors.dustyRose.opacity(0.6))
                .padding(.horizontal, 24)

                // 感情テーマのインジケータ
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeIndicatorColor)
                        .frame(width: 6, height: 6)
                    Text(themeLabel)
                        .font(ShioriTypography.pageIndicator())
                        .foregroundColor(ShioriColors.warmGray.opacity(0.6))
                }
            }
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [ShioriColors.kinari.opacity(0), ShioriColors.kinari],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .transition(.opacity)
    }

    /// 現在のテーマに対応するインジケータカラー
    private var themeIndicatorColor: Color {
        switch viewModel.currentTheme {
        case .neutral:  return ShioriColors.warmGold
        case .ocean:    return ShioriColors.dustyBlue
        case .fire:     return ShioriColors.darkCrimson
        case .darkness: return ShioriColors.mistGray
        }
    }

    /// 現在のテーマラベル
    private var themeLabel: String {
        switch viewModel.currentTheme {
        case .neutral:  return "穏やか"
        case .ocean:    return "海・悲しみ"
        case .fire:     return "炎・怒り"
        case .darkness: return "闇・恐怖"
        }
    }
}
