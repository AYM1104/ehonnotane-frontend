import SwiftUI

// シンプルなドロワー（閉じるボタンのみ）
struct SettingDrawer: View {
    @Binding var isPresented: Bool
    var headerHeight: CGFloat? = nil
    @State private var slideIn: Bool = false
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    
    // クレジット残高
    @State private var creditBalance: Int = 0
    
    // サブスクリプションプラン
    @State private var subscriptionPlan: PlanType = .free
    
    // アカウント削除画面の表示フラグ
    @State private var showAccountDeletion = false
    
    // 利用規約・プライバシーポリシー表示フラグ
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    
    // 設定サブメニューの展開状態
    @State private var showSettingsSubmenu = false
    
    // ナビゲーション割り込み用のコールバック（オプショナル）
    var onMyPageTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let availableHeight = max(geometry.size.height - (headerHeight ?? 0), 0)
                ZStack(alignment: .trailing) {
                    // 黒の半透明オーバーレイ（ドロワー表示時のみ）
                    // タップでドロワーを閉じる
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                slideIn = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                    isPresented = false
                                }
                            }
                        }
                    
                    // 右側のドロワーパネル
                    ZStack {
                        // 背景と角丸
                        UnevenRoundedRectangle(cornerRadii: .init(
                            topLeading: 35,
                            bottomLeading: 35,
                            bottomTrailing: 0,
                            topTrailing: 0
                        ))
                        .fill(Color.white.opacity(0.9))
                        
                        VStack(alignment: .leading, spacing: 32) {
                            // 閉じるボタンのみ
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                        slideIn = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                            isPresented = false
                                        }
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(1.0)
                            }
                            .padding(.bottom, 16)
                            
                            // 項目リスト
                            VStack(alignment: .leading, spacing: 12) {
                                // サブスクプラン表示
                                DrawerItemRow(
                                    title: String(localized: "settings.plan"),
                                    icon: Image(systemName: "crown"),
                                    value: subscriptionPlan.displayName
                                ) {
                                    // ドロワーを閉じてからPrice画面へ遷移
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                        slideIn = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                            isPresented = false
                                        }
                                        coordinator.navigateToPrice()
                                    }
                                }
                                // 保有クレジット表示
                                DrawerItemRow(
                                    title: String(localized: "settings.credits"),
                                    icon: Image("icon-coin"),
                                    value: "\(creditBalance)"
                                ) {
                                    // TODO: 保有クレジット画面へ遷移
                                }
                                DrawerItemRow(
                                    title: String(localized: "settings.mypage"),
                                    icon: Image("icon-face")
                                ) {
                                    // コールバックが提供されている場合はそれを呼び出し、なければ直接遷移
                                    if let onMyPageTap = onMyPageTap {
                                        // ドロワーを閉じてからコールバック実行
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                            slideIn = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                                isPresented = false
                                            }
                                            onMyPageTap()
                                        }
                                    } else {
                                        // ドロワーを閉じてからマイページへ遷移
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                            slideIn = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                                isPresented = false
                                            }
                                            // マイページへ遷移
                                            coordinator.navigateToMyPage()
                                        }
                                    }
                                }
                                DrawerItemRow(
                                    title: String(localized: "settings.logout"),
                                    icon: Image("icon-logout")
                                ) {
                                    // ドロワーを閉じてからログアウト処理を実行
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                        slideIn = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                                            isPresented = false
                                        }
                                        // ログアウト実行
                                        authManager.logout()
                                        // Top画面に遷移
                                        coordinator.navigateToTop()
                                    }
                                }
                                
                                // 設定メニュー（展開式）
                                DisclosureGroup(
                                    isExpanded: $showSettingsSubmenu,
                                    content: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            DrawerItemRow(
                                                title: String(localized: "settings.terms"),
                                                icon: Image("icon-info")
                                            ) {
                                                showTermsOfService = true
                                            }
                                            DrawerItemRow(
                                                title: String(localized: "settings.privacy"),
                                                icon: Image("icon-lock")
                                            ) {
                                                showPrivacyPolicy = true
                                            }
                                            DrawerItemRow(
                                                title: String(localized: "settings.delete_account"),
                                                icon: Image("icon-delete-trash")
                                            ) {
                                                print("🗑️ アカウント削除ボタンがタップされました")
                                                print("🗑️ showAccountDeletion を true に設定します")
                                                showAccountDeletion = true
                                                print("🗑️ showAccountDeletion = \(showAccountDeletion)")
                                            }
                                        }
                                        .padding(.leading, 12)
                                        .padding(.top, 8)
                                    },
                                    label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: "gearshape")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(Color(hex: "362D30"))
                                                .frame(width: 24, height: 24)
                                            
                                            Text(String(localized: "settings.settings"))
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(hex: "362D30"))
                                        }
                                    }
                                )
                                .accentColor(Color(hex: "362D30"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                            
                            Spacer()
                        }
                        // Drawer内のパディング
                        .padding(.top, 22)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(height: availableHeight, alignment: .top)    // ドロワーの高さを設定
                    .frame(width: 300)  // ドロワーの幅を設定
                    .padding(.top, headerHeight ?? 0)  // ヘッダーの高さを設定
                    .shadow(color: .black.opacity(0.45), radius: 25, x: -18, y: 0)  // 影を追加
                    .offset(x: slideIn ? 0 : 300)  // ドロワーの位置を設定
                }
                .onAppear {  // ドロワーが表示された時のアニメーション
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {  // 控えめなアニメーション  
                        slideIn = true  // ドロワーを表示
                    }
                    
                    // クレジット残高を取得
                    Task {
                        if let userId = authManager.getCurrentUserId() {
                            do {
                                let user = try await UserService.shared.fetchUser(userId: userId)
                                await MainActor.run {
                                    creditBalance = user.balance
                                    subscriptionPlan = user.subscription_plan
                                }
                            } catch {
                                print("❌ SettingDrawer: ユーザー情報取得失敗: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showAccountDeletion, onDismiss: {
            // AccountDeletionViewが閉じられたときにドロワーも閉じる
            print("🗑️ AccountDeletionView が閉じられました")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                slideIn = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                    isPresented = false
                }
            }
        }) {
            AccountDeletionView()
                .environmentObject(authManager)
                .environmentObject(coordinator)
        }
        // 利用規約表示
        .sheet(isPresented: $showTermsOfService) {
            LegalDocumentView(documentType: .termsOfService)
        }
        // プライバシーポリシー表示
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalDocumentView(documentType: .privacyPolicy)
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        LinearGradient(
            colors: [
                Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4),
                Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        Color.clear.ignoresSafeArea()
        SettingDrawer(
            isPresented: .constant(true),
            headerHeight: 80
        )
        .frame(maxWidth: .infinity, alignment: .trailing) // 右寄せ
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager())
    }
}

