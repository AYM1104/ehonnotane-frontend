import SwiftUI

struct QuestionSelectionComponent: View {
    let question: Question
    @Binding var answer: String
    let onSubmit: (() -> Void)?
    let isSubmitting: Bool
    let showSubmitButton: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if let questionOptions = question.options {
                // QuestionOptionをSelectOptionに変換
                Select_Input_Box(
                    options: questionOptions.map { SelectOption(label: $0.label, value: $0.value) },
                    answer: $answer
                )
                .padding(.horizontal, 4)
                
                // 最後のページの場合は送信ボタンを表示
                if showSubmitButton {
                    PrimaryButton(title: String(localized: "question.submit"), action: {
                        onSubmit?()
                    })
                    .disabled(isSubmitting || answer.isEmpty) // 選択必須とする場合
                    .padding(.top, 12)
                }
            }
        }
    }
}
