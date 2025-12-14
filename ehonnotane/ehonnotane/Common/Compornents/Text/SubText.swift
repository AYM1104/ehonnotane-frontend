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
            .lineLimit(nil)  // 複数行に折り返し可能にする
            .fixedSize(horizontal: false, vertical: true)  // 水平方向は折り返し、垂直方向は固定サイズ
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
