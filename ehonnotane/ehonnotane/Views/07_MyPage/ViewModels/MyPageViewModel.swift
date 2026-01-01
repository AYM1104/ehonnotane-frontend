import SwiftUI
import Combine

/// マイページ画面のViewModel
@MainActor
class MyPageViewModel: BaseViewModel {
    
    /// 子供のリスト
    @Published var children: [Child] = []
    
    /// お気に入りの絵本リスト
    @Published var favoriteBooks: [StoryBookListItem] = []
    
    /// お気に入り絵本の読み込み状態
    @Published var isLoadingFavorites: Bool = false
    
    /// ChildServiceのインスタンス
    private let childService = ChildService.shared
    
    /// StatisticsServiceのインスタンス
    private let statisticsService = StatisticsService.shared
    
    /// StorybookServiceのインスタンス
    private let storybookService = StorybookService.shared
    
    /// 統計データ
    @Published var statistics: Statistics?

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
        print("🔵 [MyPageViewModel] loadUserInfo() 開始")
        setLoading(true)
        clearError()
        
        guard let userId = currentUserId else {
            print("❌ [MyPageViewModel] ユーザーIDが取得できません")
            setError("ユーザーIDが取得できません")
            return
        }
        
        print("🔵 [MyPageViewModel] ユーザーID: \(userId)")
        
        do {
            // 既にユーザー情報が取得済みの場合はAPIリクエストをスキップ
            // ログイン時に既に取得されているため、子供情報のみ取得
            if userService.currentUser == nil {
                print("🔵 [MyPageViewModel] ユーザー情報が未取得のため、API呼び出し")
                // ユーザー情報が存在しない場合のみ取得
                _ = try await userService.fetchUser(userId: userId)
                print("✅ [MyPageViewModel] ユーザー情報取得成功")
            } else {
                print("✅ [MyPageViewModel] ユーザー情報は既に取得済み: \(userService.currentUser?.user_name ?? "unknown")")
            }
            
            // 子供情報を取得
            print("🔵 [MyPageViewModel] 子供情報の取得を開始")
            try await loadChildren(userId: userId)
            print("✅ [MyPageViewModel] 子供情報取得完了: \(children.count)件")
            
            // 統計データを取得
            print("🔵 [MyPageViewModel] 統計データの取得を開始")
            try await loadStatistics(userId: userId)
            print("✅ [MyPageViewModel] 統計データ取得完了")
            
            setLoading(false)
        } catch {
            setError("ユーザー情報の取得に失敗しました: \(error.localizedDescription)")
            print("❌ [MyPageViewModel] ユーザー情報の取得に失敗: \(error)")
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
        print("🔵 [MyPageViewModel] loadChildren() 開始 - userId: \(userId)")
        do {
            let fetchedChildren = try await childService.fetchChildren(userId: userId)
            print("✅ [MyPageViewModel] API呼び出し成功 - 取得件数: \(fetchedChildren.count)")
            
            if fetchedChildren.isEmpty {
                print("⚠️ [MyPageViewModel] 子供情報が0件です")
            } else {
                print("✅ [MyPageViewModel] 子供情報:")
                for (index, child) in fetchedChildren.enumerated() {
                    print("  [\(index)] ID: \(child.id), 名前: \(child.name), 誕生日: \(child.birthdate ?? "未設定")")
                }
            }
            
            self.children = fetchedChildren
            print("✅ [MyPageViewModel] viewModel.childrenに格納完了: \(self.children.count)件")
        } catch {
            print("❌ [MyPageViewModel] 子供情報の取得に失敗: \(error)")
            print("❌ [MyPageViewModel] エラー詳細: \(String(describing: error))")
            // 子供情報の取得失敗はエラーとしない（空のリストにする）
            self.children = []
            print("⚠️ [MyPageViewModel] 子供情報を空配列に設定しました")
        }
    }
    
    /// 統計データを取得
    private func loadStatistics(userId: String) async throws {
        print("🔵 [MyPageViewModel] loadStatistics() 開始 - userId: \(userId)")
        do {
            let fetchedStatistics = try await statisticsService.fetchStatistics(userId: userId)
            print("✅ [MyPageViewModel] 統計データ取得成功: すべて=\(fetchedStatistics.total), 今月=\(fetchedStatistics.thisMonth), 今週=\(fetchedStatistics.thisWeek)")
            
            self.statistics = fetchedStatistics
            print("✅ [MyPageViewModel] viewModel.statisticsに格納完了")
        } catch {
            print("❌ [MyPageViewModel] 統計データの取得に失敗: \(error)")
            print("❌ [MyPageViewModel] エラー詳細: \(String(describing: error))")
            // 統計データの取得失敗はエラーとしない（nilのまま）
            self.statistics = nil
            print("⚠️ [MyPageViewModel] 統計データをnilに設定しました")
        }
    }
    
    /// お気に入りの絵本を取得
    func fetchFavoriteBooks(userId: String) async {
        print("🔵 [MyPageViewModel] fetchFavoriteBooks() 開始 - userId: \(userId)")
        isLoadingFavorites = true
        
        do {
            // ユーザーの絵本一覧を取得
            let allBooks = try await storybookService.fetchUserStorybooks(userId: userId)
            print("✅ [MyPageViewModel] 絵本一覧取得成功: \(allBooks.count)件")
            
            // お気に入りのみをフィルタリング
            let favorites = allBooks.filter { $0.isFavorite }
            print("✅ [MyPageViewModel] お気に入り絵本: \(favorites.count)件")
            
            self.favoriteBooks = favorites
            isLoadingFavorites = false
        } catch {
            print("❌ [MyPageViewModel] お気に入り絵本の取得に失敗: \(error)")
            self.favoriteBooks = []
            isLoadingFavorites = false
        }
    }
    
    /// お子様を追加
    func addChild(name: String, birthDate: Date) async {
        print("🔵 [MyPageViewModel] addChild() 開始 - 名前: \(name)")
        
        guard let userId = currentUserId else {
            print("❌ [MyPageViewModel] ユーザーIDが取得できません")
            return
        }
        
        do {
            // 新しい子供を追加
            let newChild = try await childService.createChild(
                userId: userId,
                name: name,
                birthdate: birthDate
            )
            print("✅ [MyPageViewModel] 子供追加成功: \(newChild.name)")
            
            // リストに追加
            children.append(newChild)
            print("✅ [MyPageViewModel] 子供リスト更新完了: \(children.count)件")
        } catch {
            print("❌ [MyPageViewModel] 子供追加に失敗: \(error)")
            setError("お子様の追加に失敗しました")
        }
    }
}

