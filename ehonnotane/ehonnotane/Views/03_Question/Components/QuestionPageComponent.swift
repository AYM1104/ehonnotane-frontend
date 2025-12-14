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
                    subTitle: nil,
                    isTextFieldFocused: isTextFieldFocused
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
                subTitle: nil,
                isTextFieldFocused: isTextFieldFocused
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

#Preview("セレクトタイプ") {
    ZStack {
        // 背景色（ガラス効果が見やすいように暗めの色）
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        VStack {
            // mainCardの中に配置して実際の見た目を確認
            mainCard(width: .screen95) {
                QuestionPageComponent(
                    question: Question(
                        field: "story_theme",
                        question: "どんなテーマのお話？",
                        type: "select",
                        placeholder: nil,
                        required: true,
                        options: [
                            QuestionOption(value: "adventure", label: "冒険"),
                            QuestionOption(value: "friendship", label: "友情"),
                            QuestionOption(value: "family", label: "家族")
                        ]
                    ),
                    answer: .constant(""),
                    onSubmit: {
                        print("送信ボタンがタップされました")
                    },
                    isTextFieldFocused: nil,
                    isSubmitting: false,
                    showSubmitButton: true
                )
            }
        }
    }
    .onAppear {
        FontRegistration.registerFonts()
    }
}

#Preview("テキスト入力タイプ") {
    struct PreviewWrapper: View {
        @State private var answer: String = ""
        @FocusState private var isTextFieldFocused: Bool
        
        var body: some View {
            ZStack {
                // 背景色（ガラス効果が見やすいように暗めの色）
                Color.blue.opacity(0.3).ignoresSafeArea()
                
                VStack {
                    // mainCardの中に配置して実際の見た目を確認
                    mainCard(width: .screen95) {
                        QuestionPageComponent(
                            question: Question(
                                field: "main_character",
                                question: "主人公はだれ？",
                                type: "text",
                                placeholder: "例：うさぎさん",
                                required: true,
                                options: nil
                            ),
                            answer: $answer,
                            onSubmit: {
                                print("送信ボタンがタップされました")
                            },
                            isTextFieldFocused: $isTextFieldFocused,
                            isSubmitting: false,
                            showSubmitButton: true
                        )
                    }
                }
            }
            .onAppear {
                FontRegistration.registerFonts()
            }
        }
    }
    
    return PreviewWrapper()
}

// プレビュー
#Preview("スライダー（5ページ）") {
    struct SliderPreviewWrapper: View {
        @State private var currentIndex: Int = 0
        @State private var answer1: String = ""
        @State private var answer2: String = ""
        @State private var answer3: String = ""
        @State private var answer4: String = ""
        @State private var answer5: String = ""
        @FocusState private var isTextFieldFocused: Bool
        
        // 5ページ分の質問データ
        let questions: [Question] = [
            Question(
                field: "main_character",
                question: "主人公はだれ？",
                type: "text",
                placeholder: "例：うさぎさん",
                required: true,
                options: nil
            ),
            Question(
                field: "story_theme",
                question: "どんなテーマのお話？",
                type: "select",
                placeholder: nil,
                required: true,
                options: [
                    QuestionOption(value: "adventure", label: "冒険"),
                    QuestionOption(value: "friendship", label: "友情"),
                    QuestionOption(value: "family", label: "家族")
                ]
            ),
            Question(
                field: "story_tone",
                question: "どんな雰囲気のお話？",
                type: "text",
                placeholder: "例：楽しい、優しい",
                required: false,
                options: nil
            ),
            Question(
                field: "story_setting",
                question: "どこでお話が始まりますか？",
                type: "select",
                placeholder: nil,
                required: false,
                options: [
                    QuestionOption(value: "forest", label: "森"),
                    QuestionOption(value: "sea", label: "海"),
                    QuestionOption(value: "mountain", label: "山"),
                    QuestionOption(value: "town", label: "町")
                ]
            ),
            Question(
                field: "story_message",
                question: "伝えたいメッセージは？",
                type: "text",
                placeholder: "例：友達を大切にしよう",
                required: false,
                options: nil
            )
        ]
        
        // 質問ページの配列を作成
        var questionPages: [QuestionPage] {
            questions.enumerated().map { index, question in
                let answerBinding: Binding<String> = {
                    switch index {
                    case 0: return $answer1
                    case 1: return $answer2
                    case 2: return $answer3
                    case 3: return $answer4
                    case 4: return $answer5
                    default: return .constant("")
                    }
                }()
                
                return QuestionPage(
                    id: question.field,
                    question: question,
                    answer: answerBinding,
                    onSubmit: index == questions.count - 1 ? {
                        print("送信ボタンがタップされました")
                    } : nil,
                    isTextFieldFocused: $isTextFieldFocused,
                    showSubmitButton: index == questions.count - 1,
                    onNextQuestion: nil
                )
            }
        }
        
        var body: some View {
            ZStack {
                // 背景色（ガラス効果が見やすいように暗めの色）
                Color.blue.opacity(0.3).ignoresSafeArea()
                
                VStack {
                    // mainCardの中に配置して実際の見た目を確認
                    mainCard(width: .screen95) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            // ページスライダー（インナーカードがスライドする）
                            PageSlider(questionPages, currentIndex: $currentIndex) { page in
                                QuestionPageComponent(
                                    question: page.question,
                                    answer: page.answer,
                                    onSubmit: page.onSubmit,
                                    isTextFieldFocused: page.isTextFieldFocused,
                                    isSubmitting: false,
                                    showSubmitButton: page.showSubmitButton,
                                    onNextQuestion: page.onNextQuestion
                                )
                                .id(page.id)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onChange(of: currentIndex) { _ in
                                // ページが変更された時にキーボードを閉じる
                                isTextFieldFocused = false
                            }
                            
                            // ドットプログレスバー
                            ProgressBar(
                                totalSteps: questions.count,
                                currentStep: currentIndex,
                                dotSize: 10,
                                spacing: 12
                            )
                            .padding(.bottom, 16)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.bottom, -10)
                }
            }
            .onAppear {
                FontRegistration.registerFonts()
            }
        }
    }
    
    return SliderPreviewWrapper()
}
