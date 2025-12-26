import SwiftUI

/// 絵本一覧ビュー
struct StorybookListView: View {
    let storybooks: [StoryBookListItem]
    let isLoading: Bool
    @Binding var selectedDate: YearMonthDay?
    
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // フィルター（常に表示）
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    
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
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 12)
                
                // 下線
                Rectangle()
                    .fill(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 12)
            
            // 絵本一覧（日付が選択されている場合のみ表示）
            if let _ = selectedDate {
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
    
    /// 選択された日付をフォーマット
    private func formatSelectedDate(_ date: YearMonthDay) -> String {
        // mm/dd形式で表示（月と日は2桁で表示）
        let month = String(format: "%02d", date.month)
        let day = String(format: "%02d", date.day)
        return "\(month)/\(day)"
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

