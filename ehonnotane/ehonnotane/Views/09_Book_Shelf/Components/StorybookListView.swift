import SwiftUI

/// 絵本一覧ビュー
struct StorybookListView: View {
    let storybooks: [StoryBookListItem]
    let isLoading: Bool
    @Binding var selectedDate: YearMonthDay?
    @Binding var selectedChildId: Int? // 選択された子供のID
    var availableHeight: CGFloat? = nil // 利用可能な高さ（nilの場合は制限なし）
    let children: [Child] // 子供のリスト
    
    @State private var showFilterSheet = false // フィルターシートの表示状態
    
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // フィルター（常に表示）
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    }
                    .buttonStyle(.plain)
                    
                    // フィルタータグ（日付と子供）
                    HStack(spacing: 8) {
                        // 選択された日付のタグ、または「すべて」タグ
                        if let selected = selectedDate {
                            HStack(spacing: 6) {
                                Text(formatSelectedDate(selected))
                                    .font(.custom("YuseiMagic-Regular", size: 14))
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    selectedDate = nil
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        } else {
                            Text("すべて")
                                .font(.custom("YuseiMagic-Regular", size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                                                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                                                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        }
                        
                        // 選択された子供の名前タグ
                        if let childId = selectedChildId,
                           let child = children.first(where: { $0.id == childId }) {
                            HStack(spacing: 6) {
                                Text(child.name)
                                    .font(.custom("YuseiMagic-Regular", size: 14))
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    selectedChildId = nil
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                                                .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
                
                // 下線
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1)
                    .padding(.horizontal, 8)
            }
            .padding(.bottom, 12)
            
            // 絵本一覧（常に表示）
            if isLoading {
                ProgressView()
                    .padding()
                    .frame(maxHeight: availableHeight)
            } else if storybooks.isEmpty {
                Text(selectedDate == nil ? "絵本がありません" : "この日に作成した絵本はありません")
                    .font(.custom("YuseiMagic-Regular", size: 14))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.6))
                    .padding()
                    .frame(maxHeight: availableHeight)
            } else {
                // スクロール可能な絵本一覧
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(storybooks) { storybook in
                            StorybookListItemView(
                                storybook: storybook,
                                children: children,
                                onChildTagTap: { childId in
                                    // 子供の名前タグをタップしたときにフィルターを適用
                                    selectedChildId = childId
                                }
                            )
                            
                            if storybook.id != storybooks.last?.id {
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                            }
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 8) // 右側の余白を減らして右にずらす
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: availableHeight) // 利用可能な高さに制限
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                selectedDate: $selectedDate,
                selectedChildId: $selectedChildId,
                children: children
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    /// 選択された日付をフォーマット
    private func formatSelectedDate(_ date: YearMonthDay) -> String {
        // mm/dd形式で表示（月と日は2桁で表示）
        let month = String(format: "%02d", date.month)
        let day = String(format: "%02d", date.day)
        return "\(month)/\(day)"
    }
}

/// フィルター選択シート
struct FilterSheetView: View {
    @Binding var selectedDate: YearMonthDay?
    @Binding var selectedChildId: Int?
    let children: [Child]
    @Environment(\.dismiss) var dismiss
    
    // 一時的な選択状態（シート内での選択）
    @State private var tempSelectedDate: YearMonthDay?
    @State private var tempSelectedChildId: Int?
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日付フィルター
                VStack(alignment: .leading, spacing: 16) {
                    Text("日付で絞り込む")
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 日付選択オプション
                    VStack(spacing: 12) {
                        // 「すべて」オプション
                        Button(action: {
                            tempSelectedDate = nil
                        }) {
                            HStack {
                                Image(systemName: tempSelectedDate == nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tempSelectedDate == nil ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.gray)
                                Text("すべて")
                                    .font(.custom("YuseiMagic-Regular", size: 16))
                                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tempSelectedDate == nil ? Color(red: 20/255, green: 184/255, blue: 166/255).opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // 日付を選択
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: tempSelectedDate != nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tempSelectedDate != nil ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.gray)
                                Text(tempSelectedDate != nil ? formatDate(tempSelectedDate!) : "日付を選択")
                                    .font(.custom("YuseiMagic-Regular", size: 16))
                                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tempSelectedDate != nil ? Color(red: 20/255, green: 184/255, blue: 166/255).opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
                
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                // 子供フィルター
                VStack(alignment: .leading, spacing: 16) {
                    Text("子供で絞り込む")
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .padding(.horizontal, 20)
                    
                    // 子供選択オプション
                    VStack(spacing: 12) {
                        // 「すべて」オプション
                        Button(action: {
                            tempSelectedChildId = nil
                        }) {
                            HStack {
                                Image(systemName: tempSelectedChildId == nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tempSelectedChildId == nil ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.gray)
                                Text("すべて")
                                    .font(.custom("YuseiMagic-Regular", size: 16))
                                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(tempSelectedChildId == nil ? Color(red: 20/255, green: 184/255, blue: 166/255).opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // 子供のリスト
                        ForEach(children) { child in
                            Button(action: {
                                tempSelectedChildId = child.id
                            }) {
                                HStack {
                                    Image(systemName: tempSelectedChildId == child.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(tempSelectedChildId == child.id ? Color(red: 20/255, green: 184/255, blue: 166/255) : Color.gray)
                                    Text(child.name)
                                        .font(.custom("YuseiMagic-Regular", size: 16))
                                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tempSelectedChildId == child.id ? Color(red: 20/255, green: 184/255, blue: 166/255).opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        selectedDate = tempSelectedDate
                        selectedChildId = tempSelectedChildId
                        dismiss()
                    }
                    .foregroundColor(Color(red: 20/255, green: 184/255, blue: 166/255))
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheetView(selectedDate: $tempSelectedDate)
            }
            .onAppear {
                // シート表示時に現在の選択状態を一時変数にコピー
                tempSelectedDate = selectedDate
                tempSelectedChildId = selectedChildId
            }
        }
    }
    
    /// 日付をフォーマット
    private func formatDate(_ date: YearMonthDay) -> String {
        let calendar = Calendar.current
        if let dateObj = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: dateObj)
        }
        return "\(date.year)年\(date.month)月\(date.day)日"
    }
}

/// 日付選択シート
struct DatePickerSheetView: View {
    @Binding var selectedDate: YearMonthDay?
    @Environment(\.dismiss) var dismiss
    @State private var pickerDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    DatePicker(
                        "", // ラベルは表示しない
                        selection: $pickerDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    Spacer()
                }
                .padding(.leading)
                .padding(.trailing, 32) // 右側に追加の余白
                .padding(.vertical)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("決定") {
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: pickerDate)
                        let month = calendar.component(.month, from: pickerDate)
                        let day = calendar.component(.day, from: pickerDate)
                        selectedDate = YearMonthDay(year: year, month: month, day: day)
                        dismiss()
                    }
                    .foregroundColor(Color(red: 20/255, green: 184/255, blue: 166/255))
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                // 既に選択されている日付がある場合はそれを表示
                if let date = selectedDate {
                    let calendar = Calendar.current
                    if let dateObj = calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) {
                        pickerDate = dateObj
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// 絵本リストアイテムビュー
struct StorybookListItemView: View {
    let storybook: StoryBookListItem
    let children: [Child] // 子供のリスト
    let onChildTagTap: ((Int) -> Void)? // 子供の名前タグをタップしたときのコールバック
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        Button {
            coordinator.navigateToStorybook(storybookId: storybook.id)
        } label: {
            HStack(spacing: 12) {
                // 表紙画像（MyPageと同じサイズ）
                Group {
                    if let coverImageUrl = storybook.coverImageUrl, !coverImageUrl.isEmpty {
                        AsyncImage(url: URL(string: coverImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 90, height: 120)
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
                .frame(width: 90, height: 120)
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
                
                // ハートアイコンと子供の名前タグ
                VStack(spacing: 8) {
                    // ハートアイコン
                    Image(systemName: storybook.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(storybook.isFavorite ? .red : Color.gray.opacity(0.5))
                    
                    // 子供の名前のタグ（ハートの下に配置、タップ可能）
                    if let childId = storybook.childId,
                       let child = children.first(where: { $0.id == childId }) {
                        Button(action: {
                            onChildTagTap?(childId)
                        }) {
                            Text(child.name)
                                .font(.custom("YuseiMagic-Regular", size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 20/255, green: 184/255, blue: 166/255))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 8) // スクロールバーとの間に余白
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    /// プレースホルダー表紙（MyPageと同じスタイル：四角い図形）
    @ViewBuilder
    private func placeholderBookCover() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .cornerRadius(8)
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

