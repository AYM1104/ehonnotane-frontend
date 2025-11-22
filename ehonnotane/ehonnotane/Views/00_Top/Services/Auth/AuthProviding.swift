import Foundation

/// 認証関連のアクセスを統一するためのプロトコル
protocol AuthProviding {
    func getAccessToken() -> String?
    func isAuthenticated() -> Bool
    func getCurrentUserId() -> String?
}

/// 既存のAuthManager/TokenManagerを包むデフォルト実装
final class DefaultAuthProvider: AuthProviding {
    private let authManager: AuthManager
    private let tokenManager: TokenManager
    
    init(authManager: AuthManager = AuthManager(),
         tokenManager: TokenManager = TokenManager()) {
        self.authManager = authManager
        self.tokenManager = tokenManager
    }
    
    func getAccessToken() -> String? {
        return tokenManager.getAccessToken()
    }
    
    func isAuthenticated() -> Bool {
        return authManager.verifyAuthState()
    }
    
    func getCurrentUserId() -> String? {
        return authManager.getCurrentUserId()
    }
}

