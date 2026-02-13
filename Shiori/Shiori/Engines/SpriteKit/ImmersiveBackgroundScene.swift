// ImmersiveBackgroundScene.swift
// 没入型背景シーン（SpriteKit）
// AI演出監督：テキストの感情に応じて背景とエフェクトを自動生成

import SpriteKit

/// 感情テーマに応じた動的背景を描画するSpriteKitシーン
/// パーティクル（雨、泡、火の粉）、光エフェクト、シェーダーを管理する
final class ImmersiveBackgroundScene: SKScene {

    // MARK: - プロパティ

    /// 現在のテーマ
    private var currentTheme: EmotionTheme

    /// パーティクルエミッタノード
    private var particleEmitter: SKEmitterNode?

    /// 背景色ノード
    private var backgroundNode: SKSpriteNode?

    /// ビネットノード（闇テーマ）
    private var vignetteNode: SKSpriteNode?

    /// バックグラウンド移行フラグ（メモリ管理用）
    private var isInBackground = false

    // MARK: - 初期化

    init(size: CGSize, theme: EmotionTheme) {
        self.currentTheme = theme
        super.init(size: size)
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        self.currentTheme = .neutral
        super.init(coder: aDecoder)
    }

    // MARK: - シーンライフサイクル

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        setupBackground()
        applyTheme(currentTheme)

        // バックグラウンド通知の監視（エフェクト停止用）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        // リソースの解放
        removeAllChildren()
        removeAllActions()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - バックグラウンド制御

    /// ⚠️ 重要: バックグラウンド時にエフェクトを即座に停止する
    @objc private func appDidEnterBackground() {
        isInBackground = true
        isPaused = true
        particleEmitter?.isPaused = true
    }

    /// フォアグラウンド復帰時にエフェクトを再開する
    @objc private func appWillEnterForeground() {
        isInBackground = false
        isPaused = false
        particleEmitter?.isPaused = false
    }

    // MARK: - 背景セットアップ

    /// 基本背景ノードの初期化
    private func setupBackground() {
        let bg = SKSpriteNode(color: .clear, size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        addChild(bg)
        backgroundNode = bg
    }

    // MARK: - テーマ切り替え

    /// 感情テーマに応じた演出を適用する
    func applyTheme(_ theme: EmotionTheme) {
        guard !isInBackground else { return }
        currentTheme = theme

        // 既存のパーティクルを除去
        particleEmitter?.removeFromParent()
        particleEmitter = nil

        switch theme {
        case .neutral:
            applyNeutralTheme()
        case .ocean:
            applyOceanTheme()
        case .fire:
            applyFireTheme()
        case .darkness:
            applyDarknessTheme()
        }
    }

    // MARK: - 通常テーマ（生成りの紙、静寂）

    /// 静かな生成り色の背景。微かな光の揺らぎのみ
    private func applyNeutralTheme() {
        backgroundNode?.color = UIColor(red: 0.976, green: 0.965, blue: 0.941, alpha: 1.0)

        // 微かな光の粒子
        let emitter = createSubtleDustEmitter()
        emitter.position = CGPoint(x: size.width / 2, y: size.height)
        emitter.zPosition = -5
        addChild(emitter)
        particleEmitter = emitter
    }

    // MARK: - 海/悲しみテーマ（青、泡、滲み）

    /// 深い青の背景に上昇する泡のパーティクル
    private func applyOceanTheme() {
        backgroundNode?.run(
            SKAction.colorize(
                with: UIColor(red: 0.204, green: 0.310, blue: 0.447, alpha: 0.3),
                colorBlendFactor: 1.0,
                duration: 1.5
            )
        )

        // 泡パーティクル（下から上へ）
        let emitter = createBubbleEmitter()
        emitter.position = CGPoint(x: size.width / 2, y: 0)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        emitter.zPosition = -5
        addChild(emitter)
        particleEmitter = emitter
    }

    // MARK: - 炎/怒りテーマ（赤黒い、火の粉）

    /// 暗い赤の背景に舞い散る火の粉
    private func applyFireTheme() {
        backgroundNode?.run(
            SKAction.colorize(
                with: UIColor(red: 0.447, green: 0.153, blue: 0.129, alpha: 0.3),
                colorBlendFactor: 1.0,
                duration: 1.5
            )
        )

        // 火の粉パーティクル
        let emitter = createEmberEmitter()
        emitter.position = CGPoint(x: size.width / 2, y: 0)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        emitter.zPosition = -5
        addChild(emitter)
        particleEmitter = emitter
    }

    // MARK: - 闇/恐怖テーマ（ビネット、静寂）

    /// 暗い背景にビネット効果。パーティクルは最小限
    private func applyDarknessTheme() {
        backgroundNode?.run(
            SKAction.colorize(
                with: UIColor(red: 0.094, green: 0.082, blue: 0.082, alpha: 0.5),
                colorBlendFactor: 1.0,
                duration: 2.0
            )
        )

        // 非常に控えめな霧のパーティクル
        let emitter = createMistEmitter()
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.zPosition = -5
        addChild(emitter)
        particleEmitter = emitter
    }

    // MARK: - パーティクルエミッタ生成

    /// 微かなホコリの粒子（通常テーマ用）
    private func createSubtleDustEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 3
        emitter.numParticlesToEmit = 0 // 無限
        emitter.particleLifetime = 8
        emitter.particleLifetimeRange = 4
        emitter.particleSpeed = 5
        emitter.particleSpeedRange = 3
        emitter.emissionAngle = .pi * 1.5 // 下向き
        emitter.emissionAngleRange = 0.5
        emitter.particleAlpha = 0.1
        emitter.particleAlphaRange = 0.05
        emitter.particleAlphaSpeed = -0.01
        emitter.particleScale = 0.02
        emitter.particleScaleRange = 0.01
        emitter.particleColor = UIColor(red: 0.831, green: 0.722, blue: 0.502, alpha: 1.0)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        return emitter
    }

    /// 泡パーティクル（海テーマ用）
    private func createBubbleEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 5
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 10
        emitter.particleLifetimeRange = 5
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2 // 上向き
        emitter.emissionAngleRange = 0.3
        emitter.particleAlpha = 0.15
        emitter.particleAlphaRange = 0.1
        emitter.particleAlphaSpeed = -0.01
        emitter.particleScale = 0.03
        emitter.particleScaleRange = 0.02
        emitter.particleColor = UIColor(red: 0.608, green: 0.694, blue: 0.745, alpha: 1.0)

        // 泡の横揺れ
        let wobble = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 2),
            SKAction.moveBy(x: -10, y: 0, duration: 2)
        ])
        emitter.particleAction = SKAction.repeatForever(wobble)

        return emitter
    }

    /// 火の粉パーティクル（炎テーマ用）
    private func createEmberEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 8
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 5
        emitter.particleLifetimeRange = 3
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi / 2 // 上向き
        emitter.emissionAngleRange = 0.8
        emitter.particleAlpha = 0.3
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.05
        emitter.particleScale = 0.02
        emitter.particleScaleRange = 0.015
        emitter.particleColor = UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorRedRange = 0.2
        return emitter
    }

    /// 霧パーティクル（闇テーマ用）
    private func createMistEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 1
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 15
        emitter.particleLifetimeRange = 5
        emitter.particleSpeed = 2
        emitter.particleSpeedRange = 1
        emitter.emissionAngleRange = .pi * 2 // 全方向
        emitter.particleAlpha = 0.05
        emitter.particleAlphaRange = 0.03
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleColor = UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        return emitter
    }
}
