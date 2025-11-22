import SwiftUI

/// サブテキストコンポーネント - YuseiMagicフォントを使用したサブテキスト表示
struct SubText: View {

    
    let text: String    // 表示するテキスト
    var fontSize: CGFloat = 18    // フォントサイズ
    var color: Color = Color(hex: "362D30")    // テキストカラー
    var alignment: TextAlignment = .center    // テキストアライメント
    
    var body: some View {
        Text(text)
            .font(.custom("YuseiMagic-Regular", size: fontSize))
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
    }
}

#Preview {
    ZStack {
        // 背景
        Background {
            BigCharacter()
        }
        
        SubText(text: "これはサブテキストのサンプルです")
    }
}
