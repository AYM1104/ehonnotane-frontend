import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct Upload_Image_View: View {
    
    // 画像選択関連の状態
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    // 環境オブジェクト
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var coordinator: AppCoordinator
    
    // ViewModel（アップロード関連の状態管理とビジネスロジック）
    @StateObject private var viewModel = UploadImageService()
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: String(localized: "theme.title_line1"))
                MainText(text: String(localized: "theme.title_line2"))
                Spacer()
                
                // メインカード
                mainCard(width: .screen95) {
                    VStack(spacing: 20) {

                        // 画像表示領域 
                        if let image = selectedImage {
                            
                            // 画像が選択された場合、プレビューと決定ボタンを表示
                            ImagePreview(
                                image: image,
                                isLoading: viewModel.isUploading,
                                onCancel: {
                                    selectedImage = nil
                                }
                            )
                            .padding(.top, 30)
                            .padding(.bottom, 30)
                            
                            // 決定ボタン
                            PrimaryButton(
                                title: String(localized: "upload.confirm_button"),
                                fontSize: 18,
                                action: {
                                    // プレビューでは実行されない
                                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                                        Task {
                                            await viewModel.uploadImage(image)
                                        }
                                    } else {
                                        print("プレビューモード: アップロードは実行されません")
                                    }
                                }
                            )
                            .disabled(viewModel.isUploading)
                            .padding(.bottom, 36)
                            
                        } else {
                            // 画像が選択されていない場合、選択ボタンのみ表示
                            Spacer()
                            PrimaryButton(
                                title: String(localized: "upload.select_image"),
                                fontSize: 20,
                                action: {
                                    // sheetを直接表示（SwiftUIが自動的にアニメーションを処理）
                                    showingImagePicker = true
                                }
                            )
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // ヘッダー
            Header()
            
            // 決定ボタンを押したらローディングオーバーレイを表示
            if viewModel.isUploading {
                LoadingOverlay(message: String(localized: "upload.loading_message"))
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            #if canImport(UIKit)
            ImagePicker(
                sourceType: .photoLibrary,
                onImagePicked: { image in
                    // 画像を設定（sheetは自動的に閉じる）
                    selectedImage = image
                    handleImageSelection(image)
                },
                onCancel: {
                    // キャンセル時は何もしない（sheetは自動的に閉じる）
                }
            )
            #endif
        }
        .onAppear {
            // ViewModelを初期化（プレビューでは実行されない）
            // 実際のアプリ実行時のみ初期化を行う
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                viewModel.configure(authManager: authManager)
                _ = viewModel.verifyAuthentication()
            }
        }
        .onChange(of: authManager.isLoggedIn) { (oldValue: Bool, newValue: Bool) in
            // ログアウトされた場合、トップ画面に戻る（将来の実装用）
            if oldValue && !newValue {
                print("⚠️ Upload_Image_View: ログアウトを検知")
            }
        }
        .alert(String(localized: "upload.error_title"), isPresented: Binding(
            get: { viewModel.showingError },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.uploadError {
                Text(error)
            }
        }
        .onChange(of: viewModel.uploadResult) { oldValue, newValue in
            // アップロード成功時の処理（次の画面への遷移など）
            if let result = newValue {
                print("✅ アップロード成功")
                print("   - 画像ID: \(result.imageId)")
                print("   - 物語設定ID: \(result.storySettingId)")
                // お子さま・ページ選択画面に遷移（プレビューでは実行されない）
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                    coordinator.navigateToChildAndPageSelect(result: result)
                }
            }
        }
    }
    
    /// 画像が選択された後の処理
    private func handleImageSelection(_ image: UIImage) {
        // 画像選択時はアップロードしない（決定ボタンでアップロード）
        print("画像が選択されました: \(image)")
    }
}



#Preview {
    Upload_Image_View()
        .environmentObject(AuthManager())
        .environmentObject(AppCoordinator())
}
