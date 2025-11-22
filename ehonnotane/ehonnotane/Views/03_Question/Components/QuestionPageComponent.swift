import SwiftUI

// 質問1ページ分を表示するコンポーネント
struct QuestionPageComponent: View {
    let question: Question
    @Binding var answer: String
    let onSubmit: (() -> Void)?
    let isTextFieldFocused: FocusState<Bool>.Binding?
    let isSubmitting: Bool
    let showSubmitButton: Bool
    let onNextQuestion: (() -> Void)?
    
    init(question: Question,
         answer: Binding<String>,
         onSubmit: (() -> Void)?,
         isTextFieldFocused: FocusState<Bool>.Binding?,
         isSubmitting: Bool,
         showSubmitButton: Bool = false,
         onNextQuestion: (() -> Void)? = nil) {
        self.question = question
        self._answer = answer
        self.onSubmit = onSubmit
        self.isTextFieldFocused = isTextFieldFocused
        self.isSubmitting = isSubmitting
        self.showSubmitButton = showSubmitButton
        self.onNextQuestion = onNextQuestion
    }
    
    var body: some View {
        if question.type == "select" {
            // セレクトタイプの質問にはSelectInputBoxCardを使用
            if let questionOptions = question.options {
                SelectInputBoxCard(
                    title: question.question,
                    options: questionOptions.map { SelectOption(label: $0.label, value: $0.value) },
                    selection: $answer,
                    subTitle: nil
                ) {
                    // Top Content（空）
                    EmptyView()
                } footer: {
                    // 最後のページの時だけ「これにけってい」ボタンを表示
                    if showSubmitButton && question.type == "select" {
                        PrimaryButton(title: "これにけってい", action: {
                            // 最後のページなので送信処理を実行
                            onSubmit?()
                        })
                        .disabled(isSubmitting || answer.isEmpty)
                    } else {
                        EmptyView()
                    }
                }
            }
        } else if question.type != "submit" {
            // テキスト入力タイプの質問にはInputBoxCardを使用
            InputBoxCard(
                title: question.question,
                text: $answer,
                placeholder: question.placeholder ?? "ここに入力",
                subTitle: nil
            ) {
                // Top Content（空）
                EmptyView()
            } footer: {
                // フッターに送信ボタンを配置
                if showSubmitButton {
                    PrimaryButton(title: "送信する", action: {
                        onSubmit?()
                    })
                    .disabled(isSubmitting)
                } else {
                    EmptyView()
                }
            }
        } else {
            // 送信ボタンのみ（通常は最後のページで兼ねるのであまり使われないかも）
            VStack {
                Spacer()
                PrimaryButton(title: "送信する", action: {
                    onSubmit?()
                })
                .disabled(isSubmitting)
                Spacer()
            }
        }
    }
}
