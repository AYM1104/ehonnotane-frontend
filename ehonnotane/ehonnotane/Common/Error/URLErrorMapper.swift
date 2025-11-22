import Foundation

/// URLSession由来のURLErrorをユーザ向けNSErrorに変換するユーティリティ
struct URLErrorMapper {
    static func toNSError(_ urlError: URLError, baseURL: String) -> NSError {
        print("❌ URLエラー発生:")
        print("   - コード: \(urlError.code.rawValue)")
        print("   - 説明: \(urlError.localizedDescription)")
        let failingURLString: String
        if #available(iOS 18.4, *) {
            failingURLString = urlError.failingURL?.absoluteString ?? "不明"
        } else {
            failingURLString = urlError.failureURLString ?? "不明"
        }
        print("   - URL: \(failingURLString)")
        
        let description: String
        switch urlError.code {
        case .notConnectedToInternet:
            description = "インターネットに接続できません。ネットワーク設定を確認してください。"
        case .cannotConnectToHost:
            description = "サーバーに接続できません (\(baseURL))。バックエンドサーバーが起動しているか確認してください。"
        case .timedOut:
            description = "リクエストがタイムアウトしました。サーバーの応答を確認してください。"
        default:
            description = "ネットワークエラー: \(urlError.localizedDescription) (URL: \(baseURL))"
        }
        
        return NSError(domain: "NetworkError", code: urlError.code.rawValue, userInfo: [
            NSLocalizedDescriptionKey: description
        ])
    }
}

