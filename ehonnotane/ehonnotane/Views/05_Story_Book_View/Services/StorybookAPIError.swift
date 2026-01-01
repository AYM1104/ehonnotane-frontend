import Foundation

// MARK: - API エラー定義

/// StorybookService で使用するAPIエラー定義
enum StorybookAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    case storybookNotFound
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        case .storybookNotFound:
            return "絵本が見つかりません"
        case .invalidResponse:
            return "無効なレスポンスです"
        }
    }
}
