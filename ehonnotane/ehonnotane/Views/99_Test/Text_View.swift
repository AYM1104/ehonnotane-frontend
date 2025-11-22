import SwiftUI

struct Text_View: View {
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()
            
            VStack {
                // ヘッダー分の余白
                Spacer()
                    .frame(height: 80)
                
                // ページ説明
                MainText(text: "おはなしのタイトル", fontSize: 28, color: .white, glowEffect: true, alignment: .center)
                SubText(text: "「あすくんの ふしぎな めがね」", fontSize: 26, color: Color(hex: "362D30"), alignment: .center)
                    .padding(.bottom, 4)
                
                Spacer()
                
                // メインカード
                Spacer()
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        InnerCard {
                            VStack(alignment: .leading, spacing: 12) {
                                // タイトル群（インナーカード内表示）
                                SubText(text: "おはなしのタイトル", fontSize: 24, color: Color(hex: "362D30"), alignment: .center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                SubText(text: "「あすくんの ふしぎな めがね」", fontSize: 28, color: Color(hex: "362D30"), alignment: .center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                // 区切り線
                                Rectangle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(height: 1)
                                    .padding(.vertical, 8)
                                
                                // スクロール可能な長文セクション
                                // 高さを固定し、その中のみスクロールさせる
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.clear)
                                    
                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(alignment: .leading, spacing: 14) {
                                            ForEach(0..<40, id: \.self) { _ in
                                                SubText(
                                                    text: "Text  Text  Text  Text  Text  Text  Text  Text  Text",
                                                    fontSize: 22,
                                                    color: Color(hex: "362D30"),
                                                    alignment: .leading
                                                )
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        .padding(.trailing, 6) // スクロールバー分の余白
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 220) // セクションの表示高さ
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                        
                        // 決定ボタン
                        PrimaryButton(
                            title: "これにけってい",
                            style: .primary,
                            width: nil,
                            fontSize: 24
                        ) {
                            // 決定アクション
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .padding(.bottom, -11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    Text_View()
}
