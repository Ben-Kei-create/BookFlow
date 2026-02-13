// SubscriptionManager.swift
// 収益化マネージャ — StoreKit 2 / AdMob
// 広告削除（没入モード）サブスクリプションの管理

import SwiftUI
import StoreKit

/// サブスクリプション・広告管理マネージャ
/// MVP版ではスタブ実装。リリース時にStoreKit 2 / AdMob SDKと統合する
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - 公開プロパティ

    /// 没入モード（広告削除）が有効かどうか
    @Published var isImmersiveModeActive: Bool = false

    /// サブスクリプションの読み込み中フラグ
    @Published var isLoading: Bool = false

    /// 利用可能なプロダクト
    @Published var products: [Product] = []

    // MARK: - プロダクトID

    /// 広告削除サブスクリプションのプロダクトID
    static let immersiveModeProductId = "com.shiori.immersivemode.monthly"

    // MARK: - 初期化

    init() {
        // MVP版: デフォルトは広告あり
        isImmersiveModeActive = false

        // StoreKit 2 のトランザクションリスナーを開始
        Task {
            await listenForTransactions()
        }
    }

    // MARK: - StoreKit 2（プレースホルダー）

    /// 利用可能なプロダクトを取得する
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [
                Self.immersiveModeProductId
            ])
        } catch {
            print("プロダクト取得失敗: \(error)")
        }
        isLoading = false
    }

    /// サブスクリプションを購入する
    func purchase() async -> Bool {
        guard let product = products.first else {
            await loadProducts()
            guard let product = products.first else { return false }
            return await purchaseProduct(product)
        }
        return await purchaseProduct(product)
    }

    /// プロダクトの購入処理
    private func purchaseProduct(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isImmersiveModeActive = true
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            print("購入失敗: \(error)")
            return false
        }
    }

    /// トランザクションの検証
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    /// トランザクションリスナー
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                isImmersiveModeActive = true
                await transaction.finish()
            }
        }
    }

    /// サブスクリプションの復元
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let _ = try? checkVerified(result) {
                isImmersiveModeActive = true
                return
            }
        }
    }

    // MARK: - 広告表示制御

    /// 読書中は広告を表示しない
    /// 章の切れ目やメニュー画面でのみ表示する
    func shouldShowAd(isReading: Bool, isChapterBreak: Bool) -> Bool {
        // 没入モード（有料）なら常に非表示
        if isImmersiveModeActive { return false }

        // 読書中は非表示
        if isReading && !isChapterBreak { return false }

        // 章の切れ目またはメニューで表示
        return true
    }
}

// MARK: - エラー定義

enum StoreError: Error {
    case verificationFailed
}
