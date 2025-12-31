import Foundation
import Combine
import SwiftUI

// MARK: - API エラー定義

enum StorybookAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    case storybookNotFound
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        case .storybookNotFound:
            return "絵本が見つかりません"
        case .invalidResponse:
            return "無効なレスポンスです"
        }
    }
}

// MARK: - 絵本データ取得サービス

public class StorybookService: ObservableObject {
    private let baseURL = APIConfig.shared.baseURL
    public static let shared = StorybookService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 認証トークン管理
    private let authManager = AuthManager.shared
    
    // MARK: - 初期化
    public init() {}
    
    // MARK: - 認証状態の同期（後方互換性のため残す）
    func syncAuthState(with authManager: AuthManager) {
        // 初期化時にAuthManagerを設定するため、このメソッドは不要
        print("⚠️ syncAuthStateは非推奨です。初期化時にAuthManagerを渡してください")
    }
    
    /// 認証トークンを設定（外部から）
    func setAuthToken(_ token: String?) {
        // authManager.setAccessToken(token) // AuthManagerにsetAccessTokenがないためコメントアウト
        print("✅ StorybookService: AuthManager経由でトークンを設定しました")
    }
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return authManager.getCurrentUserId()
    }
    
    // MARK: - 認証トークン管理メソッド（AuthManagerを使用）
    
    /// アクセストークンを設定
    func setAccessToken(_ token: String?) {
        // AuthManagerを使用するため、このメソッドは非推奨
        print("⚠️ setAccessTokenは非推奨です。AuthManagerを使用してください")
    }
    
    /// 現在のアクセストークンを取得
    func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    /// 認証状態を確認
    func isAuthenticated() -> Bool {
        return authManager.verifyAuthState()
    }
    
    // MARK: - 認証エラー処理
    
    /// 認証エラー時の自動ログアウト処理
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 StorybookService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                
                // AuthManager経由でログアウト
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    /// リクエスト前の認証状態チェック
    private func checkAuthBeforeRequest() throws {
        // getAccessTokenがnilを返すため、一時的にチェックを緩和するか、TokenManagerを直接使用する
        // ここではAuthManagerのverifyAuthStateを使用
        if !authManager.verifyAuthState() {
             print("❌ StorybookService: 認証されていません")
             throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        print("✅ StorybookService: 認証状態OK")
    }
    
    func fetchStorybook(storybookId: Int) async throws -> StorybookResponse {
        guard let url = URL(string: "\(baseURL)/api/storybook/\(storybookId)") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Fetching storybook from: \(url)")
        // ログインしていなくてもプレビューが見れるように認証チェックを削除
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // 認証トークンがあれば設定するが、なくてもリクエストを送信
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ fetchStorybook: 認証トークンを設定しました")
        } else {
            print("ℹ️ fetchStorybook: 認証トークンなしでリクエストを送信します")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break
                case 404:
                    throw StorybookAPIError.storybookNotFound
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    handleAuthError(error)
                    throw error
                default:
                    throw StorybookAPIError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
                        
            let decoder = JSONDecoder()
            let storybookResponse: StorybookResponse = try decoder.decode(StorybookResponse.self, from: data)
            
            print("✅ Storybook data received successfully")
            print("📖 Title: \(storybookResponse.title)")
            print("📄 Pages with content: \(([storybookResponse.page1, storybookResponse.page2, storybookResponse.page3, storybookResponse.page4, storybookResponse.page5] as [String]).filter { !$0.isEmpty }.count)")
            print("🖼️ Image URLs: cover=\(storybookResponse.coverImageUrl != nil ? "✅" : "❌"), page1=\(storybookResponse.page1ImageUrl != nil ? "✅" : "❌"), page2=\(storybookResponse.page2ImageUrl != nil ? "✅" : "❌"), page3=\(storybookResponse.page3ImageUrl != nil ? "✅" : "❌"), page4=\(storybookResponse.page4ImageUrl != nil ? "✅" : "❌"), page5=\(storybookResponse.page5ImageUrl != nil ? "✅" : "❌")")
            print("📊 Image generation status: \(storybookResponse.imageGenerationStatus)")
            
            return storybookResponse
            
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
    
    // デコーディングエラーの詳細ログ出力
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
    
    // 画像生成状態の判定
    func isGeneratingImages(_ storybook: StorybookResponse) -> Bool {
        return storybook.imageGenerationStatus == "generating" || storybook.imageGenerationStatus == "pending"
    }
    
    // 生成状態に応じたメッセージを取得
    func getGenerationMessage(_ status: String) -> String {
        switch status {
        case "pending":
            return "絵本の準備中..."
        case "generating":
            return "絵本の絵を描いています..."
        case "completed":
            return "絵本が完成しました！"
        case "failed":
            return "絵本の生成に失敗しました"
        default:
            return "処理中..."
        }
    }
}

// MARK: - 進捗情報の構造体

struct GenerationProgress: Codable {
    let storybookId: Int
    let currentPage: Int
    let totalPages: Int
    let progressPercent: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case storybookId = "storybook_id"
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case progressPercent = "progress_percent"
        case status
    }
}

