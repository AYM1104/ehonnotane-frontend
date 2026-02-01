import SwiftUI

struct User_Register_View: View {
    @State private var currentPageIndex: Int = 0
    @State private var userNickname: String = ""
    @State private var childNickname: String = "" // Keep for compatibility if needed, or remove if unused logic depends on it
    @State private var children: [ChildEntry] = []
    
    // 登録ステータスモーダル用の状態管理
    @State private var showRegistrationModal: Bool = false
    @State private var registrationStatus: RegistrationStatus = .processing
    
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
            
            // 登録ステータスモーダル
            if showRegistrationModal {
                RegistrationStatusModal(status: registrationStatus)
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
                    // モーダルを「登録中」状態で表示
                    await MainActor.run {
                        registrationStatus = .processing
                        showRegistrationModal = true
                    }
                    
                    // ニックネームが空の場合はOAuth認証の表示名をフォールバックとして使用
                    let nicknameToSave: String
                    let trimmedNickname = userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedNickname.isEmpty {
                        // OAuth認証の表示名を使用（UserInfoのdisplayNameはname ?? email ?? "ユーザー"を返す）
                        nicknameToSave = authManager.userInfo?.displayName ?? "ユーザー"
                        print("ℹ️ ニックネーム未入力のため、OAuth表示名を使用: \(nicknameToSave)")
                    } else {
                        nicknameToSave = trimmedNickname
                    }
                    
                    try await registerService.registerUserAndChildren(
                        userId: userId,
                        nickname: nicknameToSave,
                        children: children
                    )
                    
                    // 登録完了後、モーダルを「完了」状態に更新
                    await MainActor.run {
                        registrationStatus = .completed
                    }
                    
                    // 1.5秒待ってから画像アップロード画面に遷移
                    try await Task.sleep(nanoseconds: 1_500_000_000)
                    
                    await MainActor.run {
                        showRegistrationModal = false
                        coordinator.navigateToUploadImage()
                    }
                } catch {
                    print("❌ Registration failed: \(error)")
                    // エラー時はモーダルを閉じる
                    await MainActor.run {
                        showRegistrationModal = false
                    }
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

// 登録ステータスの状態を表すenum
private enum RegistrationStatus {
    case processing  // 登録中
    case completed   // 登録完了
    
    var message: String {
        switch self {
        case .processing:
            return "ユーザー情報登録中"
        case .completed:
            return "ユーザー情報の登録が完了しました"
        }
    }
    
    var icon: String {
        switch self {
        case .processing:
            return "hourglass"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

// 登録ステータスモーダル
private struct RegistrationStatusModal: View {
    let status: RegistrationStatus
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // アイコン
                if status == .processing {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.white)
                } else {
                    Image(systemName: status.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                // メッセージ
                Text(status.message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.2))
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: status)
    }
}


#Preview {
    User_Register_View()
        .environmentObject(AppCoordinator())
}
