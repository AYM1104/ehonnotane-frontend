import Foundation
import Combine

// リクエストモデル
struct UpdateUserRequest: Encodable {
    let user_name: String
}

struct CreateChildRequest: Encodable {
    let user_id: String
    let name: String
    let birthdate: String?
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
        
        // APIリクエストを実行してユーザー情報を更新
        let updatedUser: User = try await APIClient.shared.request(endpoint: endpoint, method: .put, body: body)
        
        // UserServiceのcurrentUserを更新して、アプリ内で最新情報を使えるようにする
        await MainActor.run {
            UserService.shared.currentUser = updatedUser
        }
    }
    
    /// 誕生日テキストをISO 8601形式に変換 ("yyyy/MM/dd" → "yyyy-MM-dd")
    private func formatBirthdateForAPI(_ birthdayText: String) -> String? {
        guard !birthdayText.isEmpty else { return nil }
        return birthdayText.replacingOccurrences(of: "/", with: "-")
    }
    
    /// 子供を追加
    private func createChild(userId: String, child: ChildEntry) async throws {
        let endpoint = "/api/child/"
        // birthdateを "yyyy/MM/dd" から "yyyy-MM-dd" (ISO 8601) 形式に変換
        let formattedBirthdate = formatBirthdateForAPI(child.birthdayText)
        let body = CreateChildRequest(
            user_id: userId,
            name: child.name,
            birthdate: formattedBirthdate
        )
        
        // APIリクエストを実行して子供情報を作成
        let createdChild: Child = try await APIClient.shared.request(endpoint: endpoint, method: .post, body: body)
        
        // ChildServiceのchildrenリストに追加して、アプリ内で最新情報を使えるようにする
        await MainActor.run {
            ChildService.shared.children.append(createdChild)
        }
    }
}
    