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
    
    @State private var showTip = true
    
    var body: some View {
        ZStack {
            // 半透明の背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                
                // 濃いめの半透明パネル
                VStack(spacing: 16) {
                    // アニメーションするキャラクター
                    BookCharacterAnimation()
                        .frame(width: 80, height: 96)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                    
                    // ティップス（キャラクターとプログレスバーの間）
                    if !currentTip.isEmpty {
                        MainText(text: currentTip, fontSize: 14)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }
                    
                    // 進捗表示（ドット + パーセンテージ）
                    VStack(spacing: 12) {
                        // 進捗ドット
                        ProgressDotsView(totalPages: totalPages, currentPage: currentPage)
                        
                        // パーセンテージと推定時間
                        VStack(spacing: 4) {
                            MainText(text: "\(Int(progress * 100))%", fontSize: 28)
                            
                            if !estimatedTime.isEmpty {
                                MainText(text: estimatedTime, fontSize: 12)
                            }
                        }
                    }
                    
                    // ステータスメッセージ
                    MainText(text: message, fontSize: 16)
                        .padding(.horizontal, 24)
                    

                    
                    // 生成済みページプレビュー
                    if !generatedPreviews.isEmpty {
                        VStack(spacing: 8) {
                            MainText(text: String(localized: "generation.pages_ready"), fontSize: 14)
                            
                            PagePreviewsView(
                                generatedPreviews: generatedPreviews,
                                totalPages: totalPages
                            )
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                )
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }

    }
}

#Preview("開始時（5%）") {
    EnhancedGenerationProgressView(
        progress: 0.05,
        message: "物語を書いています...",
        estimatedTime: "計算中...",
        currentTip: "どんな絵本ができるかな？",
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
        currentTip: "たのしみだね！",
        totalPages: 5,
        currentPage: 0,
        generatedPreviews: [:]
    )
}

#Preview("画像生成中（65%）") {
    EnhancedGenerationProgressView(
        progress: 0.65,
        message: "表紙を描いています...",
        estimatedTime: "残り約45秒",
        currentTip: "えほんができたら みんなにじまんしよう",
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
        currentTip: "もうすこしで できあがるよ",
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
