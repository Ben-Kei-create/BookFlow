// AozoraBunkoDownloader.swift
// 青空文庫からテキストデータをダウンロードするサービス
// 作品一覧の検索、テキストファイルのダウンロード、パースを統合管理する

import Foundation

/// 青空文庫ダウンロードサービス
/// URLSession を使用してテキストファイルを非同期ダウンロードし、
/// AozoraBunkoParser でパースして Book モデルに変換する
final class AozoraBunkoDownloader {

    // MARK: - 依存

    /// テキストパーサー
    private let parser = AozoraBunkoParser()

    /// URLSession（カスタム設定可能）
    private let session: URLSession

    // MARK: - 初期化

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - 人気作品カタログ（MVP用）

    /// MVPで利用可能な作品リスト
    /// 青空文庫のテキストファイルURLとメタデータを保持する
    static let catalog: [AozoraEntry] = [
        AozoraEntry(
            aozoraId: "456_15050",
            title: "銀河鉄道の夜",
            author: "宮沢賢治",
            textURL: "https://www.aozora.gr.jp/cards/000081/files/456_15050.html"
        ),
        AozoraEntry(
            aozoraId: "1567_14913",
            title: "走れメロス",
            author: "太宰治",
            textURL: "https://www.aozora.gr.jp/cards/000035/files/1567_14913.html"
        ),
        AozoraEntry(
            aozoraId: "773_14560",
            title: "こころ",
            author: "夏目漱石",
            textURL: "https://www.aozora.gr.jp/cards/000148/files/773_14560.html"
        ),
        AozoraEntry(
            aozoraId: "127_150",
            title: "羅生門",
            author: "芥川龍之介",
            textURL: "https://www.aozora.gr.jp/cards/000879/files/127_15260.html"
        ),
        AozoraEntry(
            aozoraId: "1177_52012",
            title: "蜘蛛の糸",
            author: "芥川龍之介",
            textURL: "https://www.aozora.gr.jp/cards/000879/files/92_14545.html"
        ),
        AozoraEntry(
            aozoraId: "789_14547",
            title: "坊っちゃん",
            author: "夏目漱石",
            textURL: "https://www.aozora.gr.jp/cards/000148/files/789_14547.html"
        ),
        AozoraEntry(
            aozoraId: "46868_29420",
            title: "人間失格",
            author: "太宰治",
            textURL: "https://www.aozora.gr.jp/cards/000035/files/301_14912.html"
        ),
        AozoraEntry(
            aozoraId: "1779_8",
            title: "注文の多い料理店",
            author: "宮沢賢治",
            textURL: "https://www.aozora.gr.jp/cards/000081/files/43754_17659.html"
        ),
    ]

    // MARK: - ダウンロード

    /// 青空文庫からテキストをダウンロードし、Book に変換する
    /// - Parameter entry: ダウンロード対象の作品エントリ
    /// - Returns: パース済みの Book オブジェクト
    /// - Throws: ダウンロードまたはパース時のエラー
    func download(entry: AozoraEntry) async throws -> Book {
        guard let url = URL(string: entry.textURL) else {
            throw DownloadError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DownloadError.serverError
        }

        guard !data.isEmpty else {
            throw DownloadError.emptyResponse
        }

        // HTMLレスポンスの場合はHTMLタグを除去してからパース
        let book = parser.parse(
            data: data,
            title: entry.title,
            author: entry.author,
            aozoraId: entry.aozoraId
        )

        guard !book.pages.isEmpty else {
            throw DownloadError.parseFailure
        }

        return book
    }

    /// カタログからタイトルで検索する
    static func search(query: String) -> [AozoraEntry] {
        guard !query.isEmpty else { return catalog }
        return catalog.filter {
            $0.title.contains(query) || $0.author.contains(query)
        }
    }
}

// MARK: - 青空文庫作品エントリ

/// 青空文庫の作品メタデータ
struct AozoraEntry: Identifiable {
    let id = UUID()
    /// 青空文庫の作品ID
    let aozoraId: String
    /// 作品タイトル
    let title: String
    /// 著者名
    let author: String
    /// テキストファイルのURL
    let textURL: String
}

// MARK: - エラー定義

enum DownloadError: LocalizedError {
    case invalidURL
    case serverError
    case emptyResponse
    case parseFailure

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return "URLが無効です"
        case .serverError:    return "サーバーからの応答にエラーがあります"
        case .emptyResponse:  return "空のレスポンスを受信しました"
        case .parseFailure:   return "テキストのパースに失敗しました"
        }
    }
}
