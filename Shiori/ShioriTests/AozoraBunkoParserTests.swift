// AozoraBunkoParserTests.swift
// 青空文庫パーサーのユニットテスト

import XCTest
@testable import ShioriCore

final class AozoraBunkoParserTests: XCTestCase {

    var parser: AozoraBunkoParser!

    override func setUp() {
        super.setUp()
        parser = AozoraBunkoParser(charactersPerPage: 100)
    }

    // MARK: - ルビ除去テスト

    func testRemoveRubyWithMarker() {
        // ｜漢字《かんじ》 → 漢字
        let input = "｜漢字《かんじ》を読む"
        let book = parser.parseFromString(text: input, title: "test", author: "test")
        XCTAssertTrue(book.content.contains("漢字を読む"))
        XCTAssertFalse(book.content.contains("《"))
        XCTAssertFalse(book.content.contains("｜"))
    }

    func testRemoveRubyWithoutMarker() {
        // 漢字《かんじ》 → 漢字
        let input = "美しい朝《あさ》が来た"
        let book = parser.parseFromString(text: input, title: "test", author: "test")
        XCTAssertTrue(book.content.contains("美しい朝が来た"))
    }

    // MARK: - 注釈除去テスト

    func testRemoveAnnotations() {
        let input = "これは本文です。［＃ここから２字下げ］段落の開始。"
        let book = parser.parseFromString(text: input, title: "test", author: "test")
        XCTAssertFalse(book.content.contains("［＃"))
        XCTAssertTrue(book.content.contains("これは本文です。"))
    }

    // MARK: - ページ分割テスト

    func testPagination() {
        let longText = String(repeating: "あいうえお。", count: 50)
        let book = parser.parseFromString(text: longText, title: "test", author: "test")
        XCTAssertTrue(book.pages.count > 1, "長いテキストは複数ページに分割されるべき")
    }

    func testEmptyTextPagination() {
        let book = parser.parseFromString(text: "", title: "test", author: "test")
        XCTAssertTrue(book.pages.isEmpty, "空テキストはページなし")
    }

    // MARK: - フッター除去テスト

    func testRemoveFooter() {
        let input = "本文テキスト。\n\n底本：「作品集」出版社、2000年"
        let book = parser.parseFromString(text: input, title: "test", author: "test")
        XCTAssertFalse(book.content.contains("底本"))
        XCTAssertTrue(book.content.contains("本文テキスト"))
    }
}
