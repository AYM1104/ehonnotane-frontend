import SwiftUI

struct My_Page_View2: View {
    // 環境オブジェクト
    @EnvironmentObject var authManager: AuthManager
    
    // ViewModel
    @StateObject private var viewModel = MyPageViewModel()
    
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
                    .frame(height: 40) // コインセクションとの間隔
                
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
            }
            
            // ヘッダー
            Header()
        }
        .onAppear {
            // ユーザー情報を取得
            Task {
                await viewModel.loadUserInfo()
            }
        }
    }
}

#Preview {
    My_Page_View2()
        .environmentObject(AuthManager())
}
