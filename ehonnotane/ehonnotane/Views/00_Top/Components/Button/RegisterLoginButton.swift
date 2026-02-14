import SwiftUI

/// 認証ボタンコンポーネント（ユーザー登録、ログイン）
struct RegisterLoginButton: View {
    @Binding var loginModalMode: LoginModalMode
    @Binding var showLoginModal: Bool
    
    @ViewBuilder
    var body: some View {

        // ユーザー登録ボタン（セカンダリスタイル）
        PrimaryButton(
            title: String(localized: "auth.register"),
            style: .secondary,
            width: 292,
            fontName: "YuseiMagic-Regular",
            fontSize: 20,
            height: 48,
            action: {
                // サインアップ用のモーダルを表示
                withAnimation(.easeInOut(duration: 0.3)) {
                    loginModalMode = .signup
                    showLoginModal = true
                }
            }
        )
        
        // ログインボタン（プライマリスタイル）
        PrimaryButton(
            title: String(localized: "auth.login"),
            width: 292,
            fontName: "YuseiMagic-Regular",
            fontSize: 20,
            height: 48,
            action: {
                // ログイン用のモーダルを表示
                withAnimation(.easeInOut(duration: 0.3)) {
                    loginModalMode = .login
                    showLoginModal = true
                }
            }
        )
    }
}

