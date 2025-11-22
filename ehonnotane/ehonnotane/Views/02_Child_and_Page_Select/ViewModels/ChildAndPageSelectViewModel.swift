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
    
    // 選択可能なページ数を定義
    private let allPageCountOptions: [SelectOption] = [
        SelectOption(label: "3ページ", value: "3"),
        SelectOption(label: "5ページ", value: "5"),
        SelectOption(label: "7ページ", value: "7"),
        SelectOption(label: "10ページ", value: "10")
    ]
    
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
        
        // ページ数は必須
        guard let pageCount = Int(selectedPageCount) else {
            self.isLoading = false
            throw NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: "ページ数が選択されていません"])
        }
        
        // 子供IDはオプショナル（子供が0人の場合も許可）
        let childId: Int? = selectedChild.isEmpty ? nil : Int(selectedChild)
        
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
        // FreeとBasic(STARTER)は5ページまで
        if subscriptionPlan == .free || subscriptionPlan == .starter {
            self.availablePageCountOptions = allPageCountOptions.filter { option in
                guard let value = Int(option.value) else { return false }
                return value <= 5
            }
        } else {
            // それ以外は全て選択可能
            self.availablePageCountOptions = allPageCountOptions
        }
        
        // 現在の選択が選択肢にない場合は、利用可能な最大のページ数を選択
        if !availablePageCountOptions.contains(where: { $0.value == selectedPageCount }) {
            if let last = availablePageCountOptions.last {
                selectedPageCount = last.value
            }
        }
    }
}
