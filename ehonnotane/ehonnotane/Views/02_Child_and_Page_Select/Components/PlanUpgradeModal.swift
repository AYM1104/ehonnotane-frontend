import SwiftUI

/// 有料プランへの加入を促すモーダル
/// ロックされたページ数（7ページ、10ページ）をタップした時に表示
struct PlanUpgradeModal: View {
    @Binding var isPresented: Bool
    var onSelectPlan: () -> Void
    
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
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255)) // #362D30
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                
                // タイトル（世界観に合わせたやさしい表現）
                Text("もっと ながい えほんを\nつくりたいときは…")
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255)) // #362D30
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                
                // メッセージ
                Text("7ページ いじょうの えほんは\nゆうりょうプランで つくれるよ！")
                    .font(.custom("YuseiMagic-Regular", size: 14))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                
                // ボタンエリア
                HStack(spacing: 12) {
                    // あとでボタン
                    PrimaryButton(
                        title: "あとで",
                        style: .secondary,
                        width: nil,
                        fontSize: 14,
                        horizontalPadding: 8,
                        height: 44,
                        action: {
                            isPresented = false
                        }
                    )
                    
                    // プランを選ぶボタン
                    PrimaryButton(
                        title: "プランをえらぶ",
                        style: .primary,
                        width: nil,
                        fontSize: 14,
                        horizontalPadding: 8,
                        height: 44,
                        action: {
                            onSelectPlan()
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
        PlanUpgradeModal(
            isPresented: .constant(true)
        ) {
            print("プラン選択画面に遷移")
        }
    }
}
