import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

/// 画像プレビューとキャンセルボタンを含むコンポーネント
struct ImagePreview: View {
    
    #if canImport(UIKit)
    
    let image: UIImage  /// 表示する画像
    var maxWidth: CGFloat = 300 /// 画像の最大幅
    var aspectRatio: CGFloat = 4.0 / 3.0    /// 縦横比（幅:高さ）
    var cornerRadius: CGFloat = 36  /// コーナー半径
    var cancelButtonSize: CGFloat = 24  /// キャンセルボタンのサイズ
    var cancelButtonOffset: CGSize = CGSize(width: 10, height: -10) /// キャンセルボタンのオフセット
    #endif
    
    /// ロード中かどうか
    var isLoading: Bool = false
    
    /// キャンセル時のコールバック
    let onCancel: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        #if canImport(UIKit)
        ZStack(alignment: .topTrailing) {
            // 画像プレビュー（4:3の縦横比）
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: maxWidth, height: maxWidth / aspectRatio)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            
            // 右上のバツボタン
            if !isLoading {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: cancelButtonSize))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .offset(cancelButtonOffset)
            }
        }
        #else
        // UIKitが利用できない場合の代替表示
        Text("画像プレビュー")
            .font(.custom("YuseiMagic-Regular", size: 18))
            .foregroundColor(.white)
        #endif
    }
}

// MARK: - Preview

#Preview("ImagePreview Demo") {
    ImagePreviewDemo()
}

// プレビュー用のヘルパービュー
private struct ImagePreviewDemo: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    
    #if canImport(UIKit)
    @State private var selectedImage: UIImage? = nil
    #endif
    
    var body: some View {
        #if canImport(UIKit)
        VStack(spacing: 20) {
        if let image = selectedImage {
            VStack(spacing: 20) {
                // 選択された画像を表示
                ImagePreview(
                    image: image,
                    onCancel: {
                        selectedImage = nil
                        selectedItem = nil
                    }
                )
                
                // 決定ボタン
                PrimaryButton(
                    title: "これにけってい",
                    action: {
                        // 決定時の処理（必要に応じて実装）
                        print("画像が決定されました")
                    }
                )
                .padding(.top, 10) // ボタンの上に余白を追加
            }
        } else {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("画像を選択する")
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 16/255, green: 185/255, blue: 129/255),
                                Color(red: 20/255, green: 184/255, blue: 166/255),
                                Color(red: 6/255, green: 182/255, blue: 212/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        }
        .padding(10)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
        #else
        Text("Preview not available")
        #endif
    }
}
