import SwiftUI
import Combine

struct Top_View: View {
    
    // 状態管理 ------------------------------
    @State private var showButton = false   // ボタンの表示
    @State private var showLoginModal = false // ログインモーダルの表示状態
    @State private var loginModalMode: LoginModalMode = .login // ログインモーダルの表示モード
    @State private var titleTextWidth: CGFloat? = nil // タイトルテキストの幅を保持
    @EnvironmentObject var coordinator: AppCoordinator // AppCoordinatorへの参照
    @EnvironmentObject var authManager: AuthManager // AuthManagerへの参照
    @EnvironmentObject var googleProvider: GoogleAuthProvider // GoogleAuthProviderへの参照
    @EnvironmentObject var appleProvider: AppleAuthProvider // AppleAuthProviderへの参照
    @EnvironmentObject var lineProvider: LineAuthProvider // LineAuthProviderへの参照
    @EnvironmentObject var twitterProvider: TwitterAuthProvider // TwitterAuthProviderへの参照

    private var modalContentOffset: CGFloat { showLoginModal ? -340 : 0 } // モーダルのオフセット
    private var modalContentScale: CGFloat { showLoginModal ? 0.5 : 1.0 } // モーダルのスケール
    
    var body: some View {
        ZStack {
            // 背景としてBackgroundコンポーネントを使用
            Background()
            
            VStack(spacing: showLoginModal ? -60 : nil) {
                Spacer()
                
                // ロゴ＋アプリタイトル ------------------------------
                VStack(spacing: 20) {

                    // ロゴ
                    LogoAnimation()
                    
                    // タイトルテキスト（画面中央に配置）
                    TitleAnimation()
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: TitleWidthPreferenceKey.self, value: geometry.size.width)
                            }
                        )
                }
                .frame(maxHeight: .infinity)
                .offset(y: modalContentOffset)
                .scaleEffect(modalContentScale)
                .animation(.easeInOut(duration: 0.3), value: showLoginModal)

                Spacer()

                // ボタン（ユーザー登録、ログイン） ------------------------------
                VStack(spacing: 16) {
                    RegisterLoginButton(
                        loginModalMode: $loginModalMode,    
                        showLoginModal: $showLoginModal
                    )
                }
                .padding(.bottom, 40)
                .opacity((showButton && !showLoginModal) ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: showButton)
                .animation(.easeInOut(duration: 0.3), value: showLoginModal)
            }
            
            // ログインモーダルの表示時の動作
            if showLoginModal {
                // 背景タップ処理：モーダルを閉じる
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLoginModal = false
                        }
                    }
                
                // ログインモーダルの表示
                LoginModal(
                    isPresented: $showLoginModal,
                    mode: loginModalMode,
                    // Appleログインを実行
                    onAppleLogin: {
                        appleProvider.login { _ in }
                    },
                    // Googleログインを実行
                    onGoogleLogin: {
                        googleProvider.login { _ in }
                    },
                    // X（Twitter）ログインを実行
                    onTwitterLogin: {
                        print("🔘 TopView: Xログインボタンがタップされました")
                        print("🔍 TopView: twitterProvider = \(twitterProvider)")
                        twitterProvider.login { result in
                            print("🔄 TopView: Xログイン結果を受け取りました: success=\(result.success)")
                        }
                    },
                    // LINEログインを実行
                    onLineLogin: {
                        lineProvider.login { _ in }
                    }
                )
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
                .onChange(of: authManager.errorMessage) { _, errorMessage in
                    // エラーが発生した場合、モーダルを再度表示
                    if let errorMessage = errorMessage, !errorMessage.isEmpty, !showLoginModal {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLoginModal = true
                        }
                    }
                }
            }
            
            // 認証・ログイン処理中のローディング表示（OAuth認証中 or 画面遷移中）
            if authManager.isLoading || coordinator.isNavigatingAfterLogin {
                ZStack {
                    // 半透明の背景
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    // ローディングコンテンツ
                    VStack(spacing: 20) {
                        // スピナー
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        // ローディングテキスト
                        Text(String(localized: "common.logging_in"))
                            .font(.custom("YuseiMagic-Regular", size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .onPreferenceChange(TitleWidthPreferenceKey.self) { width in
            titleTextWidth = width
        }
        .onAppear {
            // タイトル表示完了後にボタンをフェードイン（5.5秒後）
            // タイトルテキストのアニメーション完了（3秒 + 1.2秒） + 少しの遅延
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showButton = true
            }
        }
        .onChange(of: authManager.isLoggedIn) { (oldValue: Bool, newValue: Bool) in
            // ログイン成功時にモーダルを閉じる（画面遷移はAppCoordinatorで処理）
            if !oldValue && newValue {
                print("✅ TopView: ログイン成功を検知 - モーダルを閉じます")
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLoginModal = false
                }
            }
        }
        .onChange(of: authManager.errorMessage) { (_: String?, errorMessage: String?) in
            // エラーメッセージが設定された場合、ログインモーダルを再度表示してエラーを表示
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                print("❌ 認証エラー: \(errorMessage)")
                // エラーメッセージはLoginModalで表示される
            }
        }
    }
}

// MARK: - PreferenceKey

/// タイトルテキストの幅を取得するためのPreferenceKey
private struct TitleWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    Top_View()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager())
        .environmentObject(GoogleAuthProvider())
        .environmentObject(LineAuthProvider())
        .environmentObject(TwitterAuthProvider())
}
