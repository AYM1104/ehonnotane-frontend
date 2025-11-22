import SwiftUI

// MARK: - 星空全体のコンポーネント（StarField）
struct StarField: View {
    let far: [Star]   // 遠景の星データ
    let mid: [Star]   // 中景の星データ
    let near: [Star]  // 近景の星データ
    
    var body: some View {
        // 画面いっぱいに広がる星空（クリックなどのイベントは通すため allowsHitTesting(false)）
        ZStack {
            // 遠景：薄くてゆったりした動きの星
            StarLayer(stars: far, layerType: .far)
            
            // 中景：標準の明るさと動きの星
            StarLayer(stars: mid, layerType: .mid)
            
            // 近景：強く光り、大きめ＆影付きの星
            StarLayer(stars: near, layerType: .near)
        }
        .allowsHitTesting(false)
    }
}

