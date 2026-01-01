import Foundation

// MARK: - 進捗情報の構造体

struct GenerationProgress: Codable {
    let storybookId: Int
    let currentPage: Int
    let totalPages: Int
    let progressPercent: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case storybookId = "storybook_id"
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case progressPercent = "progress_percent"
        case status
    }
}

// MARK: - テーマ選択フロー用のレスポンスモデル

struct ThemeSelectionResponse: Codable {
    let storybookId: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case storybookId = "storybook_id"
        case message
    }
}

struct StoryGenerationResponse: Codable {
    let storyPlotId: Int
    let storySettingId: Int
    let selectedTheme: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case storyPlotId = "story_plot_id"
        case storySettingId = "story_setting_id"
        case selectedTheme = "selected_theme"
        case message
    }
}

struct ImageGenerationResponse: Codable {
    let message: String
    let generatedImages: [String]
    
    enum CodingKeys: String, CodingKey {
        case message
        case generatedImages = "generated_images"
    }
    
    init(message: String, generatedImages: [String]) {
        self.message = message
        self.generatedImages = generatedImages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        self.generatedImages = try container.decodeIfPresent([String].self, forKey: .generatedImages) ?? []
    }
}

struct ImageUrlUpdateResponse: Codable {
    let message: String
    let updatedPages: [String]
    let updatedPagesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case updatedPages = "updated_pages"
    }
    
    init(message: String, updatedPages: [String]) {
        self.message = message
        self.updatedPages = updatedPages
        self.updatedPagesCount = updatedPages.count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        if let pagesArray = try? container.decode([String].self, forKey: .updatedPages) {
            self.updatedPages = pagesArray
            self.updatedPagesCount = pagesArray.count
        } else if let pagesInt = try? container.decode(Int.self, forKey: .updatedPages) {
            self.updatedPages = []
            self.updatedPagesCount = max(0, pagesInt)
        } else {
            self.updatedPages = []
            self.updatedPagesCount = 0
        }
    }
}

// MARK: - カレンダー用レスポンス

struct CreatedDaysResponse: Codable {
    let year: Int
    let month: Int
    let days: [Int]
}

// MARK: - ストーリー設定サマリー

struct StorySettingSummary: Codable {
    let id: Int
    let uploadImageId: Int
    let titleSuggestion: String
    let protagonistName: String
    let protagonistType: String
    let settingPlace: String
    let tone: String
    let targetAge: String
    let language: String
    let readingLevel: String
    let styleGuideline: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uploadImageId = "upload_image_id"
        case titleSuggestion = "title_suggestion"
        case protagonistName = "protagonist_name"
        case protagonistType = "protagonist_type"
        case settingPlace = "setting_place"
        case tone
        case targetAge = "target_age"
        case language
        case readingLevel = "reading_level"
        case styleGuideline = "style_guideline"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
