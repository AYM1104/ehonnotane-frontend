import SwiftUI

// MARK: - 星の型定義
// 星1つの位置・大きさ・動きなどの情報を定義
struct Star: Identifiable {
    let id = UUID()
    let src: String           // 星の色（yellow, blue, green, purple, red, white）
    let left: CGFloat         // 配置するX座標
    let top: CGFloat          // 配置するY座標
    let size: CGFloat         // 星の大きさ（px）
    let opacity: Double       // 星の透明度（0～1）
    let rotate: Double        // 星の回転角度（°）
    let twinkleDur: Double    // 点滅（twinkle）にかかる時間（秒）
    let twinkleDelay: Double  // 点滅の開始タイミング（秒）
    let floatDur: Double      // 上下に揺れる（floatY）動きの周期（秒）
}

// MARK: - 星の画像パス一覧（色違いの星）
let starImages = [
    "yellow",
    "blue",
    "green",
    "purple",
    "red",
    "white"
]

// MARK: - 画面の広さに対するベース密度
// 例: 1920x1080 ≒ 2,073,600px * 0.0003 ≒ 622個
let BASE_DENSITY: CGFloat = 0.0003

// MARK: - 星を生成する関数
func generateStars(count: Int, width: CGFloat, height: CGFloat) -> [Star] {
    return (0..<count).map { _ in
        Star(
            src: starImages.randomElement()!,
            left: CGFloat.random(in: 0...width),
            top: CGFloat.random(in: 0...height),
            size: CGFloat.random(in: 5...12),
            opacity: Double.random(in: 0.5...1.0),
            rotate: Double.random(in: 0...360),
            twinkleDur: Double.random(in: 1.5...3.5),
            twinkleDelay: Double.random(in: 0...2),
            floatDur: Double.random(in: 3...6)
        )
    }
}

