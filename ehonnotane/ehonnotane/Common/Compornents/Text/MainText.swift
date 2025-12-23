import SwiftUI

/// メインテキストコンポーネント - 輝く効果付きのテキスト表示
struct MainText: View {
    // 表示するテキスト
    let text: String
    // フォントサイズ（デフォルト: 28）
    var fontSize: CGFloat = 28
    // フォント（デフォルト: YuseiMagic-Regular）
    var font: Font? = nil
    // テキストカラー（デフォルト: 白）
    var color: Color = .white
    // 輝く効果を付けるか（デフォルト: true）
    var glowEffect: Bool = true
    // テキストアライメント（デフォルト: center）
    var alignment: TextAlignment = .center
    
    var body: some View {
        Text(text)
            .font(font ?? .custom("YuseiMagic-Regular", size: fontSize))
            .foregroundColor(color)
            .applyGlowEffect(enabled: glowEffect, color: color)
            .multilineTextAlignment(alignment)
    }
}

// 輝く効果を適用するViewModifier
private struct GlowEffect: ViewModifier {
    let enabled: Bool
    let color: Color
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: color.opacity(0.8), radius: 10, x: 0, y: 0)
                .shadow(color: color.opacity(0.6), radius: 20, x: 0, y: 0)
                .shadow(color: color.opacity(0.4), radius: 30, x: 0, y: 0)
        } else {
            content
        }
    }
}

// Viewの拡張 - 輝く効果を簡単に適用できるようにする
private extension View {
    func applyGlowEffect(enabled: Bool, color: Color) -> some View {
        modifier(GlowEffect(enabled: enabled, color: color))
    }
}

#Preview {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()
        }
        MainText(text: "どんな え でえほんを")

            }
    }
