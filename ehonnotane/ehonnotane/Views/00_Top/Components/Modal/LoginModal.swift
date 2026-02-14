import SwiftUI
import UIKit

// MARK: - ログインモード

/// ログイン/サインアップの表示切り替え
enum LoginModalMode {
    case login
    case signup
        
/// 各プロバイダーのボタン文言
    func buttonTitle(providerName: String) -> String {
        switch self {
        case .login:
            return String(localized: "auth.login_with \(providerName)")
        case .signup:
            return String(localized: "auth.signup_with \(providerName)")
        }
    }
}

/// ログインモーダルコンポーネント
struct LoginModal: View {
    // MARK: - Properties
    
    /// モーダルの表示状態を管理
    @Binding var isPresented: Bool
        
    /// 表示モード
    let mode: LoginModalMode
    
    /// ログインアクション（フォールバック用）
    let onLogin: (() -> Void)?
    
    /// Appleログインアクション
    let onAppleLogin: (() -> Void)?
    
    /// Googleログインアクション
    let onGoogleLogin: (() -> Void)?
    
    /// X（Twitter）ログインアクション
    let onTwitterLogin: (() -> Void)?
    
    /// LINEログインアクション
    let onLineLogin: (() -> Void)?
    
    // MARK: - Initializer
    
    init(
        isPresented: Binding<Bool>,
        mode: LoginModalMode = .login,
        onLogin: (() -> Void)? = nil,
        onAppleLogin: (() -> Void)? = nil,
        onGoogleLogin: (() -> Void)? = nil,
        onTwitterLogin: (() -> Void)? = nil,
        onLineLogin: (() -> Void)? = nil
    ) {
        _isPresented = isPresented
        self.mode = mode
        self.onLogin = onLogin
        self.onAppleLogin = onAppleLogin
        self.onGoogleLogin = onGoogleLogin
        self.onTwitterLogin = onTwitterLogin
        self.onLineLogin = onLineLogin
    }
    
    // MARK: - State
    
    @State private var showContent = false // コンテンツの表示アニメーション用
    
    var body: some View {
        GeometryReader { geometry in
            let modalShape = UnevenRoundedRectangle(
                topLeadingRadius: 50,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 50
            )
            ZStack {
                // ボトムシート用の角丸（上部のみ、より緩やかなカーブ）
                modalShape
                    .fill(
                        // bg-gradient-to-br from-white/15 via-white/5 to-white/10
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.15), location: 0.0),
                                .init(color: Color.white.opacity(0.05), location: 0.5),
                                .init(color: Color.white.opacity(0.10), location: 1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // ガラス風の内側ハイライト
                        // bg-gradient-to-b from-white/8 via-white/2 to-white/5
                        modalShape
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.08), location: 0.0),
                                        .init(color: Color.white.opacity(0.02), location: 0.5),
                                        .init(color: Color.white.opacity(0.05), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.plusLighter)
                    )
                    // .overlay(
                    //     // inset シャドウのシミュレーション（上部の内側白ライン）
                    //     // inset_0_1px_0_rgba(255,255,255,0.2)
                    //     VStack {
                    //         Rectangle()
                    //             .fill(Color.white.opacity(0.2))
                    //             .frame(height: 1)
                    //         Spacer()
                    //     }
                    //     .clipShape(
                    //         UnevenRoundedRectangle(
                    //             topLeadingRadius: 50,
                    //             bottomLeadingRadius: 0,
                    //             bottomTrailingRadius: 0,
                    //             topTrailingRadius: 50
                    //         )
                    //     )
                    // )
                     .overlay(
                         // 角丸に沿ったグロー効果
                         UnevenRoundedRectangle(topLeadingRadius: 50, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 50)
                             .stroke(Color.white.opacity(0.8), lineWidth: 2)
                             .shadow(color: Color.white.opacity(0.8), radius: 8, x: 0, y: 0)
                             .shadow(color: Color.white.opacity(0.6), radius: 15, x: 0, y: 0)
                             .shadow(color: Color.white.opacity(0.4), radius: 25, x: 0, y: 0)
                             .shadow(color: Color.blue.opacity(0.3), radius: 35, x: 0, y: 0)
                     )
                    // mainCardと同じ強い輝き効果（複数のシャドウ）
                     .shadow(color: Color.black.opacity(0.2), radius: 50, x: 0, y: 8)
                     .shadow(color: Color.white.opacity(0.3), radius: 50, x: 0, y: 0)
                     .shadow(color: Color(red: 102/255, green: 126/255, blue: 234/255).opacity(0.4), radius: 30, x: 0, y: 0)
                     .shadow(color: Color.white.opacity(0.2), radius: 45, x: 0, y: 0)
                
