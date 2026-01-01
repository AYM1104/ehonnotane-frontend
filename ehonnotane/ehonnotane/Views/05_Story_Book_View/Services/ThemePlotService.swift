import Foundation

// MARK: - テーマ・プロット取得サービス

/// テーマプロットの取得と物語設定の管理を担当するサービス
public class ThemePlotService {
    private let baseURL = APIConfig.shared.baseURL
    public static let shared = ThemePlotService()
    
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - 認証ヘルパー
    
    private func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 ThemePlotService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    private func checkAuthBeforeRequest() throws {
        if !authManager.verifyAuthState() {
            print("❌ ThemePlotService: 認証されていません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        print("✅ ThemePlotService: 認証状態OK")
    }
    
    private func handleDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("🔍 Type mismatch: expected \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .valueNotFound(let type, let context):
            print("🔍 Value not found: \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .keyNotFound(let key, let context):
            print("🔍 Key not found: \(key.stringValue)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .dataCorrupted(let context):
            print("🔍 Data corrupted: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        @unknown default:
            print("🔍 Unknown decoding error")
        }
    }
    
    // MARK: - 最新のstory_setting_id取得
    
    func fetchLatestStorySettingId(userId: String) async throws -> Int {
        try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/api/story/story_settings") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔍 Fetching latest story setting for user: \(userId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    handleAuthError(error)
                    throw error
                }
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response (story_settings):")
                print(jsonString)
            }
            
            let storySettings: [StorySettingSummary] = try JSONDecoder().decode([StorySettingSummary].self, from: data)
            
            guard !storySettings.isEmpty else {
                throw StorybookAPIError.storybookNotFound
            }
            
            let isoFormatter = ISO8601DateFormatter()
            let latestSetting = storySettings
                .sorted {
                    guard
                        let lhs = isoFormatter.date(from: $0.createdAt),
                        let rhs = isoFormatter.date(from: $1.createdAt)
                    else {
                        return $0.createdAt > $1.createdAt
                    }
                    return lhs > rhs
                }
                .first!
            
            print("✅ Latest story setting ID: \(latestSetting.id)")
            return latestSetting.id
            
        } catch let error as StorybookAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error (story settings): \(decodingError)")
            handleDecodingError(decodingError)
            throw StorybookAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - テーマプロット一覧取得
    
    func fetchThemePlots(userId: String, storySettingId: Int, limit: Int = 3) async throws -> ThemePlotsListResponse {
        try checkAuthBeforeRequest()
        
        var components = URLComponents(string: "\(baseURL)/api/story/story_plots")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "story_setting_id", value: String(storySettingId)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🎨 Fetching theme plots from: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    handleAuthError(error)
                    throw error
                }
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            let decoder = JSONDecoder()
            let themePlotsResponse: ThemePlotsListResponse = try decoder.decode(ThemePlotsListResponse.self, from: data)
            
            print("✅ Theme plots data received successfully")
            print("🎨 Count: \(themePlotsResponse.count)")
            print("📝 Items: \(themePlotsResponse.items.map { $0.title })")
            
            return themePlotsResponse
            
        } catch let error as StorybookAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            handleDecodingError(decodingError)
            throw StorybookAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - 物語設定削除
    
    /// story_settingを削除する（紐づく画像とGCS上のファイルも削除される）
    func deleteStorySetting(storySettingId: Int) async throws {
        try checkAuthBeforeRequest()
        guard let url = URL(string: "\(baseURL)/api/story/story_settings/\(storySettingId)") else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StorybookAPIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                handleAuthError(StorybookAPIError.serverError(401, "認証エラー"))
                throw StorybookAPIError.serverError(401, "認証エラー")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            print("✅ story_setting削除成功: storySettingId=\(storySettingId)")
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ story_setting削除失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
}
