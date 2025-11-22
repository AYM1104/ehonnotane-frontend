import SwiftUI

// ヘッダーコンポーネント
struct Header: View {   
    // 設定ドロワーの表示状態
    @State private var isSettingPresented: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack(spacing: 12) {

                    // ヘッダーロゴ＋アプリタイトル
                    HStack(spacing: 12) {
                        Image("header-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .padding(.leading, 16)
                        
                        Text("えほんのたね")
                            .font(.custom("YuseiMagic-Regular", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 本棚アイコン
                    Image("BookShelf_Icon")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .padding(.trailing, 8)
                    
                    // 歯車アイコン
                    Image(systemName: "gearshape")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                        .onTapGesture {
                            // 歯車タップで設定ドロワー表示
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                isSettingPresented = true
                            }
                        }
                }
                .padding(.bottom, 60)
                
                Spacer()
            }
            .padding(.top, geometry.safeAreaInsets.top)
            .frame(height: max(geometry.size.height * 0, 0) + geometry.safeAreaInsets.top)
            .background(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            Color.clear.ignoresSafeArea()
            
            // 設定ドロワー（必要時のみ表示）
            if isSettingPresented {
                SettingDrawer(
                    isPresented: $isSettingPresented,
                    headerHeight: 65
                )
                .frame(maxWidth: .infinity, alignment: .trailing) // 右寄せ
                .ignoresSafeArea(edges: .bottom) // 下を無視
            }
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        // 背景（プレビュー用の簡易グラデーション）
        LinearGradient(
            colors: [
                Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4),
                Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        // ヘッダー
        Header()
    }
}
