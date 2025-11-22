import Foundation
import Security
import SwiftUI

// MARK: - Keychain管理
class KeychainManager {
    private let service = "com.storybook.app"
    
    /// Keychainにデータを保存
    func save(_ data: String, forKey key: String) {
        guard let data = data.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 既存のデータを削除
        SecItemDelete(query as CFDictionary)
        
        // 新しいデータを追加
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Keychainからデータを取得
    func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Keychainからデータを削除
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// トークン管理
class TokenManager {
    private let keychain = KeychainManager()
    
    /// トークンを保存
    func saveToken(_ token: String, type: TokenType) {
        keychain.save(token, forKey: type.key)
        print("✅ トークン保存完了: \(type.rawValue)")
    }
    
    /// トークンを取得
    func getToken(type: TokenType) -> String? {
        return keychain.get(forKey: type.key)
    }
    
    /// アクセストークンを保存
    func setAccessToken(_ token: String?) {
        guard let token = token else {
            deleteToken(type: .accessToken)
            return
        }
        
        saveToken(token, type: .accessToken)
    }
    
    /// アクセストークンを取得
    func getAccessToken() -> String? {
        return getToken(type: .accessToken)
    }
    
    /// トークンを削除
    func deleteToken(type: TokenType) {
        keychain.delete(forKey: type.key)
        print("🗑️ トークン削除完了: \(type.rawValue)")
    }
    
    /// 全てのトークンを削除
    func clearAllTokens() {
        TokenType.allCases.forEach { deleteToken(type: $0) }
        print("🗑️ 全トークン削除完了")
    }
    
    /// トークンの有効性をチェック
    func verifyToken(_ token: String) -> Bool {
        guard !token.isEmpty else { return false }
        
        // JWTトークンの有効期限をチェック
        return isJWTTokenValid(token)
    }
    
    /// JWTトークンの有効期限をチェック
    private func isJWTTokenValid(_ token: String) -> Bool {
        // JWTトークンを解析（header.payload.signature）
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { 
            print("❌ TokenManager: JWTトークンの形式が不正です (components: \(components.count))")
            return false 
        }
        
        // payload部分をデコード
        let payload = components[1]
        
        // Base64URLデコード
        var base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // パディングを追加
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            print("❌ TokenManager: JWTトークンの解析に失敗しました")
            return false
        }
        
        // 有効期限をチェック（現在時刻より未来か）
        let currentTime = Date().timeIntervalSince1970
        let isValid = exp > currentTime
        
        // デバッグ情報を出力
        let expirationDate = Date(timeIntervalSince1970: exp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        
        print("🔍 TokenManager: JWT有効期限チェック")
        print("   - 現在時刻: \(formatter.string(from: Date()))")
        print("   - 有効期限: \(formatter.string(from: expirationDate))")
        print("   - 有効: \(isValid)")
        
        if !isValid {
            let timeDiff = exp - currentTime
            print("   - 期限切れ時間: \(Int(abs(timeDiff)))秒前")
        }
        
        return isValid
    }
    
    /// アクセストークンの有効性をチェック
    func isAccessTokenValid() -> Bool {
        guard let token = getToken(type: .accessToken) else { 
            print("❌ TokenManager: アクセストークンが存在しません")
            return false 
        }
        
        let isValid = verifyToken(token)
        print("🔍 TokenManager: トークン有効性チェック - 有効: \(isValid)")
        
        if !isValid {
            print("⚠️ TokenManager: トークンが無効です - トークン: \(String(token.prefix(20)))...")
        }
        
        return isValid
    }
    
    /// トークンリフレッシュの必要性をチェック
    func shouldRefreshToken() -> Bool {
        guard let token = getToken(type: .accessToken) else { return true }
        
        // JWTトークンを解析して有効期限をチェック
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return true }
        
        let payload = components[1]
        var base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true
        }
        
        let currentTime = Date().timeIntervalSince1970
        let timeUntilExpiry = exp - currentTime
        
        // 有効期限まで30分以内の場合はリフレッシュが必要
        let refreshThreshold: TimeInterval = 30 * 60 // 30分
        let shouldRefresh = timeUntilExpiry < refreshThreshold
        
        if shouldRefresh {
            print("🔄 TokenManager: トークンリフレッシュが必要です (残り時間: \(Int(timeUntilExpiry/60))分)")
        }
        
        return shouldRefresh
    }
    
    /// リフレッシュトークンが存在するかチェック
    func hasRefreshToken() -> Bool {
        return getToken(type: .refreshToken) != nil
    }
    
    /// トークンリフレッシュを試行
    func attemptTokenRefresh() async -> Bool {
        print("🔄 TokenManager: トークンリフレッシュを試行中...")
        
        guard hasRefreshToken() else {
            print("❌ TokenManager: リフレッシュトークンが存在しません")
            return false
        }
        
        // TODO: 実際のリフレッシュ処理をプロバイダー毎に実装する
        print("⚠️ TokenManager: トークンリフレッシュ機能は未実装です")
        print("   実際の実装では、各認証プロバイダーのリフレッシュAPIを呼び出してください")
        
        return false
    }
}
