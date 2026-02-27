//
//  GenerationWidgetLiveActivity.swift
//  GenerationWidget
//
//  Created by ayu on 2026/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

//
//  GenerationWidgetLiveActivity.swift
//  GenerationWidget
//
//  Created by ayu on 2026/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// メインアプリ内のModels/GenerationActivityAttributes.swiftに合わせる必要があります
// （両方のターゲットに追加していれば自動で参照できます）

struct GenerationWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenerationActivityAttributes.self) { context in
            // ロック画面 / 通知センターのUI
            VStack {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(.green)
                    Text("絵本「\(context.attributes.bookTitle)」を生成中...")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 4)
                
                HStack {
                    Text(context.state.progressText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if context.state.status == "in_progress" {
                        Text("\(Int(context.state.progressValue * 100))%")
                            .font(.system(.body, design: .monospaced))
                            .bold()
                    } else if context.state.status == "completed" {
                        Text("完成！")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Text("エラーが発生しました")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(context.state.progressValue))
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
            }
            .padding()
            .activityBackgroundTint(Color.white.opacity(0.9))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Dynamic Islandが展開（長押し）された時のUI
                
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.status == "in_progress" {
                        Text("\(Int(context.state.progressValue * 100))%")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("「\(context.attributes.bookTitle)」")
                        .font(.headline)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.progressText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 進捗バー
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.3))
                                Capsule()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * CGFloat(context.state.progressValue))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            } compactLeading: {
                // Dynamic Islandの左側（通常時）
                Image(systemName: "book.closed")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Dynamic Islandの右側（通常時）
                if context.state.status == "in_progress" {
                    Text("\(Int(context.state.progressValue * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .frame(maxWidth: 30) // 幅を制限してはみ出し防止
                } else if context.state.status == "completed" {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } minimal: {
                // 他のアクティビティが同時にある時の最小表示
                Image(systemName: "book.closed")
                    .foregroundColor(.green)
            }
            .widgetURL(URL(string: "ehonnotane://generation")) // タップ時にアプリを開くURL
            .keylineTint(Color.green)
        }
    }
}
