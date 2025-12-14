import SwiftUI

// インナーカードコンポーネント
struct InnerCard<Content: View>: View {
    private let backgroundColor: Color = Color.white.opacity(0.5)
    var cornerRadius: CGFloat = 35
    var horizontalPadding: CGFloat = 48
    var verticalPadding: CGFloat = 48
    var outerPadding: CGFloat = 16  // 外側の余白
    private let content: () -> Content
    
    // 明示的イニシャライザ（@ViewBuilder 対応）
    init(
        cornerRadius: CGFloat = 35,
        horizontalPadding: CGFloat = 48,
        verticalPadding: CGFloat = 48,
        outerPadding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.outerPadding = outerPadding
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, horizontalPadding) // インナーカード内の左右の余白
        .padding(.vertical, verticalPadding) // インナーカード内の上下の余白
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
                // 外側の余白
                .padding(EdgeInsets(top: outerPadding, leading: outerPadding, bottom: outerPadding, trailing: outerPadding))
        )
    }
}

struct InnerCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }
            
            // ヘッダー
            Header()
            
            VStack {

                // // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // メインテキストを表示
                MainText(text: "どんな えほんを")
                MainText(text: "つくろうかな？")
                Spacer()
            
            
                // メインカードを画面下部に配置
                Spacer()
                mainCard(width: .screen95) {
                    VStack(spacing: 20) {
                        InnerCard {
                            SubText(text:"てすと")
                            }
                        }
                        
                        Spacer()
                    }
                    
                    
                }
                .padding(.bottom, -11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

