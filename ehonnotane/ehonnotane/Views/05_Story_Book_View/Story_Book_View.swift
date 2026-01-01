import SwiftUI

struct StoryBookView: View {
    let storybookId: Int
    @State private var storyTitle = "絵本を読み込み中..."
    @StateObject private var viewModel: BookFromAPIModel
    @State private var currentPageIndex: Int = 0
    
    init(
        storybookId: Int,
        storybookService: StorybookService = .shared,
        previewStorybook: StorybookResponse? = nil
    ) {
        self.storybookId = storybookId
        self._viewModel = StateObject(
            wrappedValue: BookFromAPIModel(
                storybookId: storybookId,
                storybookService: storybookService,
                previewStorybook: previewStorybook,
                authManager: .shared,
                onTitleUpdate: nil
            )
        )
    }
    
    var titleFontSize: CGFloat {
        // 文字数が15文字を超える場合は少し小さくする
        storyTitle.count > 15 ? 22 : 28
    }
    
    var body: some View {
        // ヘッダー
        ZStack(alignment: .top) {
            
            // 背景
            Background {}

            // メインコンテンツ
            VStack(spacing: 0) {
                
                // タイトルと上部スペースを管理する固定高さのコンテナ
                VStack(spacing: 0) {
                    Spacer()
                    MainText(text: storyTitle, fontSize: titleFontSize)
                        .padding(.bottom, 4) // 絵本との間隔を維持
                }
                .frame(height: 120) // 高さ固定（ヘッダー考慮）
                
                // メインコンテンツ
                VStack(spacing: 4) {
                    
                    // 絵本エリア
                    if #available(iOS 15.0, *) {
                        ZStack {
                            if viewModel.isLoading {
                                // ローディング画面
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("絵本を読み込んでいます...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            } else if let errorMessage = viewModel.errorMessage {
                                // エラー画面
                                VStack(spacing: 20) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.orange)
                                    Text("エラーが発生しました")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text(errorMessage)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button("再試行") {
                                        Task {
                                            await viewModel.loadStorybook()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            } else if let story = viewModel.story {
                                // 絵本表示画面
                                VStack(spacing: 0) {
                                    if viewModel.isGeneratingImages {
                                        // 画像生成中の進捗表示
                                        VStack(spacing: 20) {
                                            // ページ進捗表示
                                            Text("\(viewModel.currentGeneratingPage)/\(viewModel.totalPages)ページ生成中...")
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
                                    
                                    // 絵本コンテンツ - Bookコンポーネントを直接使用
                                    Book(
                                        pages: viewModel.createBookPages(from: story),
                                        heightRatio: 1.0,
                                        aspectRatio: 0.62, // Adjusted to be tall but fit within screen height
                                        cornerRadius: 30,
                                        paperColor: Color(red: 252/255, green: 252/255, blue: 252/255),
                                        onPageChange: { index in
                                            currentPageIndex = index
                                        }
                                    )
                                    .padding(.horizontal, 0) // Reduced horizontal padding to widen the book
                                    .padding(.top, 0) // Reduced top padding
                                    
                                    Spacer()
                                        .frame(height: 8) // Reduced spacer height
                                        .opacity(viewModel.isGeneratingImages ? 0.7 : 1.0)
                                    
                                    // プログレスバー
                                    ProgressBar(
                                        totalSteps: story.pages.count,
                                        currentStep: currentPageIndex
                                    )
                                    .padding(.top, 8) // Reduced top padding
                                }
                            } else {
                                // 初期状態
                                VStack(spacing: 20) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 50))
                                        .foregroundColor(.primary)
                                    Text("絵本を読み込み中...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .task {
                            // タイトル更新コールバックを設定
                            viewModel.onTitleUpdate = { title in
                                storyTitle = title
                            }
                            await viewModel.loadStorybook()
                        }
                        .refreshable {
                            await viewModel.loadStorybook()
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("iOS 15.0以上が必要です")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("この機能を使用するにはiOS 15.0以上が必要です")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 24)
            }

            // ヘッダー
            Header()
        }
    }
}

#Preview {
    StoryBookView(
        storybookId: 1,
        previewStorybook: .previewSample
    )
    .environmentObject(AuthManager())
    .environmentObject(StorybookService.shared)
}
