import Foundation
import Combine

// MARK: - Models

enum PlanType: String, Codable {
    case free = "FREE"
    case starter = "STARTER"
    case plus = "PLUS"
    case premium = "PREMIUM"
}

struct User: Codable, Identifiable {
    let id: String
    let user_name: String
    let email: String?
    let balance: Int
    let subscription_plan: PlanType
    let created_at: String
    let updated_at: String
}

struct UserCreateRequest: Encodable {
    let id: String
    let user_name: String
    let email: String
}

// MARK: - Service

class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// ユーザー情報を取得
    func fetchUser(userId: String) async throws -> User {
        let endpoint = "/api/users/\(userId)"
        
        do {
            let user: User = try await APIClient.shared.request(endpoint: endpoint)
            await MainActor.run {
                self.currentUser = user
            }
            return user
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// ユーザーを新規作成
    func createUser(user: UserCreateRequest) async throws -> User {
        let endpoint = "/api/users/"
        
        do {
            let createdUser: User = try await APIClient.shared.request(endpoint: endpoint, method: .post, body: user)
            await MainActor.run {
                self.currentUser = createdUser
            }
            return createdUser
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Auth0のユーザー情報とバックエンドのユーザー情報を同期
    /// ユーザーが存在しない場合は新規作成する
    /// - Returns: (user: ユーザー情報, isNew: 新規作成されたかどうか)
    func syncUser(auth0User: UserInfo) async throws -> (user: User, isNew: Bool) {
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
            // 1. ユーザー取得を試みる
            let user = try await fetchUser(userId: auth0User.id)
            return (user, false)
        } catch let error as APIError {
            // 2. 404エラー（ユーザー未登録）の場合は新規作成
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User not found in backend, creating new user...")
                
                // メールアドレスは必須
                guard let email = auth0User.email else {
                    let error = NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "メールアドレスが必要です"])
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                    throw error
                }
                
                let newUser = UserCreateRequest(
                    id: auth0User.id,
                    user_name: auth0User.name ?? "User",
                    email: email
                )
                
                let createdUser = try await createUser(user: newUser)
                return (createdUser, true)
            }
            throw error
        } catch {
            throw error
        }
    }

    
    /// ユーザーを削除
    func deleteUser(userId: String) async throws {
        let endpoint = "/api/users/\(userId)"
        
        do {
            // bodyは不要なのでnilを渡す（型推論のために型指定）
            let body: String? = nil
            let _: DeleteUserResponse = try await APIClient.shared.request(endpoint: endpoint, method: .delete, body: body)
            
            await MainActor.run {
                self.currentUser = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
}

struct DeleteUserResponse: Decodable {
    let user_id: String
}
