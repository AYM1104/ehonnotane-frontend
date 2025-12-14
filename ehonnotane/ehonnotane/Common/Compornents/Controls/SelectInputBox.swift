import SwiftUI

/// APIの選択肢データを模したシンプルなモデル
struct SelectOption: Identifiable {
    let label: String
    let value: String
    
    var id: String { value }
}

/// 選択式入力コンポーネント
struct Select_Input_Box: View {
    let options: [SelectOption]
    @Binding var answer: String
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                ForEach(options, id: \.value) { option in
                    Button {
                        // キーボードを閉じるためにフォーカスを解除
                        onTap?()
                        // 保存するのはAPIが期待するvalue（英語コード）
                        answer = option.value
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.custom("YuseiMagic-Regular", size: 16))
                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                            
                            if answer == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    // 表示はlabel（日本語）。現在のanswer(value)から対応labelを解決
                    Text(displayLabel(for: answer, in: options))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(
                            answer.isEmpty
                            ? .gray
                            : Color(red: 54/255, green: 45/255, blue: 48/255)
                        )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
    
    /// 現在の選択値(value)に対応するlabelを返す
    private func displayLabel(for value: String, in options: [SelectOption]) -> String {
        guard !value.isEmpty else { return "選択してください" }
        return options.first(where: { $0.value == value })?.label ?? "選択してください"
    }
}

#Preview {
    SelectInputBoxPreview()
}

private struct SelectInputBoxPreview: View {
    @State private var answer: String = ""
    
    private let mockOptions = [
        SelectOption(label: "くま", value: "bear"),
        SelectOption(label: "きつね", value: "fox"),
        SelectOption(label: "うさぎ", value: "rabbit")
    ]
    
    var body: some View {
        Select_Input_Box(
            options: mockOptions,
            answer: $answer
        )
        .padding()
        .background(Color(red: 254/255, green: 247/255, blue: 232/255))
    }
}

