import SwiftUI

/// 月カレンダービュー
struct MonthCalendarView: View {
    let displayDate: Date
    @Binding var selectedDate: YearMonthDay?
    let markedDates: Set<YearMonthDay>
    let onDateChange: (Date) -> Void
    
    /// ホイールピッカーの表示状態
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 年月ヘッダー
            HStack {
                Button(action: {
                    let calendar = Calendar.current
                    if let newDate = calendar.date(byAdding: .month, value: -1, to: displayDate) {
                        onDateChange(newDate)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                }
                
                Spacer()
                
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(formatYearMonth(displayDate))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                }
                
                Spacer()
                
                Button(action: {
                    let calendar = Calendar.current
                    if let newDate = calendar.date(byAdding: .month, value: 1, to: displayDate) {
                        onDateChange(newDate)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // カレンダーグリッド
            CalendarGrid(
                displayDate: displayDate,
                selectedDate: $selectedDate,
                markedDates: markedDates
            )
            .padding(.top, 16) // 年月ヘッダーと曜日ヘッダーの間の余白
        }
        .sheet(isPresented: $showDatePicker) {
            // ホイールピッカー
            NavigationView {
                VStack {
                    DatePicker(
                        "年月を選択",
                        selection: Binding(
                            get: { displayDate },
                            set: { newDate in
                                onDateChange(newDate)
                                showDatePicker = false
                            }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("年月を選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    /// 年月をフォーマットする
    private func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

/// カレンダーグリッド
struct CalendarGrid: View {
    let displayDate: Date
    @Binding var selectedDate: YearMonthDay?
    let markedDates: Set<YearMonthDay>
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 8) {
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.custom("YuseiMagic-Regular", size: 14))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // 日付グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { day in
                    if let day = day {
                        DayView(
                            day: day,
                            isSelected: selectedDate == day,
                            isToday: isToday(day),
                            hasStorybook: markedDates.contains(day),
                            onTap: {
                                selectedDate = day
                            }
                        )
                    } else {
                        Text("")
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    /// カレンダーに表示する日付の配列を生成
    private var calendarDays: [YearMonthDay?] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayDate)
        let month = calendar.component(.month, from: displayDate)
        
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1 // 0=日曜日
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
        
        var days: [YearMonthDay?] = []
        
        // 前月の空白
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // 今月の日付
        for day in 1...daysInMonth {
            days.append(YearMonthDay(year: year, month: month, day: day))
        }
        
        return days
    }
    
    /// 今日かどうかを判定
    private func isToday(_ day: YearMonthDay) -> Bool {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        return day.year == today.year && day.month == today.month && day.day == today.day
    }
}

/// 日付を表示するビュー
struct DayView: View {
    let day: YearMonthDay
    let isSelected: Bool
    let isToday: Bool
    let hasStorybook: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text("\(day.day)")
                    .font(.custom("YuseiMagic-Regular", size: 16))
                    .foregroundColor(isSelected ? .white : Color(red: 54/255, green: 45/255, blue: 48/255))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(isToday && !isSelected ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.clear, lineWidth: 2)
                    )
                
                // 絵本を作成した日のマーク（小さなドット）
                if hasStorybook && !isSelected {
                    Circle()
                        .fill(Color(red: 20/255, green: 184/255, blue: 166/255))
                        .frame(width: 6, height: 6)
                        .offset(y: 12) // 日付の下に配置
                }
            }
        }
    }
}

