import Foundation
import Combine

// MARK: - 認証プロバイダープロトコル
protocol AuthProvider: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isLoggedIn: Bool { get }
    
    func login(completion: @escaping (AuthResult) -> Void)
    func logout(completion: @escaping (Bool) -> Void)
    func verifyToken() -> Bool
}

// MARK: - プロバイダー種別
enum AuthProviderType {
    case google
    case apple
    case line
    case twitter
}

// MARK: - 表示名・アイコン名
extension AuthProviderType {
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .apple: return "Apple"
        case .line: return "LINE"
        case .twitter: return "X"
        }
    }
    
    var iconName: String {
        switch self {
        case .google: return "logo-Google"
        case .apple: return "logo-Apple"
        case .line: return "logo-LINE"
        case .twitter: return "logo-X"
        }
    }
    
}

// MARK: - プロバイダーファクトリー
struct AuthProviderFactory {
    static func make(_ type: AuthProviderType) -> any AuthProvider {
        switch type {
        case .google:
            return GoogleAuthProvider()
        case .apple, .line, .twitter:
            // 未実装のプロバイダー
            fatalError("AuthProvider for \(type) is not implemented yet.")
        }
    }
}
