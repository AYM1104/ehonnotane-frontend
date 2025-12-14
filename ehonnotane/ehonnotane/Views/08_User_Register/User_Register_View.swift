import SwiftUI

struct User_Register_View: View {
    @State private var currentPageIndex: Int = 0
    @State private var userNickname: String = ""
    @State private var childNickname: String = "" // Keep for compatibility if needed, or remove if unused logic depends on it
    @State private var children: [ChildEntry] = []
    
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    
    // サービスは共有インスタンスを使用（必要に応じて @StateObject で監視も可能）
    private let registerService = UserRegisterService.shared
    
    private var pages: [RegisterPage] {
        [
            RegisterPage(step: .userNickname),
            RegisterPage(step: .childNickname),
            RegisterPage(step: .confirm)
        ]
    }
    
    private var currentStep: RegisterStep {
        pages[currentPageIndex].step
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .userNickname:
            return !userNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .childNickname:
            return !children.isEmpty 
        case .confirm:
            return true
        }
    }
    
    var body: some View {
        ZStack { // デフォルトで中央寄せ
            Background {}

            VStack(spacing: 16) {

                // メインカード
                MainCard(heightStyle: .percent65) {
                    VStack(spacing: 20) {

                        // タイトル
                        MainText(text: "ユーザー登録")

                        PageSlider(
                            pages,
                            currentIndex: $currentPageIndex,
                            spacing: 24,
                            onPageChanged: { _ in
                                dismissKeyboard()
                            }
                        ) { page in
                            innerCard2(for: page.step) {
                                pageView(for: page.step)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.top, 12)
                }
                ProgressBar(totalSteps: pages.count, currentStep: currentPageIndex)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // 画面中央に配置
            
            // ローディング表示
            if registerService.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
    
    @ViewBuilder
    private func pageView(for step: RegisterStep) -> some View {
        switch step {
        case .userNickname:
            NickName(nickname: $userNickname)
        case .childNickname:
            ChildAdd(
                nickname: $childNickname,
                onConfirm: {
                    nextOrSubmit()
                },
                children: $children
            )
        case .confirm:
            RegisterConfirmView(
                userNickname: userNickname,
                children: children,
                onComplete: {
                    nextOrSubmit()
                }
            )
        }
    }

    @ViewBuilder
    private func innerCard2<Content: View>(for step: RegisterStep,
                                          @ViewBuilder content: @escaping () -> Content) -> some View {
        if step == .childNickname {
            // 子ども情報ページだけ余白を調整
            InnerCard2(horizontalPadding: 32, verticalPadding: 16) {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if step == .confirm {
            // 確認ページはコンテンツに合わせた高さにする（伸びない）
            InnerCard2(expandVertically: false) {
                content()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        } else {
            InnerCard2 {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func previousPage() {
        guard currentPageIndex > 0 else { return }
        currentPageIndex -= 1
    }
    
    private func nextOrSubmit() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        } else {
            // バックエンド登録処理
            guard let userId = authManager.getCurrentUserId() else {
                print("❌ User ID not found")
                // 必要に応じてエラー表示やログイン画面への誘導
                return
            }
            
            Task {
                do {
                    try await registerService.registerUserAndChildren(
                        userId: userId,
                        nickname: userNickname,
                        children: children
                    )
                    await MainActor.run {
                        coordinator.navigateToUploadImage()
                    }
                } catch {
                    print("❌ Registration failed: \(error)")
                    // ここでアラートを表示するなどエラーハンドリングを追加可能
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct RegisterPage: Identifiable {
    var id: RegisterStep { step }
    let step: RegisterStep
}

private enum RegisterStep: Int, Identifiable {
    case userNickname
    case childNickname
    case confirm
    
    var id: Int { rawValue }
}



#Preview {
    User_Register_View()
        .environmentObject(AppCoordinator())
}
