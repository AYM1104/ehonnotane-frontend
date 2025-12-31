import SwiftUI

/// 本棚ビュー（カレンダー表示）
struct BookShelfView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // タイトルテキスト
                MainText(text: "これまでに そだてた たね")
                    .padding(.bottom, 16)
                Spacer()
                        
                // メインカード
                mainCard(width: .screen95, height: nil) {
                    CalendarView()
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // ヘッダー
            Header()
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // タイトルテキスト
                MainText(text: "これまでに そだてた たね")
                    .padding(.bottom, 16)
                Spacer()
                        
                // メインカード
                mainCard(width: .screen95, height: nil) {
                    // テスト用のCalendarView（テストデータ付き）
                    CalendarViewWithTestData()
                        .environmentObject(AppCoordinator())
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        // ヘッダー
            Header()
                .environmentObject(AppCoordinator())
    }
}

/// プレビュー用：テストデータ付きCalendarView
struct CalendarViewWithTestData: View {
    @StateObject private var viewModel = CalendarViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    
    // テスト用の絵本データ
    private let testStorybooks: [StoryBookListItem] = [
        StoryBookListItem(
            id: 1,
            storyPlotId: 1,
            userId: "test-user-1",
            childId: 1,
            title: "うさぎとかめのおはなし",
            coverImageUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            isFavorite: true
        ),
        StoryBookListItem(
            id: 2,
            storyPlotId: 2,
            userId: "test-user-1",
            childId: 2,
            title: "ももたろう",
            coverImageUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            isFavorite: false
        ),
        StoryBookListItem(
            id: 3,
            storyPlotId: 3,
            userId: "test-user-1",
            childId: nil,
            title: "かぐやひめ",
            coverImageUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            isFavorite: true
        ),
        StoryBookListItem(
            id: 4,
            storyPlotId: 4,
            userId: "test-user-1",
            childId: 1,
            title: "シンデレラ",
            coverImageUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
            isFavorite: false
        ),
        StoryBookListItem(
            id: 5,
            storyPlotId: 5,
            userId: "test-user-1",
            childId: 2,
            title: "あかずきん",
            coverImageUrl: nil,
            createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
            isFavorite: true
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // カレンダー表示
                CalendarCard(
                    onChevronTap: {
                        viewModel.isWeekMode.toggle()
                    },
                    isWeekMode: viewModel.isWeekMode
                ) {
                    Group {
                        if viewModel.isWeekMode {
                            WeekCalendarView(
                                weekStartDate: $viewModel.weekStartDate,
                                selectedDate: $viewModel.selectedDate,
                                markedDates: viewModel.markedDates
                            )
                            .frame(maxWidth: CGFloat.infinity, alignment: .top)
                        } else {
                            MonthCalendarView(
                                displayDate: viewModel.displayDate,
                                selectedDate: $viewModel.selectedDate,
                                markedDates: viewModel.markedDates,
                                onDateChange: { newDate in
                                    viewModel.displayDate = newDate
                                }
                            )
                            .frame(maxWidth: CGFloat.infinity, alignment: .top)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .background(
                    GeometryReader { calendarGeometry in
                        Color.clear
                            .preference(key: CalendarHeightPreferenceKey.self, value: calendarGeometry.size.height)
                    }
                )
                
                // フィルターと絵本一覧を表示（テストデータ付き）
                StorybookListView(
                    storybooks: {
                        // 日付で降順にソート
                        let formatter = ISO8601DateFormatter()
                        var sorted = testStorybooks.sorted { book1, book2 in
                            guard let date1 = formatter.date(from: book1.createdAt),
                                  let date2 = formatter.date(from: book2.createdAt) else {
                                return false
                            }
                            return date1 > date2 // 降順（新しい日付が上）
                        }
                        
                        // selectedDateでフィルタリング
                        if let selectedDate = viewModel.selectedDate {
                            let calendar = Calendar.current
                            let selectedDateComponents = DateComponents(year: selectedDate.year, month: selectedDate.month, day: selectedDate.day)
                            sorted = sorted.filter {
                                let storybookDate = formatter.date(from: $0.createdAt)
                                let storybookDateComponents = storybookDate.map { calendar.dateComponents([.year, .month, .day], from: $0) }
                                return selectedDateComponents == storybookDateComponents
                            }
                        }
                        
                        // selectedChildIdでフィルタリング
                        if let childId = viewModel.selectedChildId {
                            sorted = sorted.filter { $0.childId == childId }
                        }
                        
                        return sorted
                    }(),
                    isLoading: false,
                    selectedDate: $viewModel.selectedDate,
                    selectedChildId: $viewModel.selectedChildId,
                    availableHeight: max(0, geometry.size.height - viewModel.calendarHeight - 16 - 16),
                    children: [
                        Child(id: 1, user_id: "test-user-1", name: "アユ", birthdate: nil, color_theme: nil, created_at: ""),
                        Child(id: 2, user_id: "test-user-1", name: "ハル", birthdate: nil, color_theme: nil, created_at: "")
                    ],
                    onFavoriteTap: { _ in
                        // プレビュー用：何もしない
                    }
                )
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
        }
        .onPreferenceChange(CalendarHeightPreferenceKey.self) { height in
            viewModel.calendarHeight = height
        }
        .onAppear {
            // プレビュー用：初期状態は「すべて」を表示（selectedDateはnilのまま）
            // テスト用：今日と過去数日をマーク
            let calendar = Calendar.current
            let today = Date()
            var markedDates: Set<YearMonthDay> = []
            for i in 0..<5 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let y = calendar.component(.year, from: date)
                    let m = calendar.component(.month, from: date)
                    let d = calendar.component(.day, from: date)
                    markedDates.insert(YearMonthDay(year: y, month: m, day: d))
                }
            }
            viewModel.markedDates = markedDates
        }
    }
}
