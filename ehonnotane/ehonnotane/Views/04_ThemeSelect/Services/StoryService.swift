import Foundation
import Combine

// MARK: - API エラー定義

enum StoryServiceError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        }
    }
}

// MARK: - ストーリー生成サービス

class StoryService: ObservableObject {
    // APIConfig が未実装のため、一時的なプレースホルダを使用
    private let baseURL = APIConfig.shared.baseURL
    static let shared = StoryService()
    
    private init() {}
    
    // MARK: - テーマ生成トリガー
    /// 回答送信後に絵本のテーマ案（3件）を生成するAPIを呼び出す
    func generateThemes(storySettingId: Int) async throws {
        // 処理開始時間を記録
        let startTime = Date()
        print("⏱️ [テーマ生成] API呼び出し開始 - Story Setting ID: \(storySettingId)")
        print("⏱️ [テーマ生成] 開始時刻: \(startTime)")
        
        guard let url = URL(string: "\(baseURL)/api/story/story_generator") else {
            throw StoryServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["story_setting_id": storySettingId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // タイムアウト設定を延長（Gemini API呼び出しに時間がかかるため）
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 180.0  // 3分
            config.timeoutIntervalForResource = 180.0  // 3分
            let session = URLSession(configuration: config)
            
            // リクエスト送信時間を記録
            let requestStartTime = Date()
            print("⏱️ [テーマ生成] リクエスト送信開始: \(requestStartTime)")
            
            let (data, response) = try await session.data(for: request)
            
            // レスポンス受信時間を記録
            let responseTime = Date()
            let requestDuration = responseTime.timeIntervalSince(requestStartTime)
            print("⏱️ [テーマ生成] レスポンス受信: \(responseTime)")
            print("⏱️ [テーマ生成] リクエスト〜レスポンス時間: \(String(format: "%.2f", requestDuration))秒 (\(String(format: "%.0f", requestDuration * 1000))ms)")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200, 201:
                    // OK
                    if let txt = String(data: data, encoding: .utf8) {
                        print("🎯 [テーマ生成] API呼び出し成功")
                        print("📄 [テーマ生成] レスポンス内容: \(txt)")
                        
                        // レスポンスから処理時間を取得（バックエンド側の処理時間）
                        if let jsonData = txt.data(using: String.Encoding.utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let processingTimeMs = json["processing_time_ms"] as? Double {
                            print("⏱️ [テーマ生成] バックエンド処理時間: \(String(format: "%.0f", processingTimeMs))ms (\(String(format: "%.2f", processingTimeMs / 1000))秒)")
                            
                            // タイミング詳細があれば表示
                            if let timingDetails = json["timing_details"] as? [String: Any] {
                                print("⏱️ [テーマ生成] バックエンド詳細タイミング:")
                                if let dbFetch = timingDetails["db_fetch"] as? Double {
                                    print("   - DB取得: \(String(format: "%.0f", dbFetch))ms")
                                }
                                if let dataConversion = timingDetails["data_conversion"] as? Double {
                                    print("   - データ変換: \(String(format: "%.0f", dataConversion))ms")
                                }
                                if let geminiApi = timingDetails["gemini_api"] as? Double {
                                    print("   - Gemini API: \(String(format: "%.0f", geminiApi))ms")
                                }
                                if let dbSave = timingDetails["db_save"] as? Double {
                                    print("   - DB保存: \(String(format: "%.0f", dbSave))ms")
                                }
                                if let total = timingDetails["total"] as? Double {
                                    print("   - 合計: \(String(format: "%.0f", total))ms")
                                }
                            }
                        }
                    }
                    
                    // 全体の処理時間を計算
                    let totalDuration = Date().timeIntervalSince(startTime)
                    print("⏱️ [テーマ生成] 全体処理時間（Swift側）: \(String(format: "%.2f", totalDuration))秒 (\(String(format: "%.0f", totalDuration * 1000))ms)")
                    print("✅ [テーマ生成] 処理完了")
                    
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let totalDuration = Date().timeIntervalSince(startTime)
                    print("❌ [テーマ生成] サーバーエラー（処理時間: \(String(format: "%.2f", totalDuration))秒）")
                    throw StoryServiceError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    let totalDuration = Date().timeIntervalSince(startTime)
                    print("❌ [テーマ生成] 予期しないエラー（処理時間: \(String(format: "%.2f", totalDuration))秒）")
                    throw StoryServiceError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
        } catch let e as StoryServiceError {
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [テーマ生成] StoryServiceError（処理時間: \(String(format: "%.2f", totalDuration))秒）: \(e)")
            throw e
        } catch {
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [テーマ生成] ネットワークエラー（処理時間: \(String(format: "%.2f", totalDuration))秒）: \(error)")
            throw StoryServiceError.networkError(error)
        }
    }
}
