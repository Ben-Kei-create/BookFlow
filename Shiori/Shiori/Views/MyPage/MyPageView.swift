// MyPageView.swift
// マイページ — 読書アクアリウム
// 読書履歴をグラフではなく「瓶（ボトル）」として表現する
// 読んだ量に応じてボトル内に「光る結晶」や「花」が溜まっていく

import SwiftUI

/// マイページ画面
/// 読書記録を美しいアクアリウムとして視覚化する
struct MyPageView: View {
    @EnvironmentObject private var viewModel: ReadingLogViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                // ヘッダー
                myPageHeader

                // 読書アクアリウム（メインビジュアル）
                aquariumBottle

                // 読書統計（ミニマル表示）
                readingStats

                // 最近の読書記録
                recentRecords

                Spacer()
                    .frame(height: 100)
            }
        }
        .background(ShioriColors.kinari)
    }

    // MARK: - ヘッダー

    private var myPageHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("マイページ")
                .font(ShioriTypography.bookTitle())
                .foregroundColor(ShioriColors.inkBlack)

            Text("あなたの読書の記憶")
                .font(ShioriTypography.caption())
                .foregroundColor(ShioriColors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: - 読書アクアリウム

    /// ボトル型の読書記録ビジュアライゼーション
    private var aquariumBottle: some View {
        ZStack {
            // ボトルの外形
            bottleShape

            // ボトル内の結晶
            ForEach(viewModel.crystals) { crystal in
                CrystalView(crystal: crystal)
            }
        }
        .frame(width: 200, height: 320)
        .padding(.vertical, 20)
    }

    /// ボトルの外形（ガラス瓶風）
    private var bottleShape: some View {
        ZStack {
            // ボトル本体
            RoundedRectangle(cornerRadius: 24)
                .stroke(ShioriColors.warmGray.opacity(0.3), lineWidth: 1.5)
                .frame(width: 140, height: 240)
                .offset(y: 20)

            // ボトルの首
            RoundedRectangle(cornerRadius: 8)
                .stroke(ShioriColors.warmGray.opacity(0.3), lineWidth: 1.5)
                .frame(width: 50, height: 40)
                .offset(y: -110)

            // ボトルの蓋
            RoundedRectangle(cornerRadius: 4)
                .fill(ShioriColors.warmGray.opacity(0.2))
                .frame(width: 56, height: 12)
                .offset(y: -132)

            // 水位（読書量に応じて上昇）
            waterLevel
        }
    }

    /// 読書量に応じた水位
    private var waterLevel: some View {
        let fillRatio = min(Double(viewModel.totalPagesRead) / 500.0, 1.0)
        let fillHeight = 230.0 * fillRatio

        return VStack {
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ShioriColors.dustyBlue.opacity(0.15),
                            ShioriColors.dustyBlue.opacity(0.05)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 136, height: fillHeight)
                .clipShape(
                    RoundedRectangle(cornerRadius: 22)
                )
        }
        .frame(width: 140, height: 240)
        .offset(y: 20)
    }

    // MARK: - 読書統計

    /// ミニマルな読書統計表示
    private var readingStats: some View {
        HStack(spacing: 40) {
            statItem(
                value: "\(viewModel.totalPagesRead)",
                label: "ページ"
            )
            statItem(
                value: "\(viewModel.uniqueBooksRead)",
                label: "作品"
            )
            statItem(
                value: formatReadingTime(viewModel.totalReadingTime),
                label: "時間"
            )
        }
        .padding(.horizontal, 24)
    }

    /// 統計アイテム（数値 + ラベル）
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom(ShioriTypography.boldFontName, size: 22))
                .foregroundColor(ShioriColors.inkBlack)
            Text(label)
                .font(ShioriTypography.caption())
                .foregroundColor(ShioriColors.warmGray)
        }
    }

    /// 読書時間のフォーマット
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - 最近の記録

    /// 最近の読書記録リスト
    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の読書")
                .font(ShioriTypography.authorName())
                .foregroundColor(ShioriColors.warmGray)
                .padding(.horizontal, 24)

            if viewModel.records.isEmpty {
                Text("まだ読書記録がありません。\n本を読み始めましょう。")
                    .font(ShioriTypography.caption())
                    .foregroundColor(ShioriColors.warmGray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else {
                ForEach(viewModel.records.suffix(5).reversed()) { record in
                    ReadingRecordRow(record: record)
                }
            }
        }
    }
}

// MARK: - 結晶ビュー

/// ボトル内に表示される個々の結晶
struct CrystalView: View {
    let crystal: CrystalData

    /// ゆらゆら浮遊アニメーション
    @State private var isFloating = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [crystalColor.opacity(0.8), crystalColor.opacity(0.2), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 8 * crystal.size
                )
            )
            .frame(width: 16 * crystal.size, height: 16 * crystal.size)
            .offset(
                x: (crystal.position.x - 0.5) * 100,
                y: (crystal.position.y - 0.5) * 200 + (isFloating ? -5 : 5)
            )
            .rotationEffect(.degrees(crystal.rotation))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }

    /// 結晶タイプに応じた色
    private var crystalColor: Color {
        switch crystal.type {
        case .light:    return ShioriColors.warmGold
        case .flower:   return ShioriColors.sakuraPink
        case .deepSea:  return ShioriColors.deepBlue
        case .ember:    return ShioriColors.darkCrimson
        case .mist:     return ShioriColors.mistGray
        }
    }
}

// MARK: - 読書記録行

/// 読書記録の1行表示
struct ReadingRecordRow: View {
    let record: ReadingRecord

    var body: some View {
        HStack(spacing: 12) {
            // 結晶アイコン
            Circle()
                .fill(ShioriColors.dustyRose.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.bookTitle)
                    .font(ShioriTypography.caption())
                    .foregroundColor(ShioriColors.inkBlack)

                Text("\(record.pagesRead)ページ読了")
                    .font(ShioriTypography.pageIndicator())
                    .foregroundColor(ShioriColors.warmGray)
            }

            Spacer()

            Text(formatDate(record.endedAt))
                .font(ShioriTypography.pageIndicator())
                .foregroundColor(ShioriColors.warmGray.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }

    /// 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
