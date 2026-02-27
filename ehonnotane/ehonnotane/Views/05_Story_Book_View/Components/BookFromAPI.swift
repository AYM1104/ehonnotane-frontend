import SwiftUI
import Combine
import Foundation

// MARK: - APIから取得した絵本データを表示するビュー

/// APIから取得した絵本データを表示するビューの共通ロジック
@available(iOS 15.0, macOS 12.0, *)
class BookFromAPIModel: ObservableObject {
    // storybookIdを動的に受け取る
    private let storybookId: Int
    private let storybookService: StorybookService
    private let previewStorybook: StorybookResponse?
    private let authManager: AuthManager?  // ログインしていなくてもプレビューが見れるようにオプショナルに
    @Published var storybook: StorybookResponse?
    @Published var story: Story?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPageIndex: Int = 0
    
    // 画像生成進捗監視
    private var progressMonitor: ImageGenerationProgressMonitor?
    
    // タイトル更新コールバック（オプショナル）
    var onTitleUpdate: ((String) -> Void)?
    
    init(
        storybookId: Int,
        storybookService: StorybookService = .shared,
        previewStorybook: StorybookResponse? = nil,
        authManager: AuthManager? = nil,
        onTitleUpdate: ((String) -> Void)? = nil
    ) {
        self.storybookId = storybookId
        self.storybookService = storybookService
        self.previewStorybook = previewStorybook
        // ログインしていなくてもプレビューが見れるようにauthManagerをオプショナルに
        self.authManager = authManager
        self.onTitleUpdate = onTitleUpdate
    }
    
    // タイトルを外部から取得できるように公開
    var storyTitle: String {
        storybook?.title ?? String(localized: "book.loading_title")
    }
    
    /// 絵本データを読み込む
    func loadStorybook(retryCount: Int = 0) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // プレビュー専用のダミーデータがあればネットワーク通信をスキップ
        if let previewStorybook, ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            await MainActor.run {
                self.storybook = previewStorybook
                self.story = Story(from: previewStorybook)
                self.onTitleUpdate?(previewStorybook.title)
                self.isLoading = false
            }
            return
        }
        
        do {
            print("📚 Loading storybook with ID: \(storybookId)")
            
            let response = try await storybookService.fetchStorybook(storybookId: storybookId)
            
            DispatchQueue.main.async {
                self.storybook = response
                self.story = Story(from: response)
                
                // タイトルを更新
                self.onTitleUpdate?(response.title)
                
                print("✅ Storybook loaded successfully")
                print("📖 Title: \(response.title)")
                print("📄 Number of pages: \(self.story?.pages.count ?? 0)")
                print("🖼️ Image generation status: \(response.imageGenerationStatus)")
                
                // 画像生成状態をチェック
                if self.storybookService.isGeneratingImages(response) {
                    // 進捗監視を開始
                    self.startProgressMonitoring()
                }
                
                self.isLoading = false
            }
            
        } catch {
            // 500エラーの場合は自動リトライ（最大3回）
            if let apiError = error as? StorybookAPIError,
               case .serverError(let code, _) = apiError,
               code == 500, retryCount < 3 {
                print("🔄 500エラー - 自動リトライ (\(retryCount + 1)/3)...")
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
                await loadStorybook(retryCount: retryCount + 1)
                return
            }
            
            DispatchQueue.main.async {
                print("❌ Error loading storybook: \(error)")
                self.errorMessage = error.localizedDescription
                self.onTitleUpdate?(String(localized: "common.error_occurred"))
                self.isLoading = false
            }
        }
    }
    
    /// 画像生成の進捗監視を開始
    func startProgressMonitoring() {
        // 既存の監視を停止
        progressMonitor?.stopPolling()
        
        // 新しい監視を開始
        progressMonitor = ImageGenerationProgressMonitor(
            storybookId: storybookId,
            storybookService: storybookService,
            onCompleted: {
                // 完了時にデータを再読み込み
                await self.loadStorybook()
            },
            onFailed: { errorMessage in
                self.errorMessage = errorMessage
            }
        )
        
        progressMonitor?.startPolling()
    }
    
    /// 進捗監視を停止
    func stopProgressMonitoring() {
        progressMonitor?.stopPolling()
        progressMonitor = nil
    }
    
    // 進捗監視の状態を取得するためのcomputed properties
    var isGeneratingImages: Bool {
        progressMonitor?.isGeneratingImages ?? false
    }
    
    var generationProgress: Double {
        progressMonitor?.generationProgress ?? 0.0
    }
    
    var currentGeneratingPage: Int {
        progressMonitor?.currentGeneratingPage ?? 0
    }
    
    var totalPages: Int {
        progressMonitor?.totalPages ?? 6
    }
    
    var generationMessage: String {
        progressMonitor?.generationMessage ?? String(localized: "book.generating_images")
    }
    
    /// StoryからBookページを作成
    func createBookPages(from story: Story) -> [AnyView] {
        return StoryPageViewFactory.createBookPages(from: story, authManager: authManager)
    }
}

