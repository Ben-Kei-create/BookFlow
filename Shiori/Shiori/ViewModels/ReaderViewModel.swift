// ReaderViewModel.swift
// リーダー画面のViewModel
// ページ管理、感情解析、SpriteKitシーン制御を統合管理する

import SwiftUI
import Combine

/// リーダー画面の状態管理ViewModel
@MainActor
final class ReaderViewModel: ObservableObject {

    // MARK: - 公開プロパティ

    /// 現在表示中の書籍
    @Published var book: Book

    /// 現在のページインデックス
    @Published var currentPageIndex: Int = 0

    /// 現在のページの感情解析結果
    @Published var currentSentiment: PageSentiment = PageSentiment(score: 0, theme: .neutral)

    /// 現在の感情テーマ（SpriteKitシーン用）
    @Published var currentTheme: EmotionTheme = .neutral

    /// メニュー表示フラグ
    @Published var isMenuVisible: Bool = false

    /// 次ページのプレビュー（チラ見せ）テキスト
    @Published var nextPagePreview: String = ""

    /// ドラッグ抵抗値（0.0〜1.0）— シリアスなシーンほど重くなる
    @Published var dragResistance: Double = 0.0

    /// 読書開始時刻（セッション記録用）
    let readingStartedAt = Date()

    // MARK: - 内部依存

    /// 感情解析エンジン
    private let sentimentAnalyzer = SentimentAnalyzer()

    /// ハプティクスエンジン
    private let hapticsEngine = ShioriHapticsEngine()

    /// 共感データマネージャ
    private let empathyManager = EmpathyManager()

    // MARK: - 初期化

    init(book: Book) {
        self.book = book
        self.currentPageIndex = book.currentPage

        // 初回ページの解析
        analyzeCurrentPage()
        updateNextPagePreview()
    }

    // MARK: - ページ操作

    /// ページを変更する
    func changePage(to index: Int) {
        guard index >= 0 && index < book.pages.count else { return }

        currentPageIndex = index
        book.currentPage = index

        // 新しいページの感情を解析
        analyzeCurrentPage()

        // 次ページプレビューを更新
        updateNextPagePreview()

        // ページめくりのハプティクスを再生
        hapticsEngine.playPageTurnHaptic(sentiment: currentSentiment)
    }

    /// 次のページへ進む
    func nextPage() {
        changePage(to: currentPageIndex + 1)
    }

    /// 前のページへ戻る
    func previousPage() {
        changePage(to: currentPageIndex - 1)
    }

    /// 現在のページテキストを取得
    var currentPageText: String {
        guard currentPageIndex < book.pages.count else { return "" }
        return book.pages[currentPageIndex]
    }

    /// ページ進捗率（0.0〜1.0）
    var progress: Double {
        guard book.totalPages > 0 else { return 0 }
        return Double(currentPageIndex + 1) / Double(book.totalPages)
    }

    // MARK: - 感情解析

    /// 現在のページの感情を解析し、テーマを更新する
    private func analyzeCurrentPage() {
        let text = currentPageText
        guard !text.isEmpty else { return }

        currentSentiment = sentimentAnalyzer.analyze(text: text)

        // テーマの切り替え（アニメーション付き）
        withAnimation(.easeInOut(duration: 1.5)) {
            currentTheme = currentSentiment.theme
        }

        // ドラッグ抵抗の更新
        // 感情が強い（重い）シーンほどページめくりに抵抗を加える
        dragResistance = currentSentiment.weight * 0.6
    }

    // MARK: - チラ見せプレビュー

    /// 次ページの最初の1行をプレビューとして取得
    private func updateNextPagePreview() {
        let nextIndex = currentPageIndex + 1
        guard nextIndex < book.pages.count else {
            nextPagePreview = ""
            return
        }

        let nextText = book.pages[nextIndex]
        // 最初の1行（改行まで、または最大40文字）を取得
        if let firstNewline = nextText.firstIndex(of: "\n") {
            nextPagePreview = String(nextText[nextText.startIndex..<firstNewline])
        } else {
            nextPagePreview = String(nextText.prefix(40))
        }
    }

    // MARK: - メニュー操作

    /// メニューの表示/非表示を切り替える
    func toggleMenu() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isMenuVisible.toggle()
        }
    }

    // MARK: - 共感（いいね）

    /// テキスト範囲に共感マークを追加する
    func addEmpathy(at range: NSRange) {
        let mark = EmpathyMark(
            bookId: book.id,
            pageIndex: currentPageIndex,
            textRangeStart: range.location,
            textRangeEnd: range.location + range.length
        )
        empathyManager.addEmpathy(mark)

        // パーティクルエフェクト用のハプティクス
        hapticsEngine.playEmpathyHaptic()
    }

    /// 現在のページの共感データを取得する
    func getEmpathyMarks() -> [EmpathyMark] {
        return empathyManager.getMarks(for: book.id, page: currentPageIndex)
    }

    // MARK: - 読書セッション終了

    /// 読書セッションの記録を生成する
    func createReadingRecord() -> ReadingRecord {
        ReadingRecord(
            bookId: book.id,
            bookTitle: book.title,
            authorName: book.author,
            startedAt: readingStartedAt,
            pagesRead: currentPageIndex + 1,
            averageSentiment: currentSentiment.score
        )
    }
}
