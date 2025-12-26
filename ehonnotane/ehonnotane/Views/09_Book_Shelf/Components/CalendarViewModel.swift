import Foundation
import SwiftUI
import Combine

/// カレンダービューの状態管理とデータフェッチロジックを担当するViewModel
@MainActor
class CalendarViewModel: ObservableObject {
    /// 選択された日付
    @Published var selectedDate: YearMonthDay? = nil
    /// 表示する年月
    @Published var displayDate = Date()
    /// カレンダーの表示モード（false: 月カレンダー, true: 週カレンダー）
    @Published var isWeekMode = true
    /// 選択された日付の絵本一覧
    @Published var storybooks: [StoryBookListItem] = []
    /// 絵本一覧の読み込み状態
    @Published var isLoadingStorybooks = false
    /// エラーメッセージ
    @Published var errorMessage: String?
    /// 絵本を作成した日付のセット
    @Published var markedDates: Set<YearMonthDay> = []
    /// 週カレンダーの開始日（親で管理）
    @Published var weekStartDate: Date = {
        let calendar = Calendar.current
        let date = Date()
        let weekday = calendar.component(.weekday, from: date)
        let daysFromSunday = (weekday - 1) % 7
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysFromSunday, to: date) {
            return startOfWeek
        }
        return date
    }()
    
    private let storybookService = StorybookService.shared
    
    /// 選択された日付が変更されたときに呼び出される
    func onSelectedDateChanged(oldValue: YearMonthDay?, newValue: YearMonthDay?) {
        if let date = newValue {
            fetchStorybooksForDate(date)
        } else {
            storybooks = []
        }
    }
    
    /// 表示日付が変更されたときに呼び出される
    func onDisplayDateChanged() {
        if !isWeekMode {
            fetchMarkedDatesForMonth()
        }
    }
    
    /// 週モードが変更されたときに呼び出される
    func onWeekModeChanged(newValue: Bool) {
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
    
    /// 週開始日が変更されたときに呼び出される
    func onWeekStartDateChanged() {
        if isWeekMode {
            fetchMarkedDatesForWeek()
        }
    }
    
    /// 初期データを読み込む
    func loadInitialData() {
        if isWeekMode {
            fetchMarkedDatesForWeek()
        } else {
            fetchMarkedDatesForMonth()
        }
    }
    
    /// 表示中の月で絵本を作成した日付を取得
    func fetchMarkedDatesForMonth() {
        guard let userId = storybookService.getCurrentUserId() else {
            return
        }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayDate)
        let month = calendar.component(.month, from: displayDate)
        
        Task {
            do {
                let days = try await storybookService.fetchCreatedDays(
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
    func fetchMarkedDatesForWeek() {
        guard let userId = storybookService.getCurrentUserId() else {
            return
        }
        
        let calendar = Calendar.current
        let weekStart = weekStartDate
        
        Task {
            do {
                var newMarkedDates: Set<YearMonthDay> = []
                // 週の各日をチェック
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        let year = calendar.component(.year, from: date)
                        let month = calendar.component(.month, from: date)
                        let day = calendar.component(.day, from: date)
                        
                        // その日の絵本を取得して、存在するか確認
                        let books = try await storybookService.fetchUserStorybooksByDate(
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
    func fetchStorybooksForDate(_ date: YearMonthDay) {
        guard let userId = storybookService.getCurrentUserId() else {
            return
        }
        
        isLoadingStorybooks = true
        errorMessage = nil
        
        Task {
            do {
                let books = try await storybookService.fetchUserStorybooksByDate(
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

