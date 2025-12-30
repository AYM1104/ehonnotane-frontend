import SwiftUI
import Combine

@MainActor
class ThemeSelectViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storybookService = StorybookService.shared
    private let authManager = AuthManager.shared
    private let userService = UserService.shared
    
    // MARK: - Published Properties
    @Published var themePages: [ThemePage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 画像生成状態管理
    @Published var isGeneratingImages = false
    @Published var currentStep = 0
    @Published var totalSteps = 5
    @Published var stepMessage = ""
    
    // クレジット不足モーダル表示
    @Published var showCreditInsufficientModal = false
    @Published var currentCredits = 0
    @Published var requiredCredits = 0
    
    // 画像生成進捗監視
    private var progressMonitor: ImageGenerationProgressMonitor?
    
    // 進捗表示用
    @Published var progressPercentage: Double = 0.0
    
    // 段階的に進捗を上げるためのタスク
    private var progressStepperTask: Task<Void, Never>?
    
    // クリーンアップ用: story_setting_idを保持
    @Published var storySettingId: Int? = nil
    
    // 待ち時間軽減機能用のプロパティ
    @Published var estimatedTimeRemaining: String = "処理中..."
    @Published var generatedPagePreviews: [Int: String] = [:]  // [pageNumber: imageURL]
    @Published var currentTip: String = ""
    
    // 生成開始時刻（残り時間計算用）
    private var generationStartTime: Date?
    
    // ティップス管理
    private var tipTimer: Timer?
    private let tips = [
        "✨ すてきな えほんを つくっているよ",
        "🎨 きれいな いろで ぬっているよ",
        "📚 たのしい おはなしに なるかな？",
        "🌟 もうすこしで できあがるよ",
        "💝 わくわくする えほんを かいているよ",
        "🎯 しゅじんこうが いきいきと うごくよ",
        "🌈 カラフルな せかいを つくっているよ"
    ]
    private var currentTipIndex = 0
    
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
            let fetchedStorySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            self.storySettingId = fetchedStorySettingId // クリーンアップ用に保存
            
            // テーマプロット一覧を取得
            let themePlotsResponse = try await storybookService.fetchThemePlots(userId: userId, storySettingId: fetchedStorySettingId, limit: 3)
            
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
        
        // ユーザーID取得
        guard let userId = authManager.getCurrentUserId() else {
            return
        }
        
        // AppCoordinatorからデータを取得
        let storyPages = coordinator.questionData?.storyPages ?? 5
        
        // クレジット情報を取得
        do {
            let user = try await userService.fetchUser(userId: userId)
            currentCredits = user.balance
            
            // 必要なクレジット数を計算
            requiredCredits = getRequiredCredits(for: storyPages)
            
            // クレジット不足をチェック
            if currentCredits < requiredCredits {
                print("⚠️ クレジット不足: 現在=\(currentCredits), 必要=\(requiredCredits)")
                showCreditInsufficientModal = true
                return
            }
            
            // クレジットが十分な場合、通常の処理を続行
            await proceedWithThemeSelection(page: page, coordinator: coordinator, userId: userId, storyPages: storyPages)
            
        } catch {
            print("❌ ユーザー情報取得エラー: \(error)")
            errorMessage = "クレジット情報の取得に失敗しました"
        }
    }
    
    /// クレジットが十分な場合にテーマ選択処理を実行
    private func proceedWithThemeSelection(page: ThemePage, coordinator: AppCoordinator, userId: String, storyPages: Int) async {
        isGeneratingImages = true
        stepMessage = "物語を書いています..."
        currentStep = 0
        
        // 早期フィードバック: 即座に5%表示
        progressPercentage = 0.05
        
        // 生成開始時刻を記録
        generationStartTime = Date()
        
        // ティップス表示を開始
        startTipRotation()
        
        // 物語生成フェーズ: 0% -> 15% を10秒固定で進める
        animateProgress(to: 0.15, totalDurationSec: 10.0)
        
        do {
            // 最新のstory_setting_idを取得（再取得）
            let storySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            
            // AppCoordinatorからデータを取得
            let childId = coordinator.questionData?.childId ?? 0
            
            let storybookId = try await storybookService.executeThemeSelectionFlow(
                storySettingId: storySettingId,
                storyPlotId: page.storyPlotId,
                selectedTheme: page.selectedTheme,
                childId: childId,
                storyPages: storyPages
            )
            
            print("✅ ストーリーブック作成完了: \(storybookId)")
            
            // 物語生成完了、画像生成開始へ（15%からスタート）
            animateProgress(to: 0.15)
            stepMessage = "絵を描いています..."
            
            // 画像生成の進捗監視を開始
            startImageGenerationMonitoring(storybookId: storybookId, coordinator: coordinator, totalPages: storyPages)
            
        } catch {
            print("❌ ストーリーブック作成エラー: \(error)")
            errorMessage = "絵本の作成に失敗しました"
            isGeneratingImages = false
            stopTipRotation()
        }
    }
    
    /// 目標のパーセンテージまで1%刻みでゆっくり進める
    private func animateProgress(to target: Double, step: Double = 0.01, totalDurationSec: Double? = nil, defaultInterval: UInt64 = 30_000_000) {
        // 既存の進行タスクをキャンセルし、新しい目標へ向かう
        progressStepperTask?.cancel()
        let clampedTarget = max(0.0, min(1.0, target))
        
        progressStepperTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var current = self.progressPercentage
            
            // 全体時間指定がある場合、ステップ間隔を動的に決定
            let interval: UInt64
            if let totalDurationSec, clampedTarget > current {
                let remaining = clampedTarget - current
                // 残り距離とステップ数から1ステップあたりの時間を計算（下限10ms）
                let steps = max(remaining / step, 1)
                let perStepSeconds = max(totalDurationSec / steps, 0.01)
                interval = UInt64(perStepSeconds * 1_000_000_000)
            } else {
                interval = defaultInterval // デフォルト: 30msごとに+1%
            }
            
            while current < clampedTarget && !Task.isCancelled {
                current = min(current + step, clampedTarget)
                withAnimation(.linear(duration: 0.03)) {
                    self.progressPercentage = current
                }
                try? await Task.sleep(nanoseconds: interval) // デフォルト: 30msごとに+1%
            }

            // ループを抜けても念のため目標値に揃える（浮動小数の誤差やキャンセルを考慮）
            if !Task.isCancelled && self.progressPercentage < clampedTarget {
                withAnimation(.linear(duration: 0.05)) {
                    self.progressPercentage = clampedTarget
                }
            }
        }
    }
    
    /// ページ数に応じた必要クレジット数を計算
    private func getRequiredCredits(for storyPages: Int) -> Int {
        switch storyPages {
        case 3: return 80
        case 5: return 120
        case 7: return 150
        case 10: return 200
        default: return 120  // デフォルトは5ページ分
        }
    }
    
    /// 画像生成の進捗監視を開始
    private func startImageGenerationMonitoring(storybookId: Int, coordinator: AppCoordinator, totalPages: Int) {
        // 既存の監視を停止
        progressMonitor?.stopPolling()
        
        // 新しい監視を開始
        progressMonitor = ImageGenerationProgressMonitor(
            storybookId: storybookId,
            storybookService: storybookService,
            initialTotalPages: totalPages,
            onCompleted: {
                // 完了時に絵本表示画面へ遷移
                // 注意: ImageGenerationProgressMonitor は @MainActor なので、既に MainActor のコンテキストで実行されている
                print("🎯 ThemeSelectViewModel: 画像生成完了 - StoryBookView へ遷移します (storybookId: \(storybookId))")

                // 99%から100%へ（0.5秒でスムーズに）
                self.progressStepperTask?.cancel()
                self.animateProgress(to: 1.0, totalDurationSec: 0.5)
                
                // 最終メッセージ
                let finalSteps = max(self.totalSteps, 1)
                self.totalSteps = finalSteps
                self.currentStep = finalSteps
                self.stepMessage = "完成しました！"
                
                // UIを少し表示してから遷移（1秒に短縮）
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                self.isGeneratingImages = false
                self.stopTipRotation()
                coordinator.navigateToStorybook(storybookId: storybookId)
                print("✅ ThemeSelectViewModel: 遷移処理完了")
            },
            onFailed: { errorMessage in
                Task { @MainActor in
                    self.errorMessage = errorMessage
                    self.isGeneratingImages = false
                    self.stopTipRotation()
                }
            }
        )
        
        // ポーリングを開始してから同期処理を立ち上げる
        progressMonitor?.startPolling()
        
        // 進捗監視の状態を定期的に更新
        Task {
            await syncProgressFromMonitor()
        }
    }
    
    /// 進捗監視の状態をViewModelに同期
    private func syncProgressFromMonitor() async {
        guard let monitor = progressMonitor else {
            print("❌ syncProgressFromMonitor: monitor is nil")
            return
        }
        
        print("🔄 syncProgressFromMonitor: Started")
        
        // 前回のページ番号を記憶
        var lastPage = 0
        
        // 更新頻度を0.3秒に変更（バッテリー節約とUI負荷軽減）
        let updateInterval: Double = 0.3
        
        while monitor.isGeneratingImages {
            await MainActor.run {
                // 現在の状況を取得
                let currentPage = monitor.currentGeneratingPage
                let totalPages = monitor.totalPages
                let effectivePage = max(currentPage, 1)
                
                // ページ数が変わったらログ出力
                if currentPage != lastPage {
                    print("📄 ThemeSelectViewModel: ページ進行 \(lastPage) -> \(currentPage) (全\(totalPages)ページ)")
                    lastPage = currentPage
                }
                
                // APIからの進捗値（0〜1）を15%-95%の範囲にマッピング
                let rawAPIProgress = 0.15 + (0.80 * monitor.generationProgress)
                let targetFromAPI = min(rawAPIProgress, 0.95)  // 95%で上限
                
                // 進捗の後退を防止（企業レベルのUXパターン）
                let clampedTarget = max(self.progressPercentage, targetFromAPI)
                
                // 95%以上でまだ生成中の場合は99%に設定（完了待ち）
                let finalTarget: Double
                if monitor.generationProgress >= 0.95 && monitor.isGeneratingImages {
                    finalTarget = 0.99
                } else {
                    finalTarget = clampedTarget
                }
                
                print("🔎 Progress: API=\(monitor.generationProgress), mapped=\(targetFromAPI), clamped=\(clampedTarget), final=\(finalTarget)")
                
                // 短い固定時間（0.5秒）で滑らかに追従
                if finalTarget > self.progressPercentage {
                    self.animateProgress(to: finalTarget, totalDurationSec: 0.5)
                }
                
                // 推定残り時間を更新
                self.updateEstimatedTimeRemaining()
                
                // UI表示用のステップ情報を更新
                self.currentStep = effectivePage
                self.totalSteps = totalPages
                
                // 詳細なステップメッセージを生成
                self.stepMessage = self.getDetailedStepMessage(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    currentStep: ""  // 必要に応じてmonitorから取得
                )
            }
            
            try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
        }
        
        print("⏹️ syncProgressFromMonitor: Loop ended (isGeneratingImages=\(monitor.isGeneratingImages))")
        
        // 監視終了後も100%に揃えておく（完了検知が早すぎても表示を確実に100%に）
        await MainActor.run {
            if self.progressPercentage < 1.0 {
                self.progressStepperTask?.cancel()
                self.progressPercentage = 1.0
                self.animateProgress(to: 1.0, totalDurationSec: 0.5)
            }
            // 最終ステップ表示を合わせる
            let finalSteps = monitor.totalPages
            if finalSteps > 0 {
                self.totalSteps = finalSteps
                self.currentStep = finalSteps
                self.stepMessage = "えほんを仕上げています..."
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 詳細なステップメッセージを生成
    private func getDetailedStepMessage(currentPage: Int, totalPages: Int, currentStep: String) -> String {
        if currentPage == 0 {
            return "表紙を描いています..."
        } else if currentPage > totalPages {
            return "えほんを仕上げています..."
        } else {
            // currentStepに応じたメッセージ（将来的に拡張可能）
            switch currentStep {
            case "prompt":
                return "\(currentPage)ページ目のアイデアを考えています..."
            case "api_call":
                return "\(currentPage)ページ目の絵を描いています..."
            case "saving":
                return "\(currentPage)ページ目を仕上げています..."
            default:
                return "絵を描いています... (\(currentPage)/\(totalPages)ページ)"
            }
        }
    }
    
    /// 推定残り時間を更新
    private func updateEstimatedTimeRemaining() {
        guard let startTime = generationStartTime else {
            estimatedTimeRemaining = "処理中..."
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progressMade = progressPercentage
        
        // 10%以上進んでから推定を開始（初期は不安定なため）
        guard progressMade > 0.1 else {
            estimatedTimeRemaining = "計算中..."
            return
        }
        
        let estimatedTotal = elapsed / progressMade
        let remaining = max(0, estimatedTotal - elapsed)
        
        if remaining < 60 {
            estimatedTimeRemaining = "残り約\(Int(remaining))秒"
        } else {
            let minutes = Int(remaining / 60)
            estimatedTimeRemaining = "残り約\(minutes)分"
        }
    }
    
    /// ティップスローテーションを開始
    private func startTipRotation() {
        currentTipIndex = 0
        currentTip = tips[currentTipIndex]
        
        // 5秒ごとにティップスを切り替え
        tipTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // フェードアウト
            withAnimation(.easeOut(duration: 0.3)) {
                self.currentTip = ""
            }
            
            // 0.3秒後に次のティップスを表示（フェードイン）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.currentTipIndex = (self.currentTipIndex + 1) % self.tips.count
                withAnimation(.easeIn(duration: 0.3)) {
                    self.currentTip = self.tips[self.currentTipIndex]
                }
            }
        }
    }
    
    /// ティップスローテーションを停止
    private func stopTipRotation() {
        tipTimer?.invalidate()
        tipTimer = nil
        currentTip = ""
    }
}
