import SwiftUI
import Combine

#if canImport(Auth0)
import Auth0
#endif

// MARK: - LINE認証プロバイダー
class LineAuthProvider: ObservableObject, AuthProvider {
    
	//　Auth0の設定（Info.plistから取得）
	private let domain: String = Bundle.main.object(forInfoDictionaryKey: "AUTH0_DOMAIN") as? String ?? ""
	private let clientId: String = Bundle.main.object(forInfoDictionaryKey: "AUTH0_CLIENT_ID") as? String ?? ""
	private let audience: String = Bundle.main.object(forInfoDictionaryKey: "AUTH0_AUDIENCE") as? String ?? ""
	
	// トークンの管理
	private let tokenManager = TokenManager()
	
	// AuthManagerへの参照（認証結果を直接反映するため）
	private var authManager: AuthManager?
	
	// MARK: - AuthProviderプロトコル準拠のためのプロパティ
	// authManagerの状態を参照する計算プロパティ
	var isLoading: Bool {
		authManager?.isLoading ?? false
	}
	
	var errorMessage: String? {
		authManager?.errorMessage
	}
	
	var isLoggedIn: Bool {
		authManager?.isLoggedIn ?? false
	}
	
	// 初期化
	init(authManager: AuthManager? = nil) {
		self.authManager = authManager
	}
	
	// AuthManagerを後から設定（環境オブジェクトとして使用する場合）
	func setAuthManager(_ manager: AuthManager) {
		self.authManager = manager
	}
    
    /// LINEログインを実行
    func login(completion: @escaping (AuthResult) -> Void) {
        #if canImport(Auth0)
        authManager?.isLoading = true
        authManager?.errorMessage = nil
        
        print("💬 LINEログイン開始")
        print("🔍 Domain: \(domain)")
        print("🔍 Client ID: \(clientId)")
        print("🔍 Audience: \(audience)")
        
        // Auth0のUniversal LoginでLINEプロバイダーを指定
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .scope("openid profile email")
            .audience(audience)
            .parameters([
                "connection": "line",
                "ui_locales": Locale.preferredLanguages.first ?? "en"
            ]) // LINEプロバイダーを指定 + 多言語対応
            .start { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAuthResult(result, completion: completion)
                }
            }
        #else
        authManager?.errorMessage = "Auth0モジュールが利用できません"
        authManager?.isLoading = false
        completion(AuthResult(success: false, provider: .line, error: NSError(domain: "Auth0", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth0モジュールが利用できません"])))
        #endif
    }
    
    /// LINEログアウトを実行
    func logout(completion: @escaping (Bool) -> Void) {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession(federated: false) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.clearAuthState()
                        print("✅ LINEログアウト完了")
                        completion(true)
                        
                    case .failure(let error):
                        self?.authManager?.errorMessage = "LINEログアウトに失敗しました: \(error.localizedDescription)"
                        print("❌ LINEログアウトエラー: \(error)")
                        completion(false)
                    }
                }
            }
        #else
        authManager?.errorMessage = "Auth0モジュールが利用できません"
        completion(false)
        #endif
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        return tokenManager.isAccessTokenValid()
    }
    
    // MARK: - プライベートメソッド
    
    /// 認証結果を処理
    #if canImport(Auth0)
    private func handleAuthResult(_ result: Auth0.WebAuthResult<Auth0.Credentials>, completion: @escaping (AuthResult) -> Void) {
        authManager?.isLoading = false
        
        switch result {
        case .success(let credentials):
            // トークンを保存（エラーが発生してもトークンは保存しておく）
            tokenManager.saveToken(credentials.accessToken, type: .accessToken)
            tokenManager.saveToken(credentials.idToken, type: .idToken)
			
			print("🔍 handleAuthResult: 認証成功")
			
			// IDトークンからユーザー情報を取得
			let userInfo = extractUserInfoFromIdToken(credentials.idToken)
			
			print("✅ LINEログイン成功")
			print("Access Token: \(credentials.accessToken)")
			print("ID Token: \(credentials.idToken)")
			
			// ログイン成功結果を生成
			let authResult = AuthResult(
				success: userInfo != nil,
				provider: .line,
				accessToken: credentials.accessToken,
				idToken: credentials.idToken,
				userInfo: userInfo,
				error: userInfo == nil ? NSError(domain: "AuthError", code: -1, userInfo: [
					NSLocalizedDescriptionKey: "ユーザー情報の取得に失敗しました"
				]) : nil
			)
			
			// AuthManagerに直接反映（コールバックも呼び出し）
			authManager?.handleAuthResult(authResult)
			completion(authResult)
            
        case .failure(let error):
            authManager?.isLoggedIn = false
            authManager?.errorMessage = "LINEログインに失敗しました: \(error)"
            print("❌ LINEログインエラー詳細: \(error)")
            print("❌ エラータイプ: \(type(of: error))")
			
			let authResult = AuthResult(
                success: false,
                provider: .line,
                error: error
            )
            
            // AuthManagerに直接反映（コールバックも呼び出し）
            authManager?.handleAuthResult(authResult)
            completion(authResult)
        }
    }
    #endif
	
	/// IDトークンからユーザー情報を抽出
	private func extractUserInfoFromIdToken(_ idToken: String) -> UserInfo? {
		print("🔍 extractUserInfoFromIdToken開始")
		
		// JWTのペイロード部分をデコード（簡易実装）
		// 実際の実装では、JWTライブラリを使用することを推奨
		let tokenParts = idToken.components(separatedBy: ".")
		print("🔍 JWTトークン解析: \(tokenParts.count) parts")
		
		if tokenParts.count >= 2 {
			// Base64URLデコード（URL-safe文字を標準Base64に変換 + パディングを追加）
			var payloadString = tokenParts[1]
				.replacingOccurrences(of: "-", with: "+")
				.replacingOccurrences(of: "_", with: "/")
			
			let remainder = payloadString.count % 4
			if remainder > 0 {
				payloadString += String(repeating: "=", count: 4 - remainder)
			}
			
			print("🔍 デコード対象: \(payloadString)")
			
			if let data = Data(base64Encoded: payloadString),
			   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
				print("✅ JWTデコード成功")
				
				// Auth0のユーザーID（sub）を取得
				let auth0UserId = json["sub"] as? String
				let userEmail = json["email"] as? String
				let userName = json["name"] as? String
				let userPicture = json["picture"] as? String
				
				print("📧 LINEユーザー情報取得:")
				print("  UserID: \(auth0UserId ?? "なし")")
				print("  Email: \(userEmail ?? "なし")")
				print("  Name: \(userName ?? "なし")")
				print("  Picture: \(userPicture ?? "なし")")
				
				guard let userId = auth0UserId else {
					print("❌ Auth0ユーザーIDが取得できません")
					return nil
				}
				
				return UserInfo(
					id: userId,
					email: userEmail,
					name: userName,
					picture: userPicture
				)
			} else {
				print("❌ JWTデコード失敗")
			}
		} else {
			print("❌ JWTトークン形式エラー: パーツ数不足")
		}
		
		return nil
	}
	
	/// 認証状態をクリア
	private func clearAuthState() {
		authManager?.isLoggedIn = false
		authManager?.errorMessage = nil
		tokenManager.clearAllTokens()
	}
    
}

