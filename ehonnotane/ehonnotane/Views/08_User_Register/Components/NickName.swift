import SwiftUI

struct NickName: View {
    @Binding var nickname: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Spacer()

            // 入力ボックス
            InputBox2(
                placeholder: "ニックネーム",
                text: $nickname,
                isFocused: $isFocused
            )

            // 入力ボックスを基準にタイトルを上へ重ねる
            .overlay(alignment: .top) {
                SubText(text: "あなたのニックネームを\n入力してください")
                    .multilineTextAlignment(.center)
                    .offset(y: -80)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    NickNamePreview()
}

private struct NickNamePreview: View {
    @State private var name = ""

    var body: some View {
        NickName(nickname: $name)
            .padding()
    }
}
