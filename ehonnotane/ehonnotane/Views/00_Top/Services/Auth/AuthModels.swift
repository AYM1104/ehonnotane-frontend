import Foundation

// MARK: - 認証結果モデル
struct AuthResult {
    let success: Bool
    let provider: AuthProviderType
    let accessToken: String?
    let idToken: String?
    let userInfo: UserInfo?
    let error: Error?
    
    init(
        success: Bool,
        provider: AuthProviderType,
        accessToken: String? = nil,
        idToken: String? = nil,
        userInfo: UserInfo? = nil,
        error: Error? = nil
    ) {
        self.success = success
        self.provider = provider
        self.accessToken = accessToken
        self.idToken = idToken
        self.userInfo = userInfo
        self.error = error
    }
}

// MARK: - ユーザー情報モデル
struct UserInfo {
    let id: String
    let email: String?
    let name: String?
    let picture: String?
    
    var displayName: String {
        return name ?? email ?? "ユーザー"
    }
}

// MARK: - トークン種別
enum TokenType: String, CaseIterable {
    case accessToken = "access_token"
    case idToken = "id_token"
    case refreshToken = "refresh_token"
    
    var key: String {
        return "auth0_\(self.rawValue)"
    }
}


