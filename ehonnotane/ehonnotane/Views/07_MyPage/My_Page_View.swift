import SwiftUI

struct My_Page_View: View {
//    @EnvironmentObject var coordinator: AppCoordinator
//    @EnvironmentObject var authService: AuthService
    
    // 選択されたタブを管理
    @State private var selectedTab: String = "あす"
    
    // 選択された統計カテゴリを管理
    @State private var selectedStatCategory: String = "すべて"
    
    // アカウント削除画面の表示フラグ
    @State private var showAccountDeletion = false
    
    var body: some View {
         ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // アイコン、名前、編集ボタン
                HStack {
                    // 左側：アイコンと名前
                    HStack(spacing: 12) {
                        // アイコン
                        Avatar(baseDiameter: 40)
                        // Image(systemName: "person.circle")
                        //     .resizable()
                        //     .frame(width: 40, height: 40)
                        //     .foregroundColor(.white)
                        // 名前
                        // Text(authService.authManager.userInfo?.displayName ?? "てすと たろう")
                        //     .font(.system(size: 20))
                        //     .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 右側：編集ボタン
                    EditButton {
                        // 編集アクション
                        print("編集ボタンがタップされました")
                    }
                }
                .padding(.horizontal, 24)
                
                // コインアイコンとテキスト
                Spacer()
                    .frame(height: 20) // プロフィールセクションとの間隔
                
                HStack(spacing: 16) {
                    Image("icon-coin-white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40) // 適切なサイズに調整
                    
                    Text("600")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                
                // プレゼントとチャージセクション
                Spacer()
                    .frame(height: 24) // コインセクションとの間隔
                
                HStack(spacing: 0) {
                    // 左側：プレゼント
                    VStack(alignment: .center, spacing: 4) {
                        Text("プレゼント")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("300")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 中央の区切り線
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2)
                        .frame(height: 24)
                    
                    // 右側：チャージ
                    VStack(alignment: .center, spacing: 4) {
                        Text("チャージ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("0")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                
                // ボタンセクション
                Spacer()
                    .frame(height: 24) // プレゼント/チャージセクションとの間隔
                
                MyPageButtons(
                    onCharge: {
                        print("コインチャージボタンがタップされました")
                    },
                    onHistory: {
                        print("利用履歴ボタンがタップされました")
                    }
                )
                
                // 統計セクション
                Spacer()
                    .frame(height: 24) // ボタンセクションとの間隔
                
                VStack(spacing: 16) {
                    // タイトル
                    Text("これまでに 育てた たね")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 統計カラム
                    HStack(spacing: 12) {
                        // 左：すべて
                        StatItem(
                            label: "すべて",
                            value: "12",
                            isSelected: selectedStatCategory == "すべて",
                            action: {
                                selectedStatCategory = "すべて"
                            }
                        )
                        
                        // 中央：今月
                        StatItem(
                            label: "今月",
                            value: "6",
                            isSelected: selectedStatCategory == "今月",
                            action: {
                                selectedStatCategory = "今月"
                            }
                        )
                        
                        // 右：今週
                        StatItem(
                            label: "今週",
                            value: "2",
                            isSelected: selectedStatCategory == "今週",
                            action: {
                                selectedStatCategory = "今週"
                            }
                        )
                    }
                }
                // .padding(.vertical, 24)
                .padding(.horizontal, 24)
                
                // お子さま情報を追加ボタン
                Spacer()
                    .frame(height: 24) // 統計セクションとの間隔
                
                Button(action: {
                    print("お子さま情報を追加ボタンがタップされました")
                }) {
                    Text("お子さま情報を追加")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2)) // 半透明の白背景
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 1) // 白枠
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 24)
                
                // タブセクション
                Spacer()
                    .frame(height: 24) // ボタンとの間隔
                
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
                
                // 絵本リスト
                Spacer()
                    .frame(height: 24) // タブとの間隔
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // サンプルデータ（実際のデータに置き換える）
                        ForEach(0..<3) { index in
                            BookItem(
                                title: "タイトルタイトルタイトルタイトル",
                                date: "2025/11/10"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                }
                
                // アカウント削除ボタン
                Spacer()
                    .frame(height: 40)
                
                Button(action: {
                    showAccountDeletion = true
                }) {
                    Text("アカウント削除")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                        .underline()
                }
                .padding(.bottom, 20)
                .fullScreenCover(isPresented: $showAccountDeletion) {
                    AccountDeletionView()
                }
            }
             // ヘッダー
             Header()
        }
    }
    
    // MARK: - 絵本アイテム
    
    @ViewBuilder
    private func BookItem(title: String, date: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル（2行で表示）
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 120, alignment: .leading)
            
            // 表紙（四角い図形）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 100)
                .cornerRadius(8)
            
            // 作成日
            Text(date)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - 統計アイテム
    
    @ViewBuilder
    private func StatItem(label: String, value: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .background(
                // 選択された場合は少し濃い青の背景
                isSelected ? Color(red: 20/255, green: 40/255, blue: 80/255) : Color.clear
            )
            .overlay(
                // 選択された場合は白枠を表示
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
        
    // MARK: - ユーザー名
    @ViewBuilder
    private var userNameView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // ユーザー名を取得（実際のデータがある場合は使用）
            // Text(authService.authManager.userInfo?.displayName ?? "てすと たろう")
            //     .font(.custom("YuseiMagic-Regular", size: 18))
            //     .foregroundColor(.white)
        }
    }


#Preview {
    My_Page_View()
        // .environmentObject(AppCoordinator())
        // .environmentObject(AuthService())
}
