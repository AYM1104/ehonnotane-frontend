import SwiftUI

// MARK: - 絵本を表示するコンポーネント

/// ページカール効果を持つ絵本ビュー
struct Book: View {
    let pages: [AnyView]
    let title: String?
    let showTitle: Bool
    let heightRatio: CGFloat
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let paperColor: Color
    let onPageChange: ((Int) -> Void)?
    
    @State private var currentIndex: Int = 0
    
    init(
        pages: [AnyView],
        title: String? = nil,
        showTitle: Bool = true,
        heightRatio: CGFloat = 1.0,
        aspectRatio: CGFloat = 9.0/16.0,
        cornerRadius: CGFloat = 16,
        paperColor: Color = .white,
        onPageChange: ((Int) -> Void)? = nil
    ) {
        self.pages = pages
        self.title = title
        self.showTitle = showTitle
        self.heightRatio = heightRatio
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.paperColor = paperColor
        self.onPageChange = onPageChange
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width / aspectRatio
            
            VStack(spacing: 0) {
                // 絵本本体 (PageCurlを使用)
                PageCurl(pages: pages, currentIndex: $currentIndex)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .background(Color.clear)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)
                    .onChange(of: currentIndex) { newValue in
                        onPageChange?(newValue)
                    }
                
                // ページインジケーターなどが必要な場合はここに追加
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Preview

#Preview("デモ絵本（ローカル）") {
    VStack(spacing: 12) {
        // 1) ローカル画像（SF Symbolsを使用）
        let p1 = BookPage(Image(systemName: "hare.fill"), contentInset: 40, fit: BookPage.FitMode.fit, background: Color.white, text: "むかしむかし、あるところに、とてもかわいいうさぎがいました。")
        let p2 = BookPage(Image(systemName: "tortoise.fill"), contentInset: 40, fit: BookPage.FitMode.fit, background: Color.white, text: "そのうさぎは、毎日森の中を散歩するのが大好きでした。")

        // 2) リモート画像（実行時に任意のURLへ差し替え推奨）
        let remotePages: [AnyView] = {
            if #available(iOS 15.0, *) {
                let u1 = URL(string: "https://picsum.photos/900/1600")!
                let u2 = URL(string: "https://picsum.photos/1000/1600")!
                return [
                    AnyView(BookRemoteImagePage(u1, contentInset: 0, fit: BookRemoteImagePage.FitMode.fill, text: "ある日、うさぎは美しい花を見つけました。")),
                    AnyView(BookRemoteImagePage(u2, contentInset: 0, fit: BookRemoteImagePage.FitMode.fill, text: "花は「こんにちは」と笑顔で言いました。"))
                ]
            } else {
                return []
            }
        }()

        Book(
            pages: [AnyView(p1), AnyView(p2)] + remotePages,
            title: "デモのえほん",
            showTitle: false,
            heightRatio: 1,
            aspectRatio: 9.0/16.0,
            cornerRadius: 30,
            paperColor: Color(red: 252/255, green: 252/255, blue: 252/255)
        )
        .padding()
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
