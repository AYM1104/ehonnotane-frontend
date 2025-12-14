import SwiftUI

struct ChildAdd: View {
    @Binding var nickname: String
    var onConfirm: () -> Void = {}
    @FocusState private var isFocused: Bool
    @State private var isDrawerPresented: Bool = false
    @State private var childName: String = ""
    @State private var childBirthday: String = ""
    @State private var childBirthDate: Date = Date()
    @State private var tempBirthDate: Date = Date()
    @Binding var children: [ChildEntry]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()

                PrimaryButton(
                    title: "お子さまを追加",
                    action: {
                        isDrawerPresented = true
                    }
                )
                // ボタンを基準にタイトルと補足を配置
                .overlay(alignment: .top) {
                    SubText(text: "お子さまの情報を\n追加してください")
                        .multilineTextAlignment(.center)
                        .offset(y: -80)
                }
                .overlay(alignment: .bottom) {
                    SubText(
                        text: "※不要の場合は次のページへスライドしてください",
                        fontSize: 12
                    )
                    .offset(y: 46)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            ChildInfoTip()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .sheet(isPresented: $isDrawerPresented) {
            ChildAddDrawer(
                childName: $childName,
                childBirthday: $childBirthday,
                childBirthDate: $childBirthDate,
                children: $children,
                onDateChange: { date in
                    childBirthday = formatDate(date)
                },
                onConfirm: {
                    // ニックネームを更新して確認画面へ
                    updateNicknameString()
                    isDrawerPresented = false
                    // ドロワーが閉じるアニメーションを待ってから画面遷移
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onConfirm()
                    }
                }
            )
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.7)])
                .presentationCornerRadius(32)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.disabled)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    private func updateNicknameString() {
        if children.isEmpty {
            nickname = ""
        } else {
            nickname = children.map { $0.name }.joined(separator: "ちゃん、") + "ちゃん"
        }
    }
}

#Preview {
    ChildAddPreview()
}

struct ChildAddPreview: View {
    @State private var name = ""
    @State private var children: [ChildEntry] = []

    var body: some View {
        ChildAdd(nickname: $name, children: $children)
            .padding()
    }
}

/// 下から出るドロワー
private struct ChildAddDrawer: View {
    @Binding var childName: String
    @Binding var childBirthday: String
    @Binding var childBirthDate: Date
    @Binding var children: [ChildEntry]
    let onDateChange: (Date) -> Void
    let onConfirm: () -> Void
    @State private var isDatePickerVisible: Bool = false
    @State private var tempBirthDate: Date = Date()
    @Environment(\.dismiss) private var dismiss  // dismissを無効化するために取得
    
    private var canAddChild: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !childBirthday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("お子さまを追加")
                    .font(.custom("YuseiMagic-Regular", size: 22))
                    .foregroundColor(Color(hex: "362D30"))

                VStack(spacing: 18) {
                    InputBox2(
                        placeholder: "おなまえ",
                        text: $childName,
                        underlineOnly: true
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(childBirthday.isEmpty ? "たんじょうび" : childBirthday)
                            .font(.custom("YuseiMagic-Regular", size: 18))
                            .foregroundColor(childBirthday.isEmpty ? Color.black.opacity(0.4) : Color.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                tempBirthDate = childBirthDate
                                withAnimation {
                                    isDatePickerVisible = true
                                }
                            }
                        
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                    }
                }
                .frame(maxWidth: .infinity)

                SubText(
                    text: "※こちらで登録した内容はいつでも変更できます",
                    fontSize: 12,
                    color: Color.black.opacity(0.5),
                    alignment: .center
                )

                if canAddChild {
                    PrimaryButton(
                        title: "追加する",
                        action: {
                            if let entry = buildChildEntry() {
                                children.append(entry)
                                resetForm()
                                withAnimation {
                                    isDatePickerVisible = false
                                }
                                // Drawerを閉じないようにする
                                // dismiss()は呼ばない
                            }
                        }
                    )
                    .frame(maxWidth: 220)
                    .padding(.top, 8)
                }

                if !children.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(children) { child in
                                ChildRow(entry: child)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 220)
                    .padding(.top, 4)
                    
                    PrimaryButton(
                        title: "これで決定",
                        action: {
                            onConfirm()
                        }
                    )
                    .padding(.top, 24)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 32)
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .ignoresSafeArea(.container, edges: .bottom) // 下部セーフエリアを無視

            if isDatePickerVisible {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isDatePickerVisible = false
                        }
                    }

                VStack(spacing: 0) {
                    HStack {
                        Button("キャンセル") {
                            childBirthDate = tempBirthDate
                            onDateChange(tempBirthDate)
                            withAnimation {
                                isDatePickerVisible = false
                            }
                        }
                        .font(.custom("YuseiMagic-Regular", size: 16))
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Done") {
                            onDateChange(childBirthDate)
                            withAnimation {
                                isDatePickerVisible = false
                            }
                        }
                        .font(.custom("YuseiMagic-Regular", size: 16))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.95))
                    
                    Divider()
                    
                    DatePicker(
                        "",
                        selection: $childBirthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
            }
        }
    }
    
    private func buildChildEntry() -> ChildEntry? {
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        guard !childBirthday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        return ChildEntry(
            id: UUID(),
            name: trimmedName,
            birthdayText: childBirthday,
            ageText: ageText(from: childBirthDate)
        )
    }
    
    private func resetForm() {
        childName = ""
        childBirthday = ""
        tempBirthDate = Date()
        childBirthDate = Date()
        isDatePickerVisible = false
    }
    
    private func ageText(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: date, to: now)
        let years = comps.year ?? 0
        let months = comps.month ?? 0
        return "\(years)歳\(months)ヶ月"
    }
}

private struct ChildRow: View {
    let entry: ChildEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("icon-face")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.custom("YuseiMagic-Regular", size: 16))
                    .foregroundColor(Color(hex: "362D30"))
                Text("\(entry.birthdayText) / \(entry.ageText)")
                    .font(.custom("YuseiMagic-Regular", size: 12))
                    .foregroundColor(Color(hex: "362D30").opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.6))
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ChildEntry: Identifiable, Equatable {
    let id: UUID
    let name: String
    let birthdayText: String
    let ageText: String
}

private struct ChildInfoTip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image("icon_tips")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(.top, 3)

                SubText(
                    text: "お子さまの情報について",
                    fontSize: 16,
                    alignment: .leading
                )
            }
            SubText(
                text: "お子さまの名前や誕生日を設定することで、えほんのたねをより楽しく使っていただくことができます。",
                fontSize: 14,
                alignment: .leading
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    Color.white.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
