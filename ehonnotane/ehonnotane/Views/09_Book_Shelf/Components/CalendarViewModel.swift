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
    
    /// カレンダーの高さ（動的に測定）
    @Published var calendarHeight: CGFloat = 0
    
    /// 子供のリスト
    @Published var children: [Child] = []
    
    /// 選択された子供のID（フィルター用）
    @Published var selectedChildId: Int? = nil
    
    private let storybookService = StorybookService.shared
    private let childService = ChildService.shared
    
    /// 選択された日付が変更されたときに呼び出される
    func onSelectedDateChanged(oldValue: YearMonthDay?, newValue: YearMonthDay?) {
        if let date = newValue {
            fetchStorybooksForDate(date)
        } else {
            // 「すべて」が選択された場合は全絵本を取得
            fetchAllStorybooks()
        }
    }
    
    /// 選択された子供が変更されたときに呼び出される
    func onSelectedChildChanged(childId: Int?) {
        selectedChildId = childId
        // 現在のフィルター条件で絵本一覧を再取得
        if let date = selectedDate {
            fetchStorybooksForDate(date)
        } else {
            fetchAllStorybooks()
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
        loadChildren()
        // 初期表示時は「すべて」なので全絵本を取得
        fetchAllStorybooks()
        if isWeekMode {
            fetchMarkedDatesForWeek()
        } else {
            fetchMarkedDatesForMonth()
        }
    }
    
    /// 子供のリストを取得
    private func loadChildren() {
        guard let userId = storybookService.getCurrentUserId() else {
            return
        }
        
        Task {
            do {
                let fetchedChildren = try await childService.fetchChildren(userId: userId)
                children = fetchedChildren
            } catch {
                print("❌ 子供情報の取得エラー: \(error)")
                children = []
            }
        }
    }
    
    /// childIdから子供の名前を取得するヘルパーメソッド
    func getChildName(childId: Int?) -> String? {
        guard let childId = childId else { return nil }
        return children.first { $0.id == childId }?.name
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
                // 週の開始日の年月を取得
                let year = calendar.component(.year, from: weekStart)
                let month = calendar.component(.month, from: weekStart)
                
                // 月全体の作成日を1回のAPI呼び出しで取得（7回 → 1回に削減）
                let createdDays = try await storybookService.fetchCreatedDays(
                    userId: userId,
                    year: year,
                    month: month
                )
                
                // 週の範囲（7日間）を計算
                var weekDays: Set<Int> = []
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        let dateYear = calendar.component(.year, from: date)
                        let dateMonth = calendar.component(.month, from: date)
                        let dateDay = calendar.component(.day, from: date)
                        
                        // 同じ年月で、作成日に含まれる日付のみマーク
                        if dateYear == year && dateMonth == month && createdDays.contains(dateDay) {
                            weekDays.insert(dateDay)
                        }
                    }
                }
                
                // マーク済み日付セットを更新
                var newMarkedDates: Set<YearMonthDay> = []
                for day in weekDays {
                    newMarkedDates.insert(YearMonthDay(year: year, month: month, day: day))
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
                storybooks = sortStorybooksByDate(books)
            } catch {
                errorMessage = error.localizedDescription
                storybooks = []
                print("❌ 絵本一覧取得エラー: \(error)")
            }
            isLoadingStorybooks = false
        }
    }
    
    /// 全ての絵本一覧を取得
    func fetchAllStorybooks() {
        guard let userId = storybookService.getCurrentUserId() else {
            return
        }
        
        isLoadingStorybooks = true
        errorMessage = nil
        
        Task {
            do {
                let books = try await storybookService.fetchUserStorybooks(userId: userId)
                storybooks = sortStorybooksByDate(books)
            } catch {
                errorMessage = error.localizedDescription
                storybooks = []
                print("❌ 全絵本一覧取得エラー: \(error)")
            }
            isLoadingStorybooks = false
        }
    }
    
    /// 絵本一覧を日付で降順にソートし、子供でフィルター
    private func sortStorybooksByDate(_ books: [StoryBookListItem]) -> [StoryBookListItem] {
        let formatter = ISO8601DateFormatter()
        var filtered = books
        
        // 子供でフィルター
        if let childId = selectedChildId {
            filtered = filtered.filter { $0.childId == childId }
        }
        
        // 日付で降順にソート
        return filtered.sorted { book1, book2 in
            guard let date1 = formatter.date(from: book1.createdAt),
                  let date2 = formatter.date(from: book2.createdAt) else {
                return false
            }
            return date1 > date2 // 降順（新しい日付が上）
        }
    }
    
    /// お気に入り状態を更新（API完了を待つ）
    func toggleFavorite(storybookId: Int) async {
        // 1. UIを即座に更新（楽観的更新）
        if let index = storybooks.firstIndex(where: { $0.id == storybookId }) {
            let updatedBook = storybooks[index]
            let newFavoriteStatus = !updatedBook.isFavorite
            
            // ※ structなので新しいインスタンスを作成して差し替える
            let updatedItem = StoryBookListItem(
                id: updatedBook.id,
                storyPlotId: updatedBook.storyPlotId,
                userId: updatedBook.userId,
                childId: updatedBook.childId,
                title: updatedBook.title,
                coverImageUrl: updatedBook.coverImageUrl,
                createdAt: updatedBook.createdAt,
                isFavorite: newFavoriteStatus
            )
            storybooks[index] = updatedItem
            
            // 2. API呼び出しの完了を待つ
            do {
                try await storybookService.updateFavoriteStatus(
                    storybookId: storybookId,
                    isFavorite: newFavoriteStatus
                )
                print("✅ お気に入り状態を更新しました: \(newFavoriteStatus)")
            } catch {
                // 3. エラー時は元の状態に戻す（ロールバック）
                print("❌ お気に入り更新エラー: \(error)")
                storybooks[index] = updatedBook // 元の状態に戻す
                errorMessage = "お気に入りの更新に失敗しました"
            }
        }
    }
}

