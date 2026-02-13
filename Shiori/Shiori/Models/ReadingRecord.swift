// ReadingRecord.swift
// 読書記録モデル — 読書アクアリウムのデータソース

import Foundation

/// 読書記録：1セッションごとの読書データ
struct ReadingRecord: Identifiable, Codable {
    let id: UUID
    /// 対象の書籍ID
    let bookId: UUID
    /// 書籍タイトル（表示用キャッシュ）
    let bookTitle: String
    /// 著者名（表示用キャッシュ）
    let authorName: String
    /// 読書開始時刻
    let startedAt: Date
    /// 読書終了時刻
    let endedAt: Date
    /// 読んだページ数
    let pagesRead: Int
    /// セッション中の平均感情スコア
    let averageSentiment: Double

    /// 読書時間（秒）
    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }

    init(
        id: UUID = UUID(),
        bookId: UUID,
        bookTitle: String,
        authorName: String,
        startedAt: Date,
        endedAt: Date = Date(),
        pagesRead: Int,
        averageSentiment: Double = 0.0
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.authorName = authorName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.pagesRead = pagesRead
        self.averageSentiment = averageSentiment
    }
}

/// ボトル内の結晶タイプ — 読書内容に応じて変化
enum CrystalType: String, Codable, CaseIterable {
    case light      // 明るい物語 → 光る結晶
    case flower     // 恋愛・美しい物語 → 花
    case deepSea    // 悲しい物語 → 深海の欠片
    case ember      // 激しい物語 → 燃える残り火
    case mist       // ミステリー → 霧

    /// 結晶の表示色
    var colorName: String {
        switch self {
        case .light:    return "warmGold"
        case .flower:   return "sakuraPink"
        case .deepSea:  return "deepBlue"
        case .ember:    return "darkCrimson"
        case .mist:     return "mistGray"
        }
    }
}
