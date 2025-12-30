import SwiftUI

// シンプルなドロワー（閉じるボタンのみ）
struct SettingDrawer: View {
    @Binding var isPresented: Bool
    var headerHeight: CGFloat? = nil
    @State private var slideIn: Bool = false
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    
    // アカウント削除画面の表示フラグ
    @State private var showAccountDeletion = false
    
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
                                DrawerItemRow(
                                    title: "保有クレジット",
                                    icon: Image("icon-coin")
                                ) {
                                    // TODO: 保有クレジット画面へ遷移
                                }
                                DrawerItemRow(
                                    title: "マイページ",
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
                                    title: "利用規約",
                                    icon: Image("icon-info")
                                ) {
                                    // TODO: 利用規約の表示
                                }
                                DrawerItemRow(
                                    title: "プライバシーポリシー",
                                    icon: Image("icon-lock")
                                ) {
                                    // TODO: プライバシーポリシーの表示
                                }
                                DrawerItemRow(
                                    title: "ログアウト",
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
                                DrawerItemRow(
                                    title: "アカウント削除",
                                    icon: Image("icon-delete-trash")
                                ) {
                                    print("🗑️ アカウント削除ボタンがタップされました")
                                    print("🗑️ showAccountDeletion を true に設定します")
                                    showAccountDeletion = true
                                    print("🗑️ showAccountDeletion = \(showAccountDeletion)")
                                }
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

