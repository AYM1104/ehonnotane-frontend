import SwiftUI

// インナーカードコンポーネント
struct InnerCard<Content: View>: View {
    private let backgroundColor: Color = Color.white.opacity(0.5)
    var cornerRadius: CGFloat = 35
    private let content: () -> Content
    
    // 明示的イニシャライザ（@ViewBuilder 対応）
    init(cornerRadius: CGFloat = 35, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
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

