import SwiftUI
import Combine

@MainActor
class QuestionViewModel: ObservableObject {
    // QuestionServiceを使用
    private var questionService = QuestionService.shared
    
    @Published var currentQuestionIndex = 0
    @Published var answers: [String: String] = [:] // 質問IDと回答のマッピング
    
    // 送信状態の管理
    @Published var isSubmitting = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    @Published var isLoadingQuestions = false
    @Published var loadingMessage = "読み込み中..."
    
    // 呼び出し元から渡されるデータ
    let storySettingId: Int
    let childId: Int
    let storyPages: Int
    
    // テーマ選択画面への遷移コールバック
    let onNavigateToThemeSelect: () -> Void
    
    private var cancellables = Set<AnyCancellable>()
    
    // モックモード用のフラグ
    private let isMockMode: Bool
    
    init(storySettingId: Int, childId: Int, storyPages: Int, onNavigateToThemeSelect: @escaping () -> Void, mockMode: Bool = false) {
        self.storySettingId = storySettingId
        self.childId = childId
        self.storyPages = storyPages
        self.onNavigateToThemeSelect = onNavigateToThemeSelect
        self.isMockMode = mockMode
        
        // QuestionServiceの変更を監視して、ViewModelの変更として通知
        questionService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // モックモードの場合はAPI呼び出しをスキップ
        if !mockMode {
            // 質問をロード
            Task {
                await loadQuestions()
            }
        } else {
            // モックモードの場合はローディング状態を解除
            isLoadingQuestions = false
        }
    }
    
    func loadQuestions() async {
        print("🔄 質問の読み込みを開始します")
        loadingMessage = "読み込み中..."
        isLoadingQuestions = true
        
        do {
            _ = try await questionService.fetchQuestions(storySettingId: storySettingId)
            
            await MainActor.run {
                isLoadingQuestions = false
                print("✅ 質問の読み込み完了")
            }
        } catch {
            print("❌ 質問の取得に失敗しました: \(error)")
            await MainActor.run {
                isLoadingQuestions = false
                self.alertMessage = "質問の読み込みに失敗しました: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    var currentQuestions: [Question] {
        questionService.currentQuestions
    }
    
    // 回答を送信する関数
    func submitAnswers() {
        // 既に送信中の場合は処理をスキップ（二重実行を防止）
        guard !isSubmitting else {
            print("⚠️ 既に送信処理が実行中です。重複実行をスキップします。")
            return
        }
        
        print("🔄 回答送信処理を開始します")
        loadingMessage = "送信中..."
        isSubmitting = true
        
        Task {
            do {
                // QuestionServiceを使用して回答を送信
                // 送信前に選択肢の回答をvalue（英語コード）に正規化
                var normalized: [String: String] = [:]
                for question in questionService.currentQuestions {
                    let field = question.field
                    if let raw = answers[field], !raw.isEmpty {
                        if let options = question.options, !options.isEmpty {
                            if let matched = options.first(where: { $0.value == raw || $0.label == raw }) {
                                normalized[field] = matched.value
                            } else {
                                normalized[field] = raw
                            }
                        } else {
                            normalized[field] = raw
                        }
                    }
                }
                let response = try await questionService.submitAnswers(
                    storySettingId: storySettingId,
                    answers: normalized
                )
                
                print("✅ 回答送信成功:")
                print("   - Story Setting ID: \(response.story_setting_id)")
                print("   - Updated fields: \(response.updated_fields)")
                print("   - Message: \(response.message)")
                print("   - Processing time: \(response.processing_time_ms ?? 0)ms")

                // 回答送信後にテーマ生成をトリガー
                let themeStartTime = Date()
                do {
                    print("🔄 [QuestionViewModel] テーマ生成開始")
                    await MainActor.run {
                        loadingMessage = "テーマを考えているよ..."
                    }
                    try await StoryService.shared.generateThemes(storySettingId: storySettingId)
                    let themeDuration = Date().timeIntervalSince(themeStartTime)
                    print("✅ [QuestionViewModel] テーマ生成完了（View側計測: \(String(format: "%.2f", themeDuration))秒）")
                } catch {
                    let themeDuration = Date().timeIntervalSince(themeStartTime)
                    print("⚠️ [QuestionViewModel] テーマ生成API呼び出しに失敗（処理時間: \(String(format: "%.2f", themeDuration))秒）: \(error)")
                    // エラーが発生しても画面遷移は実行する（テーマ生成は後で再試行可能）
                }
                
                // メインスレッドでUIを更新して画面遷移を実行
                await MainActor.run {
                    // ローディング表示を終了
                    isSubmitting = false
                }
                
                // 画面遷移は次のランループで実行（アニメーションを確実に動作させるため）
                Task { @MainActor in
                    // 少し待機してから遷移を実行（UI更新を確実にするため）
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
                    print("🔄 [QuestionViewModel] テーマ選択画面への遷移を実行")
                    onNavigateToThemeSelect()
                    print("✅ [QuestionViewModel] テーマ選択画面への遷移完了")
                }
                
            } catch {
                print("❌ 回答送信エラー: \(error.localizedDescription)")
                
                // メインスレッドでエラーを表示
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "回答の送信に失敗しました: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
