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
                LoadingOverlay(message: "読み込み中...")
            }
        }
        .task {
            await loadInitialData()
        }
        // エラーアラート
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        // ナビゲーション確認アラート
        .alert("確認", isPresented: $showNavigationAlert) {
            Button("キャンセル", role: .cancel) {
                pendingNavigationAction = nil
            }
            Button("OK", role: .destructive) {
                Task {
                    await performCleanupAndNavigate()
                }
            }
        } message: {
            Text("これまでの操作が保存されずに画面が移動します。よろしいですか？")
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            
            // ヘッダーの高さ分のスペースを確保
            Spacer()
                .frame(height: 80)

            // メインテキスト
            MainText(text: "どんな えほんを")
            MainText(text: "つくろうかな？")
            Spacer()
        
            // メインカード
            mainCard(width: .screen95) {

                // インナーカード
                SelectInputBoxCard(
                    title: "ページ数をえらんでね",
                    options: viewModel.availablePageCountOptions,
                    selection: $viewModel.selectedPageCount,
                    subTitle: "消費クレジット: \(viewModel.requiredCredits)"
                ) {
                    // お子さまを選択 (2人以上の場合のみ表示)
                    if viewModel.childrenCount >= 2 {
                        VStack(spacing: 12) {
                            SubText(text: "お子さまをえらんでね")
                            Select_Input_Box(
                                options: viewModel.childOptions,
                                answer: $viewModel.selectedChild
                            )
                            .frame(maxWidth: 360)
                        }
                    }
                } footer: {
                    // ボタン
                    PrimaryButton(
                        title: "これにけってい",
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
                                            let childId = Int(viewModel.selectedChild) ?? 0
                                            coordinator.navigateToQuestion(
                                                storySettingId: storySettingId,
                                                childId: childId,
                                                storyPages: storyPages  
                                            )
                                        }
                                    } else {
                                        print("❌ Upload result is missing")
                                        errorMessage = "アップロード情報が見つかりません"
                                        showingErrorAlert = true
                                    }
                                } catch {
                                    print("❌ Confirmation failed: \(error)")
                                    errorMessage = "設定の保存に失敗しました: \(error.localizedDescription)"
                                    showingErrorAlert = true
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .padding(.bottom, -10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        
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
                // TODO: クレジット追加画面への遷移
                print("クレジットを追加 tapped")
            }
            .zIndex(100) // 最前面に表示
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        guard !initialDataLoaded else { return }
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
                MainText(text: "どんな えほんを")
                MainText(text: "つくろうかな？")
                Spacer()          
            
                // メインカード
                mainCard(width: .screen95) {

                    // インナーカード
                    SelectInputBoxCard(
                        title: "ページ数をえらんでね",
                        options: viewModel.availablePageCountOptions,
                        selection: $viewModel.selectedPageCount,
                        subTitle: "消費クレジット: \(viewModel.requiredCredits)"
                    ) {
                        // お子さまを選択 (2人以上の場合のみ表示)
                        if viewModel.childrenCount >= 2 {
                            VStack(spacing: 12) {
                                SubText(text: "お子さまをえらんでね")
                                Select_Input_Box(
                                    options: viewModel.childOptions,
                                    answer: $viewModel.selectedChild
                                )
                                .frame(maxWidth: 360)
                            }
                        }
                    } footer: {
                        // ボタン
                        PrimaryButton(
                            title: "これにけってい",
                            style: .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            // プレビューでは何もしない
                        }
                        .padding(.top, 16)
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
        // エラーアラート
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    Child_and_Page_Selection_View_Preview()
}
