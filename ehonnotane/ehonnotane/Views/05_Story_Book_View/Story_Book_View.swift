import SwiftUI

struct StoryBookView: View {
    let storybookId: Int
    @State private var storyTitle = "絵本を読み込み中..."
    @StateObject private var viewModel: BookFromAPIModel
    @State private var currentPageIndex: Int = 0
    
    init(storybookId: Int) {
        self.storybookId = storybookId
        self._viewModel = StateObject(
            wrappedValue: BookFromAPIModel(
                storybookId: storybookId,
                onTitleUpdate: nil
            )
        )
    }
    
    var body: some View {
        // ヘッダー
        ZStack(alignment: .top) {
            // 背景
            Background {}

            // ヘッダー
            Header()

            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインコンテンツ
                VStack(spacing: 30) {
                    // 絵本のタイトル
                    MainText(text: storyTitle)
                    
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if let story = viewModel.story {
                                // 絵本表示画面
                                VStack {
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
                                        cornerRadius: 30,
                                        paperColor: Color(red: 252/255, green: 252/255, blue: 252/255),
                                        onPageChange: { index in
                                            currentPageIndex = index
                                        }
                                    )
                                    .padding(.horizontal, 10)
                                    .opacity(viewModel.isGeneratingImages ? 0.7 : 1.0)
                                    
                                    // プログレスバー
                                    ProgressBar(
                                        totalSteps: story.pages.count,
                                        currentStep: currentPageIndex
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
                                    Text("絵本を読み込み中...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                
                Spacer()
            }
        }
    }
}



#Preview {
    StoryBookView(storybookId: 1)
        .environmentObject(AuthManager.shared)
        .environmentObject(StorybookService.shared)
}

