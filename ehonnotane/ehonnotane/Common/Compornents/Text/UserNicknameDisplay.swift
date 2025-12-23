import SwiftUI

/// ユーザーのニックネーム表示コンポーネント（編集アイコン付き）
struct UserNicknameDisplay: View {
    // ニックネーム
    let nickname: String
    // フォントサイズ（デフォルト: 16）
    var fontSize: CGFloat = 16
    // フォントウェイト（デフォルト: semibold）
    var fontWeight: Font.Weight = .semibold
    // アイコンサイズ（デフォルト: 16）
    var iconSize: CGFloat = 16
    // テキストとアイコンの間隔（デフォルト: 8）
    var spacing: CGFloat = 8
    // 編集アイコンタップ時のアクション
    var onEditTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: spacing) {
            MainText(text: nickname, font: .system(size: fontSize, weight: fontWeight))
            
            Image("icon_pencil")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .onTapGesture {
                    onEditTap?()
                }
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Background {}
        
        VStack {
            Spacer()
                .frame(height: 80)
            
            UserNicknameDisplay(
                nickname: "あゆ",
                onEditTap: {
                    print("編集ボタンがタップされました")
                }
            )
            
            Spacer()
        }
        
        Header()
    }
}

