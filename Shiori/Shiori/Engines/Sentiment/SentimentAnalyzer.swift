// SentimentAnalyzer.swift
// AI演出監督 — NaturalLanguage フレームワークによる感情解析エンジン
// テキストの感情スコアとキーワードからテーマをリアルタイムで決定する

import NaturalLanguage

/// テキストの感情を解析し、SpriteKitシーンのテーマを決定するエンジン
/// NLTagger を使用してセンチメント分析を行い、
/// キーワード辞書と組み合わせてテーマを判定する
final class SentimentAnalyzer {

    // MARK: - キーワード辞書

    /// 海/悲しみテーマのキーワード
    private let oceanKeywords: Set<String> = [
        "海", "波", "涙", "泣", "悲", "雨", "水", "流",
        "寂", "哀", "憂", "冷", "青", "沈", "深",
        "別れ", "さよなら", "孤独", "切な", "儚",
        "潮", "渚", "溺", "溢", "湿"
    ]

    /// 炎/怒りテーマのキーワード
    private let fireKeywords: Set<String> = [
        "炎", "火", "燃", "怒", "激", "熱", "赤",
        "叫", "狂", "憎", "恨", "血", "戦", "暴",
        "爆", "烈", "猛", "殺", "鬼", "魔"
    ]

    /// 闇/恐怖テーマのキーワード
    private let darknessKeywords: Set<String> = [
        "闇", "暗", "夜", "影", "死", "恐", "怖",
        "黒", "霧", "幽", "霊", "呪", "鬱", "絶望",
        "地獄", "深淵", "沈黙", "虚", "無", "墓"
    ]

    // MARK: - NLTagger

    /// NaturalLanguage の感情分析タガー
    private let tagger: NLTagger

    init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore])
    }

    // MARK: - 解析

    /// テキストの感情を解析し、PageSentiment を返す
    /// - Parameter text: 解析対象のテキスト
    /// - Returns: 感情スコアとテーマ
    func analyze(text: String) -> PageSentiment {
        // NLTagger によるセンチメントスコア取得
        let score = analyzeSentimentScore(text: text)

        // キーワードベースのテーマ判定
        let theme = determineTheme(text: text, sentimentScore: score)

        return PageSentiment(score: score, theme: theme)
    }

    // MARK: - センチメントスコア

    /// NLTagger を使用してテキスト全体のセンチメントスコアを算出する
    /// - Parameter text: 解析対象のテキスト
    /// - Returns: -1.0（非常にネガティブ）〜 1.0（非常にポジティブ）
    private func analyzeSentimentScore(text: String) -> Double {
        tagger.string = text

        var totalScore: Double = 0
        var count = 0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .paragraph,
            scheme: .sentimentScore,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        guard count > 0 else { return 0 }
        return totalScore / Double(count)
    }

    // MARK: - テーマ判定

    /// センチメントスコアとキーワードからテーマを決定する
    /// キーワードのヒット数が閾値以上の場合、キーワードベースのテーマを優先する
    private func determineTheme(text: String, sentimentScore: Double) -> EmotionTheme {
        // キーワードヒットカウント
        let oceanCount = countKeywordHits(in: text, keywords: oceanKeywords)
        let fireCount = countKeywordHits(in: text, keywords: fireKeywords)
        let darknessCount = countKeywordHits(in: text, keywords: darknessKeywords)

        // キーワードの閾値（3回以上ヒットでテーマ適用）
        let threshold = 3

        // 最もヒット数が多いテーマを選択
        let maxCount = max(oceanCount, fireCount, darknessCount)

        if maxCount >= threshold {
            if darknessCount == maxCount { return .darkness }
            if fireCount == maxCount { return .fire }
            if oceanCount == maxCount { return .ocean }
        }

        // キーワード閾値未満の場合、センチメントスコアで判定
        if sentimentScore < -0.5 {
            return .darkness
        } else if sentimentScore < -0.2 {
            return .ocean
        } else if sentimentScore > 0.5 {
            return .neutral // ポジティブは通常テーマ
        }

        return .neutral
    }

    /// テキスト中のキーワードヒット数をカウントする
    private func countKeywordHits(in text: String, keywords: Set<String>) -> Int {
        var count = 0
        for keyword in keywords {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: keyword, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<text.endIndex
            }
        }
        return count
    }
}
