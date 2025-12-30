import SwiftUI

/// 進捗ドット表示コンポーネント
/// ページごとの進捗を視覚的に表示
struct ProgressDotsView: View {
    let totalPages: Int
    let currentPage: Int
    
    // PrimaryButtonと同じグラデーションカラー（中間色のteal-500を使用）
    private let activeColor = Color(red: 20/255, green: 184/255, blue: 166/255)
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages + 1, id: \.self) { index in
                Circle()
                    .fill(index <= currentPage ? activeColor : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: index == currentPage ? 2 : 0)
                    )
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

#Preview("5ページ - 各段階") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("開始時")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 5, currentPage: 0)
            }
            
            VStack(spacing: 8) {
                Text("進行中（2ページ目）")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 5, currentPage: 2)
            }
            
            VStack(spacing: 8) {
                Text("完了")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 5, currentPage: 5)
            }
        }
        .padding()
    }
}

#Preview("10ページ版") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("10ページ - 開始時")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 10, currentPage: 0)
            }
            
            VStack(spacing: 8) {
                Text("10ページ - 中間")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 10, currentPage: 5)
            }
            
            VStack(spacing: 8) {
                Text("10ページ - 完了")
                    .foregroundColor(.white)
                ProgressDotsView(totalPages: 10, currentPage: 10)
            }
        }
        .padding()
    }
}

#Preview("3ページ版") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            Text("3ページ - 進行中")
                .foregroundColor(.white)
            ProgressDotsView(totalPages: 3, currentPage: 1)
        }
        .padding()
    }
}
