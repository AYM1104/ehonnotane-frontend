import Foundation

// MARK: - Model ---------------------------------------------------------------

/// ユーザー削除レスポンスモデル
struct DeleteUserResponse: Decodable {
    let user_id: String
}


// MARK: - Service ------------------------------------------------------------

/// ユーザー削除を担当するサービス
class UserDeleteService {
    static let shared = UserDeleteService()
    
    private init() {}
    
    /// ユーザーを削除
    func deleteUser(userId: String) async throws {
        let endpoint = "/api/users/\(userId)"
        
        // bodyは不要なのでnilを渡す（型推論のために型指定）
        let body: String? = nil
        let _: DeleteUserResponse = try await APIClient.shared.request(endpoint: endpoint, method: .delete, body: body)
    }
}

