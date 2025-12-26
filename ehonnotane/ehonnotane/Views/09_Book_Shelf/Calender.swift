import SwiftUI

/// カレンダーコンテナビュー（月カレンダーと週カレンダーを切り替え可能）
struct CalendarView: View {
    /// AppCoordinator（認証情報とStorybookServiceを含む）
    @EnvironmentObject var coordinator: AppCoordinator
    
    /// 選択された日付
    @State private var selectedDate: YearMonthDay? = nil
    /// 表示する年月
    @State private var displayDate = Date()
    /// カレンダーの表示モード（false: 月カレンダー, true: 週カレンダー）
    @State private var isWeekMode = false
    /// 選択された日付の絵本一覧
    @State private var storybooks: [StoryBookListItem] = []
    /// 絵本一覧の読み込み状態
    @State private var isLoadingStorybooks = false
    /// エラーメッセージ
    @State private var errorMessage: String?
    /// 絵本を作成した日付のセット
    @State private var markedDates: Set<YearMonthDay> = []
    /// 週カレンダーの開始日（親で管理）
    @State private var weekStartDate: Date = {
        let calendar = Calendar.current
        let date = Date()
        let weekday = calendar.component(.weekday, from: date)
        let daysFromSunday = (weekday - 1) % 7
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysFromSunday, to: date) {
            return startOfWeek
        }
        return date
    }()
    
    /// 週カレンダーに表示する開始日を計算
    private var weekStartDateForView: Date? {
        if let selected = selectedDate {
            let calendar = Calendar.current
            if let date = calendar.date(from: DateComponents(year: selected.year, month: selected.month, day: selected.day)) {
                return date
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            

            // カレンダー表示
            SubCard(
                onChevronTap: {
                    // chevronアイコンをクリックすると月/週カレンダーを切り替え
                    isWeekMode.toggle()
                },
                isWeekMode: isWeekMode
            ) {
                Group {
                    if isWeekMode {
                        // 週カレンダー表示（選択された日付がある場合はその日付を含む週を表示）
                        WeekCalendarView(
                            weekStartDate: $weekStartDate,
                            selectedDate: $selectedDate,
                            markedDates: markedDates
                        )
                        .frame(maxWidth: .infinity, alignment: .top)
                    } else {
                        // 月カレンダー表示
                        MonthCalendarView(
                            displayDate: displayDate,
                            selectedDate: $selectedDate,
                            markedDates: markedDates,
                            onDateChange: { newDate in
                                displayDate = newDate
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity) // 幅を固定（月カレンダーのサイズに合わせる）
            }
            
            // 選択された日付の絵本一覧を表示
            if let selected = selectedDate {
                StorybookListView(
                    storybooks: storybooks,
                    isLoading: isLoadingStorybooks,
                    selectedDate: selected
                )
                .padding(.top, 16)
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if let date = newValue {
                fetchStorybooksForDate(date)
            } else {
                storybooks = []
            }
        }
        .onChange(of: displayDate) { _, _ in
            if !isWeekMode {
                fetchMarkedDatesForMonth()
            }
        }
        .onChange(of: isWeekMode) { _, newValue in
            if newValue {
                // 選択された日付がある場合はその日付を含む週を表示
                if let selected = selectedDate {
                    let calendar = Calendar.current
                    if let date = calendar.date(from: DateComponents(year: selected.year, month: selected.month, day: selected.day)) {
                        let weekday = calendar.component(.weekday, from: date)
                        let daysFromSunday = (weekday - 1) % 7
                        if let startOfWeek = calendar.date(byAdding: .day, value: -daysFromSunday, to: date) {
                            weekStartDate = startOfWeek
                        }
                    }
                }
                fetchMarkedDatesForWeek()
            } else {
                fetchMarkedDatesForMonth()
            }
        }
        .onChange(of: weekStartDate) { _, _ in
            if isWeekMode {
                fetchMarkedDatesForWeek()
            }
        }
        .onAppear {
            if isWeekMode {
                fetchMarkedDatesForWeek()
            } else {
                fetchMarkedDatesForMonth()
            }
        }
    }
    
    /// 表示中の月で絵本を作成した日付を取得
    private func fetchMarkedDatesForMonth() {
        guard let userId = StorybookService.shared.getCurrentUserId() else {
            return
        }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayDate)
        let month = calendar.component(.month, from: displayDate)
        
        Task { @MainActor in
            do {
                let days = try await StorybookService.shared.fetchCreatedDays(
                    userId: userId,
                    year: year,
                    month: month
                )
                var newMarkedDates: Set<YearMonthDay> = []
                for day in days {
                    newMarkedDates.insert(YearMonthDay(year: year, month: month, day: day))
                }
                markedDates = newMarkedDates
            } catch {
                print("❌ 作成日取得エラー: \(error)")
            }
        }
    }
    
    /// 表示中の週で絵本を作成した日付を取得
    private func fetchMarkedDatesForWeek() {
        guard let userId = StorybookService.shared.getCurrentUserId() else {
            return
        }
        
        let calendar = Calendar.current
        let weekStart = weekStartDate
        
        Task { @MainActor in
            do {
                var newMarkedDates: Set<YearMonthDay> = []
                // 週の各日をチェック
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        let year = calendar.component(.year, from: date)
                        let month = calendar.component(.month, from: date)
                        let day = calendar.component(.day, from: date)
                        
                        // その日の絵本を取得して、存在するか確認
                        let books = try await StorybookService.shared.fetchUserStorybooksByDate(
                            userId: userId,
                            year: year,
                            month: month,
                            day: day
                        )
                        if !books.isEmpty {
                            newMarkedDates.insert(YearMonthDay(year: year, month: month, day: day))
                        }
                    }
                }
                markedDates = newMarkedDates
            } catch {
                print("❌ 週の作成日取得エラー: \(error)")
            }
        }
    }
    
    /// 選択された日付の絵本一覧を取得
    private func fetchStorybooksForDate(_ date: YearMonthDay) {
        guard let userId = StorybookService.shared.getCurrentUserId() else {
            return
        }
        
        isLoadingStorybooks = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let books = try await StorybookService.shared.fetchUserStorybooksByDate(
                    userId: userId,
                    year: date.year,
                    month: date.month,
                    day: date.day
                )
                storybooks = books
            } catch {
                errorMessage = error.localizedDescription
                storybooks = []
                print("❌ 絵本一覧取得エラー: \(error)")
            }
            isLoadingStorybooks = false
        }
    }
}

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

