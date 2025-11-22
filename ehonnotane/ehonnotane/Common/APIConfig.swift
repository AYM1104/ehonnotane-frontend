import Foundation

/// API設定を一元管理するクラス
class APIConfig {
    /// シングルトンインスタンス
    static let shared = APIConfig()
    
    /// 実際に使用するベースURL
    private let resolvedBaseURL: String
    
    /// デバッグモードかどうか
    let isDebugMode: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// バックエンドAPIのベースURL
    var baseURL: String { resolvedBaseURL }
    
    /// ローカル開発用のURL（デバッグ時のみ使用可能）
    var localURL: String {
        return "http://192.168.3.92:8000"
    }
    
    /// 現在使用中のURLを取得（デバッグ情報用）
    var currentURL: String {
        return baseURL
    }
    
    /// プライベートイニシャライザ（シングルトンパターン）
    private init() {
        if let infoPlistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           infoPlistURL.isEmpty == false {
            resolvedBaseURL = infoPlistURL
        } else if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"],
                  envURL.isEmpty == false {
            resolvedBaseURL = envURL
        } else {
            resolvedBaseURL = "http://127.0.0.1:8000"
            print("⚠️ APIConfig: Info.plist/API_BASE_URLが未設定のためデフォルトURLを使用します")
        }
        
        print("🔧 APIConfig初期化: baseURL = \(resolvedBaseURL)")
        print("   - デバッグモード: \(isDebugMode)")
    }
    
    /// URLが有効かどうかを検証
    func isValidURL() -> Bool {
        guard let url = URL(string: baseURL) else {
            return false
        }
        return url.scheme == "http" || url.scheme == "https"
    }
}

