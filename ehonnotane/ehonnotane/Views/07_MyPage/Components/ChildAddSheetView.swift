import SwiftUI

struct ChildAddSheetView: View {
    @Binding var childName: String
    @Binding var childBirthday: String
    @Binding var childBirthDate: Date
    let onAdd: (String, Date) -> Void
    
    @State private var isDatePickerVisible: Bool = false
    @State private var tempBirthDate: Date = Date()
    @Environment(\.dismiss) private var dismiss
    
    private var canAddChild: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !childBirthday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    // 年齢計算
    private func ageText(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: date, to: now)
        let years = comps.year ?? 0
        let months = comps.month ?? 0
        return "\(years)歳\(months)ヶ月"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // ハンドルバー（シートの取っ手）
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text("お子さまを追加")
                    .font(.custom("YuseiMagic-Regular", size: 22))
                    .foregroundColor(Color(hex: "362D30"))
                    .padding(.top, 10)

                VStack(spacing: 24) {
                    // 名前入力
                    InputBox2(
                        placeholder: "おなまえ",
                        text: $childName,
                        underlineOnly: true
                    )
                    
                    // 誕生日入力
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
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)

                Spacer()
                
                // 追加ボタン
                PrimaryButton(
                    title: "追加する",
                    action: {
                        if canAddChild {
                            onAdd(childName, childBirthDate)
                        }
                    }
                )
                .disabled(!canAddChild)
                .opacity(canAddChild ? 1.0 : 0.6)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .ignoresSafeArea()

            // DatePickerモーダル
            if isDatePickerVisible {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isDatePickerVisible = false
                        }
                    }
                    .zIndex(1)

                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        HStack {
                            Button("キャンセル") {
                                withAnimation {
                                    isDatePickerVisible = false
                                }
                            }
                            .font(.custom("YuseiMagic-Regular", size: 16))
                            .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Button("決定") {
                                childBirthDate = tempBirthDate
                                childBirthday = formatDate(tempBirthDate)
                                withAnimation {
                                    isDatePickerVisible = false
                                }
                            }
                            .font(.custom("YuseiMagic-Regular", size: 16))
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(white: 0.95))
                        
                        Divider()
                        
                        DatePicker(
                            "",
                            selection: $tempBirthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .frame(height: 216)
                        .clipped()
                        .environment(\.colorScheme, .light)
                        .tint(.black)
                        .background(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                }
                .zIndex(2)
            }
        }
    }
}
