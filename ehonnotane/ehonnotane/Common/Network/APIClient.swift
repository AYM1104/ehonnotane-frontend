import Foundation
import Combine

// MARK: - API Error Definition

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case networkError(Error)
    case serverError(Int, String)
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .encodingError:
            return "データのリクエスト作成に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        case .unauthorized:
            return "認証が必要です"
        case .unknown:
            return "予期しないエラーが発生しました"
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()
    
    private var baseURL: String {
        return APIConfig.shared.baseURL
    }
    
    private init() {}
    
    /// 汎用的なAPIリクエスト
    /// - Parameters:
    ///   - endpoint: APIのエンドポイント（例: "/api/users"）
    ///   - method: HTTPメソッド（デフォルト: .get）
    ///   - body: リクエストボディ（Encodable準拠、デフォルト: nil）
    /// - Returns: デコードされたレスポンスデータ
    func request<T: Decodable, B: Encodable>(endpoint: String, method: HTTPMethod = .get, body: B? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        print("🌐 API Request: \(method.rawValue) \(url.absoluteString)")
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // リクエストボディの設定
            if let body = body {
                let encoder = JSONEncoder()
                // 日付フォーマットが必要な場合はここで設定
                // encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
                
                #if DEBUG
                if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                    print("📦 Request Body: \(jsonString)")
                }
                #endif
            }
            
            // 共通ヘッダー（認証トークンなど）の設定
            if let token = AuthManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    throw APIError.unauthorized
                case 404:
                    // 404の場合もエラーとして扱うが、呼び出し元でハンドリングしやすいように区別
                    throw APIError.serverError(404, "リソースが見つかりません")
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    print("❌ Server Error Message: \(errorMessage)")
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    throw APIError.unknown
                }
            }
            
            // レスポンスログ（デバッグ用）
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                // 長すぎる場合は省略するなどの処理を入れても良い
                print("📄 Response: \(jsonString)")
            }
            #endif
            
            // レスポンスのデコード
            // レスポンスが空で、TがVoidのような型の場合は特別扱いが必要かもしれないが、
            // 基本的にはJSONが返ってくる前提
            if data.isEmpty {
                // 空レスポンスを許容する場合の処理（必要に応じて実装）
                // TがOptionalならnilを返すなど
                throw APIError.noData
            }
            
            let decoder = JSONDecoder()
            // 日付フォーマットなどが必要な場合はここで設定
            // decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ Decoding Error: \(decodingError)")
            throw APIError.decodingError
        } catch let encodingError as EncodingError {
             print("❌ Encoding Error: \(encodingError)")
             throw APIError.encodingError
        } catch {
            print("❌ Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    /// リクエストボディなしのGETリクエスト用コンビニエンスメソッド
    func request<T: Decodable>(endpoint: String) async throws -> T {
        // bodyに渡す型として、Encodableに準拠したダミーの型（例えばString? = nil）を指定する必要がある
        // ここでは nil を渡すので、型推論を助けるために明示的に型を指定する
        let body: String? = nil
        return try await request(endpoint: endpoint, method: .get, body: body)
    }
}
