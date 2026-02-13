// AozoraBunkoParser.swift
// 青空文庫テキストパーサー
// Shift-JIS エンコーディングのテキストファイルを読み込み、
// ルビタグ《...》や注釈［＃...］を適切に処理する

import Foundation

/// 青空文庫のテキストフォーマットをパースするクラス
/// テキストファイル（Shift-JIS）を読み込み、ルビや注釈を除去して
/// 読みやすいプレーンテキストに変換する
final class AozoraBunkoParser {

    // MARK: - 設定

    /// 1ページあたりの最大文字数（端末サイズに応じて調整可能）
    var charactersPerPage: Int

    /// ページ分割時に段落の途中で切らないようにするフラグ
    var respectParagraphs: Bool

    init(charactersPerPage: Int = 400, respectParagraphs: Bool = true) {
        self.charactersPerPage = charactersPerPage
        self.respectParagraphs = respectParagraphs
    }

    // MARK: - パース処理

    /// 青空文庫のテキストデータをパースし、Book モデルに変換する
    /// - Parameters:
    ///   - data: テキストファイルのバイナリデータ
    ///   - title: 作品タイトル
    ///   - author: 著者名
    ///   - aozoraId: 青空文庫の作品ID
    /// - Returns: パース済みの Book オブジェクト
    func parse(
        data: Data,
        title: String,
        author: String,
        aozoraId: String? = nil
    ) -> Book {
        // Shift-JIS でデコード（失敗した場合は UTF-8 を試行）
        let rawText = decodeText(from: data)

        // 青空文庫フォーマットのクリーニング
        let cleanedText = cleanAozoraFormat(rawText)

        // ヘッダー・フッターの除去
        let bodyText = extractBody(from: cleanedText)

        // ページ分割
        let pages = paginateText(bodyText)

        return Book(
            title: title,
            author: author,
            content: bodyText,
            pages: pages,
            aozoraId: aozoraId
        )
    }

    /// 文字列から直接パースする（テスト・デモ用）
    func parseFromString(
        text: String,
        title: String,
        author: String
    ) -> Book {
        let cleanedText = cleanAozoraFormat(text)
        let pages = paginateText(cleanedText)
        return Book(
            title: title,
            author: author,
            content: cleanedText,
            pages: pages
        )
    }

    // MARK: - テキストデコード

