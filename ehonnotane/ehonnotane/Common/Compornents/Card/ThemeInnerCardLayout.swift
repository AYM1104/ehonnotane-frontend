import SwiftUI

// テーマ選択のインナーカード内で使う共通レイアウト
// ・見出し
// ・中央寄せタイトル
// ・区切り線
// ・スクロール本文
struct ThemeInnerCardLayout<BodyContent: View>: View {
    let heading: String?
    let centeredTitle: String?
    let bodyContent: () -> BodyContent
    
    private var textColor: Color { Color(hex: "362D30") }
    
    init(
        heading: String? = nil,
        centeredTitle: String? = nil,
        @ViewBuilder bodyContent: @escaping () -> BodyContent
    ) {
        self.heading = heading
        self.centeredTitle = centeredTitle
        self.bodyContent = bodyContent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // 見出し
            if let heading {
                SubText(text: heading, fontSize: 16, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // おはなしのタイトル
            if let centeredTitle {
                SubText(text: centeredTitle, fontSize: 20, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // 区切り線
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(maxWidth: .infinity, maxHeight: 1)
                .padding(.vertical, 4)
            
            // おはなしの概要
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 12) {
                    bodyContent()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            }
            .scrollIndicators(.visible)
            .frame(maxWidth: .infinity)
        }
        // これまで ZStack 側に付いていた余白をこのレイアウト側で吸収
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
}

struct ThemeInnerCardLayout_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            mainCard(width: .screen95) {
                InnerCard {
                    ThemeInnerCardLayout(
                        heading: "おはなしのタイトル",
                        centeredTitle: "あすくんの あすあすあすあすあすあすあす めがね"
                    ) {
                        ForEach(0..<8, id: \.self) { _ in
                            Text("本文プレビュー  本文プレビューTextTextTextTextTextTextTextTextTextText")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "362D30"))
                        }
                    }
                }
            }
        }
    }
}


