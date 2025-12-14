import SwiftUI

// メインカードコンポーネント（ガラス風のカード）

struct MainCard<Content: View>: View {

    // プロパティを定義
    private let heightStyle: HeightStyle  // 高さの選択（画面比率 or 固定）
    private let content: () -> Content  // 内部コンテンツ
    private let labelColor: Color  // テキストカラー

    // 高さの選択（画面比率 or 固定）
    enum HeightStyle {
        case ratio(CGFloat)    // 画面高さに対する割合
        case fixed(CGFloat)    // 固定値（pt）

        static var percent65: HeightStyle { .ratio(0.65) }
        static var percent52: HeightStyle { .ratio(0.52) }
    }
    
    // イニシャライザを定義
    init(
        // デフォルト値を設定
        heightStyle: HeightStyle = .percent65,  // デフォルトは画面高さの65%
        labelColor: Color = .white,  // テキストカラー：白色
        @ViewBuilder content: @escaping () -> Content
    ) {
        // プロパティに値を設定
        self.heightStyle = heightStyle
        self.labelColor = labelColor
        self.content = content
    }
    
    // ガラス風カードの土台（３つのレイヤーを重ねる）
    private var glassBase: some View {
        RoundedRectangle(cornerRadius: 40)  // 角丸40px

            // ① 基本の背景
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

            // ② ハイライト
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

            // ③ 上部ライン
            .overlay(
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Spacer()
                }
            )
        
            // 枠線
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
        .padding(16)    // カード内部の余白を設定
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundColor(labelColor)  // text-white
    }
    
    // 表示内容を定義
    var body: some View {

        let cardHeight: CGFloat = {
            switch heightStyle {
            case .ratio(let r): return UIScreen.main.bounds.height * r
            case .fixed(let h): return h
            }
        }()

        // 画面のサイズ情報を取得
        GeometryReader { _ in
            // カード内部の組み立て
            glassBase
                .overlay(contentArea)

                // カードの幅と高さを設定
                .frame(height: cardHeight)

                // 角丸を設定
                .clipShape(RoundedRectangle(cornerRadius: 40))

                // 影を追加
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
                .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
                .shadow(color: Color(red: 102/255, green: 126/255, blue: 234/255).opacity(0.4), radius: 30, x: 0, y: 0)
                .shadow(color: Color.white.opacity(0.2), radius: 45, x: 0, y: 0)

                // カードの配置を設定（横は固定余白を空けて上部に寄せる）
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 16)
        }
        .frame(height: cardHeight)
    }
}
    

// プレビュー
// frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) を付けて中央配置しています。
#Preview {
    ZStack {
        Background {
        }
        MainCard(heightStyle: .percent65) {
            VStack(spacing: 8) {
                MainText(text: "えほんのたね")
                    .font(.title)
                Text("ここに説明テキストが入ります")
                    .font(.subheadline)
            }
        }
        // 中央配置
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
