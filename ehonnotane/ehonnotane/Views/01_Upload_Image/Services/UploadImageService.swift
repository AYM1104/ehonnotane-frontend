import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// 画像アップロード画面の状態管理とビジネスロジックを担当するViewModel
@MainActor
class UploadImageService: ObservableObject {
    
    // 状態管理
    @Published var isUploading = false  // アップロード中かどうか
    @Published var uploadError: String?  // アップロードエラーメッセージ
    @Published var showingError = false  // エラーアラートを表示するかどうか
    @Published var uploadResult: UploadResult?  // アップロード成功時の結果
    
    // 依存関係
    /// 画像アップロードサービス
    private var imageUploadService: ImageUploadService?
    
    /// 物語設定作成サービス
    private var storySettingService: StorySettingService?
    
    /// 認証マネージャー
    private var authManager: AuthManager?
    
    // MARK: - Initialization
    
    init() {
        // 初期化時は何もしない（configureで設定）
    }
    
    // MARK: - Setup
    
    /// サービスを構成
    func configure(authManager: AuthManager) {
        self.authManager = authManager
        setupServices()
    }
    
    /// サービスを初期化
    private func setupServices() {
        guard let authManager = authManager else { return }
        let authProvider = DefaultAuthProvider(authManager: authManager)
        imageUploadService = ImageUploadService(authProvider: authProvider)
        storySettingService = StorySettingService(authProvider: authProvider)
    }
    
    // MARK: - Authentication
    
    /// 認証状態を確認
    func verifyAuthentication() -> Bool {
        guard let authManager = authManager else {
            print("❌ AuthManagerが設定されていません")
            return false
        }
        
        if authManager.isLoggedIn && authManager.verifyAuthState() {
            print("✅ 認証済みユーザー: 認証状態を確認")
            return true
        } else {
            uploadError = "ログインが必要です。ログイン画面に戻ってください。"
            showingError = true
            print("❌ 未ログイン: 認証が必要です")
            return false
        }
    }
    
    // MARK: - Upload
    
    /// 画像をアップロードして物語設定も作成
    /// - Parameter image: アップロードする画像
    func uploadImage(_ image: UIImage) async {
        // AuthManagerの確認
        guard let authManager = authManager else {
            uploadError = "認証エラーが発生しました"
            showingError = true
            return
        }
        
        // 認証状態を再確認
        guard authManager.isLoggedIn && authManager.verifyAuthState() else {
            uploadError = "ログインが必要です。ログイン画面に戻ってください。"
            showingError = true
            return
        }
        
        guard let imageUploadService = imageUploadService else {
            print("❌ imageUploadServiceがnilです")
            uploadError = "アップロードサービスが初期化されていません"
            showingError = true
            return
        }
        
        guard let storySettingService = storySettingService else {
            print("❌ storySettingServiceがnilです")
            uploadError = "物語設定サービスが初期化されていません"
            showingError = true
            return
        }
        
        print("========== 🔄 アップロード処理開始 ==========")
        isUploading = true
        uploadError = nil
        uploadResult = nil
        
        do {
            // 画像をアップロード
            let uploadResponse = try await imageUploadService.uploadImage(image)
            
            // 物語設定を作成
            let storySettingResponse = try await storySettingService.createStorySettingFromImage(imageId: uploadResponse.id)
            
            print("✅ アップロード成功:")
            print("   - 画像ID: \(uploadResponse.id)")
            print("   - ファイル名: \(uploadResponse.file_name ?? "不明")")
            print("   - 物語設定ID: \(storySettingResponse.story_setting_id)")
            print("   - 生成データ: \(storySettingResponse.generated_data_jsonString ?? "なし")")
            
            // 結果を保存
            uploadResult = UploadResult(
                imageId: uploadResponse.id,
                fileName: uploadResponse.file_name,
                storySettingId: storySettingResponse.story_setting_id,
                generatedData: storySettingResponse.generated_data_jsonString
            )
            
            isUploading = false
            print("🔄 アップロード完了")
            
        } catch {
            print("❌ アップロードエラー: \(error.localizedDescription)")
            
            isUploading = false
            uploadError = error.localizedDescription
            showingError = true
        }
    }
    
    /// エラーをクリア
    func clearError() {
        uploadError = nil
        showingError = false
    }
}

// MARK: - UploadResult

/// アップロード成功時の結果を保持する構造体
struct UploadResult: Equatable {
    let imageId: Int
    let fileName: String?
    let storySettingId: Int
    let generatedData: String?
}

