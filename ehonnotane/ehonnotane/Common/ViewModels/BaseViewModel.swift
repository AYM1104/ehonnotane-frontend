import SwiftUI
import Combine

/// ViewModelの基底クラス - 全ViewModelで共通の機能を提供
///
/// ## 提供する機能
///
/// ### 1. 共通の依存関係
/// - `authManager`: 認証管理（ユーザーID取得など）
/// - `userService`: ユーザー情報の取得・更新
///
/// ### 2. 共通の状態管理
/// - `isLoading`: ローディング状態（API呼び出し中など）
/// - `errorMessage`: エラーメッセージ（APIエラーなど）
///
/// ### 3. 共通のヘルパーメソッド
/// - `setLoading()`: ローディング状態を設定
/// - `setError()`: エラーを設定（ローディングも自動的にfalseに）
/// - `clearError()`: エラーをクリア
///
/// ### 4. 共通のComputed Properties
/// - `currentUserId`: 現在のユーザーIDを取得
/// - `hasError`: エラーがあるかどうかを判定
///
/// ## 使用例
/// ```swift
/// class MyPageViewModel: BaseViewModel {
///     func loadUserInfo() async {
///         setLoading(true)  // 基底クラスのメソッドを使用
///         clearError()
///         
///         guard let userId = currentUserId else {
///             setError("ユーザーIDが取得できません")
///             return
///         }
///         
///         // API呼び出しなど...
///         setLoading(false)
///     }
/// }
/// ```
@MainActor
class BaseViewModel: ObservableObject {
    // MARK: - Common Dependencies
    /// 認証マネージャー（共通で使用）
    /// - ユーザーID取得: `authManager.getCurrentUserId()`
    /// - ユーザー情報取得: `authManager.userInfo`
    let authManager = AuthManager.shared
    
    /// ユーザーサービス（共通で使用）
    /// - ユーザー情報取得: `userService.fetchUser(userId:)`
    /// - 現在のユーザー: `userService.currentUser`
    let userService = UserService.shared
    
    // MARK: - Common Published Properties
    /// ローディング状態
    /// - `true`: API呼び出し中、データ処理中など
    /// - `false`: 処理完了、待機中など
    @Published var isLoading = false
    
    /// エラーメッセージ
    /// - `nil`: エラーなし
    /// - 文字列: エラーメッセージ（APIエラー、バリデーションエラーなど）
    @Published var errorMessage: String?
    
    // MARK: - Common Computed Properties
    /// 現在のユーザーIDを取得
    /// - ログイン済み: ユーザーIDを返す
    /// - 未ログイン: `nil`を返す
    var currentUserId: String? {
        authManager.getCurrentUserId()
    }
    
    /// エラーがあるかどうかを判定
    /// - `true`: エラーメッセージが設定されている
    /// - `false`: エラーなし
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Common Methods
    /// エラーをクリア
    /// - `errorMessage`を`nil`に設定
    func clearError() {
        errorMessage = nil
    }
    
    /// ローディング状態を設定
    /// - Parameter loading: `true`でローディング開始、`false`で終了
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// エラーを設定
    /// - Parameter message: エラーメッセージ
    /// - Note: エラー設定時に自動的に`isLoading`を`false`に設定
    func setError(_ message: String) {
        errorMessage = message
        isLoading = false
    }
}

