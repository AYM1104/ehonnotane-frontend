import SwiftUI
import UIKit

/// UIImagePickerControllerをSwiftUIで使用するためのラッパー
struct ImagePicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// 画像ソース（写真ライブラリ、カメラなど）
    let sourceType: UIImagePickerController.SourceType
    
    /// 画像が選択された時のコールバック
    let onImagePicked: (UIImage) -> Void
    
    /// ピッカーを閉じる時のコールバック
    let onCancel: (() -> Void)?
    
    // MARK: - Initializer
    
    init(
        sourceType: UIImagePickerController.SourceType,
        onImagePicked: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
        self.onCancel = onCancel
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false // 編集画面は不要
        // SwiftUIのsheetが自動的にモーダルプレゼンテーションを処理するため、
        // modalPresentationStyleは設定しない
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 初回表示時にupdateUIViewControllerが呼ばれることがあり、
        // その際にsourceTypeやdelegateを変更すると、一度閉じてから再度表示される問題が発生する
        // そのため、updateUIViewControllerでは何もしない
        // makeUIViewControllerで既に正しく設定されているため、更新は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        // 画像を取得
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        
        // pickerを閉じる（SwiftUIのsheetも自動的に閉じる）
        picker.dismiss(animated: true) {
            // メインスレッドでコールバックを呼び出し
            // dismiss完了後にコールバックを呼ぶことで、滑らかなアニメーションを保証
            if let image = image {
                DispatchQueue.main.async {
                    self.parent.onImagePicked(image)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // pickerを閉じる（SwiftUIのsheetも自動的に閉じる）
        picker.dismiss(animated: true) {
            // メインスレッドでコールバックを呼び出し
            DispatchQueue.main.async {
                self.parent.onCancel?()
            }
        }
    }
    }
}

// MARK: - Preview

#Preview {
    ImagePickerPreviewWrapper()
}

/// プレビュー用のボタンラッパー
private struct ImagePickerPreviewWrapper: View {
    @State private var isPresented = false
    @State private var selectedImageDescription = "まだ画像が選択されていません"
    
    var body: some View {
        VStack(spacing: 16) {
            Button("画像を選択する") {
                isPresented = true
            }
            Text(selectedImageDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $isPresented) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImageDescription = "画像が選択されました: \(image)"
            } onCancel: {
                selectedImageDescription = "キャンセルされました"
            }
        }
        .padding()
    }
}
