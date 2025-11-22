import SwiftUI

// マイページの「コインチャージ」「利用履歴」ボタン行コンポーネント
public struct MyPageButtons: View {
    public let onCharge: () -> Void
    public let onHistory: () -> Void
    
    public init(onCharge: @escaping () -> Void, onHistory: @escaping () -> Void) {
        self.onCharge = onCharge
        self.onHistory = onHistory
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 左側：コインチャージボタン
            PrimaryButton(
                title: "コインチャージ",
                style: .primary,
                width: 170,
                fontName: nil,
                fontSize: 14,
                horizontalPadding: 16,
                verticalPadding: 10,
                height: 40,
                action: onCharge
            )
            .frame(maxWidth: .infinity) // 均等に配置
            
            // 右側：利用履歴ボタン
            PrimaryButton(
                title: "利用履歴",
                style: .secondary,
                width: 170,
                fontName: nil,
                fontSize: 14,
                horizontalPadding: 16,
                verticalPadding: 10,
                height: 40,
                action: onHistory
            )
            .frame(maxWidth: .infinity) // 均等に配置
        }
        .padding(.leading, 24) // 左パディング（アイコンと同じ）
        .padding(.trailing, 24) // 右パディング（編集ボタンと同じ）
        .frame(height: 48) // ボタンの高さ
    }
}


