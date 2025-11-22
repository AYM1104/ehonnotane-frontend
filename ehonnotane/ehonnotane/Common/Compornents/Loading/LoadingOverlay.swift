import SwiftUI

/// 全画面ローディングオーバーレイ
struct LoadingOverlay: View {
    /// 表示するメッセージ
    var message: String = "アップロード中..."
    
    var body: some View {
        ZStack {
            // 半透明の背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            // ローディングインジケーターとメッセージ
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        LoadingOverlay(message: "物語を作っています...")
    }
}
