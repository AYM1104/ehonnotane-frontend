import SwiftUI

// シンプルなサブカードコンポーネント
// InnerCardと同じスタイルだが、セクション機能はない
struct SubCard<Content: View>: View {
    let content: () -> Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let onChevronTap: (() -> Void)?
    let isWeekMode: Bool
    
    // シンプルなイニシャライザ
    init(
        backgroundColor: Color = Color.white.opacity(0.5),
        cornerRadius: CGFloat = 35,
        horizontalPadding: CGFloat = 30,
        topPadding: CGFloat = 0,
        bottomPadding: CGFloat = 16,
        onChevronTap: (() -> Void)? = nil,
        isWeekMode: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.onChevronTap = onChevronTap
        self.isWeekMode = isWeekMode
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .frame(maxWidth: .infinity, alignment: .top) // 上揃え
            
            // 右下の三角形（クリック可能）
            if let onChevronTap = onChevronTap {
                Button(action: onChevronTap) {
                    Image(systemName: isWeekMode ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .rotationEffect(.degrees(0))
                        .id(isWeekMode ? "chevron.down" : "chevron.up") // アイコンの切り替え時にアニメーションを無効化
                        .transaction { transaction in
                            transaction.animation = nil // アニメーションを無効化
                        }
                }
                .offset(x: -12, y: -16) // 右下から少し内側に配置
            } else {
                Image(systemName: isWeekMode ? "chevron.down" : "chevron.up")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    .rotationEffect(.degrees(0))
                    .id(isWeekMode ? "chevron.down" : "chevron.up") // アイコンの切り替え時にアニメーションを無効化
                    .transaction { transaction in
                        transaction.animation = nil // アニメーションを無効化
                    }
                    .offset(x: -12, y: -16) // 右下から少し内側に配置
            }
        }
    }
}

struct SubCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()
                .environmentObject(AppCoordinator())
            
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "どんな え でえほんを")
                MainText(text: "つくろうかな？")
                Spacer()
                
                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        SubCard {
                            // コンテンツ
                            VStack(spacing: 8) {
                                SubText(text: "サブカード", fontSize: 18)
                                SubText(text: "ここにコンテンツが表示されます", fontSize: 18)
                            }
                        }
                        .padding(.top, 4) // サブカード上部の余白
                        .padding(.horizontal, 4) // サブカード左右の余白
                        .padding(.bottom, 16) // サブカード下部の余白
                    }
                }
                .padding(.horizontal, 16) // パディングを減らしてカードを広く表示
                .padding(.bottom, 16) // 画面下部からの余白
            }
        }
    }
}

