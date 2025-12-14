import SwiftUI
import Combine

/// アプリの画面遷移状態を表すenum
enum AppScreen {
    case top           // トップ画面（ログイン前）
    case userRegister  // ユーザー登録画面（新規登録時）
    case uploadImage   // 画像アップロード画面（ログイン後）
    case childAndPageSelect  // お子さま・ページ選択画面
    case question      // 質問画面
    case themeSelect   // テーマ選択画面
    case storybook     // ストーリーブック表示画面
    case myPage        // マイページ画面
}

/// アプリ全体の遷移状態を管理するコーディネーター
final class AppCoordinator: ObservableObject {
    /// 現在の画面状態
    @Published var currentScreen: AppScreen = .top
    
    /// ログイン後の遷移処理中かどうかを判定
    @Published var isNavigatingAfterLogin: Bool = false
    
    /// アップロード結果
    @Published var uploadResult: UploadResult?
    
    /// 質問画面への遷移データ
    @Published var questionData: (storySettingId: Int, childId: Int, storyPages: Int)?
    
    /// ストーリーブックID
    @Published var storybookId: Int?
    
    /// 新規ユーザー登録画面に遷移
    func navigateToUserRegister() {
        isNavigatingAfterLogin = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentScreen = .userRegister
            self?.isNavigatingAfterLogin = false
        }
    }
    
    /// ログイン成功時に画像アップロード画面に遷移
    func navigateToUploadImage() {
        isNavigatingAfterLogin = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentScreen = .uploadImage
            self?.isNavigatingAfterLogin = false
        }
    }
    
    /// アップロード成功時にお子さま・ページ選択画面に遷移
    func navigateToChildAndPageSelect(result: UploadResult? = nil) {
        if let result = result {
            self.uploadResult = result
        }
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .childAndPageSelect
        }
    }
    
    /// 質問画面に遷移
    func navigateToQuestion(storySettingId: Int, childId: Int, storyPages: Int) {
        self.questionData = (storySettingId, childId, storyPages)
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .question
        }
    }
    
    /// テーマ選択画面に遷移
    func navigateToThemeSelect() {
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .themeSelect
        }
    }
    
    /// ストーリーブック表示画面に遷移
    func navigateToStorybook(storybookId: Int) {
        self.storybookId = storybookId
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .storybook
        }
    }
    
    /// マイページ画面に遷移
    func navigateToMyPage() {
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .myPage
        }
    }
    
    /// トップ画面に戻る
    func navigateToTop() {
        DispatchQueue.main.async { [weak self] in
            self?.currentScreen = .top
            self?.uploadResult = nil
            self?.questionData = nil
            self?.storybookId = nil
        }
    }
}
