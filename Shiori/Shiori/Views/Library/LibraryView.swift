// LibraryView.swift
// ライブラリ画面 — 韓国カフェ風ミニマリズムの書籍一覧
// UIパーツ（ボタン枠）を極力排除し、タップに有機的な反応を返す

import SwiftUI

/// 書籍ライブラリ画面
/// ミニマルなカード型レイアウトで作品一覧を表示する
struct LibraryView: View {
    // MARK: - プロパティ
    @EnvironmentObject private var viewModel: LibraryViewModel
    let onBookSelected: (Book) -> Void

    /// タップ時のスケールアニメーション用
    @State private var tappedBookId: UUID?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // ヘッダー
                libraryHeader

                // 書籍一覧
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.books) { book in
                        BookCardView(
                            book: book,
                            isTapped: tappedBookId == book.id,
                            onTap: {
                                handleBookTap(book)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // 下部余白（タブバー分）
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(ShioriColors.kinari)
    }

    // MARK: - ヘッダー

    /// ライブラリのヘッダー（ミニマルデザイン）
    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ライブラリ")
                .font(ShioriTypography.bookTitle())
                .foregroundColor(ShioriColors.inkBlack)

            Text("言葉を浴びる")
                .font(ShioriTypography.caption())
                .foregroundColor(ShioriColors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 32)
    }

    // MARK: - タップハンドラ

    /// 書籍カードタップ時の処理（有機的な反応）
    private func handleBookTap(_ book: Book) {
        // タップアニメーション
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            tappedBookId = book.id
        }

        // 少し遅延してからリーダーに遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tappedBookId = nil
            onBookSelected(book)
        }
    }
}

// MARK: - 書籍カード

/// 個々の書籍を表示するカードコンポーネント
/// ボタン枠を使わず、タップに光や揺れで反応する
struct BookCardView: View {
    let book: Book
    let isTapped: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 書籍サムネイル（抽象的なビジュアル）
                bookThumbnail

                // 書籍情報
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(ShioriTypography.chapterTitle())
                        .foregroundColor(ShioriColors.inkBlack)
                        .lineLimit(1)

                    Text(book.author)
                        .font(ShioriTypography.authorName())
                        .foregroundColor(ShioriColors.warmGray)

                    // 読書進捗
                    if book.totalPages > 0 {
                        progressIndicator
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ShioriColors.linen)
                    .shadow(
                        color: ShioriColors.warmGray.opacity(isTapped ? 0.15 : 0.08),
                        radius: isTapped ? 12 : 6,
                        y: isTapped ? 6 : 3
                    )
            )
            .scaleEffect(isTapped ? 0.97 : 1.0)
            .opacity(isTapped ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - サムネイル

    /// 抽象的な書籍サムネイル（著者ごとに色が変わる）
    private var bookThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: thumbnailColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 50, height: 70)
            .overlay(
                Text(String(book.title.prefix(1)))
                    .font(.custom(ShioriTypography.boldFontName, size: 20))
                    .foregroundColor(.white.opacity(0.8))
            )
    }

    /// 書籍タイトルのハッシュ値から色を生成
    private var thumbnailColors: [Color] {
        let hash = abs(book.title.hashValue)
        let colorSets: [[Color]] = [
            [ShioriColors.dustyRose, ShioriColors.dustyRose.opacity(0.6)],
            [ShioriColors.dustyBlue, ShioriColors.dustyBlue.opacity(0.6)],
            [ShioriColors.dustyGreen, ShioriColors.dustyGreen.opacity(0.6)],
            [ShioriColors.warmGold, ShioriColors.warmGold.opacity(0.6)],
        ]
        return colorSets[hash % colorSets.count]
    }

    // MARK: - 進捗表示

    /// 読書進捗のミニインジケータ
    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ProgressView(value: Double(book.currentPage) / Double(max(book.totalPages, 1)))
                .progressViewStyle(.linear)
                .frame(width: 40)
                .tint(ShioriColors.dustyRose.opacity(0.5))

            Text("\(book.currentPage)/\(book.totalPages)")
                .font(ShioriTypography.pageIndicator())
                .foregroundColor(ShioriColors.warmGray.opacity(0.6))
        }
    }
}
