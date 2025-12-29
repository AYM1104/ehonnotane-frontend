import Foundation

/// Story Setting削除サービス
/// バックエンドAPIを呼び出してstory_setting、関連レコード、GCSファイルを削除
class StorySettingCleanupService {
    
    // バックエンドAPIのベースURL
    private let baseURL: String
    private let urlSession: URLSession
    
    // MARK: - 認証管理
    private let authProvider: AuthProviding
    
    // MARK: - 初期化
    init(authProvider: AuthProviding = DefaultAuthProvider(), urlSession: URLSession = .shared) {
        self.authProvider = authProvider
        self.urlSession = urlSession
        // APIConfigからURLを取得
        self.baseURL = APIConfig.shared.baseURL
        print("🔧 StorySettingCleanupService初期化: baseURL = \(baseURL)")
    }
    
    // MARK: - 認証トークン管理
    
    /// 現在のアクセストークンを取得
    private func getAccessToken() -> String? {
        return authProvider.getAccessToken()
    }
    
    // MARK: - Story Setting削除
    
    /// story_settingと関連データ（story_plots、upload_image、GCSファイル）を削除
    /// - Parameter storySettingId: 削除するstory_setting ID
    /// - Returns: 削除成功の場合true
    func deleteStorySetting(storySettingId: Int) async throws -> Bool {
        print("🗑️ Story Setting削除開始: ID=\(storySettingId)")
        
        var request = makeRequest(path: "/api/story/story_settings/\(storySettingId)", method: "DELETE")
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, httpResponse) = try await performDataTask(for: request)
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ Story Setting削除失敗: ステータスコード=\(httpResponse.statusCode), エラー=\(errorBody)")
            throw NSError(
                domain: "StorySettingCleanup",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "削除に失敗しました: \(errorBody)"]
            )
        }
        
        // レスポンスボディをパース（オプション）
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Story Setting削除成功: \(responseString)")
        }
        
        return true
    }
    
    // MARK: - リクエスト共通処理
    
    /// ベースURLとの結合を共通化
    private func makeRequest(path: String, method: String = "GET") -> URLRequest {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }
    
    /// URLSession経由でリクエストを実行
    private func performDataTask(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 無効なHTTPレスポンス")
            throw NetworkError.invalidResponse
        }
        print("📥 HTTPステータスコード: \(httpResponse.statusCode)")
        return (data, httpResponse)
    }
}