/// APIから取得した絵本データを表示するビュー
//@available(iOS 15.0, macOS 12.0, *)
public struct BookFromAPI: View {
    @StateObject private var viewModel: BookFromAPIModel
    
    public init(storybookId: Int, storybookService: StorybookService = .shared) {
        self._viewModel = StateObject(
            wrappedValue: BookFromAPIModel(
                storybookId: storybookId,
                storybookService: storybookService
            )
        )
    }
    
    public var body: some View {
        BookFromAPIView(viewModel: viewModel)
    }
}

/// タイトル更新コールバック付きのBookFromAPI
@available(iOS 15.0, macOS 12.0, *)
public struct BookFromAPIWithTitleUpdate: View {
    @StateObject private var viewModel: BookFromAPIModel
    
    public init(
        storybookId: Int,
        storybookService: StorybookService = .shared,
        authManager: AuthManager? = nil,
        onTitleUpdate: @escaping (String) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: BookFromAPIModel(
                storybookId: storybookId,
                storybookService: storybookService,
                authManager: authManager,
                onTitleUpdate: onTitleUpdate
            )
        )
    }
    
    public var body: some View {
        BookFromAPIView(viewModel: viewModel)
    }
}

/// 共通のビュー実装
@available(iOS 15.0, macOS 12.0, *)
private struct BookFromAPIView: View {
    @ObservedObject var viewModel: BookFromAPIModel
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                // ローディング画面
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(String(localized: "book.loading_message"))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                // エラー画面
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(String(localized: "common.error_occurred"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(String(localized: "common.retry")) {
                        Task {
                            await viewModel.loadStorybook()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let story = viewModel.story {
                // 絵本表示画面
                VStack {
                    if viewModel.isGeneratingImages {
                        // 画像生成中の進捗表示
                        VStack(spacing: 20) {
                            // 円形プログレスインジケーター
//                            CircularProgressIndicator(
//                                progress: viewModel.generationProgress,
//                                totalDots: 24,
//                                completedColor: .white, // 白（進捗済み）
//                                pendingColor: Color(red: 0.4, green: 0.4, blue: 0.5), // 暗いグレー（未進捗）
//                                radius: 50,
//                                dotSize: 6
//                            )
                            
                            // ページ進捗表示
                            Text(String(localized: "book.generating_pages \(viewModel.currentGeneratingPage) \(viewModel.totalPages)"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // 下部の短い横棒
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.2))
                                .frame(width: 60, height: 4)
                        }
                        .padding()
                        .padding(.top, 20)
                    }
                    
                    // 絵本コンテンツ
                    Book(
                        pages: viewModel.createBookPages(from: story),
                        // title: story.title,
                        heightRatio: 1.0,
                        cornerRadius: 50,
                        paperColor: Color(red: 252/255, green: 252/255, blue: 252/255),
                        onPageChange: { index in
                            viewModel.currentPageIndex = index
                        }
                    )
                    .padding(.horizontal, 10)
                    .opacity(viewModel.isGeneratingImages ? 0.7 : 1.0)
                    
                    // プログレスバー
                    ProgressBar(
                        totalSteps: story.pages.count,
                        currentStep: viewModel.currentPageIndex
                    )
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 初期状態
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .foregroundColor(.primary)
                    Text(String(localized: "book.loading_title"))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadStorybook()
        }
        .refreshable {
            await viewModel.loadStorybook()
        }
    }
}
