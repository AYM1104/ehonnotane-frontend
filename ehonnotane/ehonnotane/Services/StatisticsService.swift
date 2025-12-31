import Foundation

/// 統計データ取得サービス
class StatisticsService {
    static let shared = StatisticsService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 統計データを取得
    /// - Parameter userId: ユーザーID
    /// - Returns: 統計データ
    func fetchStatistics(userId: String) async throws -> Statistics {
        print("🔵 [StatisticsService] 統計データ取得開始 - userId: \(userId)")
        
        let endpoint = "/api/storybook/stats/\(userId)"
        
        do {
            let response: StatisticsResponse = try await apiClient.request(endpoint: endpoint)
            print("✅ [StatisticsService] 統計データ取得成功: すべて=\(response.total), 今月=\(response.thisMonth), 今週=\(response.thisWeek)")
            
            return Statistics(
                total: response.total,
                thisMonth: response.thisMonth,
                thisWeek: response.thisWeek
            )
        } catch {
            print("❌ [StatisticsService] 統計データ取得失敗: \(error)")
            throw error
        }
    }
}

/// APIレスポンス用の内部モデル
private struct StatisticsResponse: Codable {
    let userId: String
    let total: Int
    let thisMonth: Int
    let thisWeek: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case total
        case thisMonth = "this_month"
        case thisWeek = "this_week"
    }
}