/// 年月日を表す構造体
struct YearMonthDay: Hashable {
    let year: Int
    let month: Int
    let day: Int
}

/// 絵本一覧ビュー
struct StorybookListView: View {
    let storybooks: [StoryBookListItem]
    let isLoading: Bool
    let selectedDate: YearMonthDay
    
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトル
            HStack {
                SubText(
                    text: formatDateTitle(selectedDate),
                    fontSize: 18,
                    color: Color(red: 54/255, green: 45/255, blue: 48/255),
                    alignment: TextAlignment.leading
                )
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 12)
            
            // 絵本一覧
            SubCard {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if storybooks.isEmpty {
                    Text("この日に作成した絵本はありません")
                        .font(.custom("YuseiMagic-Regular", size: 14))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.6))
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(storybooks) { storybook in
                            StorybookListItemView(storybook: storybook)
                            
                            if storybook.id != storybooks.last?.id {
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
    
    /// 日付タイトルをフォーマット
    private func formatDateTitle(_ date: YearMonthDay) -> String {
        let calendar = Calendar.current
        if let dateObj = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) {
            if calendar.isDateInToday(dateObj) {
                return "今日作成した絵本"
            } else if calendar.isDateInYesterday(dateObj) {
                return "昨日作成した絵本"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.dateFormat = "M月d日"
                return "\(formatter.string(from: dateObj))に作成した絵本"
            }
        }
        return "\(date.year)年\(date.month)月\(date.day)日に作成した絵本"
    }
}

/// 絵本リストアイテムビュー
struct StorybookListItemView: View {
    let storybook: StoryBookListItem
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        Button {
            coordinator.navigateToStorybook(storybookId: storybook.id)
        } label: {
            HStack(spacing: 12) {
                // 表紙画像
                Group {
                    if let coverImageUrl = storybook.coverImageUrl, !coverImageUrl.isEmpty {
                        AsyncImage(url: URL(string: coverImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                placeholderBookCover()
                            @unknown default:
                                placeholderBookCover()
                            }
                        }
                    } else {
                        placeholderBookCover()
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // タイトルと日付
                VStack(alignment: .leading, spacing: 4) {
                    SubText(
                        text: storybook.title,
                        fontSize: 16,
                        color: Color(red: 54/255, green: 45/255, blue: 48/255),
                        alignment: TextAlignment.leading
                    )
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                        
                        SubText(
                            text: formatDate(storybook.createdAt),
                            fontSize: 12,
                            color: Color.gray,
                            alignment: TextAlignment.leading
                        )
                    }
                }
                
                Spacer()
                
                // ハートアイコン
                Image(systemName: storybook.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(storybook.isFavorite ? .red : Color.gray.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    /// プレースホルダー表紙
    @ViewBuilder
    private func placeholderBookCover() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.4, blue: 0.8),
                        Color(red: 0.7, green: 0.5, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            )
    }
    
    /// 日付をフォーマット
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "ja_JP")
            displayFormatter.dateFormat = "M月d日"
            return displayFormatter.string(from: date)
        }
    }
}

/// プレビュー用 - 月カレンダー
#Preview("月カレンダー") {
    GeometryReader { geometry in
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // ヘッダー
            Header()
                .environmentObject(AppCoordinator())
            
            // メインカード（画面下部に配置）
            VStack {
                Spacer()
                    .frame(height: 65) // ヘッダーとメインカードの間の小さな余白
                // ヘッダー以下の領域の98%を計算
                mainCard(
                    width: .screen95,
                    height: (geometry.size.height - (max(geometry.size.height * 0.06, 10))) * 0.98
                ) {
                    Group {
                        CalendarView()
                            .environmentObject(AppCoordinator())
                    }
                }
                .padding(Edge.Set.horizontal, 8) // パディングを小さく
                .padding(Edge.Set.bottom, -10) // 画面下部からの余白
            }
        }
    }
}
