import SwiftUI
import UserNotifications

@main
struct ehonnotaneApp: App {
    // AppDelegateを統合（プッシュ通知対応）
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authManager = AuthManager()
    @StateObject private var googleProvider = GoogleAuthProvider()
    @StateObject private var appleProvider = AppleAuthProvider()
    @StateObject private var lineProvider = LineAuthProvider()
    @StateObject private var twitterProvider = TwitterAuthProvider()
    
    // StoreKitManagerはシングルトンを使用
    private let storeKitManager = StoreKitManager.shared
    
    init() {
        FontRegistration.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            // ===== StoreKit テスト用 (テスト完了後は下記をコメントアウトして、元のコードのコメントを解除) =====
            /*
            StoreKitTestView()
                .environmentObject(storeKitManager)
            */
            
            // ===== 元のコード (テスト完了後にコメント解除) =====
            
            // ログイン状態に応じて画面を切り替え
            Group {
                switch coordinator.currentScreen {
                case .top:
                    Top_View()
                case .userRegister:
                    User_Register_View()
                case .uploadImage:
                    Upload_Image_View()
                case .childAndPageSelect:
                    Child_and_Page_Selection_View(uploadResult: coordinator.uploadResult)
                case .question:
                    if let data = coordinator.questionData {
                        Question_View(
                            onNavigateToThemeSelect: {
                                coordinator.navigateToThemeSelect()
                            },
                            storySettingId: data.storySettingId,
                            childId: data.childId,
                            storyPages: data.storyPages
                        )
                    } else {
                        // データがない場合はエラー表示または戻る
                        Text(String(localized: "error.data_not_found"))
                            .onAppear {
                                coordinator.navigateToTop()
                            }
                    }
                case .themeSelect:
                    Theme_Select_View()
                case .storybook:
                    if let storybookId = coordinator.storybookId {
                        StoryBookView(storybookId: storybookId)
                    } else {
                        // データがない場合はエラー表示または戻る
                        Text(String(localized: "error.storybook_not_found"))
                            .onAppear {
                                coordinator.navigateToTop()
                            }
                    }
                case .myPage:
                    My_Page_View2()
                case .price:
                    PriceView()
                case .bookShelf:
                    BookShelfView()
                }
            }
            .environmentObject(coordinator)
            .environmentObject(authManager)
            .environmentObject(googleProvider)
            .environmentObject(appleProvider)
            .environmentObject(lineProvider)
            .environmentObject(twitterProvider)
            .environmentObject(storeKitManager)
            .onAppear {
                // 認証プロバイダーにAuthManagerへの参照を設定
                googleProvider.setAuthManager(authManager)
                appleProvider.setAuthManager(authManager)
                lineProvider.setAuthManager(authManager)
                twitterProvider.setAuthManager(authManager)
                
                // 起動時にログイン状態を確認
                authManager.checkLoginStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveStorybookNotification)) { notification in
                // プッシュ通知から絵本を開く
                if let storybookId = notification.userInfo?["storybook_id"] as? Int {
                    print("📬 通知から絵本を開きます: ID=\(storybookId)")
                    coordinator.navigateToStorybook(storybookId: storybookId)
                }
            }
            .onChange(of: authManager.isLoggedIn) { (oldValue: Bool, newValue: Bool) in
                // ログイン成功時に画像アップロード画面に遷移
                if !oldValue && newValue {
                    print("✅ App: ログイン成功を検知")
                    if authManager.isNewUser {
                        print("🆕 新規ユーザー -> 登録画面へ遷移")
                        coordinator.navigateToUserRegister()
                    } else {
                        print("🔄 既存ユーザー -> 画像アップロード画面へ遷移")
                        coordinator.navigateToUploadImage()
                    }
                    
                    // ログイン後にプッシュ通知の許可をリクエスト
                    PushNotificationManager.shared.requestNotificationPermission()
                }
            }
            .onOpenURL { url in
                print("🔗 App: URLを受け取りました: \(url.absoluteString)")
                // Auth0のコールバックURLを処理
                // Auth0 SDKが自動的に処理するため、特別な処理は不要
            }

        }
    }
}
