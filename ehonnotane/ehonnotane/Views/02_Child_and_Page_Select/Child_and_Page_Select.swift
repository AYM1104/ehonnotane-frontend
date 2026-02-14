import SwiftUI

struct Child_and_Page_Selection_View: View {
    
    /// アップロード結果（前の画面から渡される）
    var uploadResult: UploadResult?

    // ViewModelを使用
    @StateObject private var viewModel = ChildAndPageSelectViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var showingCreditAlert: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var initialDataLoaded: Bool = false
    
    // ナビゲーション確認用
    @State private var showNavigationAlert: Bool = false
    @State private var pendingNavigationAction: (() -> Void)? = nil
    
    // クリーンアップサービス
    private let cleanupService = StorySettingCleanupService()
    
    var body: some View {
        ZStack(alignment: .top) {

            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }

            if initialDataLoaded {
                mainContent
            } else {
                LoadingOverlay(message: String(localized: "common.loading"))
            }
            
            // ヘッダー（ナビゲーション確認コールバック付き）
            Header(
                onLogoTap: { handleNavigationAttempt { coordinator.navigateToUploadImage() } },
                onBookShelfTap: { handleNavigationAttempt { coordinator.navigateToBookShelf() } },
                onMyPageTap: { handleNavigationAttempt { coordinator.navigateToMyPage() } }
            )
            
            // モーダル表示
            if showingCreditAlert {
                CreditInsufficientModal(
                    isPresented: $showingCreditAlert,
                    requiredCredits: viewModel.requiredCredits,
                    currentCredits: viewModel.currentCredits
                ) {
                    coordinator.navigateToPrice()
                }
                .zIndex(100) // 最前面に表示
            }
        }
        .task {
            await loadInitialData()
        }
        // エラーアラート
        .alert(String(localized: "common.error"), isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        // ナビゲーション確認アラート
        .alert(String(localized: "common.confirmation"), isPresented: $showNavigationAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingNavigationAction = nil
            }
            Button("OK", role: .destructive) {
                Task {
                    await performCleanupAndNavigate()
                }
            }
        } message: {
            Text(String(localized: "theme.navigation_warning"))
        }
    }
    
    // 決定ボタン（共通部品）
    private var decideButton: some View {
        PrimaryButton(
            title: String(localized: "common.confirm_button"),
            style: .primary,
            isLoading: viewModel.isLoading
        ) {
            if viewModel.hasInsufficientCredits {
                showingCreditAlert = true
            } else {
                // 次の画面への遷移処理
                Task {
                    do {
                        if let storySettingId = uploadResult?.storySettingId {
                            try await viewModel.confirmSelection(storySettingId: storySettingId)
                            
                            // 画面遷移（子供が0人の場合はchildIdを0として扱う）
                            if let storyPages = Int(viewModel.selectedPageCount) {
                                // 選択された子供IDを取得（0人または1人の場合はviewModel側で適切に処理済みだが、念のため取得）
                                // confirmSelectionでバリデーション済みなので、ここでは安全に取得できる
                                // Note: viewModel.selectedChildが空でも、子供が0/1人の場合は問題ない
                                let childId = Int(viewModel.selectedChild) ?? 0
                                
                                coordinator.navigateToQuestion(
                                    storySettingId: storySettingId,
                                    childId: childId,
                                    storyPages: storyPages
                                )
                            }
                        } else {
                            print("❌ Upload result is missing")
                            errorMessage = String(localized: "error.upload_not_found")
                            showingErrorAlert = true
                        }
                    } catch {
                        print("❌ Confirmation failed: \(error)")
                        
                        // エラーメッセージの表示
                        // バリデーションエラーの場合はuserInfoからメッセージを取得
                        let nsError = error as NSError
                        if nsError.domain == "Validation" {
                            errorMessage = nsError.localizedDescription
                        } else {
                            errorMessage = "設定の保存に失敗しました: \(error.localizedDescription)"
                        }
                        showingErrorAlert = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            
            // ヘッダーの高さ分のスペースを確保
            Spacer()
                .frame(height: 80)

            // メインテキスト
            MainText(text: String(localized: "theme.title_line1"))
            MainText(text: String(localized: "theme.title_line2"))
            Spacer()
        
                if viewModel.childrenCount >= 2 {
                    // 子供が2人以上の場合はカスタムスライダー形式
                    
                    // ページ定義
                    let pages = [
                        SelectionPage(type: .pageCount),
                        SelectionPage(type: .childSelect)
                    ]
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        PageSlider(pages, currentIndex: $viewModel.currentPageIndex) { page in
                            
                            switch page.type {
                            case .pageCount:
                                // 1ページ目：ページ数選択
                                SelectInputBoxCard(
                                    title: String(localized: "select.page_count_title"),
                                    options: viewModel.availablePageCountOptions,
                                    selection: $viewModel.selectedPageCount,
                                    subTitle: String(localized: "select.consume_credits \(viewModel.requiredCredits)"),
                                    onLockedOptionTap: {
                                        coordinator.navigateToPrice()
                                    }
                                ) {
                                    EmptyView()
                                } footer: {
                                    // ボタンなし（スワイプで次へ）
                                    Spacer().frame(height: 20)
                                }
                                .padding(.horizontal, 4) // カード間の余白調整（PageSliderのspacing考慮）
                                
                            case .childSelect:
                                // 2ページ目：子供選択
                                SelectInputBoxCard(
                                    title: String(localized: "select.child_title"),
                                    options: viewModel.childOptions,
                                    selection: $viewModel.selectedChild,
                                    subTitle: nil
                                ) {
                                    EmptyView()
                                } footer: {
                                    // 決定ボタン
                                    decideButton
                                        .padding(.top, 16)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // ドットプログレスバー
                        ProgressBar(
                            totalSteps: 2,
                            currentStep: viewModel.currentPageIndex,
                            dotSize: 10,
                            spacing: 12
                        )
                        .padding(.bottom, 16)
                        
                        Spacer(minLength: 0)
                    }
                    
                } else {
                    // 子供が1人以下の場合は従来の単一カード表示
                    SelectInputBoxCard(
                        title: String(localized: "select.page_count_title"),
                        options: viewModel.availablePageCountOptions,
                        selection: $viewModel.selectedPageCount,
                        subTitle: String(localized: "select.consume_credits \(viewModel.requiredCredits)"),
                        onLockedOptionTap: {
                            coordinator.navigateToPrice()
                        }
                    ) {
                        EmptyView()
                    } footer: {
                        decideButton
                            .padding(.top, 16)
                    }
                }
            }
            .padding(.bottom, -10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    // スライダー用ページモデル
    private struct SelectionPage: Identifiable {
        let id = UUID()
        let type: PageType
    }
    
    private enum PageType {
        case pageCount
        case childSelect
    }
    
    @MainActor
    private func loadInitialData() async {
        // 毎回データをリロードする
        await viewModel.loadChildren()
        // story_setting_idを設定（uploadResultから取得）
        if let storySettingId = uploadResult?.storySettingId {
            viewModel.storySettingId = storySettingId
        }
        initialDataLoaded = true
    }
    
    // MARK: - Navigation Handling
    
    /// ナビゲーション試行をハンドルし、確認アラートを表示
    private func handleNavigationAttempt(_ action: @escaping () -> Void) {
        pendingNavigationAction = action
        showNavigationAlert = true
    }
    
    /// クリーンアップを実行してからナビゲーション
    private func performCleanupAndNavigate() async {
        guard let storySettingId = viewModel.storySettingId else {
            print("⚠️ story_setting_idが見つかりません。クリーンアップをスキップします")
            pendingNavigationAction?()
            pendingNavigationAction = nil
            return
        }
        
        do {
            print("🗑️ Story Setting削除開始: ID=\(storySettingId)")
            _ = try await cleanupService.deleteStorySetting(storySettingId: storySettingId)
            print("✅ Story Setting削除完了")
        } catch {
            print("❌ Story Setting削除エラー: \(error)")
            // エラーでも遷移は実行（ユーザーの意図を尊重）
        }
        
        // 保留中のナビゲーションアクションを実行
        pendingNavigationAction?()
        pendingNavigationAction = nil
    }
}

// プレビュー専用のラッパービュー（モックViewModelを使用）
struct Child_and_Page_Selection_View_Preview: View {
    @StateObject private var viewModel = ChildAndPageSelectViewModel(
        mockMode: true,
        mockChildrenCount: 2,
        mockCredits: 200
    )
    @StateObject private var coordinator = AppCoordinator()
    
    @State private var showingCreditAlert: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }

            // メインコンテンツ        
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // メインテキスト
                MainText(text: String(localized: "theme.title_line1"))
                MainText(text: String(localized: "theme.title_line2"))
                Spacer()          
            
                // メインカード
                mainCard(width: .screen95) {
                    
                    if viewModel.childrenCount >= 2 {
                    // 子供が2人以上の場合はカスタムスライダー形式
                    
                    // ページ定義
                    let pages = [
                        SelectionPage(type: .pageCount),
                        SelectionPage(type: .childSelect)
                    ]
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        PageSlider(pages, currentIndex: $viewModel.currentPageIndex) { page in
                            
                            switch page.type {
                            case .pageCount:
                                // 1ページ目：ページ数選択
                                SelectInputBoxCard(
                                    title: String(localized: "select.page_count_title"),
                                    options: viewModel.availablePageCountOptions,
                                    selection: $viewModel.selectedPageCount,
                                    subTitle: String(localized: "select.consume_credits \(viewModel.requiredCredits)")
                                ) {
                                    EmptyView()
                                } footer: {
                                    // ボタンなし（スワイプで次へ）
                                    Spacer().frame(height: 20)
                                }
                                .padding(.horizontal, 4)
                                
                            case .childSelect:
                                // 2ページ目：子供選択
                                SelectInputBoxCard(
                                    title: String(localized: "select.child_title"),
                                    options: viewModel.childOptions,
                                    selection: $viewModel.selectedChild,
                                    subTitle: nil
                                ) {
                                    EmptyView()
                                } footer: {
                                    // 決定ボタン
                                    PrimaryButton(
                                        title: String(localized: "common.confirm_button"),
                                        style: .primary,
                                        isLoading: viewModel.isLoading
                                    ) {
                                        // プレビュー用アクション
                                    }
                                    .padding(.top, 16)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // ドットプログレスバー
                        ProgressBar(
                            totalSteps: 2,
                            currentStep: viewModel.currentPageIndex,
                            dotSize: 10,
                            spacing: 12
                        )
                        .padding(.bottom, 16)
                        
                        Spacer(minLength: 0)
                    }
                    
                } else {
                    // 子供が1人以下の場合は従来の単一カード表示
                    SelectInputBoxCard(
                        title: String(localized: "select.page_count_title"),
                        options: viewModel.availablePageCountOptions,
                        selection: $viewModel.selectedPageCount,
                        subTitle: String(localized: "select.consume_credits \(viewModel.requiredCredits)")
                    ) {
                        EmptyView()
                    } footer: {
                        PrimaryButton(
                            title: String(localized: "common.confirm_button"),
                            style: .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            // プレビュー用アクション
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .padding(.bottom, -10)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        
        // ヘッダー
        Header()
        
        // モーダル表示
        if showingCreditAlert {
            CreditInsufficientModal(
                isPresented: $showingCreditAlert,
                requiredCredits: viewModel.requiredCredits,
                currentCredits: viewModel.currentCredits
            ) {
                print("クレジットを追加 tapped")
            }
            .zIndex(100)
        }
    }
    }
    
    // スライダー用ページモデル（プレビュー用）
    private struct SelectionPage: Identifiable {
        let id = UUID()
        let type: PageType
    }
    
    private enum PageType {
        case pageCount
        case childSelect
    }
}

#Preview {
    Child_and_Page_Selection_View_Preview()
}
