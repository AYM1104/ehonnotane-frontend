import SwiftUI

/// 質問ビュー - 質問の表示と入力を行う
struct Question_View: View {
    @StateObject private var viewModel: QuestionViewModel
    
    // フォーカス管理
    @FocusState private var isTextFieldFocused: Bool
    
    init(onNavigateToThemeSelect: @escaping () -> Void, storySettingId: Int, childId: Int, storyPages: Int) {
        _viewModel = StateObject(wrappedValue: QuestionViewModel(
            storySettingId: storySettingId,
            childId: childId,
            storyPages: storyPages,
            onNavigateToThemeSelect: onNavigateToThemeSelect
        ))
    }
    
    // 質問ページのビューを作成
    private var questionPages: [QuestionPage] {
        let questions = viewModel.currentQuestions
        return questions.indices.map { index in
            createQuestionPage(index: index, question: questions[index])
        }
    }
    
    private func createQuestionPage(index: Int, question: Question) -> QuestionPage {
        let isLast = index == viewModel.currentQuestions.count - 1
        let answerBinding = Binding<String>(
            get: { self.viewModel.answers[question.field] ?? "" },
            set: { self.viewModel.answers[question.field] = $0 }
        )
        
        let submitAction: (() -> Void)? = isLast ? { viewModel.handleSubmitTapped() } : nil
        
        // 次の質問に進む処理（selectタイプの質問で、最後の質問でない場合のみ）
        let nextQuestionAction: (() -> Void)? = (question.type == "select" && !isLast) ? {
            // 次の質問インデックスに進む
            if viewModel.currentQuestionIndex < viewModel.currentQuestions.count - 1 {
                viewModel.currentQuestionIndex += 1
            }
        } : nil
        
        return QuestionPage(
            id: question.field,
            question: question,
            answer: answerBinding,
            onSubmit: submitAction,
            isTextFieldFocused: $isTextFieldFocused,
            showSubmitButton: isLast,
            onNextQuestion: nextQuestionAction
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 背景
            Background {
                BigCharacter()
            }
            
            // メインコンテンツ
            VStack {
                
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "どんな おはなしかな？")
                MainText(text: "おしえてね！")
                Spacer()
                
                // メインカード
                mainCard(width: .screen95) {
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        // 1ページ = 1枚のカード（SelectInputBoxCardまたはInputBoxCardを使用）
                        PageSlider(questionPages, currentIndex: $viewModel.currentQuestionIndex) { page in
                            QuestionPageComponent(
                                question: page.question,
                                answer: page.answer,
                                onSubmit: page.onSubmit,
                                isTextFieldFocused: page.isTextFieldFocused,
                                isSubmitting: viewModel.isSubmitting,
                                showSubmitButton: page.showSubmitButton,
                                onNextQuestion: page.onNextQuestion
                            )
                            .id(page.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: viewModel.currentQuestionIndex) { _ in
                            // ページが変更された時にキーボードを閉じる
                            isTextFieldFocused = false
                        }
                        
                        // ドットプログレスバー
                        ProgressBar(
                            totalSteps: max(questionPages.count, 1),
                            currentStep: min(viewModel.currentQuestionIndex, max(questionPages.count - 1, 0)),
                            dotSize: 10,
                            spacing: 12
                        )
                        .padding(.bottom, 16)

                        
                        Spacer(minLength: 0)
                    }
                }
                .padding(.bottom, -10)
            }
            // ヘッダー
            Header()
            
            // 回答送信中のローディング表示
            if viewModel.isSubmitting || viewModel.isLoadingQuestions {
                ZStack {
                    // 半透明の背景
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    // ローディングコンテンツ
                    VStack(spacing: 20) {
                        // スピナー
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        // ローディングテキスト
                        Text(viewModel.loadingMessage)
                            .font(.custom("YuseiMagic-Regular", size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .alert("お知らせ", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}



// プレビュー専用のラッパービュー（モックデータを使用）
struct Question_View_Preview: View {
    @StateObject private var viewModel: QuestionViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    init() {
        // モックデータをQuestionServiceに設定
        let mockQuestions: [Question] = [
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
            )
        ]
        
        // QuestionServiceにモックデータを設定
        QuestionService.shared.currentQuestions = mockQuestions
        
        // ViewModelを初期化（モックモードでAPI呼び出しをスキップ）
        _viewModel = StateObject(wrappedValue: QuestionViewModel(
            storySettingId: 1,
            childId: 1,
            storyPages: 5,
            onNavigateToThemeSelect: {
                print("テーマ選択ページに遷移（プレビュー）")
            },
            mockMode: true
        ))
    }
    
    // 質問ページのビューを作成
    private var questionPages: [QuestionPage] {
        let questions = viewModel.currentQuestions
        return questions.indices.map { index in
            createQuestionPage(index: index, question: questions[index])
        }
    }
    
    private func createQuestionPage(index: Int, question: Question) -> QuestionPage {
        let isLast = index == viewModel.currentQuestions.count - 1
        let answerBinding = Binding<String>(
            get: { self.viewModel.answers[question.field] ?? "" },
            set: { self.viewModel.answers[question.field] = $0 }
        )
        
        let submitAction: (() -> Void)? = isLast ? { 
            print("回答送信（プレビュー）")
        } : nil
        
        // 次の質問に進む処理（selectタイプの質問で、最後の質問でない場合のみ）
        let nextQuestionAction: (() -> Void)? = (question.type == "select" && !isLast) ? {
            // 次の質問インデックスに進む
            if viewModel.currentQuestionIndex < viewModel.currentQuestions.count - 1 {
                viewModel.currentQuestionIndex += 1
            }
        } : nil
        
        return QuestionPage(
            id: question.field,
            question: question,
            answer: answerBinding,
            onSubmit: submitAction,
            isTextFieldFocused: $isTextFieldFocused,
            showSubmitButton: isLast,
            onNextQuestion: nextQuestionAction
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // メインコンテンツ
            VStack {
                
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "どんな おはなしかな？")
                MainText(text: "おしえてね！")
                Spacer()
                
                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        // 1ページ = 1枚のカード（SelectInputBoxCardまたはInputBoxCardを使用）
                        PageSlider(questionPages, currentIndex: $viewModel.currentQuestionIndex) { page in
                            QuestionPageComponent(
                                question: page.question,
                                answer: page.answer,
                                onSubmit: page.onSubmit,
                                isTextFieldFocused: page.isTextFieldFocused,
                                isSubmitting: false, // プレビューでは常にfalse
                                showSubmitButton: page.showSubmitButton,
                                onNextQuestion: page.onNextQuestion
                            )
                            .id(page.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // ドットプログレスバー
                        ProgressBar(
                            totalSteps: max(questionPages.count, 1),
                            currentStep: min(viewModel.currentQuestionIndex, max(questionPages.count - 1, 0)),
                            dotSize: 10,
                            spacing: 12
                        )
                        .padding(.bottom, 16)

                        
                        Spacer(minLength: 0)
                    }
                }
                .padding(.bottom, -10)
            }
            // ヘッダー
            Header()
        }
    }
}

#Preview {
    Question_View_Preview()
}
