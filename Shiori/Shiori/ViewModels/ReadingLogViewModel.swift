// ReadingLogViewModel.swift
// 読書記録のViewModel
// 読書アクアリウム（マイページ）のデータソース

import SwiftUI

/// 読書記録の管理ViewModel
@MainActor
final class ReadingLogViewModel: ObservableObject {

    // MARK: - 公開プロパティ

    /// 全読書記録
    @Published var records: [ReadingRecord] = []

    /// ボトル内の結晶データ
    @Published var crystals: [CrystalData] = []

    /// 総読書ページ数
    var totalPagesRead: Int {
        records.reduce(0) { $0 + $1.pagesRead }
    }

    /// 総読書時間（秒）
    var totalReadingTime: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }

    /// 読んだ作品数
    var uniqueBooksRead: Int {
        Set(records.map { $0.bookId }).count
    }

    // MARK: - ストレージキー
    private let storageKey = "shiori_reading_records"

    // MARK: - 初期化

    init() {
        loadRecords()
        generateCrystals()
    }

    // MARK: - 記録の追加

    /// 読書セッションの記録を追加する
    func addRecord(_ record: ReadingRecord) {
        records.append(record)
        saveRecords()
        generateCrystals()
    }

    // MARK: - 結晶生成

    /// 読書記録から結晶データを生成する
    /// 読んだ量に応じてボトルに結晶が溜まる
    private func generateCrystals() {
        var newCrystals: [CrystalData] = []

        for record in records {
            // 感情スコアに基づいて結晶タイプを決定
            let type = crystalType(for: record.averageSentiment)

            // ページ数に応じて結晶の数を決定（10ページごとに1つ）
            let count = max(1, record.pagesRead / 10)

            for i in 0..<count {
                let crystal = CrystalData(
                    id: UUID(),
                    type: type,
                    size: CGFloat.random(in: 0.3...1.0),
                    position: CGPoint(
                        x: CGFloat.random(in: 0.1...0.9),
                        y: CGFloat.random(in: 0.1...0.9)
                    ),
                    rotation: Double.random(in: 0...360),
                    createdFrom: record.bookTitle
                )
                newCrystals.append(crystal)
            }
        }

        crystals = newCrystals
    }

    /// 感情スコアから結晶タイプを決定する
    private func crystalType(for sentiment: Double) -> CrystalType {
        if sentiment > 0.3 { return .light }
        if sentiment > 0.0 { return .flower }
        if sentiment > -0.3 { return .mist }
        if sentiment > -0.6 { return .deepSea }
        return .ember
    }

    // MARK: - 永続化

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ReadingRecord].self, from: data)
        else { return }
        records = decoded
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

/// ボトル内の結晶表示データ
struct CrystalData: Identifiable {
    let id: UUID
    let type: CrystalType
    let size: CGFloat         // 0.3〜1.0
    let position: CGPoint     // 正規化座標（0.0〜1.0）
    let rotation: Double      // 回転角度
    let createdFrom: String   // 元の書籍タイトル
}
