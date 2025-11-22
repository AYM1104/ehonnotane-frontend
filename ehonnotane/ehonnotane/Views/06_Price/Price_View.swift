import SwiftUI

struct PriceView: View {
    // 現在表示中のカードインデックス
    @State private var currentIndex: Int = 0
    // 横スクロールの現在位置（スナップ用）
    @State private var scrollOffset: CGFloat = 0
    // ドラッグ中の一時オフセット
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // ヘッダー
            Header()
        
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "えほんの たねを")
                MainText(text: "そだてよう！")
                Spacer().frame(height: 28)
                MainText(text: "プランを選んで たくさんの物語を 育ててね", fontSize: 20)
                Spacer().frame(height: 40)

                // メインカード（カルーセル）
                Carousel()
                    .padding(.bottom, -10)
            }
        }
        // .ignoresSafeArea()
    }
}


// MARK: - カルーセル本体
private extension PriceView {
    @ViewBuilder
    func Carousel() -> some View {
        // カードを3枚に固定
        let cards = Array(0..<3)
        let cardSpacing: CGFloat = 16
        
        GeometryReader { proxy in
            // 画面幅ベースでレイアウト計算（UIKit 不要）
            let screenWidth = proxy.size.width
            let cardWidth = screenWidth * 0.78
            // 中央に1枚分を配置しつつ、次カードが少し見えるように左右余白を調整
            let sidePadding = (screenWidth - cardWidth) / 2
            // HStack をオフセットさせてページングのように見せる
            let pageWidth = cardWidth + cardSpacing

            HStack(spacing: cardSpacing) {
                ForEach(cards, id: \.self) { index in
                    mainCard(width: .screen95) {
                        // カード内容（例）：プラン名・価格など
                        VStack(spacing: 12) {
                            // ロゴ
                            Image(planLogo(for: index))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 10)
                            
                            HStack(alignment: .lastTextBaseline) {
                                MainText(text: planTitle(for: index))          // 例: 20pt
                                MainText(text: "プラン", fontSize: 18)         // 小さめでも下が揃う
                            }
                            Spacer().frame(height: 8)
                            MainText(text: planSubtitle(for: index), fontSize: 18)
                            Spacer().frame(height: 8)
                            HStack(alignment: .lastTextBaseline) {
                                MainText(text: planPrice(for: index), fontSize: 42)
                                MainText(text: " / 月")
                            }
                            // プラン毎のクレジット数（先頭にチェックアイコン）
                            Spacer().frame(height: 6)
                            featureRow("毎月 \(planMonthlyCredits(for: index)) クレジット")
                            
                            // ボタン
                            Spacer().frame(height: 12)
                            PrimaryButton(
                                title: "このプランに決定",
                                width: cardWidth * 0.8,
                                action: {
                                    // プラン選択のアクション
                                    handlePlanSelection(index: index)
                                }
                            )
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(width: cardWidth)
                    .scaleEffect(index == currentIndex ? 1.0 : 0.9)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: currentIndex)
                }
            }
            .padding(.horizontal, sidePadding)
            .offset(x: -scrollOffset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        // 予測終了位置を使ってスナップ先を決定
                        let predicted = scrollOffset - value.predictedEndTranslation.width
                        let rawIndex = predicted / pageWidth
                        let snapped = (rawIndex).rounded()
                        let newIndex = max(0, min(cards.count - 1, Int(snapped)))

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            currentIndex = newIndex
                            scrollOffset = CGFloat(newIndex) * pageWidth
                            dragOffset = 0
                        }
                    }
            )
            .onChange(of: currentIndex) { _, newValue in
                // インデックス変更時はスナップ位置も同期
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    scrollOffset = CGFloat(newValue) * pageWidth
                }
            }
            .onAppear {
                // 初期位置は 0（1枚目）
                scrollOffset = 0
            }
        }
        .frame(height: 360)
    }

    // プラン名などのダミー文言をインデックスで切り替え
    func planTitle(for index: Int) -> String {
        switch index {
        case 0: return "はじめてのたね"
        case 1: return "そだてるたね"
        default: return "わくわくのたね"
        }
    }

    // プランごとのロゴ名
    func planLogo(for index: Int) -> String {
        switch index {
        case 0: return "Price_Logo_Basic"
        case 1: return "Price_logo_Standard"
        default: return "Price_logo_Premium"
        }
    }

    func planSubtitle(for index: Int) -> String {
        switch index {
        case 0: return "はじめての ものがたり におすすめ"
        case 1: return "たくさん そだてたい きみに"
        default: return "みんなで たのしむ ぜいたくプラン"
        }
    }

    func planPrice(for index: Int) -> String {
        switch index {
        case 0: return "¥ 350"
        case 1: return "¥ 500"
        default: return "¥ 800"
        }
    }
    
    // プランごとの毎月付与クレジット数
    // 数値は仮値。必要に応じて調整してください
    func planMonthlyCredits(for index: Int) -> Int {
        switch index {
        case 0: return 350
        case 1: return 700
        default: return 1200
        }
    }
    
    // 文頭にチェック入り四角アイコンを付けた行
    @ViewBuilder
    func featureRow(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            CheckSquareIcon()
            MainText(text: text, fontSize: 18)
        }
    }
    
    // チェック入りの角丸スクエアアイコン（デザインに近い表現）
    struct CheckSquareIcon: View {
        var body: some View {
            Image(systemName: "checkmark.app")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.white)
        }
    }
    
    // プラン選択時の処理
    func handlePlanSelection(index: Int) {
        let planName = planTitle(for: index)
        let price = planPrice(for: index)
        
        // TODO: 実際の処理を実装
        print("選択されたプラン: \(planName) (\(price))")
        // 例: 次の画面に遷移、APIリクエスト送信など
    }
}


#Preview {
    PriceView()
        // .environmentObject(AppCoordinator())
        // .environmentObject(AuthService())
}
