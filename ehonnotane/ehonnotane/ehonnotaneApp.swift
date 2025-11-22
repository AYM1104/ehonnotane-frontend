import SwiftUI

@main
struct ehonnotaneApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authManager = AuthManager()
    @StateObject private var googleProvider = GoogleAuthProvider()
    
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
                }
            }
            .environmentObject(coordinator)
            .environmentObject(authManager)
            .environmentObject(googleProvider)
            .onAppear {
                // GoogleAuthProviderにAuthManagerへの参照を設定
                googleProvider.setAuthManager(authManager)
                
                // 起動時にログイン状態を確認
                authManager.checkLoginStatus()
            }
            .onChange(of: authManager.isLoggedIn) { (oldValue: Bool, newValue: Bool) in
                // ログイン成功時に画像アップロード画面に遷移
                if !oldValue && newValue {
                    print("✅ App: ログイン成功を検知 - 画像アップロード画面に遷移します")
                    coordinator.navigateToUploadImage()
                }
            }
        }
    }
}
