import SwiftUI

// アバター表示用の共通コンポーネント
public struct Avatar: View {
    // ベース径（白い円の直径）
    public let baseDiameter: CGFloat
    
    public init(baseDiameter: CGFloat = 60) {
        self.baseDiameter = baseDiameter
    }
    
    public var body: some View {
        let innerDiameter = baseDiameter * (50.0 / 60.0)
        
        ZStack {
            // 白い円形の背景
            Circle()
                .fill(Color.white)
                .frame(width: baseDiameter, height: baseDiameter)
            
            // 青いキャラクター（プレースホルダー）
            // 実際のキャラクター画像がある場合は、Imageを使用
            Circle()
                .fill(Color(red: 0.4, green: 0.7, blue: 1.0)) // 青い色
                .frame(width: innerDiameter, height: innerDiameter)
                .overlay(
                    // キャラクターの目と足を簡易的に表現
                    VStack {
                        // 目
                        HStack(spacing: innerDiameter * (8.0 / 50.0)) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: innerDiameter * (4.0 / 50.0), height: innerDiameter * (4.0 / 50.0))
                            Circle()
                                .fill(Color.black)
                                .frame(width: innerDiameter * (4.0 / 50.0), height: innerDiameter * (4.0 / 50.0))
                        }
                        .padding(.top, innerDiameter * (8.0 / 50.0))
                        
                        Spacer()
                        
                        // 足
                        HStack(spacing: innerDiameter * (4.0 / 50.0)) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: innerDiameter * (3.0 / 50.0), height: innerDiameter * (3.0 / 50.0))
                            Circle()
                                .fill(Color.black)
                                .frame(width: innerDiameter * (3.0 / 50.0), height: innerDiameter * (3.0 / 50.0))
                        }
                        .padding(.bottom, innerDiameter * (4.0 / 50.0))
                    }
                )
        }
    }
}


