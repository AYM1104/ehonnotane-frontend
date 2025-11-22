import Foundation

/// アプリ全体で利用するネットワークエラー定義
enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case imageConversionFailed
    case uploadFailed
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .uploadFailed:
            return "画像のアップロードに失敗しました"
        case .authenticationRequired:
            return "ログインが必要です"
        }
    }
}

