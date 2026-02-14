import Foundation
import Combine
import UserNotifications
import UIKit

/// プッシュ通知管理クラス
/// - 通知許可のリクエスト
/// - デバイストークンの取得
/// - バックエンドへのトークン登録
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var deviceToken: String?
    @Published var isNotificationEnabled: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - 通知許可のリクエスト
    
    /// 通知許可をリクエストし、許可された場合はリモート通知に登録
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
                
                if granted {
                    print("✅ 通知許可が取得されました")
                    self.registerForRemoteNotifications()
                } else if let error = error {
                    print("❌ 通知許可エラー: \(error.localizedDescription)")
                } else {
                    print("⚠️ 通知許可が拒否されました")
                }
            }
        }
    }
    
    /// リモート通知への登録
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - デバイストークンの処理
    
    /// デバイストークンを受け取った時の処理
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        // トークンを16進数文字列に変換
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        DispatchQueue.main.async {
            self.deviceToken = tokenString
            print("✅ デバイストークン取得: \(tokenString.prefix(20))...")
            
            // バックエンドにトークンを登録
            self.registerTokenToBackend(token: tokenString)
        }
    }
    
    /// リモート通知の登録に失敗した時の処理
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ リモート通知登録失敗: \(error.localizedDescription)")
    }
    
    // MARK: - バックエンドへのトークン登録
    
    /// デバイストークンをバックエンドに登録
    private func registerTokenToBackend(token: String) {
        // 認証情報を取得
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            print("⚠️ 認証トークンがないためデバイストークン登録をスキップ")
            return
        }
        
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/device-tokens") else {
            print("❌ 無効なURL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "device_token": token,
            "platform": "ios"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ リクエストボディのシリアライズに失敗: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ デバイストークン登録エラー: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ デバイストークンをバックエンドに登録しました")
                } else {
                    print("❌ デバイストークン登録失敗: HTTP \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // MARK: - トークンの削除（ログアウト時）
    
    /// ログアウト時にデバイストークンを削除
    func unregisterToken() {
        guard let token = deviceToken,
              let accessToken = AuthManager.shared.getAccessToken() else {
            return
        }
        
        guard let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(APIConfig.shared.baseURL)/api/device-tokens/\(encodedToken)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("⚠️ デバイストークン削除エラー: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ デバイストークンを削除しました")
            }
        }.resume()
        
        DispatchQueue.main.async {
            self.deviceToken = nil
        }
    }
    
    // MARK: - 通知の受信処理
    
    /// プッシュ通知を受信した時の処理
    func handleNotification(userInfo: [AnyHashable: Any]) {
        print("📬 通知受信: \(userInfo)")
        
        // ストーリーブックIDがあれば該当の絵本を開く
        if let storybookId = userInfo["storybook_id"] as? Int,
           let action = userInfo["action"] as? String,
           action == "view_storybook" {
            
            // メインスレッドで画面遷移
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .didReceiveStorybookNotification,
                    object: nil,
                    userInfo: ["storybook_id": storybookId]
                )
            }
        }
    }
}

// MARK: - 通知名の拡張

extension Notification.Name {
    static let didReceiveStorybookNotification = Notification.Name("didReceiveStorybookNotification")
}
