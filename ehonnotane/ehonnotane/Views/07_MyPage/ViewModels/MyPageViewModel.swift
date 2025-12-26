import SwiftUI
import Combine

/// マイページ画面のViewModel
@MainActor
class MyPageViewModel: BaseViewModel {
    
    /// 子供のリスト
    @Published var children: [Child] = []
    
    /// ChildServiceのインスタンス
    private let childService = ChildService.shared

    /// ユーザー名を取得
    var username: String {
        userService.currentUser?.user_name ?? "ユーザー"
    }
    
    /// ユーザーの残高を取得
    var balance: Int {
        userService.currentUser?.balance ?? 0
    }
    
    /// ユーザー情報を取得（初回表示時など）
    /// ログイン時に既に取得済みの場合は、そのまま使用（APIリクエストなし）
    func loadUserInfo() async {
        setLoading(true)
        clearError()
        
        guard let userId = currentUserId else {
            setError("ユーザーIDが取得できません")
            return
        }
        
        do {
            // 既にユーザー情報が取得済みの場合はAPIリクエストをスキップ
            // ログイン時に既に取得されているため、子供情報のみ取得
            if userService.currentUser == nil {
                // ユーザー情報が存在しない場合のみ取得
                _ = try await userService.fetchUser(userId: userId)
            }
            
            // 子供情報を取得
            try await loadChildren(userId: userId)
            
            setLoading(false)
        } catch {
            setError("ユーザー情報の取得に失敗しました: \(error.localizedDescription)")
            print("❌ ユーザー情報の取得に失敗: \(error)")
            setLoading(false)
        }
    }
    
    /// ユーザー情報を更新（イベントベースの更新で使用）
    /// クレジット追加後、プロフィール編集後など、データが変更される可能性があるタイミングで呼び出す
    func refreshUserInfo() async {
        setLoading(true)
        clearError()
        
        guard let userId = currentUserId else {
            setError("ユーザーIDが取得できません")
            return
        }
        
        do {
            // ユーザー情報を更新
            _ = try await userService.refreshUser(userId: userId)
            
            // 子供情報も更新
            try await loadChildren(userId: userId)
            
            setLoading(false)
        } catch {
            setError("ユーザー情報の更新に失敗しました: \(error.localizedDescription)")
            print("❌ ユーザー情報の更新に失敗: \(error)")
            setLoading(false)
        }
    }
    
    /// 子供のリストを取得
    private func loadChildren(userId: String) async throws {
        do {
            let fetchedChildren = try await childService.fetchChildren(userId: userId)
            self.children = fetchedChildren
        } catch {
            print("❌ 子供情報の取得に失敗: \(error)")
            // 子供情報の取得失敗はエラーとしない（空のリストにする）
            self.children = []
        }
    }
}

