import SwiftUI
import CoreText

// フォント登録ヘルパー
class FontRegistration {
    /// カスタムフォントを登録
    static func registerFonts() {
        registerFont(bundle: Bundle.main, fontName: "YuseiMagic-Regular", fontExtension: "ttf")
    }
    
    /// 指定されたフォントファイルを登録
    /// - Parameters:
    ///   - bundle: フォントファイルが含まれるバンドル
    ///   - fontName: フォントファイル名（拡張子なし）
    ///   - fontExtension: フォント拡張子
    fileprivate static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension) else {
            print("⚠️ フォントファイルが見つかりません: \(fontName).\(fontExtension)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            if let error = error?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(error) as String
                print("⚠️ フォント登録エラー: \(errorDescription)")
            }
        } else {
            print("✅ フォント登録成功: \(fontName)")
        }
    }
}

