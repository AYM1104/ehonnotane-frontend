import Foundation

// MARK: - テーマプロットレスポンス
struct ThemePlotResponse: Codable, Identifiable {
    let storyPlotId: Int
    let title: String
    let description: String?
    let selectedTheme: String
    
    var id: Int { storyPlotId }
    
    enum CodingKeys: String, CodingKey {
        case storyPlotId = "story_plot_id"
        case title
        case description
        case selectedTheme = "selected_theme"
    }
}

// MARK: - テーマプロット一覧レスポンス
struct ThemePlotsListResponse: Codable {
    let items: [ThemePlotResponse]
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case items
        case count
    }
}

// MARK: - テーマページのデータモデル（ThemeSelectView用）
struct ThemePage: Identifiable {
    let id: String
    let title: String
    let content: String
    let storyPlotId: Int
    let selectedTheme: String
    
    init(id: String = UUID().uuidString, title: String, content: String, storyPlotId: Int, selectedTheme: String) {
        self.id = id
        self.title = title
        self.content = content
        self.storyPlotId = storyPlotId
        self.selectedTheme = selectedTheme
    }
    
    // ThemePlotResponseからThemePageに変換
    init(from themePlot: ThemePlotResponse) {
        self.id = "\(themePlot.storyPlotId)"
        self.title = themePlot.title
        self.content = themePlot.description ?? "テーマの説明"
        self.storyPlotId = themePlot.storyPlotId
        self.selectedTheme = themePlot.selectedTheme
    }
}

// MARK: - ストーリーページ
struct StoryPage: Identifiable {
    let id: Int
    let text: String
    let imageURL: String?
    let isCover: Bool
    
    init(id: Int, text: String, imageURL: String?, isCover: Bool = false) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.isCover = isCover
    }
}

// MARK: - ストーリー
struct Story {
    let title: String
    let pages: [StoryPage]
    
    init(title: String, pages: [StoryPage]) {
        self.title = title
        self.pages = pages
    }
    
    // StorybookResponseからStoryに変換
    init(from response: StorybookResponse) {
        self.title = response.title
        
        var pages: [StoryPage] = []
        
        // 表紙を追加（coverImageUrlがある場合）
        if let coverImageUrl = response.coverImageUrl, !coverImageUrl.isEmpty {
            pages.append(StoryPage(
                id: 0,
                text: response.title,
                imageURL: coverImageUrl,
                isCover: true
            ))
        }
        
        // 各ページを追加
        let pageTexts: [(String?, String?)] = [
            (response.page1, response.page1ImageUrl),
            (response.page2, response.page2ImageUrl),
            (response.page3, response.page3ImageUrl),
            (response.page4, response.page4ImageUrl),
            (response.page5, response.page5ImageUrl),
            (response.page6, response.page6ImageUrl),
            (response.page7, response.page7ImageUrl),
            (response.page8, response.page8ImageUrl),
            (response.page9, response.page9ImageUrl),
            (response.page10, response.page10ImageUrl)
        ]
        
        var pageIndex = pages.count
        for (text, imageURL) in pageTexts {
            if let text = text, !text.isEmpty {
                pages.append(StoryPage(
                    id: pageIndex,
                    text: text,
                    imageURL: imageURL,
                    isCover: false
                ))
                pageIndex += 1
            }
        }
        
        self.pages = pages
    }
}

