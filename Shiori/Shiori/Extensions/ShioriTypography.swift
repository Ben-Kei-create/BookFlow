// ShioriTypography.swift
// デザインシステム — タイポグラフィ
// ヒラギノ明朝を基本フォントとし、文字間・行間をゆったりと取る

import SwiftUI

/// Shioriのタイポグラフィ定義
/// 可読性より雰囲気を重視した設定
enum ShioriTypography {

    // MARK: - フォント名
    /// プライマリフォント（明朝体）
    static let primaryFontName = "HiraginoMincho-W3"
    /// 強調フォント（明朝体ボールド）
    static let boldFontName = "HiraginoMincho-W6"

    // MARK: - 本文（リーダー内）
    /// 本文フォント — ゆったりした読書体験のための設定
    static func body() -> Font {
        .custom(primaryFontName, size: 17)
    }

    /// 本文の行間（ポイント）
    static let bodyLineSpacing: CGFloat = 14

    /// 本文の文字間（ポイント）
    static let bodyKerning: CGFloat = 1.2

    // MARK: - 見出し
    /// 章タイトル
    static func chapterTitle() -> Font {
        .custom(boldFontName, size: 24)
    }

    /// 作品タイトル
    static func bookTitle() -> Font {
        .custom(boldFontName, size: 28)
    }

    /// 著者名
    static func authorName() -> Font {
        .custom(primaryFontName, size: 14)
    }

    // MARK: - UI要素
    /// タブラベル
    static func tabLabel() -> Font {
        .custom(primaryFontName, size: 10)
    }

    /// ボタンテキスト
    static func button() -> Font {
        .custom(primaryFontName, size: 15)
    }

    /// キャプション（補助テキスト）
    static func caption() -> Font {
        .custom(primaryFontName, size: 11)
    }

    // MARK: - ページ数表示
    /// ページインジケータ
    static func pageIndicator() -> Font {
        .custom(primaryFontName, size: 9)
    }
}

// MARK: - テキストスタイル修飾子

/// 本文用のテキストスタイル修飾子
struct ShioriBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ShioriTypography.body())
            .lineSpacing(ShioriTypography.bodyLineSpacing)
            .kerning(ShioriTypography.bodyKerning)
            .foregroundColor(ShioriColors.inkBlack)
    }
}

extension View {
    /// Shioriの本文スタイルを適用する
    func shioriBodyStyle() -> some View {
        modifier(ShioriBodyStyle())
    }
}
