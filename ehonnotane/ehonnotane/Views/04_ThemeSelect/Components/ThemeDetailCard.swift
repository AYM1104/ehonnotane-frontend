import SwiftUI

struct ThemeDetailCard: View {
    let page: ThemePage
    let isGeneratingImages: Bool
    let onSelect: () -> Void
    
    var body: some View {

        // インナーカード
        InnerCard {
            VStack(spacing: 0) {
                // おはなしのタイトル
                VStack(spacing: 20) {
                    SubText(text: "〈タイトル と がいよう〉")
                    SubText(text: page.title)
                }
                .frame(height: 100, alignment: .top)
                .frame(maxWidth: .infinity)
                
                // おはなしの概要
                ScrollView(showsIndicators: true) {
                    SubText(text: page.content)
                        .padding(.horizontal, 10)
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 10)
                
                // 決定ボタン
                VStack {
                    PrimaryButton(
                        title: isGeneratingImages ? "画像生成中..." : "これにけってい",
                        action: {
                            onSelect()
                        }
                    )
                    .disabled(isGeneratingImages)
                }
                .frame(height: 80)
            }
            .padding(.vertical, 20)
        }
    }
}

#Preview {
    ThemeDetailCard(
        page: ThemePage(
            title: "森のなかまたち",
            content: "ある日、森のなかまたちが集まって、楽しい冒険に出かけました。うさぎさん、きつねさん、くまさんが力を合わせて、素敵な宝物を見つけるお話です。",
            storyPlotId: 1,
            selectedTheme: "冒険"
        ),
        isGeneratingImages: false,
        onSelect: {
            print("テーマが選択されました")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("画像生成中") {
    ThemeDetailCard(
        page: ThemePage(
            title: "海の大冒険",
            content: "深い海の底で、小さな魚たちが大きな冒険を繰り広げます。サンゴ礁を抜けて、宝箱を探しに行くお話です。",
            storyPlotId: 2,
            selectedTheme: "海"
        ),
        isGeneratingImages: true,
        onSelect: {
            print("テーマが選択されました")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
