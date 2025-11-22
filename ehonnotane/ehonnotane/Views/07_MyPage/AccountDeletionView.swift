import SwiftUI

struct AccountDeletionView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    
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
                        showConfirmation = true
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
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("最終確認"),
                message: Text("この操作は取り消せません。本当に削除しますか？"),
                primaryButton: .destructive(Text("削除する")) {
                    performDeletion()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
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
                try await UserService.shared.deleteUser(userId: userId)
                
                await MainActor.run {
                    authManager.logout()
                    coordinator.navigateToTop()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "削除に失敗しました: \(error.localizedDescription)"
                }
            }
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
