import SwiftUI
import Combine
import Foundation

// MARK: - 認証状態管理（ログイン関連のみ）
public class AuthManager: ObservableObject {
    
    private let tokenManager = TokenManager()
    
    // MARK: - 認証状態
    @Published var isLoggedIn = false
    @Published var currentProvider: AuthProviderType?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isNewUser = false
    
    // MARK: - ユーザー情報（ログイン結果から利用）
    @Published var userInfo: UserInfo?
    
    // MARK: - 初期化
    public static let shared = AuthManager()
    public init() {}
    
    // MARK: - ログイン状態確認
    /// 起動時に保存されたトークンを確認してログイン状態を復元
    func checkLoginStatus() {
        if tokenManager.isAccessTokenValid() {
            print("✅ AuthManager: 有効なトークンを確認 - 自動ログイン")
            isLoggedIn = true
            
            // IDトークンからユーザー情報を復元（簡易的）
            if let userId = getCurrentUserId() {
                // 必要であればここでAPIを叩いて詳細なユーザー情報を取得する
                // 現状はIDのみセットしておく
                self.userInfo = UserInfo(id: userId, email: nil, name: "User", picture: nil)
            }
        } else {
            print("ℹ️ AuthManager: 有効なトークンなし - 未ログイン状態")
            isLoggedIn = false
            userInfo = nil
        }
    }
    
    // MARK: - ログイン結果の処理
    /// 認証結果を処理（ログイン成功/失敗の状態のみを反映）
    func handleAuthResult(_ result: AuthResult) {
        if result.success {
            // 認証成功したが、バックエンドとの同期が必要
            guard let userInfo = result.userInfo else {
                isLoading = false
                errorMessage = String(localized: "auth.error.user_info_not_found")
                return
            }
            
            // 同期処理を開始（ローディング状態を維持/再設定）
            isLoading = true
            
            Task {
                do {
                    // バックエンドと同期（ユーザー登録または取得）
                    let (user, isNew) = try await UserService.shared.syncUser(auth0User: userInfo)
                    
                    await MainActor.run {
                        self.isNewUser = isNew
                        self.isLoggedIn = true
                        self.currentProvider = result.provider
                        self.errorMessage = nil
                        self.userInfo = userInfo
                        self.isLoading = false
                        print("✅ 認証・同期成功: \(result.provider.displayName), NewUser: \(isNew)")
                    }
                } catch {
                    await MainActor.run {
                        self.isLoggedIn = false
                        self.currentProvider = nil
                        self.errorMessage = String(localized: "auth.error.login_failed")
                        self.userInfo = nil
                        self.isLoading = false
                        print("❌ 同期失敗: \(error)")
                    }
                }
            }
        } else {
            isLoading = false
            isLoggedIn = false
            currentProvider = nil
            errorMessage = result.error?.localizedDescription ?? String(localized: "auth.error.auth_failed")
            userInfo = nil
            
            print("❌ 認証失敗: \(result.provider.displayName) - \(errorMessage ?? "")")
        }
    }
    
    /// 現在のアクセストークンが有効かを確認
    func verifyAuthState() -> Bool {
        if isLoggedIn {
            return true
        }
        return tokenManager.isAccessTokenValid()
    }
    
    /// 現在のアクセストークンを取得
    func getAccessToken() -> String? {
        return tokenManager.getAccessToken()
    }
    
    /// 現在ログイン中のユーザーIDを取得
    func getCurrentUserId() -> String? {
        if let userId = userInfo?.id {
            return userId
        }
        if let idToken = tokenManager.getToken(type: .idToken),
           let decoded = Self.decodeJWT(token: idToken),
           let sub = decoded["sub"] as? String {
            return sub
        }
        return nil
    }
    
    /// JWTトークンを簡易デコードしてペイロードを取得
    private static func decodeJWT(token: String) -> [String: Any]? {
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return nil }
        
        var payload = components[1]
        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }

    
    /// ログアウト処理（状態のクリアのみ）
    func logout() {
        tokenManager.clearAllTokens()
        isLoggedIn = false
        currentProvider = nil
        userInfo = nil
        print("✅ AuthManager: ログアウト完了（ローカル状態クリア）")
    }
}


