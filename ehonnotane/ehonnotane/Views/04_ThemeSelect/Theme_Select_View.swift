import SwiftUI
import Combine

// テーマ選択ビュー
struct Theme_Select_View: View {
    @StateObject private var viewModel = ThemeSelectViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    
    @State private var currentPageIndex = 0
    
    // ナビゲーション確認用
    @State private var showNavigationAlert: Bool = false
    @State private var pendingNavigationAction: (() -> Void)? = nil
    
    // エラーアラート表示用
    @State private var showErrorAlert: Bool = false
    
    // クリーンアップサービス
    private let cleanupService = StorySettingCleanupService()
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }

            // メインコンテンツ           
            VStack {
                
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // メインテキストを表示
                MainText(text: String(localized: "theme.title_line1"))
                MainText(text: String(localized: "theme.title_line2"))
                Spacer()
            
                // メインカード
                mainCard(width: .screen95) {
                    VStack {
                        if viewModel.isLoading {
                            // 読み込み中 - スケルトンローディング表示
                            ThemeSkeletonView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.themePages.isEmpty {
                            // データなしまたはエラー
                            VStack(spacing: 20) {
                                if let error = viewModel.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    Text(String(localized: "theme.no_themes"))
                                        .foregroundColor(.gray)
                                }
                                
                                Button(String(localized: "common.reload")) {
                                    Task {
                                        await viewModel.loadThemeData(coordinator: coordinator)
                                    }
                                }
                                .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // テーマデータがある場合
                            VStack(spacing: 16) {
                                // PageSliderでスライド機能を実装
                                PageSlider(viewModel.themePages, currentIndex: $currentPageIndex) { page in
                                    // インナーカードを表示
                                    ThemeDetailCard(
                                        page: page,
                                        isGeneratingImages: viewModel.isGeneratingImages,
                                        onSelect: {
                                            Task {
                                                await viewModel.selectTheme(page: page, coordinator: coordinator)
                                            }
                                        }
                                    )
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // プログレスバーを表示
                                ProgressBar(
                                    totalSteps: viewModel.themePages.count,
                                    currentStep: currentPageIndex
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer()
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
            
            // 生成中プログレスオーバーレイ（画面中央モーダル）
            if viewModel.isGeneratingImages {
                EnhancedGenerationProgressView(
                    progress: viewModel.progressPercentage,
                    message: viewModel.stepMessage,
                    estimatedTime: viewModel.estimatedTimeRemaining,
                    currentTip: viewModel.currentTip,
                    totalPages: viewModel.totalSteps,
                    currentPage: viewModel.currentStep,
                    generatedPreviews: viewModel.generatedPagePreviews
                )
                .transition(.opacity)
            }
            
            // クレジット不足モーダル
            if viewModel.showCreditInsufficientModal {
                CreditInsufficientModal(
                    isPresented: $viewModel.showCreditInsufficientModal,
                    requiredCredits: viewModel.requiredCredits,
                    currentCredits: viewModel.currentCredits,
                    onAddCredit: {
                        coordinator.navigateToPrice()
                    }
                )
            }
            

        }
        .onAppear {
            Task {
                await viewModel.loadThemeData(coordinator: coordinator)
            }
        }
        // エラーメッセージの変更を監視してアラート表示
        .onChange(of: viewModel.errorMessage) { oldValue, newValue in
            if newValue != nil && !viewModel.isGeneratingImages {
                showErrorAlert = true
            }
        }
        // エラーアラート（テーマデータがあっても表示される）
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("リトライ") {
                if currentPageIndex < viewModel.themePages.count {
                    let page = viewModel.themePages[currentPageIndex]
                    Task {
                        viewModel.errorMessage = nil
                        await viewModel.selectTheme(page: page, coordinator: coordinator)
                    }
                }
            }
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
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

struct Theme_Select_View_Previews: PreviewProvider {
    static var previews: some View {
        // 通常のプレビュー
        Theme_Select_View()
            .environmentObject(AppCoordinator())
        
        // ローディング状態のプレビュー
        Theme_Select_View_Loading_Preview()
            .environmentObject(AppCoordinator())
    }
}

// ローディング状態を表示するプレビュー
struct Theme_Select_View_Loading_Preview: View {
    @StateObject private var viewModel: ThemeSelectViewModel = {
        let vm = ThemeSelectViewModel()
        vm.isLoading = true
        return vm
    }()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    @State private var currentPageIndex = 0
    
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

                // メインテキストを表示
                MainText(text: String(localized: "theme.title_line1"))
                MainText(text: String(localized: "theme.title_line2"))
                Spacer()
            
                // メインカード
                mainCard(width: .screen95) {
                    VStack {
                        if viewModel.isLoading {
                            // 読み込み中 - スケルトンローディング表示
                            ThemeSkeletonView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.themePages.isEmpty {
                            // データなしまたはエラー
                            VStack(spacing: 20) {
                                if let error = viewModel.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    Text(String(localized: "theme.no_themes"))
                                        .foregroundColor(.gray)
                                }
                                
                                Button(String(localized: "common.reload")) {
                                    Task {
                                        await viewModel.loadThemeData(coordinator: coordinator)
                                    }
                                }
                                .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // テーマデータがある場合
                            VStack(spacing: 16) {
                                // PageSliderでスライド機能を実装
                                PageSlider(viewModel.themePages, currentIndex: $currentPageIndex) { page in
                                    // インナーカードを表示
                                    ThemeDetailCard(
                                        page: page,
                                        isGeneratingImages: viewModel.isGeneratingImages,
                                        onSelect: {
                                            Task {
                                                await viewModel.selectTheme(page: page, coordinator: coordinator)
                                            }
                                        }
                                    )
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // プログレスバーを表示
                                ProgressBar(
                                    totalSteps: viewModel.themePages.count,
                                    currentStep: currentPageIndex
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.bottom, -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // ヘッダー
            Header()
        }
    }
}

// スケルトンローディングビュー
struct ThemeSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        // インナーカード
        InnerCard {
            VStack(spacing: 16) {
                // タイトルのスケルトン
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shimmer(isAnimating: isAnimating)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                
                // コンテンツのスケルトン（インナーカード内にさらにインナーカードを配置）
                InnerCard(
                    cornerRadius: 20,
                    horizontalPadding: 8,
                    verticalPadding: 8,
                    outerPadding: 0
                ) {
                    VStack(spacing: 12) {
                        // 複数のテキスト行のスケルトン
                        ForEach(0..<6, id: \.self) { index in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 16)
                                    .frame(width: index == 5 ? 120 : nil) // 最後の行は短く
                                    .shimmer(isAnimating: isAnimating)
                                
                                if index < 5 {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // ボタンのスケルトン
                VStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.2)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 40)
                        .shimmer(isAnimating: isAnimating)
                }
                .frame(height: 40)
                .padding(.top, 12)
            }
            .padding(.vertical, 0)
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

