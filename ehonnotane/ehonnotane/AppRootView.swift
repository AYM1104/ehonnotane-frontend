import SwiftUI

// アプリ全体の最上位でドロワーと黒透過オーバーレイを重ねるラッパー
struct AppRootView: View {
    
    var body: some View {
        ZStack(alignment: .top) {
            // ここにアプリの現在のルート画面を配置（各画面内でヘッダーがドロワーを制御）
            Child_and_Page_Selection_View()
        }
    }
}

#Preview {
    AppRootView()
        .onAppear {
            FontRegistration.registerFonts()
        }
}


