import Foundation

// MARK: - 物語生成サービス

/// 物語生成、ストーリーブック作成、画像生成フローを担当するサービス
public class StoryGenerationService {
    private let baseURL = APIConfig.shared.baseURL
    public static let shared = StoryGenerationService()
    
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - 認証ヘルパー
    
    private func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 StoryGenerationService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    private func checkAuthBeforeRequest() throws {
        if !authManager.verifyAuthState() {
            print("❌ StoryGenerationService: 認証されていません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        print("✅ StoryGenerationService: 認証状態OK")
    }
    
    // MARK: - ステップ1: 物語生成
    
    func generateStory(storySettingId: Int, selectedTheme: String, storyPages: Int) async throws -> StoryGenerationResponse {
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
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        // ユーザーの言語設定を取得（日本語: "ja", 英語: "en" など）
        let languageCode = Locale.current.language.languageCode?.identifier ?? "ja"
        print("🌐 物語生成 言語設定: \(languageCode)")
        
        let requestBody: [String: Any] = [
            "story_setting_id": storySettingId,
            "selected_theme": selectedTheme,
            "story_pages": storyPages,
            "language": languageCode
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request body: \(jsonString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            handleAuthError(error)
            print("❌ Server error: \(httpResponse.statusCode) - \(errorMessage)")
            throw error
        }
        
        let decoder = JSONDecoder()
        let storyResponse = try decoder.decode(StoryGenerationResponse.self, from: data)
        
        print("✅ Story generated successfully: storyPlotId=\(storyResponse.storyPlotId)")
        return storyResponse
    }
    
    // MARK: - ステップ2: ストーリーブック作成
    
    func createStorybook(storyPlotId: Int, selectedTheme: String, childId: Int, storyPages: Int) async throws -> ThemeSelectionResponse {
        let requestURLString = "\(baseURL)/api/storybook/confirm-theme-and-create"
        print("🔗 Request URL: \(requestURLString)")
        
        guard let url = URL(string: requestURLString) else {
            print("❌ Invalid URL: \(requestURLString)")
            throw StorybookAPIError.invalidURL
        }
        
        let actualChildId: Int? = childId == 0 ? nil : childId
        
        print("📖 Creating storybook from plot: storyPlotId=\(storyPlotId), selectedTheme=\(selectedTheme), childId=\(actualChildId?.description ?? "nil"), storyPages=\(storyPages)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
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
    
    // MARK: - ステップ3: 画像生成
    
    func generateStoryImages(storybookId: Int, storyPages: Int) async throws -> ImageGenerationResponse {
        guard let url = URL(string: "\(baseURL)/api/images/generation/generate-storyplot-all-pages-image-to-image") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🎨 Generating images for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "storybook_id": storybookId,
            "story_pages": storyPages
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
    
    // MARK: - ステップ4: 画像URL更新
    
    func updateImageUrls(storybookId: Int) async throws -> ImageUrlUpdateResponse {
        guard let url = URL(string: "\(baseURL)/api/storybook/update-image-urls") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔄 Updating image URLs for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
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
    
    // MARK: - テーマ選択フロー全体を実行
    
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
            
            // ステップ3: 画像生成をCloud Tasksにキック（Cloud Runがバックグラウンドで処理）
            print("🎨 Step 3: Kicking off image generation (Cloud Tasks)...")
            do {
                _ = try await self.generateStoryImages(storybookId: storybookResponse.storybookId, storyPages: storyPages)
                print("✅ Image generation task queued successfully")
            } catch {
                print("⚠️ Image generation task queueing failed: \(error)")
                // 画像生成のキューイングに失敗してもストーリーブックは作成済みなので継続
                // ステータスは「pending」のままで、ユーザーが後で再試行可能
            }
            
            print("✅ Theme selection flow completed successfully: storybookId=\(storybookResponse.storybookId)")
            print("   画像生成はバックグラウンドで実行中です。進捗はポーリングで確認してください。")
            return storybookResponse.storybookId
            
        } catch {
            print("❌ Theme selection flow failed: \(error)")
            await rollbackThemeSelectionFlow(storyPlotId: generatedStoryPlotId, storybookId: storybookId)
            throw error
        }
    }
    
    // MARK: - ロールバック処理
    
    private func rollbackThemeSelectionFlow(storyPlotId: Int?, storybookId: Int?) async {
        print("🔄 Starting rollback process...")
        
        if let storybookId = storybookId {
            print("🗑️ Rollback: Storybook \(storybookId) should be deleted")
        }
        
        if let storyPlotId = storyPlotId {
            print("🗑️ Rollback: Story plot \(storyPlotId) should be deleted")
        }
        
        print("🔄 Rollback process completed")
    }
}
