import SwiftUI

/// 強化された生成進捗表示ビュー
/// 進捗バー、推定時間、ティップス、ページプレビューを統合した総合的なローディング画面
struct EnhancedGenerationProgressView: View {
    let progress: Double
    let message: String
    let estimatedTime: String
    let currentTip: String
    let totalPages: Int
    let currentPage: Int
    let generatedPreviews: [Int: String]
    
    @State private var characterOffset: CGFloat = 0
    @State private var showTip = true
    
    var body: some View {
        ZStack {
            // 不透明背景（背後のカードが透けないようにする）
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // アニメーションするキャラクター
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .offset(y: characterOffset)
                    .shadow(color: .white.opacity(0.3), radius: 10)
                
                // 進捗表示（ドット + パーセンテージ）
                VStack(spacing: 16) {
                    // 進捗ドット
                    ProgressDotsView(totalPages: totalPages, currentPage: currentPage)
                    
                    // パーセンテージと推定時間
                    VStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.custom("ZenMaruGothic-Bold", size: 32))
                            .foregroundColor(.white)
                        
                        if !estimatedTime.isEmpty {
                            Text(estimatedTime)
                                .font(.custom("ZenMaruGothic-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // ステータスメッセージ
                Text(message)
                    .font(.custom("ZenMaruGothic-Bold", size: 18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(minHeight: 50)
                
                // ティップス（フェードイン・アウト）
                if !currentTip.isEmpty {
                    Text(currentTip)
                        .font(.custom("ZenMaruGothic-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(minHeight: 60)
                        .transition(.opacity)
                } else {
                    // ティップスが空の時もスペースを確保（レイアウトのジャンプを防ぐ）
                    Spacer()
                        .frame(height: 60)
                }
                
                // 生成済みページプレビュー
                if !generatedPreviews.isEmpty {
                    VStack(spacing: 8) {
                        Text("できてきたよ！")
                            .font(.custom("ZenMaruGothic-Bold", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        PagePreviewsView(
                            generatedPreviews: generatedPreviews,
                            totalPages: totalPages
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            // キャラクターアニメーション開始
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                characterOffset = -15
            }
        }
    }
}

#Preview("開始時（5%）") {
    EnhancedGenerationProgressView(
        progress: 0.05,
        message: "物語を書いています...",
        estimatedTime: "計算中...",
        currentTip: "✨ すてきな えほんを つくっているよ",
        totalPages: 5,
        currentPage: 0,
        generatedPreviews: [:]
    )
}

#Preview("物語生成中（15%）") {
    EnhancedGenerationProgressView(
        progress: 0.15,
        message: "絵を描いています...",
        estimatedTime: "残り約2分",
        currentTip: "🎨 きれいな いろで ぬっているよ",
        totalPages: 5,
        currentPage: 0,
        generatedPreviews: [:]
    )
}

#Preview("画像生成中（65%）") {
    EnhancedGenerationProgressView(
        progress: 0.65,
        message: "絵を描いています... (4/5ページ)",
        estimatedTime: "残り約45秒",
        currentTip: "📚 たのしい おはなしに なるかな？",
        totalPages: 5,
        currentPage: 4,
        generatedPreviews: [:]
    )
}

#Preview("完了間近（99%）") {
    EnhancedGenerationProgressView(
        progress: 0.99,
        message: "えほんを仕上げています...",
        estimatedTime: "残り約5秒",
        currentTip: "🌟 もうすこしで できあがるよ",
        totalPages: 5,
        currentPage: 5,
        generatedPreviews: [:]
    )
}

#Preview("10ページ版") {
    EnhancedGenerationProgressView(
        progress: 0.80,
        message: "絵を描いています... (8/10ページ)",
        estimatedTime: "残り約30秒",
        currentTip: "🌈 カラフルな せかいを つくっているよ",
        totalPages: 10,
        currentPage: 8,
        generatedPreviews: [:]
    )
}
