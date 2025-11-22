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
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 更新処理は不要
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
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel?()
            picker.dismiss(animated: true)
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
