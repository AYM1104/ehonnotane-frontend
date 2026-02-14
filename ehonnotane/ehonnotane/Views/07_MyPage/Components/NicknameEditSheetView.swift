import SwiftUI

/// ニックネーム編集用のシートビュー
struct NicknameEditSheetView: View {
    @Binding var isPresented: Bool
    let currentNickname: String
    let onSave: (String) async -> Bool
    
    @State private var nickname: String = ""
    @State private var isSaving: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        nickname != currentNickname
    }

    var body: some View {
        VStack(spacing: 20) {
            // ハンドルバー（シートの取っ手）
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text(String(localized: "mypage.change_nickname"))
                .font(.custom("YuseiMagic-Regular", size: 22))
                .foregroundColor(Color(hex: "362D30"))
                .padding(.top, 10)

            VStack(spacing: 24) {
                // ニックネーム入力
                InputBox2(
                    placeholder: String(localized: "mypage.nickname"),
                    text: $nickname,
                    underlineOnly: true
                )
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)

            Spacer()
            
            // 保存ボタン
            PrimaryButton(
                title: isSaving ? String(localized: "common.saving") : String(localized: "common.save"),
                action: {
                    guard canSave && !isSaving else { return }
                    isSaving = true
                    Task {
                        let success = await onSave(nickname)
                        await MainActor.run {
                            isSaving = false
                            if success {
                                isPresented = false
                            }
                        }
                    }
                }
            )
            .disabled(!canSave || isSaving)
            .opacity(canSave && !isSaving ? 1.0 : 0.6)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
            nickname = currentNickname
        }
    }
}

#Preview {
    NicknameEditSheetView(
        isPresented: .constant(true),
        currentNickname: "あゆ",
        onSave: { newNickname in
            print("新しいニックネーム: \(newNickname)")
            return true
        }
    )
}
