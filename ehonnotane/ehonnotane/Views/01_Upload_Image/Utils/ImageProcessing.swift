#if canImport(UIKit)
import UIKit

/// 画像に透明度が含まれるかを判定するユーティリティ
func hasTransparency(_ image: UIImage) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    
    let alphaInfo = cgImage.alphaInfo
    switch alphaInfo {
    case .none, .noneSkipFirst, .noneSkipLast:
        return false
    case .premultipliedFirst, .premultipliedLast, .first, .last, .alphaOnly:
        return true
    @unknown default:
        return false
    }
}
#endif

