import SwiftUI

/// 週カレンダービュー
struct WeekCalendarView: View {
    /// 表示する週の開始日（日曜日）
    @Binding var weekStartDate: Date
    /// 選択された日付
    @Binding var selectedDate: YearMonthDay?
    /// 絵本を作成した日付のセット
    let markedDates: Set<YearMonthDay>
    
    var body: some View {
        VStack(spacing: 0) {
            // 週のヘッダー（前週/次週のナビゲーション）
            HStack {
                Button(action: {
                    let calendar = Calendar.current
                    if let newDate = calendar.date(byAdding: .day, value: -7, to: weekStartDate) {
                        weekStartDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                }
                
                Spacer()
                
                Text(formatWeekRange(weekStartDate))
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                
                Spacer()
                
                Button(action: {
                    let calendar = Calendar.current
                    if let newDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate) {
                        weekStartDate = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .font(.custom("YuseiMagic-Regular", size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // 週カレンダーグリッド
            WeekCalendarGrid(
                weekStartDate: weekStartDate,
                selectedDate: $selectedDate,
                markedDates: markedDates
            )
            .padding(.top, 16)
        }
    }
    
    /// 週の範囲をフォーマットする（例: "2024年1月1日〜7日"）
    private func formatWeekRange(_ startDate: Date) -> String {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        
        if startYear == endYear && startMonth == endMonth {
            // 同じ月の場合
            formatter.dateFormat = "yyyy年M月d日"
            let startStr = formatter.string(from: startDate)
            formatter.dateFormat = "d日"
            let endStr = formatter.string(from: endDate)
            return "\(startStr)〜\(endStr)"
        } else {
            // 異なる月の場合
            formatter.dateFormat = "yyyy年M月d日"
            let startStr = formatter.string(from: startDate)
            let endStr = formatter.string(from: endDate)
            return "\(startStr)〜\(endStr)"
        }
    }
}

/// 週カレンダーグリッド
struct WeekCalendarGrid: View {
    let weekStartDate: Date
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
            
            // 週の日付グリッド（月カレンダーと同じレイアウト構造を使用）
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let calendar = Calendar.current
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) {
                        let year = calendar.component(.year, from: date)
                        let month = calendar.component(.month, from: date)
                        let day = calendar.component(.day, from: date)
                        let yearMonthDay = YearMonthDay(year: year, month: month, day: day)
                        
                        DayView(
                            day: yearMonthDay,
                            isSelected: selectedDate == yearMonthDay,
                            isToday: isToday(yearMonthDay),
                            hasStorybook: markedDates.contains(yearMonthDay),
                            onTap: {
                                selectedDate = yearMonthDay
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    /// 今日かどうかを判定
    private func isToday(_ day: YearMonthDay) -> Bool {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        return day.year == today.year && day.month == today.month && day.day == today.day
    }
}

