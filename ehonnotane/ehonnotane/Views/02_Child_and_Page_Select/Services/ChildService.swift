import Foundation
import Combine


// 子供のモデル
struct Child: Codable, Identifiable, Equatable {
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
        print("🔵 [ChildService] fetchChildren() 開始 - userId: \(userId)")
        
        // APIエンドポイントを定義
        let endpoint = "/api/child/user/\(userId)"
        print("🔵 [ChildService] APIエンドポイント: \(endpoint)")
        
        do {
            let response: [Child] = try await APIClient.shared.request(endpoint: endpoint)
            print("✅ [ChildService] API呼び出し成功 - 取得件数: \(response.count)")
            
            if response.isEmpty {
                print("⚠️ [ChildService] レスポンスが空です（子供情報0件）")
            } else {
                print("✅ [ChildService] 取得した子供情報:")
                for (index, child) in response.enumerated() {
                    print("  [\(index)] ID: \(child.id), 名前: \(child.name)")
                }
            }
            
            await MainActor.run {
                self.children = response
                print("✅ [ChildService] ChildService.shared.childrenに格納完了: \(self.children.count)件")
            }
            return response
            
        } catch {
            print("❌ [ChildService] API呼び出し失敗: \(error)")
            print("❌ [ChildService] エラー詳細: \(String(describing: error))")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // 子供を作成 ---------------------
    struct CreateChildRequest: Codable {
        let user_id: String
        let name: String
        let birthdate: String
        let color_theme: String?
    }
    
    func createChild(userId: String, name: String, birthdate: Date) async throws -> Child {
        print("🔵 [ChildService] createChild() 開始")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdateString = formatter.string(from: birthdate)
        
        let requestBody = CreateChildRequest(
            user_id: userId,
            name: name,
            birthdate: birthdateString,
            color_theme: "default" // デフォルトテーマ
        )
        
        let endpoint = "/api/child/"
        
        do {
            let response: Child = try await APIClient.shared.request(
                endpoint: endpoint,
                method: .post,
                body: requestBody
            )
            print("✅ [ChildService] 子供作成成功: \(response.name)")
            
            // リストを更新するために再取得
            _ = try await fetchChildren(userId: userId)
            
            return response
        } catch {
            print("❌ [ChildService] 子供作成失敗: \(error)")
            throw error
        }
    }
}