// MARK: - 絵本レスポンス
struct StorybookResponse: Codable {
    let id: Int
    let storyPlotId: Int
    let userId: String
    let childId: Int?
    let title: String
    let description: String?
    let keywords: [String]?
    let storyContent: String
    let page1: String
    let page2: String
    let page3: String
    let page4: String
    let page5: String
    let page6: String?
    let page7: String?
    let page8: String?
    let page9: String?
    let page10: String?
    let coverImageUrl: String?
    let page1ImageUrl: String?
    let page2ImageUrl: String?
    let page3ImageUrl: String?
    let page4ImageUrl: String?
    let page5ImageUrl: String?
    let page6ImageUrl: String?
    let page7ImageUrl: String?
    let page8ImageUrl: String?
    let page9ImageUrl: String?
    let page10ImageUrl: String?
    let imageGenerationStatus: String
    let isFavorite: Bool?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case storyPlotId = "story_plot_id"
        case userId = "user_id"
        case childId = "child_id"
        case title
        case description
        case keywords
        case storyContent = "story_content"
        case page1 = "page_1"
        case page2 = "page_2"
        case page3 = "page_3"
        case page4 = "page_4"
        case page5 = "page_5"
        case page6 = "page_6"
        case page7 = "page_7"
        case page8 = "page_8"
        case page9 = "page_9"
        case page10 = "page_10"
        case coverImageUrl = "cover_image_url"
        case page1ImageUrl = "page_1_image_url"
        case page2ImageUrl = "page_2_image_url"
        case page3ImageUrl = "page_3_image_url"
        case page4ImageUrl = "page_4_image_url"
        case page5ImageUrl = "page_5_image_url"
        case page6ImageUrl = "page_6_image_url"
        case page7ImageUrl = "page_7_image_url"
        case page8ImageUrl = "page_8_image_url"
        case page9ImageUrl = "page_9_image_url"
        case page10ImageUrl = "page_10_image_url"
        case imageGenerationStatus = "image_generation_status"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 絵本リストアイテム
struct StoryBookListItem: Codable, Identifiable {
    let id: Int
    let storyPlotId: Int
    let userId: String
    let title: String
    let coverImageUrl: String?
    let createdAt: String
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case storyPlotId = "story_plot_id"
        case userId = "user_id"
        case title
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
        case isFavorite = "is_favorite"
    }
}

// MARK: - 日別絵本一覧レスポンス
struct StoryBookListByDateResponse: Codable {
    let books: [StorybookResponse]
    let folderCount: Int
    
    enum CodingKeys: String, CodingKey {
        case books
        case folderCount = "folder_count"
    }
}

// MARK: - 週間統計レスポンス
struct WeeklyStatsResponse: Codable {
    let weekTotal: Int
    let weekStart: String
    let weekEnd: String
    let dailyCounts: [DailyCount]
    
    enum CodingKeys: String, CodingKey {
        case weekTotal = "week_total"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case dailyCounts = "daily_counts"
    }
}

// MARK: - 日別カウント
struct DailyCount: Codable {
    let day: String
    let date: String
    let count: Int
}

// MARK: - ユーザー情報レスポンス
struct UserInfoResponse: Codable {
    let userId: String
    let userName: String
    let email: String?
    let name: String?
    let picture: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case email
        case name
        case picture
    }
}

// MARK: - アカウント削除レスポンスDTO
struct AccountDeletionResponseDTO: Codable {
    let message: String
    let userId: String
    let deletedStorybooks: Int
    let deletedStoryPlots: Int
    let deletedStorySettings: Int
    let deletedUploadImages: Int
    let storageCleanup: StorageCleanupResponse
    let auth0Cleanup: Auth0CleanupResponse
    
    enum CodingKeys: String, CodingKey {
        case message
        case userId = "user_id"
        case deletedStorybooks = "deleted_storybooks"
        case deletedStoryPlots = "deleted_story_plots"
        case deletedStorySettings = "deleted_story_settings"
        case deletedUploadImages = "deleted_upload_images"
        case storageCleanup = "storage_cleanup"
        case auth0Cleanup = "auth0_cleanup"
    }
}

// MARK: - ストレージクリーンアップレスポンス
struct StorageCleanupResponse: Codable {
    let enabled: Bool
    let uploadsRemoved: Bool?
    let generatedRemoved: Bool?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case uploadsRemoved = "uploads_removed"
        case generatedRemoved = "generated_removed"
        case error
    }
}

// MARK: - Auth0クリーンアップレスポンス
struct Auth0CleanupResponse: Codable {
    let enabled: Bool
    let accountRemoved: Bool?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case accountRemoved = "account_removed"
        case error
    }
}
