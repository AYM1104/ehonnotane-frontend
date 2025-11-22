import Foundation

/// 物語設定作成サービス
class StorySettingService {
    
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
        print("🔧 StorySettingService初期化: baseURL = \(baseURL)")
    }
    
    // MARK: - 認証トークン管理
    
    /// 現在のアクセストークンを取得
    private func getAccessToken() -> String? {
        return authProvider.getAccessToken()
    }
    
    // MARK: - 物語設定作成
    
    /// 画像IDから物語設定を作成する
    func createStorySettingFromImage(imageId: Int) async throws -> (story_setting_id: Int, generated_data_jsonString: String?) {
        var request = makeRequest(path: "/api/story/story_settings/\(imageId)", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, httpResponse) = try await performDataTask(for: request)
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "StorySettingCreate", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: body])
        }
        
        let decoded = try JSONDecoder().decode(StorySettingCreateResponse.self, from: data)
        var jsonString: String? = nil
        if let gen = decoded.generated_data, let encoded = try? JSONEncoder().encode(gen) {
            jsonString = String(data: encoded, encoding: .utf8)
        }
        return (decoded.story_setting_id, jsonString)
    }
    
    /// 物語設定を更新する（子供IDとページ数）
    func updateStorySetting(id: Int, childId: Int?, pageCount: Int?) async throws {
        var request = makeRequest(path: "/api/story/story_settings/\(id)", method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = [:]
        if let childId = childId {
            body["child_id"] = childId
        }
        if let pageCount = pageCount {
            body["page_count"] = pageCount
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await performDataTask(for: request)
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "StorySettingUpdate", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorBody])
        }
        print("✅ 物語設定更新成功: ID=\(id)")
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

