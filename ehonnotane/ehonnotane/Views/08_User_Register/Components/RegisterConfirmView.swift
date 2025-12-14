import SwiftUI

struct RegisterConfirmView: View {
    let userNickname: String
    let children: [ChildEntry]
    
    var body: some View {
        VStack(spacing: 0) {
            SubText(text: "入力内容の確認", fontSize: 20)
//                .padding(.top, 8)
                .padding(.bottom, 24)
            
            VStack(alignment: .leading, spacing: 0) {
                // あなたのニックネーム
                VStack(alignment: .leading, spacing: 8) {
                    SubText(text: "あなたのニックネーム", fontSize: 16)
                    
                    HStack {
                        SubText(text: userNickname.isEmpty ? "未入力" : userNickname, fontSize: 20)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 8)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                }
                .padding(.bottom, 24)

                // お子さま情報
                VStack(alignment: .leading, spacing: 12) {
                    SubText(text: "お子さま情報", fontSize: 16)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(children) { child in
                                VStack(spacing: 12) {
                                    HStack(alignment: .center, spacing: 12) {
                                        // 顔アイコン (仮のCircle or Image)
                                        Image("icon-face") // アセット確認が必要だが既存コードで使用されていたので維持
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            SubText(text: child.name, fontSize: 18)
                                            
                                            SubText(text: "\(child.birthdayText) / \(child.ageText)", fontSize: 14)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(height: 1)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
//                    .frame(height: 135)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            // 完了ボタン
            PrimaryButton(
                title: "完了",
                action: {
                    onComplete?()
                }
            )
            .padding(.top, 24)
//            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .top) 
    }
    
    var onComplete: (() -> Void)?
}

// Unused but preserved from original file logic if needed in future
private struct ConfirmItem: Identifiable {
    let id: UUID
    let title: String
    let value: String
    
    var displayValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未入力" : value
    }
}

#Preview {
    ZStack {
        Background {}
        
        MainCard(heightStyle: .percent65) {
            VStack(spacing: 20) {
                MainText(text: "ユーザー登録")
                
                InnerCard2(expandVertically: false) {
                    RegisterConfirmView(
                        userNickname: "たろう",
                        children: [
                            ChildEntry(id: UUID(), name: "はなこ", birthdayText: "2020/05/15", ageText: "4歳7ヶ月"),
                             ChildEntry(id: UUID(), name: "じろう", birthdayText: "2022/03/10", ageText: "2歳9ヶ月"),
                             ChildEntry(id: UUID(), name: "さぶろう", birthdayText: "2023/08/20", ageText: "1歳4ヶ月")
                        ],
                        onComplete: {
                            print("完了ボタンが押されました")
                        }
                    )
                }
            }
            .padding(.top, 12)
        }
    }
}