    /// バイナリデータをテキストにデコードする
    /// Shift-JIS → UTF-8 の順で試行
    private func decodeText(from data: Data) -> String {
        // まず Shift-JIS（Windows-31J）でデコードを試みる
        let shiftJISEncoding = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)
            )
        )

        if let text = String(data: data, encoding: shiftJISEncoding) {
            return text
        }

        // Shift-JIS 失敗時は UTF-8 でデコード
        if let text = String(data: data, encoding: .utf8) {
            return text
        }

        // どちらも失敗した場合は EUC-JP を試行
        let eucJPEncoding = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.EUC_JP.rawValue)
            )
        )

        if let text = String(data: data, encoding: eucJPEncoding) {
            return text
        }

        // 全て失敗した場合は Latin-1 で強制デコード（データ損失の可能性あり）
        return String(data: data, encoding: .isoLatin1) ?? ""
    }

    // MARK: - 青空文庫フォーマットのクリーニング

    /// 青空文庫特有のフォーマットタグを除去する
    private func cleanAozoraFormat(_ text: String) -> String {
        var result = text

        // ルビの除去: ｜漢字《かんじ》 → 漢字
        // パターン1: ルビ開始記号「｜」付き
        result = result.replacingOccurrences(
            of: "｜([^《]+)《[^》]+》",
            with: "$1",
            options: .regularExpression
        )

        // パターン2: ルビ開始記号なし（漢字に直接ルビ）
        // 例: 漢字《かんじ》 → 漢字
        result = result.replacingOccurrences(
            of: "《[^》]+》",
            with: "",
            options: .regularExpression
        )

        // 注釈の除去: ［＃...］
        // 例: ［＃ここから２字下げ］, ［＃「」は底本では「」］
        result = result.replacingOccurrences(
            of: "［＃[^］]*］",
            with: "",
            options: .regularExpression
        )

        // 外字記法の除去: ※［＃...］
        result = result.replacingOccurrences(
            of: "※［＃[^］]*］",
            with: "※",
            options: .regularExpression
        )

        // ルビ開始記号の残りを除去
        result = result.replacingOccurrences(of: "｜", with: "")

        // 連続する空行を1つに統合
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - ヘッダー・フッター除去

    /// 青空文庫テキストのヘッダーとフッターを除去し、本文のみを抽出する
    private func extractBody(from text: String) -> String {
        var result = text

        // ヘッダーの検出と除去
        // 青空文庫のテキストは通常、タイトル→著者名→空行→本文の構成
        // 「底本：」以降はフッターとして除去
        if let footerRange = result.range(of: "底本：") {
            result = String(result[result.startIndex..<footerRange.lowerBound])
        }

        // 「底本:」（半角コロン版）もチェック
        if let footerRange = result.range(of: "底本:") {
            result = String(result[result.startIndex..<footerRange.lowerBound])
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - ページ分割

    /// テキストをページ単位に分割する
    /// 段落の途中で切れないように配慮する
    func paginateText(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        if respectParagraphs {
            return paginateByParagraphs(text)
        } else {
            return paginateByCharacterCount(text)
        }
    }

    /// 段落を尊重してページ分割する
    private func paginateByParagraphs(_ text: String) -> [String] {
        let paragraphs = text.components(separatedBy: "\n")
        var pages: [String] = []
        var currentPage = ""

        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespaces)

            // 空行はそのまま追加（段落区切り）
            if trimmed.isEmpty {
                if !currentPage.isEmpty {
                    currentPage += "\n"
                }
                continue
            }

            // 現在のページに段落を追加するとページサイズを超える場合
            if currentPage.count + trimmed.count > charactersPerPage && !currentPage.isEmpty {
                pages.append(currentPage.trimmingCharacters(in: .whitespacesAndNewlines))
                currentPage = ""
            }

            // 1つの段落がページサイズより大きい場合は強制分割
            if trimmed.count > charactersPerPage {
                let chunks = splitLongParagraph(trimmed)
                for (index, chunk) in chunks.enumerated() {
                    if index == chunks.count - 1 {
                        currentPage = chunk
                    } else {
                        if !currentPage.isEmpty {
                            pages.append(currentPage.trimmingCharacters(in: .whitespacesAndNewlines))
                            currentPage = ""
                        }
                        pages.append(chunk)
                    }
                }
            } else {
                if !currentPage.isEmpty {
                    currentPage += "\n"
                }
                currentPage += trimmed
            }
        }

        // 最後のページを追加
        let lastPage = currentPage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastPage.isEmpty {
            pages.append(lastPage)
        }

        return pages
    }

    /// 文字数ベースでページ分割する（段落無視）
    private func paginateByCharacterCount(_ text: String) -> [String] {
        var pages: [String] = []
        var startIndex = text.startIndex

        while startIndex < text.endIndex {
            let endOffset = text.index(startIndex, offsetBy: charactersPerPage, limitedBy: text.endIndex)
                ?? text.endIndex
            let page = String(text[startIndex..<endOffset])
            pages.append(page.trimmingCharacters(in: .whitespacesAndNewlines))
            startIndex = endOffset
        }

        return pages.filter { !$0.isEmpty }
    }

    /// 長い段落を句読点や文末で適切に分割する
    private func splitLongParagraph(_ paragraph: String) -> [String] {
        var chunks: [String] = []
        var current = ""

        // 文単位で分割を試みる（句点「。」で区切る）
        let sentences = paragraph.components(separatedBy: "。")

        for (index, sentence) in sentences.enumerated() {
            let sentenceWithPeriod = index < sentences.count - 1 ? sentence + "。" : sentence

            if current.count + sentenceWithPeriod.count > charactersPerPage && !current.isEmpty {
                chunks.append(current)
                current = ""
            }

            current += sentenceWithPeriod
        }

        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chunks.append(current)
        }

        return chunks
    }
}
