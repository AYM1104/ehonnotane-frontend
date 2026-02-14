import Foundation
import StoreKit

/// バックエンドとのサブスクリプション連携サービス
class SubscriptionService {
    
    static let shared = SubscriptionService()
    
    private init() {}
    
    // MARK: - Models
    
    /// トランザクション検証リクエスト
    struct VerifyTransactionRequest: Codable {
        let transaction: TransactionData
        
        struct TransactionData: Codable {
            let id: String
            let originalTransactionId: String
            let productId: String
            let purchaseDate: String
            let expiresDate: String?
            let jwsRepresentation: String
        }
    }
    
    /// トランザクション検証レスポンス
    struct VerifyTransactionResponse: Codable {
        let success: Bool
        let subscription: SubscriptionInfo
        let creditsGranted: Int
        let totalCredits: Int
    }
    
    /// サブスクリプション情報
    struct SubscriptionInfo: Codable {
        let id: Int
        let userId: String
        let planType: String
        let productId: String
        let status: String
        let expiresAt: String?
        let autoRenewStatus: Bool
    }
    
    /// サブスクリプション状態レスポンス
    struct SubscriptionStatusResponse: Codable {
        let subscription: SubscriptionInfo?
        let credits: CreditsInfo
        
        struct CreditsInfo: Codable {
            let balance: Int
            let monthlyAllocation: Int
            let nextGrantDate: String?
        }
    }
    
    // MARK: - Public Methods
    
    /// トランザクションをバックエンドで検証
    func verifyTransaction(transaction: Transaction) async throws -> VerifyTransactionResponse {
        let endpoint = "/api/subscriptions/verify"
        
        // 購入日時と有効期限をISO 8601形式に変換
        let purchaseDate = ISO8601DateFormatter().string(from: transaction.purchaseDate)
        let expiresDate = transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) }
        
        // JWS表現を取得（iOS 15.2+）
        let jwsRepresentation: String
        if #available(iOS 15.2, *) {
            // Data型をStringに変換
            if let jwsString = String(data: transaction.jsonRepresentation, encoding: .utf8) {
                jwsRepresentation = jwsString
            } else {
                throw NSError(domain: "SubscriptionService", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "JWS表現の変換に失敗しました"
                ])
            }
        } else {
            // Fallback: iOS 15.0-15.1ではJWS取得できない
            throw NSError(domain: "SubscriptionService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "iOS 15.2以上が必要です"
            ])
        }
        
        let requestBody = VerifyTransactionRequest(
            transaction: VerifyTransactionRequest.TransactionData(
                id: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                productId: transaction.productID,
                purchaseDate: purchaseDate,
                expiresDate: expiresDate,
                jwsRepresentation: jwsRepresentation
            )
        )
        
        print("📡 SubscriptionService: トランザクション検証リクエスト送信")
        
        let response: VerifyTransactionResponse = try await APIClient.shared.request(
            endpoint: endpoint,
            method: .post,
            body: requestBody
        )
        
        print("✅ SubscriptionService: トランザクション検証成功 - credits: \(response.creditsGranted)")
        return response
    }
    
    /// サブスクリプション状態を取得
    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        let endpoint = "/api/subscriptions/status"
        
        print("📡 SubscriptionService: サブスクリプション状態取得")
        
        // GETリクエスト用に空のbody構造体を定義
        struct EmptyBody: Codable {}
        
        let response: SubscriptionStatusResponse = try await APIClient.shared.request(
            endpoint: endpoint,
            method: .get,
            body: EmptyBody()
        )
        
        if let subscription = response.subscription {
            print("✅ サブスクリプション状態取得: plan=\(subscription.planType), status=\(subscription.status)")
        } else {
            print("ℹ️ サブスクリプションなし")
        }
        
        return response
    }
    
    /// プロダクトIDからプラン名を取得
    func planName(for productId: String) -> String {
        switch productId {
        case "com.ehonnotane.subscription.starter":
            return "はじめてのたね"
        case "com.ehonnotane.subscription.plus":
            return "そだてるたね"
        case "com.ehonnotane.subscription.premium":
            return "わくわくのたね"
        default:
            return "不明なプラン"
        }
    }
    
    /// プロダクトIDから月次クレジット数を取得
    func monthlyCredits(for productId: String) -> Int {
        switch productId {
        case "com.ehonnotane.subscription.starter":
            return 600
        case "com.ehonnotane.subscription.plus":
            return 1000
        case "com.ehonnotane.subscription.premium":
            return 1500
        default:
            return 0
        }
    }
}
