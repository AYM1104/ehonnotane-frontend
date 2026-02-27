import SwiftUI
import Combine

#if canImport(Auth0)
import Auth0
#endif

// MARK: - Apple認証プロバイダー
class AppleAuthProvider: ObservableObject, AuthProvider {

    
    // MARK: - Auth0設定
    #if canImport(Auth0)
    private let domain = "ehonnotane.jp.auth0.com"
    private let clientId = "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh"
    private let audience = "https://api.ehonnotane"
    #endif
    
    // MARK: - 認証状態管理
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    
    // MARK: - AuthManagerへの参照（認証結果を直接反映するため）
    private var authManager: AuthManager?
    
    // MARK: - トークン管理
    private let tokenManager = TokenManager()
    
    // AuthManagerを後から設定（環境オブジェクトとして使用する場合）
    func setAuthManager(_ manager: AuthManager) {
        self.authManager = manager
    }
    
    // MARK: - パブリックメソッド
    
    /// Apple Sign Inを実行
    func login(completion: @escaping (AuthResult) -> Void) {
        #if canImport(Auth0)
        isLoading = true
        errorMessage = nil
        
        print("🍎 Apple Sign In開始")
        print("🔍 Domain: \(domain)")
        print("🔍 Client ID: \(clientId)")
        print("🔍 Audience: \(audience)")
        
        // Auth0のUniversal LoginでAppleプロバイダーを指定
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .scope("openid profile email")
            .audience(audience)
            .parameters([
                "connection": "Apple",
                "ui_locales": Locale.preferredLanguages.first ?? "en"
            ]) // Appleプロバイダーを指定 + 多言語対応
            .start { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAuthResult(result, completion: completion)
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        completion(AuthResult(success: false, provider: .apple, error: NSError(domain: "Auth0", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth0モジュールが利用できません"])))
        #endif
    }
    
    /// Apple Sign Outを実行
    func logout(completion: @escaping (Bool) -> Void) {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession(federated: false) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.clearAuthState()
                        print("✅ Appleログアウト完了")
                        completion(true)
                        
                    case .failure(let error):
                        self?.errorMessage = "Appleログアウトに失敗しました: \(error.localizedDescription)"
                        print("❌ Appleログアウトエラー: \(error)")
                        completion(false)
                    }
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
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
        isLoading = false
        
        switch result {
        case .success(let credentials):
            print("🔍 handleAuthResult: .success ケースに入りました")
            
            // トークンを保存（エラーが発生してもトークンは保存しておく）
            tokenManager.saveToken(credentials.accessToken, type: .accessToken)
            tokenManager.saveToken(credentials.idToken, type: .idToken)
            
            print("🔍 handleAuthResult: トークン保存完了")
            print("🔍 handleAuthResult: 認証成功")
            print("🔍 handleAuthResult: IDトークンの抽出を開始...")
            
            // IDトークンからユーザー情報を取得
            let userInfo = extractUserInfoFromIdToken(credentials.idToken)

            
            print("✅ Apple Sign In成功")
            print("Access Token: \(credentials.accessToken)")
            print("ID Token: \(credentials.idToken)")
            
            // Auth0認証成功 → AuthResultをsuccess:trueで返す
            // バックエンドとの同期はAuthManager.handleAuthResult内のsyncUserで行う
            // ※ registerUserToSupabase は削除済み（syncUser と競合してユーザー二重作成エラーの原因となっていたため）
            if let userInfo = userInfo {
                // Auth0認証成功時点でAuthResultを返す
                let authResult = AuthResult(
                    success: true,
                    provider: .apple,
                    accessToken: credentials.accessToken,
                    idToken: credentials.idToken,
                    userInfo: userInfo
                )
                // AuthManagerに直接反映（コールバックも呼び出し）
                self.authManager?.handleAuthResult(authResult)
                completion(authResult)
            } else {
                // userInfoが取得できない場合（JWTデコード失敗）
                self.isLoggedIn = false
                self.errorMessage = "ユーザー情報の取得に失敗しました"
                
                completion(AuthResult(
                    success: false,
                    provider: .apple,
                    error: NSError(domain: "AuthError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "ユーザー情報の取得に失敗しました"
                    ])
                ))
            }
            
        case .failure(let error):
            isLoggedIn = false
            
            // エラーメッセージを解析して、より分かりやすいメッセージを生成
            let errorDescription = error.localizedDescription
            var userFriendlyMessage = "Apple Sign Inに失敗しました"
            
            // 「connection is not enabled」エラーの場合、Auth0設定の問題であることを明確に伝える
            if errorDescription.lowercased().contains("connection is not enabled") ||
               errorDescription.lowercased().contains("the connection is not enabled") {
                userFriendlyMessage = """
                Apple Sign Inが有効になっていません。
                
                Auth0ダッシュボードで以下の設定を行ってください：
                1. Auth0ダッシュボードにログイン
                2. 「Authentication」→「Social」→「Apple」を選択
                3. Apple接続を有効化
                4. 「Applications」タブでNative App（\(clientId)）を有効化
                5. Apple Developerで作成したService IDとKey IDを設定
                
                詳細は開発者にお問い合わせください。
                """
                print("❌ Apple Sign Inエラー: Auth0でApple接続が有効になっていません")
                print("   解決方法: Auth0ダッシュボードでApple接続を有効化してください")
            } else {
                userFriendlyMessage = "Apple Sign Inに失敗しました: \(errorDescription)"
            }
            
            errorMessage = userFriendlyMessage
            print("❌ Apple Sign Inエラー詳細: \(error)")
            print("❌ エラータイプ: \(type(of: error))")
            print("❌ エラー説明: \(errorDescription)")
            
            completion(AuthResult(
                success: false,
                provider: .apple,
                error: error
            ))
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
            // Base64URLデコード（パディングを追加）
            var payloadString = tokenParts[1]
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
                
                print("📧 Appleユーザー情報取得:")
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
    
    /// バックエンドサーバーへの接続をテスト（リトライ機能付き）
    private func testServerConnection(baseURL: String) async -> Bool {
        guard let testURL = URL(string: "\(baseURL)/health") else {
            print("❌ 接続テストURLエラー")
            return false
        }
        
        // 最大3回試行（初回 + 2回のリトライ）
        let maxRetries = 2
        let retryDelays: [TimeInterval] = [1.0, 3.0] // 指数バックオフ: 1秒、3秒
        
        for attempt in 0...maxRetries {
            var request = URLRequest(url: testURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 5.0 // 5秒でタイムアウト
            
            if attempt > 0 {
                print("🔄 リトライ試行 \(attempt)/\(maxRetries): \(testURL.absoluteString)")
            } else {
                print("🔍 接続テスト: \(testURL.absoluteString)")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if attempt > 0 {
                        print("✅ サーバー接続テスト成功（リトライ後）: \(httpResponse.statusCode)")
                    } else {
                        print("✅ サーバー接続テスト成功: \(httpResponse.statusCode)")
                    }
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   レスポンス: \(responseString)")
                    }
                    return httpResponse.statusCode == 200
                }
            } catch let urlError as URLError {
                // リトライ可能なエラーかチェック
                let shouldRetry = (urlError.code == .timedOut || urlError.code == .cannotConnectToHost) && attempt < maxRetries
                
                if attempt == 0 {
                    print("❌ サーバー接続テスト失敗:")
                    print("   - エラータイプ: \(urlError.localizedDescription)")
                    print("   - エラーコード: \(urlError.code.rawValue)")
                    print("   - URL: \(urlError.failingURL?.absoluteString ?? testURL.absoluteString)")
                }
                
                // エラーの種類に応じた詳細メッセージ
                switch urlError.code {
                case .notConnectedToInternet:
                    print("   ⚠️ インターネット接続がありません。")
                    print("      iOS Simulatorの場合: localhost または 127.0.0.1 を使用してください")
                    print("      実機の場合: デバイスとサーバーが同じWi-Fiネットワークに接続されているか確認してください")
                    // インターネット接続エラーはリトライしない
                    return false
                case .cannotConnectToHost:
                    if shouldRetry {
                        print("   ⚠️ ホストに接続できません (\(baseURL)) - リトライします...")
                    } else {
                        print("   ⚠️ ホストに接続できません (\(baseURL))")
                        print("      - バックエンドサーバーが起動しているか確認してください")
                        print("      - ファイアウォール設定を確認してください")
                        print("      - iOS Simulatorの場合: 192.168.3.92 の代わりに localhost または 127.0.0.1 を試してください")
                    }
                case .timedOut:
                    if shouldRetry {
                        print("   ⚠️ リクエストがタイムアウトしました - リトライします...")
                    } else {
                        print("   ⚠️ リクエストがタイムアウトしました")
                    }
                case .cannotFindHost:
                    print("   ⚠️ ホストが見つかりません (\(baseURL))")
                    print("      - URLが正しいか確認してください")
                    // ホストが見つからないエラーはリトライしない
                    return false
                default:
                    if shouldRetry {
                        print("   ⚠️ その他のネットワークエラー: \(urlError.localizedDescription) - リトライします...")
                    } else {
                        print("   ⚠️ その他のネットワークエラー: \(urlError.localizedDescription)")
                    }
                }
                
                // リトライ可能な場合は待機して再試行
                if shouldRetry {
                    let delay = retryDelays[attempt - 1]
                    print("   ⏳ \(delay)秒待機してからリトライします...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch {
                if attempt == 0 {
                    print("❌ サーバー接続テスト失敗: \(error.localizedDescription)")
                    print("   - エラータイプ: \(type(of: error))")
                }
                // その他のエラーはリトライしない
                return false
            }
        }
        
        return false
    }
    
    /// バックエンドでユーザーを取得または作成（初回ログイン時は自動作成＋300クレジット付与）
    private func registerUserToSupabase(userInfo: UserInfo) async throws {
        var baseURL = APIConfig.shared.baseURL
        
        // まずサーバーへの接続をテスト
        print("🔍 バックエンドサーバーへの接続をテスト中...")
        var isServerReachable = await testServerConnection(baseURL: baseURL)
        
        // iOS Simulatorの場合、接続に失敗したらlocalhostを試す
        #if targetEnvironment(simulator)
        if !isServerReachable && baseURL.contains("192.168.") {
            let localhostURL = baseURL.replacingOccurrences(of: "192.168.3.92", with: "localhost")
            print("⚠️ 接続失敗。iOS Simulatorの場合、localhostを試します: \(localhostURL)")
            isServerReachable = await testServerConnection(baseURL: localhostURL)
            if isServerReachable {
                baseURL = localhostURL
                print("✅ localhostでの接続に成功しました")
            }
        }
        #endif
        
        if !isServerReachable {
            let errorMessage = "バックエンドサーバーに接続できません"
            print("⚠️ \(errorMessage)")
            print("   確認事項:")
            print("   1. バックエンドサーバーが起動しているか確認してください")
            print("   2. URLが正しいか確認してください: \(baseURL)")
            print("   3. iOSデバイスとバックエンドサーバーが同じネットワークに接続されているか確認してください")
            print("   4. iOS Simulatorの場合、localhost または 127.0.0.1 を使用してください")
            throw NSError(domain: "NetworkError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        guard let url = URL(string: "\(baseURL)/auth0/me") else {
            print("❌ ユーザー情報取得URLエラー")
            throw NSError(domain: "URLError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "無効なURLです"
            ])
        }
        
        // アクセストークンを取得
        guard let accessToken = tokenManager.getToken(type: .accessToken) else {
            print("❌ アクセストークンが取得できません")
            throw NSError(domain: "AuthError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "アクセストークンが取得できません"
            ])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0 // 10秒でタイムアウト
        
        print("📤 GET /auth0/me リクエスト送信")
        print("   URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 ユーザー情報取得レスポンス: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 レスポンスボディ: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ ユーザー情報取得成功（初回ログインの場合は自動的にユーザー作成＋300クレジット付与）")
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    print("❌ ユーザー情報取得エラー: \(httpResponse.statusCode) - \(errorMessage)")
                    // エラーをスローして呼び出し元で処理できるようにする
                    throw NSError(domain: "AuthError", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "ユーザー情報取得エラー: \(errorMessage)"
                    ])
                }
            } else {
                print("❌ 無効なレスポンス")
            }
        } catch let urlError as URLError {
            // URLエラーの詳細をログ出力
            print("❌ ユーザー情報取得通信エラー:")
            print("   - エラータイプ: \(urlError.localizedDescription)")
            print("   - エラーコード: \(urlError.code.rawValue)")
            print("   - URL: \(urlError.failingURL?.absoluteString ?? url.absoluteString)")
            
            // エラーの種類に応じた詳細メッセージ
            switch urlError.code {
            case .notConnectedToInternet:
                print("   ⚠️ インターネット接続がありません。ネットワーク設定を確認してください。")
            case .cannotConnectToHost:
                print("   ⚠️ サーバーに接続できません (\(baseURL))。バックエンドサーバーが起動しているか確認してください。")
            case .timedOut:
                print("   ⚠️ リクエストがタイムアウトしました。")
            case .cannotFindHost:
                print("   ⚠️ ホストが見つかりません (\(baseURL))。URLが正しいか確認してください。")
            default:
                print("   ⚠️ その他のネットワークエラー: \(urlError.localizedDescription)")
            }
            // エラーを再スローして呼び出し元で処理できるようにする
            throw urlError
        } catch {
            print("❌ ユーザー情報取得通信エラー: \(error.localizedDescription)")
            print("   - エラータイプ: \(type(of: error))")
            // エラーを再スローして呼び出し元で処理できるようにする
            throw error
        }
    }
    
    /// 認証状態をクリア
    private func clearAuthState() {
        isLoggedIn = false
        errorMessage = nil
        tokenManager.clearAllTokens()
    }
}
