import SwiftUI

// MARK: - 星のレイヤー（StarLayer）
// 星を配置するレイヤー
struct StarLayer: View {
    let stars: [Star]
    let layerType: LayerType
    
    var body: some View {
        ForEach(stars) { star in
            StarView(star: star, layerType: layerType)
        }
    }
}

// MARK: - 個別の星ビュー（StarView）
struct StarView: View {
    let star: Star
    let layerType: LayerType
    
    @State private var twinkleOpacity: Double = 1.0
    @State private var twinkleScale: CGFloat = 1.0
    @State private var floatY: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 塗りつぶし
            DiamondShape()
                .fill(starColor)
            
            // 黒枠線（opacity: 0.2）
            DiamondShape()
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            
            // 黒枠線（通常）
            DiamondShape()
                .stroke(Color.black, lineWidth: 1)
        }
        .frame(width: star.size, height: star.size)
        .opacity(layerOpacity)
        .rotationEffect(.degrees(star.rotate))
        .scaleEffect(twinkleScale)
        .blur(radius: blurRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)
        .offset(y: floatY)
        .position(x: star.left, y: star.top)
        .onAppear {
            startAnimations()
        }
    }
    
    // レイヤータイプごとの透明度
    private var layerOpacity: Double {
        switch layerType {
        case .far:
            return star.opacity * 0.8 * twinkleOpacity  // 少し薄めに表示
        case .mid:
            return star.opacity * twinkleOpacity        // そのままの明るさ
        case .near:
            return star.opacity * twinkleOpacity        // はっきり見える
        }
    }
    
    // レイヤータイプごとのブラー効果
    private var blurRadius: CGFloat {
        switch layerType {
        case .far:
            return 0.2  // ほんの少しぼかして遠さを演出
        case .mid:
            return 0
        case .near:
            return 0
        }
    }
    
    // レイヤータイプごとのシャドウ効果（近景だけ光をにじませる）
    private var shadowColor: Color {
        layerType == .near ? Color.white.opacity(0.35) : Color.clear
    }
    
    private var shadowRadius: CGFloat {
        layerType == .near ? 4 : 0
    }
    
    // 星の色を取得（SVGファイルと同じカラーコード）
    private var starColor: Color {
        switch star.src {
        case "yellow":
            return Color(hex: "#FFC31C")  // star-yellow.svg
        case "blue":
            return Color(hex: "#77C7E3")  // star-blue.svg
        case "green":
            return Color(hex: "#00AA9C")  // star-green.svg
        case "purple":
            return Color(hex: "#A481B4")  // star-purple.svg
        case "red":
            return Color(hex: "#E3662A")  // star-red.svg
        case "white":
            return Color(hex: "#F8F8FA")  // star-white.svg
        default:
            return Color(hex: "#F8F8FA")
        }
    }
    
    // アニメーションを開始
    private func startAnimations() {
        // レイヤータイプごとのアニメーション設定
        let (twinkleDuration, floatDuration, floatDelay) = getAnimationParams()
        
        // 点滅アニメーション（twinkle）
        // 0%: opacity: 0.45, scale: 0.95（少し暗く小さめ）
        // 100%: opacity: 1.0, scale: 1.05（明るく大きめ）
        withAnimation(
            .easeInOut(duration: twinkleDuration)
            .repeatForever(autoreverses: true)
            .delay(star.twinkleDelay)
        ) {
            twinkleOpacity = 0.45
            twinkleScale = 0.95
        }
        
        // 上下に揺れるアニメーション（floatY）
        // -2px ⇔ 2px
        withAnimation(
            .easeInOut(duration: floatDuration)
            .repeatForever(autoreverses: true)
            .delay(floatDelay)
        ) {
            floatY = 2
        }
    }
    
    // レイヤータイプごとのアニメーションパラメータ
    private func getAnimationParams() -> (twinkleDuration: Double, floatDuration: Double, floatDelay: Double) {
        switch layerType {
        case .far:
            return (
                twinkleDuration: star.twinkleDur,
                floatDuration: star.floatDur,
                floatDelay: star.twinkleDelay / 2
            )
        case .mid:
            return (
                twinkleDuration: star.twinkleDur,
                floatDuration: star.floatDur * 0.7,
                floatDelay: star.twinkleDelay / 3
            )
        case .near:
            return (
                twinkleDuration: star.twinkleDur * 0.8,
                floatDuration: star.floatDur * 0.5,
                floatDelay: star.twinkleDelay / 4
            )
        }
    }
}

