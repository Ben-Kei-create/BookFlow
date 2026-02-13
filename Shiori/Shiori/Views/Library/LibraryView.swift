// LibraryView.swift
// ライブラリ画面 — 韓国カフェ風ミニマリズムの書籍一覧
// UIパーツ（ボタン枠）を極力排除し、タップに有機的な反応を返す
// 青空文庫カタログからのダウンロード機能を含む

import SwiftUI

/// 書籍ライブラリ画面
/// ミニマルなカード型レイアウトで作品一覧を表示する
struct LibraryView: View {
    // MARK: - プロパティ
    @EnvironmentObject private var viewModel: LibraryViewModel
    let onBookSelected: (Book) -> Void

    /// タップ時のスケールアニメーション用
    @State private var tappedBookId: UUID?
    /// カタログ表示フラグ
    @State private var isShowingCatalog = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // ヘッダー
                libraryHeader

                // 書籍一覧
                if viewModel.books.isEmpty {
                    emptyState
                } else {
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
                }

                // 青空文庫カタログセクション
                catalogSection

                // 下部余白（タブバー分）
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(ShioriColors.kinari)
        .sheet(isPresented: $isShowingCatalog) {
            AozoraCatalogSheet(viewModel: viewModel)
        }
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

    // MARK: - 空状態

    /// 書籍が0冊のときの空状態表示
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(ShioriColors.warmGray.opacity(0.4))

            Text("まだ本がありません")
                .font(ShioriTypography.authorName())
                .foregroundColor(ShioriColors.warmGray)

            Text("下の「青空文庫から追加」で\n作品をダウンロードしましょう")
                .font(ShioriTypography.caption())
                .foregroundColor(ShioriColors.warmGray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - 青空文庫カタログセクション

    /// 青空文庫からダウンロードするためのセクション
    private var catalogSection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 32)

            Button {
                isShowingCatalog = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .light))
                    Text("青空文庫から追加")
                        .font(ShioriTypography.button())
                }
                .foregroundColor(ShioriColors.dustyBlue)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .stroke(ShioriColors.dustyBlue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - タップハンドラ

    /// 書籍カードタップ時の処理（有機的な反応）
    private func handleBookTap(_ book: Book) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            tappedBookId = book.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tappedBookId = nil
            onBookSelected(book)
        }
    }
}

// MARK: - 書籍カード

/// 個々の書籍を表示するカードコンポーネント
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

    /// 抽象的な書籍サムネイル
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
                    .foregroundColor(ShioriColors.kinari.opacity(0.9))
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

// MARK: - 青空文庫カタログシート

/// 青空文庫カタログのモーダルシート
struct AozoraCatalogSheet: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    /// ダウンロード中のエントリID
    @State private var downloadingId: UUID?
    /// エラーメッセージ
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(AozoraBunkoDownloader.catalog) { entry in
                        catalogRow(entry: entry)
                    }
                }
                .padding(24)
            }
            .background(ShioriColors.kinari)
            .navigationTitle("青空文庫")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(ShioriTypography.button())
                        .foregroundColor(ShioriColors.dustyRose)
                }
            }
        }
    }

    /// カタログ内の1作品行
    private func catalogRow(entry: AozoraEntry) -> some View {
        let isAlreadyDownloaded = viewModel.books.contains { $0.title == entry.title }
        let isDownloading = downloadingId == entry.id

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(ShioriTypography.button())
                    .foregroundColor(ShioriColors.inkBlack)
                Text(entry.author)
                    .font(ShioriTypography.caption())
                    .foregroundColor(ShioriColors.warmGray)
            }

            Spacer()

            if isAlreadyDownloaded {
                Text("追加済み")
                    .font(ShioriTypography.caption())
                    .foregroundColor(ShioriColors.dustyGreen)
            } else if isDownloading {
                ProgressView()
                    .tint(ShioriColors.dustyRose)
            } else {
                Button {
                    downloadBook(entry: entry)
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(ShioriColors.dustyBlue)
                }
            }
        }
        .padding(.vertical, 8)
    }

    /// 書籍をダウンロードする
    private func downloadBook(entry: AozoraEntry) {
        downloadingId = entry.id
        errorMessage = nil

        Task {
            do {
                let downloader = AozoraBunkoDownloader()
                let book = try await downloader.download(entry: entry)
                await MainActor.run {
                    viewModel.books.append(book)
                    downloadingId = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    downloadingId = nil
                }
            }
        }
    }
}
