import SwiftUI

/// 生成済みページのプレビュー表示コンポーネント
/// 完成したページをサムネイルで表示し、進捗を視覚化
struct PagePreviewsView: View {
    let generatedPreviews: [Int: String]
    let totalPages: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<totalPages + 1, id: \.self) { pageIndex in
                    if let imageURL = generatedPreviews[pageIndex] {
                        // 生成完了
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            Text(pageIndex == 0 ? "表紙" : "\(pageIndex)P")
                                                .font(.custom("ZenMaruGothic-Bold", size: 10))
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(4)
                                        }
                                    )
                                    .transition(.scale.combined(with: .opacity))
                            case .failure:
                                placeholderView(pageIndex: pageIndex, status: "エラー")
                            case .empty:
                                placeholderView(pageIndex: pageIndex, status: "読込中")
                            @unknown default:
                                placeholderView(pageIndex: pageIndex, status: "...")
                            }
                        }
                    } else {
                        // 未生成
                        placeholderView(
                            pageIndex: pageIndex,
                            status: pageIndex == generatedPreviews.count ? "作成中" : "待機中"
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 110)
    }
    
    /// プレースホルダー表示
    private func placeholderView(pageIndex: Int, status: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 90)
            .overlay(
                VStack(spacing: 4) {
                    if status == "作成中" {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                    }
                    Text(status)
                        .font(.custom("ZenMaruGothic-Regular", size: 10))
                        .foregroundColor(status == "待機中" ? .gray : .white)
                }
            )
    }
}

#Preview("未生成") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            Text("未生成状態")
                .foregroundColor(.white)
                .font(.headline)
            
            PagePreviewsView(
                generatedPreviews: [:],
                totalPages: 5
            )
        }
    }
}

#Preview("表紙のみ完成") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            Text("表紙のみ完成")
                .foregroundColor(.white)
                .font(.headline)
            
            PagePreviewsView(
                generatedPreviews: [
                    0: "https://picsum.photos/200/300"
                ],
                totalPages: 5
            )
        }
    }
}

#Preview("2ページ完成") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            Text("2ページ完成（作成中）")
                .foregroundColor(.white)
                .font(.headline)
            
            PagePreviewsView(
                generatedPreviews: [
                    0: "https://picsum.photos/200/301",
                    1: "https://picsum.photos/200/302"
                ],
                totalPages: 5
            )
        }
    }
}

#Preview("全て完成") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            Text("5ページ全完成")
                .foregroundColor(.white)
                .font(.headline)
            
            PagePreviewsView(
                generatedPreviews: [
                    0: "https://picsum.photos/200/300",
                    1: "https://picsum.photos/200/301",
                    2: "https://picsum.photos/200/302",
                    3: "https://picsum.photos/200/303",
                    4: "https://picsum.photos/200/304",
                    5: "https://picsum.photos/200/305"
                ],
                totalPages: 5
            )
        }
    }
}

#Preview("10ページ版") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            Text("10ページ版（6ページ完成）")
                .foregroundColor(.white)
                .font(.headline)
            
            PagePreviewsView(
                generatedPreviews: [
                    0: "https://picsum.photos/200/300",
                    1: "https://picsum.photos/200/301",
                    2: "https://picsum.photos/200/302",
                    3: "https://picsum.photos/200/303",
                    4: "https://picsum.photos/200/304",
                    5: "https://picsum.photos/200/305"
                ],
                totalPages: 10
            )
        }
    }
}
