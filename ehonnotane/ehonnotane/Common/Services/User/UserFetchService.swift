import Foundation

// MARK: - Model ---------------------------------------------------------------

/// ユーザー情報モデル
struct User: Codable, Identifiable {
    let id: String
    let user_name: String
    let email: String?
    let balance: Int
    let subscription_plan: PlanType
    let created_at: String
    let updated_at: String
}

/// サブスクリプションプラン種別
enum PlanType: String, Codable {
    case free = "FREE"
    case starter = "STARTER"
    case plus = "PLUS"
    case premium = "PREMIUM"
    
    /// ドロワー等に表示するプラン名
    var displayName: String {
        switch self {
        case .free: return "無料"
        case .starter: return "スターター"
        case .plus: return "プラス"
        case .premium: return "プレミアム"
        }
    }
}


// MARK: - Service ------------------------------------------------------------

/// ユーザー情報取得を担当するサービス
class UserFetchService {
    static let shared = UserFetchService()
    
    private init() {}
    
    /// ユーザー情報を取得
    func fetchUser(userId: String) async throws -> User {
        let endpoint = "/api/users/\(userId)"
        return try await APIClient.shared.request(endpoint: endpoint)
    }
}

