import SwiftUI

@main
struct ehonnotaneApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authManager = AuthManager()
    @StateObject private var googleProvider = GoogleAuthProvider()
    @StateObject private var lineProvider = LineAuthProvider()
    @StateObject private var twitterProvider = TwitterAuthProvider()
    
    init() {
        FontRegistration.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
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
                        Text("エラー: データが見つかりません")
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
                        Text("エラー: ストーリーブックIDが見つかりません")
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
            .environmentObject(lineProvider)
            .environmentObject(twitterProvider)
            .onAppear {
                // 認証プロバイダーにAuthManagerへの参照を設定
                googleProvider.setAuthManager(authManager)
                lineProvider.setAuthManager(authManager)
                twitterProvider.setAuthManager(authManager)
                
                // 起動時にログイン状態を確認
                authManager.checkLoginStatus()
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
                }
            }
        }
    }
}
