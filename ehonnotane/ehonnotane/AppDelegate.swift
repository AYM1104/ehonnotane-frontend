import UIKit
import UserNotifications

/// SwiftUIアプリでプッシュ通知を処理するためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 通知センターのデリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - リモート通知登録
    
    /// デバイストークンの取得に成功
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
    
    /// デバイストークンの取得に失敗
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// フォアグラウンドで通知を受信した時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 通知をタップした時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        PushNotificationManager.shared.handleNotification(userInfo: userInfo)
        completionHandler()
    }
}
