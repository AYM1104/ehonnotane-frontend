import Foundation

// MARK: - 絵本一覧取得サービス

/// ユーザーの絵本一覧取得、お気に入り管理を担当するサービス
public class StorybookListService {
    private let baseURL = APIConfig.shared.baseURL
    public static let shared = StorybookListService()
    
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - 認証ヘルパー
    
    private func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 StorybookListService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    private func checkAuthBeforeRequest() throws {
        if !authManager.verifyAuthState() {
            print("❌ StorybookListService: 認証されていません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        print("✅ StorybookListService: 認証状態OK")
    }
    
    // MARK: - 作成日一覧取得
    
    /// 指定ユーザーの指定年月の作成日一覧を取得
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
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 絵本一覧取得レスポンスJSON（全体）: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
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
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 月別絵本一覧取得レスポンスJSON: \(jsonString.prefix(500))")
            }
            
            let decoder = JSONDecoder()
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
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 日別絵本一覧取得レスポンスJSON: \(jsonString.prefix(500))")
            }
            
            let decoder = JSONDecoder()
            var storybooks: [StorybookResponse]
            var folderCount: Int?
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if jsonObject.keys.contains("books") && jsonObject.keys.contains("folder_count") {
                    let dateResponse = try decoder.decode(StoryBookListByDateResponse.self, from: data)
                    storybooks = dateResponse.books
                    folderCount = dateResponse.folderCount
                    print("✅ 辞書形式のレスポンスをデコード成功: books=\(storybooks.count), folder_count=\(folderCount ?? 0)")
                } else {
                    throw StorybookAPIError.invalidResponse
                }
            } else if let _ = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                storybooks = try decoder.decode([StorybookResponse].self, from: data)
                print("✅ 配列形式のレスポンスをデコード成功: count=\(storybooks.count)")
            } else {
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
    
    // MARK: - お気に入り状態更新
    
    /// ストーリーブックのお気に入り状態を更新する
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
    
    // MARK: - 絵本削除
    
    /// ストーリーブックを削除する
    func deleteStorybook(storybookId: Int) async throws {
        try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/api/storybook/\(storybookId)") else {
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
            
            print("✅ 絵本削除成功: storybookId=\(storybookId)")
        } catch let error as StorybookAPIError {
            handleAuthError(error)
            throw error
        } catch {
            print("❌ 絵本削除失敗: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
}
