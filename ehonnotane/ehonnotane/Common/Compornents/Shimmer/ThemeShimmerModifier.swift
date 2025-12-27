import SwiftUI

// テーマ選択ビューとMyPageで使用するシマーエフェクトのモディファイア
extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ThemeShimmerModifier(isAnimating: isAnimating))
    }
}

struct ThemeShimmerModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
            )
            .clipped()
    }
}

