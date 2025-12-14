import SwiftUI

// テキスト入力ボックスコンポーネント
struct InputBox2: View {

    // プロパティを定義
    let placeholder: String    // プレースホルダー
    @Binding private var text: String
    let isTextFieldFocused: FocusState<Bool>.Binding?    // テキストフィールドがフォーカスされているかどうか
    @FocusState private var internalFocus: Bool    // テキストフィールドがフォーカスされているかどうか
    let underlineOnly: Bool    // 下線のみ表示するスタイルか

    // イニシャライザを定義
    init(
        // デフォルト値を設定
        placeholder: String = "",    // プレースホルダー
        text: Binding<String>,    // テキスト
        isFocused: FocusState<Bool>.Binding? = nil,    // テキストフィールドがフォーカスされているかどうか
        underlineOnly: Bool = false
    ) {
        // プロパティに値を設定
        self.placeholder = placeholder
        _text = text
        self.isTextFieldFocused = isFocused
        self.underlineOnly = underlineOnly
    }
    
    // 表示内容を定義
    var body: some View {

        // 入力ボックスの組み立て
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    // プレースホルダーを表示
                    Text(placeholder)
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .padding(.horizontal, 20)
                }
                
                // テキストフィールドを表示
                TextField("", text: $text)
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 52)
                    .focused(isTextFieldFocused != nil ? isTextFieldFocused! : $internalFocus)
            }

            // 入力ボックスの幅を設定
            .frame(maxWidth: .infinity)

            // 背景を設定
            .background {
                if underlineOnly {
                    Color.clear
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
            }
            .overlay(alignment: .bottom) {
                if underlineOnly {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 1)
                        .padding(.horizontal, 4)
                }
            }

            // 影を表示
            .shadow(color: underlineOnly ? .clear : Color.white.opacity(0.25), radius: 6, x: 0, y: 4)
        }

        // 入力ボックスの高さ
        .frame(height: 52)
    }
}

#Preview {
    StatefulPreviewWrapper("") { text in
        VStack(spacing: 20) {
            InputBox2(
                placeholder: "ラベルなしの入力",
                text: text
            )
            
            InputBox2(
                placeholder: "お子さまのなまえ",
                text: text
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.blue.opacity(0.1))
        )
        .padding()
    }
}

// /// SwiftUIプレビュー用ステートラッパー
// struct StatefulPreviewWrapper<Value, Content: View>: View {
//     @State private var value: Value
//     private let content: (Binding<Value>) -> Content
    
//     init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
//         _value = State(initialValue: initialValue)
//         self.content = content
//     }
    
//     var body: some View {
//         content($value)
//     }
// }
