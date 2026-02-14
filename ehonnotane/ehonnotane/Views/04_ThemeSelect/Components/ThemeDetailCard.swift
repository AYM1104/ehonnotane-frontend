import SwiftUI

struct ThemeDetailCard: View {
    let page: ThemePage
    let isGeneratingImages: Bool
    let onSelect: () -> Void
    
    var body: some View {

        // インナーカード
        InnerCard {
            VStack(spacing: 16) {
                // おはなしのタイトル
                VStack(spacing: 0) {
//                    SubText(text: "〈タイトル と がいよう〉")
                    SubText(text: page.title)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                
                // おはなしの概要（インナーカード内にさらにインナーカードを配置）
                InnerCard(
                    cornerRadius: 20,  // 内側カードの角丸（外側は35）
                    horizontalPadding: 8,  // 内側カードの左右パディング（外側は48）
                    verticalPadding: 8,  // 内側カードの上下パディング（外側は48）
                    outerPadding: 0  // 外側の余白を0にして外側カードいっぱいに広がるようにする
                ) {
                    ScrollView(showsIndicators: true) {
                        SubText(text: page.content)
                            .padding(.horizontal, 10)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
                .frame(height: 40)
                .padding(.top, 12)
            }
            .padding(.vertical, 0)
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()  // 背景に大きなキャラクターを表示
        }
        
        // ヘッダー
        Header()
        
        VStack {
            // ヘッダーの高さ分のスペースを確保
            Spacer()
                .frame(height: 80)
            
            // メインテキスト
            MainText(text: "どんな えほんを")
            MainText(text: "つくろうかな？")
            Spacer()
            
            // メインカード
            mainCard(width: .screen95) {
                VStack(spacing: 0) {
                    ThemeDetailCard(
                        page: ThemePage(
                            title: "森のなかまたちとあすあすの大冒険とゆきゆき",
                            content: "ある日、森のなかまたちが集まって、楽しい冒険に出かけました。うさぎさん、きつねさん、くまさんが力を合わせて、素敵な宝物を見つけるお話です。ある日、森のなかまたちが集まって、楽しい冒険に出かけました。うさぎさん、きつねさん、くまさんが力を合わせて、素敵な宝物を見つけるお話です。",
                            storyPlotId: 1,
                            selectedTheme: "冒険"
                        ),
                        isGeneratingImages: false,
                        onSelect: {
                            print("テーマが選択されました")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // プログレスバー
                    ProgressBar(
                        totalSteps: 5,
                        currentStep: 2
                    )
                    .padding(.bottom, 16)

                    
                    Spacer(minLength: 0)
                }
            }
            .padding(.bottom, -10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview("画像生成中（プログレスオーバーレイ）") {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()  // 背景に大きなキャラクターを表示
        }
        
        // ヘッダー
        Header()
        
        VStack {
            // ヘッダーの高さ分のスペースを確保
            Spacer()
                .frame(height: 80)
            
            // メインテキスト
            MainText(text: "どんな えほんを")
            MainText(text: "つくろうかな？")
            Spacer()
            
            // メインカード
            mainCard(width: .screen95) {
                VStack(spacing: 16) {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.bottom, -10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        
        // 生成中プログレスオーバーレイ（画面中央モーダル）
        EnhancedGenerationProgressView(
            progress: 0.65,
            message: "絵を描いています... (4/5ページ)",
            estimatedTime: "残り約45秒",
            currentTip: "🎨 きれいな いろで ぬっているよ",
            totalPages: 5,
            currentPage: 4,
            generatedPreviews: [:]
        )
    }
}
