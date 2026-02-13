// PageView.swift
// 個々のページを表示するコンポーネント
// テキスト描画、共感グロー効果、PencilKitレイヤーを統合

import SwiftUI

/// 1ページ分のテキスト表示コンポーネント
/// GPU最適化のため、.drawingGroup() は親ビューで適用される
struct PageView: View {
    // MARK: - プロパティ
    let text: String
    let pageIndex: Int
    let empathyMarks: [EmpathyMark]
    let theme: EmotionTheme

    /// テキストの揺れアニメーション（炎テーマ時）
    @State private var textShakeOffset: CGFloat = 0
    /// ビネット効果の強度（闇テーマ時）
    @State private var vignetteIntensity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // テーマに応じた背景グラデーション
                ShioriColors.gradient(for: theme)
                    .ignoresSafeArea()

                // 闇テーマ時のビネット効果
                if theme == .darkness {
                    vignetteOverlay
                }

                // テキストコンテンツ
                ScrollView(.vertical, showsIndicators: false) {
                    textContent
                        .padding(.horizontal, 32)
                        .padding(.vertical, 80)
                        .frame(minHeight: geometry.size.height)
                }

                // 共感グロー効果オーバーレイ
                if !empathyMarks.isEmpty {
                    empathyGlowOverlay
                }
            }
        }
        .onAppear {
            startThemeAnimations()
        }
        .onChange(of: theme) { _, _ in
            startThemeAnimations()
        }
    }

    // MARK: - テキストコンテンツ

    /// 本文テキスト（Shioriスタイル適用済み）
    private var textContent: some View {
        Text(text)
            .font(ShioriTypography.body())
            .lineSpacing(ShioriTypography.bodyLineSpacing)
            .kerning(ShioriTypography.bodyKerning)
            .foregroundColor(textColor)
            .multilineTextAlignment(.leading)
            .offset(x: theme == .fire ? textShakeOffset : 0) // 炎テーマ時の微揺れ
            .drawingGroup() // GPU描画最適化（Metal）
    }

    /// テーマに応じたテキストカラー
    private var textColor: Color {
        switch theme {
        case .neutral:  return ShioriColors.inkBlack
        case .ocean:    return ShioriColors.inkBlack.opacity(0.85)
        case .fire:     return ShioriColors.inkBlack
        case .darkness: return ShioriColors.warmGray.opacity(0.9)
        }
    }

    // MARK: - ビネット効果（闇テーマ）

    /// 画面四隅が暗くなるビネット効果
    private var vignetteOverlay: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.clear,
                ShioriColors.void.opacity(vignetteIntensity)
            ]),
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - 共感グロー効果

    /// 共感が多い箇所を蛍のように発光させるオーバーレイ
    private var empathyGlowOverlay: some View {
        // 共感マークの位置に発光エフェクトを配置
        GeometryReader { geometry in
            ForEach(empathyMarks) { mark in
                let yPosition = calculateGlowPosition(
                    mark: mark,
                    in: geometry.size
                )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ShioriColors.fireflyGlow.opacity(glowIntensity(for: mark)),
                                ShioriColors.warmthTint.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width / 2, y: yPosition)
                    .allowsHitTesting(false)
            }
        }
    }

    /// 共感カウントに応じたグロー強度
    private func glowIntensity(for mark: EmpathyMark) -> Double {
        min(Double(mark.count) * 0.15, 0.8)
    }

    /// 共感マークのY座標を計算する
    private func calculateGlowPosition(mark: EmpathyMark, in size: CGSize) -> CGFloat {
        let textLength = max(text.count, 1)
        let relativePosition = Double(mark.textRangeStart) / Double(textLength)
        return size.height * relativePosition * 0.8 + 80
    }

    // MARK: - テーマアニメーション

    /// テーマに応じたアニメーションを開始する
    private func startThemeAnimations() {
        switch theme {
        case .fire:
            // 炎テーマ：文字の微揺れ
            withAnimation(
                .easeInOut(duration: 0.15)
                .repeatForever(autoreverses: true)
            ) {
                textShakeOffset = 0.5
            }
            vignetteIntensity = 0

        case .darkness:
            // 闇テーマ：ビネット効果
            textShakeOffset = 0
            withAnimation(.easeIn(duration: 2.0)) {
                vignetteIntensity = 0.7
            }

        default:
            textShakeOffset = 0
            withAnimation(.easeOut(duration: 1.0)) {
                vignetteIntensity = 0
            }
        }
    }
}
