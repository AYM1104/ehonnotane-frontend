import SwiftUI

// 編集ボタンの共通コンポーネント
public struct EditButton: View {
    public let onTap: () -> Void

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 編集ボタン
            Button(action: onTap) {
                Text("編集")
                    .font(.custom("YuseiMagic-Regular", size: 14))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }

            // 通知ドット（編集ボタンの左下）
            Circle()
                .fill(Color(red: 0.6, green: 0.3, blue: 0.2)) // 赤茶色
                .frame(width: 8, height: 8)
                .offset(x: -4, y: 4)
        }
    }
}


