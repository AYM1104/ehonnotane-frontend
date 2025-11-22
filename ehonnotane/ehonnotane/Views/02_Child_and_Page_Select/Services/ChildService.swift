import Foundation
import Combine


// 子供のモデル
struct Child: Codable, Identifiable {
    let id: Int
    let user_id: String
    let name: String
    let birthdate: String?
    let color_theme: String?
    let created_at: String
}

// 子供の人数を取得するためのレスポンスモデル
struct ChildrenCountResponse: Codable {
    let user_id: String
    let children_count: Int
}

class ChildService: ObservableObject {
    static let shared = ChildService()
    
    // 初期値
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var childrenCount: Int = 0  // 子供の人数
    @Published var children: [Child] = []  // 子供のリスト
    
    private init() {}
    
    // ユーザーの子供の人数を取得 ---------------------
    func fetchChildrenCount(userId: String) async throws -> Int {

        // APIエンドポイントを定義
        let endpoint = "/api/child/user/\(userId)/count"
        
        do {
            let response: ChildrenCountResponse = try await APIClient.shared.request(endpoint: endpoint)
            
            await MainActor.run {
                self.childrenCount = response.children_count
            }
            // レスポンスとして子供の人数を返す
            return response.children_count
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // ユーザーの子供一覧を取得 ---------------------
    func fetchChildren(userId: String) async throws -> [Child] {
        // APIエンドポイントを定義
        let endpoint = "/api/child/user/\(userId)"
        
        do {
            let response: [Child] = try await APIClient.shared.request(endpoint: endpoint)
            
            await MainActor.run {
                self.children = response
            }
            return response
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
}
