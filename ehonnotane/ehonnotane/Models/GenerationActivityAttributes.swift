import Foundation
import ActivityKit

/// 絵本生成のLive Activityで扱うデータの定義
public struct GenerationActivityAttributes: ActivityAttributes {
    
    // 静的なデータ（アクティビティ開始時に一度だけ設定され、変更されないデータ）
    public struct ContentState: Codable, Hashable {
        /// 現在の進捗状況のテキスト（例: "物語を作成中...", "画像を生成中..."）
        public var progressText: String
        
        /// 進捗の割合（0.0 から 1.0）
        public var progressValue: Double
        
        /// 完了予定時刻（これをもとに残り時間タイマーを表示します）
        public var estimatedEndTime: Date
        
        /// 状態（"in_progress", "completed", "error" など）
        public var status: String
    }
    
    /// 絵本のタイトルまたはテーマ（静的データ）
    public var bookTitle: String
    
    /// 対象となる子供の名前（静的データ）
    public var childName: String
}
