import SwiftUI
import Combine

/// 画像生成の進捗を監視するクラス
@MainActor
class ImageGenerationProgressMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published var isGeneratingImages = false
    @Published var generationProgress: Double = 0.0  // 0.0 - 1.0
    @Published var currentGeneratingPage: Int = 0
    @Published var totalPages: Int = 6
    @Published var generationMessage = "絵本の絵を描いています..."
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let storybookId: Int
    private let storybookService: StorybookService
    private var progressPollingTask: Task<Void, Never>?
    
    // MARK: - Callbacks
    var onCompleted: (() async -> Void)?
    var onFailed: ((String) -> Void)?
    
    // フォアグラウンド復帰時のポーリング再開用
    private var foregroundObserver: NSObjectProtocol?
    private var willEnterForegroundObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init(
        storybookId: Int,
        storybookService: StorybookService = .shared,
        initialTotalPages: Int? = nil,
        onCompleted: (() async -> Void)? = nil,
        onFailed: ((String) -> Void)? = nil
    ) {
        self.storybookId = storybookId
        self.storybookService = storybookService
        self.onCompleted = onCompleted
        self.onFailed = onFailed
        if let initialTotalPages {
            self.totalPages = initialTotalPages
        }
        
        // フォアグラウンド復帰時にポーリングを再開（willEnterForeground = より早い段階で検知）
        willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.resumePollingIfNeeded(reason: "willEnterForeground")
            }
        }
        
        // didBecomeActive でも再開チェック（念押し）
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.resumePollingIfNeeded(reason: "didBecomeActive")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 進捗ポーリングを開始
    func startPolling() {
        guard !isGeneratingImages else {
            print("⚠️ 既にポーリングが実行中です")
            return
        }
        
        isGeneratingImages = true
        errorMessage = nil
        generationProgress = 0.0
        currentGeneratingPage = 0
        
        progressPollingTask?.cancel()
        progressPollingTask = Task {
            await pollProgress()
        }
    }
    
    /// ポーリングを停止
    func stopPolling() {
        progressPollingTask?.cancel()
        progressPollingTask = nil
        isGeneratingImages = false
    }
    
    // MARK: - Private Methods
    
    /// 進捗をポーリング
    private func pollProgress() async {
        while !Task.isCancelled {
            do {
                let progress = try await storybookService.fetchGenerationProgress(storybookId: storybookId)
                
                // UI更新はメインスレッドで実行
                await MainActor.run {
                    self.generationProgress = Double(progress.progressPercent) / 100.0
                    self.currentGeneratingPage = progress.currentPage
                    self.totalPages = progress.totalPages
                }
                
                // デバッグログ: 進捗情報を出力
                print("📊 ImageGenerationProgressMonitor: 進捗取得 - status: \(progress.status), progress: \(progress.progressPercent)%, page: \(progress.currentPage)/\(progress.totalPages)")
                
                // 完了したらポーリング停止（大文字小文字を無視して比較）
                if progress.status.lowercased() == "completed" {
                    print("✅ ImageGenerationProgressMonitor: 画像生成完了を検知")
                    await MainActor.run {
                        // APIが100%未満の進捗を返しても表示を100%に揃える
                        self.generationProgress = 1.0
                        self.currentGeneratingPage = progress.totalPages
                        self.totalPages = progress.totalPages
                        self.isGeneratingImages = false
                    }
                    self.progressPollingTask?.cancel()
                    
                    // 完了コールバックを実行
                    if let onCompleted = onCompleted {
                        print("🚀 ImageGenerationProgressMonitor: onCompleted コールバックを実行します")
                        await onCompleted()
                        print("✅ ImageGenerationProgressMonitor: onCompleted コールバック実行完了")
                    } else {
                        print("⚠️ ImageGenerationProgressMonitor: onCompleted コールバックが設定されていません")
                    }
                    break
                } else if progress.status.lowercased() == "failed" {
                    await MainActor.run {
                        self.isGeneratingImages = false
                        self.errorMessage = "画像生成に失敗しました"
                    }
                    self.progressPollingTask?.cancel()
                    
                    // 失敗コールバックを実行
                    if let onFailed = onFailed {
                        await MainActor.run {
                            onFailed("画像生成に失敗しました")
                        }
                    }
                    break
                }
                
                // 完了していない場合は1秒後に再ポーリング
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                
            } catch {
                print("進捗取得エラー: \(error)")
                // エラー時は2秒待ってから再試行
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// フォアグラウンド復帰時にポーリング中であれば再開する
    private func resumePollingIfNeeded(reason: String) {
        guard isGeneratingImages else {
            print("ℹ️ ImageGenerationProgressMonitor: \(reason) - 生成中ではないためスキップ")
            return
        }
        
        print("🔄 ImageGenerationProgressMonitor: \(reason) - ポーリング再開チェック")
        print("   isGenerating=\(isGeneratingImages), pollingTask=\(String(describing: progressPollingTask)), cancelled=\(progressPollingTask?.isCancelled ?? true)")
        
        // 既存のタスクをキャンセルして新しいタスクを開始（サスペンド状態のタスクを確実にリフレッシュ）
        progressPollingTask?.cancel()
        progressPollingTask = nil
        
        print("🔄 ImageGenerationProgressMonitor: \(reason) - ポーリングを再開します")
        progressPollingTask = Task {
            await self.pollProgress()
        }
    }
    
    deinit {
        progressPollingTask?.cancel()
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
