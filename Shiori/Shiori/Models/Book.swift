// Book.swift
// 書籍データモデル
// 青空文庫から取得した作品情報を保持する

import Foundation

/// 書籍データモデル
struct Book: Identifiable, Codable, Hashable {
    let id: UUID
    /// 作品タイトル
    let title: String
    /// 著者名
    let author: String
    /// 本文テキスト（パース済み）
    let content: String
    /// ページ分割済みテキスト配列
    var pages: [String]
    /// 現在の読書位置（ページインデックス）
    var currentPage: Int
    /// 総ページ数
    var totalPages: Int { pages.count }
    /// 青空文庫の作品ID（オプション）
    let aozoraId: String?
    /// ダウンロード日時
    let downloadedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        content: String,
        pages: [String] = [],
        currentPage: Int = 0,
        aozoraId: String? = nil,
        downloadedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.content = content
        self.pages = pages
        self.currentPage = currentPage
        self.aozoraId = aozoraId
        self.downloadedAt = downloadedAt
    }
}

/// ページ内の感情解析結果
struct PageSentiment {
    /// 感情スコア（-1.0 = 非常にネガティブ 〜 1.0 = 非常にポジティブ）
    let score: Double
    /// 検出されたキーワードカテゴリ
    let theme: EmotionTheme
    /// ページの「重さ」（シリアス度）— ドラッグ抵抗に使用
    var weight: Double {
        abs(score) // スコアの絶対値が大きいほど感情的に重い
    }
}

/// 感情テーマ：SpriteKitシーンの切り替えに使用
enum EmotionTheme: String, CaseIterable {
    case neutral    // 通常：生成りの紙、静寂
    case ocean      // 海/悲しみ：青、泡、滲み
    case fire       // 炎/怒り：赤黒い、火の粉、揺れ
    case darkness   // 闇/恐怖：ビネット、心音

    /// テーマに対応する背景色（グラデーションの基準色）
    var primaryColor: String {
        switch self {
        case .neutral:  return "kinari"
        case .ocean:    return "deepBlue"
        case .fire:     return "darkCrimson"
        case .darkness: return "void"
        }
    }
}

/// 共感（いいね）データ — Firestoreとの同期用
struct EmpathyMark: Identifiable, Codable {
    let id: UUID
    /// 対象の書籍ID
    let bookId: UUID
    /// ページインデックス
    let pageIndex: Int
    /// テキスト内の開始位置
    let textRangeStart: Int
    /// テキスト内の終了位置
    let textRangeEnd: Int
    /// 共感カウント（集約値）
    var count: Int
    /// タイムスタンプ
    let createdAt: Date

    init(
        id: UUID = UUID(),
        bookId: UUID,
        pageIndex: Int,
        textRangeStart: Int,
        textRangeEnd: Int,
        count: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.pageIndex = pageIndex
        self.textRangeStart = textRangeStart
        self.textRangeEnd = textRangeEnd
        self.count = count
        self.createdAt = createdAt
    }
}
