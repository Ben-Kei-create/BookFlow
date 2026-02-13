// ShioriHapticsEngine.swift
// ASMRハプティクスエンジン
// CoreHaptics を使用して紙の質感、心音、衝撃を表現する

import CoreHaptics

/// 触覚フィードバックエンジン
/// ページめくり時の紙質感、シーン転換時の心音、共感タップ時のパルスを管理する
final class ShioriHapticsEngine {

    // MARK: - プロパティ

    /// CoreHaptics エンジン
    private var engine: CHHapticEngine?

    /// エンジンが利用可能かどうか
    private var isAvailable: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - 初期化

    init() {
        setupEngine()
    }

    /// ハプティクスエンジンの初期化
    private func setupEngine() {
        guard isAvailable else { return }

        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true

            // エンジンが停止した場合の再起動ハンドラ
            engine?.stoppedHandler = { [weak self] reason in
                print("ハプティクスエンジン停止: \(reason)")
                self?.restartEngine()
            }

            // エンジンリセットハンドラ
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }

            try engine?.start()
        } catch {
            print("ハプティクスエンジン初期化失敗: \(error)")
        }
    }

    /// エンジンの再起動
    private func restartEngine() {
        do {
            try engine?.start()
        } catch {
            print("ハプティクスエンジン再起動失敗: \(error)")
        }
    }

    // MARK: - ページめくりハプティクス

    /// ページめくり時の紙質感ハプティクスを再生する
    /// 感情スコアに応じて質感が変化する
    /// - Parameter sentiment: 現在のページの感情解析結果
    func playPageTurnHaptic(sentiment: PageSentiment) {
        guard isAvailable, let engine = engine else { return }

        do {
            let pattern = try createPageTurnPattern(sentiment: sentiment)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("ページめくりハプティクス再生失敗: \(error)")
        }
    }

    /// ページめくりの触覚パターンを生成
    /// 通常: しっとりした紙の感触
    /// シリアス: ザラザラした重い紙
    /// ポジティブ: 軽やかでさらさらした紙
    private func createPageTurnPattern(sentiment: PageSentiment) -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        switch sentiment.theme {
        case .neutral:
            // しっとりした紙 — 軽い連続振動
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: 0.15
            ))

        case .ocean:
            // 湿った紙 — 低い振動が長めに
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                ],
                relativeTime: 0,
                duration: 0.25
            ))

        case .fire:
            // ザラザラした紙 — 短いパルスの連続
            for i in 0..<4 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: Double(i) * 0.04
                ))
            }

        case .darkness:
            // 心音のような低い鼓動
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0)
                ],
                relativeTime: 0.15
            ))
        }

        return try! CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - 心音ハプティクス（闇テーマ持続）

    /// 闇テーマ中に持続的に再生される心音ハプティクス
    func playHeartbeatHaptic() {
        guard isAvailable, let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []

            // ドクン...ドクン... のリズム
            for beat in 0..<4 {
                let baseTime = Double(beat) * 0.8

                // 強い拍動
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: baseTime
                ))

                // 弱い拍動（残響）
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                    ],
                    relativeTime: baseTime + 0.2
                ))
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("心音ハプティクス再生失敗: \(error)")
        }
    }

    // MARK: - 共感タップハプティクス

    /// 共感（ダブルタップ）時のパルスハプティクス
    /// パーティクルが弾ける感覚を表現する
    func playEmpathyHaptic() {
        guard isAvailable, let engine = engine else { return }

        do {
            var events: [CHHapticEvent] = []

            // 中心のインパクト
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ))

            // 放射状のパルス（弱くなりながら広がる感覚）
            for i in 1..<5 {
                let intensity = Float(0.5) - Float(i) * 0.1
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: Double(i) * 0.05
                ))
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("共感ハプティクス再生失敗: \(error)")
        }
    }

    // MARK: - エンジン停止

    /// ハプティクスエンジンを停止する（画面離脱時）
    func stop() {
        engine?.stop(completionHandler: nil)
    }
}
