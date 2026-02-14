import SwiftUI

struct TitleAnimation: View {
    // アニメーション状態を管理
    @State private var showText = false
    @State private var showGlow = false
    
    // ローカライズされたタイトルの各文字
    private var characters: [String] {
        String(localized: "app.title").map { String($0) }
    }
    
    // 文字数に応じたフォントサイズ（長いほど小さく）
    private var fontSize: CGFloat {
        characters.count <= 8 ? 48 : 28
    }
    
    // 文字数に応じたスペーシング（長いほど詰める）
    private var spacing: CGFloat {
        characters.count <= 8 ? 8 : 2
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, char in
                Text(char)
                    .font(.custom("YuseiMagic-Regular", size: fontSize))
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
                    // 各文字に遅延を設定（文字数が多いほど短く）
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(Double(index) * (characters.count <= 8 ? 0.2 : 0.1)),
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
