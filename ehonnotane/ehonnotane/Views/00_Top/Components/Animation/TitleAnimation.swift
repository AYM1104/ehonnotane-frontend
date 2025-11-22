import SwiftUI

struct TitleAnimation: View {
    // アニメーション状態を管理
    @State private var showText = false
    @State private var showGlow = false
    
    // "えほんのたね" の各文字
    private let characters = ["え", "ほ", "ん", "の", "た", "ね"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, char in
                Text(char)
                    .font(.custom("YuseiMagic-Regular", size: 48))
                    .foregroundColor(Color.white)
                    // 手書き風アニメーション効果
                    .scaleEffect(showText ? 1.0 : 0.5)
                    .opacity(showText ? 1.0 : 0.0)
                    .rotationEffect(.degrees(showText ? 0 : -10))
                    // 光るエフェクト（3層のshadow）
                    .shadow(
                        color: Color.white.opacity(showGlow ? 0.8 : 0.5),
                        radius: showGlow ? 15 : 10
                    )
                    .shadow(
                        color: Color(red: 1, green: 0.78, blue: 0.59).opacity(showGlow ? 0.6 : 0.3),
                        radius: showGlow ? 30 : 20
                    )
                    .shadow(
                        color: Color(red: 1, green: 0.59, blue: 0.39).opacity(showGlow ? 0.4 : 0),
                        radius: showGlow ? 40 : 0
                    )
                    // 各文字に遅延を設定（200ms = 0.2秒ずつ）
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(Double(index) * 0.2),
                        value: showText
                    )
            }
        }
        .onAppear {
            // ロゴアニメーション完了後に文字アニメーション開始（3秒後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showText = true
            }
            
            // 文字が全て表示された後に光るエフェクト開始（3秒 + 1.5秒後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    showGlow = true
                }
            }
        }
    }
}

#Preview {
    TitleAnimation()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