                // コンテンツ構造
                VStack {
                    // メインコンテンツ
                    VStack {
                        
                        // ログインフォーム
                        VStack(spacing: 20) {
                            // ログインタイトルとキャラクター
                            HStack {
//                                Text(mode.titleText)
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                            }
                            .offset(x: showContent ? 0 : -50)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)
                            .padding(.horizontal, 20)
                            
                            // ソーシャルログインボタン
                            VStack(spacing: 24) {
                                
                                // Appleログインボタン
                                PrimaryButton(
                                    title: mode.buttonTitle(providerName: "Apple"),
                                    style: .black,
                                    width: 292,
                                    fontName: nil,
                                    fontSize: 18,
                                    height: 48,
                                    logoImageName: "logo-Apple",
                                    logoSize: 48,
                                    textAlignment: .leading,
                                    action: {
                                        if let onAppleLogin = onAppleLogin {
                                            onAppleLogin()
                                        } else if let onLogin = onLogin {
                                            onLogin()
                                        }
                                    }
                                )
                                
                                // Googleログインボタン
                                PrimaryButton(
                                    title: mode.buttonTitle(providerName: "Google"),
                                    style: .google,
                                    width: 292,
                                    fontName: nil,
                                    fontSize: 18,
                                    height: 48,
                                    logoImageName: "logo-Google",
                                    logoSize: 48,
                                    textAlignment: .leading,
                                    action: {
                                        if let onGoogleLogin = onGoogleLogin {
                                            onGoogleLogin()
                                        } else if let onLogin = onLogin {
                                            onLogin()
                                        }
                                    }
                                )
                                
                                // Xログインボタン
                                PrimaryButton(
                                    title: mode.buttonTitle(providerName: "X"),
                                    style: .black,
                                    width: 292,
                                    fontName: nil,
                                    fontSize: 18,
                                    height: 48,
                                    logoImageName: "logo-X",
                                    logoSize: 48,
                                    textAlignment: .leading,
                                    action: {
                                        if let onTwitterLogin = onTwitterLogin {
                                            onTwitterLogin()
                                        } else if let onLogin = onLogin {
                                            onLogin()
                                        }
                                    }
                                )
                                
                                // LINEログインボタン
                                PrimaryButton(
                                    title: mode.buttonTitle(providerName: "LINE"),
                                    style: .line,
                                    width: 292,
                                    fontName: nil,
                                    fontSize: 18,
                                    height: 48,
                                    logoImageName: "logo-LINE",
                                    logoSize: 48,
                                    textAlignment: .leading,
                                    action: {
                                        if let onLineLogin = onLineLogin {
                                            onLineLogin()
                                        } else if let onLogin = onLogin {
                                            onLogin()
                                        }
                                    }
                                )
                            }
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                            .padding(.horizontal, 20)
                            
                            // Characters画像（ログインボタンの下に配置）
                            Image("Characters")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                                .padding(.top, 20)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)
                        }
                        .padding(.vertical, 25)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height * (2.0/3.0))
            .padding(.horizontal, 0) // 横幅を画面いっぱいに
            .position(x: geometry.size.width / 2, y: geometry.size.height - (geometry.size.height * (2.0/3.0)) / 2) // 画面下に配置
            .ignoresSafeArea(.all, edges: .bottom) //
        }
        .onAppear {
            // モーダル表示時のアニメーション開始
            withAnimation {
                showContent = true
            }
        }
        .onDisappear {
            // モーダルが閉じる時にリセット
            showContent = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// PDFファイルを画像として読み込む（PDFKitを使わない方法）
    private func loadPDFAsImage(named name: String) -> UIImage? {
        #if canImport(UIKit)
        guard let pdfURL = Bundle.main.url(forResource: name, withExtension: "pdf"),
              let pdfDocument = CGPDFDocument(pdfURL as CFURL),
              let firstPage = pdfDocument.page(at: 1) else {
            return nil
        }
        
        let pageRect = firstPage.getBoxRect(.mediaBox)
        let scale: CGFloat = 2.0 // Retina対応
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: 0, y: -pageRect.height)
        context.drawPDFPage(firstPage)
        
        return UIGraphicsGetImageFromCurrentImageContext()
        #else
        return nil
        #endif
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showModal = false
    
    ZStack {
        // プレビュー用の暗い背景
        Color.black
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Button("モーダルを表示") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showModal = true
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .offset(y: showModal ? -200 : 0) // モーダル表示時に上に移動
            .animation(.easeInOut(duration: 0.3), value: showModal)
            
            Spacer()
        }
        
        if showModal {
            // 背景タップでモーダルを閉じる
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showModal = false
                    }
                }
            
            LoginModal(
                isPresented: $showModal,
                onLogin: {
                    print("ログインボタンが押されました")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showModal = false
                    }
                }
            )
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom))
            .zIndex(1)
        }
    }
}

