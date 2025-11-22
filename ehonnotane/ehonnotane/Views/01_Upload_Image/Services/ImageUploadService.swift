import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif


// 画像アップロードサービス
class ImageUploadService: ObservableObject {
    // ObservableObjectの要件を満たすためのPublishedプロパティ
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    // バックエンドAPIのベースURL（環境変数優先、未設定時はローカル）
    private let baseURL: String
    private let urlSession: URLSession
    
    // MARK: - 認証管理
    private let authProvider: AuthProviding
    
    // MARK: - 初期化
    init(authProvider: AuthProviding = DefaultAuthProvider(), urlSession: URLSession = .shared) {
        self.authProvider = authProvider
        self.urlSession = urlSession
        // APIConfigからURLを取得
        self.baseURL = APIConfig.shared.baseURL
        print("🔧 ImageUploadService初期化: baseURL = \(baseURL)")
    }
    
    // MARK: - 認証トークン管理（AuthManagerを使用）
    
    /// アクセストークンを設定
    func setAccessToken(_ token: String?) {
        // AuthManagerを使用するため、このメソッドは非推奨
        print("⚠️ setAccessTokenは非推奨です。AuthManagerを使用してください")
    }
    
    /// 現在のアクセストークンを取得
    func getAccessToken() -> String? {
        return authProvider.getAccessToken()
    }
    
    /// 認証状態を確認
    func isAuthenticated() -> Bool {
        return authProvider.isAuthenticated()
    }
    
    // 現在のユーザーIDを取得
    private func getCurrentUserId() -> String {
        return authProvider.getCurrentUserId() ?? "0"
    }
    
    // 画像をアップロード
    func uploadImage(_ image: Any) async throws -> UploadImageResponse {
        #if canImport(UIKit)
        let uiImage = try resolveUIImage(from: image)
        let token = try requireAccessToken()
        print("✅ 認証済みユーザーでアップロードを実行")
        
        let payload = try prepareImagePayload(from: uiImage)
        let boundary = UUID().uuidString
        let body = buildMultipartBody(
            boundary: boundary,
            userId: getCurrentUserId(),
            payload: payload
        )
        
        var request = makeRequest(path: "/api/images/upload", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        
        // リクエストURLをログ出力
        print("🌐 アップロードリクエスト送信先: \(request.url!)")
        print("📦 リクエストサイズ: \(body.count) bytes")
        
        do {
            return try await sendUploadRequest(request: request)
        } catch let urlError as URLError {
            throw URLErrorMapper.toNSError(urlError, baseURL: baseURL)
        } catch {
            print("❌ 予期しないエラー: \(error.localizedDescription)")
            throw error
        }
        
        #else
        throw NetworkError.uploadFailed
        #endif
    }
    
    // 認証済みURLを取得する
    func getSignedUrl(imageId: Int) async throws -> String {
        var request = makeRequest(path: "/images/signed-url/\(imageId)")
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, httpResponse) = try await performDataTask(for: request)
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let signedUrlResponse = try JSONDecoder().decode(SignedUrlResponse.self, from: data)
        return signedUrlResponse.signed_url
    }
    
    // MARK: - リクエスト共通処理
    
    // 画像の型変換（Any -> UIImageへ変換）
    private func resolveUIImage(from image: Any) throws -> UIImage {
        guard let uiImage = image as? UIImage else {
            throw NetworkError.imageConversionFailed
        }
        return uiImage
    }
    
    // 認証トークンを取得
    private func requireAccessToken() throws -> String {
        guard let token = getAccessToken() else {
            print("❌ 認証トークンが未設定です")
            throw NetworkError.authenticationRequired
        }
        return token
    }
    
    /// UIImageからアップロード用データを作成（常にJPEG形式で保存）
    private func prepareImagePayload(from uiImage: UIImage) throws -> ImagePayload {
        // 画像サイズに応じて圧縮率を調整
        // 長辺が3000ピクセルを超える場合は0.7、それ以外は0.8
        let maxDimension = max(uiImage.size.width, uiImage.size.height)
        let compressionQuality: CGFloat = maxDimension > 3000 ? 0.7 : 0.8
        
        guard let jpegData = uiImage.jpegData(compressionQuality: compressionQuality) else {
            throw NetworkError.imageConversionFailed
        }
        
        print("📸 画像形式: image/jpeg")
        print("📏 画像サイズ: \(uiImage.size.width)x\(uiImage.size.height)")
        print("💾 ファイルサイズ: \(jpegData.count) bytes")
        print("🎚️ 圧縮率: \(compressionQuality)")
        
        return ImagePayload(
            data: jpegData,
            contentType: "image/jpeg",
            filename: "image.jpg"
        )
    }
    
    /// Multipartデータを組み立て（ユーザーIDとファイルデータ）
    private func buildMultipartBody(boundary: String, userId: String, payload: ImagePayload) -> Data {
        var body = Data()
        
        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }
        
        // ユーザーIDを追加
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n")
        append("\(userId)\r\n")
        
        // ファイルデータを追加
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(payload.filename)\"\r\n")
        append("Content-Type: \(payload.contentType)\r\n\r\n")
        body.append(payload.data)
        append("\r\n")
        append("--\(boundary)--\r\n")
        
        return body
    }
    
    // URLRequestを作成
    private func makeRequest(path: String, method: String = "GET") -> URLRequest {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }
    
    /// URLSession経由でリクエストを実行
    private func performDataTask(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 無効なHTTPレスポンス")
            throw NetworkError.invalidResponse
        }
        print("📥 HTTPステータスコード: \(httpResponse.statusCode)")
        return (data, httpResponse)
    }
    
    /// 画像アップロード専用のレスポンス処理
    private func sendUploadRequest(request: URLRequest) async throws -> UploadImageResponse {
        let (data, httpResponse) = try await performDataTask(for: request)
        
        if httpResponse.statusCode == 401 {
            print("❌ 認証エラー: トークンが無効です")
            throw NetworkError.authenticationRequired
        } else if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            print("❌ サーバーエラー (\(httpResponse.statusCode)): \(errorMessage)")
            throw NetworkError.uploadFailed
        }
        
        return try JSONDecoder().decode(UploadImageResponse.self, from: data)
    }
    
    /// 画像アップロード用のペイロード情報
    private struct ImagePayload {
        let data: Data
        let contentType: String
        let filename: String
    }
}

