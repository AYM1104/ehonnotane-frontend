import SwiftUI

// MARK: - 菱形（Diamond）Shape
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 菱形の4つの頂点を定義
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.midY)
        
        // 菱形を描画
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.closeSubpath()
        
        return path
    }
}

