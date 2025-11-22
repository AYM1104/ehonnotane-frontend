import SwiftUI

// 質問ページのデータ構造
struct QuestionPage: Identifiable {
    let id: String // 安定したIDを使用
    let question: Question
    let answer: Binding<String>
    let onSubmit: (() -> Void)?
    let isTextFieldFocused: FocusState<Bool>.Binding?
    
    let showSubmitButton: Bool
    let onNextQuestion: (() -> Void)?
    
    init(id: String, question: Question, answer: Binding<String>, onSubmit: (() -> Void)?, isTextFieldFocused: FocusState<Bool>.Binding? = nil, showSubmitButton: Bool = false, onNextQuestion: (() -> Void)? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.onSubmit = onSubmit
        self.isTextFieldFocused = isTextFieldFocused
        self.showSubmitButton = showSubmitButton
        self.onNextQuestion = onNextQuestion
    }
}
