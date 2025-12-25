import SwiftUI

struct My_Page_View2: View {
    // 環境オブジェクト
    @EnvironmentObject var authManager: AuthManager
    
    // ViewModel
    @StateObject private var viewModel = MyPageViewModel()
    
    // 選択されたタブを管理
    @State private var selectedTab: String = "あす"
    
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
                UserNicknameDisplay(
                    nickname: viewModel.username,
                    onEditTap: {
                        // 編集アクション
                        print("編集ボタンがタップされました")
                    }
                )
                
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
                        // クレジット追加アクション
                        print("クレジットを追加するボタンがタップされました")
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
                            value: "12"
                        )
                        
                        // 中央：今月
                        StatItem(
                            label: "今月",
                            value: "6"
                        )
                        
                        // 右：今週
                        StatItem(
                            label: "今週",
                            value: "2"
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
                            // タブ1：あす
                            TabItem(
                                title: "あす",
                                isSelected: selectedTab == "あす",
                                action: {
                                    selectedTab = "あす"
                                }
                            )
                            
                            // タブ2：ゆき
                            TabItem(
                                title: "ゆき",
                                isSelected: selectedTab == "ゆき",
                                action: {
                                    selectedTab = "ゆき"
                                }
                            )
                            
                            // タブ3：たろ
                            TabItem(
                                title: "たろ",
                                isSelected: selectedTab == "たろ",
                                action: {
                                    selectedTab = "たろ"
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // 絵本リスト
                        Spacer()
                            .frame(height: 16) // タブとの間隔
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // サンプルデータ（実際のデータに置き換える）
                                ForEach(0..<4) { index in
                                    BookItem()
                                }
                            }
                            .padding(.horizontal, 24)
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
            // ユーザー情報を取得
            Task {
                await viewModel.loadUserInfo()
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
    private func BookItem() -> some View {
        // 表紙（四角い図形）
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 90, height: 120)
            .cornerRadius(8)
    }
}

#Preview {
    My_Page_View2()
        .environmentObject(AuthManager())
}
