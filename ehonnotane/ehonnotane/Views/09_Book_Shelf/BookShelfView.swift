import SwiftUI

/// 本棚ビュー（カレンダー表示）
struct BookShelfView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // タイトルテキスト
                MainText(text: "これまでに そだてた たね")
                    .padding(.bottom, 16)
                Spacer()
                        
                // メインカード
                mainCard(width: .screen95, height: nil) {
                    CalendarView()
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // ヘッダー
            Header()
        }
    }
}

#Preview {
    BookShelfView()
        .environmentObject(AppCoordinator())
}
