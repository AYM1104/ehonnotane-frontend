import Foundation

/// ストーリーブック統計データのモデル
struct Statistics: Codable {
    /// 総数（すべて）
    let total: Int
    
    /// 今月の作成数
    let thisMonth: Int
    
    /// 今週の作成数
    let thisWeek: Int
    
    enum CodingKeys: String, CodingKey {
        case total
        case thisMonth = "this_month"
        case thisWeek = "this_week"
    }
}
