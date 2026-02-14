import SwiftUI

struct CreditInsufficientModal: View {
    @Binding var isPresented: Bool
    let requiredCredits: Int
    let currentCredits: Int
    var onAddCredit: () -> Void
    
    var body: some View {
        ZStack {
            // 背景を暗くする
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // モーダルコンテンツ
            VStack(spacing: 0) {
                // アイコン
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255)) // #362D30
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                
                // タイトル
                Text(String(localized: "credit.insufficient_title"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255)) // #362D30
                    .padding(.bottom, 24)
                
                // クレジット情報
                VStack(spacing: 8) {
                    HStack {
                        Text(String(localized: "credit.required_label"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        Text("\(requiredCredits)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    }
                    
                    HStack {
                        Text(String(localized: "credit.current_label"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        Text("\(currentCredits)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    }
                }
                .padding(.bottom, 24)
                
                // ボタンエリア
                HStack(spacing: 12) {
                    // 後にするボタン
                    PrimaryButton(
                        title: String(localized: "common.later"),
                        style: .secondary,
                        width: nil, // 幅を自動調整
                        fontSize: 14,
                        horizontalPadding: 8,
                        height: 44,
                        action: {
                            isPresented = false
                        }
                    )
                    
                    // チャージするボタン
                    PrimaryButton(
                        title: String(localized: "common.charge"),
                        style: .primary,
                        width: nil, // 幅を自動調整
                        fontSize: 14,
                        horizontalPadding: 8,
                        height: 44,
                        action: {
                            onAddCredit()
                            isPresented = false
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .frame(width: 320)
            .background(Color(red: 248/255, green: 247/255, blue: 242/255)) // #F8F7F2
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        CreditInsufficientModal(
            isPresented: .constant(true),
            requiredCredits: 80,
            currentCredits: 60
        ) {
            print("Add Credit")
        }
    }
}
