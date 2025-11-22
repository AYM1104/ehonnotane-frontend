import SwiftUI

// シンプルなキャラクター画像表示コンポーネント
struct BigCharacter: View {
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                
                Image("Big_Charactor")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geo.size.height * 0.8)
                    .padding(.bottom, 32)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview("デフォルト") {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()
        }
        
        // ヘッダー
//        Header()
//            .environmentObject(AppCoordinator())
    }
}
