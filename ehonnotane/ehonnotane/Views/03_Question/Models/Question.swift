import Foundation

// 質問モデル群（アプリ全体で共通利用）
struct QuestionOption: Codable, Identifiable {
    var id: String { value }
    let value: String
    let label: String
}

struct Question: Codable, Identifiable {
    // バックエンドの field を安定IDとして利用
    var id: String { field }
    let field: String
    let question: String
    let type: String
    let placeholder: String?
    let required: Bool?
    let options: [QuestionOption]?
}


// API レスポンスモデル（View から分離してメインアクター分離の警告を回避）
struct QuestionAPIResponse: Decodable {
    let questions: [Question]
    let story_setting_id: Int
    let message: String?
    let processing_time_ms: Double?
}


