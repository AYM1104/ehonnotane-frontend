import SwiftUI

/// PrimaryButtonコンポーネント
enum PrimaryButtonStyle {
    case primary    // グラデーション背景
    case secondary  // 白背景
    case black      // 黒背景
    case google     // Google背景 (#F2F2F2)
    case line       // LINE背景 (#06C755)
}

struct PrimaryButton: View {
    // MARK: - Properties
    
    /// ボタンに表示するテキスト
    let title: String
    
    /// ボタンのスタイル（primary: グラデーション、secondary: 白背景）
    var style: PrimaryButtonStyle = .primary
    
    /// ボタンが無効かどうか
    var disabled: Bool = false
    
    /// ロード中かどうか
    var isLoading: Bool = false
    
    /// ボタンの幅
    var width: CGFloat? = 224
    
    /// フォント名
    var fontName: String? = "YuseiMagic-Regular"
    
    /// フォントサイズ
    var fontSize: CGFloat = 20
    
    /// 水平方向のパディング
    var horizontalPadding: CGFloat = 16
    
    /// 垂直方向のパディング
    var verticalPadding: CGFloat = 10
    
    /// ボタンの高さ
    var height: CGFloat = 48
    
    /// ボタン左側に表示するロゴ画像名（nilの場合は表示しない）
    var logoImageName: String? = nil
    
    /// ロゴ画像のサイズ
    var logoSize: CGFloat = 24
    
    /// テキストの配置（デフォルトは中央配置）
    var textAlignment: TextAlignment = .center
    
    /// ボタンタップ時のアクション
    var action: () -> Void
    
    // MARK: - State
    
    /// ボタンが押されているかどうか
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if !disabled && !isLoading {
                action()
            }
        }) {
            ZStack {
                HStack(alignment: .center, spacing: 12) {
                    // 中央配置または右揃えの場合は左側にSpacerを配置
                    if textAlignment == .center || textAlignment == .trailing {
                        Spacer()
                    }
                    
                    // ロゴ画像
                    if let logoImageName = logoImageName {
                        Image(logoImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: logoSize, height: logoSize)
                    }
                    
                    // テキスト
                    Text(title)
                        .font(fontName != nil ? .custom(fontName!, size: fontSize) : .system(size: fontSize, weight: .medium))
                        .foregroundColor(style == .primary || style == .black || style == .line ? .white : Color(red: 54/255, green: 45/255, blue: 48/255)) // SubTextと同じ色 (#362D30)
                        .multilineTextAlignment(textAlignment)
                    
                    // 中央配置または左揃えの場合は右側にSpacerを配置
                    if textAlignment == .center || textAlignment == .leading {
                        Spacer()
                    }
                }
                .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .primary || style == .black || style == .line ? .white : Color(red: 54/255, green: 45/255, blue: 48/255)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(height: height)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
            .shadow(
                color: style == .primary ? Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5) : (style == .black ? Color.black.opacity(0.3) : (style == .line ? Color(red: 6/255, green: 199/255, blue: 85/255).opacity(0.3) : (style == .google ? Color.black.opacity(0.1) : Color.black.opacity(0.1)))),
                radius: style == .primary ? 15 : (style == .black ? 8 : (style == .line ? 8 : (style == .google ? 5 : 5))),
                x: 0,
                y: style == .primary ? 5 : (style == .black ? 3 : (style == .line ? 3 : (style == .google ? 2 : 2)))
            )
        }
        .modifier(WidthModifier(width: width)) // widthに応じて適切なframeを適用
        .opacity(disabled ? 0.5 : 1.0)
        .allowsHitTesting(!disabled && !isLoading)
        // プレス時の縮小効果
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        // プレスジェスチャー
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !disabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    // MARK: - Width Modifier
    
    /// widthに応じて適切なframeを適用するViewModifier
    private struct WidthModifier: ViewModifier {
        let width: CGFloat?
        
        func body(content: Content) -> some View {
            if let width = width {
                content.frame(width: width)
            } else {
                content.frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            // グラデーション背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
                    Color(red: 20/255, green: 184/255, blue: 166/255), // teal-500
                    Color(red: 6/255, green: 182/255, blue: 212/255)   // cyan-500
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                // 光るボーダーエフェクト
                RoundedRectangle(cornerRadius: height / 2)
                    .strokeBorder(
                        Color(red: 110/255, green: 231/255, blue: 183/255).opacity(0.5),
                        lineWidth: 1
                    )
            )
        case .secondary:
            // インナーカードと同じスタイルの背景
            Color.white.opacity(0.5)
                .overlay(
                    // メインカードと同じスタイルの白い枠線
                    // より光らせるために不透明度を上げてグロー効果を追加
                    RoundedRectangle(cornerRadius: height / 2)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2.5)
                        .shadow(color: Color.white.opacity(0.8), radius: 4, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.6), radius: 8, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.4), radius: 12, x: 0, y: 0)
                )
        case .black:
            // 黒背景
            Color.black
        case .google:
            // Google背景 (#F2F2F2)
            Color(red: 242/255, green: 242/255, blue: 242/255)
        case .line:
            // LINE背景 (#06C755)
            Color(red: 6/255, green: 199/255, blue: 85/255)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        PrimaryButton(
            title: "プライマリーボタン",
            style: .primary,
            fontSize: 14,
            action: {
                print("プライマリーボタンがタップされました")
            }
        )
        
        PrimaryButton(
            title: "セカンダリーボタン",
            style: .secondary,
            fontSize: 14,
            action: {
                print("セカンダリーボタンがタップされました")
            }
        )
        
        HStack(spacing: 12) {
            PrimaryButton(
                title: "プライマリー",
                style: .primary,
                fontSize: 14,
                action: {
                    print("プライマリーボタンがタップされました")
                }
            )
            .frame(maxWidth: .infinity)
            
            PrimaryButton(
                title: "セカンダリー",
                style: .secondary,
                fontSize: 14,
                action: {
                    print("セカンダリーボタンがタップされました")
                }
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        
        HStack(spacing: 12) {
                            // 後にするボタン
                            PrimaryButton(
                                title: "後にする",
                                style: .secondary,
                                width: nil, // 幅を自動調整
                                fontSize: 14,
                                height: 44,
                                action: {
                                    print("セカンダリーボタンがタップされました")
                                }
                                
                            )
                            
                            // チャージするボタン
                            PrimaryButton(
                                title: "チャージする",
                                style: .primary,
                                width: nil, // 幅を自動調整
                                fontSize: 14,
                                height: 44,
                                action: {
                                    print("セカンダリーボタンがタップされました")
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
    }
    .padding()
}

