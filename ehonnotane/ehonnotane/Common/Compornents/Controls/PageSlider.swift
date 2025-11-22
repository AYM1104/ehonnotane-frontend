import SwiftUI

/// ページスライダーコンポーネント（標準のTabViewを使用）
struct PageSlider<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    // 入力
    let pages: Data
    @Binding var currentIndex: Int
    let content: (Data.Element) -> Content

    init(_ pages: Data,
         currentIndex: Binding<Int>,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.pages = pages
        self._currentIndex = currentIndex
        self.content = content
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 8) // 左側の余白
                    content(page)
                    Spacer()
                        .frame(width: 8) // 右側の余白
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

#Preview {
    PageSliderPreviewView()
}

struct PageSliderPreviewView: View {
    @State private var index: Int = 0
    struct PreviewPage: Identifiable {
        let id = UUID()
        let content: String
    }
    
    let pages = [
        PreviewPage(content: "ページ1"),
        PreviewPage(content: "ページ2"),
        PreviewPage(content: "ページ3")
    ]
    
    var body: some View {
        PageSlider(pages, currentIndex: $index) { page in
            VStack {
                Text(page.content)
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
            .cornerRadius(16)
        }
        .frame(height: 300)
        .padding()
    }
}
