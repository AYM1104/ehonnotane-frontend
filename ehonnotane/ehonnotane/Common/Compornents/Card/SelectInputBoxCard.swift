import SwiftUI

struct SelectInputBoxCard<TopContent: View, Footer: View>: View {
    let title: String
    let options: [SelectOption]
    @Binding var selection: String
    let subTitle: String?
    let topContent: TopContent
    let footer: Footer
    let isTextFieldFocused: FocusState<Bool>.Binding?
    
    init(
        title: String,
        options: [SelectOption],
        selection: Binding<String>,
        subTitle: String? = nil,
        isTextFieldFocused: FocusState<Bool>.Binding? = nil,
        @ViewBuilder topContent: () -> TopContent,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.subTitle = subTitle
        self.isTextFieldFocused = isTextFieldFocused
        self.topContent = topContent()
        self.footer = footer()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            InnerCard {
                ZStack {
                    // セレクトボックスを中央に固定配置
                    VStack(
                        alignment: .center,
                        spacing: 32
                    ) {
                        Spacer()
                        
                        // Select_Input_Boxコンポーネントを配置
                        Select_Input_Box(
                            options: options,
                            answer: $selection,
                            onTap: {
                                // キーボードを閉じるためにフォーカスを解除
                                isTextFieldFocused?.wrappedValue = false
                            }
                        )
                        .frame(maxWidth: 360) // ここでセレクトボックスの最大幅を調整
                        // Select_Input_Boxコンポーネントの上にタイトルを配置
                        .overlay(alignment: .top) {
                            SubText(text: title)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 4)  // 左右にパディングを追加して折り返しを促す
                                .offset(y: -60)
                                .padding(.bottom, 12)
                        }
                        // Select_Input_Boxコンポーネントの下にサブテキストを配置
                        .overlay(alignment: .bottom) {
                            if let subTitle = subTitle {
                                SubText(text: subTitle)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .offset(y: 60)
                                    .padding(.bottom, 12)
                            }
                        }
                        
                        // 追加のコンテンツ（例：子供選択ボックス）をここに配置
                        topContent
                            .padding(.top, 40) // サブタイトルとの間隔を確保
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // フッター（ボタン）を下部に配置（セレクトボックスの位置に影響しない）
                    VStack {
                        Spacer()
                        footer
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
                SelectInputBoxCard(
                    title: "テストタイトル",
                    options: [
                        SelectOption(label: "オプション1", value: "1"),
                        SelectOption(label: "オプション2", value: "2")
                    ],
                    selection: .constant("1"),
                    subTitle: "補足説明"
                ) {
                    // Top Content
                    EmptyView()
                } footer: {
                    PrimaryButton(
                        title: "これにけってい",
                        action: {
                            print("ボタンがタップされました")
                        }
                    )
                }
            }
        }
    }
}
