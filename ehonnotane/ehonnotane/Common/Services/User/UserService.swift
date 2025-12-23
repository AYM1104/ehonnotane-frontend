import Foundation
import Combine

// MARK: - Service

/// ユーザー情報の状態管理と統合ロジックを担当するサービス
/// 各機能サービス（UserFetchService, UserCreateService, UserDeleteService）を統合し、
/// currentUserの状態管理を行う
class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: User?
    
    private let fetchService = UserFetchService.shared
    private let createService = UserCreateService.shared
    private let deleteService = UserDeleteService.shared
    
    private init() {}
    
    func fetchUser(userId: String) async throws -> User {
        let user = try await fetchService.fetchUser(userId: userId)
        await MainActor.run {
            self.currentUser = user
        }
        return user
    }
    
    func createUser(user: UserCreateRequest) async throws -> User {
        let createdUser = try await createService.createUser(user: user)
        await MainActor.run {
            self.currentUser = createdUser
        }
        return createdUser
    }
    
    /// Auth0のユーザー情報とバックエンドのユーザー情報を同期
    /// ユーザーが存在しない場合は新規作成する
    func syncUser(auth0User: UserInfo) async throws -> (user: User, isNew: Bool) {
        do {
            let user = try await fetchUser(userId: auth0User.id)
            return (user, false)
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                print("ℹ️ User not found in backend, creating new user...")
                
                guard let email = auth0User.email else {
                    throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "メールアドレスが必要です"])
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
        }
    }
    
    func deleteUser(userId: String) async throws {
        try await deleteService.deleteUser(userId: userId)
        await MainActor.run {
            self.currentUser = nil
        }
    }
}

