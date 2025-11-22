import SwiftUI

// ロゴのSVGパス（ベース部分）
struct PlantIconPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale = min(rect.width / 48, rect.height / 48)
        let offsetX = (rect.width - 48 * scale) / 2
        let offsetY = (rect.height - 48 * scale) / 2
        
        // パス1: 左側の本の部分
        // M24.0071 46.704V44.2235C24.0071 44.2235 16.4584 40.8258 4.00004 41.007V44.7672C4.13595 45.3107 4.63428 45.3107 4.63428 45.3107H22.2119C22.6196 46.704 24.0071 46.704 24.0071 46.704Z
        path.move(to: CGPoint(x: 24.2 * scale + offsetX, y: 46.704 * scale + offsetY))
        path.addLine(to: CGPoint(x: 24.2 * scale + offsetX, y: 44.2235 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 4.00004 * scale + offsetX, y: 41.007 * scale + offsetY),
                      control1: CGPoint(x: 20 * scale + offsetX, y: 42 * scale + offsetY),
                      control2: CGPoint(x: 10 * scale + offsetX, y: 41 * scale + offsetY))
        path.addLine(to: CGPoint(x: 4.00004 * scale + offsetX, y: 44.7672 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 4.63428 * scale + offsetX, y: 45.3107 * scale + offsetY),
                      control1: CGPoint(x: 4.13595 * scale + offsetX, y: 45 * scale + offsetY),
                      control2: CGPoint(x: 4.4 * scale + offsetX, y: 45.2 * scale + offsetY))
        path.addLine(to: CGPoint(x: 22.2119 * scale + offsetX, y: 45.3107 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 24.2 * scale + offsetX, y: 46.704 * scale + offsetY),
                      control1: CGPoint(x: 22.6196 * scale + offsetX, y: 46 * scale + offsetY),
                      control2: CGPoint(x: 23.5 * scale + offsetX, y: 46.5 * scale + offsetY))
        
        // パス2: 右側の大きな本
        // M24.0139 43.9047V35.8695C24.0139 35.8695 32.4403 24.3379 44.0379 23.547C46.0313 23.4111 46.9373 24.5436 46.9826 25.7216C46.9373 27.6696 47.0732 38.3611 46.9373 38.6783C46.883 39.0407 46.892 40.3092 44.5816 40.7169C31.3983 40.6263 24.0139 43.9047 24.0139 43.9047Z
        path.move(to: CGPoint(x: 24.0139 * scale + offsetX, y: 43.9047 * scale + offsetY))
        path.addLine(to: CGPoint(x: 24.0139 * scale + offsetX, y: 35.8695 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 44.0379 * scale + offsetX, y: 23.547 * scale + offsetY),
                      control1: CGPoint(x: 27 * scale + offsetX, y: 32 * scale + offsetY),
                      control2: CGPoint(x: 35 * scale + offsetX, y: 25 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 46.9826 * scale + offsetX, y: 25.7216 * scale + offsetY),
                      control1: CGPoint(x: 45.5 * scale + offsetX, y: 23.5 * scale + offsetY),
                      control2: CGPoint(x: 46.8 * scale + offsetX, y: 24.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 46.9373 * scale + offsetX, y: 38.6783 * scale + offsetY),
                      control1: CGPoint(x: 47 * scale + offsetX, y: 30 * scale + offsetY),
                      control2: CGPoint(x: 47 * scale + offsetX, y: 36 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 44.5816 * scale + offsetX, y: 40.7169 * scale + offsetY),
                      control1: CGPoint(x: 46.9 * scale + offsetX, y: 39.5 * scale + offsetY),
                      control2: CGPoint(x: 45.8 * scale + offsetX, y: 40.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 24.0139 * scale + offsetX, y: 43.9047 * scale + offsetY),
                      control1: CGPoint(x: 35 * scale + offsetX, y: 41 * scale + offsetY),
                      control2: CGPoint(x: 28 * scale + offsetX, y: 43 * scale + offsetY))
        
        // パス3: 左側の大きな本
        // M23.9856 43.9047V35.8695C23.9856 35.8695 15.5592 24.3379 3.9616 23.547C1.96826 23.4111 1.06219 24.5436 1.01689 25.7216C1.06219 27.6696 0.926285 38.3611 1.06219 38.6783C1.11656 39.0407 1.1075 40.3092 3.41796 40.7169C16.6012 40.6263 23.9856 43.9047 23.9856 43.9047Z
        path.move(to: CGPoint(x: 23.9856 * scale + offsetX, y: 43.9047 * scale + offsetY))
        path.addLine(to: CGPoint(x: 23.9856 * scale + offsetX, y: 35.8695 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 3.9616 * scale + offsetX, y: 23.547 * scale + offsetY),
                      control1: CGPoint(x: 21 * scale + offsetX, y: 32 * scale + offsetY),
                      control2: CGPoint(x: 13 * scale + offsetX, y: 25 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 1.01689 * scale + offsetX, y: 25.7216 * scale + offsetY),
                      control1: CGPoint(x: 2.5 * scale + offsetX, y: 23.5 * scale + offsetY),
                      control2: CGPoint(x: 1.2 * scale + offsetX, y: 24.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 1.06219 * scale + offsetX, y: 38.6783 * scale + offsetY),
                      control1: CGPoint(x: 1 * scale + offsetX, y: 30 * scale + offsetY),
                      control2: CGPoint(x: 1 * scale + offsetX, y: 36 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 3.41796 * scale + offsetX, y: 40.7169 * scale + offsetY),
                      control1: CGPoint(x: 1.1 * scale + offsetX, y: 39.5 * scale + offsetY),
                      control2: CGPoint(x: 2.2 * scale + offsetX, y: 40.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 23.9856 * scale + offsetX, y: 43.9047 * scale + offsetY),
                      control1: CGPoint(x: 13 * scale + offsetX, y: 41 * scale + offsetY),
                      control2: CGPoint(x: 20 * scale + offsetX, y: 43 * scale + offsetY))
        
        // パス4: 右側の中くらいの本
        // M24.0139 43.8315V26.7975C24.0139 26.7975 30.2658 18.9601 37.5143 18.643C38.1485 18.643 39.87 18.7789 40.1872 20.8628C40.2778 25.8461 40.1418 33.7289 40.1418 33.7289C40.1418 33.7289 40.1418 35.7177 37.5143 36.1753C28.4083 37.7609 24.0139 43.8315 24.0139 43.8315Z
        path.move(to: CGPoint(x: 24.0139 * scale + offsetX, y: 43.8315 * scale + offsetY))
        path.addLine(to: CGPoint(x: 24.0139 * scale + offsetX, y: 26.7975 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 37.5143 * scale + offsetX, y: 18.643 * scale + offsetY),
                      control1: CGPoint(x: 26 * scale + offsetX, y: 23 * scale + offsetY),
                      control2: CGPoint(x: 32 * scale + offsetX, y: 19.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 40.1872 * scale + offsetX, y: 20.8628 * scale + offsetY),
                      control1: CGPoint(x: 39 * scale + offsetX, y: 18.7 * scale + offsetY),
                      control2: CGPoint(x: 40 * scale + offsetX, y: 19.8 * scale + offsetY))
        path.addLine(to: CGPoint(x: 40.1418 * scale + offsetX, y: 33.7289 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 37.5143 * scale + offsetX, y: 36.1753 * scale + offsetY),
                      control1: CGPoint(x: 40.1418 * scale + offsetX, y: 35 * scale + offsetY),
                      control2: CGPoint(x: 39 * scale + offsetX, y: 36 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 24.0139 * scale + offsetX, y: 43.8315 * scale + offsetY),
                      control1: CGPoint(x: 31 * scale + offsetX, y: 38 * scale + offsetY),
                      control2: CGPoint(x: 26.5 * scale + offsetX, y: 42 * scale + offsetY))
        
        // パス5: 左側の中くらいの本
        // M23.9856 43.8315V26.7975C23.9856 26.7975 17.7338 18.9601 10.4852 18.643C9.851 18.643 8.12948 18.7789 7.81236 20.8628C7.72176 25.8461 7.85766 33.7289 7.85766 33.7289C7.85766 33.7289 7.85766 35.7177 10.4852 36.1753C19.5912 37.7609 23.9856 43.8315 23.9856 43.8315Z
        path.move(to: CGPoint(x: 23.9856 * scale + offsetX, y: 43.8315 * scale + offsetY))
        path.addLine(to: CGPoint(x: 23.9856 * scale + offsetX, y: 26.7975 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 10.4852 * scale + offsetX, y: 18.643 * scale + offsetY),
                      control1: CGPoint(x: 22 * scale + offsetX, y: 23 * scale + offsetY),
                      control2: CGPoint(x: 16 * scale + offsetX, y: 19.5 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 7.81236 * scale + offsetX, y: 20.8628 * scale + offsetY),
                      control1: CGPoint(x: 9 * scale + offsetX, y: 18.7 * scale + offsetY),
                      control2: CGPoint(x: 8 * scale + offsetX, y: 19.8 * scale + offsetY))
        path.addLine(to: CGPoint(x: 7.85766 * scale + offsetX, y: 33.7289 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 10.4852 * scale + offsetX, y: 36.1753 * scale + offsetY),
                      control1: CGPoint(x: 7.85766 * scale + offsetX, y: 35 * scale + offsetY),
                      control2: CGPoint(x: 9 * scale + offsetX, y: 36 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 23.9856 * scale + offsetX, y: 43.8315 * scale + offsetY),
                      control1: CGPoint(x: 17 * scale + offsetX, y: 38 * scale + offsetY),
                      control2: CGPoint(x: 21.5 * scale + offsetX, y: 42 * scale + offsetY))
        
        // パス6: 右側の本の部分
        // M24 46.704V44.2235C24 44.2235 31.5487 40.8258 44.007 41.007V44.7672C43.8711 45.3107 43.3728 45.3107 43.3728 45.3107H25.7952C25.3874 46.704 24 46.704 24 46.704Z
        path.move(to: CGPoint(x: 23.5 * scale + offsetX, y: 46.704 * scale + offsetY))
        path.addLine(to: CGPoint(x: 23.8 * scale + offsetX, y: 44.2235 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 44.007 * scale + offsetX, y: 41.007 * scale + offsetY),
                      control1: CGPoint(x: 28 * scale + offsetX, y: 42 * scale + offsetY),
                      control2: CGPoint(x: 38 * scale + offsetX, y: 41 * scale + offsetY))
        path.addLine(to: CGPoint(x: 44.007 * scale + offsetX, y: 44.7672 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 43.3728 * scale + offsetX, y: 45.3107 * scale + offsetY),
                      control1: CGPoint(x: 43.8711 * scale + offsetX, y: 45 * scale + offsetY),
                      control2: CGPoint(x: 43.6 * scale + offsetX, y: 45.2 * scale + offsetY))
        path.addLine(to: CGPoint(x: 25.7952 * scale + offsetX, y: 45.3107 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 23.8 * scale + offsetX, y: 46.704 * scale + offsetY),
                      control1: CGPoint(x: 25.3874 * scale + offsetX, y: 46 * scale + offsetY),
                      control2: CGPoint(x: 24.7 * scale + offsetX, y: 46.5 * scale + offsetY))
        
        return path
    }
}

