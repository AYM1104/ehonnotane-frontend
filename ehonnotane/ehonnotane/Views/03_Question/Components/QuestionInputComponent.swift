import SwiftUI

struct QuestionInputComponent: View {
    let question: Question
    @Binding var answer: String
    let onSubmit: (() -> Void)?
    let isTextFieldFocused: FocusState<Bool>.Binding?
    let isSubmitting: Bool
    let showSubmitButton: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 上部のスペース
            Spacer()
            
            // InputBoxコンポーネントを使用
            InputBox(
                placeholder: question.placeholder ?? "ここに入力",
                text: $answer,
                isFocused: isTextFieldFocused
            )
            .disabled(isSubmitting)
            
            // 最後のページの場合は送信ボタンを表示
            if showSubmitButton {
                PrimaryButton(title: "送信する", action: {
                    onSubmit?()
                })
                .disabled(isSubmitting)
                .padding(.top, 12)
            }
            
            // 下部のスペース
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
