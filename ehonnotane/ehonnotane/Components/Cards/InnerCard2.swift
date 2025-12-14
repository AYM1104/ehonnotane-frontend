import SwiftUI

// インナーカードコンポーネント
struct InnerCard2<Content: View>: View {

    // プロパティを定義
    private let backgroundColor: Color = Color.white.opacity(0.5)  // 背景色：白色（不透明度50%）
    var cornerRadius: CGFloat  // 角丸
    var horizontalPadding: CGFloat  // 左右の余白
    var verticalPadding: CGFloat  // 上下の余白
    var outerPadding: CGFloat  // 外側の余白
    var expandVertically: Bool  // 縦方向に伸ばすかどうか
    private let content: () -> Content
    
    // イニシャライザを定義
    init(
        // デフォルト値を設定
        cornerRadius: CGFloat = 35,  // 角丸：35px
        horizontalPadding: CGFloat = 48,  // 内側の左右の余白：48px
        verticalPadding: CGFloat = 48,  // 内側の上下の余白：48px
        outerPadding: CGFloat = 16,  // カード外側の余白：16px
        expandVertically: Bool = true,  // デフォルトは縦に伸ばす
        @ViewBuilder content: @escaping () -> Content
    ) {
        // プロパティに値を設定
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.outerPadding = outerPadding
        self.expandVertically = expandVertically
        self.content = content
    }
    
    // 表示内容を定義
    var body: some View {

        // カード内部の組み立て
        VStack(alignment: .leading, spacing: 16) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        // カード内部の余白を設定
        .padding(.horizontal, horizontalPadding) // 左右の余白
        .padding(.vertical, verticalPadding) // 上下の余白

        // カードの幅と高さを設定
        .frame(maxWidth: .infinity, maxHeight: expandVertically ? .infinity : nil, alignment: .topLeading)
        
        // 背景を設定
        .background(
        
            // 背景色
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
        )
    }
}

struct InnerCard2_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            VStack {            
                MainCard(heightStyle: .percent65) {
                    VStack() {
                        MainText(text: "えほんのたね")
                            .font(.title)
                        InnerCard2 {
                            SubText(text:"てすと")
                            }
                        }
                        
                        Spacer()
                    }                
                }
                // 中央配置
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)   
            }
        }
    }


