import Foundation

// MARK: - Model ---------------------------------------------------------------

/// ユーザー作成リクエストモデル
struct UserCreateRequest: Encodable {
    let id: String
    let user_name: String
    let email: String?
}


// MARK: - Service ------------------------------------------------------------

/// ユーザー作成を担当するサービス
class UserCreateService {
    static let shared = UserCreateService()
    
    private init() {}
    
    /// ユーザーを新規作成
    func createUser(user: UserCreateRequest) async throws -> User {
        let endpoint = "/api/users/"
        return try await APIClient.shared.request(endpoint: endpoint, method: .post, body: user)
    }
}

