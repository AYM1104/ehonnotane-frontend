import Foundation
import Combine

// リクエストモデル
struct UpdateUserRequest: Encodable {
    let user_name: String
}

struct CreateChildRequest: Encodable {
    let user_id: String
    let name: String
    let birthdate: String
}

class UserRegisterService: ObservableObject {
    static let shared = UserRegisterService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// ユーザー情報の登録（ニックネーム更新と子供の追加）
    func registerUserAndChildren(userId: String, nickname: String, children: [ChildEntry]) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            // 1. ユーザーのニックネーム更新
            try await updateUserNickname(userId: userId, nickname: nickname)
            
            // 2. 子供の登録（並列実行も可能だが、シンプルに直列で実行）
            for child in children {
                try await createChild(userId: userId, child: child)
            }
            
            print("✅ User registration completed")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// ユーザーのニックネームを更新
    private func updateUserNickname(userId: String, nickname: String) async throws {
        let endpoint = "/api/users/\(userId)"
        let body = UpdateUserRequest(user_name: nickname)
        
        // レスポンスの型はUserだが、ここでは使わないので破棄
        let _: User = try await APIClient.shared.request(endpoint: endpoint, method: .put, body: body)
    }
    
    /// 子供を追加
    private func createChild(userId: String, child: ChildEntry) async throws {
        let endpoint = "/api/child/"
        // birthdateは "yyyy/MM/dd" 形式でChildEntryに入っていると仮定
        // APIが期待するフォーマットに合わせる必要があるが、APIClient側でJSONEncoderの設定による
        // ここではそのまま文字列として送る
        let body = CreateChildRequest(
            user_id: userId,
            name: child.name,
            birthdate: child.birthdayText
        )
        
        // レスポンスの型はChildだが、ここでは使わないので破棄
        let _: Child = try await APIClient.shared.request(endpoint: endpoint, method: .post, body: body)
    }
}
    