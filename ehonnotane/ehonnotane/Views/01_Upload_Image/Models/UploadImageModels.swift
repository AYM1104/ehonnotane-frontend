import Foundation

// MARK: - 画像アップロードレスポンス
struct UploadImageResponse: Codable, Identifiable {
    let id: Int
    let user_id: String?
    let file_name: String?
    let file_url: String?
    let content_type: String?
    let created_at: String?
    let updated_at: String?
}

// MARK: - 署名付きURLレスポンス
struct SignedUrlResponse: Codable {
    let signed_url: String
    let expires_in: Int?
}

// MARK: - 認証レスポンス
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

// MARK: - 物語設定作成レスポンス
struct StorySettingCreateResponse: Codable {
    let story_setting_id: Int
    let generated_data: StorySettingGeneratedData?
}

// MARK: - 物語設定生成データ
struct StorySettingGeneratedData: Codable {
    let title_suggestion: String?
    let protagonist_name: String?
    let protagonist_type: String?
    let setting_place: String?
    let tone: String?
    let target_age: String?
    let language: String?
    let reading_level: String?
    let style_guideline: String?
}

