// OnboardingView.swift
// オンボーディング画面
// 初回起動時に「言葉を浴びる」体験のコンセプトを伝える
// 韓国カフェ風ミニマリズムのデザイン

import SwiftUI

/// 初回起動オンボーディング画面
/// アプリのコンセプトを3ステップで伝え、没入体験への期待を高める
struct OnboardingView: View {
    // MARK: - プロパティ
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var opacity: Double = 0

    /// オンボーディングの各ステップ
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "leaf.fill",
            title: "言葉を浴びる",
            description: "読むのではなく、物語の世界に\n身を委ねる読書体験を。",
            accentColor: ShioriColors.dustyGreen
        ),
        OnboardingStep(
            icon: "waveform",
            title: "物語が息づく",
            description: "文章の感情に合わせて\n背景と音が変化します。",
            accentColor: ShioriColors.dustyBlue
        ),
        OnboardingStep(
            icon: "sparkles",
            title: "共感が光る",
            description: "他の読者が心を動かされた\n一節が、蛍のように光ります。",
            accentColor: ShioriColors.dustyRose
        ),
    ]

    var body: some View {
        ZStack {
            // 背景
            ShioriColors.kinari
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // コンテンツ
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepView(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 360)

                // ページインジケータ
                pageIndicator
                    .padding(.top, 32)

                Spacer()

                // ボタン
                actionButton
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
        }
        .opacity(opacity)
    }

    // MARK: - ステップビュー

    /// 個々のオンボーディングステップ
    private func stepView(step: OnboardingStep) -> some View {
        VStack(spacing: 24) {
            // アイコン（有機的な光の輪で囲む）
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [step.accentColor.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: step.icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(step.accentColor)
            }

            // タイトル
            Text(step.title)
                .font(ShioriTypography.bookTitle())
                .foregroundColor(ShioriColors.inkBlack)

            // 説明文
            Text(step.description)
                .font(ShioriTypography.body())
                .lineSpacing(ShioriTypography.bodyLineSpacing)
                .kerning(ShioriTypography.bodyKerning)
                .foregroundColor(ShioriColors.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - ページインジケータ

    /// ミニマルなドットインジケータ
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Circle()
                    .fill(
                        index == currentStep
                            ? ShioriColors.inkBlack
                            : ShioriColors.warmGray.opacity(0.3)
                    )
                    .frame(width: index == currentStep ? 8 : 6,
                           height: index == currentStep ? 8 : 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - アクションボタン

    /// 「次へ」または「はじめる」ボタン（枠なしミニマルデザイン）
    private var actionButton: some View {
        Button {
            if currentStep < steps.count - 1 {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep += 1
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        } label: {
            Text(currentStep < steps.count - 1 ? "次へ" : "はじめる")
                .font(ShioriTypography.button())
                .foregroundColor(ShioriColors.kinari)
                .frame(width: 200, height: 48)
                .background(
                    Capsule()
                        .fill(ShioriColors.inkBlack)
                )
        }
    }
}

// MARK: - データモデル

/// オンボーディングのステップデータ
private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
}
