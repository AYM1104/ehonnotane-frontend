import SwiftUI

/// 共通テキスト入力ボックス
/// 角丸背景とプレースホルダー表示を標準化
struct InputBox: View {
    // MARK: - Properties
    let label: String?
    let placeholder: String
    @Binding private var text: String
    
    init(
        label: String? = nil,
        placeholder: String = "",
        text: Binding<String>
    ) {
        self.label = label
        self.placeholder = placeholder
        _text = text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .padding(.horizontal, 20)
                }
                
                TextField("", text: $text)
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 52)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: Color.white.opacity(0.25), radius: 6, x: 0, y: 4)
        }
    }
}

#Preview {
    StatefulPreviewWrapper("") { text in
        VStack(spacing: 20) {
            InputBox(
                label: "なまえ",
                placeholder: "お子さまのなまえ",
                text: text
            )
            
            InputBox(
                placeholder: "ラベルなしの入力",
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

/// SwiftUIプレビュー用ステートラッパー
private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content
    
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
}

