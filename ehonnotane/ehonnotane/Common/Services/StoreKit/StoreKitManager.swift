import StoreKit
import Foundation
import Combine

/// StoreKit 2を使用したアプリ内課金管理
@MainActor
class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// シングルトンインスタンス
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    
    /// 利用可能なサブスクリプションプロダクト
    @Published var availableProducts: [Product] = []
    
    /// 利用可能なサブスクリプションプロダクト（互換性のため）
    var products: [Product] { availableProducts }
    
    /// 購入済みのサブスクリプション
    @Published var purchasedSubscriptions: [Product] = []
    
    /// 現在のサブスクリプション状態
    @Published var subscriptionStatus: Product.SubscriptionInfo.Status?
    
    /// 読み込み中フラグ
    @Published var isLoading = false
    
    /// エラー情報
    @Published var lastError: StoreKitError?
    
    // MARK: - Private Properties
    
    /// サブスクリプションプロダクトID
    private let productIds = [
        "com.ehonnotane.subscription.starter",
        "com.ehonnotane.subscription.plus",
        "com.ehonnotane.subscription.premium"
    ]
    
    /// トランザクション更新タスク
    private var transactionUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    private init() {
        // アプリ起動時にトランザクション監視を開始
        transactionUpdateTask = Task {
            await observeTransactionUpdates()
        }
        
        // プロダクト情報を読み込み
        Task {
            await loadProducts()
            await checkPurchasedSubscriptions()
        }
    }
    
    deinit {
        transactionUpdateTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// プロダクト情報を読み込む
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: productIds)
            self.availableProducts = products.sorted { lhs, rhs in
                // 価格順にソート
                (lhs.price as Decimal) < (rhs.price as Decimal)
            }
            print("✅ StoreKit: \(products.count)個のプロダクトを読み込みました")
        } catch {
            print("❌ StoreKit: プロダクト読み込みエラー - \(error)")
            lastError = .loadProductsFailed(error)
        }
    }
    
    /// サブスクリプションを購入
    func purchase(_ product: Product) async throws -> Transaction {
        isLoading = true
        defer { isLoading = false }
        
        print("🛒 StoreKit: 購入開始 - \(product.id)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // トランザクションを検証
            let transaction = try checkVerified(verification)
            
            print("✅ StoreKit: App Store購入成功 - \(transaction.productID)")
            
            // バックエンドでトランザクション検証とクレジット付与
            do {
                let response = try await SubscriptionService.shared.verifyTransaction(transaction: transaction)
                print("✅ バックエンド検証成功 - credits: \(response.creditsGranted), total: \(response.totalCredits)")
            } catch {
                // バックエンド検証失敗でもトランザクションは完了させる
                // （後でリトライ可能）
                print("⚠️ バックエンド検証エラー: \(error)")
                print("⚠️ トランザクションは完了しますが、クレジット付与は後で再試行されます")
            }
            
            // トランザクションを完了
            await transaction.finish()
            
            // サブスクリプション状態を更新
            await checkPurchasedSubscriptions()
            
            return transaction
            
        case .userCancelled:
            print("⚠️ StoreKit: ユーザーが購入をキャンセルしました")
            throw StoreKitError.purchaseCancelled
            
        case .pending:
            print("⏳ StoreKit: 購入が保留中です（Ask to Buyなど）")
            throw StoreKitError.purchasePending
            
        @unknown default:
            print("❌ StoreKit: 不明な購入結果")
            throw StoreKitError.unknownPurchaseResult
        }
    }
    
    /// 購入を復元
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("🔄 StoreKit: 購入を復元中...")
        
        try await AppStore.sync()
        await checkPurchasedSubscriptions()
        
        print("✅ StoreKit: 購入の復元が完了しました")
    }
    
    /// 購入済みサブスクリプションを確認
    func checkPurchasedSubscriptions() async {
        var purchased: [Product] = []
        
        // 現在有効なすべてのエンタイトルメントを確認
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // サブスクリプションプロダクトの場合
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchased.append(product)
                    
                    // サブスクリプション状態を取得
                    if let subscription = product.subscription {
                        Task {
                            let statuses = try? await subscription.status
                            if let status = statuses?.first {
                                await MainActor.run {
                                    self.subscriptionStatus = status
                                    print("✅ StoreKit: サブスクリプション状態 - \(status.state)")
                                }
                            }
                        }
                    }
                }
                
            } catch {
                print("❌ StoreKit: トランザクション検証エラー - \(error)")
            }
        }
        
        self.purchasedSubscriptions = purchased
        
        if purchased.isEmpty {
            print("ℹ️ StoreKit: 購入済みサブスクリプションはありません")
        } else {
            print("✅ StoreKit: \(purchased.count)個のサブスクリプションが有効です")
        }
    }
    
    // MARK: - Private Methods
    
    /// トランザクション更新を監視
    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                
                print("🔔 StoreKit: トランザクション更新 - \(transaction.productID)")
                
                // サブスクリプション状態を更新
                await checkPurchasedSubscriptions()
                
                // トランザクションを完了
                await transaction.finish()
                
            } catch {
                print("❌ StoreKit: トランザクション更新エラー - \(error)")
            }
        }
    }
    
    /// トランザクション検証
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let transaction, let error):
            // 検証に失敗
            print("❌ StoreKit: トランザクション検証失敗 - \(error)")
            throw StoreKitError.verificationFailed(error)
            
        case .verified(let transaction):
            // 検証成功
            return transaction
        }
    }
}

// MARK: - StoreKitError

enum StoreKitError: LocalizedError {
    case loadProductsFailed(Error)
    case purchaseCancelled
    case purchasePending
    case unknownPurchaseResult
    case verificationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .loadProductsFailed(let error):
            return "プロダクト情報の読み込みに失敗しました: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "購入がキャンセルされました"
        case .purchasePending:
            return "購入が保留中です。承認されると自動的に完了します。"
        case .unknownPurchaseResult:
            return "不明な購入結果です"
        case .verificationFailed(let error):
            return "トランザクションの検証に失敗しました: \(error.localizedDescription)"
        }
    }
}
