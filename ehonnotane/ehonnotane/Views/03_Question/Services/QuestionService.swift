import Foundation
import Combine

// QuestionModels.swiftで定義された型を使用

// MARK: - API エラー定義

enum QuestionAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    case questionsNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.invalid_url")
        case .noData:
            return String(localized: "error.no_data")
        case .decodingError:
            return String(localized: "error.decoding_failed")
        case .networkError(let error):
            return String(localized: "error.network \(error.localizedDescription)")
        case .serverError(let code, let message):
            return String(localized: "error.server \(code) \(message)")
        case .questionsNotFound:
            return String(localized: "question.not_found")
        }
    }
}

// MARK: - 質問データ取得サービス

class QuestionService: ObservableObject {
    private let baseURL = APIConfig.shared.baseURL
    static let shared = QuestionService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentQuestions: [Question] = []
    @Published var currentQuestionIndex = 0
    
    private init() {}
    
    // 質問を取得する関数
    func fetchQuestions(storySettingId: Int) async throws -> QuestionAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/story/story_settings/\(storySettingId)/questions") else {
            throw QuestionAPIError.invalidURL
        }
        
        print("❓ Fetching questions from: \(url)")
        
        // デバイスの言語設定を取得
        let preferredLanguage = Locale.preferredLanguages.first ?? "ja"
        print("📝 Device Language: \(preferredLanguage)")
        
        var request = URLRequest(url: url)
        request.setValue(preferredLanguage, forHTTPHeaderField: "Accept-Language")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break
                case 404:
                    throw QuestionAPIError.questionsNotFound
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? String(localized: "error.unknown")
                    throw QuestionAPIError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    throw QuestionAPIError.serverError(httpResponse.statusCode, String(localized: "error.unexpected"))
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            let decoder = JSONDecoder()
            let questionResponse = try decoder.decode(QuestionAPIResponse.self, from: data)
            
            print("✅ Questions data received successfully")
            print("❓ Questions count: \(questionResponse.questions.count)")
            print("📊 Processing time: \(questionResponse.processing_time_ms ?? 0)ms")
            
            await MainActor.run {
                self.currentQuestions = questionResponse.questions
            }
            
            return questionResponse
            
        } catch let error as QuestionAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            handleDecodingError(decodingError)
            throw QuestionAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw QuestionAPIError.networkError(error)
        }
    }
    
    // デコーディングエラーの詳細ログ出力
    private func handleDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("🔍 Type mismatch: expected \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .valueNotFound(let type, let context):
            print("🔍 Value not found: \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .keyNotFound(let key, let context):
            print("🔍 Key not found: \(key.stringValue)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .dataCorrupted(let context):
            print("🔍 Data corrupted: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        @unknown default:
            print("🔍 Unknown decoding error")
        }
    }
    
    // 現在の質問を取得
    func getCurrentQuestion() -> Question? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }
    
    // 次の質問に進む
    func nextQuestion() {
        if currentQuestionIndex < currentQuestions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    // 前の質問に戻る
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    // 質問の進捗を取得（0.0-1.0）
    func getProgress() -> Double {
        guard !currentQuestions.isEmpty else { return 0.0 }
        return Double(currentQuestionIndex + 1) / Double(currentQuestions.count)
    }
    
    // 質問が完了したかどうか
    func isCompleted() -> Bool {
        return currentQuestionIndex >= currentQuestions.count - 1
    }
    
    // MARK: - 回答送信機能（Supabase版APIに合わせて個別送信）
    
    struct SingleAnswerSubmissionRequest: Codable {
        let field: String
        let answer: String
    }
    
    struct SingleAnswerSubmissionResponse: Codable {
        let story_setting_id: Int
        let field: String
        let answer: String
        let message: String
        let processing_time_ms: Double?
    }
    
    // 回答を送信する関数（1件ずつ送信: /answers）
    func submitAnswers(storySettingId: Int, answers: [String: String]) async throws -> BulkAnswerSubmissionResponse {
        print("📤 Submitting answers individually to /answers (count=\(answers.count))")
        var updatedFields: [String] = []
        
        for (field, answer) in answers {
            guard let url = URL(string: "\(baseURL)/api/story/story_settings/\(storySettingId)/answers") else {
                throw QuestionAPIError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = SingleAnswerSubmissionRequest(field: field, answer: answer)
            do {
                let jsonData = try JSONEncoder().encode(body)
                request.httpBody = jsonData
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200, 201:
                        break
                    case 404:
                        let errorMessage = String(data: data, encoding: .utf8) ?? String(localized: "error.not_found")
                        throw QuestionAPIError.serverError(404, errorMessage)
                    case 400...599:
                        let errorMessage = String(data: data, encoding: .utf8) ?? String(localized: "error.unknown")
                        throw QuestionAPIError.serverError(httpResponse.statusCode, errorMessage)
                    default:
                        throw QuestionAPIError.serverError(httpResponse.statusCode, String(localized: "error.unexpected"))
                    }
                }
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🟢 Answer accepted: field=\(field) resp=\(jsonString)")
                }
                updatedFields.append(field)
            } catch {
                print("❌ Failed to submit field=\(field): \(error)")
                throw error
            }
        }
        return BulkAnswerSubmissionResponse(
            story_setting_id: storySettingId,
            updated_fields: updatedFields,
            message: "\(updatedFields.count)個のフィールドを更新しました",
            processing_time_ms: nil
        )
    }

}

// MARK: - 回答送信用のデータ構造

struct BulkAnswerSubmissionRequest: Codable {
    let answers: [String: String]
}

struct BulkAnswerSubmissionResponse: Codable {
    let story_setting_id: Int
    let updated_fields: [String]
    let message: String
    let processing_time_ms: Double?
}
