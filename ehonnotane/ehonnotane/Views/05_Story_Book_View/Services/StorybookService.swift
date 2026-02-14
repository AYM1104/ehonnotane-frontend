import Foundation
import Combine
import SwiftUI

// MARK: - 絵本データ取得サービス（ファサード）

/// StorybookService は後方互換性のためファサードとして機能します。
/// 内部的に各専門サービスに処理を委譲します。
public class StorybookService: ObservableObject {
    private let baseURL = APIConfig.shared.baseURL
    public static let shared = StorybookService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 依存サービス
    private let authManager = AuthManager.shared
    private let listService = StorybookListService.shared
    private let themePlotService = ThemePlotService.shared
    private let storyGenerationService = StoryGenerationService.shared
    
    // MARK: - 初期化
    public init() {}
    
    // MARK: - 認証状態管理（後方互換性のため残す）
    
    func syncAuthState(with authManager: AuthManager) {
        print("⚠️ syncAuthStateは非推奨です。初期化時にAuthManagerを渡してください")
    }
    
    func setAuthToken(_ token: String?) {
        print("✅ StorybookService: AuthManager経由でトークンを設定しました")
    }
    
    func getCurrentUserId() -> String? {
        return authManager.getCurrentUserId()
    }
    
    func setAccessToken(_ token: String?) {
        print("⚠️ setAccessTokenは非推奨です。AuthManagerを使用してください")
    }
    
    func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    func isAuthenticated() -> Bool {
        return authManager.verifyAuthState()
    }
    
    // MARK: - 認証エラー処理
    
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 StorybookService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    private func checkAuthBeforeRequest() throws {
        if !authManager.verifyAuthState() {
             print("❌ StorybookService: 認証されていません")
             throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        print("✅ StorybookService: 認証状態OK")
    }
    
    // MARK: - デコーディングエラーの詳細ログ出力
    
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
    
    // MARK: - 絵本取得（直接実装）
    
    func fetchStorybook(storybookId: Int) async throws -> StorybookResponse {
        guard let url = URL(string: "\(baseURL)/api/storybook/\(storybookId)") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Fetching storybook from: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
                        
            let decoder = JSONDecoder()
            let storybookResponse: StorybookResponse = try decoder.decode(StorybookResponse.self, from: data)
            
            print("✅ Storybook data received successfully")
            print("📖 Title: \(storybookResponse.title)")
            print("📄 Pages with content: \(storybookResponse.pages?.count ?? 0)")
            print("🖼️ Image URLs: cover=\(storybookResponse.coverImageUrl != nil ? "✅" : "❌"), pages with images=\(storybookResponse.pages?.filter { $0.imageUrl != nil }.count ?? 0)")
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
    
    // MARK: - 画像生成状態の判定
    
    func isGeneratingImages(_ storybook: StorybookResponse) -> Bool {
        return storybook.imageGenerationStatus == "generating" || storybook.imageGenerationStatus == "pending"
    }
    
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
    
    // MARK: - 進捗取得（直接実装）
    
    func fetchGenerationProgress(storybookId: Int) async throws -> GenerationProgress {
        guard let url = URL(string: "\(baseURL)/api/storybook/\(storybookId)/generation-progress") else {
            throw StorybookAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
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
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 fetchGenerationProgress response: \(jsonString)")
        }
        let decoder = JSONDecoder()
        return try decoder.decode(GenerationProgress.self, from: data)
    }
    
    // MARK: - 委譲メソッド（後方互換性）
    
    // StorybookListService への委譲
    func fetchCreatedDays(userId: String, year: Int, month: Int) async throws -> [Int] {
        return try await listService.fetchCreatedDays(userId: userId, year: year, month: month)
    }
    
    func fetchUserStorybooks(userId: String) async throws -> [StoryBookListItem] {
        return try await listService.fetchUserStorybooks(userId: userId)
    }
    
    func fetchUserStorybooksByMonth(userId: String, year: Int, month: Int) async throws -> [StoryBookListItem] {
        return try await listService.fetchUserStorybooksByMonth(userId: userId, year: year, month: month)
    }
    
    func fetchUserStorybooksByDate(userId: String, year: Int, month: Int, day: Int) async throws -> [StoryBookListItem] {
        return try await listService.fetchUserStorybooksByDate(userId: userId, year: year, month: month, day: day)
    }
    
    func updateFavoriteStatus(storybookId: Int, isFavorite: Bool) async throws {
        try await listService.updateFavoriteStatus(storybookId: storybookId, isFavorite: isFavorite)
    }
    
    func deleteStorybook(storybookId: Int) async throws {
        try await listService.deleteStorybook(storybookId: storybookId)
    }
    
    // ThemePlotService への委譲
    func fetchLatestStorySettingId(userId: String) async throws -> Int {
        return try await themePlotService.fetchLatestStorySettingId(userId: userId)
    }
    
    func fetchThemePlots(userId: String, storySettingId: Int, limit: Int = 3) async throws -> ThemePlotsListResponse {
        return try await themePlotService.fetchThemePlots(userId: userId, storySettingId: storySettingId, limit: limit)
    }
    
    func deleteStorySetting(storySettingId: Int) async throws {
        try await themePlotService.deleteStorySetting(storySettingId: storySettingId)
    }
    
    // StoryGenerationService への委譲
    func generateStory(storySettingId: Int, selectedTheme: String, storyPages: Int) async throws -> StoryGenerationResponse {
        return try await storyGenerationService.generateStory(storySettingId: storySettingId, selectedTheme: selectedTheme, storyPages: storyPages)
    }
    
    func createStorybook(storyPlotId: Int, selectedTheme: String, childId: Int, storyPages: Int) async throws -> ThemeSelectionResponse {
        return try await storyGenerationService.createStorybook(storyPlotId: storyPlotId, selectedTheme: selectedTheme, childId: childId, storyPages: storyPages)
    }
    
    func generateStoryImages(storybookId: Int) async throws -> ImageGenerationResponse {
        return try await storyGenerationService.generateStoryImages(storybookId: storybookId)
    }
    
    func updateImageUrls(storybookId: Int) async throws -> ImageUrlUpdateResponse {
        return try await storyGenerationService.updateImageUrls(storybookId: storybookId)
    }
    
    func executeThemeSelectionFlow(storySettingId: Int, storyPlotId: Int, selectedTheme: String, childId: Int, storyPages: Int) async throws -> Int {
        return try await storyGenerationService.executeThemeSelectionFlow(storySettingId: storySettingId, storyPlotId: storyPlotId, selectedTheme: selectedTheme, childId: childId, storyPages: storyPages)
    }
}
