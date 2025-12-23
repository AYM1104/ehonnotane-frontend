import SwiftUI
import Combine

/// マイページ画面のViewModel
@MainActor
class MyPageViewModel: BaseViewModel {

    /// ユーザー名を取得
    var username: String {
        userService.currentUser?.user_name ?? "ユーザー"
    }
    
    /// ユーザーの残高を取得
    var balance: Int {
        userService.currentUser?.balance ?? 0
    }
    
    /// ユーザー情報を取得
    func loadUserInfo() async {
        setLoading(true)
        clearError()
        
        guard let userId = currentUserId else {
            setError("ユーザーIDが取得できません")
            return
        }
        
        do {
            _ = try await userService.fetchUser(userId: userId)
            setLoading(false)
        } catch {
            setError("ユーザー情報の取得に失敗しました: \(error.localizedDescription)")
            print("❌ ユーザー情報の取得に失敗: \(error)")
        }
    }
}

