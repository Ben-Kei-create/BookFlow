// ShioriColors.swift
// デザインシステム — カラーパレット
// コンセプト:「韓国カフェ風ミニマリズム」×「没入型シアター」
// ⚠️ 真っ白（#FFFFFF）は使用禁止

import SwiftUI

/// Shioriのカラーパレット
/// 生成り色（Kinari）、淡いグレー、くすみカラーをベースとする
enum ShioriColors {

    // MARK: - ベースカラー

    /// 生成り色 — アプリ全体の背景色
    static let kinari = Color(red: 0.976, green: 0.965, blue: 0.941)        // #F9F6F0

    /// 温かみのあるグレー — セカンダリテキスト、非アクティブ要素
    static let warmGray = Color(red: 0.694, green: 0.667, blue: 0.639)      // #B1AAA3

    /// 墨色 — プライマリテキスト
    static let inkBlack = Color(red: 0.192, green: 0.180, blue: 0.169)      // #312E2B

    /// 淡い亜麻色 — カード背景、セクション分割
    static let linen = Color(red: 0.949, green: 0.933, blue: 0.906)         // #F2EEE7

    // MARK: - アクセントカラー（くすみカラー）

    /// くすみピンク — 共感マーク、ハイライト
    static let dustyRose = Color(red: 0.808, green: 0.639, blue: 0.624)     // #CEA39F

    /// くすみブルー — 海テーマ、リンク
    static let dustyBlue = Color(red: 0.608, green: 0.694, blue: 0.745)     // #9BB1BE

    /// くすみグリーン — 成功状態
    static let dustyGreen = Color(red: 0.639, green: 0.729, blue: 0.659)    // #A3BAA8

    // MARK: - 感情テーマカラー

    /// 深い青 — 海/悲しみテーマ
    static let deepBlue = Color(red: 0.204, green: 0.310, blue: 0.447)      // #344F72

    /// 暗い深紅 — 炎/怒りテーマ
    static let darkCrimson = Color(red: 0.447, green: 0.153, blue: 0.129)   // #722721

    /// 虚無の黒 — 闇/恐怖テーマ
    static let void = Color(red: 0.094, green: 0.082, blue: 0.082)          // #181515

    /// 温かい金色 — 読書アクアリウムの結晶
    static let warmGold = Color(red: 0.831, green: 0.722, blue: 0.502)      // #D4B880

    /// 桜ピンク — 花の結晶
    static let sakuraPink = Color(red: 0.878, green: 0.714, blue: 0.722)    // #E0B6B8

    /// 霧のグレー — ミステリー結晶
    static let mistGray = Color(red: 0.753, green: 0.753, blue: 0.773)      // #C0C0C5

    // MARK: - 共感グロー

    /// 蛍の光 — 共感が多い箇所の発光色
    static let fireflyGlow = Color(red: 1.0, green: 0.918, blue: 0.659)     // #FFEBA8

    /// 温もりの赤み — 共感テキストの温度感
    static let warmthTint = Color(red: 0.945, green: 0.796, blue: 0.733)    // #F1CBBB
}

// MARK: - テーマごとのグラデーション

extension ShioriColors {
    /// 感情テーマに応じた背景グラデーション
    static func gradient(for theme: EmotionTheme) -> LinearGradient {
        switch theme {
        case .neutral:
            return LinearGradient(
                colors: [kinari, linen],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ocean:
            return LinearGradient(
                colors: [dustyBlue.opacity(0.3), deepBlue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .fire:
            return LinearGradient(
                colors: [dustyRose.opacity(0.4), darkCrimson.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .darkness:
            return LinearGradient(
                colors: [inkBlack.opacity(0.7), void.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
