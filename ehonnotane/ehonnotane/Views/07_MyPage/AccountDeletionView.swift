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
                    Text("アカウント削除")
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
                    Text("本当に削除しますか？")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("アカウントを削除すると、以下のデータを含むすべての情報が完全に削除され、復元することはできません。")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "作成したすべての絵本")
                        BulletPoint(text: "アップロードした写真")
                        BulletPoint(text: "購入したクレジット")
                        BulletPoint(text: "お子さまの情報")
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
                        Text("アカウントを削除する")
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
                        Text("キャンセル")
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
                    title: Text("最終確認"),
                    message: Text("この操作は取り消せません。本当に削除しますか？"),
                    primaryButton: .destructive(Text("削除する")) {
                        performDeletion()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            case .success:
                return Alert(
                    title: Text("削除完了"),
                    message: Text("アカウントを削除しました。"),
                    dismissButton: .default(Text("OK")) {
                        handleDeletionComplete()
                    }
                )
            }
        }
    }
    
    private func performDeletion() {
        guard let userId = authManager.userInfo?.id else {
            errorMessage = "ユーザー情報が見つかりません"
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
                    errorMessage = "削除に失敗しました: \(error.localizedDescription)"
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
