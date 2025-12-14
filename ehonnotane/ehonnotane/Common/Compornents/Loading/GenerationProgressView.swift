import SwiftUI

struct GenerationProgressView: View {
    let progress: Double // 0.0 - 1.0
    let message: String
    
    // アニメーション用のState
    @State private var isAnimating = false
    
    // ドットの設定
    private let dotCount = 12
    private let circleSize: CGFloat = 200
    private let dotSize: CGFloat = 12
    
    var body: some View {
        ZStack {
            // 背景（半透明の黒）
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // サークルドットプログレス
                ZStack {
                    // ドットの円配置
                    ForEach(0..<dotCount, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(getDotOpacity(index: index))
                            .offset(y: -circleSize / 2)
                            .rotationEffect(.degrees(Double(index) / Double(dotCount) * 360))
                    }
                    
                    // 中央のパーセンテージ表示
                    VStack(spacing: 5) {
                        CountingText(value: progress)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("完了")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: circleSize, height: circleSize)
                
                // メッセージ
                Text(message)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // ドットの不透明度を計算
    // 進捗に応じて光るドットの数が増える演出
    private func getDotOpacity(index: Int) -> Double {
        // 進捗(0.0-1.0)をドットのインデックス(0-11)にマッピング
        let activeIndex = Int(progress * Double(dotCount))
        
        // 基本の不透明度
        let baseOpacity: Double = 0.3
        
        // 現在の進捗位置に近いドットほど明るくする
        if index <= activeIndex {
            return 1.0
        } else {
            return baseOpacity
        }
    }
}

// 数値をアニメーションで変化させるためのView
struct CountingText: View, Animatable {
    var value: Double
    var font: Font = .system(size: 48, weight: .bold, design: .rounded)
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var body: some View {
        // 小数点誤差で99%に留まらないよう丸め＆クランプ
        let percent = max(0, min(100, Int((value * 100).rounded())))
        Text("\(percent)%")
            .font(font)
    }
    
    // フォントをモディファイアで設定できるようにする
    func font(_ font: Font) -> CountingText {
        var view = self
        view.font = font
        return view
    }
}

#Preview {
    GenerationProgressView(progress: 0.5, message: "物語を書いています...")
}
