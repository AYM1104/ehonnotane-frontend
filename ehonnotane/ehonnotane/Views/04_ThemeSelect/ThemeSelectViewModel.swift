import SwiftUI
import Combine

@MainActor
class ThemeSelectViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storybookService = StorybookService.shared
    private let authManager = AuthManager.shared
    
    // MARK: - Published Properties
    @Published var themePages: [ThemePage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 画像生成状態管理
    @Published var isGeneratingImages = false
    @Published var currentStep = 0
    @Published var totalSteps = 5
    @Published var stepMessage = ""
    
    // 画像生成進捗監視
    private var progressMonitor: ImageGenerationProgressMonitor?
    
    // MARK: - Methods
    
    func loadThemeData(coordinator: AppCoordinator) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 認証状態を事前チェック
            print("🔍 ThemeSelectViewModel: 認証状態チェック開始")
            
            // 認証済みユーザーIDを取得
            guard let userId = authManager.getCurrentUserId() else {
                print("❌ ThemeSelectViewModel: ユーザーIDが取得できません")
                themePages = []
                print("⚠️ ThemeSelectViewModel: ユーザーIDが取得できないため、空のテーマリストを表示")
                isLoading = false
                return
            }
            
            print("✅ ThemeSelectViewModel: ユーザーID取得OK - userId: \(userId)")
            
            // 最新のstory_setting_idを取得
            let storySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            
            // テーマプロット一覧を取得
            let themePlotsResponse = try await storybookService.fetchThemePlots(userId: userId, storySettingId: storySettingId, limit: 3)
            
            // ThemePlotResponseからThemePageに変換
            themePages = themePlotsResponse.items.map { ThemePage(from: $0) }
            
            print("✅ テーマデータ読み込み完了: \(themePages.count)件")
            
        } catch {
            print("❌ テーマデータ読み込みエラー: \(error)")
            
            // 認証エラーの場合は特別な処理
            if let storybookError = error as? StorybookAPIError,
               case .serverError(let code, _) = storybookError,
               code == 401 {
                print("🚨 ThemeSelectViewModel: 認証エラー検出 - ログアウト処理を実行")
                
                // 認証エラーの場合は自動的にログアウト
                authManager.logout()
                coordinator.navigateToTop()
                
                errorMessage = "認証に問題があります。ログインし直してください。"
            } else {
                // その他のエラーは空のテーマリストとして扱う（エラー表示しない）
                print("⚠️ ThemeSelectViewModel: APIエラーのため、空のテーマリストを表示")
                themePages = []
                errorMessage = "テーマの読み込みに失敗しました: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    func selectTheme(page: ThemePage, coordinator: AppCoordinator) async {
        print("Selected theme: \(page.title)")
        
        isGeneratingImages = true
        stepMessage = "絵本を作成しています..."
        currentStep = 1
        
        // ユーザーID取得
        guard let userId = authManager.getCurrentUserId() else {
            isGeneratingImages = false
            return
        }
        
        do {
             // 最新のstory_setting_idを取得（再取得）
            let storySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            
            // AppCoordinatorからデータを取得
            let childId = coordinator.questionData?.childId ?? 0
            let storyPages = coordinator.questionData?.storyPages ?? 5
            
            let storybookId = try await storybookService.executeThemeSelectionFlow(
                storySettingId: storySettingId,
                storyPlotId: page.storyPlotId,
                selectedTheme: page.selectedTheme,
                childId: childId,
                storyPages: storyPages
            )
            
            print("✅ ストーリーブック作成完了: \(storybookId)")
            
            // 画像生成の進捗監視を開始
            startImageGenerationMonitoring(storybookId: storybookId, coordinator: coordinator)
            
        } catch {
            print("❌ ストーリーブック作成エラー: \(error)")
            errorMessage = "絵本の作成に失敗しました"
            isGeneratingImages = false
        }
    }
    
    /// 画像生成の進捗監視を開始
    private func startImageGenerationMonitoring(storybookId: Int, coordinator: AppCoordinator) {
        // 既存の監視を停止
        progressMonitor?.stopPolling()
        
        // 新しい監視を開始
        progressMonitor = ImageGenerationProgressMonitor(
            storybookId: storybookId,
            storybookService: storybookService,
            onCompleted: {
                // 完了時に絵本表示画面へ遷移
                await MainActor.run {
                    self.isGeneratingImages = false
                    coordinator.navigateToStorybook(storybookId: storybookId)
                }
            },
            onFailed: { errorMessage in
                Task { @MainActor in
                    self.errorMessage = errorMessage
                    self.isGeneratingImages = false
                }
            }
        )
        
        // 進捗監視の状態を定期的に更新
        Task {
            await syncProgressFromMonitor()
        }
        
        progressMonitor?.startPolling()
    }
    
    /// 進捗監視の状態をViewModelに同期
    private func syncProgressFromMonitor() async {
        guard let monitor = progressMonitor else { return }
        
        while monitor.isGeneratingImages {
            await MainActor.run {
                self.isGeneratingImages = monitor.isGeneratingImages
                self.currentStep = monitor.currentGeneratingPage
                self.totalSteps = monitor.totalPages
                self.stepMessage = "\(monitor.currentGeneratingPage)/\(monitor.totalPages)ページ生成中..."
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒ごとに更新
        }
        
        await MainActor.run {
            self.isGeneratingImages = false
        }
    }
}
