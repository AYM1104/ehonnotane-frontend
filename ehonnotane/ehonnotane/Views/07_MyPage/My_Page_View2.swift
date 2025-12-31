import SwiftUI

struct My_Page_View2: View {
    // 環境オブジェクト
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var coordinator: AppCoordinator
    
    // ViewModel
    @StateObject private var viewModel = MyPageViewModel()
    
    // 選択されたタブを管理（子供の名前で管理）
    @State private var selectedTab: String? = nil
    

    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // ユーザー名
                if viewModel.isLoading {
                    // ローディング中のスケルトン
                    ShimmerSkeletonView()
                } else {
                    UserNicknameDisplay(
                        nickname: viewModel.username,
                        onEditTap: {
                            // 編集アクション
                            print("編集ボタンがタップされました")
                        }
                    )
                }
                
                // ユーザーアイコン表示用のサークル
                Circle()
                    .frame(width: 82, height: 82)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.top, 4)
                
                // コインアイコンとテキスト
                Spacer()
                    .frame(height: 40) // プロフィールセクションとの間隔
                
                HStack(spacing: 16) {
                    Image("icon-coin")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40) // 適切なサイズに調整
                    
                    Text("\(viewModel.balance)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                
                // クレジットを追加するボタン
                Spacer()
                    .frame(height: 25) // コインセクションとの間隔
                
                PrimaryButton(
                    title: "クレジットを追加する",
                    width: nil, // 幅を自動調整
                    fontName: nil, // SFPro（システムフォント）を使用
                    action: {
                        // 価格・プラン選択画面に遷移
                        coordinator.navigateToPrice()
                    }
                )
                .fixedSize() // テキストに合わせた幅に調整
                .padding(.horizontal, 20) // 左右の余白を設定
                
                // 統計セクション
                Spacer()
                    .frame(height: 40) // ボタンセクションとの間隔
                
                VStack() {
                    // タイトル
                    Text("これまでに 育てた たね")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    // 統計カラム
                    HStack(spacing: 12) {
                        // 左：すべて
                        StatItem(
                            label: "すべて",
                            value: "\(viewModel.statistics?.total ?? 0)"
                        )
                        
                        // 中央：今月
                        StatItem(
                            label: "今月",
                            value: "\(viewModel.statistics?.thisMonth ?? 0)"
                        )
                        
                        // 右：今週
                        StatItem(
                            label: "今週",
                            value: "\(viewModel.statistics?.thisWeek ?? 0)"
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // MainCardセクション
                Spacer()
                    .frame(height: 20) // 統計セクションとの間隔
                
                // タイトル
                Text("お気に入りのえほん")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 16) // タイトルとMainCardの間隔
                
                
                // mainCardを画面下部から16pxの位置に配置し、高さを自動調整
                mainCard(width: .screen90, height: nil) {
                    VStack(spacing: 0) {
                        // タブセクション
                        HStack(spacing: 0) {
                            if !viewModel.children.isEmpty {
                                // 子供が登録されている場合：子供の名前に基づいてタブを動的に生成
                                ForEach(viewModel.children) { child in
                                    TabItem(
                                        title: child.name,
                                        isSelected: selectedTab == child.name,
                                        action: {
                                            selectedTab = child.name
                                        }
                                    )
                                }
                            } else {
                                // 子供が登録されていない場合：ユーザー名をタブに表示
                                TabItem(
                                    title: viewModel.username,
                                    isSelected: selectedTab == viewModel.username,
                                    action: {
                                        selectedTab = viewModel.username
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // 絵本リスト
                        Spacer()
                            .frame(height: 16) // タブとの間隔
                        
                        // 選択されたタブに応じてお気に入りをフィルタリング
                        let filteredFavorites: [StoryBookListItem] = {
                            guard let selectedTab = selectedTab else { return viewModel.favoriteBooks }
                            
                            // 子供のタブが選択されている場合
                            if let child = viewModel.children.first(where: { $0.name == selectedTab }) {
                                return viewModel.favoriteBooks.filter { $0.childId == child.id }
                            }
                            
                            // ユーザー名のタブが選択されている場合（child_idがnilのもの）
                            if selectedTab == viewModel.username {
                                return viewModel.favoriteBooks.filter { $0.childId == nil }
                            }
                            
                            return viewModel.favoriteBooks
                        }()
                        
                        
                        Group {
                            if filteredFavorites.isEmpty {
                                // お気に入りが空の場合
                                Text("お気に入りの絵本が登録されていません")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                // お気に入りがある場合
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(filteredFavorites) { book in
                                            BookItem(book: book)
                                                .onTapGesture {
                                                    // 絵本詳細画面に遷移
                                                    coordinator.navigateToStorybook(storybookId: book.id)
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.bottom, 0) // 下の余白
                    }
                }
                .padding(.bottom, 0) // 画面下部から16pxの余白
            }
            
            // ヘッダー
            Header()
        }
//        .ignoresSafeArea()
        .onAppear {
            print("🔵 [My_Page_View2] onAppear が呼ばれました")
            // ユーザー情報を取得
            Task {
                print("🔵 [My_Page_View2] Task開始 - お気に入りを取得します")
                // 毎回、最初にお気に入りを最新化
                if let userId = viewModel.currentUserId {
                    print("🔵 [My_Page_View2] userId取得成功: \(userId)")
                    await viewModel.fetchFavoriteBooks(userId: userId)
                    print("✅ [My_Page_View2] お気に入り取得完了: \(viewModel.favoriteBooks.count)件")
                } else {
                    print("❌ [My_Page_View2] userIdが取得できませんでした")
                }
                
                await viewModel.loadUserInfo()
                
                // 初期状態でタブを選択
                if selectedTab == nil {
                    if !viewModel.children.isEmpty {
                        // 子供が登録されている場合：最初の子供の名前を選択
                        selectedTab = viewModel.children[0].name
                    } else {
                        // 子供が登録されていない場合：ユーザー名を選択
                        selectedTab = viewModel.username
                    }
                }
            }
        }
        .onChange(of: viewModel.children) {
            // 子供のリストが変更されたとき、タブを選択
            if selectedTab == nil {
                if !viewModel.children.isEmpty {
                    // 子供が登録されている場合：最初の子供の名前を選択
                    selectedTab = viewModel.children[0].name
                } else {
                    // 子供が登録されていない場合：ユーザー名を選択
                    selectedTab = viewModel.username
                }
            }
        }
    }
    
    // MARK: - 統計アイテム
    
    @ViewBuilder
    private func StatItem(label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
    }
    
    // MARK: - タブアイテム
    
    @ViewBuilder
    private func TabItem(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // 選択されたタブには緑の下線を表示
                if isSelected {
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 絵本アイテム
    
    @ViewBuilder
    private func BookItem(book: StoryBookListItem) -> some View {
        VStack(spacing: 0) {
            // 表紙画像
            if let coverImageUrl = book.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        // 読み込み中
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 90, height: 120)
                            .cornerRadius(8)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    case .success(let image):
                        // 画像読み込み成功
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 120)
                            .cornerRadius(8)
                            .clipped()
                    case .failure(_):
                        // 画像読み込み失敗
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 90, height: 120)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    @unknown default:
                        // その他の状態
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 90, height: 120)
                            .cornerRadius(8)
                    }
                }
            } else {
                // 画像URLがない場合
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
    }
    
    // MARK: - スケルトンローディング（テーマ選択ビューと同じスタイル）
    
    @ViewBuilder
    private func ShimmerSkeletonView() -> some View {
        SkeletonShimmerView()
    }
}

// MARK: - スケルトンシマービュー（テーマ選択ビューと同じスタイル）

struct SkeletonShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 120, height: 24)
            .shimmer(isAnimating: isAnimating)
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

#Preview {
    // プレビューでは空の状態を表示（Swift Concurrencyの制約のため）
    // 実際にお気に入りの表示を確認するには実機/シミュレーターを使用してください
    My_Page_View2()
        .environmentObject(AuthManager())
        .environmentObject(AppCoordinator())
}



