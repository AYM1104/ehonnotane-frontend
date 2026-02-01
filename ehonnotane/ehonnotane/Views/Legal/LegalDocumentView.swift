import SwiftUI
import WebKit

/// 利用規約・プライバシーポリシー表示用のWebView
struct LegalDocumentView: View {
    enum DocumentType {
        case termsOfService
        case privacyPolicy
        
        var title: String {
            switch self {
            case .termsOfService:
                return String(localized: "settings.terms")
            case .privacyPolicy:
                return String(localized: "settings.privacy")
            }
        }
        
        var fileName: String {
            // デバイスの言語設定に応じてファイルを切り替え
            let languageCode = Locale.current.language.languageCode?.identifier ?? "ja"
            let suffix = languageCode == "ja" ? "" : "_en"
            
            switch self {
            case .termsOfService:
                return "terms_of_service\(suffix)"
            case .privacyPolicy:
                return "privacy_policy\(suffix)"
            }
        }
    }
    
    let documentType: DocumentType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            LocalHTMLWebView(fileName: documentType.fileName)
                .navigationTitle(documentType.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String(localized: "common.close")) {
                            dismiss()
                        }
                    }
                }
        }
    }
}

/// ローカルHTMLファイルを表示するWebView
struct LocalHTMLWebView: UIViewRepresentable {
    let fileName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // バンドル内のHTMLファイルを読み込み
        if let url = Bundle.main.url(forResource: fileName, withExtension: "html") {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            // ファイルが見つからない場合のフォールバック
            let html = """
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, sans-serif;
                        padding: 20px;
                        text-align: center;
                        color: #666;
                    }
                </style>
            </head>
            <body>
                <p>ドキュメントを読み込めませんでした。</p>
                <p>後ほど再度お試しください。</p>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
}

// MARK: - Preview

#Preview("利用規約") {
    LegalDocumentView(documentType: .termsOfService)
}

#Preview("プライバシーポリシー") {
    LegalDocumentView(documentType: .privacyPolicy)
}
