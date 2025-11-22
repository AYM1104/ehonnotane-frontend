import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - リモート画像を表示するためのビュー

/// 紙面にリモート画像（URL）を表示（認証対応版）
@available(iOS 15.0, macOS 12.0, *)
public struct BookRemoteImagePage: View {
    public enum FitMode { case fit, fill }

    let url: URL
    let contentInset: CGFloat
    let fit: FitMode
    let background: Color
    let placeholderBackground: Color
    let text: String?
    let textAreaHeight: CGFloat
//    let authManager: AuthManager?

    public init(
        _ url: URL,
        contentInset: CGFloat = 24,
        fit: FitMode = .fit,
        background: Color = .white,
        placeholderBackground: Color = Color.black.opacity(0.05),
        text: String? = nil,
        textAreaHeight: CGFloat = 120,
//        authManager: AuthManager? = nil
    ) {
        self.url = url
        self.contentInset = contentInset
        self.fit = fit
        self.background = background
        self.placeholderBackground = placeholderBackground
        self.text = text
        self.textAreaHeight = textAreaHeight
//        self.authManager = authManager
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 画像エリア
            GeometryReader { geo in
                let w = geo.size.width
                let imageHeight = geo.size.height
                AuthenticatedAsyncImage(
                    url: url,
//                    authManager: authManager,
                    fit: fit,
                    width: w,
                    height: imageHeight
                )
            }
            .frame(maxWidth: .infinity)
            
            // テキストエリア
            if let text = text {
                ScrollView {
                    VStack(spacing: 0) {
                        SubText(text: text, fontSize: 20)
                            .padding(.horizontal, 16)
                            .lineSpacing(4)
                    }
                }
                .frame(height: textAreaHeight)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(background)
            }
        }
        .background(background)
    }

    private struct Scaled: ViewModifier {
        let mode: FitMode
        func body(content: Content) -> some View {
            switch mode {
            case .fit:  return AnyView(content.scaledToFit())
            case .fill: return AnyView(content.scaledToFill())
            }
        }
    }
}

// MARK: - 画像読み込みユーティリティ

/// GCS画像URLをプロキシエンドポイントに変換するユーティリティ関数
private func convertToProxyURL(_ originalURL: URL) -> URL? {
    let urlString = originalURL.absoluteString
    
    // storage.googleapis.comのURLの場合のみプロキシエンドポイントに変換
//    if urlString.contains("storage.googleapis.com") {
//        let baseURL = APIConfig.shared.baseURL
//        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            return originalURL
//        }
//        return URL(string: "\(baseURL)/api/images/proxy?url=\(encodedURL)")
//    }
    
    // それ以外のURLはそのまま返す
    return originalURL
}

/// 認証ヘッダー付きで画像を読み込むAsyncImageの代替コンポーネント
@available(iOS 15.0, macOS 12.0, *)
struct AuthenticatedAsyncImage: View {
    let url: URL
//    let authManager: AuthManager?
    let fit: BookRemoteImagePage.FitMode
    let width: CGFloat
    let height: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .modifier(ScaledModifier(mode: fit))
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .white.opacity(1.0), radius: 55, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.75), radius: 30, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 20)
                            .blur(radius: 50)
                    )
            } else if isLoading {
                ZStack {
                    Color.black.opacity(0.05)
                    ProgressView()
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    Color.black.opacity(0.05)
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        error = nil
        
        do {
            // GCS画像URLの場合はプロキシエンドポイントに変換
            let imageURL = convertToProxyURL(url) ?? url
            
            var request = URLRequest(url: imageURL)
            request.httpMethod = "GET"
            
            // プロキシエンドポイント経由の場合は認証トークンを追加
//            if imageURL.absoluteString.contains("/api/images/proxy"),
////               let authManager = authManager,
//               let token = authManager.getAccessToken() {
//                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//                print("🔐 プロキシ経由で画像を読み込み中: \(imageURL)")
//            } else {
//                print("📷 画像を読み込み中: \(imageURL)")
//            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "ImageLoadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "無効なレスポンス"])
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = "HTTP \(httpResponse.statusCode)"
                print("❌ 画像読み込みエラー: \(errorMessage) - \(imageURL)")
                throw NSError(domain: "ImageLoadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            guard let uiImage = UIImage(data: data) else {
                throw NSError(domain: "ImageLoadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗しました"])
            }
            
            await MainActor.run {
                self.image = uiImage
                self.isLoading = false
                print("✅ 画像読み込み成功: \(imageURL)")
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                print("❌ 画像読み込み失敗: \(error.localizedDescription) - \(url)")
            }
        }
    }
    
    private struct ScaledModifier: ViewModifier {
        let mode: BookRemoteImagePage.FitMode
        func body(content: Content) -> some View {
            switch mode {
            case .fit:  return AnyView(content.scaledToFit())
            case .fill: return AnyView(content.scaledToFill())
            }
        }
    }
}

