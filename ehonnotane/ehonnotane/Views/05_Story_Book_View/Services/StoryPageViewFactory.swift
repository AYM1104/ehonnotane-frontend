import SwiftUI

/// StoryからBookページビューを生成するファクトリークラス
struct StoryPageViewFactory {
    /// StoryからBookページのビュー配列を生成
    /// - Parameter story: 絵本のストーリーデータ
    /// - Parameter authManager: 認証マネージャー（画像読み込み用）
    /// - Returns: 各ページのビュー配列
    static func createBookPages(from story: Story, authManager: AuthManager? = nil) -> [AnyView] {
        return story.pages.map { page in
            createPageView(from: page, authManager: authManager)
        }
    }
    
    /// 単一のページからビューを生成
    /// - Parameter page: ページデータ
    /// - Parameter authManager: 認証マネージャー
    /// - Returns: ページのビュー
    private static func createPageView(from page: StoryPage, authManager: AuthManager? = nil) -> AnyView {
        // 画像URLがある場合
        if let imageURLString = page.imageURL,
           let imageURL = URL(string: imageURLString) {
            // 表紙の場合はテキストエリアなしで画像のみ表示
            if page.isCover {
                return AnyView(
                    BookRemoteImagePage(
                        imageURL,
                        contentInset: 0,
                        fit: .fill,
                        text: "",  // 表紙はテキストなし
                        textAreaHeight: 0,
                        authManager: authManager
                    )
                )
            } else {
                // 通常ページはテキスト付きで表示
                return AnyView(
                    BookRemoteImagePage(
                        imageURL,
                        contentInset: 0,
                        fit: .fill,
                        text: page.text,
                        textAreaHeight: 150,
                        authManager: authManager
                    )
                )
            }
        } else {
            // 画像がない場合はテキストのみ
            return AnyView(
                createTextOnlyPageView(text: page.text)
            )
        }
    }
    
    /// テキストのみのページビューを生成
    /// - Parameter text: 表示するテキスト
    /// - Returns: テキストのみのビュー
    private static func createTextOnlyPageView(text: String) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

