import SwiftUI

// MARK: - メイン背景ビュー（Background）
struct Background<Content: View>: View {
    let content: () -> Content
    
    @State private var mounted = false
    @State private var viewport: CGSize? = nil
    @State private var farStars: [Star] = []
    @State private var midStars: [Star] = []
    @State private var nearStars: [Star] = []
    
    init(@ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // グラデーション背景（fixed inset-0 bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900）
                LinearGradient(
                    colors: [
                        Color(red: 0.5, green: 0.2, blue: 0.6),  // purple-900
                        Color(red: 0.1, green: 0.2, blue: 0.6),  // blue-900
                        Color(red: 0.2, green: 0.1, blue: 0.5)   // indigo-900
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 星空（マウント完了まで描画しない）
                if mounted {
                    StarField(far: farStars, mid: midStars, near: nearStars)
                }
                
                // コンテンツ（relative z-10）
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: geometry.size) { oldSize, newSize in
                // サイズ変化時の暗黙アニメーションを無効化
                withAnimation(nil) {
                    updateViewport(size: newSize)
                }
            }
            .onAppear {
                // 初回マウント時の暗黙アニメーションを無効化
                withAnimation(nil) {
                    mounted = true
                    updateViewport(size: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // ビューポートを更新して星を再生成する関数
    private func updateViewport(size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        viewport = size
        
        let width = size.width
        let height = size.height
        let area = width * height
        
        // 画面サイズに応じた密度調整
        let densityScale: CGFloat = {
            if width < 600 { return 0.6 }
            if width < 900 { return 0.8 }
            return 1.0
        }()
        
        // 星の数を計算（TypeScriptの実装と同じ）
        let farCount = min(180, Int(area * 0.00004 * densityScale))
        let midCount = min(240, Int(area * 0.00006 * densityScale))
        let nearCount = min(140, Int(area * 0.00003 * densityScale))
        
        // 星を生成
        farStars = generateStars(count: farCount, width: width, height: height)
        midStars = generateStars(count: midCount, width: width, height: height)
        nearStars = generateStars(count: nearCount, width: width, height: height)
    }
}

// MARK: - Preview
#Preview {
    Background {

    }
}
