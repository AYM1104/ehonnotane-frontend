import SwiftUI

// MARK: - カードサイズ定義

/// カードの幅を決める
enum CardWidth {
    case screen90  // 画面幅の90%
    case screen95  // 画面幅の95%
    case screen100 // 画面幅の100%
    
    /// 幅の割合（0.0 〜 1.0）
    var ratio: CGFloat {
        switch self {
        case .screen90: return 0.9
        case .screen95: return 0.95
        case .screen100: return 1.0
        }
    }
    
    /// 画面サイズに応じた最大幅を計算
    func maxWidth(in totalWidth: CGFloat) -> CGFloat {
        totalWidth * ratio
    }
}

/// ガラス風のメインカードコンポーネント
struct mainCard<Content: View>: View {
    /// 内部コンテンツ
    private let content: () -> Content
    /// 横幅タイプ
    private let width: CardWidth
    /// 高さ
    private let height: CGFloat
    /// テキストカラー
    private let labelColor: Color
    
    init(
        width: CardWidth = .screen95,
        height: CGFloat = 440,
        labelColor: Color = .white,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.height = height
        self.labelColor = labelColor
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            let cardWidth = width.maxWidth(in: geo.size.width)
            
            glassBase
                .overlay(contentArea)
                .frame(maxWidth: cardWidth)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
                .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
                .shadow(color: Color(red: 102/255, green: 126/255, blue: 234/255).opacity(0.4), radius: 30, x: 0, y: 0)
                .shadow(color: Color.white.opacity(0.2), radius: 45, x: 0, y: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)  
        }
        .frame(height: height)
    }
    
    /// ガラス風の土台
    private var glassBase: some View {
        RoundedRectangle(cornerRadius: 40)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.15), location: 0.0),
                        .init(color: Color.white.opacity(0.05), location: 0.5),
                        .init(color: Color.white.opacity(0.10), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // ガラス風の内側ハイライト
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.08), location: 0.0),
                        .init(color: Color.white.opacity(0.02), location: 0.5),
                        .init(color: Color.white.opacity(0.05), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // 上部の内側白ライン
            .overlay(
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Spacer()
                }
            )
        
            // 白い枠線（border border-white/30）
            // より光らせるために不透明度を上げてグロー効果を追加
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                    .shadow(color: Color.white.opacity(0.5), radius: 3, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.3), radius: 6, x: 0, y: 0)
            )
    }
    
    /// コンテンツ表示エリア
    private var contentArea: some View {
        VStack {
            content()
        }
        // パディング
        .padding(.top, 16)      // pt-4
        .padding(.horizontal, 16)  // px-4
        .padding(.bottom, 16)   // pb-4
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundColor(labelColor)  // text-white
    }
}
    
// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        VStack {
            Spacer()
            mainCard(width: .screen95) {
                VStack(spacing: 8) {
                    Text("えほんのたね")
                        .font(.title)
                    Text("ここに説明テキストが入ります")
                        .font(.subheadline)
                }
            }
        }
    }
}