// MARK: - 進捗取得機能

extension StorybookService {
    // 画像生成の進捗情報を取得
    func fetchGenerationProgress(storybookId: Int) async throws -> GenerationProgress {
        // ログインしていなくてもプレビューが見れるように認証チェックを削除
        // try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/api/storybook/\(storybookId)/generation-progress") else {
            throw StorybookAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンがあれば設定するが、なくてもリクエストを送信
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ fetchGenerationProgress: 認証トークンを設定しました")
        } else {
            print("ℹ️ fetchGenerationProgress: 認証トークンなしでリクエストを送信します")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            handleAuthError(error)
            throw error
        }
        
        // 受信した生JSONをログ出力（デバッグ用）
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 fetchGenerationProgress response: \(jsonString)")
        }
        let decoder = JSONDecoder()
        return try decoder.decode(GenerationProgress.self, from: data)
    }
}


// MARK: - テーマ取得サービス

extension StorybookService {
    // 指定ユーザーの指定年月の作成日一覧を取得
    struct CreatedDaysResponse: Codable {
        let year: Int
        let month: Int
        let days: [Int]
    }
    
    func fetchCreatedDays(userId: String, year: Int, month: Int) async throws -> [Int] {
        try checkAuthBeforeRequest()
        var components = URLComponents(string: "\(baseURL)/api/storybook/user/\(userId)/created-days")!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month))
        ]
        guard let url = components.url else { throw StorybookAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw StorybookAPIError.serverError(code, msg)
        }
        let decoded = try JSONDecoder().decode(CreatedDaysResponse.self, from: data)
        return decoded.days
    }
    
    // APIレスポンス用の簡易ストーリー設定情報
    private struct StorySettingSummary: Codable {
        let id: Int
        let uploadImageId: Int
        let titleSuggestion: String
        let protagonistName: String
        let protagonistType: String
        let settingPlace: String
        let tone: String
        let targetAge: String
        let language: String
        let readingLevel: String
        let styleGuideline: String
        let createdAt: String
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case uploadImageId = "upload_image_id"
            case titleSuggestion = "title_suggestion"
            case protagonistName = "protagonist_name"
            case protagonistType = "protagonist_type"
            case settingPlace = "setting_place"
            case tone
            case targetAge = "target_age"
            case language
            case readingLevel = "reading_level"
            case styleGuideline = "style_guideline"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    // ユーザーの最新のstory_setting_idを取得
    func fetchLatestStorySettingId(userId: String) async throws -> Int {
        // 認証状態を事前チェック
        try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/api/story/story_settings") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔍 Fetching latest story setting for user: \(userId)")
        
        // 認証ヘッダーを追加
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを追加
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
                    
                    // 認証エラーの場合は自動ログアウト
                    handleAuthError(error)
                    
                    throw error
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response (story_settings):")
                print(jsonString)
            }
            
            // JSON配列として解析（型注釈を追加）
            let storySettings: [StorySettingSummary] = try JSONDecoder().decode([StorySettingSummary].self, from: data)
            
            guard !storySettings.isEmpty else {
                throw StorybookAPIError.storybookNotFound
            }
            
            // created_at で最新順にソートして最新のレコードを取得
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
    
    // テーマプロット一覧を取得
    func fetchThemePlots(userId: String, storySettingId: Int, limit: Int = 3) async throws -> ThemePlotsListResponse {
        // 認証状態を事前チェック
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
        
        // 認証ヘッダーを追加
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを追加
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
                    
                    // 認証エラーの場合は自動ログアウト
                    handleAuthError(error)
                    
                    throw error
                }
            }
            
            // レスポンスデータの詳細ログ
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
    
    // MARK: - テーマ選択フロー
    
    // テーマ選択フロー用のレスポンスモデル
    struct ThemeSelectionResponse: Codable {
        let storybookId: Int
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case storybookId = "storybook_id"
            case message
        }
    }
    
    struct StoryGenerationResponse: Codable {
        let storyPlotId: Int
        let storySettingId: Int
        let selectedTheme: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case storyPlotId = "story_plot_id"
            case storySettingId = "story_setting_id"
            case selectedTheme = "selected_theme"
            case message
        }
    }
    
    struct ImageGenerationResponse: Codable {
        let message: String
        let generatedImages: [String]
        
        enum CodingKeys: String, CodingKey {
            case message
            case generatedImages = "generated_images"
        }
        
        init(message: String, generatedImages: [String]) {
            self.message = message
            self.generatedImages = generatedImages
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
            self.generatedImages = try container.decodeIfPresent([String].self, forKey: .generatedImages) ?? []
        }
    }
    
    struct ImageUrlUpdateResponse: Codable {
        let message: String
        let updatedPages: [String]
        // デコードの互換性確保のために件数も保持（配列/数値どちらにも対応）
        let updatedPagesCount: Int
        
        enum CodingKeys: String, CodingKey {
            case message
            case updatedPages = "updated_pages"
        }
        
        // 明示的なイニシャライザ（テスト等で利用）
        init(message: String, updatedPages: [String]) {
            self.message = message
            self.updatedPages = updatedPages
            self.updatedPagesCount = updatedPages.count
        }
        
        // バックエンドが updated_pages を配列（推奨）または数値（後方互換）で返すケースに対応
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
            if let pagesArray = try? container.decode([String].self, forKey: .updatedPages) {
                self.updatedPages = pagesArray
                self.updatedPagesCount = pagesArray.count
            } else if let pagesInt = try? container.decode(Int.self, forKey: .updatedPages) {
                self.updatedPages = []
                self.updatedPagesCount = max(0, pagesInt)
            } else {
                self.updatedPages = []
                self.updatedPagesCount = 0
            }
        }
    }
    
    // ステップ1: 物語生成
    func generateStory(storySettingId: Int, selectedTheme: String, storyPages: Int) async throws -> StoryGenerationResponse {
        // 認証状態を事前チェック
        try checkAuthBeforeRequest()
        
        let requestURLString = "\(baseURL)/api/story/select_theme"
        print("🔗 Request URL: \(requestURLString)")
        print("🔗 baseURL: \(baseURL)")
        
        guard let url = URL(string: requestURLString) else {
            print("❌ Invalid URL: \(requestURLString)")
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Generating story from theme: storySettingId=\(storySettingId), selectedTheme=\(selectedTheme), storyPages=\(storyPages)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        let requestBody: [String: Any] = [
            "story_setting_id": storySettingId,
            "selected_theme": selectedTheme,
            "story_pages": storyPages
        ]
        
        // リクエストボディのデバッグ出力
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request body: \(jsonString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        // レスポンスのデバッグ出力
        print("📥 Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            
            // 認証エラーの場合は自動ログアウト
            handleAuthError(error)
            
            print("❌ Server error: \(httpResponse.statusCode) - \(errorMessage)")
            throw error
        }
        
        let decoder = JSONDecoder()
        let storyResponse = try decoder.decode(StoryGenerationResponse.self, from: data)
        
        print("✅ Story generated successfully: storyPlotId=\(storyResponse.storyPlotId)")
        return storyResponse
    }
    
    // ステップ2: ストーリーブック作成
    func createStorybook(storyPlotId: Int, selectedTheme: String, childId: Int, storyPages: Int) async throws -> ThemeSelectionResponse {
        let requestURLString = "\(baseURL)/api/storybook/confirm-theme-and-create"
        print("🔗 Request URL: \(requestURLString)")
        
        guard let url = URL(string: requestURLString) else {
            print("❌ Invalid URL: \(requestURLString)")
            throw StorybookAPIError.invalidURL
        }
        
        // childIdが0の場合はnilとして扱う（子供未登録の場合）
        let actualChildId: Int? = childId == 0 ? nil : childId
        
        print("📖 Creating storybook from plot: storyPlotId=\(storyPlotId), selectedTheme=\(selectedTheme), childId=\(actualChildId?.description ?? "nil"), storyPages=\(storyPages)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        // child_idがnilの場合はnullを送信、それ以外は値を送信
        var requestBody: [String: Any] = [
            "story_plot_id": storyPlotId,
            "selected_theme": selectedTheme,
            "story_pages": storyPages
        ]
        if let childId = actualChildId {
            requestBody["child_id"] = childId
        } else {
            requestBody["child_id"] = NSNull()
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let storybookResponse = try decoder.decode(ThemeSelectionResponse.self, from: data)
        
        print("✅ Storybook created successfully: storybookId=\(storybookResponse.storybookId)")
        return storybookResponse
    }
    
    // ステップ3: 画像生成
    func generateStoryImages(storybookId: Int) async throws -> ImageGenerationResponse {
        guard let url = URL(string: "\(baseURL)/api/images/generation/generate-storyplot-all-pages-image-to-image") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🎨 Generating images for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを設定
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "storybook_id": storybookId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let imageResponse = try decoder.decode(ImageGenerationResponse.self, from: data)
        
        print("✅ Images generated successfully: \(imageResponse.generatedImages.count) images")
        return imageResponse
    }
    
    // ステップ4: 画像URL更新
    func updateImageUrls(storybookId: Int) async throws -> ImageUrlUpdateResponse {
        guard let url = URL(string: "\(baseURL)/api/storybook/update-image-urls") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔄 Updating image URLs for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        let requestBody = [
            "storybook_id": storybookId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let updateResponse = try decoder.decode(ImageUrlUpdateResponse.self, from: data)
        
        print("✅ Image URLs updated successfully: \(updateResponse.updatedPagesCount) pages")
        return updateResponse
    }
    
    // テーマ選択フロー全体を実行（非推奨: childIdとstoryPagesが必要）
    func executeThemeSelectionFlow(storySettingId: Int, storyPlotId: Int, selectedTheme: String, childId: Int, storyPages: Int) async throws -> Int {
        print("🚀 Starting theme selection flow: storySettingId=\(storySettingId), storyPlotId=\(storyPlotId), selectedTheme=\(selectedTheme), childId=\(childId), storyPages=\(storyPages)")
        
        var generatedStoryPlotId: Int?
        var storybookId: Int?
        
        do {
            // ステップ1: 物語生成
            print("📝 Step 1: Generating story...")
            let storyResponse = try await generateStory(storySettingId: storySettingId, selectedTheme: selectedTheme, storyPages: storyPages)
            generatedStoryPlotId = storyResponse.storyPlotId
            
            // ステップ2: ストーリーブック作成
            print("📖 Step 2: Creating storybook...")
            let storybookResponse = try await createStorybook(storyPlotId: storyResponse.storyPlotId, selectedTheme: storyResponse.selectedTheme, childId: childId, storyPages: storyPages)
            storybookId = storybookResponse.storybookId
            
            // ステップ3: 画像生成はフロント側のポーリングに委ねるため、ここではキックだけ行い即返す
            // バックグラウンドで画像生成→URL更新を行うが、UIの進捗アニメーションをブロックしない
            print("🎨 Step 3: Generating images (kick only, no wait)...")
            Task.detached(priority: .background) { [weak self] in
                guard let self else { return }
                do {
                    _ = try await self.generateStoryImages(storybookId: storybookResponse.storybookId)
                    _ = try await self.updateImageUrls(storybookId: storybookResponse.storybookId)
                } catch {
                    print("⚠️ Image generation (fire-and-forget) failed: \(error)")
                }
            }
            
            print("✅ Theme selection flow completed successfully (images are generating): storybookId=\(storybookResponse.storybookId)")
            return storybookResponse.storybookId
            
        } catch {
            print("❌ Theme selection flow failed: \(error)")
            
            // ロールバック処理
            await rollbackThemeSelectionFlow(storyPlotId: generatedStoryPlotId, storybookId: storybookId)
            
            throw error
        }
    }
    
    // ロールバック処理
    private func rollbackThemeSelectionFlow(storyPlotId: Int?, storybookId: Int?) async {
        print("🔄 Starting rollback process...")
        
        // 注意: 実際のロールバック処理は、バックエンドAPIで
        // 適切なロールバック機能が実装されている場合にのみ有効
        // 現在はログ出力のみ
        
        if let storybookId = storybookId {
            print("🗑️ Rollback: Storybook \(storybookId) should be deleted")
        }
        
        if let storyPlotId = storyPlotId {
            print("🗑️ Rollback: Story plot \(storyPlotId) should be deleted")
        }
        
        print("🔄 Rollback process completed")
    }

    // MARK: - 週間統計取得
    func fetchWeeklyStats(userId: String) async throws -> WeeklyStatsResponse {
        try checkAuthBeforeRequest()
        guard let url = URL(string: "\(baseURL)/api/story/users/\(userId)/weekly_stats") else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            // デバッグ用: 実際のレスポンスJSONを出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 週間統計取得レスポンスJSON: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            // WeeklyStatsResponseはカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
            // keyDecodingStrategyを設定すると、CodingKeysとの競合が発生する可能性がある
            let result = try decoder.decode(WeeklyStatsResponse.self, from: data)
            print("✅ 週間統計取得成功: weekTotal=\(result.weekTotal)")
            return result
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ 週間統計取得失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - ユーザー情報取得
    func fetchUserInfo(userId: String) async throws -> UserInfoResponse {
        try checkAuthBeforeRequest()
        guard let url = URL(string: "\(baseURL)/api/users/\(userId)") else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            // デバッグ用: 実際のレスポンスJSONを出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 ユーザー情報取得レスポンスJSON: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            // UserInfoResponseはカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
            // keyDecodingStrategyを設定すると、CodingKeysとの競合が発生する可能性がある
            let result = try decoder.decode(UserInfoResponse.self, from: data)
            print("✅ ユーザー情報取得成功: userName=\(result.userName)")
            return result
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ ユーザー情報取得失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - ユーザーの絵本一覧取得
    func fetchUserStorybooks(userId: String) async throws -> [StoryBookListItem] {
        try checkAuthBeforeRequest()
        guard let url = URL(string: "\(baseURL)/api/storybook/user/\(userId)") else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            // デバッグ用: 実際のレスポンスJSONを出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 絵本一覧取得レスポンスJSON（全体）: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            // StorybookResponseはカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
            // keyDecodingStrategyを設定すると、CodingKeysとの競合が発生する可能性がある
            
            // レスポンスは配列なので、そのままデコード
            let storybooks = try decoder.decode([StorybookResponse].self, from: data)
            
            // StorybookResponseからStoryBookListItemに変換
            let items = storybooks.map { storybook -> StoryBookListItem in
                return StoryBookListItem(
                    id: storybook.id,
                    storyPlotId: storybook.storyPlotId,
                    userId: storybook.userId,
                    childId: storybook.childId,
                    title: storybook.title,
                    coverImageUrl: storybook.coverImageUrl,
                    createdAt: storybook.createdAt,
                    isFavorite: storybook.isFavorite ?? false  // デフォルト値（APIから取得できない場合）
                )
            }
            
            print("✅ 絵本一覧取得成功: count=\(items.count)")
            return items
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ 絵本一覧取得失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - 月別絵本一覧取得
    func fetchUserStorybooksByMonth(userId: String, year: Int, month: Int) async throws -> [StoryBookListItem] {
        try checkAuthBeforeRequest()
        var components = URLComponents(string: "\(baseURL)/api/storybook/user/\(userId)")!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month))
        ]
        guard let url = components.url else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            // デバッグ用: 実際のレスポンスJSONを出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 月別絵本一覧取得レスポンスJSON: \(jsonString.prefix(500))")
            }
            
            let decoder = JSONDecoder()
            // StorybookResponseはカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
            // keyDecodingStrategyを設定すると、CodingKeysとの競合が発生する可能性がある
            
            let storybooks = try decoder.decode([StorybookResponse].self, from: data)
            
            let items = storybooks.map { storybook -> StoryBookListItem in
                return StoryBookListItem(
                    id: storybook.id,
                    storyPlotId: storybook.storyPlotId,
                    userId: storybook.userId,
                    childId: storybook.childId,
                    title: storybook.title,
                    coverImageUrl: storybook.coverImageUrl,
                    createdAt: storybook.createdAt,
                    isFavorite: storybook.isFavorite ?? false
                )
            }
            
            print("✅ 月別絵本一覧取得成功: year=\(year), month=\(month), count=\(items.count)")
            return items
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ 月別絵本一覧取得失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - 日別絵本一覧取得
    func fetchUserStorybooksByDate(userId: String, year: Int, month: Int, day: Int) async throws -> [StoryBookListItem] {
        try checkAuthBeforeRequest()
        var components = URLComponents(string: "\(baseURL)/api/storybook/user/\(userId)")!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "month", value: String(month)),
            URLQueryItem(name: "day", value: String(day))
        ]
        guard let url = components.url else {
            throw StorybookAPIError.invalidURL
        }
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            // デバッグ用: レスポンスの内容を確認
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 日別絵本一覧取得レスポンスJSON: \(jsonString.prefix(500))")
            }
            
            let decoder = JSONDecoder()
            // StorybookResponseはカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
            // keyDecodingStrategyを設定すると、CodingKeysとの競合が発生する可能性がある
            
            // JSONの構造を確認して、辞書か配列かを判断
            var storybooks: [StorybookResponse]
            var folderCount: Int?
            
            // JSONオブジェクトをパースして構造を確認
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // 辞書形式の場合（日別フィルタリング）
                if jsonObject.keys.contains("books") && jsonObject.keys.contains("folder_count") {
                    // 新しいレスポンス形式（辞書）
                    // StoryBookListByDateResponseもカスタムCodingKeysを使用するため、keyDecodingStrategyは設定しない
                    let dateResponse = try decoder.decode(StoryBookListByDateResponse.self, from: data)
                    storybooks = dateResponse.books
                    folderCount = dateResponse.folderCount
                    print("✅ 辞書形式のレスポンスをデコード成功: books=\(storybooks.count), folder_count=\(folderCount ?? 0)")
                } else {
                    // 予期しない辞書形式の場合はエラー
                    throw StorybookAPIError.invalidResponse
                }
            } else if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                // 配列形式の場合（従来の形式）
                storybooks = try decoder.decode([StorybookResponse].self, from: data)
                print("✅ 配列形式のレスポンスをデコード成功: count=\(storybooks.count)")
            } else {
                // どちらでもない場合はエラー
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ 予期しないJSON形式: \(jsonString.prefix(200))")
                }
                throw StorybookAPIError.invalidResponse
            }
            
            let items = storybooks.map { storybook -> StoryBookListItem in
                return StoryBookListItem(
                    id: storybook.id,
                    storyPlotId: storybook.storyPlotId,
                    userId: storybook.userId,
                    childId: storybook.childId,
                    title: storybook.title,
                    coverImageUrl: storybook.coverImageUrl,
                    createdAt: storybook.createdAt,
                    isFavorite: storybook.isFavorite ?? false
                )
            }
            
            // フォルダ数もログに出力
            if let folderCount = folderCount {
                print("✅ 日別絵本一覧取得成功: year=\(year), month=\(month), day=\(day), count=\(items.count), folder_count=\(folderCount)")
            } else {
                print("✅ 日別絵本一覧取得成功: year=\(year), month=\(month), day=\(day), count=\(items.count)")
            }
            return items
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ 日別絵本一覧取得失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - アカウント管理
    func deleteCurrentAccount() async throws -> AccountDeletionResponseDTO {
        try checkAuthBeforeRequest()
        guard let url = URL(string: "\(baseURL)/auth0/me") else {
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
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(AccountDeletionResponseDTO.self, from: data)
            print("✅ Account deletion succeeded for user: \(result.userId)")
            return result
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ Account deletion failed: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - 物語設定削除
    /// story_settingを削除する（紐づく画像とGCS上のファイルも削除される）
    /// - Parameter storySettingId: 削除する物語設定ID
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
    
    // MARK: - お気に入り状態更新
    /// ストーリーブックのお気に入り状態を更新する
    /// - Parameters:
    ///   - storybookId: ストーリーブックID
    ///   - isFavorite: お気に入り状態
    func updateFavoriteStatus(storybookId: Int, isFavorite: Bool) async throws {
        try checkAuthBeforeRequest()
        
        var components = URLComponents(string: "\(baseURL)/api/storybook/\(storybookId)/favorite")!
        components.queryItems = [
            URLQueryItem(name: "is_favorite", value: String(isFavorite))
        ]
        
        guard let url = components.url else {
            throw StorybookAPIError.invalidURL
        }
        
        guard let token = getAccessToken() else {
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
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
            
            print("✅ お気に入り状態更新成功: storybookId=\(storybookId), isFavorite=\(isFavorite)")
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ お気に入り状態更新失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
}
