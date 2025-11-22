import SwiftUI
#if canImport(UIKit)
import UIKit

// 1) 最小の PageCurl ラッパー（背景/ダブルサイドをシンプルに）
struct SimplePageCurl<Content: View>: UIViewControllerRepresentable {
    var pages: [Content]

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .pageCurl,
                                       navigationOrientation: .horizontal,
                                       options: nil)
        pvc.dataSource = context.coordinator
        pvc.view.backgroundColor = .systemBackground
        context.coordinator.controllers = pages.map {
            let host = UIHostingController(rootView: $0.ignoresSafeArea())
            host.view.backgroundColor = .systemBackground
            return host
        }
        pvc.setViewControllers([context.coordinator.controllers.first!],
                               direction: .forward, animated: false)
        pvc.isDoubleSided = false   // まずは単ページで確実に動かす
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {}

    final class Coordinator: NSObject, UIPageViewControllerDataSource {
        var parent: SimplePageCurl
        var controllers: [UIViewController] = []
        init(_ parent: SimplePageCurl) { self.parent = parent }

        func pageViewController(_ p: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i > 0 else { return nil }
            return controllers[i - 1]
        }
        func pageViewController(_ p: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i + 1 < controllers.count else { return nil }
            return controllers[i + 1]
        }
    }
}

// 2) デモ用のはっきりしたページ
struct DemoPage: View {
    let number: Int
    var body: some View {
        ZStack {
            Color.white
            Text("\(number)")
                .font(.system(size: 160, weight: .black))
        }
        .ignoresSafeArea()
    }
}

// 3) 実行ビュー：右端/左端をスワイプしてめくる
struct MinimalPageCurlDemo: View {
    var body: some View {
        SimplePageCurl(pages: [
            DemoPage(number: 1),
            DemoPage(number: 2),
            DemoPage(number: 3),
            DemoPage(number: 4)
        ])
        .navigationBarBackButtonHidden(true) // 戻るスワイプと競合しないように
    }
}

// 4) Book.swiftで使用するPageCurlラッパー
public struct PageCurl: View {
    public let pages: [AnyView]
    @Binding var currentIndex: Int
    
    public init(pages: [AnyView], currentIndex: Binding<Int>) {
        self.pages = pages
        self._currentIndex = currentIndex
    }
    
    public var body: some View {
        SimplePageCurl<AnyView>(pages: pages)
            .onAppear {
                // 初期インデックスを設定（必要に応じて実装）
            }
    }
}

#Preview { MinimalPageCurlDemo() }
#endif