// 葉と茎のパス（上部の芽の部分）
struct LeafGroupPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale = min(rect.width / 48, rect.height / 48)
        let offsetX = (rect.width - 48 * scale) / 2
        let offsetY = (rect.height - 48 * scale) / 2
        
        // パス1: 右側の葉
        // M35.9042 5.97663C37.4897 11.4583 31.4644 18.9253 24.0347 16.6682C23.8988 16.2151 23.3551 6.20312 30.2413 3.39436C32.6423 2.48831 35.1703 3.43966 35.9042 5.97663Z
        path.move(to: CGPoint(x: 35.9042 * scale + offsetX, y: 5.97663 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 24.0347 * scale + offsetX, y: 16.6682 * scale + offsetY),
                      control1: CGPoint(x: 37.4897 * scale + offsetX, y: 11.4583 * scale + offsetY),
                      control2: CGPoint(x: 31.4644 * scale + offsetX, y: 18.9253 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 30.2413 * scale + offsetX, y: 3.39436 * scale + offsetY),
                      control1: CGPoint(x: 23.8988 * scale + offsetX, y: 16.2151 * scale + offsetY),
                      control2: CGPoint(x: 23.3551 * scale + offsetX, y: 6.20312 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 35.9042 * scale + offsetX, y: 5.97663 * scale + offsetY),
                      control1: CGPoint(x: 32.6423 * scale + offsetX, y: 2.48831 * scale + offsetY),
                      control2: CGPoint(x: 35.1703 * scale + offsetX, y: 3.43966 * scale + offsetY))
        
        // パス2: 左側の葉
        // M14.1586 7.92439C13.2525 12.2282 18.0093 18.4347 23.8427 16.7338C23.9548 16.359 23.8427 8.60395 18.7231 5.75564C16.3331 4.93439 14.5823 5.96415 14.1586 7.92439Z
        path.move(to: CGPoint(x: 14.1586 * scale + offsetX, y: 7.92439 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 23.8427 * scale + offsetX, y: 16.7338 * scale + offsetY),
                      control1: CGPoint(x: 13.2525 * scale + offsetX, y: 12.2282 * scale + offsetY),
                      control2: CGPoint(x: 18.0093 * scale + offsetX, y: 18.4347 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 18.7231 * scale + offsetX, y: 5.75564 * scale + offsetY),
                      control1: CGPoint(x: 23.9548 * scale + offsetX, y: 16.359 * scale + offsetY),
                      control2: CGPoint(x: 23.8427 * scale + offsetX, y: 8.60395 * scale + offsetY))
        path.addCurve(to: CGPoint(x: 14.1586 * scale + offsetX, y: 7.92439 * scale + offsetY),
                      control1: CGPoint(x: 16.3331 * scale + offsetX, y: 4.93439 * scale + offsetY),
                      control2: CGPoint(x: 14.5823 * scale + offsetX, y: 5.96415 * scale + offsetY))
        
        // パス3: 右側の葉への線
        // M24.4878 16.804L35.9042 6.02191
        path.move(to: CGPoint(x: 24.4878 * scale + offsetX, y: 16.804 * scale + offsetY))
        path.addLine(to: CGPoint(x: 35.9042 * scale + offsetX, y: 6.02191 * scale + offsetY))
        
        // パス4: 左側の葉への線
        // M23.8534 16.3966L15.5176 5.93156
        path.move(to: CGPoint(x: 23.8534 * scale + offsetX, y: 16.3966 * scale + offsetY))
        path.addLine(to: CGPoint(x: 15.5176 * scale + offsetX, y: 5.93156 * scale + offsetY))
        
        return path
    }
}

