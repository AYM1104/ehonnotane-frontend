import SwiftUI

enum AlertType: Identifiable {
    case confirmation
    case success
    
    var id: String {
        switch self {
        case .confirmation: return "confirmation"
        case .success: return "success"
        }
    }
}

struct AccountDeletionView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var alertType: AlertType?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Background {}
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(String(localized: "settings.delete_account"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                
                // Warning Text
                VStack(spacing: 16) {
                    Text(String(localized: "account.confirm_delete"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(String(localized: "account.delete_warning"))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: String(localized: "account.delete_item1"))
                        BulletPoint(text: String(localized: "account.delete_item2"))
                        BulletPoint(text: String(localized: "account.delete_item3"))
                        BulletPoint(text: String(localized: "account.delete_item4"))
                    }
                    .padding(.vertical)
                }
                
                Spacer()
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        alertType = .confirmation
                    }) {
                        Text(String(localized: "account.delete_button"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .disabled(isDeleting)
                    .allowsHitTesting(!isDeleting)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(String(localized: "common.cancel"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .disabled(isDeleting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            if isDeleting {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert(item: $alertType) { type in
            switch type {
            case .confirmation:
                return Alert(
                    title: Text(String(localized: "account.final_confirmation")),
                    message: Text(String(localized: "account.cannot_undo")),
                    primaryButton: .destructive(Text(String(localized: "common.delete"))) {
                        performDeletion()
                    },
                    secondaryButton: .cancel(Text(String(localized: "common.cancel")))
                )
            case .success:
                return Alert(
                    title: Text(String(localized: "account.deletion_complete")),
                    message: Text(String(localized: "account.deleted_message")),
                    dismissButton: .default(Text("OK")) {
                        handleDeletionComplete()
                    }
                )
            }
        }
    }
    
    private func performDeletion() {
        guard let userId = authManager.userInfo?.id else {
            errorMessage = String(localized: "account.user_not_found")
            return
        }
        
        isDeleting = true
        errorMessage = nil
        
        Task {
            do {
                print("🗑️ アカウント削除処理を開始します: \(userId)")
                try await UserService.shared.deleteUser(userId: userId)
                print("✅ アカウント削除処理が完了しました")
                
                await MainActor.run {
                    isDeleting = false
                    alertType = .success
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = String(localized: "account.delete_failed \(error.localizedDescription)")
                    print("❌ アカウント削除に失敗しました: \(error)")
                }
            }
        }
    }
    
    private func handleDeletionComplete() {
        print("🔄 ログアウト処理を実行します")
        authManager.logout()
        
        // モーダルを閉じる
        print("🔄 AccountDeletionView を閉じます")
        presentationMode.wrappedValue.dismiss()
        
        // 少し遅延させてからTop画面に遷移（モーダルが完全に閉じるまで待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔄 Top画面に遷移します")
            coordinator.navigateToTop()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    AccountDeletionView()
        .environmentObject(AuthManager())
        .environmentObject(AppCoordinator())
}
