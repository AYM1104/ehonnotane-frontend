import SwiftUI
import Combine

class ChildAndPageSelectViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var childOptions: [SelectOption] = []
    @Published var selectedChild: String = ""
    @Published var selectedPageCount: String = "3"
    @Published var isLoading: Bool = true
    @Published var childrenCount: Int = 0
    @Published var availablePageCountOptions: [SelectOption] = []
    @Published var currentCredits: Int = 0
    
    // 現在のページインデックス（スライド用）
    @Published var currentPageIndex: Int = 0
    
    // クリーンアップ用: story_setting_idを保持
    @Published var storySettingId: Int? = nil
    
    // 選択可能なページ数を定義（計算プロパティでローカライズ対応）
    private var allPageCountOptions: [SelectOption] {
        [3, 5, 7, 10].map { count in
            SelectOption(label: String(localized: "select.page_count_option \(count)"), value: "\(count)")
        }
    }
    
    // 消費するクレジット数を定義
    var requiredCredits: Int {
        switch selectedPageCount {
        case "3": return 80
        case "5": return 120
        case "7": return 150
        case "10": return 200
        default: return 0
        }
    }
    
    // クレジット不足かどうか
    var hasInsufficientCredits: Bool {
        return requiredCredits > currentCredits
    }
    
    // MARK: - Private Properties
    
    private let childService = ChildService.shared
    private let userService = UserService.shared
    private let storySettingService = StorySettingService()
    private var subscriptionPlan: PlanType = .free
    private let isMockMode: Bool
    
    // MARK: - Initializers
    
    /// 通常の初期化（実際のデータを使用）
    init() {
        self.isMockMode = false
    }
    
    /// プレビュー用の初期化（モックデータを使用）
    init(mockMode: Bool = false, mockChildrenCount: Int = 2, mockCredits: Int = 200) {
        self.isMockMode = mockMode
        if mockMode {
            // モックデータを設定
            self.childrenCount = mockChildrenCount
            self.currentCredits = mockCredits
            self.isLoading = false
            self.subscriptionPlan = .premium
            
            // モックの子供データ
            if mockChildrenCount >= 2 {
                self.childOptions = [
                    SelectOption(label: "太郎", value: "1"),
                    SelectOption(label: "花子", value: "2")
                ]
            } else if mockChildrenCount == 1 {
                self.childOptions = [
                    SelectOption(label: "太郎", value: "1")
                ]
                self.selectedChild = "1"
            }
            
            // 全ページ数オプションを利用可能にする
            self.availablePageCountOptions = allPageCountOptions
        }
    }
    
    // MARK: - Methods
    
    @MainActor
    func confirmSelection(storySettingId: Int) async throws {
        self.isLoading = true
        
        // ページ数は必須（バリデーション済みだが念のため）
        guard let pageCount = Int(selectedPageCount) else {
            self.isLoading = false
            throw NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: "ページ数が選択されていません"])
        }
        
        // 子供の選択チェック
        // childrenCount >= 2 の場合は選択必須
        if childrenCount >= 2 && selectedChild.isEmpty {
            self.isLoading = false
            throw NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: "お子さまを選択してください"])
        }
        
        // 子供IDを設定
        // 選択されている場合はそのID、空の場合はnil（0人または1人の場合）
        // ただし、1人の場合でselectedChildがセットされていない場合（念のため）は、
        // optionsの最初の要素をデフォルトとして使うロジックも考えられるが、
        // loadChildrenで既にセットされているはず。
        
        var childId: Int? = nil
        
        if !selectedChild.isEmpty {
            childId = Int(selectedChild)
        } else if childrenCount == 1 {
            // 念のため、1人の場合は自動的にそのIDを使用（loadChildrenでセットされるはずだが）
            if let firstChild = childOptions.first?.value {
                childId = Int(firstChild)
            }
        }
        
        do {
            // 物語設定を更新
            try await storySettingService.updateStorySetting(
                id: storySettingId,
                childId: childId,
                pageCount: pageCount
            )
            self.isLoading = false
        } catch {
            self.isLoading = false
            throw error
        }
    }
    
    @MainActor
    func loadChildren() async {
        // モックモードの場合は何もしない
        if isMockMode {
            return
        }
        
        // AuthManagerを使ってユーザーIDを取得
        guard let userId = AuthManager().getCurrentUserId() else {
            print("⚠️ ユーザーIDを取得できませんでした")
            self.isLoading = false
            return
        }
        
        do {
            // ユーザー情報を取得してプランを確認
            let user = try await userService.fetchUser(userId: userId)
            self.subscriptionPlan = user.subscription_plan
            self.currentCredits = user.balance
            print("✅ ユーザープラン: \(user.subscription_plan.rawValue)")
            print("✅ 現在のクレジット: \(user.balance)")
            
            // プランに基づいてページ数オプションをフィルタリング
            updateAvailablePageOptions()
            
            // 子供の人数を取得
            let count = try await childService.fetchChildrenCount(userId: userId)
            self.childrenCount = count
            print("✅ 子供の人数: \(count)")
            
            // 子供が1人以上いる場合は詳細情報も取得
            if count > 0 {
                let children = try await childService.fetchChildren(userId: userId)
                
                // SelectOption形式に変換
                self.childOptions = children.map { child in
                    SelectOption(label: child.name, value: String(child.id))
                }
                
                // 子供が1人の場合は自動選択
                if children.count == 1 {
                    self.selectedChild = String(children[0].id)
                }
            }
            
            self.isLoading = false
            
        } catch {
            print("❌ データ取得エラー: \(error.localizedDescription)")
            self.isLoading = false
            // エラー時もデフォルト（制限付き）で表示できるようにする
            updateAvailablePageOptions()
        }
    }
    
    // サブスクプランに基づいて選択可能ページ数を表示
    private func updateAvailablePageOptions() {
        // Freeプランは5ページまで選択可能、7/10はロック表示
        // サブスクプラン利用者（STARTER/PLUS/PREMIUM）は全ページ選択可能
        if subscriptionPlan == .free {
            self.availablePageCountOptions = allPageCountOptions.map { option in
                guard let value = Int(option.value) else { return option }
                if value > 5 {
                    return SelectOption(label: option.label, value: option.value, isLocked: true)
                }
                return option
            }
        } else {
            // それ以外は全て選択可能
            self.availablePageCountOptions = allPageCountOptions
        }
        
        // 現在の選択がロックされた選択肢の場合はリセット
        if let currentOption = availablePageCountOptions.first(where: { $0.value == selectedPageCount }),
           currentOption.isLocked {
            // 利用可能な最大のページ数（ロックされていない）を選択
            if let lastUnlocked = availablePageCountOptions.last(where: { !$0.isLocked }) {
                selectedPageCount = lastUnlocked.value
            }
        }
        
        // 現在の選択が選択肢にない場合は、利用可能な最大のページ数を選択
        if !availablePageCountOptions.contains(where: { $0.value == selectedPageCount }) {
            if let lastUnlocked = availablePageCountOptions.last(where: { !$0.isLocked }) {
                selectedPageCount = lastUnlocked.value
            }
        }
    }
}
