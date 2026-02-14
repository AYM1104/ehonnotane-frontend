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
        
        // pages 配列から各ページを追加
        if let responsePages = response.pages {
            var pageIndex = pages.count
            for pageData in responsePages.sorted(by: { $0.pageNumber < $1.pageNumber }) {
                if !pageData.content.isEmpty {
                    pages.append(StoryPage(
                        id: pageIndex,
                        text: pageData.content,
                        imageURL: pageData.imageUrl,
                        isCover: false
                    ))
                    pageIndex += 1
                }
            }
        }
        
        self.pages = pages
    }
}

// MARK: - ページデータ（APIレスポンス用）
struct PageData: Codable {
    let pageNumber: Int
    let content: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case content
        case imageUrl = "image_url"
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
    let coverImageUrl: String?
    let pages: [PageData]?
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
        case coverImageUrl = "cover_image_url"
        case pages
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
    let childId: Int?
    let title: String
    let coverImageUrl: String?
    let createdAt: String
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case storyPlotId = "story_plot_id"
        case userId = "user_id"
        case childId = "child_id"
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

#if DEBUG
extension StorybookResponse {
    /// プレビューでログインせずに表示するためのダミーデータ
    static var previewSample: StorybookResponse {
        StorybookResponse(
            id: 1,
            storyPlotId: 999,
            userId: "preview-user",
            childId: nil,
            title: "プレビューの森へようこそ",
            description: "ログイン不要でプレビュー確認するためのサンプル絵本です。",
            keywords: ["プレビュー", "サンプル"],
            coverImageUrl: "https://picsum.photos/seed/ehon-cover/900/1600",
            pages: [
                PageData(pageNumber: 1, content: "ある日、ちいさなタネが風に乗って森へたどり着きました。", imageUrl: "https://picsum.photos/seed/ehon-page1/900/1600"),
                PageData(pageNumber: 2, content: "タネは優しい妖精と出会い、不思議な冒険へ進みます。", imageUrl: "https://picsum.photos/seed/ehon-page2/900/1600"),
                PageData(pageNumber: 3, content: "森の動物たちが集まり、タネを応援してくれました。", imageUrl: "https://picsum.photos/seed/ehon-page3/900/1600"),
                PageData(pageNumber: 4, content: "タネは光る泉で大切な願いを叶える方法を学びます。", imageUrl: "https://picsum.photos/seed/ehon-page4/900/1600"),
                PageData(pageNumber: 5, content: "願いが叶い、タネは大きな木に成長して森を照らしました。", imageUrl: "https://picsum.photos/seed/ehon-page5/900/1600")
            ],
            imageGenerationStatus: "completed",
            isFavorite: false,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
    }
}
#endif
