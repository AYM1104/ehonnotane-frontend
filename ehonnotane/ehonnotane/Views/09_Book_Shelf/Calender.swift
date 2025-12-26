import SwiftUI

/// カレンダーの高さを測定するためのPreferenceKey
struct CalendarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// カレンダーコンテナビュー（月カレンダーと週カレンダーを切り替え可能）
struct CalendarView: View {
    /// AppCoordinator（認証情報とStorybookServiceを含む）
    @EnvironmentObject var coordinator: AppCoordinator
    
    /// ViewModel（状態管理とデータフェッチロジック）
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // カレンダー表示
                CalendarCard(
                    onChevronTap: {
                        // chevronアイコンをクリックすると月/週カレンダーを切り替え
                        viewModel.isWeekMode.toggle()
                    },
                    isWeekMode: viewModel.isWeekMode
                ) {
                    Group {
                        if viewModel.isWeekMode {
                            // 週カレンダー表示（選択された日付がある場合はその日付を含む週を表示）
                            WeekCalendarView(
                                weekStartDate: $viewModel.weekStartDate,
                                selectedDate: $viewModel.selectedDate,
                                markedDates: viewModel.markedDates
                            )
                            .frame(maxWidth: CGFloat.infinity, alignment: .top)
                        } else {
                            // 月カレンダー表示
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
                    .frame(minWidth: 0, maxWidth: .infinity) // 幅を固定（月カレンダーのサイズに合わせる）
                }
                .background(
                    // カレンダーの高さを測定するための背景
                    GeometryReader { calendarGeometry in
                        Color.clear
                            .preference(key: CalendarHeightPreferenceKey.self, value: calendarGeometry.size.height)
                    }
                )
                
                // フィルターと絵本一覧を表示（常に表示）
                StorybookListView(
                    storybooks: viewModel.storybooks,
                    isLoading: viewModel.isLoadingStorybooks,
                    selectedDate: $viewModel.selectedDate,
                    selectedChildId: $viewModel.selectedChildId,
                    availableHeight: max(0, geometry.size.height - viewModel.calendarHeight - 16 - 16), // カレンダー高さ + padding(.top, 16) + 下部余白16pxを引く
                    children: viewModel.children
                )
                .padding(.top, 16)
                .padding(.bottom, 16) // 下部余白16px
            }
        }
        .onPreferenceChange(CalendarHeightPreferenceKey.self) { height in
            viewModel.calendarHeight = height
        }
        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
            viewModel.onSelectedDateChanged(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: viewModel.displayDate) { _, _ in
            viewModel.onDisplayDateChanged()
        }
        .onChange(of: viewModel.isWeekMode) { _, newValue in
            viewModel.onWeekModeChanged(newValue: newValue)
        }
        .onChange(of: viewModel.weekStartDate) { _, _ in
            viewModel.onWeekStartDateChanged()
        }
        .onChange(of: viewModel.selectedChildId) { _, newValue in
            viewModel.onSelectedChildChanged(childId: newValue)
        }
        .onAppear {
            viewModel.loadInitialData()
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