// 茎のパス（細い線）
struct StemPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale = min(rect.width / 48, rect.height / 48)
        let offsetX = (rect.width - 48 * scale) / 2
        let offsetY = (rect.height - 48 * scale) / 2
        
        // 中央の茎（細い線）
        // M24 16.5L24 26.5
        path.move(to: CGPoint(x: 24 * scale + offsetX, y: 16.5 * scale + offsetY))
        path.addLine(to: CGPoint(x: 24 * scale + offsetX, y: 26.5 * scale + offsetY))
        
        return path
    }
}

struct LogoAnimation: View {
    // アニメーション状態
    @State private var plantProgress: CGFloat = 0
    @State private var leafProgress: CGFloat = 0
    @State private var showGlow: Bool = false
    
    var body: some View {
        // アイコン部分
        ZStack {
                // ベースの植物のストローク（最初のアニメーション）
                PlantIconPath()
                    .trim(from: 0, to: plantProgress)
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 120, height: 120)
                    .shadow(color: showGlow ? Color.white.opacity(0.8) : Color.white.opacity(0.5), radius: showGlow ? 15 : 10)
                    .shadow(color: Color(red: 1, green: 0.78, blue: 0.59).opacity(showGlow ? 0.6 : 0.3), radius: showGlow ? 30 : 20)
                    .shadow(color: Color(red: 1, green: 0.59, blue: 0.39).opacity(showGlow ? 0.4 : 0), radius: showGlow ? 40 : 0)
                
                // 葉のグループのストローク（遅延アニメーション）
                LeafGroupPath()
                    .trim(from: 0, to: leafProgress)
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 120, height: 120)
                    .opacity(leafProgress > 0 ? 1 : 0)
                    .shadow(color: showGlow ? Color.white.opacity(0.8) : Color.white.opacity(0.5), radius: showGlow ? 15 : 10)
                    .shadow(color: Color(red: 1, green: 0.78, blue: 0.59).opacity(showGlow ? 0.6 : 0.3), radius: showGlow ? 30 : 20)
                    .shadow(color: Color(red: 1, green: 0.59, blue: 0.39).opacity(showGlow ? 0.4 : 0), radius: showGlow ? 40 : 0)
                
                // 茎のストローク（細い線）
                StemPath()
                    .trim(from: 0, to: leafProgress)
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 120, height: 120)
                    .opacity(leafProgress > 0 ? 1 : 0)
                    .shadow(color: showGlow ? Color.white.opacity(0.8) : Color.white.opacity(0.5), radius: showGlow ? 15 : 10)
                    .shadow(color: Color(red: 1, green: 0.78, blue: 0.59).opacity(showGlow ? 0.6 : 0.3), radius: showGlow ? 30 : 20)
                    .shadow(color: Color(red: 1, green: 0.59, blue: 0.39).opacity(showGlow ? 0.4 : 0), radius: showGlow ? 40 : 0)
            }
            .frame(width: 160, height: 160)
            .onAppear {
                startAnimation()
            }
    }
    
    // アニメーションシーケンスの開始
    private func startAnimation() {
        // 1. 植物のベース部分をストローク描画（0.5秒後に開始、1秒間）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                plantProgress = 1.0
            }
            
            // グローエフェクトを開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    showGlow = true
                }
            }
        }
        
        // 2. 葉と茎をストローク描画（1.8秒後に開始、1秒間）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 1.0)) {
                leafProgress = 1.0
            }
        }
    }
}

#Preview {
    LogoAnimation()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
