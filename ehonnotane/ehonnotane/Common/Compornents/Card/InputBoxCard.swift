import SwiftUI

struct InputBoxCard<TopContent: View, Footer: View>: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let subTitle: String?
    let topContent: TopContent
    let footer: Footer
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "ここに入力",
        subTitle: String? = nil,
        @ViewBuilder topContent: () -> TopContent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.subTitle = subTitle
        self.topContent = topContent()
        self.footer = footer()
    }
    
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            
            InnerCard {
                VStack(
                    alignment: .center,
                    spacing: 32
                ) {
                    Spacer()
                    
                    // InputBoxコンポーネントを配置
                    InputBox(
                        placeholder: placeholder,
                        text: $text
                    )
                    .frame(maxWidth: 360) // ここで入力ボックスの最大幅を調整
                    // InputBoxコンポーネントの上にタイトルを配置
                    .overlay(alignment: .top) {
                        SubText(text: title)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(y: -60)
                            .padding(.bottom, 12)
                    }
                    // InputBoxコンポーネントの下にサブテキストを配置
                    .overlay(alignment: .bottom) {
                        if let subTitle = subTitle {
                            SubText(text: subTitle)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .offset(y: 60)
                                .padding(.bottom, 12)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24) // ここでインナーカード内の左右の余白を調整
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        // 背景色（ガラス効果が見やすいように暗めの色）
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        VStack {           
            // mainCardの中に配置して実際の見た目を確認
            mainCard(width: .screen95) {
                InputBoxCard(
                    title: "テストタイトル",
                    text: .constant(""),
                    placeholder: "ここに入力してください",
                    subTitle: "補足説明"
                ) {
                    // Top Content
                    Text("Top Content")
                } footer: {
                    Text("フッター")
                }
            }
        }
    }
}

